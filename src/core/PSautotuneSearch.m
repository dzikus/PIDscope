function res = PSautotuneSearch(id, opt)
%% PSautotuneSearch - the P and D that widen the loop without spending its margins
%  id  - from PSidentifyChirp
%  opt - thresholds, all exposed so they can be read off logs known to be good
%        and known to be bad before anyone freezes them
%
%  Maximises the 0 dB crossover under hard limits on phase margin, the
%  sensitivity peak and the closed loop peak. The condition is PM >= target, not
%  PM == target: on a discrete grid equality is brittle, and maximising
%  bandwidth presses PM down onto the target by itself. When something other
%  than PM binds, the answer comes out more conservative rather than not coming
%  out at all.
%
%  res.gains carries P, I, D and F and nothing else. Betaflight issue #5258 was
%  a filter cutoff derived from chirp coherence; here there is nowhere to put
%  one.

if nargin < 2 || isempty(opt), opt = struct(); end

o = struct('pmTarget', 60, 'msMax', 2.0, 'peakMaxDb', 6, ...
           'magAtTrustDb', -6, 'wcpFracTrust', 0.5, 'wcpMaxRatio', 3, ...
           'dDomRatio', 2.0, ...
           'pClamp', [0.25 2.0], 'dClamp', [0.6 1.25], 'pidsumFrac', 0.9, ...
           'peakStepMin', 1.05);
fn = fieldnames(o);
for k = 1:numel(fn)
    if isfield(opt, fn{k}) && ~isempty(opt.(fn{k})), o.(fn{k}) = opt.(fn{k}); end
end

res = blank();
res.opt = o;
res.notes = {};

P0 = id.gains.P; I0 = id.gains.I; D0 = id.gains.D; F0 = id.gains.F;
res.gains = struct('axis', id.gains.axis, 'P', P0, 'I', I0, 'D', D0, 'F', F0);

% the loop may only be evaluated where the plant was measured
keep = id.freq > 0 & id.freq <= id.fTrust;
if sum(keep) < 16
    res.reason = 'no-candidate';
    res.notes{end+1} = 'trust band too narrow to evaluate a loop in';
    return
end
fk = id.freq(keep);
Pk = id.G_plant(keep);

b = PSautotuneBasis(id.gains, id.fp, id.FsPid, fk);

base = evalOne(Pk, fk, P0*b.Ap + I0*b.Ai, D0*b.D1, F0*b.F1);
res.pm0 = base.pm; res.gm0 = base.gm; res.ms0 = base.ms;
res.wcp0 = base.wcp; res.wcg0 = base.wcg; res.peakDb0 = base.peakDb;

if isnan(base.wcp)
    res.reason = 'no-crossover';
    res.notes{end+1} = 'the flown loop never crosses 0 dB inside the trust band';
    return
end

dHi = o.dClamp(2);
if D0 > 0 && isfield(id.gains, 'dMax') && ~isempty(id.gains.dMax) && id.gains.dMax > D0
    % the log records the floor of a D that moved; the controller model only
    % covers the static value, so raising it would be raising something else
    dHi = min(dHi, 1.0);
    res.notes{end+1} = 'dynamic D was active, so D is held at or below the logged value';
end
if D0 > 0 && ~isempty(id.axisD) && isfinite(id.pidsumLimit) && id.pidsumLimit > 0
    peakD = max(abs(id.axisD));
    if peakD > 0
        sBudget = o.pidsumFrac * id.pidsumLimit / peakD;
        if sBudget < dHi
            dHi = max(o.dClamp(1), sBudget);
            res.notes{end+1} = sprintf('D capped at %.2fx by the measured pidsum budget', dHi);
        end
    end
end

% Walk whole gains rather than scale factors. A scale grid aliases onto the
% integers unevenly, so the same craft answered differently depending only on
% where the grid happened to start - 32 of 54 answers on the pichim corpus
% moved by one count when the lower clamp changed.
Pcand = max(1, round(o.pClamp(1)*P0)) : round(o.pClamp(2)*P0);
Dcand = round(o.dClamp(1)*D0) : round(dHi*D0);
if isempty(Pcand), Pcand = max(1, P0); end
if isempty(Dcand), Dcand = D0; end

