function [needsWork, msgs, info] = PSautotuneVerdict(id, opt)
%% PSautotuneVerdict - does the tune being flown actually need changing?
%  id   - from PSidentifyChirp
%  opt  - threshold overrides; every threshold is echoed in info
%
%  needsWork - true when the flown loop breaks a limit worth acting on
%  msgs      - what to tell the pilot, empty when there is nothing to say
%
%  Separate from the search, which answers "what else is reachable". A loop can
%  be perfectly healthy and still have a faster tune available; that is an
%  option, not advice.
%
%  Thresholds come from every chirp log we have: 41 usable axes over 11 logs,
%  eight airframes, four pilots, three firmware versions and two MCU families.
%  Four axes are plainly mistuned (20250918_aosmini_01 roll and pitch, galina_8
%  roll and pitch), the other thirty-seven fly well.
%
%                    37 good axes      the 4 bad ones     separates?
%    phase margin    37.7 .. 86.5      23.2 .. 29.0       yes, clean gap
%    Ms              1.28 .. 2.23      2.12 .. 3.44       no, they overlap
%
%  Step overshoot and the closed loop peak are measured and reported, but they
%  decide nothing. Both come from T = P*(A+F)*S, which carries the modelled
%  integrator, and a chirp cannot see that integrator on roll or pitch:
%  iterm_relax is on by default for exactly those two axes, and a sweep drives
%  the setpoint past its cutoff for the whole run. Rebuilding every logged PID
%  term across all 15 chirp logs put the running integrator at 6..74% of the
%  integral of the error on roll and pitch, correlating as weakly as 0.29, while
%  yaw - which the mechanism does not touch - reconstructed at 1.00 with
%  correlation 1.000. Gating on those two flagged 19 of 41 axes; phase margin and
%  Ms alone flag the same four known-bad axes and nothing else.
%
%  A setpoint step is itself a fast stick move, so iterm_relax acts during one
%  too and the full-I step is a run the craft never makes. A gust does see the
%  full integrator, but a gust enters at the plant output, so S describes it -
%  and Ms already measures S.
%
%  Betaflight's own limit of Ms <= 2.0 is drawn against a different quantity -
%  their open loop is approximated as T/(1-T), which reads about 0.74x our
%  sensitivity peak and 25 deg more phase margin on an axis with real D - so it
%  cannot be carried over unchanged.

if nargin < 2 || isempty(opt), opt = struct(); end

o = struct('pmFloor', 35, 'msMax', 2.7);
fn = fieldnames(o);
for k = 1:numel(fn)
    if isfield(opt, fn{k}) && ~isempty(opt.(fn{k})), o.(fn{k}) = opt.(fn{k}); end
end

info = o;
info.pm = NaN; info.ms = NaN; info.peakDb = NaN; info.overshoot = NaN;
msgs = {};
needsWork = false;

if ~isfield(id, 'ok') || ~id.ok || isempty(id.G_plant)
    msgs{end+1} = 'The plant was not measured, so this tune cannot be judged';
    return
end

keep = id.freq > 0 & id.freq <= id.fTrust;
if sum(keep) < 16
    msgs{end+1} = 'The trusted band is too narrow to judge this tune';
    return
end
fk = id.freq(keep);

[A, D, F] = PSbuildController(id.gains, id.fp, id.FsPid, fk);
[Tc, L, S] = PSpredictClosedLoop(id.G_plant(keep), A, D, F);
[~, info.pm] = PSmarginsFromL(fk, L);
info.ms = max(abs(S));
info.peakDb = 20*log10(max(abs(Tc)) + 1e-12);

[A, D, F] = PSbuildController(id.gains, id.fp, id.FsPid, id.freq);
Tf = PSpredictClosedLoop(id.G_plant, A, D, F);
[~, s] = PSstepFromFRD(id.freq, Tf, min(id.fTrust, 300));
if ~isempty(s), info.overshoot = max(s) - 1; end

if ~isnan(info.pm) && info.pm < o.pmFloor
    needsWork = true;
    msgs{end+1} = sprintf(['Phase margin is %.0f deg, below the %.0f deg this ' ...
                           'tool treats as the floor'], info.pm, o.pmFloor);
end
if info.ms > o.msMax
    needsWork = true;
    msgs{end+1} = sprintf('Disturbances are amplified %.1fx at worst, over %.1fx', ...
                          info.ms, o.msMax);
end

end
