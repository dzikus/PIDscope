function PSautotuneUI(T, setupInfo, Fs, tIND)
%% PSautotuneUI - propose PID gains from a chirp log, one row per axis
%  T, setupInfo, Fs, tIND - as handed to the other tools
%
%  The plant is measured once when the window opens; the aggressiveness setting
%  only re-runs the search, so there is nothing to press to get an answer.
%  Refused axes say why rather than showing blank numbers.

th = PStheme();
fontsz = th.fontsz;

figName = 'Autotune';
old = findobj('Type', 'figure', 'Name', figName);
if ~isempty(old), close(old); end

screensz = get(0, 'ScreenSize');
figW = 770; figH = 430;
fig = figure('Name', figName, 'NumberTitle', 'off', 'Color', th.figBg, ...
    'Position', [round((screensz(3)-figW)/2) round((screensz(4)-figH)/2) figW figH], ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');

axNames = {'Roll', 'Pitch', 'Yaw'};
targets = [72.5 60 50];
tgtLabels = {'Conservative  72.5 deg', 'Normal  60 deg', 'Aggressive  50 deg'};
colLabels = {'Axis', 'P', 'I', 'D', 'FF', 'Phase margin', 'Ms', 'Crossover'};
colX      = [ 20,    85,  170, 255, 340,  425,            545,  620];
colW      = [ 60,     80,  80,  80,  80,  115,             70,  130];

uicontrol(fig, 'Style', 'text', 'String', 'Aggressiveness', ...
    'Position', [20 figH-42 110 20], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
hTarget = uicontrol(fig, 'Style', 'popupmenu', 'String', tgtLabels, 'Value', 2, ...
    'Position', [135 figH-44 190 24], 'FontSize', fontsz, ...
    'Callback', @(~,~) recompute());

hStatus = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Position', [340 figH-42 410 20], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);

for c = 1:numel(colLabels)
    uicontrol(fig, 'Style', 'text', 'String', colLabels{c}, ...
        'Position', [colX(c) figH-82 colW(c) 20], 'FontSize', fontsz, ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold', ...
        'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
end

rowY = [figH-112, figH-142, figH-172];
hCell = zeros(3, numel(colLabels));
hNote = zeros(1, 3);
for r = 1:3
    for c = 1:numel(colLabels)
        hCell(r,c) = uicontrol(fig, 'Style', 'text', 'String', '', ...
            'Position', [colX(c) rowY(r) colW(c) 20], 'FontSize', fontsz, ...
            'HorizontalAlignment', 'left', ...
            'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
    end
    set(hCell(r,1), 'String', axNames{r}, 'FontWeight', 'bold');
    hNote(r) = uicontrol(fig, 'Style', 'text', 'String', '', 'Visible', 'off', ...
        'Position', [colX(2) rowY(r) 660 20], 'FontSize', fontsz, ...
        'HorizontalAlignment', 'left', ...
        'ForegroundColor', th.btnReset, 'BackgroundColor', th.figBg);
end

hFoot = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Position', [20 66 730 40], 'FontSize', fontsz, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);

hCopy = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Copy CLI', ...
    'Position', [20 22 120 30], 'FontSize', fontsz, 'FontWeight', 'bold', ...
    'BackgroundColor', th.btnAutotune, 'ForegroundColor', [0 0 0], ...
    'Callback', @(~,~) copyCLI());

ids = [];
res = cell(1, 3);
gateMsg = {'', '', ''};

identify();
recompute();


    function identify()
        set(hStatus, 'String', 'Measuring the plant on three axes...');
        drawnow;
        for a = 0:2
            id = PSidentifyChirp(T, setupInfo, Fs, tIND, a);
            if isempty(ids), ids = id; else, ids(a+1) = id; end
        end
        set(hStatus, 'String', '');
        drawnow;
    end


    function recompute()
        tgt = targets(get(hTarget, 'Value'));
        set(hStatus, 'String', sprintf('Searching at %.1f deg...', tgt));
        drawnow;

        notes = {};
        for r = 1:3
            id = ids(r);
            [gok, gmsgs, ginfo] = PSautotuneGates(id);
            gateMsg{r} = strjoin(gmsgs, '; ');
            res{r} = [];
            if ~gok
                showNote(r, gateMsg{r});
                continue
            end
            opt = struct('pmTarget', tgt, 'dClamp', [0.6 ginfo.dClampHi]);
            r_ = PSautotuneSearch(id, opt);
            res{r} = r_;
            if ~r_.ok
                showNote(r, sprintf('No tune clears %.1f deg here (%s)', tgt, r_.reason));
                continue
            end
            showRow(r, id, r_);
            if ~isempty(gmsgs), notes{end+1} = sprintf('%s: %s', id.axisName, gateMsg{r}); end
        end

        band = [];
        for r = 1:3
            if isfinite(ids(r).fTrust), band(end+1) = ids(r).fTrust; end
        end
        foot = {};
        if ~isempty(band)
            foot{end+1} = sprintf('Plant good to %.0f Hz', min(band));
        end
        foot = [foot notes];
        foot{end+1} = 'Verify on a test flight';
        set(hFoot, 'String', strjoin(foot, '  |  '));
        set(hStatus, 'String', '');
        drawnow;
    end


    function showNote(r, msg)
        for c = 2:size(hCell, 2)
            set(hCell(r,c), 'Visible', 'off');
        end
        set(hNote(r), 'String', msg, 'Visible', 'on');
    end


    function showRow(r, id, rr)
        set(hNote(r), 'Visible', 'off');
        for c = 2:size(hCell, 2)
            set(hCell(r,c), 'Visible', 'on');
        end
        set(hCell(r,2), 'String', sprintf('%d -> %d', id.gains.P, rr.gains.P));
        set(hCell(r,3), 'String', sprintf('%d -> %d', id.gains.I, rr.gains.I));
        set(hCell(r,4), 'String', sprintf('%d -> %d', id.gains.D, rr.gains.D));
        set(hCell(r,5), 'String', sprintf('%d -> %d', id.gains.F, rr.gains.F));
        set(hCell(r,6), 'String', sprintf('%.0f -> %.0f deg', rr.pm0, rr.pm));
        set(hCell(r,7), 'String', sprintf('%.2f -> %.2f', rr.ms0, rr.ms));
        set(hCell(r,8), 'String', sprintf('%.0f -> %.0f Hz', rr.wcp0, rr.wcp));
    end


    function copyCLI()
        tgt = targets(get(hTarget, 'Value'));
        items = [];
        for r = 1:3
            it = struct('axisName', axNames{r}, 'ok', false, ...
                        'gains', struct('P',0,'I',0,'D',0,'F',0), 'note', gateMsg{r});
            if ~isempty(res{r}) && res{r}.ok
                it.ok = true;
                it.gains = res{r}.gains;
            elseif isempty(it.note)
                it.note = sprintf('no tune clears %.1f deg', tgt);
            end
            if isempty(items), items = it; else, items(r) = it; end
        end
        txt = PSautotuneCLI(items, tgt);
        if PScopyToClipboard(txt)
            set(hCopy, 'String', 'Copied!');
        else
            PSshowCLIDialog(txt);
        end
    end

end
