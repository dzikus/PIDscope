% test_PSmarginsFromL.m - tests for stability margins of the open loop

%!test
%! % Third order lag with known margins: L = K/(1 + j f/f0)^3, K=2, f0=1 Hz.
%! % |L| = 1 at f = 0.766421, phase there -112.3754 deg -> PM 67.6246
%! % phase = -180 at f = tan(60 deg) = 1.7320508, |L| = K/8 -> GM 12.0412 dB
%! f = (0.01:0.001:5)';
%! L = 2 ./ (1 + 1j*f).^3;
%! [gm, pm, wg, wp] = PSmarginsFromL(f, L);
%! assert(wp, 0.766421, 1e-3);
%! assert(pm, 67.6246, 0.05);
%! assert(wg, 1.7320508, 1e-3);
%! assert(gm, 12.0412, 0.05);

%!test
%! % A quad rate loop is already past -180 deg at the bottom of the band, so
%! % the principal value has to be used - unwrapping from the first bin puts
%! % the answer a full turn out and reports a phase margin over 360 deg.
%! f = (0.4:0.01:200)';
%! phd = min(-210 + 4*f, -100);      % -208.4 deg at the first bin, levels off
%! L = (25 ./ f) .* exp(1j*phd*pi/180);
%! assert(angle(L(1)) > 0, 'fixture must start with a positive principal angle');
%! [gm, pm, wg, wp] = PSmarginsFromL(f, L);
%! assert(wp, 25, 0.05);
%! assert(pm, 70, 0.2);
%! % the -180 crossing at 7.5 Hz sits below the gain crossover and belongs to
%! % the conditionally stable region, so it is not the gain margin
%! assert(isnan(gm), 'a crossing below the gain crossover is not the gain margin');

%!test
%! % Pure integrator: crosses 0 dB at fc with 90 deg to spare and never
%! % reaches -180, so there is no gain margin to report
%! fc = 12;
%! f = (0.1:0.005:100)';
%! L = fc ./ (1j*f);
%! [gm, pm, wg, wp] = PSmarginsFromL(f, L);
%! assert(wp, fc, 0.02);
%! assert(pm, 90, 0.1);
%! assert(isnan(gm));
%! assert(isnan(wg));

%!test
%! % A loop that never reaches 0 dB has no phase margin
%! f = (1:0.5:500)';
%! L = 0.01 ./ (1 + 1j*f/50);
%! [gm, pm, wg, wp] = PSmarginsFromL(f, L);
%! assert(isnan(pm));
%! assert(isnan(wp));

%!test
%! % Margins are returned in (-180, 180]: a loop crossing over with 200 deg of
%! % lag is unstable and must read as a negative margin, not 160
%! f = (0.4:0.01:200)';
%! phd = -260 + 3*f;                 % -200 deg at the 20 Hz crossover
%! L = (20 ./ f) .* exp(1j*phd*pi/180);
%! [~, pm, ~, wp] = PSmarginsFromL(f, L);
%! assert(wp, 20, 0.05);
%! assert(pm, -20, 0.2);
