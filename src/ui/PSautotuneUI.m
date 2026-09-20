function PSautotuneUI(T, setupInfo, Fs, tIND, logName)
%% PSautotuneUI - what to change in your PID, read off a chirp log
%  T, setupInfo, Fs, tIND - as handed to the other tools
%  logName                - shown in the header, optional
%
%  All nine answers (three axes, three settings) are worked out once when the
%  window opens and then just displayed, so nothing recomputes while you read.
%  Stability margins live in the Chirp Analysis window; this one answers the
%  only question a pilot has, which is what to type into the CLI.

if nargin < 5, logName = ''; end

th = PStheme();
fontsz = th.fontsz;

figName = 'Autotune';
old = findobj('Type', 'figure', 'Name', figName);
if ~isempty(old), close(old); end

figW = 700; figH = 560;
screensz = get(0, 'ScreenSize');
fig = figure('Name', figName, 'NumberTitle', 'off', 'Color', th.figBg, ...
    'Position', [round((screensz(3)-figW)/2) round((screensz(4)-figH)/2) figW figH], ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');

axNames = {'Roll', 'Pitch', 'Yaw'};
gainNames = {'P', 'I', 'D'};
setNames = {'CALM', 'NORMAL', 'SHARP'};
setBlurb = {'most margin', 'recommended', 'least margin'};
targets  = [72.5 60 50];

xAxis = 22; wAxis = 64;
xCol = [96 292 488]; wCol = 186;
yTitle = figH - 38; ySummary = figH - 108; ySep = figH - 118;
yHdr = figH - 154; yBlurb = figH - 170;
rowH = 22; grpGap = 12; yTop = figH - 198;
rowY = zeros(3, 3);
for g = 1:3
    for k = 1:3
        rowY(g,k) = yTop - (g-1)*(3*rowH + grpGap) - (k-1)*rowH;
    end
end

% Backdrop: groups the three gains of an axis together and marks the column
% most pilots should take. uicontrols always draw over axes, so this sits
% behind everything without fighting for hit testing.
axBg = axes('Parent', fig, 'Units', 'normalized', 'Position', [0 0 1 1], ...
    'XLim', [0 figW], 'YLim', [0 figH], 'Visible', 'off', 'HitTest', 'off');
hold(axBg, 'on');
hiCol = min(1, th.figBg + 0.045);
colBg = {th.figBg, hiCol, th.figBg};
patch('Parent', axBg, 'FaceColor', hiCol, 'EdgeColor', 'none', 'HitTest', 'off', ...
    'XData', [xCol(2)-10 xCol(2)+wCol-10 xCol(2)+wCol-10 xCol(2)-10], ...
    'YData', [rowY(3,3)-10 rowY(3,3)-10 yHdr+22 yHdr+22]);
line('Parent', axBg, 'XData', [xAxis figW-xAxis], 'YData', [ySep ySep], ...
    'Color', th.gridColor, 'LineWidth', 0.5, 'HitTest', 'off');
for g = 1:2
    yg = rowY(g,3) - grpGap/2;
    line('Parent', axBg, 'XData', [xAxis figW-xAxis], 'YData', [yg yg], ...
        'Color', th.gridColor, 'LineWidth', 0.5, 'HitTest', 'off');
end
hold(axBg, 'off');

uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', 'Autotune', ...
    'Position', [xAxis yTitle 200 24], 'FontSize', fontsz+3, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.btnAutotune, 'BackgroundColor', th.figBg);
uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', logName, ...
    'Position', [figW-432-22 yTitle+2 432 20], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'right', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

hSummary = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [xAxis ySummary figW-2*xAxis 56], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);

% progress sits where the table will be, so hiding it leaves no hole
hBarBg = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [xAxis yTop+6 figW-2*xAxis 10], ...
    'BackgroundColor', th.btnBg, 'ForegroundColor', th.btnBg);
hBar = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [xAxis yTop+6 1 10], ...
    'BackgroundColor', th.btnAutotune, 'ForegroundColor', th.btnAutotune);
hStep = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [xAxis yTop-24 figW-2*xAxis 18], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

hCell = zeros(3, 3, 3);     % axis, setting, gain
hNote = zeros(1, 3);
hHdr = zeros(1, 3);
for g = 1:3
    uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', axNames{g}, ...
        'Position', [xAxis rowY(g,1) wAxis rowH], 'FontSize', fontsz, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
    hNote(g) = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
        'Visible', 'off', 'Position', [xCol(1) rowY(g,1) figW-xCol(1)-22 rowH], ...
        'FontSize', fontsz, 'HorizontalAlignment', 'left', ...
        'ForegroundColor', th.btnReset, 'BackgroundColor', th.figBg);
    for s = 1:3
        for k = 1:3
            hCell(g,s,k) = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', ...
                'String', '', 'Position', [xCol(s) rowY(g,k) wCol rowH], ...
                'FontSize', fontsz, 'FontName', 'Monospace', ...
                'HorizontalAlignment', 'left', ...
                'ForegroundColor', th.textPrimary, 'BackgroundColor', colBg{s});
        end
    end
end

