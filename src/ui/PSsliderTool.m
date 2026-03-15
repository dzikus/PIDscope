function PSsliderTool(rollPID_str, pitchPID_str, yawPID_str)
%% PSsliderTool - interactive PID ratio calculator
%  Popup window with firmware presets and ratio-based sliders.
%  Two math modes: PTB (P-anchor, ratio-based) and BF (simplified_tuning.c style).

thm = PStheme();
fontsz = thm.fontsz;

fig = findobj('Type', 'figure', 'Name', 'PID Slider Tool');
if ~isempty(fig), close(fig); end

screensz = get(0, 'ScreenSize');
figW = round(min(720, screensz(3) * 0.55));
figH = round(min(520, screensz(4) * 0.55));
figX = round((screensz(3) - figW) / 2);
figY = round((screensz(4) - figH) / 2);
fig = figure('Name', 'PID Slider Tool', 'NumberTitle', 'off', ...
    'Color', thm.figBg, ...
    'Position', [figX figY figW figH], ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');

% Firmware presets: {name, P, I, D, yawDfactor}
presets = { ...
    'Betaflight',  NaN,  NaN,  NaN,  1.0;
    'INAV',        40,   75,   20,   0.0;
    'FETTEC',      1.00, 0.01, 2.50, 0.08;
    'KISS_ULTRA',  1.5,  0.05, 5.0,  0.04;
    'QuickSilver', 42,   85,   30,   1.0;
    'ArduPilot',   0.135,0.090,0.0036,5.0;
};

hasLogPID = nargin >= 3 && ~isempty(rollPID_str);
if hasLogPID
    rp = sscanf(strrep(rollPID_str, ' ', ''), '%f,%f,%f');
    yp = sscanf(strrep(yawPID_str, ' ', ''), '%f,%f,%f');
    if numel(rp) >= 3 && numel(yp) >= 3
        ydf = 1.0;
        if rp(3) > 0, ydf = yp(3) / rp(3); end
        presets(end+1,:) = {'From Log', rp(1), rp(2), rp(3), ydf};
    end
end

fwNames = presets(:,1);
setappdata(fig, 'presets', presets);

% Slider names per math mode
slNamesPTB = {'PD Ratio', 'PI Ratio', 'Roll-Pitch Ratio', 'Yaw Ratio', 'Master Multiplier'};
slNamesBF  = {'D Gain', 'PI Gain', 'Roll-Pitch Ratio', 'Yaw Ratio', 'Master Multiplier'};
setappdata(fig, 'slNamesPTB', slNamesPTB);
setappdata(fig, 'slNamesBF', slNamesBF);

% --- Controls ---
h = struct();

% Row 0: Reset + firmware + math mode
h.resetBtn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Reset', ...
    'Position', [20 figH-50 70 30], ...
    'FontSize', fontsz, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.btnReset, 'ForegroundColor', [0 0 0], ...
    'Callback', @cb_reset);

h.fwDd = uicontrol(fig, 'Style', 'popupmenu', 'String', fwNames, ...
    'Position', [100 figH-50 130 28], ...
    'FontSize', fontsz, ...
    'Callback', @cb_fwChanged);

uicontrol(fig, 'Style', 'text', 'String', 'Math:', ...
    'Position', [240 figH-50 40 22], 'FontSize', fontsz, ...
    'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg, ...
    'HorizontalAlignment', 'right');

h.mathDd = uicontrol(fig, 'Style', 'popupmenu', ...
    'String', {'PTB (ratio)', 'Betaflight'}, ...
    'Position', [285 figH-50 120 28], ...
    'FontSize', fontsz, ...
    'Callback', @cb_mathChanged);

% Row 1: headers
hdrY = figH - 90;
uicontrol(fig, 'Style', 'text', 'String', 'PID start values', ...
    'Position', [140 hdrY 170 22], 'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg, ...
    'HorizontalAlignment', 'center');
uicontrol(fig, 'Style', 'text', 'String', 'PID test values', ...
    'Position', [390 hdrY 300 22], 'FontSize', fontsz+1, 'FontWeight', 'bold', ...
    'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg, ...
    'HorizontalAlignment', 'center');

