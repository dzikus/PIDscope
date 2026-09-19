function id = PSidentifyChirp(T, setupInfo, Fs, tIND, axisIdx)
%% PSidentifyChirp - measure the plant and the tracking response from a chirp run
%  T          - data struct for one file
%  setupInfo  - header cell array {param, value}
%  Fs         - sample rate (Hz)
%  tIND       - logical time index mask
%  axisIdx    - 0=Roll, 1=Pitch, 2=Yaw
%
%  Always returns the same fields, so three axes concatenate into a struct
%  array. Nothing is drawn, printed or popped up - the caller decides how to
%  report ok and msg, which is what lets all three axes run without opening
%  three windows.

axNames = {'Roll', 'Pitch', 'Yaw'};
axSuffix = {'_0_', '_1_', '_2_'};
ax = axisIdx + 1;

id = blank();
id.axisIdx = axisIdx;
id.axisName = axNames{ax};

if ~isfield(T, 'debug_0_')
    id.msg = 'No debug data in log - chirp analysis requires debug_mode = CHIRP';
    return
end

sinarg_raw = T.debug_0_(tIND);
sinarg = sinarg_raw / 5000;

if max(abs(sinarg)) < 0.1
    id.msg = 'No chirp data found in debug_0_ (sinarg ≈ 0). Set debug_mode = CHIRP in BF.';
    return
end

gyro = T.(['gyroADC' axSuffix{ax}])(tIND);
sp = T.(['setpoint' axSuffix{ax}])(tIND);

hasAxisSum = isfield(T, ['axisP' axSuffix{ax}]) && isfield(T, ['axisI' axSuffix{ax}]);
axisSum = []; Dterm = []; Fterm = [];
if hasAxisSum
    P = T.(['axisP' axSuffix{ax}])(tIND);
    I = T.(['axisI' axSuffix{ax}])(tIND);
    Dterm = zeros(size(P));
    Fterm = zeros(size(P));
    if isfield(T, ['axisD' axSuffix{ax}]), Dterm = T.(['axisD' axSuffix{ax}])(tIND); end
    if isfield(T, ['axisF' axSuffix{ax}]), Fterm = T.(['axisF' axSuffix{ax}])(tIND); end
    axisSum = P + I + Dterm + Fterm;
end

thr = [];
if isfield(T, 'setpoint_3_'), thr = T.setpoint_3_(tIND); end

% scores come from the block list, the pick from the one function that owns
% that rule - two copies of it would drift
w = PSchirpWindows(sinarg_raw, gyro, axisSum, thr, Fs, setupInfo, axisIdx);
[i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
id.i0 = i0;
id.i1 = i1;
id.nSamp = i1 - i0 + 1;
k = find([w.i0] == i0, 1);
if ~isempty(k)
    id.durSec = w(k).durSec;
    id.gyroVar = w(k).gyroVar;
    id.pidsumLimit = w(k).pidsumLimit;
end

sinarg_w = sinarg(i0:i1);
sp_filt = PSrotFiltFilt(sp(i0:i1), sinarg_w, Fs);
gyro_filt = PSrotFiltFilt(gyro(i0:i1), sinarg_w, Fs);

[id.G_track, id.C_track, id.freq, id.nSeg] = ...
    PSestimateFreqResponse(sp_filt, gyro_filt, Fs);

if hasAxisSum
    axisSum_filt = PSrotFiltFilt(axisSum(i0:i1), sinarg_w, Fs);
    [id.G_uw, id.C_uw, ~] = PSestimateFreqResponse(sp_filt, axisSum_filt, Fs);
    id.G_plant = id.G_track ./ (id.G_uw + 1e-12);
    id.axisD = Dterm(i0:i1);
    Fw = Fterm(i0:i1);
    if any(Fw ~= 0)
        axisF_filt = PSrotFiltFilt(Fw, sinarg_w, Fs);
        [id.G_ff, ~, ~] = PSestimateFreqResponse(sp_filt, axisF_filt, Fs);
    end
end

id.fTrust = PStrustBand(id.freq, id.C_track);

if ~isempty(setupInfo)
    id.fp = PSparseFilterParams(setupInfo);
    id.FsPid = id.fp.pid_rate_hz;
    if id.FsPid <= 0, id.FsPid = Fs; end
    id.gains = PSparsePIDGains(setupInfo, axisIdx);
end

id.ok = true;

end


function id = blank()
    id = struct('ok', false, 'msg', '', ...
                'freq', [], 'G_track', [], 'C_track', [], ...
                'G_plant', [], 'G_uw', [], 'C_uw', [], 'G_ff', [], ...
                'gains', [], 'fp', [], 'FsPid', [], ...
                'axisIdx', [], 'axisName', '', ...
                'i0', [], 'i1', [], 'nSamp', [], 'durSec', NaN, ...
                'gyroVar', NaN, 'nSeg', 0, 'fTrust', NaN, ...
                'axisD', [], 'pidsumLimit', NaN);
end
