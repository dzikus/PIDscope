% test_PSautotuneGates.m - what has to be true of a log before autotune may answer
%
% The gates judge the measurement; the scan's constraints judge the loop. Every
% threshold with a number in it is either structural (the log cannot mean
% anything else) or was read off the pichim corpus - 18 axes over 6 logs from 3
% airframes - and the reading is written next to it.

%!function id = mkid(varargin)
%!  p = struct('P', 46, 'I', 66, 'D', 32, 'F', 0, 'dMax', 0, ...
%!             'ok', true, 'msg', '', 'nSeg', 70, 'fTrust', 125, ...
%!             'gyroVar', 5e5, 'satFrac', 0, 'durSec', 20, 'chirpTime', 20, ...
%!             'thrStd', 8, 'coh', 0.99, 'FsPid', 2000);
%!  for j = 1:2:numel(varargin), p.(varargin{j}) = varargin{j+1}; end
%!  freq = (0:0.4:400)';
%!  id = struct('ok', p.ok, 'msg', p.msg, 'freq', freq, ...
%!              'G_track', ones(size(freq)), ...
%!              'C_track', p.coh*ones(size(freq)), ...
%!              'G_plant', ones(size(freq)), 'G_uw', ones(size(freq)), ...
%!              'C_uw', p.coh*ones(size(freq)), 'G_ff', [], ...
%!              'gains', struct('axis',0,'P',p.P,'I',p.I,'D',p.D,'F',p.F,'dMax',p.dMax), ...
%!              'fp', [], 'FsPid', p.FsPid, 'axisIdx', 0, 'axisName', 'Roll', ...
%!              'i0', 1, 'i1', 40000, 'nSamp', 40000, 'durSec', p.durSec, ...
%!              'chirpTime', p.chirpTime, 'gyroVar', p.gyroVar, ...
%!              'satFrac', p.satFrac, 'thrStd', p.thrStd, ...
%!              'nSeg', p.nSeg, 'fTrust', p.fTrust, 'axisD', ones(100,1), ...
%!              'pidsumLimit', 800);
%!endfunction

%!test
%! % A log like the ones in the corpus passes every gate
%! [ok, msgs] = PSautotuneGates(mkid());
%! assert(ok, sprintf('a good log was refused: %s', strjoin(msgs, '; ')));
%! assert(isempty(msgs));

%!test
%! % Identification having failed is itself a refusal, and its reason carries
%! % through rather than being replaced by a gate's wording
%! [ok, msgs] = PSautotuneGates(mkid('ok', false, 'msg', 'No chirp data found'));
%! assert(~ok);
%! assert(~isempty(strfind(strjoin(msgs, ' '), 'No chirp data found')));

%!test
%! % An axis that was not swept. Measured on the corpus: the swept axis scores
%! % 3.6e5 to 5.8e5, while cross-axis coupling during another axis's run reaches
%! % 1365 - so the old floor of 500 sat inside the coupling, not above it.
%! [ok, msgs] = PSautotuneGates(mkid('gyroVar', 1365));
%! assert(~ok, 'cross-axis coupling must not read as a swept axis');
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'swept')));
%! [ok2, ~] = PSautotuneGates(mkid('gyroVar', 3.6e5));
%! assert(ok2, 'a genuinely swept axis must pass');

%!test
%! % A sweep that was cut short never reached the top of the band, and fTrust
%! % off it still looks perfectly reasonable - which is what makes it dangerous
%! [ok, msgs] = PSautotuneGates(mkid('durSec', 11, 'chirpTime', 20));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'sweep')));
%! [ok2, ~] = PSautotuneGates(mkid('durSec', 19.5, 'chirpTime', 20));
%! assert(ok2, '0.95 of the sweep is enough');

%!test
%! % Saturation means the loop was not linear, so the plant measured through it
%! % is a fiction. Every axis in the corpus measured exactly zero, so any real
%! % fraction is already abnormal.
%! [ok, msgs] = PSautotuneGates(mkid('satFrac', 0.02));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'satur')));

%!test
%! % Too few Welch segments to average. The corpus runs 70 on every axis, so 3
%! % means something went wrong with the window rather than with the flying.
%! [ok, msgs] = PSautotuneGates(mkid('nSeg', 3));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'average')));

%!test
%! % A trust band too narrow to hold a loop. The corpus runs 106 to 164 Hz.
%! [ok, msgs] = PSautotuneGates(mkid('fTrust', 30));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'band')));

%!test
%! % Coherence gate: the corpus sits at 0.999 median, so 0.5 is plainly broken
%! [ok, msgs] = PSautotuneGates(mkid('coh', 0.5));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'coherence')));
%! [ok2, ~] = PSautotuneGates(mkid('coh', 0.9));
%! assert(ok2);

%!test
%! % Gains that cannot be scaled
%! [okP, mP] = PSautotuneGates(mkid('P', 0));
%! assert(~okP);
%! [okI, mI] = PSautotuneGates(mkid('I', 0));
%! assert(~okI);
%! assert(~isempty(strfind(lower(strjoin([mP mI], ' ')), 'gain')));

%!test
%! % Dynamic D is a warning, not a refusal - and it has to reach the scan as a
%! % clamp, because the model only covers the static value
%! [ok, msgs, info] = PSautotuneGates(mkid('D', 20, 'dMax', 35));
%! assert(ok, 'dynamic D must not refuse the axis');
%! assert(~isempty(msgs), 'but it must warn');
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'dynamic')));
%! assert(info.dClampHi == 1.0, 'and hold D at or below what was flown');
%! [~, ~, info2] = PSautotuneGates(mkid('D', 20, 'dMax', 0));
%! assert(info2.dClampHi > 1.0, 'static D keeps the normal headroom');

%!test
%! % An implausible loop rate means the header was misread, and everything
%! % derived from it - the whole controller model - is wrong with it
%! [ok, msgs] = PSautotuneGates(mkid('FsPid', 60));
%! assert(~ok);
%! assert(~isempty(strfind(lower(strjoin(msgs, ' ')), 'loop rate')));

%!test
%! % Thresholds are echoed so they can be read back off a log rather than
%! % guessed at again later
%! [~, ~, info] = PSautotuneGates(mkid());
%! for f = {'gyroVarMin','satFracMax','nSegMin','fTrustMin','cohMin','sweepFrac'}
%!   assert(isfield(info, f{1}), sprintf('info must echo %s', f{1}));
%! end
%! % and they can be overridden, so a stricter caller is possible without an edit
%! [ok, ~] = PSautotuneGates(mkid('fTrust', 80), struct('fTrustMin', 100));
%! assert(~ok, 'a caller-supplied threshold must actually bind');
