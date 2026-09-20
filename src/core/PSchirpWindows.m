function w = PSchirpWindows(sinarg_raw, gyro, axisSum, thr, Fs, si, axisIdx)
%% PSchirpWindows - score every chirp run in a log, one struct per run
%  sinarg_raw - debug_0_ column (sinarg * 5000)
%  gyro       - gyro for the axis under test
%  axisSum    - P+I+D+F for that axis, or [] when the PID terms are not logged
%  thr        - setpoint_3_ (mixer throttle), or [] when absent
%  Fs         - sample rate (Hz), or [] to leave the timed fields unknown
%  si         - setupInfo cell array {param, value}
%  axisIdx    - 0=Roll, 1=Pitch, 2=Yaw, picks which pidsum limit applies
%
%  Everything from axisSum on is optional. What cannot be worked out comes back
%  NaN and complete comes back false, so a run nobody could time never reads as
%  a run that passed.
%
%  Fields: i0/i1/nSamp/durSec, chirpTime/complete, gyroVar, satFrac/pidsumLimit,
%  thrStd.

if nargin < 3, axisSum = []; end
if nargin < 4, thr = []; end
if nargin < 5, Fs = []; end
if nargin < 6, si = {}; end
if nargin < 7, axisIdx = []; end

sinarg_raw = sinarg_raw(:);
gyro = gyro(:);
axisSum = axisSum(:);
thr = thr(:);

w = struct([]);

% sinarg is a phase wrapping through [0, 2*pi], so it passes through zero on
% every cycle - hundreds of times a second at the top of the sweep. Only a real
% gap between runs separates two of them, not a wrap or a sample landing on one.
maxGap = 50;
act = find(sinarg_raw ~= 0);
if isempty(act), return; end

brk = find(diff(act) > maxGap);
starts = act([1; brk+1]);
ends = act([brk; numel(act)]);

chirpTime = NaN;
pidsumLimit = NaN;
if ~isempty(si)
    chirpTime = hnum(si, 'chirp_time_seconds');
    % yaw runs on its own limit, and scoring it against the roll one would hide
    % a third of the saturation
    if isequal(axisIdx, 2)
        pidsumLimit = hnum(si, 'pidsum_limit_yaw');
    elseif ~isempty(axisIdx)
        pidsumLimit = hnum(si, 'pidsum_limit');
    end
end

haveFs = ~isempty(Fs) && Fs > 0;
canSat = ~isempty(axisSum) && isfinite(pidsumLimit) && pidsumLimit > 0;

for k = 1:numel(starts)
    i0 = starts(k);
    i1 = ends(k);

    w(k).i0 = i0;
    w(k).i1 = i1;
    w(k).nSamp = i1 - i0 + 1;

    w(k).durSec = NaN;
    if haveFs, w(k).durSec = w(k).nSamp / Fs; end
    w(k).chirpTime = chirpTime;
    % a sweep cut short never reached the top of the band, yet fTrust off it
    % still comes out looking sensible
    w(k).complete = w(k).durSec >= 0.95 * chirpTime;

    w(k).gyroVar = var(gyro(i0:i1));

    w(k).satFrac = NaN;
    if canSat
        % the loop stops being linear before the sum reaches the clip, which
        % makes the plant measured off a saturated run a fiction
        w(k).satFrac = mean(abs(axisSum(i0:i1)) >= 0.98 * pidsumLimit);
    end
    w(k).pidsumLimit = pidsumLimit;

    w(k).thrStd = NaN;
    if ~isempty(thr), w(k).thrStd = std(thr(i0:i1)); end
end

end


function v = hnum(si, key)
    v = NaN;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            v = str2double(strtrim(si{k,2}));
            return;
        end
    end
end
