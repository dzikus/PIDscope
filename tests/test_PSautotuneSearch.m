% test_PSautotuneSearch.m - the 2D scan over P and D
%
% Every expected number here comes from phase algebra on the fixture plant, not
% from a previous run of the scan. The fixture is an integrator with delay,
%   P(f) = k*exp(-j*w*tau) / (j*w)
% for which proportional-only control gives exactly
%   PM = 90 deg - w*tau*(180/pi)
% so a phase margin target fixes the crossover, and the crossover fixes P.

%!function id = mkfix(varargin)
%!  p = struct('k', 180.13977, 'tau', 0.002, 'P', 40, 'I', 0, 'D', 0, 'F', 0, ...
%!             'dMax', 0, 'fTrust', 300, 'fp', [], 'mode', 0, 'modeQ', 3, ...
%!             'axisD', 1, 'notch', 0);
%!  for j = 1:2:numel(varargin), p.(varargin{j}) = varargin{j+1}; end
%!  Fs = 2000;
%!  freq = (0:0.2:600)';
%!  w = 2*pi*freq; s = 1j*w;
%!  G = p.k * exp(-1j*w*p.tau) ./ (1j*w);
%!  G(1) = 1e9;
%!  if p.mode > 0
%!    wn = 2*pi*p.mode;
%!    G = G ./ (1 + s/(p.modeQ*wn) + (s/wn).^2);
%!  end
%!  if p.notch > 0
%!    wz = 2*pi*p.notch;
%!    G = G .* (s.^2 + wz^2) ./ (s.^2 + s*wz/3 + wz^2);
%!  end
%!  id = struct('ok', true, 'msg', '', 'freq', freq, 'G_track', [], ...
%!              'C_track', ones(size(freq)), 'G_plant', G, 'G_uw', [], ...
%!              'C_uw', [], 'G_ff', [], ...
%!              'gains', struct('axis',0,'P',p.P,'I',p.I,'D',p.D,'F',p.F,'dMax',p.dMax), ...
%!              'fp', p.fp, 'FsPid', Fs, 'axisIdx', 0, 'axisName', 'Roll', ...
%!              'i0', 1, 'i1', 40000, 'nSamp', 40000, 'durSec', 20, ...
%!              'gyroVar', 5e5, 'nSeg', 70, 'fTrust', p.fTrust, ...
%!              'axisD', p.axisD*ones(1000,1), 'pidsumLimit', 800);
%!endfunction

%!test
%! % T1 - the target is hit where the algebra says it is.
%! % tau = 2 ms and a 50 deg target pin w*tau = 40 deg, so w = 349.066 rad/s and
%! % the exact P that lands there is 60.5. k is picked to put it half an integer
%! % from either neighbour, so the scan has to return 60 on the rule and not on
%! % a rounding accident. That P gives w = 346.18 rad/s, f = 55.10 Hz, PM 50.33.
%! % msMax is lifted here so that the phase margin is the only thing binding.
%! res = PSautotuneSearch(mkfix(), struct('pmTarget', 50, 'msMax', 3));
%! assert(res.ok, res.reason);
%! assert(res.gains.P == 60, sprintf('expected P 60, got %d', res.gains.P));
%! assert(abs(res.wcp - 55.096) < 0.3, sprintf('crossover %.2f Hz', res.wcp));
%! assert(res.pm > 50 && res.pm < 50.5, sprintf('pm %.4f', res.pm));

%!test
%! % T2 - three targets, three answers, each fixed by the same algebra. The
%! % target sets w*tau, w*tau sets the crossover, and the crossover sets the
%! % exact P: 50 deg -> 40 deg -> 60.50; 60 deg -> 30 deg -> 45.38;
%! % 72.5 deg -> 17.5 deg -> 26.47. Only the integer below each clears.
%! got = zeros(1,3);
%! tgt = [50 60 72.5];
%! for k = 1:3
%!   r = PSautotuneSearch(mkfix(), struct('pmTarget', tgt(k), 'msMax', 3));
%!   assert(r.ok, r.reason);
%!   got(k) = r.gains.P;
%! end
%! assert(isequal(got, [60 45 26]), sprintf('got %d %d %d', got));
%! assert(all(diff(got) < 0), 'a stricter target must never ask for more gain');

