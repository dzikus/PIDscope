function [fundFreq, harmonics] = PSestimateRPM(freqAxis, ampMatrix, nHarmonics)
%% PSestimateRPM - estimate motor fundamental frequency from throttle-binned spectra
%  freqAxis   - 1×M frequency vector in Hz (from PSthrSpec freq(1,:))
%  ampMatrix  - 100×M amplitude matrix (throttle bins × freq bins)
%  nHarmonics - number of harmonics to return (default 3)
%
%  Returns:
%    fundFreq  - 100×1 estimated fundamental freq per throttle bin (Hz), NaN where unknown
%    harmonics - 100×nHarmonics matrix (Hz)

if nargin < 3, nHarmonics = 3; end

nBins = size(ampMatrix, 1);
fundFreq = NaN(nBins, 1);

% motor noise band limits
fLo = 80;
fHi = 500;
fMask = freqAxis >= fLo & freqAxis <= fHi;
fIdx = find(fMask);

if isempty(fIdx), harmonics = NaN(nBins, nHarmonics); return; end

for t = 1:nBins
    spec = ampMatrix(t, :);
    if all(spec == 0), continue; end

    band = spec(fIdx);
    noiseFloor = median(band);
    threshold = noiseFloor + (max(band) - noiseFloor) * 0.3;

    % find local maxima above threshold
    pkIdx = [];
    pkVal = [];
    for j = 2:length(band)-1
        if band(j) > band(j-1) && band(j) > band(j+1) && band(j) > threshold
            pkIdx(end+1) = j;
            pkVal(end+1) = band(j);
        end
    end
    if isempty(pkIdx), continue; end

    % sort by amplitude, take top candidate
    [~, si] = sort(pkVal, 'descend');
    f0 = freqAxis(fIdx(pkIdx(si(1))));

    % check for harmonic confirmation: peak near 2*f0
    f2lo = f0 * 1.8;
    f2hi = f0 * 2.2;
    f2mask = freqAxis >= f2lo & freqAxis <= f2hi;
    if any(f2mask) && max(spec(f2mask)) > noiseFloor * 1.5
        fundFreq(t) = f0;
    else
        % might be a harmonic itself — check if f0/2 has a peak
        fhlo = f0 * 0.4;
        fhhi = f0 * 0.6;
        fhmask = freqAxis >= fhlo & freqAxis <= fhhi & fMask;
        if any(fhmask) && max(spec(fhmask)) > noiseFloor * 1.3
            fundFreq(t) = freqAxis(fIdx(pkIdx(si(1)))) / 2;
        else
            fundFreq(t) = f0;
        end
    end
end

% smooth across throttle bins to reduce jitter
validMask = ~isnan(fundFreq);
if sum(validMask) > 5
    fundFreq(validMask) = smooth(fundFreq(validMask), 5, 'moving');
end

% generate harmonics
harmonics = fundFreq .* (1:nHarmonics);

end
