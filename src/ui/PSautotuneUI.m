function PSautotuneUI(T, setupInfo, Fs, tIND, logName)
%% PSautotuneUI - what to change in your PID, read off a chirp log
%  T, setupInfo, Fs, tIND - as handed to the other tools
%  logName                - shown in the header, optional
%
%  Everything is worked out before the window opens, so it never appears with
%  empty rows. The flown value is printed once per gain and the three settings
%  print only what they would change it to. Stability margins live in the Chirp
%  Analysis window; this one answers what to type into the CLI, and shows what
%  each answer does to the step response.

if nargin < 5, logName = ''; end

th = PStheme();
fontsz = th.fontsz;

axNames = {'Roll', 'Pitch', 'Yaw'};
axCols = {th.axisRoll, th.axisPitch, th.axisYaw};
gainNames = {'P', 'I', 'D', 'FF'};
setNames = {'CALM', 'NORMAL', 'SHARP'};
setBlurb = {'most margin', 'recommended', 'least margin'};
setCols = {th.bodeCoherence, th.textAccent, th.btnReset};
targets = [72.5 60 50];

%% --- work it all out first ---
wb = [];
try wb = waitbar(0, 'Measuring the plant...'); catch, end
ids = [];
res = cell(3, 3);
stepDat = cell(1, 3);
gateMsg = {'', '', ''};
gateWarn = {'', '', ''};
gateOk = false(1, 3);
nStep = 12; done = 0;

for a = 1:3
    tick(done/nStep, sprintf('Measuring the %s plant...', lower(axNames{a})));
    id = PSidentifyChirp(T, setupInfo, Fs, tIND, a-1);
    if isempty(ids), ids = id; else, ids(a) = id; end
    done = done + 1;
end
for a = 1:3
    [gok, gmsgs, ginfo] = PSautotuneGates(ids(a));
    % a passing axis can still carry a message - dynamic D is a warning, not a
    % refusal. Conflating the two marked a usable axis unusable and, worse, kept
    % it out of the verdict entirely, so a craft with 23 deg of phase margin was
    % told nothing needed changing.
    gateOk(a) = gok;
    if gok
        gateWarn{a} = strjoin(gmsgs, '; ');
    else
        gateMsg{a} = strjoin(gmsgs, '; ');
        done = done + 3;
        continue
    end
    for s = 1:3
        tick(done/nStep, sprintf('Working out %s for %s...', setNames{s}, lower(axNames{a})));
        res{a,s} = PSautotuneSearch(ids(a), ...
            struct('pmTarget', targets(s), 'dClamp', [0.6 ginfo.dClampHi]));
        done = done + 1;
    end
    stepDat{a} = stepsFor(ids(a), res(a,:));
end
try close(wb); catch, end

%% --- then draw it ---
figName = 'Autotune';
old = findobj('Type', 'figure', 'Name', figName);
if ~isempty(old), close(old); end

screensz = get(0, 'ScreenSize');
fig = figure('Name', figName, 'NumberTitle', 'off', ...
    'Color', th.figBg, ...
    'Position', round([0 0 screensz(3) screensz(4)]));

plotL = 0.04; plotR = 0.585; colW = plotR - plotL;
topMargin = 0.03; botMargin = 0.06; rowGap = 0.045;
plotH = (1 - topMargin - botMargin - 2*rowGap) / 3;
plotB = [1-topMargin-plotH, 0, 0];
plotB(2) = plotB(1) - plotH - rowGap;
plotB(3) = plotB(2) - plotH - rowGap;

tShow = 250;    % the same window on every axis, so the three can be compared
customCol = th.btnDash6;
hCustom = zeros(1, 3);
axCustom = zeros(1, 3);
hEdit = zeros(3, 4);
hCustomInfo = [];

