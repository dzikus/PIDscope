function [b, a] = PSbfFilters(type, fc, Fs, Q)
%% PSbfFilters - BF-compatible discrete filter coefficients
%  type: 'pt1','pt2','pt3','biquad','notch'
%  fc: cutoff/center freq (Hz)
%  Fs: sample rate (Hz)
%  Q: quality factor (notch only, default 3.5 = BF dyn_notch_q/100)

if nargin < 4, Q = 1/sqrt(2); end
if fc <= 0 || fc >= Fs/2
    b = 1; a = 1; return;
end

Ts = 1/Fs;

switch lower(type)
    case 'pt1'
        RC = 1/(2*pi*fc);
        k = Ts/(RC + Ts);
        b = [k 0]; a = [1 -(1-k)];

    case 'pt2'
        fc_corr = fc * 1.553773974;
        RC = 1/(2*pi*fc_corr);
        k = Ts/(RC + Ts);
        b1 = [k 0]; a1 = [1 -(1-k)];
        b = conv(b1, b1); a = conv(a1, a1);

    case 'pt3'
        fc_corr = fc * 1.961459177;
        RC = 1/(2*pi*fc_corr);
        k = Ts/(RC + Ts);
        b1 = [k 0]; a1 = [1 -(1-k)];
        b = conv(conv(b1, b1), b1); a = conv(conv(a1, a1), a1);

    case 'biquad'
        w0 = 2*pi*fc/Fs;
        alpha = sin(w0) / (2 * (1/sqrt(2)));
        b0 = (1 - cos(w0)) / 2;
        b1 = 1 - cos(w0);
        b2 = (1 - cos(w0)) / 2;
        a0 = 1 + alpha;
        b = [b0 b1 b2] / a0;
        a = [1 -2*cos(w0)/a0 (1-alpha)/a0];

    case 'notch'
        w0 = 2*pi*fc/Fs;
        alpha = sin(w0) / (2*Q);
        a0 = 1 + alpha;
        b = [1 -2*cos(w0) 1] / a0;
        a = [1 -2*cos(w0)/a0 (1-alpha)/a0];

    otherwise
        b = 1; a = 1;
end
end
