function PSTestSignalConfig(PSfig, T, Nfiles, A_lograte, SetupInfo, guiHandles, tIND)
%% PSTestSignalConfig - configure BF filter chain and apply to log data

thm = PStheme();
fontsz = thm.fontsz;
screensz = get(0, 'ScreenSize');

fig = findobj('Type', 'figure', 'Name', 'Test Signal Configuration');
if ~isempty(fig), close(fig); end
fig = figure('Name', 'Test Signal Configuration', 'NumberTitle', 'off', ...
    'Color', thm.figBg, ...
    'Position', round([0 0 screensz(3) screensz(4)]));
try set(fig, 'WindowState', 'maximized'); catch, end

fileIdx = 1;
try fileIdx = get(guiHandles.FileNum, 'Value'); fileIdx = fileIdx(1); catch, end
Fs = A_lograte(fileIdx) * 1000;

% parse filter params from log headers
fp = struct();
if iscell(SetupInfo) && numel(SetupInfo) >= fileIdx
    fp = PSparseFilterParams(SetupInfo{fileIdx});
else
    fp.gyro_lpf1_type=0; fp.gyro_lpf1_hz=0;
    fp.gyro_lpf2_type=0; fp.gyro_lpf2_hz=0;
    fp.gyro_notch1_hz=0; fp.gyro_notch1_cut=0;
    fp.gyro_notch2_hz=0; fp.gyro_notch2_cut=0;
    fp.dterm_lpf1_type=0; fp.dterm_lpf1_hz=0;
    fp.dterm_lpf2_type=0; fp.dterm_lpf2_hz=0;
    fp.dterm_notch_hz=0; fp.dterm_notch_cut=0;
end

% RPY colors: raw=solid, filtered=lighter
axCols = {thm.axisRoll, thm.axisPitch, thm.axisYaw};
axColsFilt = {thm.axisRollFilt, thm.axisPitchFilt, thm.axisYawFilt};
axNames = {'Roll','Pitch','Yaw'};

% layout: plots left 75%, controls right 25%
cpL = 0.76; cpW = 0.23;
plotL = 0.06; plotR_ = cpL - 0.02;
plotW = plotR_ - plotL;
bgc = thm.panelBg; fgc = thm.textPrimary;
ibc = thm.inputBg; ifc = thm.inputFg;
lc = thm.textSecondary;

uipanel('Parent', fig, 'Title', '', ...
    'BackgroundColor', thm.panelBg, 'ForegroundColor', thm.panelFg, ...
    'HighlightColor', thm.panelBorder, ...
    'FontSize', fontsz, 'Position', [cpL .02 cpW .96]);

% axes: top = PSD spectrum (raw vs filtered), bottom = time domain
axSpec = axes('Parent', fig, 'Units', 'normalized', 'Position', [plotL 0.54 plotW 0.42]);
axTime = axes('Parent', fig, 'Units', 'normalized', 'Position', [plotL 0.06 plotW 0.42]);
PSstyleAxes(axSpec, thm); PSstyleAxes(axTime, thm);

% control panel
x0 = cpL + 0.02;
cW = cpW - 0.04;
halfW = cW / 2;
rh = 0.026; gap = 0.004;
row = 0.94;
cb = @(~,~) updatePreview();

