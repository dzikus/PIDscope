function PSfilterSim(gyroRaw, Fs, setupInfo)
%% PSfilterSim - simulate BF gyro filter chain on raw gyro data
%  gyroRaw   - struct with fields r/p/y (column vectors, deg/s)
%  Fs        - sample rate (Hz)
%  setupInfo - cell array {param, value} from header

fig = figure('Name', 'Filter Simulation', 'NumberTitle', 'off', ...
    'Color', [.15 .15 .15], 'Position', [80 60 1100 700]);

fp = parseFilterParams(setupInfo);

axData = {gyroRaw.r, gyroRaw.p, gyroRaw.y};
axNames = {'Roll', 'Pitch', 'Yaw'};

axSpec = axes('Parent', fig, 'Units', 'normalized', 'Position', [.06 .54 .62 .40]);
axTime = axes('Parent', fig, 'Units', 'normalized', 'Position', [.06 .10 .62 .36]);

cpL = .72; cpW = .27;
uipanel('Parent', fig, 'Title', 'Filter Settings', 'FontSize', 9, 'FontWeight', 'bold', ...
    'BackgroundColor', [.25 .25 .25], 'ForegroundColor', [.9 .9 .9], ...
    'Position', [cpL .02 cpW .96]);

row = .92; rh = .032; gap = .005;
bgc = [.25 .25 .25]; fgc = [.9 .9 .9];
cb = @(~,~) doUpdate();

% axis selector
mkLabel(fig, 'Axis:', cpL, row, rh, bgc, fgc);
h.axis = uicontrol(fig, 'Style', 'popupmenu', 'String', axNames, 'Value', 1, ...
    'Units', 'normalized', 'Position', [cpL+.06 row .08 rh], 'FontSize', 8, 'Callback', cb);
row = row - rh - gap*3;

% Gyro LPF1
mkSection(fig, '--- Gyro LPF1 ---', cpL, row, cpW, rh, bgc, [.5 .9 1]);
row = row - rh - gap;
[h.glpf1_type, row] = mkType(fig, cpL, row, rh, gap, bgc, fgc, fp.gyro_lpf1_type, cb);
[h.glpf1_hz, h.glpf1_lbl, row] = mkSlider(fig, 'Hz:', cpL, row, rh, gap, bgc, fgc, 0, 1000, fp.gyro_lpf1_hz, cb);
row = row - gap*2;

% Gyro LPF2
mkSection(fig, '--- Gyro LPF2 ---', cpL, row, cpW, rh, bgc, [.5 .9 1]);
row = row - rh - gap;
[h.glpf2_type, row] = mkType(fig, cpL, row, rh, gap, bgc, fgc, fp.gyro_lpf2_type, cb);
[h.glpf2_hz, h.glpf2_lbl, row] = mkSlider(fig, 'Hz:', cpL, row, rh, gap, bgc, fgc, 0, 1000, fp.gyro_lpf2_hz, cb);
row = row - gap*2;

% Gyro Notch 1
mkSection(fig, '--- Gyro Notch 1 ---', cpL, row, cpW, rh, bgc, [1 .8 .4]);
row = row - rh - gap;
[h.gn1_hz, h.gn1_hz_lbl, row] = mkSlider(fig, 'Center:', cpL, row, rh, gap, bgc, fgc, 0, 1000, fp.gyro_notch1_hz, cb);
[h.gn1_cut, h.gn1_cut_lbl, row] = mkSlider(fig, 'Cutoff:', cpL, row, rh, gap, bgc, fgc, 0, 800, fp.gyro_notch1_cut, cb);
row = row - gap*2;

% Gyro Notch 2
mkSection(fig, '--- Gyro Notch 2 ---', cpL, row, cpW, rh, bgc, [1 .8 .4]);
row = row - rh - gap;
[h.gn2_hz, h.gn2_hz_lbl, row] = mkSlider(fig, 'Center:', cpL, row, rh, gap, bgc, fgc, 0, 1000, fp.gyro_notch2_hz, cb);
[h.gn2_cut, h.gn2_cut_lbl, row] = mkSlider(fig, 'Cutoff:', cpL, row, rh, gap, bgc, fgc, 0, 800, fp.gyro_notch2_cut, cb);
row = row - gap*2;

