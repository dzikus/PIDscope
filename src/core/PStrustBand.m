function fTrust = PStrustBand(freq, C, cohMin, runLen)
%% PStrustBand - top of the frequency band a chirp measurement can be trusted to
%  freq   - frequency vector (Hz)
%  C      - coherence 0..1 on that grid
%  cohMin - coherence below this counts as lost (default 0.8, the line the
%           Bode plot already draws)
%  runLen - how many bins in a row must be lost before the band ends (default 5)
%
%  This bounds where a prediction may be evaluated. It is never a filter cutoff:
%  the chirp excitation falls about 20 dB above 30 Hz, so coherence drops for
%  reasons that have nothing to do with gyro noise. Reading a noise floor out of
%  it is what cost Betaflight issue #5258.

if nargin < 3 || isempty(cohMin), cohMin = 0.8; end
if nargin < 4 || isempty(runLen), runLen = 5; end

freq = freq(:);
C = C(:);

% Below 2 Hz a 2.5 s Welch segment holds too few cycles for coherence to mean
% anything, and the sweep itself starts at 0.2 Hz.
low = freq > 2 & C < cohMin;

iBad = [];
if numel(low) >= runLen
    iBad = find(conv(double(low), ones(runLen, 1), 'valid') == runLen, 1);
end

if isempty(iBad)
    fTrust = max(freq);
else
    fTrust = freq(max(iBad - 1, 2));
end

end
