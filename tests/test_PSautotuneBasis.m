% test_PSautotuneBasis.m - the controller family as four fixed responses

%!test
%! % The whole scan rests on this: every gain enters PSbuildController as a
%! % plain scalar multiplier, so two calls reproduce any candidate. A nonlinear
%! % term added there later would corrupt every cell of the scan silently, so
%! % pin it against direct builds across axes and across the ends of the range.
%! Fs = 2000; freq = (0:0.4:1000)';
%! fp = struct('dterm_lpf1_type',0,'dterm_lpf1_hz',80, ...
%!             'dterm_lpf2_type',3,'dterm_lpf2_hz',120, ...
%!             'dterm_notch_hz',350,'dterm_notch_cut',260);
%! tuples = [40 60 25 90; 1 0 0 0; 0 1 0 0; 120 200 55 0; 0 0 0 0];
%! for axis = 0:2
%!   b = PSautotuneBasis(struct('axis', axis), fp, Fs, freq);
%!   for r = 1:rows(tuples)
%!     g = struct('axis', axis, 'P', tuples(r,1), 'I', tuples(r,2), ...
%!                'D', tuples(r,3), 'F', tuples(r,4));
%!     [A, D, F] = PSbuildController(g, fp, Fs, b.freq);
%!     eA = max(abs(A - (g.P*b.Ap + g.I*b.Ai))) / max(1, max(abs(A)));
%!     eD = max(abs(D - g.D*b.D1)) / max(1, max(abs(D)));
%!     eF = max(abs(F - g.F*b.F1)) / max(1, max(abs(F)));
%!     assert(eA < 1e-12, sprintf('axis %d row %d: A off by %g', axis, r, eA));
%!     assert(eD < 1e-12, sprintf('axis %d row %d: D off by %g', axis, r, eD));
%!     assert(eF < 1e-12, sprintf('axis %d row %d: F off by %g', axis, r, eF));
%!   end
%! end

%!test
%! % DC is dropped, because there the integrator is Inf and a candidate with
%! % I = 0 would ask for 0*Inf
%! Fs = 2000; freq = (0:0.4:1000)';
%! b = PSautotuneBasis(struct('axis',0), [], Fs, freq);
%! assert(all(b.freq > 0), 'DC must not reach the basis');
%! assert(numel(b.freq) == numel(freq) - 1);
%! assert(isequal(freq(b.keep), b.freq), 'keep must map back onto the input grid');
%! assert(all(isfinite(b.Ap)) && all(isfinite(b.Ai)));
%! assert(all(isfinite(b.D1)) && all(isfinite(b.F1)));
%! assert(all(isfinite(0*b.Ai)), 'an I-free candidate must stay finite');

%!test
%! % Yaw runs 2.5x the I gain (pid_init.c:378); losing that in the basis would
%! % make every yaw candidate wrong by the same factor and still look plausible
%! Fs = 2000; freq = (0:0.4:1000)';
%! bR = PSautotuneBasis(struct('axis',0), [], Fs, freq);
%! bY = PSautotuneBasis(struct('axis',2), [], Fs, freq);
%! assert(max(abs(bY.Ai - 2.5*bR.Ai)) < 1e-12 * max(abs(bR.Ai)));
%! assert(max(abs(bY.Ap - bR.Ap)) < 1e-12 * max(1, max(abs(bR.Ap))), 'P is not scaled');

%!test
%! % The dterm filter chain lives inside the basis. A scan that assumed an ideal
%! % Kd*s would promise phase lead the hardware does not have - which is the
%! % whole risk behind moving D at all.
%! Fs = 2000; freq = (0:0.4:1000)';
%! fp = struct('dterm_lpf1_type',0,'dterm_lpf1_hz',0, ...
%!             'dterm_lpf2_type',3,'dterm_lpf2_hz',120, ...
%!             'dterm_notch_hz',0,'dterm_notch_cut',0);
%! bF = PSautotuneBasis(struct('axis',0), fp, Fs, freq);
%! bN = PSautotuneBasis(struct('axis',0), [], Fs, freq);
%! k = find(bF.freq >= 200, 1);
%! assert(abs(bF.D1(k)) < 0.5 * abs(bN.D1(k)), 'PT3 at 120 Hz must show up at 200 Hz');
%! j = find(bF.freq >= 5, 1);
%! assert(abs(bF.D1(j)) > 0.95 * abs(bN.D1(j)), 'and must not bite at 5 Hz');

%!test
%! % tpa carries through, because it scales P and D but never I
%! Fs = 2000; freq = (0:0.4:1000)';
%! b1 = PSautotuneBasis(struct('axis',0), [], Fs, freq);
%! b2 = PSautotuneBasis(struct('axis',0,'tpa',0.6), [], Fs, freq);
%! assert(max(abs(b2.Ap - 0.6*b1.Ap)) < 1e-12 * max(1, max(abs(b1.Ap))));
%! assert(max(abs(b2.D1 - 0.6*b1.D1)) < 1e-12 * max(abs(b1.D1)));
%! assert(max(abs(b2.Ai - b1.Ai)) < 1e-12 * max(abs(b1.Ai)), 'tpa must not touch I');
