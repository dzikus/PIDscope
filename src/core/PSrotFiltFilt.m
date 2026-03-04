function y = PSrotFiltFilt(signal, sinarg, Fs)
%% PSrotFiltFilt - rotating demodulation filter (extract chirp-correlated component)
%  Based on pichim/bf_controller_tuning apply_rotfiltfilt.m
%  signal  - time-domain signal to filter (column vector)
%  sinarg  - chirp phase argument in radians (from debug_0_ / 5000)
%  Fs      - sample rate (Hz)

Ts = 1 / Fs;

% 2nd order Butterworth lowpass at 10 Hz (bilinear / Tustin)
wlp = 2 * pi * 10;
Dlp = sqrt(3) / 2;
[b, a] = butter2_tustin(wlp, Dlp, Ts);

% complex phasor from sinarg
p = exp(1j * sinarg(:));

% rotate to baseband
yR = signal(:) .* p;
yQ = signal(:) .* conj(p);

% zero-phase lowpass
yR = filtfilt(b, a, yR);
yQ = filtfilt(b, a, yQ);

% back-rotate and take real part
y = real((yR .* conj(p) + yQ .* p) * 0.5);

end


function [b, a] = butter2_tustin(wn, D, Ts)
    % 2nd order continuous: H(s) = wn^2 / (s^2 + 2*D*wn*s + wn^2)
    % Bilinear (Tustin) transform: s = (2/Ts)*(z-1)/(z+1)
    k = 2 / Ts;
    k2 = k^2;
    wn2 = wn^2;
    denom = k2 + 2*D*wn*k + wn2;
    b0 = wn2 / denom;
    b1 = 2 * wn2 / denom;
    b2 = wn2 / denom;
    a1 = 2 * (wn2 - k2) / denom;
    a2 = (k2 - 2*D*wn*k + wn2) / denom;
    b = [b0 b1 b2];
    a = [1 a1 a2];
end
