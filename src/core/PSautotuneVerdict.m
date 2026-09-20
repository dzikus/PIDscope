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
%  Thresholds come from every chirp log we have: 24 usable axes over 8 logs,
%  six airframes, four pilots, three firmware versions and two MCU families.
%  Four axes are plainly mistuned (20250918_aosmini_01 roll and pitch, galina_8
%  roll and pitch), the other twenty fly well.
%
%                    20 good axes      the 4 bad ones     separates?
%    phase margin    38.1 .. 86.5      23.2 .. 29.0       yes, clean gap
%    step overshoot   1 .. 15 %        22 .. 50 %         yes, gap 15-22
%    closed loop pk  0.36 .. 1.79 dB   1.76 .. 6.51 dB    no, they overlap
%    Ms              1.28 .. 2.23      2.12 .. 3.44       no, they overlap
%
%  So the verdict rests on phase margin and overshoot; the peak and Ms are kept
%  only to catch something extreme. Betaflight's own limit of Ms <= 2.0 is drawn
%  against a different quantity - their open loop is approximated as T/(1-T),
%  which reads about 0.74x our sensitivity peak and 25 deg more phase margin on
%  an axis with real D - so it cannot be carried over unchanged.

if nargin < 2 || isempty(opt), opt = struct(); end

o = struct('pmFloor', 35, 'peakDbMax', 3.0, 'overshootMax', 0.18, 'msMax', 2.7);
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
if info.peakDb > o.peakDbMax
    needsWork = true;
    msgs{end+1} = sprintf('The loop peaks %.1f dB above the setpoint, over %.1f dB', ...
                          info.peakDb, o.peakDbMax);
end
if isfinite(info.overshoot) && info.overshoot > o.overshootMax
    needsWork = true;
    msgs{end+1} = sprintf('A step overshoots by %.0f%%, over %.0f%%', ...
                          100*info.overshoot, 100*o.overshootMax);
end
if info.ms > o.msMax
    needsWork = true;
    msgs{end+1} = sprintf('Disturbances are amplified %.1fx at worst, over %.1fx', ...
                          info.ms, o.msMax);
end

end
