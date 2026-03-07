function PSrunChirpAnalysis(T, setupInfo, debugIdx, Fs, tIND, axisIdx)
%% PSrunChirpAnalysis - extract chirp data and run frequency response analysis
%  T          - data struct for one file
%  setupInfo  - header cell array {param, value}
%  debugIdx   - debug mode indices struct
%  Fs         - sample rate (Hz)
%  tIND       - logical time index mask
%  axisIdx    - 0=Roll, 1=Pitch, 2=Yaw

axNames = {'Roll', 'Pitch', 'Yaw'};
axSuffix = {'_0_', '_1_', '_2_'};
ax = axisIdx + 1;

% check CHIRP debug mode
if ~isfield(T, 'debug_0_')
    warndlg('No debug data in log - chirp analysis requires debug_mode = CHIRP');
    return
end

sinarg_raw = T.debug_0_(tIND);
sinarg = sinarg_raw / 5000;

if max(abs(sinarg)) < 0.1
    warndlg('No chirp data found in debug_0_ (sinarg ≈ 0). Set debug_mode = CHIRP in BF.');
    return
end

% get gyro and setpoint for selected axis
gyro = T.(['gyroADC' axSuffix{ax}])(tIND);
sp = T.(['setpoint' axSuffix{ax}])(tIND);

% find chirp evaluation window
[i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
sinarg_w = sinarg(i0:i1);
gyro_w = gyro(i0:i1);
sp_w = sp(i0:i1);

fprintf('Chirp window: samples %d-%d (%d samples, %.1f s)\n', ...
    i0, i1, i1-i0+1, (i1-i0+1)/Fs);

% apply rotating demodulation filter to extract chirp-correlated components
sp_filt = PSrotFiltFilt(sp_w, sinarg_w, Fs);
gyro_filt = PSrotFiltFilt(gyro_w, sinarg_w, Fs);

% build axisSum and axisSumPI if PID terms available
hasAxisSum = false;
if isfield(T, ['axisP' axSuffix{ax}]) && isfield(T, ['axisI' axSuffix{ax}])
    P = T.(['axisP' axSuffix{ax}])(tIND);
    I = T.(['axisI' axSuffix{ax}])(tIND);
    D = zeros(size(P));
    F = zeros(size(P));
    if isfield(T, ['axisD' axSuffix{ax}]), D = T.(['axisD' axSuffix{ax}])(tIND); end
    if isfield(T, ['axisF' axSuffix{ax}]), F = T.(['axisF' axSuffix{ax}])(tIND); end

    axisSum_w = P(i0:i1) + I(i0:i1) + D(i0:i1) + F(i0:i1);
    axisSumPI_w = P(i0:i1) + I(i0:i1);

    axisSum_filt = PSrotFiltFilt(axisSum_w, sinarg_w, Fs);
    hasAxisSum = true;
end

% estimate tracking transfer function: T = sp → gyro
[G_track, C_track, freq] = PSestimateFreqResponse(sp_filt, gyro_filt, Fs);

% estimate plant if PID terms available
G_plant = [];
if hasAxisSum
    [G_uw, ~, ~] = PSestimateFreqResponse(sp_filt, axisSum_filt, Fs);
    % P = T / Guw (transfer function from controller output to gyro)
    G_plant = G_track ./ (G_uw + 1e-12);
end

% step response from tracking TF
stepData = struct();
try
    [stepData.t_ms, stepData.step] = PSstepFromFRD(freq, G_track, 300);
catch
    stepData = [];
end

% plot
PSplotBode(freq, G_track, G_plant, C_track, stepData, axNames{ax});

end
