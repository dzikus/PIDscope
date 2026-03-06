function [t_ms, step] = PSstepFromFRD(freq, G, fMax)
%% PSstepFromFRD - compute step response from frequency response data via IFFT
%  Based on pichim/bf_controller_tuning calculate_step_response_from_frd.m
%  freq  - frequency vector (Hz), one-sided
%  G     - complex frequency response (one-sided)
%  fMax  - truncation frequency (Hz), default max(freq)

if nargin < 3 || isempty(fMax), fMax = max(freq); end

G = G(:);
freq = freq(:);

% band-limit
G(freq > fMax) = 0;

% mirror for full two-sided spectrum (Hermitian symmetry → real IFFT)
Nfull = 2 * (length(G) - 1);
G_full = [G; conj(G(end-1:-1:2))];

imp = real(ifft(G_full));
step = cumsum(imp);

% normalize to unit DC if G(1) is not zero
if abs(G(1)) > 1e-10
    step = step / abs(G(1));
end

Ts = 1 / (2 * freq(end));
t_ms = (0:length(step)-1)' * Ts * 1000;

% trim to first 500 ms
mask = t_ms <= 500;
t_ms = t_ms(mask);
step = step(mask);

end
