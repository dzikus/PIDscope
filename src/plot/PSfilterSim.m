function PSfilterSim(~, Fs, setupInfo)
%% PSfilterSim - BF filter chain visualization (theoretical response)
%  Layout: 2 cols (Lowpass | Notch) x 4 rows (Magnitude, Delay, Phase, Step)

thm = PStheme();
fontsz = thm.fontsz;
screensz = get(0, 'ScreenSize');
fig = findobj('Type', 'figure', 'Name', 'Filter Simulation');
if ~isempty(fig), close(fig); end
fig = figure('Name', 'Filter Simulation', 'NumberTitle', 'off', ...
    'Color', thm.figBg, ...
    'Position', round([0 0 screensz(3) screensz(4)]));
try set(fig, 'WindowState', 'maximized'); catch, end

fp = PSparseFilterParams(setupInfo);

% Use gyro loop rate from headers if available (filters run at gyro rate, not logging rate)
if fp.gyro_rate_hz > 0, Fs = fp.gyro_rate_hz; end

% Layout: 2 cols x 4 rows + gradient bars
plotL = 0.05;
plotR = 0.75;
colGap = 0.055;
colW = (plotR - plotL - colGap) / 2;
colL = [plotL, plotL + colW + colGap];
titleH = 0.04;
barH = 0.018;
topMargin = 0.01;
botMargin = 0.06;
rowGap = 0.012;
topY = 1 - topMargin - titleH;
barY = topY - barH;
plotTop = barY - rowGap*0.5;
rowH = (plotTop - botMargin - 3*rowGap) / 4;
rowB1 = plotTop - rowH;
rowB2 = rowB1 - rowH - rowGap;
rowB3 = rowB2 - rowH - rowGap;
rowB4 = rowB3 - rowH - rowGap;

axLmag   = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) rowB1 colW rowH]);
axLdelay = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) rowB2 colW rowH]);
axLphase = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) rowB3 colW rowH]);
axLstep  = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) rowB4 colW rowH]);

axNmag   = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) rowB1 colW rowH]);
axNdelay = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) rowB2 colW rowH]);
axNphase = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) rowB3 colW rowH]);
axNstep  = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) rowB4 colW rowH]);

% Style all plot axes once (dark theme)
for ax_ = {axLmag, axLdelay, axLphase, axNmag, axNdelay, axNphase}
    PSstyleAxes(ax_{1}, thm);
    set(ax_{1}, 'XTickLabel', {});  % freq-domain rows: hide X ticks (shared axis)
end
for ax_ = {axLstep, axNstep}
    PSstyleAxes(ax_{1}, thm);  % row4: keep X tick labels
end

% Pre-create pooled line objects: 16 per axes, reuse via setLine/hideLines
POOL = 16;
axAll8 = [axLmag axLdelay axLphase axLstep axNmag axNdelay axNphase axNstep];
lnPool = cell(8, POOL);
for ai = 1:8
    hold(axAll8(ai), 'on');
    for li = 1:POOL
        lnPool{ai, li} = line(axAll8(ai), NaN, NaN, 'Visible', 'off', 'HitTest', 'off');
    end
end
% text annotation pools: 8 per axes
TPOOL = 8;
txPool = cell(8, TPOOL);
for ai = 1:8
    for ti = 1:TPOOL
        txPool{ai, ti} = text(NaN, NaN, '', 'Parent', axAll8(ai), 'Visible', 'off', ...
            'FontSize', fontsz-1, 'HitTest', 'off');
    end
end
% re-enable grid after hold+line creation (hold can reset grid in Octave)
for ai = 1:8, grid(axAll8(ai), 'on'); end
% axes indices for easy access
AX_LMAG=1; AX_LDLY=2; AX_LPH=3; AX_LSTP=4;
AX_NMAG=5; AX_NDLY=6; AX_NPH=7; AX_NSTP=8;

% Gradient frequency bars
axBarL = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) barY colW barH], 'Tag', 'gradbar');
axBarN = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) barY colW barH], 'Tag', 'gradbar');