% Row 2-4: P/I/D edit boxes + test value labels
labels = {'P', 'I', 'D'};
axNames = {'Roll', 'Pitch', 'Yaw'};
for k = 1:3
    yy = hdrY - 28*k;
    uicontrol(fig, 'Style', 'text', 'String', labels{k}, ...
        'Position', [170 yy 20 22], ...
        'FontSize', fontsz, 'FontWeight', 'bold', ...
        'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg);
    h.startEdit(k) = uicontrol(fig, 'Style', 'edit', 'String', '', ...
        'Position', [195 yy 90 24], 'FontSize', fontsz, ...
        'Callback', @cb_recalc);
end
for k = 1:3
    yy = hdrY - 28*k;
    h.testLbl(k) = uicontrol(fig, 'Style', 'text', ...
        'String', [axNames{k} ' PID:'], ...
        'Position', [390 yy 300 22], 'FontSize', fontsz, ...
        'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg, ...
        'HorizontalAlignment', 'left');
end

% Math mode description label
h.mathDesc = uicontrol(fig, 'Style', 'text', 'String', '', ...
    'Position', [420 figH-50 290 22], 'FontSize', fontsz-1, ...
    'ForegroundColor', thm.textSecondary, 'BackgroundColor', thm.figBg, ...
    'HorizontalAlignment', 'left');

% Sliders
slY0 = hdrY - 28*3 - 45;
slGap = 55;
slLblW = 200;
slX = 210;
slW = figW - slX - 30;

for k = 1:5
    yy = slY0 - (k-1)*slGap;
    h.slLbl(k) = uicontrol(fig, 'Style', 'text', ...
        'String', sprintf('%s: 1.00', slNamesPTB{k}), ...
        'Position', [5 yy slLblW 22], 'FontSize', fontsz, ...
        'ForegroundColor', thm.textPrimary, 'BackgroundColor', thm.figBg, ...
        'HorizontalAlignment', 'right');
    h.sl(k) = uicontrol(fig, 'Style', 'slider', ...
        'Position', [slX yy slW 20], ...
        'Min', 0.25, 'Max', 2.00, 'Value', 1.00, ...
        'SliderStep', [0.01/1.75, 0.05/1.75], ...
        'Callback', @cb_sliderMoved);
end

setappdata(fig, 'h', h);

% Init
if hasLogPID, set(h.fwDd, 'Value', numel(fwNames)); end
cb_mathChanged(h.mathDd, []);
cb_fwChanged(h.fwDd, []);

% ---- Nested callbacks ----
    function cb_fwChanged(src, ~)
        idx = get(src, 'Value');
        pr = getappdata(fig, 'presets');
        for e = 1:3
            v = pr{idx, e+1};
            if isnan(v), set(h.startEdit(e), 'String', '');
            else set(h.startEdit(e), 'String', num2str(v)); end
        end
        cb_reset([], []);
    end

    function cb_mathChanged(~, ~)
        mode = get(h.mathDd, 'Value');
        if mode == 1
            sn = getappdata(fig, 'slNamesPTB');
            set(h.mathDesc, 'String', 'P=anchor, ratios adjust I/D');
        else
            sn = getappdata(fig, 'slNamesBF');
            set(h.mathDesc, 'String', 'PI Gain scales P+I together');
        end
        setappdata(fig, 'slNames', sn);
        for s = 1:5
            v = get(h.sl(s), 'Value');
            set(h.slLbl(s), 'String', sprintf('%s: %.2f', sn{s}, v));
        end
        recalc();
    end

    function cb_reset(~, ~)
        sn = getappdata(fig, 'slNames');
        for s = 1:5
            set(h.sl(s), 'Value', 1.00);
            set(h.slLbl(s), 'String', sprintf('%s: 1.00', sn{s}));
        end
        recalc();
    end

    function cb_sliderMoved(~, ~)
        sn = getappdata(fig, 'slNames');
        for s = 1:5
            v = get(h.sl(s), 'Value');
            set(h.slLbl(s), 'String', sprintf('%s: %.2f', sn{s}, v));
        end
        recalc();
    end

    function cb_recalc(~, ~), recalc(); end

    function recalc()
        P0 = str2double(get(h.startEdit(1), 'String'));
        I0 = str2double(get(h.startEdit(2), 'String'));
        D0 = str2double(get(h.startEdit(3), 'String'));
        if isnan(P0) || isnan(I0) || isnan(D0), return; end

        idx = get(h.fwDd, 'Value');
        pr = getappdata(fig, 'presets');
        ydf = pr{idx, 5};
        yawD0 = D0 * ydf;

        sl1 = get(h.sl(1), 'Value');  % PD Ratio / D Gain
        sl2 = get(h.sl(2), 'Value');  % PI Ratio / PI Gain
        rpr = get(h.sl(3), 'Value');  % Roll-Pitch Ratio
        ywr = get(h.sl(4), 'Value');  % Yaw Ratio
        mst = get(h.sl(5), 'Value');  % Master Multiplier

        mode = get(h.mathDd, 'Value');

        if mode == 1
            % PTB math: P is anchor, PI ratio affects I only, Yaw I excludes PI
            rP = P0 * mst;
            rI = I0 * sl2 * mst;
            rD = D0 * sl1 * mst;

            pP = rP * rpr;
            pI = rI * rpr;
            pD = rD * rpr;

            yP = rP * ywr;
            yI = I0 * ywr * mst;
            yD = yawD0 * sl1 * ywr * mst;
        else
            % BF math: PI Gain scales P AND I together, Yaw I follows PI Gain
            rP = P0 * sl2 * mst;
            rI = I0 * sl2 * mst;
            rD = D0 * sl1 * mst;

            pP = rP * rpr;
            pI = rI * rpr;
            pD = rD * rpr;

            yP = rP * ywr;
            yI = rI * ywr;
            yD = yawD0 * sl1 * ywr * mst;
        end

        set(h.testLbl(1), 'String', sprintf('Roll PID:  %s  %s  %s', fp(rP), fp(rI), fp(rD)));
        set(h.testLbl(2), 'String', sprintf('Pitch PID:  %s  %s  %s', fp(pP), fp(pI), fp(pD)));
        set(h.testLbl(3), 'String', sprintf('Yaw PID:  %s  %s  %s', fp(yP), fp(yI), fp(yD)));
    end

    function s = fp(v)
        if abs(v) < 0.001
            s = sprintf('%.4f', v);
        elseif abs(v) < 1
            s = sprintf('%.3f', v);
        elseif abs(v - round(v)) < 0.005
            s = sprintf('%.0f', v);
        else
            s = sprintf('%.2f', v);
        end
    end
end
