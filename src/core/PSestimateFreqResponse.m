function [G, C, freq, nSeg] = PSestimateFreqResponse(inp, out, Fs, Nest, Noverlap)
%% PSestimateFreqResponse - Welch cross-spectral frequency response estimation
%  Based on pichim/bf_controller_tuning estimate_frequency_response.m
%  inp      - input signal (excitation-correlated, column vector), or a cell
%             array of several windows of the same system
%  out      - output signal (response), matching inp in shape and count
%  Fs       - sample rate (Hz)
%  Nest     - FFT segment length (default: round(2.5*Fs))
%  Noverlap - segment overlap (default: round(0.9*Nest))
%
%  Returns:
%    G    - complex frequency response (one-sided, Nhalf x 1)
%    C    - coherence 0..1 (Nhalf x 1)
%    freq - frequency vector in Hz (Nhalf x 1)
%    nSeg - how many segments went into the average
%
%  Several windows pool their Suu/Syu/Syy accumulators before G and C are
%  formed, which weights each window by how hard it was driven. Averaging the
%  finished G estimates instead would give a barely excited window the same say
%  as a well excited one.

if nargin < 4 || isempty(Nest), Nest = round(2.5 * Fs); end
if nargin < 5 || isempty(Noverlap), Noverlap = round(0.9 * Nest); end

if ~iscell(inp), inp = {inp}; end
if ~iscell(out), out = {out}; end
if numel(inp) ~= numel(out)
    error('PSestimateFreqResponse: %d input windows against %d output windows', ...
          numel(inp), numel(out));
end

Nhalf = floor(Nest/2) + 1;
freq = (0:Nhalf-1)' * Fs / Nest;

w = hann(Nest, 'periodic');
Nstep = Nest - Noverlap;
W = sum(w) / Nest / 2;

Suu = zeros(Nhalf, 1);
Syu = zeros(Nhalf, 1);
Syy = zeros(Nhalf, 1);
nSeg = 0;

for k = 1:numel(inp)
    u = inp{k}(:);
    y = out{k}(:);
    N = min(length(u), length(y));
    if N < Nest, continue; end
    u = u(1:N) - mean(u(1:N));
    y = y(1:N) - mean(y(1:N));

    for s = 1:(floor((N - Nest) / Nstep) + 1)
        i0 = (s-1) * Nstep + 1;
        idx = i0 : (i0 + Nest - 1);

        U = fft(u(idx) .* w, Nest); U = U(1:Nhalf) / (Nest * W);
        Y = fft(y(idx) .* w, Nest); Y = Y(1:Nhalf) / (Nest * W);

        % DC and Nyquist: undo single-sided doubling
        U(1) = U(1) / 2; U(end) = U(end) / 2;
        Y(1) = Y(1) / 2; Y(end) = Y(end) / 2;

        Suu = Suu + U .* conj(U);
        Syu = Syu + Y .* conj(U);
        Syy = Syy + Y .* conj(Y);
        nSeg = nSeg + 1;
    end
end

if nSeg < 1
    G = zeros(Nhalf, 1);
    C = zeros(Nhalf, 1);
    return
end

Suu = Suu / nSeg;
Syu = Syu / nSeg;
Syy = Syy / nSeg;

delta = max(Suu) * 1e-12;
G = Syu ./ (Suu + delta);
C = abs(Syu).^2 ./ (Suu .* Syy + delta);

end
