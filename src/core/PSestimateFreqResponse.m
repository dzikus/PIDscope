function [G, C, freq] = PSestimateFreqResponse(inp, out, Fs, Nest, Noverlap)
%% PSestimateFreqResponse - Welch cross-spectral frequency response estimation
%  Based on pichim/bf_controller_tuning estimate_frequency_response.m
%  inp      - input signal (excitation-correlated, column vector)
%  out      - output signal (response, column vector)
%  Fs       - sample rate (Hz)
%  Nest     - FFT segment length (default: round(2.5*Fs))
%  Noverlap - segment overlap (default: round(0.9*Nest))
%
%  Returns:
%    G    - complex frequency response (one-sided, Nhalf x 1)
%    C    - coherence 0..1 (Nhalf x 1)
%    freq - frequency vector in Hz (Nhalf x 1)

if nargin < 4 || isempty(Nest), Nest = round(2.5 * Fs); end
if nargin < 5 || isempty(Noverlap), Noverlap = round(0.9 * Nest); end

inp = inp(:);
out = out(:);
N = min(length(inp), length(out));
inp = inp(1:N) - mean(inp(1:N));
out = out(1:N) - mean(out(1:N));

w = hann(Nest, 'periodic');
Nstep = Nest - Noverlap;
Nseg = floor((N - Nest) / Nstep) + 1;

if Nseg < 1
    Nhalf = floor(Nest/2) + 1;
    G = zeros(Nhalf, 1);
    C = zeros(Nhalf, 1);
    freq = (0:Nhalf-1)' * Fs / Nest;
    return
end

Nhalf = floor(Nest/2) + 1;
W = sum(w) / Nest / 2;

Suu = zeros(Nhalf, 1);
Syu = zeros(Nhalf, 1);
Syy = zeros(Nhalf, 1);

for s = 1:Nseg
    i0 = (s-1) * Nstep + 1;
    idx = i0 : (i0 + Nest - 1);

    u_seg = inp(idx) .* w;
    y_seg = out(idx) .* w;

    U = fft(u_seg, Nest); U = U(1:Nhalf) / (Nest * W);
    Y = fft(y_seg, Nest); Y = Y(1:Nhalf) / (Nest * W);

    % DC and Nyquist: undo single-sided doubling
    U(1) = U(1) / 2; U(end) = U(end) / 2;
    Y(1) = Y(1) / 2; Y(end) = Y(end) / 2;

    Suu = Suu + U .* conj(U);
    Syu = Syu + Y .* conj(U);
    Syy = Syy + Y .* conj(Y);
end

Suu = Suu / Nseg;
Syu = Syu / Nseg;
Syy = Syy / Nseg;

delta = max(Suu) * 1e-12;
G = Syu ./ (Suu + delta);
C = abs(Syu).^2 ./ (Suu .* Syy + delta);

freq = (0:Nhalf-1)' * Fs / Nest;

end