for s = 1:3
    hdrCol = th.textPrimary;
    if s == 2, hdrCol = th.btnAutotune; end
    hHdr(s) = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', setNames{s}, ...
        'Position', [xCol(s) yHdr wCol 20], 'FontSize', fontsz+1, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'ForegroundColor', hdrCol, 'BackgroundColor', colBg{s});
    uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', setBlurb{s}, ...
        'Position', [xCol(s) yBlurb wCol 16], 'FontSize', fontsz-1, ...
        'HorizontalAlignment', 'left', ...
        'ForegroundColor', th.textSecondary, 'BackgroundColor', colBg{s});
end

hFoot = uicontrol(fig, 'Style', 'text', 'Units', 'pixels', 'String', '', ...
    'Position', [xAxis 96 figW-2*xAxis 40], 'FontSize', fontsz-1, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textSecondary, 'BackgroundColor', th.figBg);

hBtn = zeros(1, 3);
for s = 1:3
    hBtn(s) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'pixels', ...
        'String', ['Copy ' setNames{s}], ...
        'Position', [xCol(s) 32 wCol 32], 'FontSize', fontsz, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', th.btnBg, 'ForegroundColor', th.btnAutotune, ...
        'Callback', @(~,~) copyCLI(s));
end

ids = [];
res = cell(3, 3);
gateMsg = {'', '', ''};

compute();
render();


    function compute()
        nStep = 12; done = 0;
        for a = 1:3
            step(sprintf('Measuring the %s plant...', lower(axNames{a})), done, nStep);
            id = PSidentifyChirp(T, setupInfo, Fs, tIND, a-1);
            if isempty(ids), ids = id; else, ids(a) = id; end
            done = done + 1;
        end
        for a = 1:3
            [gok, gmsgs, ginfo] = PSautotuneGates(ids(a));
            gateMsg{a} = strjoin(gmsgs, '; ');
            if ~gok
                done = done + 3;
                step('', done, nStep);
                continue
            end
            for s = 1:3
                step(sprintf('Working out %s for %s...', setNames{s}, lower(axNames{a})), ...
                     done, nStep);
                res{a,s} = PSautotuneSearch(ids(a), ...
                    struct('pmTarget', targets(s), 'dClamp', [0.6 ginfo.dClampHi]));
                done = done + 1;
            end
        end
        step('', nStep, nStep);
        set([hBarBg hBar hStep], 'Visible', 'off');
    end


    function step(msg, done, total)
        w = max(1, round((figW - 2*xAxis) * done / total));
        set(hBar, 'Position', [xAxis figH-130 w 10]);
        if ~isempty(msg), set(hStep, 'String', msg); end
        drawnow;
    end


    function render()
        hot = {}; soft = {}; refused = {};
        for a = 1:3
            if ~isempty(gateMsg{a})
                set(hNote(a), 'String', gateMsg{a}, 'Visible', 'on');
                for s = 1:3
                    for k = 1:3, set(hCell(a,s,k), 'Visible', 'off'); end
                end
                refused{end+1} = axNames{a};
                continue
            end
            for s = 1:3
                r = res{a,s};
                for k = 1:3
                    if isempty(r) || ~r.ok
                        txt = '';
                        if k == 1, txt = 'out of reach'; end
                        set(hCell(a,s,k), 'String', txt, ...
                            'ForegroundColor', th.textSecondary);
                        continue
                    end
                    was = gainOf(ids(a).gains, k);
                    now = gainOf(r.gains, k);
                    col = th.textPrimary;
                    if now < was, col = th.btnDash2; elseif now > was, col = th.btnRun; end
                    set(hCell(a,s,k), 'ForegroundColor', col, ...
                        'String', sprintf('%s %4d -> %-4d', gainNames{k}, was, now));
                end
            end
            rn = res{a,2};
            if ~isempty(rn) && rn.ok
                if rn.gains.P < ids(a).gains.P, hot{end+1} = axNames{a};
                elseif rn.gains.P > ids(a).gains.P, soft{end+1} = axNames{a};
                end
            end
        end

        lines = {};
        if ~isempty(hot)
            lines{end+1} = sprintf('%s want less gain - they are flying close to the limit.', ...
                                   strjoin(hot, ' and '));
        end
        if ~isempty(soft)
            lines{end+1} = sprintf('%s can take more gain than %s flying.', ...
                                   strjoin(soft, ' and '), pickAux(numel(soft)));
        end
        if ~isempty(refused)
            lines{end+1} = sprintf('%s could not be read from this log.', ...
                                   strjoin(refused, ' and '));
        end
        if isempty(lines), lines{end+1} = 'Nothing to change on this log.'; end
        set(hSummary, 'String', lines);

        band = [];
        for a = 1:3
            if isfinite(ids(a).fTrust), band(end+1) = ids(a).fTrust; end
        end
        foot = {'Pick a column and paste it into the Betaflight CLI. Feedforward is left as flown.'};
        if ~isempty(band)
            foot{end+1} = sprintf(['Measured from the chirp up to %.0f Hz. ' ...
                                   'Fly it and check before trusting it.'], min(band));
        end
        set(hFoot, 'String', foot);
    end


    function v = gainOf(g, k)
        switch k
            case 1, v = g.P;
            case 2, v = g.I;
            otherwise, v = g.D;
        end
    end


    function s = pickAux(n)
        s = 'it is';
        if n > 1, s = 'they are'; end
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
        txt = PSautotuneCLI(items, targets(s));
        if PScopyToClipboard(txt)
            set(hBtn(s), 'String', 'Copied!');
        else
            PSshowCLIDialog(txt);
        end
    end

end
