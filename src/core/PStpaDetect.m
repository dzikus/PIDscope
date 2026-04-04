function [tpaFlag, onsetPct, ratioDB] = PStpaDetect(ampMat, freqRow, psd)
%% Detect throttle-correlated noise escalation in 30-80 Hz band
%  ampMat  - 100xM throttle-binned spectrum (from PSthrSpec)
%  freqRow - 1xM frequency vector (Hz)
%  psd     - true if ampMat values are in dB

    tpaFlag = false; onsetPct = 0; ratioDB = 0;

    if isempty(ampMat) || size(ampMat,2) < 2, return; end
    if isempty(freqRow), return; end

    % diagnostic band: 30-80 Hz (D-term 60-80, P-term 30-50)
    fIdx = find(freqRow >= 30 & freqRow <= 80);
    if isempty(fIdx), return; end

    % throttle regions
    loThr = 10:30;   % hover
    hiThr = 50:90;   % cruise to punch-out
    loThr = loThr(loThr <= size(ampMat,1));
    hiThr = hiThr(hiThr <= size(ampMat,1));
    if isempty(loThr) || isempty(hiThr), return; end

    bandLo = ampMat(loThr, fIdx);
    bandHi = ampMat(hiThr, fIdx);

    Elo = nanmean(bandLo(:));
    Ehi = nanmean(bandHi(:));

    if psd
        ratioDB = Ehi - Elo;
    else
        if Elo <= 0, return; end
        ratioDB = 20 * log10(Ehi / Elo);
    end

    tpaFlag = ratioDB > 6;

    if ~tpaFlag, return; end

    % onset: per-bin energy, find first bin exceeding baseline
    if psd
        thresh = Elo + 3;
    else
        thresh = Elo * 1.5;
    end
    for t = 1:size(ampMat,1)
        Et = nanmean(ampMat(t, fIdx));
        if Et > thresh
            onsetPct = t;
            break;
        end
    end
end