% D-term LPF1
mkSection(fig, '--- D-term LPF1 ---', cpL, row, cpW, rh, bgc, [.5 1 .5]);
row = row - rh - gap;
[h.dlpf1_type, row] = mkType(fig, cpL, row, rh, gap, bgc, fgc, fp.dterm_lpf1_type, cb);
[h.dlpf1_hz, h.dlpf1_lbl, row] = mkSlider(fig, 'Hz:', cpL, row, rh, gap, bgc, fgc, 0, 500, fp.dterm_lpf1_hz, cb);
row = row - gap*2;

% D-term LPF2
mkSection(fig, '--- D-term LPF2 ---', cpL, row, cpW, rh, bgc, [.5 1 .5]);
row = row - rh - gap;
[h.dlpf2_type, row] = mkType(fig, cpL, row, rh, gap, bgc, fgc, fp.dterm_lpf2_type, cb);
[h.dlpf2_hz, h.dlpf2_lbl, row] = mkSlider(fig, 'Hz:', cpL, row, rh, gap, bgc, fgc, 0, 500, fp.dterm_lpf2_hz, cb);
row = row - gap*2;

% D-term Notch
mkSection(fig, '--- D-term Notch ---', cpL, row, cpW, rh, bgc, [1 .6 .6]);
row = row - rh - gap;
[h.dn_hz, h.dn_hz_lbl, row] = mkSlider(fig, 'Center:', cpL, row, rh, gap, bgc, fgc, 0, 1000, fp.dterm_notch_hz, cb);
[h.dn_cut, h.dn_cut_lbl, row] = mkSlider(fig, 'Cutoff:', cpL, row, rh, gap, bgc, fgc, 0, 800, fp.dterm_notch_cut, cb);

