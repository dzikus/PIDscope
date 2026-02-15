function PSplotDynNotchOverlay(ax, notchMat, xData, imgHeight, freqMax, mode)
%% PSplotDynNotchOverlay - overlay dynamic notch frequencies on spectrogram
%  ax        - axes handle
%  notchMat  - Nx3 matrix [notch1_Hz, notch2_Hz, notch3_Hz] (same length as xData)
%  xData     - Nx1 throttle (%) or time index for each sample
%  imgHeight - number of pixel rows in image (size(img,1))
%  freqMax   - max frequency in Hz (Nyquist)
%  mode      - 'throttle' or 'time'

if isempty(notchMat) || imgHeight < 2 || freqMax <= 0
    return;
end

hold(ax, 'on');
colors = [0 1 1; 1 1 1; 1 0 1]; % cyan, white, magenta
numNotches = min(3, size(notchMat, 2));
hz_per_pixel = freqMax / imgHeight;

if strcmp(mode, 'throttle')
    % Average notch freq per throttle bin (1-100, same as PSthrSpec)
    for n = 1:numNotches
        xPts = [];
        yPts = [];
        for bin = 1:100
            inBin = abs(xData - bin) <= 1;
            if any(inBin)
                vals = notchMat(inBin, n);
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
            h = plot(ax, xPts, yPts, '.', 'MarkerSize', 4);
            set(h, 'Color', colors(n,:), 'HitTest', 'off');
        end
    end

elseif strcmp(mode, 'time')
    % xData = number of time windows in spectrogram
    % notchMat has full-rate samples, need to resample to numWindows
    numWindows = xData;
    numSamples = size(notchMat, 1);
    if numSamples == 0 || numWindows == 0, return; end

    samplesPerWindow = max(1, round(numSamples / numWindows));

    for n = 1:numNotches
        xPts = [];
        yPts = [];
        for w = 1:numWindows
            lo = max(1, round((w-1) * samplesPerWindow) + 1);
            hi = min(numSamples, round(w * samplesPerWindow));
            vals = notchMat(lo:hi, n);
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
            h = plot(ax, xPts, yPts, '.', 'MarkerSize', 3);
            set(h, 'Color', colors(n,:), 'HitTest', 'off');
        end
    end
end

end