titleY = topY;
hTitleL = uicontrol(fig, 'Style', 'text', 'String', 'LOWPASS FILTERS', ...
    'Units', 'normalized', 'Position', [colL(1) titleY colW titleH], ...
    'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.figBg, 'ForegroundColor', thm.textAccent);
hTitleN = uicontrol(fig, 'Style', 'text', 'String', 'NOTCH FILTERS', ...
    'Units', 'normalized', 'Position', [colL(2) titleY colW titleH], ...
    'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.figBg, 'ForegroundColor', thm.secNotch);

% Control panel
cpL = .76; cpW = .23;
uipanel('Parent', fig, 'Title', 'Filter Controls', 'FontWeight', 'bold', ...
    'BackgroundColor', thm.panelBg, 'ForegroundColor', thm.panelFg, ...
    'HighlightColor', thm.panelBorder, ...
    'FontSize', fontsz, 'Position', [cpL .02 cpW .96]);

row = .93; rh = .026; gap = .004;
bgc = thm.panelBg; fgc = thm.panelFg;
cb = @(~,~) autoUpdate();
ibc = thm.inputBg; ifc = thm.inputFg;
lc = thm.textSecondary;

% grid: label col = cpL+.01, half-width col = cpL+.115
x0 = cpL + .01; cW = cpW - .02; halfW = cW / 2;

% Looprate + #Motors
loopRates = [1000 1100 3200 6400 6664 8000 9000 32000];
loopLabels = {'1k','1.1k','3.2k','6.4k','6.664k','8k','9k','32k'};
[~, lrIdx] = min(abs(loopRates - Fs));
uicontrol(fig, 'Style', 'text', 'String', 'Rate:', ...
    'Units', 'normalized', 'Position', [x0 row .035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.looprate = uicontrol(fig, 'Style', 'popupmenu', 'String', loopLabels, 'Value', lrIdx, ...
    'Units', 'normalized', 'Position', [x0+.04 row halfW-.04 rh], 'FontSize', fontsz, ...
    'Callback', @(~,~) loopRateChanged());
uicontrol(fig, 'Style', 'text', 'String', 'Mot:', ...
    'Units', 'normalized', 'Position', [x0+halfW row .035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.rpm_nmot = uicontrol(fig, 'Style', 'popupmenu', ...
    'String', {'1','2','3','4','5','6','7','8'}, 'Value', 4, ...
    'Units', 'normalized', 'Position', [x0+halfW+.04 row halfW-.04 rh], 'FontSize', fontsz, 'Callback', cb);
row = row - rh - gap*2;

mkSection(fig, 'Gyro LPF1', cpL, row, cpW, rh, bgc, thm.textAccent, fontsz-1);
row = row - rh - gap;
[h.glpf1_type, h.glpf1_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.gyro_lpf1_type, fp.gyro_lpf1_hz, cb, fontsz);

mkSection(fig, 'Gyro LPF2', cpL, row, cpW, rh, bgc, thm.textAccent, fontsz-1);
row = row - rh - gap;
[h.glpf2_type, h.glpf2_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.gyro_lpf2_type, fp.gyro_lpf2_hz, cb, fontsz);

mkSection(fig, 'Gyro Notch 1', cpL, row, cpW, rh, bgc, thm.secNotch, fontsz-1);
row = row - rh - gap;
[h.gn1_hz, h.gn1_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.gyro_notch1_hz, fp.gyro_notch1_cut, cb, fontsz);

mkSection(fig, 'Gyro Notch 2', cpL, row, cpW, rh, bgc, thm.secNotch, fontsz-1);
row = row - rh - gap;
[h.gn2_hz, h.gn2_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.gyro_notch2_hz, fp.gyro_notch2_cut, cb, fontsz);

mkSection(fig, 'D-term LPF1', cpL, row, cpW, rh, bgc, thm.secDtermLPF, fontsz-1);
row = row - rh - gap;
[h.dlpf1_type, h.dlpf1_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.dterm_lpf1_type, fp.dterm_lpf1_hz, cb, fontsz);

mkSection(fig, 'D-term LPF2', cpL, row, cpW, rh, bgc, thm.secDtermLPF, fontsz-1);
row = row - rh - gap;
[h.dlpf2_type, h.dlpf2_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.dterm_lpf2_type, fp.dterm_lpf2_hz, cb, fontsz);

mkSection(fig, 'D-term Notch', cpL, row, cpW, rh, bgc, thm.secDtermNotch, fontsz-1);
row = row - rh - gap;
[h.dn_hz, h.dn_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.dterm_notch_hz, fp.dterm_notch_cut, cb, fontsz);

% RPM: Hz + #Harm + Q on one line
mkSection(fig, 'RPM Filter Sim', cpL, row, cpW, rh, bgc, thm.btnDash1, fontsz-1);
row = row - rh - gap;
thirdW = cW / 3;
uicontrol(fig, 'Style', 'text', 'String', 'Hz:', ...
    'Units', 'normalized', 'Position', [x0 row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.rpm_base = uicontrol(fig, 'Style', 'edit', 'String', '200', ...
    'Units', 'normalized', 'Position', [x0+.03 row thirdW-.035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, 'HorizontalAlignment', 'center', 'Callback', cb);
uicontrol(fig, 'Style', 'text', 'String', '#H:', ...
    'Units', 'normalized', 'Position', [x0+thirdW row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.rpm_nharm = uicontrol(fig, 'Style', 'popupmenu', ...
    'String', {'0','1','2','3','4','5','6','7'}, 'Value', 4, ...
    'Units', 'normalized', 'Position', [x0+thirdW+.03 row thirdW-.035 rh], 'FontSize', fontsz, 'Callback', cb);
uicontrol(fig, 'Style', 'text', 'String', 'Q:', ...
    'Units', 'normalized', 'Position', [x0+thirdW*2 row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.rpm_q = uicontrol(fig, 'Style', 'edit', 'String', '500', ...
    'Units', 'normalized', 'Position', [x0+thirdW*2+.03 row thirdW-.035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, 'HorizontalAlignment', 'center', 'Callback', cb);
row = row - rh - gap;

% Test signal: Lo + Hi + Dur on one line
mkSection(fig, 'Test Signal', cpL, row, cpW, rh, bgc, thm.btnDash5, fontsz-1);
row = row - rh - gap;
uicontrol(fig, 'Style', 'text', 'String', 'Lo:', ...
    'Units', 'normalized', 'Position', [x0 row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.sig_start = uicontrol(fig, 'Style', 'edit', 'String', '0', ...
    'Units', 'normalized', 'Position', [x0+.03 row thirdW-.035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, 'HorizontalAlignment', 'center', 'Callback', cb);
uicontrol(fig, 'Style', 'text', 'String', 'Hi:', ...
    'Units', 'normalized', 'Position', [x0+thirdW row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.sig_end = uicontrol(fig, 'Style', 'edit', 'String', '1000', ...
    'Units', 'normalized', 'Position', [x0+thirdW+.03 row thirdW-.035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, 'HorizontalAlignment', 'center', 'Callback', cb);
uicontrol(fig, 'Style', 'text', 'String', 'Dur:', ...
    'Units', 'normalized', 'Position', [x0+thirdW*2 row .025 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.sig_dur = uicontrol(fig, 'Style', 'edit', 'String', '1', ...
    'Units', 'normalized', 'Position', [x0+thirdW*2+.03 row thirdW-.035 rh], ...
    'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, 'HorizontalAlignment', 'center', 'Callback', cb);
row = row - rh - gap;

% Options
mkSection(fig, 'Options', cpL, row, cpW, rh, bgc, thm.btnSave, fontsz-1);
row = row - rh - gap;
h.magdB = uicontrol(fig, 'Style', 'checkbox', 'String', 'Magnitude dB', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0 row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
h.logfreq = uicontrol(fig, 'Style', 'checkbox', 'String', 'Log Frequency', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+halfW row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap;
h.combinelpf = uicontrol(fig, 'Style', 'checkbox', 'String', 'combine lpf', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0 row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap;
ddW_ = cW * 0.48;
h.row4mode = uicontrol(fig, 'Style', 'popupmenu', 'String', {'Step resp.','Impulse resp.','Signal Generator'}, 'Value', 1, ...
    'Units', 'normalized', 'Position', [x0 row ddW_ rh], ...
    'FontSize', fontsz, 'Callback', @(~,~) toggleStepRow());
h.addnoise = uicontrol(fig, 'Style', 'checkbox', 'String', 'Add noise', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+halfW row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap;
h.showboth = uicontrol(fig, 'Style', 'checkbox', 'String', 'Show Both', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0 row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap;
h.autoupd = uicontrol(fig, 'Style', 'checkbox', 'String', 'Auto Update', 'Value', 1, ...
    'Units', 'normalized', 'Position', [x0 row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, ...
    'Callback', @(~,~) toggleAutoUpdate());
h.updBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Update', ...
    'Units', 'normalized', 'Position', [x0+halfW row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', thm.btnBg, 'ForegroundColor', thm.textPrimary, ...
    'Enable', 'off', 'Callback', @(~,~) doUpdate());
row = row - rh - gap;
h.totalDelay = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [x0 row cW rh], ...
    'FontSize', fontsz, 'FontWeight', 'bold', ...
    'BackgroundColor', bgc, 'ForegroundColor', thm.btnDash1, 'HorizontalAlignment', 'left');
row = row - rh - gap*2;
h.copyCLI = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Copy CLI', ...
    'Units', 'normalized', 'Position', [x0+halfW*.3 row halfW*1.3 rh+.004], ...
    'FontSize', fontsz, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.btnBg, 'ForegroundColor', thm.textAccent, ...
    'Callback', @(~,~) copyCLI());

doUpdate();

    function autoUpdate()
        if get(h.autoupd, 'Value'), doUpdate(); end
    end

    function loopRateChanged()
        Fs = loopRates(get(h.looprate, 'Value'));
        autoUpdate();
    end

    function toggleStepRow()
        applyLayout();
        autoUpdate();
    end

    function applyLayout()
        sStep = get(h.row4mode, 'Value') > 0;  % always show row 4
        sBoth = get(h.showboth, 'Value');
        offscr = [-2 -2 .01 .01];

        if sStep
            nRows = 4;
        else
            nRows = 3;
        end
        rH = (plotTop - botMargin - (nRows-1)*rowGap) / nRows;
        rB1 = plotTop - rH;
        rB2 = rB1 - rH - rowGap;
        rB3 = rB2 - rH - rowGap;
        if nRows == 4
            rB4 = rB3 - rH - rowGap;
        end

        if sBoth
            w = plotR - plotL; xL = plotL;
        else
            w = colW; xL = colL(1);
        end

        set(axLmag,   'Position', [xL rB1 w rH]);
        set(axLdelay, 'Position', [xL rB2 w rH]);
        set(axLphase, 'Position', [xL rB3 w rH]);
        if sStep
            set(axLstep, 'Position', [xL rB4 w rH], 'Visible', 'on');
        else
            set(axLstep, 'Position', offscr, 'Visible', 'off');
        end

        if sBoth
            set(axNmag,   'Position', offscr);
            set(axNdelay, 'Position', offscr);
            set(axNphase, 'Position', offscr);
            set(axNstep,  'Position', offscr);
            set(hTitleN, 'Visible', 'off');
            set(axBarN, 'Position', offscr);
            set(axBarL, 'Position', [plotL barY plotR-plotL barH]);
        else
            set(axNmag,   'Position', [colL(2) rB1 colW rH]);
            set(axNdelay, 'Position', [colL(2) rB2 colW rH]);
            set(axNphase, 'Position', [colL(2) rB3 colW rH]);
            if sStep
                set(axNstep, 'Position', [colL(2) rB4 colW rH], 'Visible', 'on');
            else
                set(axNstep, 'Position', offscr, 'Visible', 'off');
            end
            set(hTitleN, 'Visible', 'on');
            set(axBarN, 'Position', [colL(2) barY colW barH]);
            set(axBarL, 'Position', [colL(1) barY colW barH]);
        end
    end

    function toggleAutoUpdate()
        if get(h.autoupd, 'Value')
            set(h.updBtn, 'Enable', 'off');
            doUpdate();
        else
            set(h.updBtn, 'Enable', 'on');
        end
    end

    function doUpdate()
        if ~ishandle(fig), return; end

        allFreqAx = [axLmag axLdelay axLphase axNmag axNdelay axNphase];

        % Suppress "Non-positive limit for logarithmic axis" during redraw
        wstate = warning('query', 'all');
        warning('off', 'all');

        glpf1t = get(h.glpf1_type, 'Value') - 1;
        glpf1f = readEdit(h.glpf1_hz);
        glpf2t = get(h.glpf2_type, 'Value') - 1;
        glpf2f = readEdit(h.glpf2_hz);
        gn1f = readEdit(h.gn1_hz);
        gn1c = readEdit(h.gn1_cut);
        gn2f = readEdit(h.gn2_hz);
        gn2c = readEdit(h.gn2_cut);
        dlpf1t = get(h.dlpf1_type, 'Value') - 1;
        dlpf1f = readEdit(h.dlpf1_hz);
        dlpf2t = get(h.dlpf2_type, 'Value') - 1;
        dlpf2f = readEdit(h.dlpf2_hz);
        dnf = readEdit(h.dn_hz);
        dnc = readEdit(h.dn_cut);
        rpmBase = readEdit(h.rpm_base);
        rpmNharm = get(h.rpm_nharm, 'Value') - 1;
        rpmQ = readEdit(h.rpm_q);
        nMotors = get(h.rpm_nmot, 'Value');
        usedB = get(h.magdB, 'Value');
        useLog = get(h.logfreq, 'Value');
        combineLPF = get(h.combinelpf, 'Value');
        addNoise = get(h.addnoise, 'Value');
        showBoth = get(h.showboth, 'Value');
        row4mode = get(h.row4mode, 'Value');  % 1=step, 2=impulse, 3=signal gen
        sigHzLo = readEdit(h.sig_start);
        sigHzHi = readEdit(h.sig_end);
        sigDur = max(0.1, readEditF(h.sig_dur));

        % partial update: skip unchanged column
        curAll = [glpf1t glpf1f glpf2t glpf2f dlpf1t dlpf1f dlpf2t dlpf2f ...
                  gn1f gn1c gn2f gn2c dnf dnc rpmBase rpmNharm rpmQ nMotors ...
                  usedB useLog combineLPF addNoise showBoth row4mode sigHzLo sigHzHi round(sigDur*100)];
        curLPF = curAll(1:8); curNotch = curAll(9:18);
        prev = getappdata(fig, 'prevAll');
        doLPF = true; doNotch = true;
        if ~isempty(prev) && numel(prev) == numel(curAll)
            lpfChanged = ~isequal(curLPF, prev(1:8));
            notchChanged = ~isequal(curNotch, prev(9:18));
            optsChanged = ~isequal(curAll(19:end), prev(19:end));
            if ~optsChanged && ~showBoth
                if lpfChanged && ~notchChanged, doNotch = false; end
                if notchChanged && ~lpfChanged, doLPF = false; end
            end
        end
        setappdata(fig, 'prevAll', curAll);

        types = {'pt1', 'biquad', 'pt2', 'pt3'};
        Nfft = 4096;
        fVec = linspace(0, Fs/2, Nfft)';
        fMax = min(Fs/2, 1000);
        fIdx = fVec <= fMax;
        if useLog, fMin = 10; fIdx = fVec >= fMin & fVec <= fMax; end

        % LPF frequency responses
        H_lpf1 = lpfH(glpf1t, glpf1f, Fs, Nfft, types);
        H_lpf2 = lpfH(glpf2t, glpf2f, Fs, Nfft, types);
        H_dlpf1 = lpfH(dlpf1t, dlpf1f, Fs, Nfft, types);
        H_dlpf2 = lpfH(dlpf2t, dlpf2f, Fs, Nfft, types);
        H_gyroLPF = H_lpf1 .* H_lpf2;
        H_dtermLPF = H_dlpf1 .* H_dlpf2;

        % Notch frequency responses (static)
        H_gn1 = notchH(gn1f, gn1c, Fs, Nfft);
        H_gn2 = notchH(gn2f, gn2c, Fs, Nfft);
        H_dn  = notchH(dnf, dnc, Fs, Nfft);

        % RPM harmonic notches (cascaded nMotors times per harmonic)
        rpmCols = {[.9 .2 .2],[.9 .6 .1],[.9 .9 .2],[.3 .8 .3],[.2 .8 .8],[.9 .9 .9],[.8 .3 .8]};
        H_rpm = cell(rpmNharm, 1);
        H_rpm1 = cell(rpmNharm, 1);  % single-motor for phase plot
        H_rpmAll = ones(Nfft, 1);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                H_single = notchH_Q(fc_rpm, rpmQ, Fs, Nfft);
                H_rpm1{ri} = H_single;
                H_rpm{ri} = H_single .^ nMotors;
            else
                H_rpm1{ri} = ones(Nfft, 1);
                H_rpm{ri} = ones(Nfft, 1);
            end
            H_rpmAll = H_rpmAll .* H_rpm{ri};
        end
        H_gyroN = H_gn1 .* H_gn2 .* H_rpmAll;
        % single-motor product for phase plot (avoids ±180 wrapping)
        H_rpmAll1 = ones(Nfft, 1);
        for ri = 1:rpmNharm, H_rpmAll1 = H_rpmAll1 .* H_rpm1{ri}; end
        H_gyroN1 = H_gn1 .* H_gn2 .* H_rpmAll1;
        H_dtermN = H_dn;

        % Group delay
        dw = gradient(2*pi*fVec);
        gd_gL = smooth(-gradient(unwrap(angle(H_gyroLPF))) ./ dw * 1000, 21, 'moving');
        gd_dL = smooth(-gradient(unwrap(angle(H_dtermLPF))) ./ dw * 1000, 21, 'moving');
        gd_gN = smooth(-gradient(unwrap(angle(H_gyroN))) ./ dw * 1000, 51, 'moving');
        gd_dN = smooth(-gradient(unwrap(angle(H_dtermN))) ./ dw * 1000, 51, 'moving');

        delayL = gd_gL(2);
        delayN = gd_gN(2);
        set(hTitleL, 'String', sprintf('LOWPASS FILTERS | Delay %.5fms', delayL));
        set(hTitleN, 'String', sprintf('NOTCH FILTERS | Delay %.4fms', delayN));
        set(h.totalDelay, 'String', sprintf('Total Delay: %.3fms (LPF %.3f + Notch %.3f)', ...
            delayL + delayN, delayL, delayN));

        % Row 4 input signals
        if row4mode == 3
            % Signal Generator: chirp
            sigLen = round(Fs * sigDur);
            tSigL = (0:sigLen-1)' / Fs;
            sigInL = localChirp(tSigL, sigHzLo, sigDur, sigHzHi);
            tSigN = tSigL; sigInN = sigInL;
            r4labelL = 'Duration (sec)'; r4ylabelL = 'Amplitude';
            r4labelN = 'Duration (sec)'; r4ylabelN = 'Amplitude';
        elseif row4mode == 2
            % Impulse response
            lpfStepMs = 4;
            stepLenL = round(Fs * lpfStepMs / 1000);
            sigInL = zeros(stepLenL, 1); sigInL(1) = 1;
            tSigL = (0:stepLenL-1)' / Fs * 1000;
            notchStepMs = 100;
            stepLenN = round(Fs * notchStepMs / 1000);
            sigInN = zeros(stepLenN, 1); sigInN(1) = 1;
            tSigN = (0:stepLenN-1)' / Fs * 1000;
            r4labelL = 'Time (ms)'; r4ylabelL = 'Impulse Resp.';
            r4labelN = 'Time (ms)'; r4ylabelN = 'Impulse Resp.';
        else
            % Step response
            lpfStepMs = 4;
            stepLenL = round(Fs * lpfStepMs / 1000);
            sigInL = ones(stepLenL, 1);
            tSigL = (0:stepLenL-1)' / Fs * 1000;
            notchStepMs = 100;
            stepLenN = round(Fs * notchStepMs / 1000);
            sigInN = ones(stepLenN, 1);
            tSigN = (0:stepLenN-1)' / Fs * 1000;
            r4labelL = 'Time (ms)'; r4ylabelL = 'Step Resp.';
            r4labelN = 'Time (ms)'; r4ylabelN = 'Step Resp.';
        end

        sL_g = applyLPF(applyLPF(sigInL, glpf2t, glpf2f, Fs), glpf1t, glpf1f, Fs);
        sL_d = applyLPF(applyLPF(sigInL, dlpf2t, dlpf2f, Fs), dlpf1t, dlpf1f, Fs);
        sN_g = applyNotch(applyNotch(sigInN, gn2f, gn2c, Fs), gn1f, gn1c, Fs);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                for mi = 1:nMotors
                    sN_g = applyNotch_Q(sN_g, fc_rpm, rpmQ, Fs);
                end
            end
        end
        sN_d = applyNotch(sigInN, dnf, dnc, Fs);
        sN_rpm = cell(rpmNharm, 1);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                tmp = sigInN;
                for mi = 1:nMotors, tmp = applyNotch_Q(tmp, fc_rpm, rpmQ, Fs); end
                sN_rpm{ri} = tmp;
            else
                sN_rpm{ri} = sigInN;
            end
        end
        sN_gn1 = applyNotch(sigInN, gn1f, gn1c, Fs);
        sN_gn2 = applyNotch(sigInN, gn2f, gn2c, Fs);

        if addNoise
            noiseAmp = 0.03;
            noisyL = sigInL + randn(numel(sigInL), 1) * noiseAmp;
            nsL_g = applyLPF(applyLPF(noisyL, glpf2t, glpf2f, Fs), glpf1t, glpf1f, Fs);
            nsL_d = applyLPF(applyLPF(noisyL, dlpf2t, dlpf2f, Fs), dlpf1t, dlpf1f, Fs);
            noisyN = sigInN + randn(numel(sigInN), 1) * noiseAmp;
            nsN_g = applyNotch(applyNotch(noisyN, gn2f, gn2c, Fs), gn1f, gn1c, Fs);
            for ri = 1:rpmNharm
                fc_rpm = rpmBase * ri;
                if fc_rpm > 0 && fc_rpm < Fs/2
                    for mi = 1:nMotors, nsN_g = applyNotch_Q(nsN_g, fc_rpm, rpmQ, Fs); end
                end
            end
            nsN_d = applyNotch(noisyN, dnf, dnc, Fs);
        end

        colG = [0 .85 .85]; colD = [.4 .9 .4];
        colRef = [.45 .45 .45];
        % Notch column: warm colors
        colStaticN = [1 .65 .2];
        colCombN = [.95 .85 .2];
        plotFn = @plot;

        %% GRADIENT FREQUENCY BARS
        drawGradientBar(axBarL, fMax, [.2 .7 .8; .3 .9 .5], ...
            {glpf1f, glpf2f, dlpf1f, dlpf2f}, {colG*0.7, colG, colD*0.7, colD}, thm);
        set(axBarL, 'ButtonDownFcn', @(~,~) barClick(axBarL, {h.glpf1_hz, h.glpf2_hz, h.dlpf1_hz, h.dlpf2_hz}, fMax));
        notchFreqs = {}; notchCols = {};
        for ri = 1:rpmNharm
            ci = min(ri, numel(rpmCols));
            notchFreqs{end+1} = rpmBase * ri;
            notchCols{end+1} = rpmCols{ci};
        end
        if gn1f > 0, notchFreqs{end+1} = gn1f; notchCols{end+1} = colStaticN; end
        if gn2f > 0, notchFreqs{end+1} = gn2f; notchCols{end+1} = colStaticN*0.85; end
        if dnf > 0, notchFreqs{end+1} = dnf; notchCols{end+1} = colD; end
        drawGradientBar(axBarN, fMax, [.8 .3 .2; .9 .7 .2], notchFreqs, notchCols, thm);
        set(axBarN, 'ButtonDownFcn', @(~,~) barClick(axBarN, {h.gn1_hz, h.gn2_hz, h.dn_hz}, fMax));

        %% TEST SIGNAL PSD (if sigHzHi > sigHzLo)
        if sigHzHi > sigHzLo && sigDur > 0
            Nsig = round(Fs * sigDur);
            t_sig = (0:Nsig-1)' / Fs;
            sig = localChirp(t_sig, max(sigHzLo,1), sigDur, sigHzHi);
            sig_gL = sig;
            if glpf1t > 0 && glpf1f > 0, sig_gL = applyLPF(sig_gL, glpf1t, glpf1f, Fs); end
            if glpf2t > 0 && glpf2f > 0, sig_gL = applyLPF(sig_gL, glpf2t, glpf2f, Fs); end
            sig_gN = sig;
            if gn1f > 0, sig_gN = applyNotch(sig_gN, gn1f, gn1c, Fs); end
            if gn2f > 0, sig_gN = applyNotch(sig_gN, gn2f, gn2c, Fs); end
            for ri = 1:rpmNharm
                fc_rpm = rpmBase * ri;
                if fc_rpm > 0 && fc_rpm < Fs/2
                    for mi = 1:nMotors, sig_gN = applyNotch_Q(sig_gN, fc_rpm, rpmQ, Fs); end
                end
            end
        end

        %% LOWPASS COLUMN

        % Individual filter responses for non-combined mode
        gd_g1 = smooth(-gradient(unwrap(angle(H_lpf1))) ./ dw * 1000, 21, 'moving');
        gd_g2 = smooth(-gradient(unwrap(angle(H_lpf2))) ./ dw * 1000, 21, 'moving');
        gd_d1 = smooth(-gradient(unwrap(angle(H_dlpf1))) ./ dw * 1000, 21, 'moving');
        gd_d2 = smooth(-gradient(unwrap(angle(H_dlpf2))) ./ dw * 1000, 21, 'moving');
        ph_g1 = unwrap(angle(H_lpf1)) * 180/pi;
        ph_g2 = unwrap(angle(H_lpf2)) * 180/pi;
        ph_d1 = unwrap(angle(H_dlpf1)) * 180/pi;
        ph_d2 = unwrap(angle(H_dlpf2)) * 180/pi;
        sL_g1 = applyLPF(sigInL, glpf1t, glpf1f, Fs);
        sL_g2 = applyLPF(sigInL, glpf2t, glpf2f, Fs);
        sL_d1 = applyLPF(sigInL, dlpf1t, dlpf1f, Fs);
        sL_d2 = applyLPF(sigInL, dlpf2t, dlpf2f, Fs);

        g1on = glpf1t > 0 && glpf1f > 0;
        g2on = glpf2t > 0 && glpf2f > 0;
        d1on = dlpf1t > 0 && dlpf1f > 0;
        d2on = dlpf2t > 0 && dlpf2f > 0;
        colNoise = [.9 .25 .25];

        applyLayout();
        fF = fVec(fIdx);

        if doLPF  % --- LPF COLUMN ---

        %% LOWPASS MAGNITUDE (pre-created lines)
        li = 1;
        if combineLPF
            li = setLine(AX_LMAG, li, fF, magY(H_gyroLPF(fIdx), usedB), colG, 1.5);
            li = setLine(AX_LMAG, li, fF, magY(H_dtermLPF(fIdx), usedB), colD, 1.2);
        else
            if g1on, li = setLine(AX_LMAG, li, fF, magY(H_lpf1(fIdx), usedB), colG, 1.2); end
            if g2on, li = setLine(AX_LMAG, li, fF, magY(H_lpf2(fIdx), usedB), colG, 1.2, '--'); end
            if d1on, li = setLine(AX_LMAG, li, fF, magY(H_dlpf1(fIdx), usedB), colD, 1.0); end
            if d2on, li = setLine(AX_LMAG, li, fF, magY(H_dlpf2(fIdx), usedB), colD, 1.0, '--'); end
        end
        if showBoth
            li = setLine(AX_LMAG, li, fF, magY(H_gyroN(fIdx), usedB), colCombN, 1.2);
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                li = setLine(AX_LMAG, li, fF, magY(H_rpm{ri}(fIdx), usedB), rpmCols{ci}, 0.7);
            end
        end
        fLo = xlimF(useLog, fMax);
        refY = 0.707; if usedB, refY = -3; end
        li = setLine(AX_LMAG, li, [fLo(1) fMax], [refY refY], thm.refLine3dB, 0.5, ':');
        % cutoff vertical lines (gyro + dterm)
        magYL = [0 1.1]; if usedB, magYL = [-60 3]; end
        if g1on && glpf1f > 0, li = setLine(AX_LMAG, li, [glpf1f glpf1f], magYL, colG*0.7, 0.5, '--'); end
        if g2on && glpf2f > 0, li = setLine(AX_LMAG, li, [glpf2f glpf2f], magYL, colG, 0.5, '--'); end
        if d1on && dlpf1f > 0, li = setLine(AX_LMAG, li, [dlpf1f dlpf1f], magYL, colD*0.7, 0.5, '--'); end
        if d2on && dlpf2f > 0, li = setLine(AX_LMAG, li, [dlpf2f dlpf2f], magYL, colD, 0.5, '--'); end
        hideRest(AX_LMAG, li);
        if usedB
            set(axLmag, 'XLim', fLo, 'YLim', [-60 3], 'XTickLabel', {});
            set(get(axLmag, 'YLabel'), 'String', 'Magnitude (dB)');
        else
            set(axLmag, 'XLim', fLo, 'YLim', [0 1.1], 'XTickLabel', {});
            set(get(axLmag, 'YLabel'), 'String', 'Magnitude (abs)');
        end
        % annotations (text + cutoff lines via txPool)
        ti = 1;
        names_ = {'off', 'pt1', 'biquad', 'pt2', 'pt3'};
        if usedB, ay = -3; ayd = -6; else ay = 1.05; ayd = -0.08; end
        if glpf1t > 0 && glpf1f > 0
            ti = setTxt(AX_LMAG, ti, glpf1f+10, ay, sprintf('%s: %dHz', names_{glpf1t+1}, glpf1f), colG*0.7);
            ay = ay + ayd;
        end
        if glpf2t > 0 && glpf2f > 0
            ti = setTxt(AX_LMAG, ti, glpf2f+10, ay, sprintf('%s: %dHz', names_{glpf2t+1}, glpf2f), colG);
            ay = ay + ayd;
        end
        if dlpf1t > 0 && dlpf1f > 0
            ti = setTxt(AX_LMAG, ti, dlpf1f+10, ay, sprintf('D %s: %dHz', names_{dlpf1t+1}, dlpf1f), colD*0.7);
            ay = ay + ayd;
        end
        if dlpf2t > 0 && dlpf2f > 0
            ti = setTxt(AX_LMAG, ti, dlpf2f+10, ay, sprintf('D %s: %dHz', names_{dlpf2t+1}, dlpf2f), colD);
        end
        hideTxt(AX_LMAG, ti);

        %% LOWPASS DELAY (pre-created lines)
        li = 1;
        if combineLPF
            li = setLine(AX_LDLY, li, fF, gd_gL(fIdx), colG, 1.5);
            li = setLine(AX_LDLY, li, fF, gd_dL(fIdx), colD, 1.2);
            gdMax = max([max(gd_gL(fIdx)) max(gd_dL(fIdx)) 0.3]) * 1.3;
        else
            allGdL = [0.3];
            if g1on, li = setLine(AX_LDLY, li, fF, gd_g1(fIdx), colG, 1.2); allGdL(end+1) = max(gd_g1(fIdx)); end
            if g2on, li = setLine(AX_LDLY, li, fF, gd_g2(fIdx), colG, 1.2, '--'); allGdL(end+1) = max(gd_g2(fIdx)); end
            if d1on, li = setLine(AX_LDLY, li, fF, gd_d1(fIdx), colD, 1.0); allGdL(end+1) = max(gd_d1(fIdx)); end
            if d2on, li = setLine(AX_LDLY, li, fF, gd_d2(fIdx), colD, 1.0, '--'); allGdL(end+1) = max(gd_d2(fIdx)); end
            gdMax = max(allGdL) * 1.3;
        end
        if showBoth
            li = setLine(AX_LDLY, li, fF, gd_gN(fIdx), colCombN, 1.2);
        end
        % cutoff lines (gyro + dterm)
        if g1on && glpf1f > 0, li = setLine(AX_LDLY, li, [glpf1f glpf1f], [0 gdMax], colG*0.7, 0.5, '--'); end
        if g2on && glpf2f > 0, li = setLine(AX_LDLY, li, [glpf2f glpf2f], [0 gdMax], colG, 0.5, '--'); end
        if d1on && dlpf1f > 0, li = setLine(AX_LDLY, li, [dlpf1f dlpf1f], [0 gdMax], colD*0.7, 0.5, '--'); end
        if d2on && dlpf2f > 0, li = setLine(AX_LDLY, li, [dlpf2f dlpf2f], [0 gdMax], colD, 0.5, '--'); end
        hideRest(AX_LDLY, li);
        set(axLdelay, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
        if isfinite(gdMax) && gdMax > 0, set(axLdelay, 'YLim', [0 gdMax]); end
        set(get(axLdelay, 'YLabel'), 'String', 'Filter Delay (ms)');
        % delay annotations
        ti = 1;
        yTxtL = gdMax * 0.92; yTxtStp = gdMax * 0.17;
        if combineLPF
            ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL, sprintf('gyro lpf: %.5fms', gd_gL(2)), colG);
            ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL-yTxtStp, sprintf('dterm lpf: %.5fms', gd_dL(2)), colD);
        else
            if g1on, ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL, sprintf('gyro lpf1: %.5fms', gd_g1(2)), colG*0.7); yTxtL=yTxtL-yTxtStp; end
            if g2on, ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL, sprintf('gyro lpf2: %.5fms', gd_g2(2)), colG); yTxtL=yTxtL-yTxtStp; end
            if d1on, ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL, sprintf('dterm lpf1: %.5fms', gd_d1(2)), colD*0.7); yTxtL=yTxtL-yTxtStp; end
            if d2on, ti = setTxt(AX_LDLY, ti, fMax*0.02, yTxtL, sprintf('dterm lpf2: %.5fms', gd_d2(2)), colD); end
        end
        hideTxt(AX_LDLY, ti);

        %% LOWPASS PHASE (pre-created lines)
        li = 1;
        if combineLPF
            ph_gL = unwrap(angle(H_gyroLPF)) * 180/pi;
            ph_dL = unwrap(angle(H_dtermLPF)) * 180/pi;
            li = setLine(AX_LPH, li, fF, ph_gL(fIdx), colG, 1.5);
            li = setLine(AX_LPH, li, fF, ph_dL(fIdx), colD, 1.2);
        else
            if g1on, li = setLine(AX_LPH, li, fF, ph_g1(fIdx), colG, 1.2); end
            if g2on, li = setLine(AX_LPH, li, fF, ph_g2(fIdx), colG, 1.2, '--'); end
            if d1on, li = setLine(AX_LPH, li, fF, ph_d1(fIdx), colD, 1.0); end
            if d2on, li = setLine(AX_LPH, li, fF, ph_d2(fIdx), colD, 1.0, '--'); end
        end
        if showBoth
            ph_gN_ = smooth(angle(H_gyroN1) * 180/pi, 9, 'moving');
            li = setLine(AX_LPH, li, fF, ph_gN_(fIdx), colCombN, 1.2);
        end
        if g1on && glpf1f > 0, li = setLine(AX_LPH, li, [glpf1f glpf1f], [-200 0], colG*0.7, 0.5, '--'); end
        if g2on && glpf2f > 0, li = setLine(AX_LPH, li, [glpf2f glpf2f], [-200 0], colG, 0.5, '--'); end
        if d1on && dlpf1f > 0, li = setLine(AX_LPH, li, [dlpf1f dlpf1f], [-200 0], colD*0.7, 0.5, '--'); end
        if d2on && dlpf2f > 0, li = setLine(AX_LPH, li, [dlpf2f dlpf2f], [-200 0], colD, 0.5, '--'); end
        hideRest(AX_LPH, li);
        set(axLphase, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
        set(get(axLphase, 'YLabel'), 'String', 'Phase Delay (deg)');
        hideTxt(AX_LPH, 1);

        %% LOWPASS ROW 4 (pre-created lines)
        li = 1;
        if row4mode == 3
            li = setLine(AX_LSTP, li, tSigL, sigInL, [.5 .5 .5], 0.6);
            li = setLine(AX_LSTP, li, tSigL, sL_g, [.95 .2 .2], 1.2);
            hideRest(AX_LSTP, li);
            set(axLstep, 'XLim', [0 sigDur], 'YLim', [-1.1 1.1]);
        else
            if row4mode == 1
                li = setLine(AX_LSTP, li, [tSigL(1) tSigL(end)], [1 1], colRef, 0.5, '--');
            end
            if combineLPF
                li = setLine(AX_LSTP, li, tSigL, sL_g, colG, 1.5);
                li = setLine(AX_LSTP, li, tSigL, sL_d, colD, 1.2);
                if addNoise
                    li = setLine(AX_LSTP, li, tSigL, nsL_g, colNoise, 0.8);
                    li = setLine(AX_LSTP, li, tSigL, nsL_d, colNoise*0.7, 0.7);
                end
            else
                if g1on, li = setLine(AX_LSTP, li, tSigL, sL_g1, colG, 1.2); end
                if g2on, li = setLine(AX_LSTP, li, tSigL, sL_g2, colG, 1.2, '--'); end
                if d1on, li = setLine(AX_LSTP, li, tSigL, sL_d1, colD, 1.0); end
                if d2on, li = setLine(AX_LSTP, li, tSigL, sL_d2, colD, 1.0, '--'); end
                if addNoise
                    li = setLine(AX_LSTP, li, tSigL, nsL_g, colNoise, 0.8);
                    li = setLine(AX_LSTP, li, tSigL, nsL_d, colNoise*0.7, 0.7);
                end
            end
            hideRest(AX_LSTP, li);
            if row4mode == 1
                set(axLstep, 'XLim', [tSigL(1) tSigL(end)], 'YLim', [-0.05 1.15]);
            else
                set(axLstep, 'XLim', [tSigL(1) tSigL(end)]);
            end
        end
        xlabel(axLstep, r4labelL, 'Color', thm.textPrimary);
        set(get(axLstep, 'YLabel'), 'String', r4ylabelL);
        hideTxt(AX_LSTP, 1);
        end  % if doLPF

        %% NOTCH COLUMN (skip when showBoth)

        if doNotch && ~showBoth
            gridC = thm.gridColor;

            %% NOTCH MAGNITUDE
            li = 1;
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                li = setLine(AX_NMAG, li, fF, magY(H_rpm{ri}(fIdx), usedB), rpmCols{ci}, 0.9);
            end
            if gn1f > 0, li = setLine(AX_NMAG, li, fF, magY(H_gn1(fIdx), usedB), colStaticN, 0.8); end
            if gn2f > 0, li = setLine(AX_NMAG, li, fF, magY(H_gn2(fIdx), usedB), colStaticN*0.85, 0.8, '--'); end
            li = setLine(AX_NMAG, li, fF, magY(H_gyroN(fIdx), usedB), colCombN, 1.5);
            if dnf > 0, li = setLine(AX_NMAG, li, fF, magY(H_dtermN(fIdx), usedB), colD, 1.2); end
            % notch vertical lines
            for ri = 1:rpmNharm, fc=rpmBase*ri; if fc>0, li=setLine(AX_NMAG,li,[fc fc],[0 1.1],gridC,0.5,':'); end; end
            if gn1f>0, li=setLine(AX_NMAG,li,[gn1f gn1f],[0 1.1],colStaticN,0.5,'--'); end
            if gn2f>0, li=setLine(AX_NMAG,li,[gn2f gn2f],[0 1.1],colStaticN*0.85,0.5,'--'); end
            if dnf>0, li=setLine(AX_NMAG,li,[dnf dnf],[0 1.1],colD,0.5,'--'); end
            hideRest(AX_NMAG, li);
            if usedB
                set(axNmag, 'XLim', xlimF(useLog, fMax), 'YLim', [-40 3], 'XTickLabel', {});
                set(get(axNmag, 'YLabel'), 'String', 'Magnitude (dB)');
            else
                set(axNmag, 'XLim', xlimF(useLog, fMax), 'YLim', [0 1.1], 'XTickLabel', {});
                set(get(axNmag, 'YLabel'), 'String', 'Magnitude (abs)');
            end
            % annotations
            ti = 1;
            if usedB, ay0=-5; ayd=-5; else ay0=0.85; ayd=-0.07; end
            ay = ay0;
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols)); fc=rpmBase*ri;
                ti = setTxt(AX_NMAG, ti, fc+10, ay, sprintf('RPM: %dHz', fc), rpmCols{ci}); ay=ay+ayd;
            end
            if gn1f>0, ti=setTxt(AX_NMAG,ti,gn1f+10,ay,sprintf('N1: %dHz',gn1f),colStaticN); ay=ay+ayd; end
            if gn2f>0, ti=setTxt(AX_NMAG,ti,gn2f+10,ay,sprintf('N2: %dHz',gn2f),colStaticN*0.85); ay=ay+ayd; end
            if dnf>0, ti=setTxt(AX_NMAG,ti,dnf+10,ay,sprintf('D: %dHz',dnf),colD); end
            hideTxt(AX_NMAG, ti);

            %% NOTCH DELAY
            li = 1;
            rpmGd1 = cell(rpmNharm, 1);
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                rpmGd1{ri} = smooth(-gradient(unwrap(angle(H_rpm1{ri}))) ./ dw * 1000, 51, 'moving');
                li = setLine(AX_NDLY, li, fF, rpmGd1{ri}(fIdx), rpmCols{ci}, 0.9);
            end
            if gn1f > 0
                gd_gn1_v = smooth(-gradient(unwrap(angle(H_gn1))) ./ dw * 1000, 51, 'moving');
                li = setLine(AX_NDLY, li, fF, gd_gn1_v(fIdx), colStaticN, 0.8);
            end
            if gn2f > 0
                gd_gn2_v = smooth(-gradient(unwrap(angle(H_gn2))) ./ dw * 1000, 51, 'moving');
                li = setLine(AX_NDLY, li, fF, gd_gn2_v(fIdx), colStaticN*0.85, 0.8, '--');
            end
            li = setLine(AX_NDLY, li, fF, gd_gN(fIdx), colCombN, 1.5);
            if dnf > 0, li = setLine(AX_NDLY, li, fF, gd_dN(fIdx), colD, 1.2); end
            % vertical lines
            for ri=1:rpmNharm, fc=rpmBase*ri; if fc>0, li=setLine(AX_NDLY,li,[fc fc],[-1 1],gridC,0.5,':'); end; end
            if gn1f>0, li=setLine(AX_NDLY,li,[gn1f gn1f],[-1 1],colStaticN,0.5,'--'); end
            if gn2f>0, li=setLine(AX_NDLY,li,[gn2f gn2f],[-1 1],colStaticN*0.85,0.5,'--'); end
            if dnf>0, li=setLine(AX_NDLY,li,[dnf dnf],[-1 1],colD,0.5,'--'); end
            hideRest(AX_NDLY, li);
            gdMaxN = max(abs(gd_gN(2)) * 3, 0.5);
            if isfinite(gdMaxN), set(axNdelay, 'YLim', [-gdMaxN gdMaxN]); end
            set(axNdelay, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
            set(get(axNdelay, 'YLabel'), 'String', 'Filter Delay (ms)');
            % annotations
            ti = 1; nAn = max(rpmNharm+2, 2);
            yTxt = gdMaxN*0.9; yStN = 2*gdMaxN*0.9/nAn;
            ti = setTxt(AX_NDLY, ti, fMax*0.3, yTxt, sprintf('combined: %.4fms', gd_gN(2)), colCombN); yTxt=yTxt-yStN;
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols)); fc=rpmBase*ri;
                ti = setTxt(AX_NDLY, ti, fMax*0.3, yTxt, sprintf('RPM %dHz: %.5fms', fc, rpmGd1{ri}(2)), rpmCols{ci}); yTxt=yTxt-yStN;
            end
            if gn1f>0, ti=setTxt(AX_NDLY,ti,fMax*0.3,yTxt,sprintf('N1 %dHz: %.5fms',gn1f,gd_gn1_v(2)),colStaticN); yTxt=yTxt-yStN; end
            if gn2f>0, ti=setTxt(AX_NDLY,ti,fMax*0.3,yTxt,sprintf('N2 %dHz: %.5fms',gn2f,gd_gn2_v(2)),colStaticN*0.85); yTxt=yTxt-yStN; end
            if dnf>0, ti=setTxt(AX_NDLY,ti,fMax*0.3,yTxt,sprintf('D %dHz: %.4fms',dnf,gd_dN(2)),colD); end
            hideTxt(AX_NDLY, ti);

            %% NOTCH PHASE
            li = 1;
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                ph_ri = smooth(angle(H_rpm1{ri}) * 180/pi, 9, 'moving');
                li = setLine(AX_NPH, li, fF, ph_ri(fIdx), rpmCols{ci}, 0.9);
            end
            if gn1f > 0
                ph_gn1_ = smooth(angle(H_gn1) * 180/pi, 9, 'moving');
                li = setLine(AX_NPH, li, fF, ph_gn1_(fIdx), colStaticN, 0.8);
            end
            if gn2f > 0
                ph_gn2_ = smooth(angle(H_gn2) * 180/pi, 9, 'moving');
                li = setLine(AX_NPH, li, fF, ph_gn2_(fIdx), colStaticN*0.85, 0.8, '--');
            end
            ph_gN = smooth(angle(H_gyroN1) * 180/pi, 9, 'moving');
            ph_dN_ = smooth(angle(H_dtermN) * 180/pi, 9, 'moving');
            li = setLine(AX_NPH, li, fF, ph_gN(fIdx), colCombN, 1.5);
            if dnf > 0, li = setLine(AX_NPH, li, fF, ph_dN_(fIdx), colD, 1.2); end
            for ri=1:rpmNharm, fc=rpmBase*ri; if fc>0, li=setLine(AX_NPH,li,[fc fc],[-90 90],gridC,0.5,':'); end; end
            if gn1f>0, li=setLine(AX_NPH,li,[gn1f gn1f],[-90 90],colStaticN,0.5,'--'); end
            if gn2f>0, li=setLine(AX_NPH,li,[gn2f gn2f],[-90 90],colStaticN*0.85,0.5,'--'); end
            if dnf>0, li=setLine(AX_NPH,li,[dnf dnf],[-90 90],colD,0.5,'--'); end
            hideRest(AX_NPH, li);
            set(axNphase, 'XLim', xlimF(useLog, fMax), 'YLim', [-90 90], 'XTickLabel', {});
            set(get(axNphase, 'YLabel'), 'String', 'Phase Delay (deg)');
            hideTxt(AX_NPH, 1);

            %% NOTCH ROW 4
            li = 1;
            if row4mode == 3
                li = setLine(AX_NSTP, li, tSigN, sigInN, [.5 .5 .5], 0.6);
                li = setLine(AX_NSTP, li, tSigN, sN_g, [.95 .2 .2], 1.2);
                hideRest(AX_NSTP, li);
                set(axNstep, 'XLim', [0 sigDur], 'YLim', [-1.1 1.1]);
            else
                if row4mode == 1, li = setLine(AX_NSTP, li, [tSigN(1) tSigN(end)], [1 1], colRef, 0.5, '--'); end
                for ri = 1:rpmNharm
                    ci = min(ri, numel(rpmCols));
                    li = setLine(AX_NSTP, li, tSigN, sN_rpm{ri}, rpmCols{ci}, 0.8);
                end
                if gn1f > 0, li = setLine(AX_NSTP, li, tSigN, sN_gn1, colStaticN, 0.8); end
                if gn2f > 0, li = setLine(AX_NSTP, li, tSigN, sN_gn2, colStaticN*0.85, 0.8, '--'); end
                li = setLine(AX_NSTP, li, tSigN, sN_g, colCombN, 1.5);
                if dnf > 0, li = setLine(AX_NSTP, li, tSigN, sN_d, colD, 1.2); end
                if addNoise
                    li = setLine(AX_NSTP, li, tSigN, nsN_g, colNoise, 0.8);
                    if dnf > 0, li = setLine(AX_NSTP, li, tSigN, nsN_d, colNoise*0.7, 0.7); end
                end
                hideRest(AX_NSTP, li);
                if row4mode == 1
                    set(axNstep, 'XLim', [tSigN(1) tSigN(end)], 'YLim', [0.8 1.2]);
                else
                    set(axNstep, 'XLim', [tSigN(1) tSigN(end)]);
                end
            end
            xlabel(axNstep, r4labelN, 'Color', thm.textPrimary);
            set(get(axNstep, 'YLabel'), 'String', r4ylabelN);
            hideTxt(AX_NSTP, 1);
        end

        % Set XScale+XLim atomically
        xl = xlimF(useLog, fMax);
        if useLog, xsc = 'log'; else xsc = 'linear'; end
        for axi = 1:numel(allFreqAx)
            if ishandle(allFreqAx(axi)), set(allFreqAx(axi), 'XLim', xl, 'XScale', xsc); end
        end

        warning(wstate);
    end

    function copyCLI()
        typeNames = {'PT1', 'BIQUAD', 'PT2', 'PT3'};
        lines = {};
        lines{end+1} = '# PIDscope Filter Sim -> BF CLI';
        lines{end+1} = '# Gyro Lowpass';
        t = cliTypeIdx(h.glpf1_type);
        lines{end+1} = sprintf('set gyro_lpf1_type = %s', typeNames{max(t,1)});
        lines{end+1} = sprintf('set gyro_lpf1_static_hz = %d', cliHz(h.glpf1_hz, t));
        t = cliTypeIdx(h.glpf2_type);
        lines{end+1} = sprintf('set gyro_lpf2_type = %s', typeNames{max(t,1)});
        lines{end+1} = sprintf('set gyro_lpf2_static_hz = %d', cliHz(h.glpf2_hz, t));
        lines{end+1} = '# Gyro Notch';
        lines{end+1} = sprintf('set gyro_notch1_hz = %d', readEdit(h.gn1_hz));
        lines{end+1} = sprintf('set gyro_notch1_cutoff = %d', readEdit(h.gn1_cut));
        lines{end+1} = sprintf('set gyro_notch2_hz = %d', readEdit(h.gn2_hz));
        lines{end+1} = sprintf('set gyro_notch2_cutoff = %d', readEdit(h.gn2_cut));
        lines{end+1} = '# D-term Lowpass';
        t = cliTypeIdx(h.dlpf1_type);
        lines{end+1} = sprintf('set dterm_lpf1_type = %s', typeNames{max(t,1)});
        lines{end+1} = sprintf('set dterm_lpf1_static_hz = %d', cliHz(h.dlpf1_hz, t));
        t = cliTypeIdx(h.dlpf2_type);
        lines{end+1} = sprintf('set dterm_lpf2_type = %s', typeNames{max(t,1)});
        lines{end+1} = sprintf('set dterm_lpf2_static_hz = %d', cliHz(h.dlpf2_hz, t));
        lines{end+1} = '# D-term Notch';
        lines{end+1} = sprintf('set dterm_notch_hz = %d', readEdit(h.dn_hz));
        lines{end+1} = sprintf('set dterm_notch_cutoff = %d', readEdit(h.dn_cut));
        lines{end+1} = 'save';
        cliText = strjoin(lines, char(10));
        ok = copyToClipboard(cliText);
        if ok
            set(h.copyCLI, 'String', 'Copied!');
        else
            showCLIDialog(cliText);
        end
    end

    function t = cliTypeIdx(hPopup)
        v = get(hPopup, 'Value');
        t = max(v - 1, 0);
    end

    function hz = cliHz(hEdit, typeVal)
        if typeVal == 0, hz = 0; return; end
        hz = readEdit(hEdit);
    end

    function idx = setLine(axi, idx, x, y, col, lw, ls)
        % update pre-created line from pool
        if nargin < 7, ls = '-'; end
        set(lnPool{axi, idx}, 'XData', x, 'YData', y, 'Color', col, ...
            'LineWidth', lw, 'LineStyle', ls, 'Visible', 'on');
        idx = idx + 1;
    end

    function hideRest(axi, fromIdx)
        for li = fromIdx:POOL
            set(lnPool{axi, li}, 'Visible', 'off', 'XData', NaN, 'YData', NaN);
        end
    end

    function idx = setTxt(axi, idx, x, y, str, col)
        set(txPool{axi, idx}, 'Position', [x y 0], 'String', str, 'Color', col, 'Visible', 'on');
        idx = idx + 1;
    end

    function hideTxt(axi, fromIdx)
        for ti = fromIdx:TPOOL
            set(txPool{axi, ti}, 'Visible', 'off', 'String', '');
        end
    end

    function barClick(ax, edits, fMax)
        if isempty(edits), return; end
        cp = get(ax, 'CurrentPoint');
        xClick = max(0, min(fMax, round(cp(1,1))));
        % find nearest edit box by current value
        bestDist = inf; bestIdx = 1;
        for ei = 1:numel(edits)
            ev = str2double(get(edits{ei}, 'String'));
            if isnan(ev), ev = 0; end
            d = abs(ev - xClick);
            if d < bestDist, bestDist = d; bestIdx = ei; end
        end
        set(edits{bestIdx}, 'String', int2str(xClick));
        autoUpdate();
    end

end

%% helpers
function y = magY(H, usedB)
    if usedB
        y = 20*log10(abs(H) + 1e-12);
    else
        y = abs(H);
    end
end

function xl = xlimF(useLog, fMax)
    if useLog, xl = [10 fMax]; else xl = [0 fMax]; end
end

function y = applyLPF(x, type, hz, Fs)
    if type == 0 || hz == 0, y = x; return; end
    types = {'pt1', 'biquad', 'pt2', 'pt3'};
    if type > numel(types), y = x; return; end
    [b, a] = PSbfFilters(types{type}, hz, Fs);
    y = filter(b, a, x);
end

function y = applyNotch(x, center_hz, cutoff_hz, Fs)
    if center_hz == 0, y = x; return; end
    if cutoff_hz <= 0, cutoff_hz = center_hz * 0.7; end
    Q = center_hz / (center_hz - cutoff_hz + 1);
    [b, a] = PSbfFilters('notch', center_hz, Fs, Q);
    y = filter(b, a, x);
end

function y = applyNotch_Q(x, center_hz, Q, Fs)
    if center_hz == 0, y = x; return; end
    [b, a] = PSbfFilters('notch', center_hz, Fs, Q/100);
    y = filter(b, a, x);
end

function H = lpfH(type, hz, Fs, Nfft, types)
    H = ones(Nfft, 1);
    if type == 0 || hz == 0 || type > numel(types), return; end
    [b, a] = PSbfFilters(types{type}, hz, Fs);
    [H, ~] = freqz(b, a, Nfft, Fs);
    H = H(:);
end

function H = notchH(center_hz, cutoff_hz, Fs, Nfft)
    H = ones(Nfft, 1);
    if center_hz == 0, return; end
    if cutoff_hz <= 0, cutoff_hz = center_hz * 0.7; end
    Q = center_hz / (center_hz - cutoff_hz + 1);
    [b, a] = PSbfFilters('notch', center_hz, Fs, Q);
    [H, ~] = freqz(b, a, Nfft, Fs);
    H = H(:);
end

function H = notchH_Q(center_hz, Q, Fs, Nfft)
    H = ones(Nfft, 1);
    if center_hz == 0, return; end
    [b, a] = PSbfFilters('notch', center_hz, Fs, Q/100);
    [H, ~] = freqz(b, a, Nfft, Fs);
    H = H(:);
end

function drawCutoffLines(ax, f1on, f1, f2on, f2, col)
    yl = get(ax, 'YLim');
    if f1on && f1 > 0, line(ax, [f1 f1], yl, 'Color', col*0.7, 'LineStyle', '--', 'LineWidth', 0.5, 'HitTest', 'off'); end
    if f2on && f2 > 0, line(ax, [f2 f2], yl, 'Color', col, 'LineStyle', '--', 'LineWidth', 0.5, 'HitTest', 'off'); end
end

function drawNotchLines(ax, rpmBase, rpmNharm, gn1f, gn2f, dnf, gridCol)
    yl = get(ax, 'YLim');
    for ri = 1:rpmNharm
        fc = rpmBase * ri;
        if fc > 0, line(ax, [fc fc], yl, 'Color', gridCol, 'LineStyle', ':', 'LineWidth', 0.5, 'HitTest', 'off'); end
    end
    if gn1f > 0, line(ax, [gn1f gn1f], yl, 'Color', gridCol, 'LineStyle', '--', 'LineWidth', 0.5, 'HitTest', 'off'); end
    if gn2f > 0, line(ax, [gn2f gn2f], yl, 'Color', gridCol, 'LineStyle', '--', 'LineWidth', 0.5, 'HitTest', 'off'); end
    if dnf > 0, line(ax, [dnf dnf], yl, 'Color', gridCol, 'LineStyle', '--', 'LineWidth', 0.5, 'HitTest', 'off'); end
end

function annotateLPF(ax, t1, f1, t2, f2, ~, col, fsz, usedB)
    names = {'off', 'pt1', 'biquad', 'pt2', 'pt3'};
    if usedB, yLim = [-60 3]; y = -3; yd = -6;
    else yLim = [0 1.1]; y = 1.05; yd = -0.08; end
    if t1 > 0 && f1 > 0
        text(f1+10, y, sprintf('%s: %dHz', names{t1+1}, f1), 'Parent', ax, ...
            'Color', col*0.7, 'FontSize', fsz-1);
        line(ax, [f1 f1], yLim, 'Color', col*0.7, 'LineStyle', '--', 'LineWidth', 0.5);
        y = y + yd;
    end
    if t2 > 0 && f2 > 0
        text(f2+10, y, sprintf('%s: %dHz', names{t2+1}, f2), 'Parent', ax, ...
            'Color', col, 'FontSize', fsz-1);
        line(ax, [f2 f2], yLim, 'Color', col, 'LineStyle', '--', 'LineWidth', 0.5);
    end
end

function annotateNotch(ax, gn1f, gn2f, dnf, rpmBase, rpmNharm, rpmCols, colStaticN, colCombN, colD, fsz, usedB)
    if usedB, y0 = -5; yd = -5; yLim = [-40 3];
    else y0 = 0.85; yd = -0.07; yLim = [0 1.1]; end
    y = y0;
    for ri = 1:rpmNharm
        ci = min(ri, numel(rpmCols));
        fc = rpmBase * ri;
        text(fc+10, y, sprintf('RPM: %dHz', fc), 'Parent', ax, ...
            'Color', rpmCols{ci}, 'FontSize', fsz-1);
        line(ax, [fc fc], yLim, 'Color', rpmCols{ci}, 'LineStyle', '--', 'LineWidth', 0.5);
        y = y + yd;
    end
    if gn1f > 0
        text(gn1f+10, y, sprintf('N1: %dHz', gn1f), 'Parent', ax, ...
            'Color', colStaticN, 'FontSize', fsz-1);
        line(ax, [gn1f gn1f], yLim, 'Color', colStaticN, 'LineStyle', '--', 'LineWidth', 0.5);
        y = y + yd;
    end
    if gn2f > 0
        text(gn2f+10, y, sprintf('N2: %dHz', gn2f), 'Parent', ax, ...
            'Color', colStaticN*0.85, 'FontSize', fsz-1);
        line(ax, [gn2f gn2f], yLim, 'Color', colStaticN*0.85, 'LineStyle', '--', 'LineWidth', 0.5);
        y = y + yd;
    end
    if dnf > 0
        text(dnf+10, y, sprintf('D: %dHz', dnf), 'Parent', ax, ...
            'Color', colD, 'FontSize', fsz-1);
        line(ax, [dnf dnf], yLim, 'Color', colD, 'LineStyle', '--', 'LineWidth', 0.5);
    end
end

% parseFilterParams/hval/hstr moved to src/util/PSparseFilterParams.m

function mkSection(fig, txt, cpL, row, cpW, rh, bgc, col, fsz)
    uicontrol(fig, 'Style', 'text', 'String', txt, ...
        'Units', 'normalized', 'Position', [cpL+.01 row cpW-.02 rh], ...
        'FontSize', fsz, 'FontWeight', 'bold', 'BackgroundColor', bgc, 'ForegroundColor', col);
end

function [hType, hHz, rowOut] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, initType, initHz, cb, fsz)
    if initHz == 0, ddVal = 1;
    else ddVal = min(initType + 2, 5); end
    ddW = cW * 0.48; edW = cW * 0.35; lblW = cW * 0.15;
    th_ = PStheme();
    hType = uicontrol(fig, 'Style', 'popupmenu', ...
        'String', {'OFF', 'PT1', 'Biquad', 'PT2', 'PT3'}, 'Value', ddVal, ...
        'Units', 'normalized', 'Position', [x0 row ddW rh], 'FontSize', fsz, 'Callback', cb);
    hHz = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(initHz)), ...
        'Units', 'normalized', 'Position', [x0+ddW+.005 row edW rh], ...
        'FontSize', fsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
        'HorizontalAlignment', 'center', 'Callback', cb);
    uicontrol(fig, 'Style', 'text', 'String', 'Hz', ...
        'Units', 'normalized', 'Position', [x0+ddW+edW+.008 row lblW rh], ...
        'FontSize', fsz-1, 'BackgroundColor', th_.panelBg, ...
        'ForegroundColor', lc, 'HorizontalAlignment', 'left');
    rowOut = row - rh - gap;
end

function [hCenter, hCutoff, rowOut] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, initCenter, initCutoff, cb, fsz)
    halfW = cW / 2; lblW = .03; edW = halfW - lblW - .01;
    uicontrol(fig, 'Style', 'text', 'String', 'Ctr:', ...
        'Units', 'normalized', 'Position', [x0 row lblW rh], ...
        'FontSize', fsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
    hCenter = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(initCenter)), ...
        'Units', 'normalized', 'Position', [x0+lblW+.005 row edW rh], ...
        'FontSize', fsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
        'HorizontalAlignment', 'center', 'Callback', cb);
    uicontrol(fig, 'Style', 'text', 'String', 'Cut:', ...
        'Units', 'normalized', 'Position', [x0+halfW row lblW rh], ...
        'FontSize', fsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
    hCutoff = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(initCutoff)), ...
        'Units', 'normalized', 'Position', [x0+halfW+lblW+.005 row edW rh], ...
        'FontSize', fsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
        'HorizontalAlignment', 'center', 'Callback', cb);
    rowOut = row - rh - gap;
end

function v = readEdit(h)
    v = round(str2double(get(h, 'String')));
    if isnan(v), v = 0; end
end

function v = readEditF(h)
    v = str2double(get(h, 'String'));
    if isnan(v), v = 0; end
end

function drawGradientBar(ax, fMax, gradCols, markerFreqs, markerCols, thm)
    cla(ax);
    Ngr = 256;
    grad = zeros(1, Ngr, 3);
    for ch = 1:3, grad(1,:,ch) = linspace(gradCols(1,ch), gradCols(2,ch), Ngr); end
    hi = imagesc(ax, [0 fMax], [0 1], grad);
    set(hi, 'HitTest', 'off');
    set(ax, 'YTick', [], 'XTick', [], 'XLim', [0 fMax], 'YLim', [0 1], 'Box', 'on');
    set(ax, 'XColor', thm.axesFg, 'YColor', thm.axesFg);
    hold(ax, 'on');
    for k = 1:numel(markerFreqs)
        f = markerFreqs{k};
        if f > 0 && f <= fMax
            line(ax, [f f], [0 1], 'Color', markerCols{k}, 'LineWidth', 2, 'HitTest', 'off');
            % slider handle: triangle top + bottom
            plot(ax, f, 0.95, 'v', 'Color', markerCols{k}, 'MarkerSize', 7, 'MarkerFaceColor', markerCols{k}, 'HitTest', 'off');
            plot(ax, f, 0.05, '^', 'Color', markerCols{k}, 'MarkerSize', 7, 'MarkerFaceColor', markerCols{k}, 'HitTest', 'off');
        end
    end
    hold(ax, 'off');
end

function y = localChirp(t, f0, dur, f1)
    % log-sweep chirp
    if f0 <= 0, f0 = 1; end
    if f1 <= f0, f1 = f0 + 1; end
    beta = (f1/f0)^(1/dur);
    phase = 2*pi * f0 * (beta.^t - 1) / log(beta);
    y = sin(phase);
end

function ok = copyToClipboard(str)
    ok = false;
    tmpf = [tempname '.txt'];
    fid = fopen(tmpf, 'w'); fprintf(fid, '%s', str); fclose(fid);
    if ismac()
        [st, ~] = system(sprintf('pbcopy < %s 2>&1', tmpf));
        ok = (st == 0);
    elseif ispc()
        [st, ~] = system(sprintf('clip < %s 2>&1', tmpf));
        ok = (st == 0);
    else
        cmds = {'xclip -selection clipboard', 'xsel --clipboard --input', 'wl-copy'};
        for k = 1:numel(cmds)
            [st, ~] = system(sprintf('%s < %s 2>&1', cmds{k}, tmpf));
            if st == 0, ok = true; break; end
        end
    end
    delete(tmpf);
end

function showCLIDialog(cliText)
    screensz = get(0, 'ScreenSize');
    dlg = figure('Name', 'BF CLI Commands', 'NumberTitle', 'off', ...
        'Color', [.15 .15 .15], ...
        'Position', round([screensz(3)*.3 screensz(4)*.25 460 380]));
    uicontrol(dlg, 'Style', 'text', 'String', 'Select All + Copy:', ...
        'Units', 'normalized', 'Position', [.05 .90 .9 .07], ...
        'FontSize', 11, 'BackgroundColor', [.15 .15 .15], 'ForegroundColor', [.9 .9 .9]);
    uicontrol(dlg, 'Style', 'edit', 'Max', 100, 'String', cliText, ...
        'Units', 'normalized', 'Position', [.05 .12 .9 .76], ...
        'HorizontalAlignment', 'left', 'FontName', 'Monospace', 'FontSize', 10, ...
        'BackgroundColor', [.1 .1 .1], 'ForegroundColor', [.9 .9 .9]);
    uicontrol(dlg, 'Style', 'pushbutton', 'String', 'Close', ...
        'Units', 'normalized', 'Position', [.35 .02 .3 .08], ...
        'FontSize', 11, 'BackgroundColor', [.3 .3 .3], 'ForegroundColor', [.9 .9 .9], ...
        'Callback', @(~,~) close(dlg));
end