doUpdate();

    function doUpdate()
        if ~ishandle(fig), return; end
        ai = get(h.axis, 'Value');
        dat = axData{ai};

        glpf1t = get(h.glpf1_type, 'Value') - 1;
        glpf1f = round(get(h.glpf1_hz, 'Value'));
        glpf2t = get(h.glpf2_type, 'Value') - 1;
        glpf2f = round(get(h.glpf2_hz, 'Value'));
        gn1f = round(get(h.gn1_hz, 'Value'));
        gn1c = round(get(h.gn1_cut, 'Value'));
        gn2f = round(get(h.gn2_hz, 'Value'));
        gn2c = round(get(h.gn2_cut, 'Value'));
        dlpf1t = get(h.dlpf1_type, 'Value') - 1;
        dlpf1f = round(get(h.dlpf1_hz, 'Value'));
        dlpf2t = get(h.dlpf2_type, 'Value') - 1;
        dlpf2f = round(get(h.dlpf2_hz, 'Value'));
        dnf = round(get(h.dn_hz, 'Value'));
        dnc = round(get(h.dn_cut, 'Value'));

        set(h.glpf1_lbl, 'String', num2str(glpf1f));
        set(h.glpf2_lbl, 'String', num2str(glpf2f));
        set(h.gn1_hz_lbl, 'String', num2str(gn1f));
        set(h.gn1_cut_lbl, 'String', num2str(gn1c));
        set(h.gn2_hz_lbl, 'String', num2str(gn2f));
        set(h.gn2_cut_lbl, 'String', num2str(gn2c));
        set(h.dlpf1_lbl, 'String', num2str(dlpf1f));
        set(h.dlpf2_lbl, 'String', num2str(dlpf2f));
        set(h.dn_hz_lbl, 'String', num2str(dnf));
        set(h.dn_cut_lbl, 'String', num2str(dnc));

        % gyro filter chain
        filt = dat;
        filt = applyLPF(filt, glpf1t, glpf1f, Fs);
        filt = applyLPF(filt, glpf2t, glpf2f, Fs);
        filt = applyNotch(filt, gn1f, gn1c, Fs);
        filt = applyNotch(filt, gn2f, gn2c, Fs);

        % D-term
        dterm = [0; diff(dat)] * Fs;
        dterm = applyLPF(dterm, dlpf1t, dlpf1f, Fs);
        dterm = applyLPF(dterm, dlpf2t, dlpf2f, Fs);
        dterm = applyNotch(dterm, dnf, dnc, Fs);

        F_kHz = Fs / 1000;
        [fO, sO] = PSSpec2d(dat', F_kHz, 1);
        [fF, sF] = PSSpec2d(filt', F_kHz, 1);
        [~, sD] = PSSpec2d(dterm', F_kHz, 1);

        cla(axSpec);
        plot(axSpec, fO, sO, 'Color', [.5 .5 .5], 'LineWidth', 0.8);
        hold(axSpec, 'on');
        plot(axSpec, fF, sF, 'c', 'LineWidth', 1.3);
        plot(axSpec, fO, sD, 'Color', [.4 .9 .4], 'LineWidth', 0.8);
        hold(axSpec, 'off');
        set(axSpec, 'Color', [.1 .1 .1], 'XColor', [.8 .8 .8], 'YColor', [.8 .8 .8], ...
            'FontSize', 8, 'FontWeight', 'bold', 'XLim', [0 Fs/2]);
        set(get(axSpec, 'XLabel'), 'String', 'Frequency (Hz)', 'Color', [.8 .8 .8]);
        set(get(axSpec, 'YLabel'), 'String', 'PSD (dB)', 'Color', [.8 .8 .8]);
        th = title(axSpec, [axNames{ai} ' \x{2014} Spectrum']);
        set(th, 'Color', [.9 .9 .9]);
        grid(axSpec, 'on'); set(axSpec, 'GridColor', [.3 .3 .3]);
        legend(axSpec, {'Raw gyro', 'Filtered gyro', 'D-term (filtered)'}, ...
            'TextColor', [.8 .8 .8], 'Color', [.2 .2 .2], 'EdgeColor', [.4 .4 .4], ...
            'Location', 'northeast', 'FontSize', 7);

        N = min(2000, length(dat));
        t = (0:N-1) / Fs * 1000;
        cla(axTime);
        plot(axTime, t, dat(1:N), 'Color', [.5 .5 .5], 'LineWidth', 0.6);
        hold(axTime, 'on');
        plot(axTime, t, filt(1:N), 'c', 'LineWidth', 1.2);
        hold(axTime, 'off');
        set(axTime, 'Color', [.1 .1 .1], 'XColor', [.8 .8 .8], 'YColor', [.8 .8 .8], ...
            'FontSize', 8, 'FontWeight', 'bold');
        set(get(axTime, 'XLabel'), 'String', 'Time (ms)', 'Color', [.8 .8 .8]);
        set(get(axTime, 'YLabel'), 'String', 'deg/s', 'Color', [.8 .8 .8]);
        th2 = title(axTime, [axNames{ai} ' \x{2014} Time Domain']);
        set(th2, 'Color', [.9 .9 .9]);
        grid(axTime, 'on'); set(axTime, 'GridColor', [.3 .3 .3]);
        legend(axTime, {'Raw', 'Filtered'}, 'TextColor', [.8 .8 .8], ...
            'Color', [.2 .2 .2], 'EdgeColor', [.4 .4 .4], 'Location', 'northeast', 'FontSize', 7);
    end

end

%% helpers (NOT nested — no closure issues)
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

function fp = parseFilterParams(si)
    fp.gyro_lpf1_type = hval(si, 'gyro_lpf1_type', 0);
    fp.gyro_lpf1_hz = hval(si, 'gyro_lpf1_static_hz', 0);
    fp.gyro_lpf2_type = hval(si, 'gyro_lpf2_type', 0);
    fp.gyro_lpf2_hz = hval(si, 'gyro_lpf2_static_hz', 0);
    fp.dterm_lpf1_type = hval(si, 'dterm_lpf1_type', 0);
    fp.dterm_lpf1_hz = hval(si, 'dterm_lpf1_static_hz', 100);
    fp.dterm_lpf2_type = hval(si, 'dterm_lpf2_type', 0);
    fp.dterm_lpf2_hz = hval(si, 'dterm_lpf2_static_hz', 0);
    fp.dterm_notch_hz = hval(si, 'dterm_notch_hz', 0);
    fp.dterm_notch_cut = hval(si, 'dterm_notch_cutoff', 0);
    tmp = hstr(si, 'gyro_notch_hz', '0,0'); v = str2num(tmp);
    if isempty(v), v = [0 0]; end
    fp.gyro_notch1_hz = v(1);
    fp.gyro_notch2_hz = 0; if numel(v) > 1, fp.gyro_notch2_hz = v(2); end
    tmp = hstr(si, 'gyro_notch_cutoff', '0,0'); v = str2num(tmp);
    if isempty(v), v = [0 0]; end
    fp.gyro_notch1_cut = v(1);
    fp.gyro_notch2_cut = 0; if numel(v) > 1, fp.gyro_notch2_cut = v(2); end
end

function v = hval(si, key, default)
    v = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            tmp = str2num(strtrim(si{k,2}));
            if ~isempty(tmp), v = tmp(1); end
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

function mkLabel(fig, txt, cpL, row, rh, bgc, fgc)
    uicontrol(fig, 'Style', 'text', 'String', txt, ...
        'Units', 'normalized', 'Position', [cpL+.01 row .05 rh], ...
        'FontSize', 8, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'HorizontalAlignment', 'left');
end

function mkSection(fig, txt, cpL, row, cpW, rh, bgc, col)
    uicontrol(fig, 'Style', 'text', 'String', txt, ...
        'Units', 'normalized', 'Position', [cpL+.01 row cpW-.02 rh], ...
        'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', bgc, 'ForegroundColor', col);
end

function [hType, rowOut] = mkType(fig, cpL, row, rh, gap, bgc, fgc, initVal, cb)
    uicontrol(fig, 'Style', 'text', 'String', 'Type:', ...
        'Units', 'normalized', 'Position', [cpL+.01 row .05 rh], ...
        'FontSize', 8, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'HorizontalAlignment', 'left');
    hType = uicontrol(fig, 'Style', 'popupmenu', ...
        'String', {'OFF', 'PT1', 'Biquad', 'PT2', 'PT3'}, 'Value', initVal + 1, ...
        'Units', 'normalized', 'Position', [cpL+.06 row .10 rh], 'FontSize', 8, 'Callback', cb);
    rowOut = row - rh - gap;
end

function [hSlider, hLbl, rowOut] = mkSlider(fig, label, cpL, row, rh, gap, bgc, fgc, mn, mx, initVal, cb)
    initVal = max(mn, min(mx, initVal));
    uicontrol(fig, 'Style', 'text', 'String', label, ...
        'Units', 'normalized', 'Position', [cpL+.01 row .05 rh], ...
        'FontSize', 8, 'BackgroundColor', bgc, 'ForegroundColor', fgc, 'HorizontalAlignment', 'left');
    step1 = 1/max(mx-mn, 1); step10 = 10/max(mx-mn, 1);
    hSlider = uicontrol(fig, 'Style', 'slider', 'Min', mn, 'Max', mx, 'Value', initVal, ...
        'Units', 'normalized', 'Position', [cpL+.06 row .13 rh], ...
        'SliderStep', [step1 step10], 'Callback', cb);
    hLbl = uicontrol(fig, 'Style', 'text', 'String', num2str(round(initVal)), ...
        'Units', 'normalized', 'Position', [cpL+.20 row .05 rh], ...
        'FontSize', 8, 'BackgroundColor', bgc, 'ForegroundColor', [1 1 .6], 'HorizontalAlignment', 'left');
    rowOut = row - rh - gap;
end