nD = numel(Dcand); nP = numel(Pcand);
g = struct();
g.okMask = false(nD, nP);
g.pm = nan(nD, nP);  g.ms = nan(nD, nP);  g.wcp = nan(nD, nP);
g.gm = nan(nD, nP);  g.peakDb = nan(nD, nP);  g.nCross = zeros(nD, nP);
g.magTrustDb = nan(nD, nP); g.dRatio = nan(nD, nP);
g.P = zeros(nD, nP); g.I = zeros(nD, nP); g.D = zeros(nD, nP);

for iD = 1:nD
    Di = Dcand(iD);
    Dv = Di * b.D1;
    for iP = 1:nP
        Pi = Pcand(iP);
        % Ki in the firmware is absolute, so holding I while cutting P drags
        % the PI corner upwards and the integrator adds lag exactly where the
        % scan is trying to buy phase margin. Scaling both keeps the integral
        % time the pilot flew.
        Ii = I0;
        if P0 > 0, Ii = round(Pi / P0 * I0); end
        c = evalOne(Pk, fk, Pi*b.Ap + Ii*b.Ai, Dv, F0*b.F1);
        g.P(iD,iP) = Pi; g.I(iD,iP) = Ii; g.D(iD,iP) = Di;
        g.pm(iD,iP) = c.pm; g.ms(iD,iP) = c.ms; g.wcp(iD,iP) = c.wcp;
        g.gm(iD,iP) = c.gm; g.peakDb(iD,iP) = c.peakDb;
        g.nCross(iD,iP) = c.nCross;
        g.magTrustDb(iD,iP) = c.magTrustDb; g.dRatio(iD,iP) = c.dRatio;
        g.okMask(iD,iP) = Pi >= 1 && admissible(c, o, id.fTrust, base.wcp);
    end
end

% A cell with no admissible neighbour is a one-point island: rounding to whole
% gains put it there and a neighbouring log would not reproduce it. Requiring
% every neighbour instead would back the answer off by one grid step, which
% would make the proposal depend on how finely the grid was drawn.
sel = g.okMask & (neighbourCount(g.okMask) >= 1 | numel(g.okMask) == 1);
if ~any(sel(:))
    res.reason = 'no-candidate';
    res.notes{end+1} = 'nothing on the grid clears the targets';
    res.grid = g;
    return
end

wcp = g.wcp; wcp(~sel) = -Inf;
best = max(wcp(:));
tie = sel & (wcp >= best * 0.99);
[iDs, iPs] = find(tie);
kD = Dcand(iDs); kP = Pcand(iPs);
[~, pick] = sortrows([kD(:), kP(:)], [1 2]);
iD = iDs(pick(1)); iP = iPs(pick(1));

res.iD = iD; res.iP = iP;
res.grid = g;
res.gains.P = g.P(iD,iP);
res.gains.I = g.I(iD,iP);
res.gains.D = g.D(iD,iP);

% D acts on the gyro only, so the tracking response is P*A/(1+P*(A+D)) and the
% PI zero at Ki/Kp sits in the numerator where the margins never see it.
% Measured on the pichim corpus: at a fixed cell, I moved the step overshoot
% from 1.11 to 1.17 while the phase margin moved 0.6 deg and Ms not at all.
% So take the most I that does not make the step worse than it already flies -
% I is what rejects disturbances, and it is nearly free of the margins.
[res.gains.I, res.peak, res.peak0] = shapeI(id, res.gains, I0, o, base.wcp);
if isfinite(res.peak) && isfinite(res.peak0) && res.peak > max(res.peak0, o.peakStepMin) + 1e-6
    res.notes{end+1} = sprintf(['step overshoot still %.0f%% against %.0f%% flown - ' ...
                                'the margins would not allow less I'], ...
                               100*(res.peak-1), 100*(res.peak0-1));
end
res.scale = struct('P', ratio(res.gains.P, P0), 'I', ratio(res.gains.I, I0), ...
                   'D', ratio(res.gains.D, D0), 'F', 1);

% report what the CLI will actually set, not what the scale factor found
fin = evalOne(Pk, fk, res.gains.P*b.Ap + res.gains.I*b.Ai, ...
              res.gains.D*b.D1, res.gains.F*b.F1);
res.pm = fin.pm; res.gm = fin.gm; res.ms = fin.ms;
res.wcp = fin.wcp; res.wcg = fin.wcg; res.peakDb = fin.peakDb;

res.ok = true;
if res.gains.P == P0 && res.gains.I == I0 && res.gains.D == D0
    res.reason = 'already-tuned';
else
    res.reason = 'ok';
end