% source signal
uicontrol(fig, 'Style', 'text', 'String', 'Source:', ...
    'Units', 'normalized', 'Position', [x0 row .06 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
srcLabels = {'Gyro','P-term','D-term(prefilt)','D-term','Setpoint','PIDsum','PIDerror'};
h.source = uicontrol(fig, 'Style', 'popupmenu', 'String', srcLabels, 'Value', 1, ...
    'Units', 'normalized', 'Position', [x0+.065 row cW-.065 rh], ...
    'FontSize', fontsz, 'Callback', cb);
row = row - rh - gap*2;

mkSection('Gyro LPF1', thm.textAccent);
[h.glpf1_type, h.glpf1_hz, row] = mkTypeHz(fp.gyro_lpf1_type, fp.gyro_lpf1_hz);

mkSection('Gyro LPF2', thm.textAccent);
[h.glpf2_type, h.glpf2_hz, row] = mkTypeHz(fp.gyro_lpf2_type, fp.gyro_lpf2_hz);

mkSection('Gyro Notch 1', thm.secNotch);
[h.gn1_hz, h.gn1_cut, row] = mkNotchPair(fp.gyro_notch1_hz, fp.gyro_notch1_cut);

mkSection('Gyro Notch 2', thm.secNotch);
[h.gn2_hz, h.gn2_cut, row] = mkNotchPair(fp.gyro_notch2_hz, fp.gyro_notch2_cut);

mkSection('D-term LPF1', thm.secDtermLPF);
[h.dlpf1_type, h.dlpf1_hz, row] = mkTypeHz(fp.dterm_lpf1_type, fp.dterm_lpf1_hz);

mkSection('D-term LPF2', thm.secDtermLPF);
[h.dlpf2_type, h.dlpf2_hz, row] = mkTypeHz(fp.dterm_lpf2_type, fp.dterm_lpf2_hz);

mkSection('D-term Notch', thm.secDtermNotch);
[h.dn_hz, h.dn_cut, row] = mkNotchPair(fp.dterm_notch_hz, fp.dterm_notch_cut);

row = row - gap*2;

% R/P/Y checkboxes
chkW = cW / 3;
h.chkR = uicontrol(fig, 'Style', 'checkbox', 'String', 'R', 'Value', 1, ...
    'Units', 'normalized', 'Position', [x0 row chkW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', thm.axisRoll, ...
    'Callback', cb);
h.chkP = uicontrol(fig, 'Style', 'checkbox', 'String', 'P', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+chkW row chkW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', thm.axisPitch, ...
    'Callback', cb);
h.chkY = uicontrol(fig, 'Style', 'checkbox', 'String', 'Y', 'Value', 0, ...
    'Units', 'normalized', 'Position', [x0+2*chkW row chkW rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', thm.axisYaw, ...
    'Callback', cb);
row = row - rh - gap;

% preview window
uicontrol(fig, 'Style', 'text', 'String', 'Win:', ...
    'Units', 'normalized', 'Position', [x0 row .04 rh], ...
    'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
h.winLen = uicontrol(fig, 'Style', 'popupmenu', 'String', {'0.5s','1s','2s','5s','Full'}, 'Value', 2, ...
    'Units', 'normalized', 'Position', [x0+.045 row cW-.045 rh], ...
    'FontSize', fontsz, 'Callback', cb);
row = row - rh - gap*3;

% Apply button
h.applyBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Apply', ...
    'Units', 'normalized', 'Position', [x0 row cW rh*1.3], ...
    'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.btnRun, 'ForegroundColor', [1 1 1], ...
    'Callback', @(~,~) applyToLogViewer());
row = row - rh - gap;

h.status = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [x0 row cW rh], ...
    'FontSize', fontsz-1, 'BackgroundColor', bgc, 'ForegroundColor', thm.btnRun, ...
    'HorizontalAlignment', 'center');

updatePreview();

%% nested: section header
    function mkSection(txt, col)
        uicontrol(fig, 'Style', 'text', 'String', txt, ...
            'Units', 'normalized', 'Position', [cpL+.01 row cpW-.02 rh], ...
            'FontSize', fontsz-1, 'FontWeight', 'bold', ...
            'BackgroundColor', bgc, 'ForegroundColor', col);
        row = row - rh - gap;
    end

%% nested: type + hz
    function [hType, hHz, r] = mkTypeHz(defType, defHz)
        if defHz == 0, ddVal = 1;
        else ddVal = min(defType + 2, 5); end
        ddW = cW * 0.48; edW = cW * 0.35; lblW = cW * 0.15;
        hType = uicontrol(fig, 'Style', 'popupmenu', ...
            'String', {'OFF', 'PT1', 'Biquad', 'PT2', 'PT3'}, 'Value', ddVal, ...
            'Units', 'normalized', 'Position', [x0 row ddW rh], 'FontSize', fontsz, 'Callback', cb);
        hHz = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(defHz)), ...
            'Units', 'normalized', 'Position', [x0+ddW+.005 row edW rh], ...
            'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
            'HorizontalAlignment', 'center', 'Callback', cb);
        uicontrol(fig, 'Style', 'text', 'String', 'Hz', ...
            'Units', 'normalized', 'Position', [x0+ddW+edW+.008 row lblW rh], ...
            'FontSize', fontsz-1, 'BackgroundColor', bgc, ...
            'ForegroundColor', lc, 'HorizontalAlignment', 'left');
        r = row - rh - gap;
    end

%% nested: notch pair
    function [hHz, hCut, r] = mkNotchPair(defHz, defCut)
        lblW = .03; edW = halfW - lblW - .005;
        uicontrol(fig, 'Style', 'text', 'String', 'Ctr:', ...
            'Units', 'normalized', 'Position', [x0 row lblW rh], ...
            'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
        hHz = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(defHz)), ...
            'Units', 'normalized', 'Position', [x0+lblW+.005 row edW rh], ...
            'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
            'HorizontalAlignment', 'center', 'Callback', cb);
        uicontrol(fig, 'Style', 'text', 'String', 'Cut:', ...
            'Units', 'normalized', 'Position', [x0+halfW row lblW rh], ...
            'FontSize', fontsz, 'BackgroundColor', bgc, 'ForegroundColor', lc, 'HorizontalAlignment', 'right');
        hCut = uicontrol(fig, 'Style', 'edit', 'String', num2str(round(defCut)), ...
            'Units', 'normalized', 'Position', [x0+halfW+lblW+.005 row edW rh], ...
            'FontSize', fontsz, 'BackgroundColor', ibc, 'ForegroundColor', ifc, ...
            'HorizontalAlignment', 'center', 'Callback', cb);
        r = row - rh - gap;
    end

