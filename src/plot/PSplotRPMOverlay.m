function PSplotRPMOverlay(ax, rpmMat, xData, imgHeight, freqMax, mode, nHarmonics, motors, harmonics, lw)
%% PSplotRPMOverlay - overlay RPM filter motor frequencies on spectrogram
%  ax          - axes handle
%  rpmMat      - Nx4 matrix [motor1_Hz, motor2_Hz, motor3_Hz, motor4_Hz]
%  xData       - throttle vector (Nx1) or number of time windows (scalar)
%  imgHeight   - number of pixel rows in image
%  freqMax     - max frequency in Hz
%  mode        - 'throttle' or 'time'
%  nHarmonics  - max harmonics (default 3)
%  motors      - vector of motor indices to draw, e.g. [1 3] (default all)
%  harmonics   - vector of harmonic indices to draw, e.g. [1 3] (default 1:nHarmonics)
%  lw          - line width (default 1)

if nargin < 7 || isempty(nHarmonics), nHarmonics = 3; end
if nargin < 8 || isempty(motors), motors = 1:min(4, size(rpmMat, 2)); end
if nargin < 9 || isempty(harmonics), harmonics = 1:nHarmonics; end
if nargin < 10 || isempty(lw), lw = 1; end
if isempty(rpmMat) || imgHeight < 2 || freqMax <= 0
    return;
end

hold(ax, 'on');
th = PStheme();
motorCol = cell2mat(th.sigMotor(:));
lineStyles = {'-'; '--'; ':'};
hz_per_pixel = freqMax / imgHeight;

if strcmp(mode, 'throttle')
    for mi = 1:numel(motors)
        m = motors(mi);
        if m > size(rpmMat, 2), continue; end
        ci = min(m, size(motorCol, 1));
        for hi = 1:numel(harmonics)
            harm = harmonics(hi);
            xPts = [];
            yPts = [];
            for bin = 1:100
                inBin = abs(xData - bin) <= 1;
                if any(inBin)
                    vals = rpmMat(inBin, m) * harm;
                    vals = vals(vals > 0 & vals < freqMax);
                    if ~isempty(vals)
                        avgHz = nanmean(vals);
                        y_px = imgHeight - round(avgHz / hz_per_pixel);
                        if y_px >= 1 && y_px <= imgHeight
                            xPts(end+1) = bin;
                            yPts(end+1) = y_px;
                        end
                    end
                end
            end
            if numel(yPts) >= 5, yPts = round(smooth(yPts(:), 5))'; end
            if ~isempty(xPts)
                lstyle = lineStyles{min(harm, numel(lineStyles))};
                plot(ax, xPts, yPts, lstyle, 'LineWidth', lw, ...
                    'Color', motorCol(ci,:), 'HitTest', 'off');
            end
        end
    end

elseif strcmp(mode, 'time')
    numWindows = xData;
    numSamples = size(rpmMat, 1);
    if numSamples == 0 || numWindows == 0, return; end
    samplesPerWindow = max(1, round(numSamples / numWindows));

    for mi = 1:numel(motors)
        m = motors(mi);
        if m > size(rpmMat, 2), continue; end
        ci = min(m, size(motorCol, 1));
        for hi = 1:numel(harmonics)
            harm = harmonics(hi);
            xPts = [];
            yPts = [];
            for w = 1:numWindows
                lo = max(1, round((w-1) * samplesPerWindow) + 1);
                hi2 = min(numSamples, round(w * samplesPerWindow));
                vals = rpmMat(lo:hi2, m) * harm;
                vals = vals(vals > 0 & vals < freqMax);
                if ~isempty(vals)
                    avgHz = nanmean(vals);
                    y_px = imgHeight - round(avgHz / hz_per_pixel);
                    if y_px >= 1 && y_px <= imgHeight
                        xPts(end+1) = w;
                        yPts(end+1) = y_px;
                    end
                end
            end
            if numel(yPts) >= 5, yPts = round(smooth(yPts(:), 5))'; end
            if ~isempty(xPts)
                lstyle = lineStyles{min(harm, numel(lineStyles))};
                plot(ax, xPts, yPts, lstyle, 'LineWidth', lw, ...
                    'Color', motorCol(ci,:), 'HitTest', 'off');
            end
        end
    end
end

end
