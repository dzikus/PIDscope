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

fp = parseFilterParams(setupInfo);

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

% Gradient frequency bars
axBarL = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(1) barY colW barH], 'Tag', 'gradbar');
axBarN = axes('Parent', fig, 'Units', 'normalized', 'Position', [colL(2) barY colW barH], 'Tag', 'gradbar');

titleY = topY;
hTitleL = uicontrol(fig, 'Style', 'text', 'String', 'LOWPASS FILTERS', ...
    'Units', 'normalized', 'Position', [colL(1) titleY colW titleH], ...
    'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.figBg, 'ForegroundColor', [.4 .9 1]);
hTitleN = uicontrol(fig, 'Style', 'text', 'String', 'NOTCH FILTERS', ...
    'Units', 'normalized', 'Position', [colL(2) titleY colW titleH], ...
    'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.figBg, 'ForegroundColor', [1 .6 .3]);

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

mkSection(fig, 'Gyro LPF1', cpL, row, cpW, rh, bgc, [.4 .9 1], fontsz-1);
row = row - rh - gap;
[h.glpf1_type, h.glpf1_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.gyro_lpf1_type, fp.gyro_lpf1_hz, cb, fontsz);

mkSection(fig, 'Gyro LPF2', cpL, row, cpW, rh, bgc, [.4 .9 1], fontsz-1);
row = row - rh - gap;
[h.glpf2_type, h.glpf2_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.gyro_lpf2_type, fp.gyro_lpf2_hz, cb, fontsz);

mkSection(fig, 'Gyro Notch 1', cpL, row, cpW, rh, bgc, [1 .7 .3], fontsz-1);
row = row - rh - gap;
[h.gn1_hz, h.gn1_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.gyro_notch1_hz, fp.gyro_notch1_cut, cb, fontsz);

mkSection(fig, 'Gyro Notch 2', cpL, row, cpW, rh, bgc, [1 .7 .3], fontsz-1);
row = row - rh - gap;
[h.gn2_hz, h.gn2_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.gyro_notch2_hz, fp.gyro_notch2_cut, cb, fontsz);

mkSection(fig, 'D-term LPF1', cpL, row, cpW, rh, bgc, [.4 1 .4], fontsz-1);
row = row - rh - gap;
[h.dlpf1_type, h.dlpf1_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.dterm_lpf1_type, fp.dterm_lpf1_hz, cb, fontsz);

mkSection(fig, 'D-term LPF2', cpL, row, cpW, rh, bgc, [.4 1 .4], fontsz-1);
row = row - rh - gap;
[h.dlpf2_type, h.dlpf2_hz, row] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, fp.dterm_lpf2_type, fp.dterm_lpf2_hz, cb, fontsz);

mkSection(fig, 'D-term Notch', cpL, row, cpW, rh, bgc, [1 .5 .5], fontsz-1);
row = row - rh - gap;
[h.dn_hz, h.dn_cut, row] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, fp.dterm_notch_hz, fp.dterm_notch_cut, cb, fontsz);

