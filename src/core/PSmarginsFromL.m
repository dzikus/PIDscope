function [gm_dB, pm_deg, wcg, wcp] = PSmarginsFromL(freq, L)
%% PSmarginsFromL - gain and phase margin of an open loop
%  freq - frequency vector (Hz)
%  L    - complex open loop response on that grid (P*C, not a closed loop)
%
%  gm_dB, wcg - gain margin (dB) and the phase crossover it sits at (Hz)
%  pm_deg, wcp - phase margin (deg, in (-180, 180]) and the gain crossover (Hz)
%  Either pair is NaN when the loop has no such crossing in the band given.
%
%  The phase comes from the principal value rather than from unwrapping. A quad
%  rate loop is already past -180 deg at the bottom of the band - the plant is
%  an integrator and the I term adds its own 90 deg - so unwrapping from the
%  first bin puts every later value a full turn out.

freq = freq(:);
L = L(:);
mag_dB = 20*log10(abs(L) + 1e-12);

wcp = NaN; pm_deg = NaN;
ci = find(diff(sign(mag_dB)) ~= 0, 1);
if ~isempty(ci)
    wcp = interp1(mag_dB(ci:ci+1), freq(ci:ci+1), 0, 'linear');
    Lc = interp1(freq(ci:ci+1), L(ci:ci+1), wcp, 'linear');
    pm_deg = 180 + angle(Lc) * 180/pi;
    if pm_deg > 180, pm_deg = pm_deg - 360; end
end

% The gain margin is the first phase crossover above the gain crossover: that
% is the one saying how much more gain the loop takes. Crossings below it
% belong to the conditionally stable region every PI-on-integrator loop has.
wcg = NaN; gm_dB = NaN;
crossed = find(diff(sign(imag(L))) ~= 0 & real(L(1:end-1)) < 0);
if ~isnan(wcp), crossed = crossed(freq(crossed) > wcp); end
if ~isempty(crossed)
    ci = crossed(1);
    wcg = interp1(imag(L(ci:ci+1)), freq(ci:ci+1), 0, 'linear');
    gm_dB = -interp1(freq(ci:ci+1), mag_dB(ci:ci+1), wcg, 'linear');
end

end