end


function [Ibest, pk, pk0] = shapeI(id, gains, I0, o, wcp0)
    Ibest = gains.I;
    pk0 = stepPeak(id, id.gains);
    pk = stepPeak(id, gains);
    if I0 <= 0 || ~isfinite(pk0) || ~isfinite(pk), return; end
    limit = max(pk0, o.peakStepMin);
    if pk <= limit, return; end

    keep = id.freq > 0 & id.freq <= id.fTrust;
    fk = id.freq(keep);
    Pk = id.G_plant(keep);

    % walk I down, but only over values that still clear every constraint - an
    % I that fixes the step and loses the margin is not an answer
    for Ii = (gains.I-1):-1:max(1, round(0.2*I0))
        trial = gains; trial.I = Ii;
        [A, D, F] = PSbuildController(trial, id.fp, id.FsPid, fk);
        if ~admissible(evalOne(Pk, fk, A, D, F), o, id.fTrust, wcp0), continue; end
        p = stepPeak(id, trial);
        if p < pk, Ibest = Ii; pk = p; end
        if p <= limit, break; end
    end
end


function pk = stepPeak(id, gains)
    pk = NaN;
    if isempty(id.G_plant), return; end
    [A, D, F] = PSbuildController(gains, id.fp, id.FsPid, id.freq);
    Tp = PSpredictClosedLoop(id.G_plant, A, D, F);
    [~, s] = PSstepFromFRD(id.freq, Tp, min(id.fTrust, 300));
    if isempty(s), return; end
    pk = max(s);
end


function ok = admissible(c, o, fTrust, wcp0)
    ok = ~isnan(c.pm) && c.pm >= o.pmTarget ...
         && c.ms <= o.msMax ...
         && c.peakDb <= o.peakMaxDb ...
         && c.nCross == 1 ...
         && c.magTrustDb <= o.magAtTrustDb ...
         && c.wcp <= o.wcpFracTrust * fTrust ...
         && c.wcp <= o.wcpMaxRatio * wcp0 ...
         && c.dRatio <= o.dDomRatio;
end


function c = evalOne(P, freq, A, D, F)
    [T, L, S] = PSpredictClosedLoop(P, A, D, F);
    [c.gm, c.pm, c.wcg, c.wcp] = PSmarginsFromL(freq, L);
    c.ms = max(abs(S));
    c.peakDb = 20*log10(max(abs(T)) + 1e-12);
    magDb = 20*log10(abs(L) + 1e-12);
    c.nCross = sum(diff(sign(magDb)) ~= 0);
    c.magTrustDb = magDb(end);
    % How far the derivative may outweigh the PI part at the crossover. Lead
    % beyond this rests the loop on the modelled D chain instead of on the
    % measured plant. Flown Betaflight tunes sit higher here than one might
    % guess: across the 18 axes of the pichim corpus the ratio runs 0.10 to
    % 1.90, median 1.62, so a limit of 1 would reject every roll and pitch tune
    % in it - including the craft of the author of the chirp tooling.
    c.dRatio = 0;
    if ~isnan(c.wcp)
        aW = interp1(freq, abs(A), c.wcp, 'linear');
        dW = interp1(freq, abs(D), c.wcp, 'linear');
        c.dRatio = dW / max(aW, 1e-12);
    end
end


function n = neighbourCount(m)
    n = zeros(size(m));
    n(2:end,:)   = n(2:end,:)   + m(1:end-1,:);
    n(1:end-1,:) = n(1:end-1,:) + m(2:end,:);
    n(:,2:end)   = n(:,2:end)   + m(:,1:end-1);
    n(:,1:end-1) = n(:,1:end-1) + m(:,2:end);
end


function r = ratio(new, old)
    r = 1;
    if old ~= 0, r = new / old; end
end


function res = blank()
    res = struct('ok', false, 'reason', 'no-candidate', ...
                 'gains', [], 'scale', [], 'notes', {{}}, ...
                 'pm', NaN, 'gm', NaN, 'ms', NaN, 'wcp', NaN, 'wcg', NaN, ...
                 'peakDb', NaN, 'peak', NaN, 'peak0', NaN, ...
                 'pm0', NaN, 'gm0', NaN, 'ms0', NaN, 'wcp0', NaN, ...
                 'wcg0', NaN, 'peakDb0', NaN, ...
                 'iD', NaN, 'iP', NaN, 'grid', [], 'opt', []);
end
