function [ok, msgs, info] = PSautotuneGates(id, opt)
%% PSautotuneGates - whether a measurement is fit to tune from
%  id   - from PSidentifyChirp
%  opt  - threshold overrides; every threshold is echoed in info
%
%  ok   - false when the axis must be refused
%  msgs - what to tell the pilot; non-empty with ok true means a warning
%  info - the thresholds that were applied, plus what the log actually scored
%
%  These judge the measurement. The scan's own constraints judge the loop, and
%  the two must not be confused: a log can be perfectly measured and still have
%  no admissible tune, which is a different answer from "this log cannot be
%  read".
%
%  The numbers come from the pichim corpus - 18 axes across 6 logs from 3
%  airframes - except where marked structural, meaning the log cannot mean
%  anything else.

if nargin < 2 || isempty(opt), opt = struct(); end

o = struct('gyroVarMin', 500, ...   % swept axes score 3523..6188, coupling reaches 137
           'sweepFrac', 0.95, ...   % structural: a short sweep has no top of band
           'satFracMax', 0.01, ...  % structural: saturation makes the plant a fiction
           'nSegMin', 8, ...        % the corpus runs 70 on every axis
           'cohMin', 0.78, ...      % the corpus sits at 0.999 median
           'fTrustMin', 60, ...     % the corpus runs 106..164 Hz
           'FsPidRange', [500 16000]);
fn = fieldnames(o);
for k = 1:numel(fn)
    if isfield(opt, fn{k}) && ~isempty(opt.(fn{k})), o.(fn{k}) = opt.(fn{k}); end
end

info = o;
info.dClampHi = 1.25;
info.gyroVar = getf(id, 'gyroVar');
info.satFrac = getf(id, 'satFrac');
info.thrStd = getf(id, 'thrStd');   % carried, not gated: no failing log measured yet
info.nSeg = getf(id, 'nSeg');
info.fTrust = getf(id, 'fTrust');
info.cohMedian = NaN;

msgs = {};
ok = false;

if ~isfield(id, 'ok') || ~id.ok
    msgs{end+1} = id.msg;
    return
end

if isempty(id.G_plant)
    msgs{end+1} = 'The PID terms are not in this log, so the plant cannot be measured';
    return
end

if ~(id.gains.P > 0 && id.gains.I > 0)
    msgs{end+1} = 'P and I must both be non-zero for a gain to be scaled';
    return
end

if ~(id.FsPid >= o.FsPidRange(1) && id.FsPid <= o.FsPidRange(2))
    msgs{end+1} = sprintf('Loop rate reads %g Hz, which is outside %g..%g', ...
                          id.FsPid, o.FsPidRange(1), o.FsPidRange(2));
    return
end

if ~(info.gyroVar > o.gyroVarMin)
    msgs{end+1} = sprintf(['This axis was not swept in the run that was picked ' ...
                           '(gyro variance %.0f, needs %.0f)'], info.gyroVar, o.gyroVarMin);
    return
end

if ~(id.durSec >= o.sweepFrac * id.chirpTime)
    msgs{end+1} = sprintf('The sweep stopped after %.1f s of %.1f s, so the top of the band is missing', ...
                          id.durSec, id.chirpTime);
    return
end

if ~(info.satFrac < o.satFracMax)
    msgs{end+1} = sprintf(['The PID sum saturated for %.1f%% of the run, so the loop ' ...
                           'was not linear and the plant measured through it is not real'], ...
                          100*info.satFrac);
    return
end

if ~(info.nSeg >= o.nSegMin)
    msgs{end+1} = sprintf('Only %d segments to average, needs %d', info.nSeg, o.nSegMin);
    return
end

if ~(info.fTrust >= o.fTrustMin)
    msgs{end+1} = sprintf('The trusted band ends at %.0f Hz, needs %.0f', ...
                          info.fTrust, o.fTrustMin);
    return
end

% the plant is G_track/G_uw, so judge it on the worse of the two. The upper edge
% follows fTrust, otherwise this and the trust band gate measure the same thing
% twice and on a 107 Hz log this one becomes unreachable.
hi = min(150, info.fTrust);
band = id.freq > 2 & id.freq <= hi;
if any(band)
    C = id.C_track;
    if ~isempty(id.C_uw), C = min(id.C_track, id.C_uw); end
    info.cohMedian = median(C(band));
end
if ~(info.cohMedian >= o.cohMin)
    msgs{end+1} = sprintf('Plant coherence is %.2f over 2..%.0f Hz, needs %.2f', ...
                          info.cohMedian, hi, o.cohMin);
    return
end

ok = true;

% dynamic D is a warning: the log records the floor of a D that moved, and the
% controller model only covers the static value
if isfield(id.gains, 'dMax') && ~isempty(id.gains.dMax) && id.gains.dMax > id.gains.D
    info.dClampHi = 1.0;
    msgs{end+1} = sprintf(['Dynamic D was active (d_max %g above D %g), so D is held ' ...
                           'at or below what was flown'], id.gains.dMax, id.gains.D);
end

end


function v = getf(s, f)
    v = NaN;
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); end
end