%!test
%! % T3 - a lightly damped mode above the crossover bends the Nyquist curve
%! % toward -1 without eating the phase margin, so Ms binds first. The answer
%! % then comes out well inside the phase target instead of spending it, and it
%! % is a different answer from T1 - otherwise this test proves nothing.
%! res = PSautotuneSearch(mkfix('mode', 110, 'modeQ', 3), struct('pmTarget', 50));
%! assert(res.ok, res.reason);
%! assert(res.ms <= 2.0 + 1e-9, sprintf('Ms %.4f over the hard limit', res.ms));
%! assert(res.ms > 1.9, sprintf('Ms %.4f is not what bound the answer', res.ms));
%! assert(res.pm > 60, sprintf('pm %.2f - Ms should have bound well before PM', res.pm));
%! assert(res.gains.P ~= 60, 'a resonant plant must not land on the T1 answer');

%!test
%! % T4 - an over-tuned loop has to be told to come down. Without this the scan
%! % could be written as "only ever raise" and still pass T1 to T3.
%! res = PSautotuneSearch(mkfix('P', 80), struct('pmTarget', 60));
%! assert(res.ok, res.reason);
%! assert(res.scale.P < 1, sprintf('expected a cut, got scale %.3f', res.scale.P));
%! assert(res.gains.P == 45, sprintf('expected P 45, got %d', res.gains.P));

%!test
%! % T5 - the #5258 barrier. A result that cannot name a filter cannot retune
%! % one. This is structural, so it is checked on every shape of input.
%! cases = {mkfix(), mkfix('P', 80), mkfix('mode', 45), ...
%!          mkfix('D', 15, 'tau', 0.006), mkfix('I', 60), mkfix('fTrust', 120)};
%! for k = 1:numel(cases)
%!   r = PSautotuneSearch(cases{k}, struct('pmTarget', 60));
%!   assert(isequal(sort(fieldnames(r.gains)), sort({'axis';'P';'I';'D';'F'})), ...
%!          sprintf('case %d: gains must carry exactly axis P I D F', k));
%!   assert(~isfield(r, 'fp'), sprintf('case %d: result must not carry filter params', k));
%!   fn = fieldnames(r);
%!   for j = 1:numel(fn)
%!     assert(isempty(strfind(lower(fn{j}), 'lpf')), 'no filter field may appear');
%!     assert(isempty(strfind(lower(fn{j}), 'notch')), 'no filter field may appear');
%!     assert(isempty(strfind(lower(fn{j}), 'dterm')), 'no filter field may appear');
%!     assert(isempty(strfind(lower(fn{j}), 'gyro')), 'no filter field may appear');
%!   end
%! end

%!test
%! % T9 - the D dimension is worth having, and worth knowing by how much.
%! % With tau = 6 ms and P alone, PM = 60 pins w*tau = 30 deg, so the crossover
%! % sits at 13.89 Hz whatever P does: P moves magnitude, never phase. k here
%! % puts the exact P-only answer at 40.5, so the scan must return 40 and 13.72
%! % Hz. Adding D moves it to 21.98 Hz.
%! % Unlimited lead would give 3.2x rather than 1.6x. It is capped because a
%! % cell is admissible only while |D| <= |A| at the crossover, which holds D's
%! % contribution to at most 45 deg of lead. That cap is the point: lead beyond
%! % it means stability resting on the derivative and its filters, which is the
%! % least certain part of the model.
%! kk = 67.2743;
%! o = struct('pmTarget', 60);
%! rP = PSautotuneSearch(mkfix('k', kk, 'tau', 0.006, 'P', 40, 'D', 0), o);
%! r2 = PSautotuneSearch(mkfix('k', kk, 'tau', 0.006, 'P', 40, 'D', 12), o);
%! assert(rP.ok, rP.reason); assert(r2.ok, r2.reason);
%! assert(abs(rP.wcp - 13.72) < 0.3, sprintf('P-only crossover %.2f Hz', rP.wcp));
%! assert(r2.wcp > 1.5 * rP.wcp, ...
%!        sprintf('2D crossover %.2f vs P-only %.2f Hz', r2.wcp, rP.wcp));
%! assert(r2.gains.D ~= 12, 'the scan has to actually move D, not just leave it');

