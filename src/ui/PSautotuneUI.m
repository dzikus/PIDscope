function PSautotuneUI(T, setupInfo, Fs, tIND, logName)
%% PSautotuneUI - what to change in your PID, read off a chirp log
%  T, setupInfo, Fs, tIND - as handed to the other tools
%  logName                - shown in the header, optional
%
%  Everything is worked out before the window opens, so it never appears with
%  empty rows. The flown value is printed once per gain and the three settings
%  print only what they would change it to. Stability margins live in the Chirp
%  Analysis window; this one answers what to type into the CLI.

if nargin < 5, logName = ''; end

th = PStheme();
fontsz = th.fontsz;

axNames = {'Roll', 'Pitch', 'Yaw'};
gainNames = {'P', 'I', 'D'};
setNames = {'CALM', 'NORMAL', 'SHARP'};
setBlurb = {'most margin', 'recommended', 'least margin'};
targets  = [72.5 60 50];

%% --- work it all out first ---
wb = [];
try wb = waitbar(0, 'Measuring the plant...'); catch, end
ids = [];
res = cell(3, 3);
gateMsg = {'', '', ''};
nStep = 12; done = 0;
for a = 1:3
    tick(done/nStep, sprintf('Measuring the %s plant...', lower(axNames{a})));
    id = PSidentifyChirp(T, setupInfo, Fs, tIND, a-1);
    if isempty(ids), ids = id; else, ids(a) = id; end
    done = done + 1;
end
for a = 1:3
    [gok, gmsgs, ginfo] = PSautotuneGates(ids(a));
    gateMsg{a} = strjoin(gmsgs, '; ');
    if ~gok
        done = done + 3;
        continue
    end
    for s = 1:3
        tick(done/nStep, sprintf('Working out %s for %s...', setNames{s}, lower(axNames{a})));
        res{a,s} = PSautotuneSearch(ids(a), ...
            struct('pmTarget', targets(s), 'dClamp', [0.6 ginfo.dClampHi]));
        done = done + 1;
    end
end
try close(wb); catch, end

%% --- then draw it ---
figName = 'Autotune';
old = findobj('Type', 'figure', 'Name', figName);
if ~isempty(old), close(old); end

figW = 604; figH = 520;
screensz = get(0, 'ScreenSize');
fig = figure('Name', figName, 'NumberTitle', 'off', 'Color', th.figBg, ...
    'Position', [round((screensz(3)-figW)/2) round((screensz(4)-figH)/2) figW figH], ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');

mL = 24;
xAx = mL; wAx = 56;
xGain = 86; wGain = 16;
xNow = 104; wNow = 60;
xCol = [200 330 460]; wCol = 120;
hiCol = min(1, th.figBg + 0.04);
colBg = {th.figBg, hiCol, th.figBg};

% rows are exactly as tall as they are spaced, so the highlighted column reads
% as one block instead of a stack of stripes
rowH = 18; grpGap = 14; yTop = figH - 204;
rowY = zeros(3, 3);
for g = 1:3
    for k = 1:3
        rowY(g,k) = yTop - (g-1)*(3*rowH + grpGap) - (k-1)*rowH;
    end
end

txt = @(s, x, y, w, col, align, fs, wt, bg) uicontrol(fig, 'Style', 'text', ...
    'Units', 'pixels', 'String', s, 'Position', [x y w 18], 'FontSize', fs, ...
    'FontWeight', wt, 'HorizontalAlignment', align, ...
    'ForegroundColor', col, 'BackgroundColor', bg);

rule = @(y) uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [mL y figW-2*mL 1], ...
    'BackgroundColor', th.gridColor, 'ForegroundColor', th.gridColor);

uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', 'Autotune', ...
    'Position', [mL figH-42 200 24], 'FontSize', fontsz+3, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
txt(logName, figW-mL-380, figH-40, 380, th.textSecondary, 'right', fontsz, 'normal', th.figBg);
rule(figH-54);

%% --- one plain sentence about what the log says ---
hot = {}; soft = {}; refused = {};
for a = 1:3
    if ~isempty(gateMsg{a}), refused{end+1} = axNames{a}; continue; end
    rn = res{a,2};
    if isempty(rn) || ~rn.ok, continue; end
    if rn.gains.P < ids(a).gains.P, hot{end+1} = axNames{a};
    elseif rn.gains.P > ids(a).gains.P, soft{end+1} = axNames{a};
    end
end
lines = {};
if ~isempty(hot)
    lines{end+1} = sprintf('%s want less gain - they are flying close to the limit.', ...
                           strjoin(hot, ' and '));
