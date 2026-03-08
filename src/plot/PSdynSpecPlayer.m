function PSdynSpecPlayer(specMatCell, Tm, F, axisLabels, signalName)
%% PSdynSpecPlayer - animated playback of 1D spectra over time
%  specMatCell - cell array of freq×time matrices (from PStimeFreqCalc, flipud'd)
%  Tm          - time vector (seconds)
%  F           - frequency vector (Hz, ascending)
%  axisLabels  - cell array of axis names {'Roll','Pitch','Yaw'}
%  signalName  - signal type string (e.g. 'Gyro')

if nargin < 5, signalName = ''; end

nCh = numel(specMatCell);
valid = false(nCh, 1);
for k = 1:nCh
    valid(k) = ~isempty(specMatCell{k});
end
chIdx = find(valid);
nValid = numel(chIdx);
if nValid == 0, warndlg('No spectrogram data'); return; end

nFreq = size(specMatCell{chIdx(1)}, 1);
nFrames = size(specMatCell{chIdx(1)}, 2);

% un-flip so row 1 = lowest freq
specData = cell(nCh, 1);
yLo = inf; yHi = -inf;
for k = chIdx'
    specData{k} = flipud(specMatCell{k});
    yLo = min(yLo, min(specData{k}(:)));
    yHi = max(yHi, max(specData{k}(:)));
end
yPad = (yHi - yLo) * 0.05;

thm = PStheme();
fontsz = thm.fontsz;
screensz = get(0, 'ScreenSize');
figW = round(.6 * screensz(3));
figH = round(.85 * screensz(4));
figName = ['Spectrum Player - ' signalName];
fig = findobj('Type', 'figure', 'Name', figName);
if ~isempty(fig), close(fig); end
fig = figure('Name', figName, 'NumberTitle', 'off', ...
    'Color', thm.figBg, 'Position', round([0 0 screensz(3) screensz(4)]));
try set(fig, 'WindowState', 'maximized'); catch, end

axColors = {[0 .85 .85], [.85 .85 0], [.85 .3 .85]};

% layout: nValid spectrum rows + 1 spectrogram row at bottom + transport bar
specH = 0.58 / nValid;
specGap = 0.02;
specBot = 0.34;

specLines = {};
titleHandles = {};
axSpec = {};
for vi = 1:nValid
    k = chIdx(vi);
    yPos = specBot + (nValid - vi) * (specH + specGap);
    ax = axes('Parent', fig, 'Units', 'normalized', ...
        'Position', [.07 yPos .86 specH - specGap]);
    specLines{vi} = plot(ax, F, specData{k}(:, 1), 'Color', axColors{k}, 'LineWidth', 1.2);
    set(ax, 'XLim', [F(1) F(end)], 'YLim', [yLo-yPad yHi+yPad]);
    PSstyleAxes(ax, thm);
    set(get(ax, 'YLabel'), 'String', 'dB');
    if vi == nValid
        set(get(ax, 'XLabel'), 'String', 'Frequency (Hz)');
    else
        set(ax, 'XTickLabel', []);
    end
    titleHandles{vi} = title(ax, axisLabels{k});
    set(titleHandles{vi}, 'Color', axColors{k});
    axSpec{vi} = ax;
end

% spectrogram (use first valid channel)
sgIdx = chIdx(1);
axSg = axes('Parent', fig, 'Units', 'normalized', 'Position', [.07 .10 .86 .16]);
imagesc(axSg, specMatCell{sgIdx});
PSstyleAxes(axSg, thm);

nYt = 4;
yTk = linspace(1, nFreq, nYt+1);
yLb = arrayfun(@(y) sprintf('%.0f', F(end)-(y-1)/(nFreq-1)*F(end)), yTk, 'UniformOutput', false);
set(axSg, 'YTick', yTk, 'YTickLabel', yLb);

nXt = 8;
xTk = linspace(1, nFrames, nXt+1);
xLb = arrayfun(@(x) sprintf('%.1f', interp1(1:nFrames, Tm, x)), xTk, 'UniformOutput', false);
set(axSg, 'XTick', xTk, 'XTickLabel', xLb);
set(get(axSg, 'XLabel'), 'String', 'Time (s)');
try colormap(axSg, hot); catch, end

hold(axSg, 'on');
cursorLine = plot(axSg, [1 1], [1 nFreq], 'w-', 'LineWidth', 1.5);
hold(axSg, 'off');

% time label above spectrogram
timeLbl = uicontrol(fig, 'Style', 'text', ...
    'String', sprintf('%s  t = %.2fs', signalName, Tm(1)), ...
    'Units', 'normalized', 'Position', [.07 .27 .40 .025], ...
    'FontSize', fontsz, 'FontWeight', 'bold', ...
    'BackgroundColor', thm.figBg, 'ForegroundColor', thm.textPrimary, ...
    'HorizontalAlignment', 'left');

% transport controls
btnW = .07; btnH = .04; btnY = .02;
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Play', ...
    'Units', 'normalized', 'Position', [.07 btnY btnW btnH], ...
    'FontSize', fontsz, 'FontWeight', 'bold', 'ForegroundColor', [0 .6 0], ...
    'Callback', @playCallback);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Pause', ...
    'Units', 'normalized', 'Position', [.07+btnW+.01 btnY btnW btnH], ...
    'FontSize', fontsz, 'FontWeight', 'bold', 'ForegroundColor', [.8 .2 0], ...
    'Callback', @pauseCallback);

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Stop', ...
    'Units', 'normalized', 'Position', [.07+2*(btnW+.01) btnY btnW btnH], ...
    'FontSize', fontsz, 'FontWeight', 'bold', 'ForegroundColor', [.7 0 0], ...
    'Callback', @stopCallback);

