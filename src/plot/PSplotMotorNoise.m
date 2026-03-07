function PSplotMotorNoise(T, f, tIND, Fs)
%% PSplotMotorNoise - per-motor spectral analysis for noise diagnostics
%  T      - data struct for file f
%  f      - file index (unused, for signature compat)
%  tIND   - logical time index mask
%  Fs     - sample rate (Hz)

th = PStheme();
fontsz = th.fontsz;
screensz = get(0, 'ScreenSize');
fig = findobj('Type', 'figure', 'Name', 'Motor / Prop Noise Analysis');
if ~isempty(fig), close(fig); end
fig = figure('Name', 'Motor / Prop Noise Analysis', 'NumberTitle', 'off', ...
    'Color', th.figBg, ...
    'Position', round([.08*screensz(3) .06*screensz(4) .78*screensz(3) .82*screensz(4)]));

F_kHz = Fs / 1000;
motorCol = {'motor_0_', 'motor_1_', 'motor_2_', 'motor_3_'};
motorLbl = {'Motor 1', 'Motor 2', 'Motor 3', 'Motor 4'};
mCol = {[0 .85 .3], [.85 .85 0], [.85 .2 .2], [.3 .5 1]};
gyroAxLbl = {'Roll', 'Pitch', 'Yaw'};
gyroCol = {'gyroADC_0_', 'gyroADC_1_', 'gyroADC_2_'};

nMotors = 0;
for m = 1:4
    if isfield(T, motorCol{m}), nMotors = m; end
end
if nMotors == 0, warndlg('No motor data in log'); close(fig); return; end

motorData = cell(nMotors, 1);
gyroData = cell(3, 1);
for m = 1:nMotors
    motorData{m} = T.(motorCol{m})(tIND);
end
for g = 1:3
    gyroData{g} = T.(gyroCol{g})(tIND);
end

throttle = zeros(size(motorData{1}));
for m = 1:nMotors, throttle = throttle + motorData{m}; end
throttle = throttle / nMotors;