% RPM: Hz + #Harm + Q on one line
mkSection(fig, 'RPM Filter Sim', cpL, row, cpW, rh, bgc, [1 .4 .4], fontsz-1);
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
mkSection(fig, 'Test Signal', cpL, row, cpW, rh, bgc, [.8 .6 .2], fontsz-1);
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
mkSection(fig, 'Options', cpL, row, cpW, rh, bgc, [.7 .7 .7], fontsz-1);
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
h.addnoise = uicontrol(fig, 'Style', 'checkbox', 'String', 'Add noise', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+halfW row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap;
h.showstep = uicontrol(fig, 'Style', 'checkbox', 'String', 'Step resp.', 'Value', 1, ...
    'Units', 'normalized', 'Position', [x0 row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, ...
    'Callback', @(~,~) toggleStepRow());
h.showboth = uicontrol(fig, 'Style', 'checkbox', 'String', 'Show Both', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+halfW row halfW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'Callback', cb);
row = row - rh - gap*2;
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
    'BackgroundColor', bgc, 'ForegroundColor', [.9 .2 .2], 'HorizontalAlignment', 'left');

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
        sStep = get(h.showstep, 'Value');
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
            set(axNmag,   'Position', offscr); cla(axNmag);
            set(axNdelay, 'Position', offscr); cla(axNdelay);
            set(axNphase, 'Position', offscr); cla(axNphase);
            set(axNstep,  'Position', offscr); cla(axNstep);
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
        showStep = get(h.showstep, 'Value');
        sigHzLo = readEdit(h.sig_start);
        sigHzHi = readEdit(h.sig_end);
        sigDur = max(0.1, readEditF(h.sig_dur));

        types = {'pt1', 'biquad', 'pt2', 'pt3'};
        Nfft = 2048;
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
        H_rpmAll = ones(Nfft, 1);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                H_single = notchH_Q(fc_rpm, rpmQ, Fs, Nfft);
                H_rpm{ri} = H_single .^ nMotors;
            else
                H_rpm{ri} = ones(Nfft, 1);
            end
            H_rpmAll = H_rpmAll .* H_rpm{ri};
        end
        H_gyroN = H_gn1 .* H_gn2 .* H_rpmAll;
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

        % Step responses — LPF: adaptive time, Notch: 100ms
        minCutoff = Fs/2;
        for cc = [glpf1f glpf2f dlpf1f dlpf2f]
            if cc > 0, minCutoff = min(minCutoff, cc); end
        end
        lpfStepMs = max(4, min(10, 1000 / max(minCutoff, 50)));
        stepLenL = round(Fs * lpfStepMs / 1000);
        stepInL = ones(stepLenL, 1);
        tStepL = (0:stepLenL-1)' / Fs * 1000;

        notchStepMs = 100;
        stepLenN = round(Fs * notchStepMs / 1000);
        stepInN = ones(stepLenN, 1);
        tStepN = (0:stepLenN-1)' / Fs * 1000;

        sL_g = applyLPF(applyLPF(stepInL, glpf2t, glpf2f, Fs), glpf1t, glpf1f, Fs);
        sL_d = applyLPF(applyLPF(stepInL, dlpf2t, dlpf2f, Fs), dlpf1t, dlpf1f, Fs);
        sN_g = applyNotch(applyNotch(stepInN, gn2f, gn2c, Fs), gn1f, gn1c, Fs);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                for mi = 1:nMotors
                    sN_g = applyNotch_Q(sN_g, fc_rpm, rpmQ, Fs);
                end
            end
        end
        sN_d = applyNotch(stepInN, dnf, dnc, Fs);
        % Per-RPM-harmonic steps (cascaded nMotors)
        sN_rpm = cell(rpmNharm, 1);
        for ri = 1:rpmNharm
            fc_rpm = rpmBase * ri;
            if fc_rpm > 0 && fc_rpm < Fs/2
                tmp = stepInN;
                for mi = 1:nMotors, tmp = applyNotch_Q(tmp, fc_rpm, rpmQ, Fs); end
                sN_rpm{ri} = tmp;
            else
                sN_rpm{ri} = stepInN;
            end
        end
        sN_gn1 = applyNotch(stepInN, gn1f, gn1c, Fs);
        sN_gn2 = applyNotch(stepInN, gn2f, gn2c, Fs);

        % Noisy step responses (for "Add noise" option)
        if addNoise
            noiseAmp = 0.03;
            noisyL = stepInL + randn(stepLenL, 1) * noiseAmp;
            nsL_g = applyLPF(applyLPF(noisyL, glpf2t, glpf2f, Fs), glpf1t, glpf1f, Fs);
            nsL_d = applyLPF(applyLPF(noisyL, dlpf2t, dlpf2f, Fs), dlpf1t, dlpf1f, Fs);
            noisyN = stepInN + randn(stepLenN, 1) * noiseAmp;
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
        sL_g1 = applyLPF(stepInL, glpf1t, glpf1f, Fs);
        sL_g2 = applyLPF(stepInL, glpf2t, glpf2f, Fs);
        sL_d1 = applyLPF(stepInL, dlpf1t, dlpf1f, Fs);
        sL_d2 = applyLPF(stepInL, dlpf2t, dlpf2f, Fs);

        g1on = glpf1t > 0 && glpf1f > 0;
        g2on = glpf2t > 0 && glpf2f > 0;
        d1on = dlpf1t > 0 && dlpf1f > 0;
        d2on = dlpf2t > 0 && dlpf2f > 0;
        colNoise = [.9 .25 .25];

        applyLayout();

        %% LOWPASS COLUMN (+ notch overlay when showBoth)

        cla(axLmag); hold(axLmag, 'on');
        if combineLPF
            plotFn(axLmag, fVec(fIdx), magY(H_gyroLPF(fIdx), usedB), 'Color', colG, 'LineWidth', 1.5);
            plotFn(axLmag, fVec(fIdx), magY(H_dtermLPF(fIdx), usedB), 'Color', colD, 'LineWidth', 1.2);
        else
            if g1on, plotFn(axLmag, fVec(fIdx), magY(H_lpf1(fIdx), usedB), 'Color', colG, 'LineWidth', 1.2); end
            if g2on, plotFn(axLmag, fVec(fIdx), magY(H_lpf2(fIdx), usedB), 'Color', colG, 'LineWidth', 1.2, 'LineStyle', '--'); end
            if d1on, plotFn(axLmag, fVec(fIdx), magY(H_dlpf1(fIdx), usedB), 'Color', colD, 'LineWidth', 1.0); end
            if d2on, plotFn(axLmag, fVec(fIdx), magY(H_dlpf2(fIdx), usedB), 'Color', colD, 'LineWidth', 1.0, 'LineStyle', '--'); end
        end
        if showBoth
            plotFn(axLmag, fVec(fIdx), magY(H_gyroN(fIdx), usedB), 'Color', colCombN, 'LineWidth', 1.2);
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                plotFn(axLmag, fVec(fIdx), magY(H_rpm{ri}(fIdx), usedB), 'Color', rpmCols{ci}, 'LineWidth', 0.7);
            end
        end
        fLo = xlimF(useLog, fMax);
        if usedB
            line(axLmag, [fLo(1) fMax], [-3 -3], 'Color', [.6 .6 .2], 'LineStyle', ':', 'LineWidth', 0.5);
        else
            line(axLmag, [fLo(1) fMax], [0.707 0.707], 'Color', [.6 .6 .2], 'LineStyle', ':', 'LineWidth', 0.5);
        end
        hold(axLmag, 'off');
        PSstyleAxes(axLmag, thm);
        if usedB
            set(axLmag, 'XLim', xlimF(useLog, fMax), 'YLim', [-60 3], 'XTickLabel', {});
            set(get(axLmag, 'YLabel'), 'String', 'Magnitude (dB)');
        else
            set(axLmag, 'XLim', xlimF(useLog, fMax), 'YLim', [0 1.1], 'XTickLabel', {});
            set(get(axLmag, 'YLabel'), 'String', 'Magnitude (abs)');
        end
        annotateLPF(axLmag, glpf1t, glpf1f, glpf2t, glpf2f, types, colG, fontsz, usedB);

        cla(axLdelay); hold(axLdelay, 'on');
        if combineLPF
            plotFn(axLdelay, fVec(fIdx), gd_gL(fIdx), 'Color', colG, 'LineWidth', 1.5);
            plotFn(axLdelay, fVec(fIdx), gd_dL(fIdx), 'Color', colD, 'LineWidth', 1.2);
        else
            if g1on, plotFn(axLdelay, fVec(fIdx), gd_g1(fIdx), 'Color', colG, 'LineWidth', 1.2); end
            if g2on, plotFn(axLdelay, fVec(fIdx), gd_g2(fIdx), 'Color', colG, 'LineWidth', 1.2, 'LineStyle', '--'); end
            if d1on, plotFn(axLdelay, fVec(fIdx), gd_d1(fIdx), 'Color', colD, 'LineWidth', 1.0); end
            if d2on, plotFn(axLdelay, fVec(fIdx), gd_d2(fIdx), 'Color', colD, 'LineWidth', 1.0, 'LineStyle', '--'); end
        end
        if showBoth
            plotFn(axLdelay, fVec(fIdx), gd_gN(fIdx), 'Color', colCombN, 'LineWidth', 1.2);
        end
        hold(axLdelay, 'off');
        PSstyleAxes(axLdelay, thm); set(axLdelay, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
        if combineLPF
            gdMax = max([max(gd_gL(fIdx)) max(gd_dL(fIdx)) 0.3]) * 1.3;
        else
            allGdL = [0.3];
            if g1on, allGdL(end+1) = max(gd_g1(fIdx)); end
            if g2on, allGdL(end+1) = max(gd_g2(fIdx)); end
            if d1on, allGdL(end+1) = max(gd_d1(fIdx)); end
            if d2on, allGdL(end+1) = max(gd_d2(fIdx)); end
            gdMax = max(allGdL) * 1.3;
        end
        if isfinite(gdMax) && gdMax > 0, set(axLdelay, 'YLim', [0 gdMax]); end
        set(get(axLdelay, 'YLabel'), 'String', 'Filter Delay (ms)');
        yTxtL = gdMax * 0.92;
        yTxtStp = gdMax * 0.17;
        if combineLPF
            text(fMax*0.02, yTxtL, sprintf('gyro lpf: %.3fms', gd_gL(2)), 'Parent', axLdelay, ...
                'Color', colG, 'FontSize', fontsz-1);
            text(fMax*0.02, yTxtL - yTxtStp, sprintf('dterm lpf: %.3fms', gd_dL(2)), 'Parent', axLdelay, ...
                'Color', colD, 'FontSize', fontsz-1);
        else
            if g1on, text(fMax*0.02, yTxtL, sprintf('gyro lpf1: %.3fms', gd_g1(2)), 'Parent', axLdelay, 'Color', colG*0.7, 'FontSize', fontsz-1); yTxtL = yTxtL - yTxtStp; end
            if g2on, text(fMax*0.02, yTxtL, sprintf('gyro lpf2: %.3fms', gd_g2(2)), 'Parent', axLdelay, 'Color', colG, 'FontSize', fontsz-1); yTxtL = yTxtL - yTxtStp; end
            if d1on, text(fMax*0.02, yTxtL, sprintf('dterm lpf1: %.3fms', gd_d1(2)), 'Parent', axLdelay, 'Color', colD*0.7, 'FontSize', fontsz-1); yTxtL = yTxtL - yTxtStp; end
            if d2on, text(fMax*0.02, yTxtL, sprintf('dterm lpf2: %.3fms', gd_d2(2)), 'Parent', axLdelay, 'Color', colD, 'FontSize', fontsz-1); end
        end

        cla(axLphase); hold(axLphase, 'on');
        if combineLPF
            ph_gL = unwrap(angle(H_gyroLPF)) * 180/pi;
            ph_dL = unwrap(angle(H_dtermLPF)) * 180/pi;
            plotFn(axLphase, fVec(fIdx), ph_gL(fIdx), 'Color', colG, 'LineWidth', 1.5);
            plotFn(axLphase, fVec(fIdx), ph_dL(fIdx), 'Color', colD, 'LineWidth', 1.2);
        else
            if g1on, plotFn(axLphase, fVec(fIdx), ph_g1(fIdx), 'Color', colG, 'LineWidth', 1.2); end
            if g2on, plotFn(axLphase, fVec(fIdx), ph_g2(fIdx), 'Color', colG, 'LineWidth', 1.2, 'LineStyle', '--'); end
            if d1on, plotFn(axLphase, fVec(fIdx), ph_d1(fIdx), 'Color', colD, 'LineWidth', 1.0); end
            if d2on, plotFn(axLphase, fVec(fIdx), ph_d2(fIdx), 'Color', colD, 'LineWidth', 1.0, 'LineStyle', '--'); end
        end
        if showBoth
            ph_gN = smooth(angle(H_gyroN) * 180/pi, 9, 'moving');
            plotFn(axLphase, fVec(fIdx), ph_gN(fIdx), 'Color', colCombN, 'LineWidth', 1.2);
        end
        hold(axLphase, 'off');
        PSstyleAxes(axLphase, thm); set(axLphase, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
        set(get(axLphase, 'YLabel'), 'String', 'Phase Delay (deg)');

        if showStep
            cla(axLstep);
            line(axLstep, [tStepL(1) tStepL(end)], [1 1], 'Color', colRef, 'LineWidth', 0.5, 'LineStyle', '--'); hold(axLstep, 'on');
            if combineLPF
                plot(axLstep, tStepL, sL_g, 'Color', colG, 'LineWidth', 1.5);
                plot(axLstep, tStepL, sL_d, 'Color', colD, 'LineWidth', 1.2);
                if addNoise
                    plot(axLstep, tStepL, nsL_g, 'Color', colNoise, 'LineWidth', 0.8);
                    plot(axLstep, tStepL, nsL_d, 'Color', colNoise*0.7, 'LineWidth', 0.7);
                end
            else
                if g1on, plot(axLstep, tStepL, sL_g1, 'Color', colG, 'LineWidth', 1.2); end
                if g2on, plot(axLstep, tStepL, sL_g2, 'Color', colG, 'LineWidth', 1.2, 'LineStyle', '--'); end
                if d1on, plot(axLstep, tStepL, sL_d1, 'Color', colD, 'LineWidth', 1.0); end
                if d2on, plot(axLstep, tStepL, sL_d2, 'Color', colD, 'LineWidth', 1.0, 'LineStyle', '--'); end
                if addNoise
                    plot(axLstep, tStepL, nsL_g, 'Color', colNoise, 'LineWidth', 0.8);
                    plot(axLstep, tStepL, nsL_d, 'Color', colNoise*0.7, 'LineWidth', 0.7);
                end
            end
            hold(axLstep, 'off');
            PSstyleAxes(axLstep, thm); set(axLstep, 'XLim', [tStepL(1) tStepL(end)], 'YLim', [-0.05 1.15]);
            xlabel(axLstep, 'Time (ms)', 'Color', thm.textPrimary);
            set(get(axLstep, 'YLabel'), 'String', 'Step Resp.');
        end

        %% NOTCH COLUMN (skip when showBoth)

        if ~showBoth
            cla(axNmag); hold(axNmag, 'on');
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                plotFn(axNmag, fVec(fIdx), magY(H_rpm{ri}(fIdx), usedB), 'Color', rpmCols{ci}, 'LineWidth', 0.9);
            end
            if gn1f > 0
                plotFn(axNmag, fVec(fIdx), magY(H_gn1(fIdx), usedB), 'Color', colStaticN, 'LineWidth', 0.8);
            end
            if gn2f > 0
                plotFn(axNmag, fVec(fIdx), magY(H_gn2(fIdx), usedB), 'Color', colStaticN*0.85, 'LineWidth', 0.8, 'LineStyle', '--');
            end
            plotFn(axNmag, fVec(fIdx), magY(H_gyroN(fIdx), usedB), 'Color', colCombN, 'LineWidth', 1.5);
            if dnf > 0
                plotFn(axNmag, fVec(fIdx), magY(H_dtermN(fIdx), usedB), 'Color', colD, 'LineWidth', 1.2);
            end
            hold(axNmag, 'off');
            PSstyleAxes(axNmag, thm);
            if usedB
                set(axNmag, 'XLim', xlimF(useLog, fMax), 'YLim', [-40 3], 'XTickLabel', {});
                set(get(axNmag, 'YLabel'), 'String', 'Magnitude (dB)');
            else
                set(axNmag, 'XLim', xlimF(useLog, fMax), 'YLim', [0 1.1], 'XTickLabel', {});
                set(get(axNmag, 'YLabel'), 'String', 'Magnitude (abs)');
            end
            annotateNotch(axNmag, gn1f, gn2f, dnf, rpmBase, rpmNharm, rpmCols, colStaticN, colCombN, colD, fontsz, usedB);

            cla(axNdelay); hold(axNdelay, 'on');
            rpmGd = cell(rpmNharm, 1);
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                rpmGd{ri} = smooth(-gradient(unwrap(angle(H_rpm{ri}))) ./ dw * 1000, 51, 'moving');
                plotFn(axNdelay, fVec(fIdx), rpmGd{ri}(fIdx), 'Color', rpmCols{ci}, 'LineWidth', 0.9);
            end
            plotFn(axNdelay, fVec(fIdx), gd_gN(fIdx), 'Color', colCombN, 'LineWidth', 1.5);
            if dnf > 0
                plotFn(axNdelay, fVec(fIdx), gd_dN(fIdx), 'Color', colD, 'LineWidth', 1.2);
            end
            hold(axNdelay, 'off');
            PSstyleAxes(axNdelay, thm); set(axNdelay, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
            gdMaxN = max(abs(gd_gN(2)) * 3, 0.5);
            if isfinite(gdMaxN), set(axNdelay, 'YLim', [-gdMaxN gdMaxN]); end
            set(get(axNdelay, 'YLabel'), 'String', 'Filter Delay (ms)');
            nAnnot = rpmNharm;
            if gn1f > 0, nAnnot = nAnnot + 1; end
            if gn2f > 0, nAnnot = nAnnot + 1; end
            if dnf > 0, nAnnot = nAnnot + 1; end
            nAnnot = max(nAnnot + 1, 2);
            yTxt = gdMaxN * 0.9;
            yStN = 2 * gdMaxN * 0.9 / nAnnot;
            text(fMax*0.3, yTxt, sprintf('combined: %.4fms', gd_gN(2)), ...
                'Parent', axNdelay, 'Color', colCombN, 'FontSize', fontsz-1);
            yTxt = yTxt - yStN;
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                fc_rpm = rpmBase * ri;
                text(fMax*0.3, yTxt, sprintf('RPM %dHz: %.4fms', fc_rpm, rpmGd{ri}(2)), ...
                    'Parent', axNdelay, 'Color', rpmCols{ci}, 'FontSize', fontsz-1);
                yTxt = yTxt - yStN;
            end
            if gn1f > 0
                gd_gn1_v = smooth(-gradient(unwrap(angle(H_gn1))) ./ dw * 1000, 51, 'moving');
                text(fMax*0.3, yTxt, sprintf('N1 %dHz: %.4fms', gn1f, gd_gn1_v(2)), ...
                    'Parent', axNdelay, 'Color', colStaticN, 'FontSize', fontsz-1);
                yTxt = yTxt - yStN;
            end
            if gn2f > 0
                gd_gn2_v = smooth(-gradient(unwrap(angle(H_gn2))) ./ dw * 1000, 51, 'moving');
                text(fMax*0.3, yTxt, sprintf('N2 %dHz: %.4fms', gn2f, gd_gn2_v(2)), ...
                    'Parent', axNdelay, 'Color', colStaticN*0.85, 'FontSize', fontsz-1);
                yTxt = yTxt - yStN;
            end
            if dnf > 0
                text(fMax*0.3, yTxt, sprintf('D %dHz: %.4fms', dnf, gd_dN(2)), ...
                    'Parent', axNdelay, 'Color', colD, 'FontSize', fontsz-1);
            end

            cla(axNphase); hold(axNphase, 'on');
            for ri = 1:rpmNharm
                ci = min(ri, numel(rpmCols));
                ph_ri = smooth(angle(H_rpm{ri}) * 180/pi, 9, 'moving');
                plotFn(axNphase, fVec(fIdx), ph_ri(fIdx), 'Color', rpmCols{ci}, 'LineWidth', 0.9);
            end
            ph_gN = smooth(angle(H_gyroN) * 180/pi, 9, 'moving');
            ph_dN = smooth(angle(H_dtermN) * 180/pi, 9, 'moving');
            plotFn(axNphase, fVec(fIdx), ph_gN(fIdx), 'Color', colCombN, 'LineWidth', 1.5);
            if dnf > 0
                plotFn(axNphase, fVec(fIdx), ph_dN(fIdx), 'Color', colD, 'LineWidth', 1.2);
            end
            hold(axNphase, 'off');
            PSstyleAxes(axNphase, thm); set(axNphase, 'XLim', xlimF(useLog, fMax), 'XTickLabel', {});
            set(get(axNphase, 'YLabel'), 'String', 'Phase Delay (deg)');

            if showStep
                cla(axNstep);
                line(axNstep, [tStepN(1) tStepN(end)], [1 1], 'Color', colRef, 'LineWidth', 0.5, 'LineStyle', '--'); hold(axNstep, 'on');
                for ri = 1:rpmNharm
                    ci = min(ri, numel(rpmCols));
                    plot(axNstep, tStepN, sN_rpm{ri}, 'Color', rpmCols{ci}, 'LineWidth', 0.8);
                end
                if gn1f > 0, plot(axNstep, tStepN, sN_gn1, 'Color', colStaticN, 'LineWidth', 0.8); end
                if gn2f > 0, plot(axNstep, tStepN, sN_gn2, 'Color', colStaticN*0.85, 'LineWidth', 0.8, 'LineStyle', '--'); end
                plot(axNstep, tStepN, sN_g, 'Color', colCombN, 'LineWidth', 1.5);
                if dnf > 0, plot(axNstep, tStepN, sN_d, 'Color', colD, 'LineWidth', 1.2); end
                if addNoise
                    plot(axNstep, tStepN, nsN_g, 'Color', colNoise, 'LineWidth', 0.8);
                    if dnf > 0, plot(axNstep, tStepN, nsN_d, 'Color', colNoise*0.7, 'LineWidth', 0.7); end
                end
                hold(axNstep, 'off');
                PSstyleAxes(axNstep, thm); set(axNstep, 'XLim', [tStepN(1) tStepN(end)], 'YLim', [0.8 1.2]);
                xlabel(axNstep, 'Time (ms)', 'Color', thm.textPrimary);
                set(get(axNstep, 'YLabel'), 'String', 'Step Resp.');
            end
        end

        % Set XScale after all plotting to avoid log-axis warnings
        if useLog
            xsc = 'log';
        else
            xsc = 'linear';
        end
        for axi = 1:numel(allFreqAx)
            if ishandle(allFreqAx(axi)), set(allFreqAx(axi), 'XScale', xsc); end
        end
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

function fp = parseFilterParams(si)
    % BF enum is same across all versions: 0=PT1, 1=BIQUAD, 2=PT2, 3=PT3
    % Filter disabled when hz == 0, NOT by type value
    % Header key names differ: BF 4.3+ uses gyro_lpf1_*, BF 4.2 uses gyro_lowpass_*
    fp.gyro_lpf1_type = hval(si, 'gyro_lpf1_type', hval(si, 'gyro_lowpass_type', 0));
    fp.gyro_lpf1_hz = hval(si, 'gyro_lpf1_static_hz', hval(si, 'gyro_lowpass_hz', 0));
    fp.gyro_lpf2_type = hval(si, 'gyro_lpf2_type', hval(si, 'gyro_lowpass2_type', 0));
    fp.gyro_lpf2_hz = hval(si, 'gyro_lpf2_static_hz', hval(si, 'gyro_lowpass2_hz', 0));
    fp.dterm_lpf1_type = hval(si, 'dterm_lpf1_type', hval(si, 'dterm_lowpass_type', 0));
    fp.dterm_lpf1_hz = hval(si, 'dterm_lpf1_static_hz', hval(si, 'dterm_lowpass_hz', 0));
    fp.dterm_lpf2_type = hval(si, 'dterm_lpf2_type', hval(si, 'dterm_lowpass2_type', 0));
    fp.dterm_lpf2_hz = hval(si, 'dterm_lpf2_static_hz', hval(si, 'dterm_lowpass2_hz', 0));
    fp.dterm_notch_hz = hval(si, 'dterm_notch_hz', 0);
    fp.dterm_notch_cut = hval(si, 'dterm_notch_cutoff', 0);
    tmp = hstr(si, 'gyro_notch_hz', '0,0'); v = str2double(strsplit(tmp, ','));
    if any(isnan(v)), v = [0 0]; end
    fp.gyro_notch1_hz = v(1);
    fp.gyro_notch2_hz = 0; if numel(v) > 1, fp.gyro_notch2_hz = v(2); end
    tmp = hstr(si, 'gyro_notch_cutoff', '0,0'); v = str2double(strsplit(tmp, ','));
    if any(isnan(v)), v = [0 0]; end
    fp.gyro_notch1_cut = v(1);
    fp.gyro_notch2_cut = 0; if numel(v) > 1, fp.gyro_notch2_cut = v(2); end
end

function v = hval(si, key, default)
    v = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            tmp = str2double(strtrim(si{k,2}));
            if ~isnan(tmp), v = tmp; end
            return;
        end
    end
end

function s = hstr(si, key, default)
    s = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            s = strtrim(si{k,2});
            return;
        end
    end
end

function mkSection(fig, txt, cpL, row, cpW, rh, bgc, col, fsz)
    uicontrol(fig, 'Style', 'text', 'String', txt, ...
        'Units', 'normalized', 'Position', [cpL+.01 row cpW-.02 rh], ...
        'FontSize', fsz, 'FontWeight', 'bold', 'BackgroundColor', bgc, 'ForegroundColor', col);
end

function [hType, hHz, rowOut] = mkTypeHz(fig, x0, row, rh, gap, cW, ibc, ifc, lc, initType, initHz, cb, fsz)
    if initHz == 0, ddVal = 1;
    else ddVal = min(initType + 2, 5); end
    ddW = cW * 0.48; edW = cW * 0.35; lblW = cW * 0.15;
    hType = uicontrol(fig, 'Style', 'popupmenu', ...
        'String', {'OFF', 'PT1', 'Biquad', 'PT2', 'PT3'}, 'Value', ddVal, ...
        'Units', 'normalized', 'Position', [x0 row ddW rh], 'FontSize', fsz, 'Callback', cb);
    hHz = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(initHz)), ...
        'Units', 'normalized', 'Position', [x0+ddW+.005 row edW rh], ...
        'FontSize', fsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
        'HorizontalAlignment', 'center', 'Callback', cb);
    uicontrol(fig, 'Style', 'text', 'String', 'Hz', ...
        'Units', 'normalized', 'Position', [x0+ddW+edW+.008 row lblW rh], ...
        'FontSize', fsz-1, 'BackgroundColor', [.22 .22 .24], ...
        'ForegroundColor', lc, 'HorizontalAlignment', 'left');
    rowOut = row - rh - gap;
end

function [hCenter, hCutoff, rowOut] = mkNotchPair(fig, x0, row, rh, gap, cW, bgc, ibc, ifc, lc, initCenter, initCutoff, cb, fsz)
    halfW = cW / 2; lblW = .03; edW = halfW - lblW - .005;
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
    imagesc(ax, [0 fMax], [0 1], grad);
    set(ax, 'YTick', [], 'XTick', [], 'XLim', [0 fMax], 'YLim', [0 1], 'Box', 'on');
    set(ax, 'XColor', thm.axesFg, 'YColor', thm.axesFg);
    hold(ax, 'on');
    for k = 1:numel(markerFreqs)
        f = markerFreqs{k};
        if f > 0 && f <= fMax
            line(ax, [f f], [0 1], 'Color', markerCols{k}, 'LineWidth', 2);
            plot(ax, f, 0.5, 'v', 'Color', markerCols{k}, 'MarkerSize', 5, 'MarkerFaceColor', markerCols{k});
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