%% nested: read edit field
    function v = readEdit(hEdit)
        v = str2double(get(hEdit, 'String'));
        if isnan(v), v = 0; end
    end

%% nested: get source field name
    function srcField = getSrcField()
        srcIdx = get(h.source, 'Value');
        fields = {'gyroADC_','axisP_','axisDpf_','axisD_','setpoint_','pidsum_','piderr_'};
        srcField = fields{srcIdx};
    end

%% nested: get full source signal for one axis
    function [tFull, rawFull] = getFullData(axNum)
        srcField = getSrcField();
        fname = [srcField int2str(axNum) '_'];
        if ~isfield(T{fileIdx}, fname)
            tFull = []; rawFull = []; return;
        end
        rawFull = T{fileIdx}.(fname);
        N = numel(rawFull);
        tFull = (0:N-1)' / Fs;
    end

%% nested: get windowed data slice
    function [tSlice, rawSlice, i1, i2] = getPreviewSlice(axNum)
        [tFull, rawFull] = getFullData(axNum);
        if isempty(tFull), tSlice=[]; rawSlice=[]; i1=1; i2=1; return; end
        N = numel(rawFull);

        winIdx = get(h.winLen, 'Value');
        winSecs = [0.5 1 2 5 inf];
        wSec = winSecs(winIdx);

        idx = tIND{fileIdx};
        if isempty(idx), idx = 1:N; end
        midSample = round(mean([idx(1) idx(end)]));
        if wSec >= tFull(end)
            i1 = 1; i2 = N;
        else
            halfWin = round(wSec/2 * Fs);
            i1 = max(1, midSample - halfWin);
            i2 = min(N, midSample + halfWin);
        end
        tSlice = tFull(i1:i2);
        rawSlice = rawFull(i1:i2);
    end

%% nested: apply filter chain to a signal vector
    function out = applyChain(sig, sFs)
        out = applyLPF(sig, get(h.glpf1_type,'Value')-1, readEdit(h.glpf1_hz), sFs);
        out = applyLPF(out, get(h.glpf2_type,'Value')-1, readEdit(h.glpf2_hz), sFs);
        out = applyNotch(out, readEdit(h.gn1_hz), readEdit(h.gn1_cut), sFs);
        out = applyNotch(out, readEdit(h.gn2_hz), readEdit(h.gn2_cut), sFs);
        srcIdx = get(h.source, 'Value');
        if srcIdx == 3 || srcIdx == 4
            out = applyLPF(out, get(h.dlpf1_type,'Value')-1, readEdit(h.dlpf1_hz), sFs);
            out = applyLPF(out, get(h.dlpf2_type,'Value')-1, readEdit(h.dlpf2_hz), sFs);
            out = applyNotch(out, readEdit(h.dn_hz), readEdit(h.dn_cut), sFs);
        end
    end

%% nested: which axes are selected
    function sel = getSelectedAxes()
        sel = find([get(h.chkR,'Value') get(h.chkP,'Value') get(h.chkY,'Value')]);
    end