for a = 1:3
    ax = axes('Parent', fig, 'Units', 'normalized', ...
        'Position', [plotL plotB(a) colW plotH]);
    PSstyleAxes(ax, th);
    hold(ax, 'on');
    d = stepDat{a};
    if isempty(d)
        text(0.5, 0.5, gateMsg{a}, 'Parent', ax, 'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'Color', th.btnReset, 'FontSize', fontsz);
        set(ax, 'XTick', [], 'YTick', []);
    else
        line(ax, [0 tShow], [1 1], 'Color', th.bodeRef, 'LineStyle', ':');
        % legend off explicit handles - the reference line would otherwise take
        % the first entry and shift every label onto the wrong curve
        hs = plot(ax, d.t, d.y0, 'Color', th.textSecondary, 'LineWidth', 1.4, ...
                  'LineStyle', '--');
        leg = {'as flown'};
        % two settings can land on the same gains - on yaw Ms binds before the
        % phase margin does, so NORMAL and SHARP come out identical. Drawing
        % both would hide one curve completely under the other.
        for s = 1:3
            if isempty(d.y{s}), continue; end
            same = {};
            for s2 = (s+1):3
                if ~isempty(res{a,s}) && ~isempty(res{a,s2}) && ...
                   isequal(res{a,s}.gains, res{a,s2}.gains)
                    same{end+1} = setNames{s2};
                    d.y{s2} = [];
                end
            end
            nm = setNames{s};
            if ~isempty(same), nm = strjoin([{nm} same], ' = '); end
            hs(end+1) = plot(ax, d.t, d.y{s}, 'Color', setCols{s}, 'LineWidth', 1.6);
            leg{end+1} = nm;
        end
        % the try-it-yourself curve, empty until something is typed
        hCustom(a) = plot(ax, nan, nan, 'Color', customCol, 'LineWidth', 1.8);
        hs(end+1) = hCustom(a);
        leg{end+1} = 'custom';
        axCustom(a) = ax;
        set(ax, 'XLim', [0 tShow], 'YLim', [0 1.6]);
        hl = legend(ax, hs, leg, 'Location', 'southeast');
        try PSstyleLegend(hl, th); catch, end
        try set(hl, 'FontSize', fontsz+1); catch, end
    end
    set(get(ax, 'YLabel'), 'String', 'Step');
    if a == 3
        set(get(ax, 'XLabel'), 'String', 'Time (ms)');
    end
    title(ax, axNames{a}, 'Color', axCols{a});
end

%% --- control column ---
cpL = 0.615;
xGain = cpL + 0.028; wGain = 0.014;
xNow  = cpL + 0.044; wNow = 0.040;
xSet  = cpL + [0.090 0.146 0.202]; wSet = 0.052;
xCust = cpL + 0.262; wCust = 0.058;
wStep = 0.014;
xStep = xCust + wCust + [0.003 0.019];
stepLbl = {'-', '+'};
stepDir = [-1 1];
rh = 0.024; grpGap = 0.014; nGain = 4;
% banding so the eye keeps the row across the four numbers, with the
% recommended column a shade lighter still
band = {th.figBg, min(1, th.figBg + 0.022)};
cellBg = @(k, s) min(1, band{mod(k,2)+1} + 0.035*(s == 2));

txt = @(s, x, y, w, col, align, fs, wt, bg) uicontrol(fig, 'Style', 'text', ...
    'Units', 'normalized', 'String', s, 'Position', [x y w rh], 'FontSize', fs, ...
    'FontWeight', wt, 'HorizontalAlignment', align, ...
    'ForegroundColor', col, 'BackgroundColor', bg);

uicontrol(fig, 'Style', 'text', 'Units', 'normalized', 'String', 'Autotune', ...
    'Position', [cpL 0.948 0.14 0.032], 'FontSize', fontsz+3, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
txt(logName, cpL, 0.918, 0.340, th.textSecondary, 'left', fontsz, 'normal', th.figBg);

% The headline answers the only question most people open this window with, so
% it gets a band of its own - the previous version said it in body text the same
% size and colour as everything else, and it read as a caption.
[headline, bodyLines, allWell] = summaryLines();
bannerBg = th.bannerWarn; bannerFg = th.btnReset;
if allWell, bannerBg = th.bannerOk; bannerFg = th.bodeCoherence; end
% runs to the right edge of the table below it, steppers included, so the band
% reads as belonging to the column rather than stopping short of it
bannerW = 0.262 + 0.058 + 0.019 + 0.014;
uicontrol(fig, 'Style', 'text', 'Units', 'normalized', 'String', ['  ' headline], ...
    'Position', [cpL 0.862 bannerW 0.038], 'FontSize', fontsz+3, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', bannerFg, 'BackgroundColor', bannerBg);
uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'String', cellfun(@(s) ['  ' s], bodyLines, 'UniformOutput', false), ...
    'Position', [cpL 0.806 bannerW 0.056], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', bannerBg);

txt('now', xNow, 0.782, wNow, th.textSecondary, 'right', fontsz, 'bold', th.figBg);
for s = 1:3
    hdrBg = min(1, th.figBg + 0.035*(s == 2));
    txt(setNames{s}, xSet(s), 0.782, wSet, setCols{s}, 'right', fontsz+1, 'bold', hdrBg);
    txt(setBlurb{s}, xSet(s), 0.759, wSet, th.textSecondary, 'right', fontsz-2, 'normal', hdrBg);
end
txt('CUSTOM', xCust, 0.782, wCust, customCol, 'right', fontsz+1, 'bold', th.figBg);
txt('type and see', xCust, 0.759, wCust, th.textSecondary, 'right', fontsz-2, 'normal', th.figBg);

yTop = 0.700;
for g = 1:3
    yG = yTop - (g-1)*(nGain*rh + grpGap);
    txt(axNames{g}, cpL, yG, 0.028, axCols{g}, 'left', fontsz, 'bold', th.figBg);
    if ~gateOk(g)
        txt('not usable', xGain, yG, 0.10, th.btnReset, 'left', fontsz, 'normal', th.figBg);
        continue
    end
    for k = 1:nGain
        yR = yG - (k-1)*rh;
        was = gainOf(ids(g).gains, k);
        txt(gainNames{k}, xGain, yR, wGain, th.textSecondary, 'left', fontsz, 'bold', cellBg(k,0));
        txt(sprintf('%d', was), xNow, yR, wNow, th.textPrimary, 'right', fontsz+1, 'normal', cellBg(k,0));
        for s = 1:3
            r = res{g,s};
            % feedforward is not proposed - showing the flown number again in
            % all three columns would be noise, so the row stays blank there
            if k == 4 || isempty(r) || ~r.ok
                str = '';
                if k == 1 && (isempty(r) || ~r.ok), str = 'n/a'; end
                txt(str, xSet(s), yR, wSet, th.textSecondary, 'right', fontsz, 'normal', cellBg(k,s));
            else
                now = gainOf(r.gains, k);
                % colour says the direction, so a glance along the row reads as
                % a change rather than four unrelated numbers
                col = th.textSecondary;
                if now < was, col = th.btnReset; elseif now > was, col = th.bodeCoherence; end
                txt(sprintf('%d', now), xSet(s), yR, wSet, col, 'right', fontsz+1, ...
                    'normal', cellBg(k,s));
            end
        end
        start = was;
        r = res{g,2};
        if ~isempty(r) && r.ok && k < 4, start = gainOf(r.gains, k); end
        hEdit(g,k) = uicontrol(fig, 'Style', 'edit', 'Units', 'normalized', ...
            'String', sprintf('%d', start), ...
            'Position', [xCust yR wCust rh], 'FontSize', fontsz, ...
            'HorizontalAlignment', 'right', ...
            'Callback', @(~,~) onCustom(g));
        % nudging one count at a time is how a gain is actually explored; typing
        % still works, so an exact value is never more than a keystroke away
        for d = 1:2
            uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
                'String', stepLbl{d}, 'Tag', 'autotuneStep', ...
                'Position', [xStep(d) yR wStep rh], ...
                'FontSize', fontsz, 'FontWeight', 'bold', ...
                'ForegroundColor', customCol, 'BackgroundColor', th.btnBg, ...
                'Callback', @(~,~) bump(g, k, stepDir(d)));
        end
    end
end

% The colours in the table mean something, so say what. The swatch is what makes
% this read as a key - two coloured words on their own look like stray labels.
yKey = 0.372; wSwatch = 0.010;
txt('Colour key', cpL, yKey, 0.055, th.textSecondary, 'left', fontsz-1, 'normal', th.figBg);
keyX = cpL + 0.062;
keyCols = {th.btnReset, th.bodeCoherence};
keyText = {'lower than now', 'higher than now'};
for k = 1:2
    uicontrol(fig, 'Style', 'text', 'Units', 'normalized', 'String', '', ...
        'Position', [keyX yKey+0.005 wSwatch rh-0.010], ...
        'BackgroundColor', keyCols{k});
    txt(keyText{k}, keyX+wSwatch+0.006, yKey, 0.085, keyCols{k}, 'left', ...
        fontsz-1, 'normal', th.figBg);
    keyX = keyX + wSwatch + 0.100;
end

hCustomInfo = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', 'String', '', ...
    'Position', [cpL 0.336 0.340 rh], 'FontSize', fontsz-1, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

uicontrol(fig, 'Style', 'text', 'Units', 'normalized', 'String', footLines(), ...
    'Position', [cpL 0.244 bannerW 0.076], 'FontSize', fontsz-1, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

% one button per column, in that column's colour, so the button and the curve
% it belongs to read as the same thing
hBtn = zeros(1, 4);
btnX = [xSet xCust]; btnW = [wSet wSet wSet wCust];
btnName = [setNames {'CUSTOM'}]; btnCol = [setCols {customCol}];
for s = 1:4
    hBtn(s) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'String', btnName{s}, 'Tag', 'autotuneCopy', ...
        'Position', [btnX(s) 0.196 btnW(s) 0.046], ...
        'FontSize', fontsz+1, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', th.btnBg, 'ForegroundColor', btnCol{s}, ...
        'Callback', @(~,~) copyCLI(s));
end
txt('Copy to CLI:', cpL, 0.206, 0.075, th.textSecondary, 'left', fontsz, 'normal', th.figBg);

PSstyleControls(fig, th);
tintBoxes();          % after the theme pass, which would otherwise repaint them
PSdatatipSetup(fig);


    function tick(frac, msg)
        if isempty(wb), return; end
        try waitbar(frac, wb, msg); drawnow; catch, end
    end


    function d = stepsFor(id, rrow)
        d = [];
        if isempty(id.G_plant) || numel(id.freq) < 16, return; end
        % the full grid, DC included: PSstepFromFRD reads bin 1 as DC and
        % normalises by it, so handing it a band-limited grid shifts every
        % frequency by one bin and the step never settles to 1
        fmax = min(id.fTrust, 300);
        [A, D, F] = PSbuildController(id.gains, id.fp, id.FsPid, id.freq);
        Tp = PSpredictClosedLoop(id.G_plant, A, D, F);
        [d.t, d.y0] = PSstepFromFRD(id.freq, Tp, fmax);
        d.y = cell(1, 3);
        for s = 1:3
            r = rrow{s};
            if isempty(r) || ~r.ok, continue; end
            [A, D, F] = PSbuildController(r.gains, id.fp, id.FsPid, id.freq);
            Tp = PSpredictClosedLoop(id.G_plant, A, D, F);
            [~, d.y{s}] = PSstepFromFRD(id.freq, Tp, fmax);
        end
    end


    function [headline, lines, allWell] = summaryLines()
        % the headline answers "does anything need changing", which is not the
        % same question as "what else is reachable" - a healthy loop can still
        % have a faster tune available, and that is an option, not advice
        bad = {}; flagged = {}; why = {};
        for a = 1:3
            if ~gateOk(a), bad{end+1} = axNames{a}; continue; end
            [needs, vmsgs] = PSautotuneVerdict(ids(a));
            if needs
                flagged{end+1} = axNames{a};
                if isempty(why), why = vmsgs(1); end
            end
        end
        lines = {};
        allWell = isempty(flagged);
        if ~allWell
            verb = 'NEEDS';
            if numel(flagged) > 1, verb = 'NEED'; end
            headline = sprintf('%s %s ATTENTION', upper(strjoin(flagged, ' AND ')), verb);
            if ~isempty(why), lines{end+1} = why{1}; end
        else
            headline = 'NOTHING NEEDS CHANGING';
            lines{end+1} = 'Your tune is within limits. The columns below are';
            lines{end+1} = 'options, not advice.';
        end
        if ~isempty(bad)
            lines{end+1} = sprintf('%s could not be read from this log.', strjoin(bad, ' and '));
        end
    end


    function foot = footLines()
        band = [];
        for a = 1:3
            if isfinite(ids(a).fTrust), band(end+1) = ids(a).fTrust; end
        end
        foot = {'Pick a column, paste it into the Betaflight CLI.', ...
                'Feedforward is left as flown.'};
        if ~isempty(band)
            foot{end+1} = sprintf('Measured to %.0f Hz. Fly it and check.', min(band));
        end
        % a warning is worth saying once, naming the axes it applies to, rather
        % than repeating the same sentence three times
        warned = {};
        for a = 1:3
            if gateOk(a) && ~isempty(gateWarn{a}), warned{end+1} = axNames{a}; end
        end
        if ~isempty(warned)
            foot{end+1} = sprintf('Dynamic D on %s, so D is held at or below what was flown.', ...
                                  strjoin(warned, ' and '));
        end
    end


    function tintBoxes()
        % same reading as the proposed columns: what you typed against what you
        % are flying, so the custom column is scanned the same way as the rest
        for a = 1:3
            if hEdit(a,1) == 0, continue; end
            for k = 1:4
                was = gainOf(ids(a).gains, k);
                v = boxVal(a, k);
                col = th.inputFg;
                if v < was, col = th.btnReset; elseif v > was, col = th.bodeCoherence; end
                set(hEdit(a,k), 'ForegroundColor', col);
            end
        end
    end


    function bump(g, k, d)
        if hEdit(g,k) == 0, return; end
        v = max(0, boxVal(g, k) + d);
        set(hEdit(g,k), 'String', sprintf('%d', v));
        onCustom(g);
    end


    function v = boxVal(a, k)
        v = round(str2double(get(hEdit(a,k), 'String')));
        if ~isfinite(v) || v < 0, v = 0; end
    end


    function v = gainOf(gg, k)
        switch k
            case 1, v = gg.P;
            case 2, v = gg.I;
            case 3, v = gg.D;
            otherwise, v = gg.F;
        end
    end


    function onCustom(g)
        id = ids(g);
        if isempty(id.G_plant) || hCustom(g) == 0, return; end
        v = zeros(1, 4);
        for k = 1:4
            v(k) = round(str2double(get(hEdit(g,k), 'String')));
            if ~isfinite(v(k)) || v(k) < 0, v(k) = 0; end
            set(hEdit(g,k), 'String', sprintf('%d', v(k)));
        end
        gg = struct('axis', id.axisIdx, 'P', v(1), 'I', v(2), 'D', v(3), 'F', v(4));
        [A, D, F] = PSbuildController(gg, id.fp, id.FsPid, id.freq);
        Tp = PSpredictClosedLoop(id.G_plant, A, D, F);
        [t, y] = PSstepFromFRD(id.freq, Tp, min(id.fTrust, 300));
        set(hCustom(g), 'XData', t, 'YData', y);
        % feedforward never enters L = P*(A+D), so it cannot destabilise the
        % loop - the margins below answer for P, I and D only
        keep = id.freq > 0 & id.freq <= id.fTrust;
        [A, D, F] = PSbuildController(gg, id.fp, id.FsPid, id.freq(keep));
        [~, L, S] = PSpredictClosedLoop(id.G_plant(keep), A, D, F);
        [~, pm] = PSmarginsFromL(id.freq(keep), L);
        if isnan(pm)
            s = sprintf('%s custom: no 0 dB crossing in band', axNames{g});
        else
            s = sprintf('%s custom: PM %.0f deg, Ms %.2f, overshoot %.0f%%', ...
                        axNames{g}, pm, max(abs(S)), 100*(max(y)-1));
        end
        tintBoxes();
        set(hCustomInfo, 'String', s);
        if pm < 30 || max(abs(S)) > 2.5
            set(hCustomInfo, 'ForegroundColor', th.btnReset);
        else
            set(hCustomInfo, 'ForegroundColor', th.textSecondary);
        end
    end


    function copyCLI(s)
        items = [];
        for a = 1:3
            it = struct('axisName', axNames{a}, 'ok', false, ...
                        'gains', struct('P',0,'I',0,'D',0,'F',0), 'note', gateMsg{a});
            if s == 4
                % whatever is in the boxes, even if it was never proposed
                if hEdit(a,1) ~= 0
                    it.ok = true;
                    it.gains = struct('P', boxVal(a,1), 'I', boxVal(a,2), ...
                                      'D', boxVal(a,3), 'F', boxVal(a,4));
                elseif isempty(it.note)
                    it.note = 'nothing typed for this axis';
                end
            else
                r = res{a,s};
                if ~isempty(r) && r.ok
                    it.ok = true;
                    it.gains = r.gains;
                elseif isempty(it.note)
                    it.note = sprintf('no tune reaches %s on this axis', setNames{s});
                end
            end
            if isempty(items), items = it; else, items(a) = it; end
        end
        tgt = NaN;
        if s <= 3, tgt = targets(s); end
        cliText = PSautotuneCLI(items, tgt);
        if PScopyToClipboard(cliText)
            set(hBtn(s), 'String', 'Copied!');
        else
            PSshowCLIDialog(cliText);
        end
    end

end