%!test
%! % T10 - and the D filter takes part of that lead straight back. A scan that
%! % assumed an ideal Kd*s would promise phase lead the hardware does not have,
%! % which is a flyaway derived from a linear model. Measured, strictly ordered:
%! % 13.72 Hz on P alone, 18.10 Hz with a PT1 at 30 Hz, 21.98 Hz unfiltered.
%! kk = 67.2743;
%! fpPT1 = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 30, ...
%!                'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
%!                'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
%! o = struct('pmTarget', 60);
%! rP    = PSautotuneSearch(mkfix('k',kk,'tau',0.006,'P',40,'D',0), o);
%! rFilt = PSautotuneSearch(mkfix('k',kk,'tau',0.006,'P',40,'D',12,'fp',fpPT1), o);
%! rNone = PSautotuneSearch(mkfix('k',kk,'tau',0.006,'P',40,'D',12), o);
%! assert(rNone.wcp > rFilt.wcp, ...
%!        sprintf('unfiltered D must beat PT1-filtered D: %.1f vs %.1f Hz', ...
%!                rNone.wcp, rFilt.wcp));
%! assert(rFilt.wcp > rP.wcp, ...
%!        sprintf('filtered D must still beat P alone: %.1f vs %.1f Hz', ...
%!                rFilt.wcp, rP.wcp));

%!test
%! % T13 - D makes a second 0 dB crossing real, and PSmarginsFromL reports the
%! % first one. A cell with more than one crossing has a phase margin that means
%! % nothing, so it must never be chosen.
%! res = PSautotuneSearch(mkfix('notch', 30), struct('pmTarget', 50));
%! assert(any(res.grid.nCross(:) > 1), 'this fixture must produce such cells');
%! if res.ok
%!   assert(res.grid.nCross(res.iD, res.iP) == 1, 'the chosen cell must cross once');
%! end
%! bad = res.grid.nCross > 1;
%! assert(~any(res.grid.okMask(bad)), 'no multi-crossing cell may be admissible');

%!test
%! % The D noise budget is measured, not inferred: axisD is in the log and D
%! % scales it linearly, so the headroom against pidsum_limit is arithmetic.
%! % This is the opposite of what went wrong in #5258.
%! fix = mkfix('k', 67.2743, 'tau', 0.006, 'P', 40, 'D', 15, 'axisD', 700);
%! res = PSautotuneSearch(fix, struct('pmTarget', 60));
%! assert(res.ok, res.reason);
%! assert(res.gains.D <= 15, 'raising D past the pidsum headroom is not allowed');
%! assert(~isempty(strfind(lower(strjoin(res.notes, ' ')), 'pidsum')), ...
%!        'the budget must say when it bound');

%!test
%! % I moves with P, because Ki in the firmware is absolute. Holding I while
%! % cutting P drags the PI corner upwards, so the integrator contributes more
%! % lag exactly where the scan is trying to buy phase margin. Measured on the
%! % pichim corpus: with I held, one craft tops out at 45.2 deg of reachable
%! % phase margin however far P is cut, and clears 69.9 deg once I follows.
%! res = PSautotuneSearch(mkfix('P', 80, 'I', 120), struct('pmTarget', 60));
%! assert(res.ok, res.reason);
%! assert(res.gains.I ~= 120, 'I has to move when P does');
%! assert(abs(res.scale.I - res.scale.P) < 0.02, ...
%!        sprintf('I scaled %.3f against P %.3f - the integral time must hold', ...
%!                res.scale.I, res.scale.P));

%!test
%! % Reason codes have to be usable by the UI without guessing
%! r = PSautotuneSearch(mkfix('P', 40), struct('pmTarget', 60, 'pClamp', [1 1]));
%! assert(strcmp(r.reason, 'already-tuned') || strcmp(r.reason, 'ok'));
%! r2 = PSautotuneSearch(mkfix(), struct('pmTarget', 179));
%! assert(~r2.ok);
%! assert(strcmp(r2.reason, 'no-candidate'), sprintf('reason was %s', r2.reason));

%!test
%! % Margins are recomputed from the integer gains that the CLI will actually
%! % set, not from the scale factor that found them
%! res = PSautotuneSearch(mkfix(), struct('pmTarget', 50));
%! g = struct('axis', 0, 'P', res.gains.P, 'I', res.gains.I, ...
%!            'D', res.gains.D, 'F', res.gains.F);
%! id = mkfix();
%! keep = id.freq > 0 & id.freq <= id.fTrust;
%! [A, D, F] = PSbuildController(g, id.fp, id.FsPid, id.freq(keep));
%! [~, L] = PSpredictClosedLoop(id.G_plant(keep), A, D, F);
%! [gm, pm, wcg, wcp] = PSmarginsFromL(id.freq(keep), L);
%! assert(abs(pm - res.pm) < 1e-9, 'reported PM must come from the integer gains');
%! assert(abs(wcp - res.wcp) < 1e-9, 'reported crossover likewise');
