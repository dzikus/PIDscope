function [A, D, F] = PSbuildController(gains, fp, Fs, freq)
%% PSbuildController - Betaflight PID controller as a frequency response
%  Splits the controller the way the loop actually uses it: the PI part acts on
%  the error, the D part on the gyro, the feedforward part on the setpoint.
%  Output units match the logged axisP/axisI/axisD/axisF, so the result can be
%  checked straight against a log.
%
%  gains - struct with P, I, D, F (as entered in the firmware), optional tpa
%  fp    - filter params from PSparseFilterParams, or [] for no dterm filtering
%  Fs    - PID loop rate (Hz)
%  freq  - frequency vector (Hz)
%
%  A - Kp + Ki/s, on the error
%  D - Kd*s*Hdterm, on the gyro (enters the loop with a minus sign)
%  F - Kff*s, on the setpoint
%
%  Feedforward smoothing is not modelled, so F is optimistic on a log flown
%  with heavy smoothing - compare against the logged axisF before trusting it.

PTERM_SCALE = 0.032029;
ITERM_SCALE = 0.244381;
DTERM_SCALE = 0.000529;
FF_SCALE    = 0.013754;

tpa = 1;
if isfield(gains, 'tpa') && ~isempty(gains.tpa), tpa = gains.tpa; end

Kp = gains.P * PTERM_SCALE * tpa;
Ki = gains.I * ITERM_SCALE;
Kd = gains.D * DTERM_SCALE * tpa;
Kf = gains.F * FF_SCALE;

Ts = 1 / Fs;
freq = freq(:);
zinv = exp(-2j*pi*freq*Ts);

A = Kp + Ki * Ts ./ (1 - zinv);
dc = (freq == 0);
if any(dc)
    if Ki > 0, A(dc) = Inf; else, A(dc) = Kp; end
end

deriv = (1 - zinv) / Ts;
D = Kd * deriv .* dtermChain(fp, Fs, freq);
F = Kf * deriv;

end


function H = dtermChain(fp, Fs, freq)
    def = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 0, ...
                 'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
                 'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
    fn = fieldnames(def);
    for k = 1:numel(fn)
        if isstruct(fp) && isfield(fp, fn{k}) && ~isempty(fp.(fn{k}))
            def.(fn{k}) = fp.(fn{k});
        end
    end

    H = notchResp(def.dterm_notch_hz, def.dterm_notch_cut, Fs, freq);
    H = H .* lpfResp(def.dterm_lpf1_type, def.dterm_lpf1_hz, Fs, freq);
    H = H .* lpfResp(def.dterm_lpf2_type, def.dterm_lpf2_hz, Fs, freq);
end


function H = lpfResp(type, hz, Fs, freq)
    types = {'pt1', 'biquad', 'pt2', 'pt3'};   % BF enum 0..3
    H = ones(numel(freq), 1);
    if hz <= 0 || type < 0 || type >= numel(types), return; end
    [b, a] = PSbfFilters(types{type+1}, hz, Fs);
    H = freqz(b, a, freq, Fs);
    H = H(:);
end


function H = notchResp(center_hz, cutoff_hz, Fs, freq)
    H = ones(numel(freq), 1);
    Q = PSnotchQ(center_hz, cutoff_hz);
    if Q <= 0, return; end
    [b, a] = PSbfFilters('notch', center_hz, Fs, Q);
    H = freqz(b, a, freq, Fs);
    H = H(:);
end
