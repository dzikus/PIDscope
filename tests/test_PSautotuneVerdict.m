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
%! % Ms alone is not a verdict. On the corpus a well flown axis reaches 2.23 and
%! % a badly flown one sits at 2.12, so no Ms line separates them - it stays a
%! % backstop for the extreme, not the headline.
%! [~, ~, info] = PSautotuneVerdict(mkid());
%! assert(info.msMax >= 2.5, 'Ms must not be the tight test any more');
%! assert(isfield(info, 'ms') && isfinite(info.ms), 'but it is still reported');

%!test
%! % Everything measured is handed back so the window can say why
%! [~, ~, info] = PSautotuneVerdict(mkid());
%! for f = {'pm', 'ms', 'peakDb', 'overshoot', 'pmFloor', 'peakDbMax', 'overshootMax'}
%!   assert(isfield(info, f{1}), sprintf('info must carry %s', f{1}));
%! end

%!test
%! % No plant means no verdict, and it must say so rather than guess
%! bad = mkid();
%! bad.G_plant = [];
%! [needs, msgs] = PSautotuneVerdict(bad);
%! assert(~needs);
%! assert(~isempty(msgs), 'it must explain why it cannot judge');
