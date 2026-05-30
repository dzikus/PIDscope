function [stepresponse, t] = PSstepcalc(SP, GY, lograte, Ycorrection, smoothFactor, subsampleFactor, minRate, maxRate)
%% [stepresponse, t] = PSstepcalc(SP, GY, lograte, Ycorrection, smoothFactor, subsampleFactor, minRate, maxRate)
% this function deconvolves the step response function using
% SP = set point (input), GY = filtered gyro (output)
% returns matrix/stack of etimated stepresponse functions, time [t] in ms
%
%
% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
smoothVals = [1 20 40 60];
if smoothFactor > 1
    GY = smooth(GY, smoothVals(smoothFactor),'lowess');
end

if nargin < 6 || isempty(subsampleFactor), subsampleFactor = 5; end
if nargin < 7 || isempty(minRate), minRate = 40; end
if nargin < 8 || isempty(maxRate), maxRate = 500; end

segment_length = (lograte*2000); % 2 sec segments
wnd = (lograte*1000) * .5; % 500ms step response function, length will depend on lograte
StepRespDuration_ms = 500; % max dur of step resp in ms for plotting
t = 0 : 1/lograte : StepRespDuration_ms;% time in ms
      
segment_vector = 1 : round(segment_length/subsampleFactor) : length(SP);
tmp = find((segment_vector+segment_length) < segment_vector(end));
if isempty(tmp), NSegs = 0; else NSegs = max(tmp); end
if NSegs > 0
    SPseg = zeros(NSegs, segment_length+1); GYseg = zeros(NSegs, segment_length+1);
    j = 0;
    for i = 1 : NSegs
        peakRate = max(abs(SP(segment_vector(i):segment_vector(i)+segment_length)));
        if peakRate >= minRate && peakRate <= maxRate
            j=j+1;
            SPseg(j,:) = SP(segment_vector(i):segment_vector(i)+segment_length);  
            GYseg(j,:) = GY(segment_vector(i):segment_vector(i)+segment_length); 
        end
    end

    nValid = j;
    if nValid > 0
        SPseg = SPseg(1:nValid,:);
        GYseg = GYseg(1:nValid,:);

        padLength = 100;
        segW = size(SPseg, 2);
        w = hann(segW)';

        % vectorized FFT: all segments at once
        A = [zeros(nValid, padLength), GYseg .* w, zeros(nValid, padLength)];
        B = [zeros(nValid, padLength), SPseg .* w, zeros(nValid, padLength)];
        fftLen = size(A, 2);
        A = fft(A, [], 2) / fftLen;
        B = fft(B, [], 2) / fftLen;
        Bcon = conj(B);
        resptmp = cumsum(real(ifft((A .* Bcon) ./ (B .* Bcon + 0.0001), [], 2)), 2);

        steadyStateWindow = find(t > 200 & t < StepRespDuration_ms);
        j = 0;
        for i = 1:nValid
            steadyStateResp = resptmp(i, steadyStateWindow);
            if Ycorrection
                ssm = nanmean(steadyStateResp);
                if ssm ~= 1
                    resptmp(i,:) = resptmp(i,:) * (2 - ssm);
                end
                steadyStateResp = resptmp(i, steadyStateWindow);
            end
            if min(steadyStateResp) > 0.5 && max(steadyStateResp) < 3
                j = j + 1;
                stepresponse(j,:) = resptmp(i, 1:1+wnd);
            end
        end
    end
else
end