motorSpec = cell(nMotors, 1);
motorFreq = cell(nMotors, 1);
for m = 1:nMotors
    mdat_ac = motorData{m} - mean(motorData{m});
    [motorFreq{m}, motorSpec{m}] = PSSpec2d(mdat_ac', F_kHz, 1);
end

gyroSpec = cell(3, 1); gyroFreqV = cell(3, 1);
for g = 1:3
    gdat_ac = gyroData{g} - mean(gyroData{g});
    [gyroFreqV{g}, gyroSpec{g}] = PSSpec2d(gdat_ac', F_kHz, 1);
end

fMax = min(Fs/2, 1000);

% store for callbacks
dat = struct();
dat.motorData = motorData;
dat.gyroData = gyroData;
dat.nMotors = nMotors;
dat.Fs = Fs;
dat.fMax = fMax;
dat.mCol = {mCol};
dat.motorLbl = {motorLbl};
dat.gyroAxLbl = gyroAxLbl;

% --- Info bar (top, thin) ---
rmsAll = zeros(nMotors, 1);
for m = 1:nMotors
    mask = motorFreq{m} >= 100 & motorFreq{m} <= 600;
    if any(mask)
        lin = 10.^(motorSpec{m}(mask)/10);
        rmsAll(m) = 10*log10(mean(lin));
    end
end
[~, worst] = max(rmsAll);
[~, best] = min(rmsAll);
spread = rmsAll(worst) - rmsAll(best);
infoStr = sprintf('Noisiest: %s (%.0f dB)   Quietest: %s (%.0f dB)   Spread: %.1f dB', ...
    motorLbl{worst}, rmsAll(worst), motorLbl{best}, rmsAll(best), spread);
uicontrol(fig, 'Style', 'text', 'String', infoStr, 'Units', 'normalized', ...
    'Position', [.06 .965 .88 .03], 'FontSize', fontsz, 'FontWeight', 'bold', ...
    'ForegroundColor', th.textAccent, 'BackgroundColor', th.panelBg, ...
    'HorizontalAlignment', 'center');

% --- TOP LEFT: All motors overlay PSD ---
axOvl = axes('Parent', fig, 'Units', 'normalized', 'Position', [.06 .70 .42 .22]);
for m = 1:nMotors
    plot(axOvl, motorFreq{m}, motorSpec{m}, 'Color', mCol{m}, 'LineWidth', 1.2);
    hold(axOvl, 'on');
end
addBandShading(axOvl);
hold(axOvl, 'off');
PSstyleAxes(axOvl, th); set(axOvl, 'XLim', [0 fMax]);
set(get(axOvl, 'YLabel'), 'String', 'dB');
title(axOvl, 'Motor PSD Comparison');
h_leg = legend(axOvl, motorLbl(1:nMotors), 'Location', 'northeast');
try PSstyleLegend(h_leg, th); catch, end

% --- TOP RIGHT: Gyro PSD ---
axGyro = axes('Parent', fig, 'Units', 'normalized', 'Position', [.56 .70 .38 .22]);
gCols = {[1 .4 .4], [.4 1 .4], [.4 .6 1]};
for g = 1:3
    plot(axGyro, gyroFreqV{g}, gyroSpec{g}, 'Color', gCols{g}, 'LineWidth', 1.1);
    hold(axGyro, 'on');
end
addBandShading(axGyro);
hold(axGyro, 'off');
PSstyleAxes(axGyro, th); set(axGyro, 'XLim', [0 fMax]);
set(get(axGyro, 'YLabel'), 'String', 'dB');
title(axGyro, 'Gyro Noise');
h_leg = legend(axGyro, gyroAxLbl, 'Location', 'northeast');
try PSstyleLegend(h_leg, th); catch, end

% --- MID LEFT: Motor-Gyro coherence ---
axCoh = axes('Parent', fig, 'Units', 'normalized', 'Position', [.06 .39 .42 .25]);
dat.axCoh = axCoh;
plotCoherence(axCoh, motorData, gyroData{1}, nMotors, mCol, motorLbl, Fs, fMax, 'Roll');

% gyro axis dropdown (right of title, inside plot area)
uicontrol(fig, 'Style', 'popupmenu', 'String', {'Roll', 'Pitch', 'Yaw'}, ...
    'Units', 'normalized', 'Position', [.06 .64 .10 .025], ...
    'FontSize', fontsz, 'Callback', {@cohAxisCb, fig});
setappdata(fig, 'mndat', dat);

% --- MID RIGHT: Noise bar chart per frequency band ---
axBar = axes('Parent', fig, 'Units', 'normalized', 'Position', [.56 .39 .38 .25]);
bands = [20 80; 80 200; 200 500; 500 round(fMax)];
bandLabelsClean = {'Propwash', 'Low motor', 'Motor', 'High freq'};
noiseMat = zeros(nMotors, size(bands, 1));
for m = 1:nMotors
    for b = 1:size(bands, 1)
        mask = motorFreq{m} >= bands(b,1) & motorFreq{m} < bands(b,2);
        if any(mask)
            lin = 10.^(motorSpec{m}(mask)/10);
            noiseMat(m, b) = 10*log10(mean(lin));
        end
    end
end
bh = bar(axBar, noiseMat', 'grouped');
for m = 1:nMotors
    set(bh(m), 'FaceColor', mCol{m});
end
PSstyleAxes(axBar, th);
set(axBar, 'XTick', 1:size(bands,1), 'XTickLabel', bandLabelsClean);
set(get(axBar, 'YLabel'), 'String', 'Mean PSD (dB)');
title(axBar, 'Noise by Frequency Band');
h_leg = legend(axBar, motorLbl(1:nMotors), 'Location', 'northeast');
try PSstyleLegend(h_leg, th); catch, end

% --- BOTTOM: Motor output time domain ---
axTime = axes('Parent', fig, 'Units', 'normalized', 'Position', [.06 .06 .88 .26]);
N = length(motorData{1});
t = (0:N-1) / Fs;
for m = 1:nMotors
    plot(axTime, t, motorData{m}, 'Color', mCol{m}, 'LineWidth', 0.5);
    hold(axTime, 'on');
end
plot(axTime, t, throttle, 'Color', [.9 .9 .9], 'LineWidth', 1.5, 'LineStyle', '--');
hold(axTime, 'off');
PSstyleAxes(axTime, th); set(axTime, 'XLim', [0 max(t)]);
set(axTime, 'YLim', [0 100]);
set(get(axTime, 'XLabel'), 'String', 'Time (s)');
set(get(axTime, 'YLabel'), 'String', 'Motor %');
title(axTime, 'Motor Output');
h_leg = legend(axTime, [motorLbl(1:nMotors), {'Throttle avg'}], 'Location', 'northeast');
try PSstyleLegend(h_leg, th); catch, end

PSdatatipSetup(fig);

end


function cohAxisCb(src, ~, fig)
    dat = getappdata(fig, 'mndat');
    gIdx = get(src, 'Value');
    gdat = dat.gyroData{gIdx};
    axLbl = dat.gyroAxLbl{gIdx};
    plotCoherence(dat.axCoh, dat.motorData, gdat, dat.nMotors, ...
        dat.mCol{1}, dat.motorLbl{1}, dat.Fs, dat.fMax, axLbl);
end


function plotCoherence(ax, motorData, gdat, nMotors, mCol, motorLbl, Fs, fMax, axLabel)
    cla(ax);
    thm = PStheme();
    gdat_ac = gdat - mean(gdat);
    for m = 1:nMotors
        mdat = motorData{m} - mean(motorData{m});
        [Cxy, fCoh] = mscohere_simple(mdat, gdat_ac, Fs, 1024);
        plot(ax, fCoh, Cxy, 'Color', mCol{m}, 'LineWidth', 1.0);
        hold(ax, 'on');
    end
    hold(ax, 'off');
    PSstyleAxes(ax, thm); set(ax, 'XLim', [0 fMax]);
    set(ax, 'YLim', [0 1.05]);
    set(get(ax, 'XLabel'), 'String', 'Hz');
    set(get(ax, 'YLabel'), 'String', 'Coherence');
    title(ax, ['Motor-Gyro Coherence (' axLabel ')']);
    h_leg = legend(ax, motorLbl(1:nMotors), 'Location', 'northeast');
    try PSstyleLegend(h_leg, thm); catch, end
end


function addBandShading(ax)
    yl = get(ax, 'YLim');
    % propwash 20-80 Hz
    fill(ax, [20 80 80 20], [yl(1) yl(1) yl(2) yl(2)], [.5 .3 .1], ...
        'FaceAlpha', .12, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    % motor noise 100-400 Hz
    fill(ax, [100 400 400 100], [yl(1) yl(1) yl(2) yl(2)], [.5 .1 .1], ...
        'FaceAlpha', .12, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end


function [Cxy, f] = mscohere_simple(x, y, Fs, nfft)
    if nargin < 4, nfft = 1024; end
    noverlap = round(nfft * 0.5);
    w = hann(nfft);
    nstep = nfft - noverlap;
    nseg = floor((length(x) - nfft) / nstep);
    if nseg < 1
        f = (0:nfft/2)' * Fs / nfft;
        Cxy = zeros(size(f));
        return;
    end

    nhalf = nfft/2 + 1;
    Sxx = zeros(nhalf, 1); Syy = zeros(nhalf, 1); Sxy = zeros(nhalf, 1);

    for s = 1:nseg
        idx = (s-1)*nstep + (1:nfft);
        xw = (x(idx) - mean(x(idx))) .* w;
        yw = (y(idx) - mean(y(idx))) .* w;
        X = fft(xw, nfft); X = X(1:nhalf);
        Y = fft(yw, nfft); Y = Y(1:nhalf);
        Sxx = Sxx + X .* conj(X);
        Syy = Syy + Y .* conj(Y);
        Sxy = Sxy + Y .* conj(X);
    end

    Cxy = abs(Sxy).^2 ./ (Sxx .* Syy + 1e-12);
    f = (0:nhalf-1)' * Fs / nfft;
end
