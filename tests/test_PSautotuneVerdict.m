% test_PSautotuneVerdict.m - does this tune need changing at all?
%
% Thresholds are read off the pichim corpus, 18 axes over 6 logs. Sixteen of
% them are well flown and two (20250918_aosmini_01 roll and pitch) plainly are
% not. Any limit worth having must separate those two groups; Ms does not,
% because its range overlaps them completely.

%!function id = mkid(varargin)
%!  p = struct('tau', 0.002, 'k', 180.13977, 'P', 46, 'I', 66, 'D', 0, 'F', 0, ...
%!             'dMax', 0, 'fTrust', 300);
%!  for j = 1:2:numel(varargin), p.(varargin{j}) = varargin{j+1}; end
%!  freq = (0:0.2:600)';
%!  w = 2*pi*freq;
%!  G = p.k * exp(-1j*w*p.tau) ./ (1j*w);
%!  G(1) = 1e9;
%!  id = struct('ok', true, 'msg', '', 'freq', freq, 'G_plant', G, ...
%!              'G_track', [], 'C_track', ones(size(freq)), 'G_uw', [], ...
%!              'C_uw', [], 'G_ff', [], 'fp', [], 'FsPid', 2000, ...
%!              'gains', struct('axis',0,'P',p.P,'I',p.I,'D',p.D,'F',p.F,'dMax',p.dMax), ...
%!              'axisIdx', 0, 'axisName', 'Roll', 'fTrust', p.fTrust, ...
%!              'i0', 1, 'i1', 100, 'nSamp', 100, 'durSec', 20, 'chirpTime', 20, ...
%!              'gyroVar', 5e3, 'satFrac', 0, 'thrStd', 8, 'nSeg', 70, ...
%!              'axisD', ones(10,1), 'pidsumLimit', 800);
%!endfunction

%!test
%! % A loop with plenty of margin needs nothing said about it
%! [needs, msgs] = PSautotuneVerdict(mkid('P', 26));
%! assert(~needs, sprintf('a healthy tune was flagged: %s', strjoin(msgs, '; ')));
%! assert(isempty(msgs));

%!test
%! % Phase margin is what actually separated the corpus: the sixteen good axes
%! % run 38 to 82 deg, the two bad ones 25 and 29
%! [needs, msgs] = PSautotuneVerdict(mkid('P', 90));
%! assert(needs, 'a loop this tight must be flagged');
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'phase margin')));

%!test
%! % The floor is where it was measured to be, and it is settable
%! healthy = mkid('P', 26);
%! [a, ~, info] = PSautotuneVerdict(healthy);
%! assert(info.pmFloor == 35, 'the measured floor must be the default');
%! assert(~a, 'this fixture is the healthy one');
%! [b, msgs] = PSautotuneVerdict(healthy, struct('pmFloor', info.pm + 5));
%! assert(b, 'a floor above the measured margin must flag it');
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'phase margin')));

%!test
%! % Ms does not separate good tunes from bad ones: on 24 measured axes the good
%! % range 1.28..2.23 overlaps the bad 2.12..3.44. It stays as a backstop, so it
%! % may not be set tight enough to become the headline test.
%! [~, ~, info] = PSautotuneVerdict(mkid());
%! assert(info.msMax >= 2.5, 'Ms must not be the tight test');
%! assert(isfield(info, 'ms') && isfinite(info.ms), 'but it is still reported');
%! assert(info.pmFloor > 29 && info.pmFloor < 37.7, 'PM floor must sit in the gap');

%!test
%! % Step overshoot and the closed loop peak both come from T = P*(A+F)*S, which
%! % carries the modelled integrator. Rebuilding every logged PID term across all
%! % 15 chirp logs showed iterm_relax gates that integrator off on roll and pitch
%! % for the whole sweep - the logged axisI runs 6..74% of the integral of the
%! % error, and correlates with it as weakly as 0.29 - while yaw, which the
%! % mechanism does not touch, reconstructs at 1.00 with correlation 1.000.
%! % So neither number may decide anything. This loop has margin to spare and
%! % would still overshoot 28% on paper.
%! id = mkid('P', 20, 'I', 160);
%! [needs, msgs, info] = PSautotuneVerdict(id);
%! assert(info.pm > 38, sprintf('fixture must have margin, has %.1f', info.pm));
%! assert(info.ms < 2.3, sprintf('fixture must have a calm Ms, has %.2f', info.ms));
%! assert(info.overshoot > 0.25, ...
%!        sprintf('fixture must overshoot on paper, does %.0f%%', 100*info.overshoot));
%! assert(~needs, sprintf('a modelled overshoot must not flag a tune: %s', ...
%!                        strjoin(msgs, '; ')));

%!test
%! % The two contaminated numbers are still measured and handed to the window -
%! % they are worth showing - but there is no threshold left to compare them to
%! [~, ~, info] = PSautotuneVerdict(mkid());
%! for f = {'pm', 'ms', 'peakDb', 'overshoot', 'pmFloor', 'msMax'}
%!   assert(isfield(info, f{1}), sprintf('info must carry %s', f{1}));
%! end
%! for f = {'peakDbMax', 'overshootMax'}
%!   assert(~isfield(info, f{1}), ...
%!          sprintf('%s still exists, so something still gates on it', f{1}));
%! end

%!test
%! % No plant means no verdict, and it must say so rather than guess
%! bad = mkid();
%! bad.G_plant = [];
%! [needs, msgs] = PSautotuneVerdict(bad);
%! assert(~needs);
%! assert(~isempty(msgs), 'it must explain why it cannot judge');