%% nested: update preview plots
    function updatePreview()
        if ~ishandle(fig), return; end
        sel = getSelectedAxes();
        if isempty(sel), return; end

        fMax = min(Fs/2, 1000);
        Nfft = 2^floor(log2(min(4096, numel(T{fileIdx}.loopIteration))));

        cla(axSpec); hold(axSpec, 'on');
        cla(axTime); hold(axTime, 'on');
        legTxt = {};

        for si = 1:numel(sel)
            axNum = sel(si) - 1;
            colRaw = axCols{sel(si)};
            colFilt = axColsFilt{sel(si)};

            [~, rawFull] = getFullData(axNum);
            if isempty(rawFull), continue; end
            filtFull = applyChain(rawFull, Fs);

            % PSD
            try
                [pRaw, fPsd] = pwelch(rawFull, hanning(Nfft), round(Nfft/2), Nfft, Fs);
                [pFilt, ~] = pwelch(filtFull, hanning(Nfft), round(Nfft/2), Nfft, Fs);
            catch
                win = hanning(Nfft);
                nSeg = floor(numel(rawFull) / Nfft);
                pRaw = zeros(Nfft/2+1, 1); pFilt = pRaw;
                for ssi = 1:nSeg
                    sidx = (ssi-1)*Nfft + (1:Nfft);
                    segR = rawFull(sidx) .* win;
                    segF = filtFull(sidx) .* win;
                    fR = abs(fft(segR)).^2; fF = abs(fft(segF)).^2;
                    pRaw = pRaw + fR(1:Nfft/2+1);
                    pFilt = pFilt + fF(1:Nfft/2+1);
                end
                pRaw = pRaw / max(nSeg,1);
                pFilt = pFilt / max(nSeg,1);
                fPsd = linspace(0, Fs/2, Nfft/2+1)';
            end

            fIdx_ = fPsd <= fMax & fPsd > 0;
            plot(axSpec, fPsd(fIdx_), 10*log10(pRaw(fIdx_)+1e-12), ...
                'Color', colRaw, 'LineWidth', 1.2);
            plot(axSpec, fPsd(fIdx_), 10*log10(pFilt(fIdx_)+1e-12), ...
                'Color', colFilt, 'LineWidth', 1.2);
            legTxt{end+1} = [axNames{sel(si)} ' raw'];
            legTxt{end+1} = [axNames{sel(si)} ' filt'];

            % time domain
            [tSlice, rawSlice] = getPreviewSlice(axNum);
            if isempty(tSlice), continue; end
            filtSlice = applyChain(rawSlice, Fs);
            plot(axTime, tSlice, rawSlice, 'Color', colRaw, 'LineWidth', 0.8);
            plot(axTime, tSlice, filtSlice, 'Color', colFilt, 'LineWidth', 1.2);
        end

        hold(axSpec, 'off'); hold(axTime, 'off');
        PSstyleAxes(axSpec, thm); PSstyleAxes(axTime, thm);

        ttl = strjoin(axNames(sel), '/');
        title(axSpec, [ttl ' - Spectrum'], 'Color', thm.textPrimary, 'FontSize', fontsz);
        xlabel(axSpec, 'Frequency (Hz)', 'Color', thm.textSecondary);
        ylabel(axSpec, 'PSD (dB)', 'Color', thm.textSecondary);
        set(axSpec, 'XLim', [0 fMax]);
        legend(axSpec, legTxt, 'TextColor', thm.textPrimary, ...
            'Color', thm.panelBg, 'EdgeColor', thm.legendEdge, 'Location', 'northeast');

        title(axTime, [ttl ' - Time Domain'], 'Color', thm.textPrimary, 'FontSize', fontsz);
        xlabel(axTime, 'Time (s)', 'Color', thm.textSecondary);
        ylabel(axTime, 'deg/s', 'Color', thm.textSecondary);
    end

%% nested: apply filter chain to all log data
    function applyToLogViewer()
        set(h.status, 'String', 'Applying...', 'ForegroundColor', thm.btnDash5);
        drawnow;
        srcField = getSrcField();
        for f = 1:Nfiles
            fFs = A_lograte(f) * 1000;
            for p = 0:2
                fname = [srcField int2str(p) '_'];
                if isfield(T{f}, fname)
                    T{f}.(['testSignal_' int2str(p) '_']) = applyChain(T{f}.(fname), fFs);
                else
                    T{f}.(['testSignal_' int2str(p) '_']) = zeros(size(T{f}.loopIteration));
                end
            end
        end
        assignin('base', 'T', T);
        set(h.status, 'String', 'Applied! Check Log Viewer & Spectral Analyzer.', 'ForegroundColor', thm.btnRun);
        % add Test Signal to SA SpecList if not already there
        try
            sl = evalin('base', 'guiHandlesSpec2.SpecList');
            if ishandle(sl)
                items = get(sl, 'String');
                if ~any(strcmp(items, 'Test Signal'))
                    items{end+1} = 'Test Signal';
                    set(sl, 'String', items);
                end
            end
        catch, end
        try
            if get(guiHandles.checkboxTS, 'Value')
                evalin('base', 'PSplotLogViewer');
            end
        catch, end
    end

end

%% local filter helpers
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