end
if ~isempty(soft)
    lines{end+1} = sprintf('%s can take more gain than it is flying.', strjoin(soft, ' and '));
end
if ~isempty(refused)
    lines{end+1} = sprintf('%s could not be read from this log.', strjoin(refused, ' and '));
end
if isempty(lines), lines{end+1} = 'Nothing to change on this log.'; end
uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', lines, ...
    'Position', [mL figH-112 figW-2*mL 48], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
rule(figH-124);

%% --- header ---
txt('now', xNow, figH-152, wNow, th.textSecondary, 'right', fontsz, 'normal', th.figBg);
for s = 1:3
    txt(setNames{s}, xCol(s), figH-152, wCol, th.textPrimary, 'right', fontsz, 'bold', colBg{s});
    txt(setBlurb{s}, xCol(s), figH-168, wCol, th.textSecondary, 'right', fontsz-1, 'normal', colBg{s});
end
rule(figH-178);

%% --- one row per gain, the flown value printed once ---
for g = 1:3
    txt(axNames{g}, xAx, rowY(g,1), wAx, th.textPrimary, 'left', fontsz, 'bold', th.figBg);
    if ~isempty(gateMsg{g})
        txt(gateMsg{g}, xGain, rowY(g,1), figW-xGain-mL, th.btnReset, 'left', fontsz, 'normal', th.figBg);
        if g < 3, rule(rowY(g,3) - grpGap/2); end
        continue
    end
    for k = 1:3
        was = gainOf(ids(g).gains, k);
        txt(gainNames{k}, xGain, rowY(g,k), wGain, th.textSecondary, 'left', fontsz, 'normal', th.figBg);
        txt(sprintf('%d', was), xNow, rowY(g,k), wNow, th.textSecondary, 'right', fontsz, 'normal', th.figBg);
        for s = 1:3
            r = res{g,s};
            if isempty(r) || ~r.ok
                str = ''; col = th.textSecondary;
                if k == 1, str = 'out of reach'; end
                txt(str, xCol(s), rowY(g,k), wCol, col, 'right', fontsz-1, 'normal', colBg{s});
            else
                now = gainOf(r.gains, k);
                txt(sprintf('%d', now), xCol(s), rowY(g,k), wCol, th.textPrimary, ...
                    'right', fontsz, 'normal', colBg{s});
            end
        end
    end
    if g < 3, rule(rowY(g,3) - grpGap/2); end
end

%% --- footer and the three copies ---
band = [];
for a = 1:3
    if isfinite(ids(a).fTrust), band(end+1) = ids(a).fTrust; end
end
foot = {'Pick a column and paste it into the Betaflight CLI. Feedforward is left as flown.'};
if ~isempty(band)
    foot{end+1} = sprintf(['Measured from the chirp up to %.0f Hz. ' ...
                           'Fly it and check before trusting it.'], min(band));
end
uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', foot, ...
    'Position', [mL 82 figW-2*mL 36], 'FontSize', fontsz-1, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

hBtn = zeros(1, 3);
for s = 1:3
    hBtn(s) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'pixels', ...
        'String', ['Copy ' setNames{s}], ...
        'Position', [xCol(s) 30 wCol 32], 'FontSize', fontsz, 'FontWeight', 'bold', ...
        'BackgroundColor', th.btnBg, 'ForegroundColor', th.textAccent, ...
        'Callback', @(~,~) copyCLI(s));
end

PSstyleControls(fig, th);


    function tick(frac, msg)
        if isempty(wb), return; end
        try waitbar(frac, wb, msg); drawnow; catch, end
    end


    function v = gainOf(gg, k)
        switch k
            case 1, v = gg.P;
            case 2, v = gg.I;
            otherwise, v = gg.D;
        end
    end


    function copyCLI(s)
        items = [];
        for a = 1:3
            it = struct('axisName', axNames{a}, 'ok', false, ...
                        'gains', struct('P',0,'I',0,'D',0,'F',0), 'note', gateMsg{a});
            r = res{a,s};
            if ~isempty(r) && r.ok
                it.ok = true;
                it.gains = r.gains;
            elseif isempty(it.note)
                it.note = sprintf('no tune reaches %s on this axis', setNames{s});
            end
            if isempty(items), items = it; else, items(a) = it; end
        end
        cliText = PSautotuneCLI(items, targets(s));
        if PScopyToClipboard(cliText)
            set(hBtn(s), 'String', 'Copied!');
        else
            PSshowCLIDialog(cliText);
        end
    end

end