uicontrol(fig, 'Style', 'text', 'String', 'Speed:', ...
    'Units', 'normalized', 'Position', [.30 btnY+.005 .045 .030], ...
    'FontSize', fontsz, 'BackgroundColor', thm.figBg, 'ForegroundColor', thm.textPrimary);
speedMenu = uicontrol(fig, 'Style', 'popupmenu', ...
    'String', {'0.25x', '0.5x', '1x', '2x', '4x'}, 'Value', 3, ...
    'Units', 'normalized', 'Position', [.35 btnY .06 btnH], 'FontSize', fontsz);

frameLbl = uicontrol(fig, 'Style', 'text', ...
    'String', sprintf('1 / %d', nFrames), ...
    'Units', 'normalized', 'Position', [.42 btnY+.005 .08 .030], ...
    'FontSize', fontsz, 'BackgroundColor', thm.figBg, 'ForegroundColor', thm.textSecondary, ...
    'HorizontalAlignment', 'center');

timeSlider = uicontrol(fig, 'Style', 'slider', 'Min', 1, 'Max', nFrames, 'Value', 1, ...
    'Units', 'normalized', 'Position', [.51 btnY .42 btnH], ...
    'SliderStep', [1/max(nFrames-1,1) 10/max(nFrames-1,1)], ...
    'Callback', @sliderCallback);

setappdata(fig, 'isPlaying', false);
setappdata(fig, 'currentFrame', 1);

    function updateDisplay(frame)
        if ~ishandle(fig), return; end
        frame = max(1, min(nFrames, round(frame)));
        for vi2 = 1:nValid
            k2 = chIdx(vi2);
            set(specLines{vi2}, 'YData', specData{k2}(:, frame));
        end
        set(cursorLine, 'XData', [frame frame]);
        set(timeLbl, 'String', sprintf('%s  t = %.2fs', signalName, Tm(frame)));
        set(timeSlider, 'Value', frame);
        set(frameLbl, 'String', sprintf('%d / %d', frame, nFrames));
        setappdata(fig, 'currentFrame', frame);
    end

    function playCallback(~, ~)
        if getappdata(fig, 'isPlaying'), return; end
        setappdata(fig, 'isPlaying', true);
        speeds = [0.25 0.5 1 2 4];
        spd = speeds(get(speedMenu, 'Value'));
        dt = median(diff(Tm));
        frame = getappdata(fig, 'currentFrame');
        if frame >= nFrames, frame = 1; end
        while frame <= nFrames && ishandle(fig) && getappdata(fig, 'isPlaying')
            updateDisplay(frame);
            drawnow;
            pause(dt / spd);
            frame = frame + 1;
        end
        if ishandle(fig), setappdata(fig, 'isPlaying', false); end
    end

    function pauseCallback(~, ~)
        setappdata(fig, 'isPlaying', false);
    end

    function stopCallback(~, ~)
        setappdata(fig, 'isPlaying', false);
        updateDisplay(1);
    end

    function sliderCallback(src, ~)
        setappdata(fig, 'isPlaying', false);
        updateDisplay(round(get(src, 'Value')));
    end

end
