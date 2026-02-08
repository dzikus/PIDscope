function d = finddelay(x, y, maxlag)
%% FINDDELAY - Octave-compatible delay estimation via cross-correlation
% Drop-in replacement for MATLAB Signal Processing Toolbox finddelay()
%
% Usage:
%   d = finddelay(x, y)           - estimate delay between x and y
%   d = finddelay(x, y, maxlag)   - with maximum lag constraint
%
% Returns positive d when y is a delayed copy of x.
% Uses xcorr from the Octave signal package.

  if nargin < 3
    maxlag = max(length(x), length(y)) - 1;
  end

  x = x(:);
  y = y(:);

  % Octave's xcorr lag convention is opposite to MATLAB's finddelay:
  % xcorr(x,y) peaks at lag=-D when y is delayed by D relative to x
  [c, lags] = xcorr(x, y, maxlag);
  [~, idx] = max(abs(c));
  d = -lags(idx);

end
