function PSplotRPMOverlay(ax, rpmMat, xData, imgHeight, freqMax, mode, nHarmonics)
%% PSplotRPMOverlay - overlay RPM filter motor frequencies on spectrogram
%  ax          - axes handle
%  rpmMat      - Nx4 matrix [motor1_Hz, motor2_Hz, motor3_Hz, motor4_Hz]
%  xData       - throttle vector (Nx1) or number of time windows (scalar)
%  imgHeight   - number of pixel rows in image
%  freqMax     - max frequency in Hz
%  mode        - 'throttle' or 'time'
%  nHarmonics  - number of harmonics to draw (default 3)

if nargin < 7, nHarmonics = 3; end
if isempty(rpmMat) || imgHeight < 2 || freqMax <= 0
    return;
end

hold(ax, 'on');
motorCol = [0 .9 0; .9 .9 0; .9 0 0; .3 .5 1]; % green yellow red blue
lineStyles = {'-'; '--'; ':'};
hz_per_pixel = freqMax / imgHeight;
nMotors = min(4, size(rpmMat, 2));

if strcmp(mode, 'throttle')
    for m = 1:nMotors
        for harm = 1:nHarmonics
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
            if ~isempty(xPts)
                lstyle = lineStyles{min(harm, numel(lineStyles))};
                h = plot(ax, xPts, yPts, lstyle, 'LineWidth', 1);
                set(h, 'Color', motorCol(m,:), 'HitTest', 'off');
            end
        end
    end

elseif strcmp(mode, 'time')
    numWindows = xData;
    numSamples = size(rpmMat, 1);
    if numSamples == 0 || numWindows == 0, return; end
    samplesPerWindow = max(1, round(numSamples / numWindows));

    for m = 1:nMotors
        for harm = 1:nHarmonics
            xPts = [];
            yPts = [];
            for w = 1:numWindows
                lo = max(1, round((w-1) * samplesPerWindow) + 1);
                hi = min(numSamples, round(w * samplesPerWindow));
                vals = rpmMat(lo:hi, m) * harm;
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
            if ~isempty(xPts)
                lstyle = lineStyles{min(harm, numel(lineStyles))};
                h = plot(ax, xPts, yPts, lstyle, 'LineWidth', 1);
                set(h, 'Color', motorCol(m,:), 'HitTest', 'off');
            end
        end
    end
end

end
