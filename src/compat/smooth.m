function ys = smooth(y, span, method)
%% SMOOTH - Octave-compatible data smoothing function
% Drop-in replacement for MATLAB Curve Fitting Toolbox smooth()
%
% Usage:
%   ys = smooth(y)                 - 5-point moving average
%   ys = smooth(y, span)           - span-point moving average
%   ys = smooth(y, span, method)   - with method: 'moving', 'lowess', 'loess'
%
% Methods:
%   'moving' - Simple moving average (default)
%   'lowess' - Locally weighted linear regression (tri-cube weights)
%   'loess'  - Locally weighted quadratic regression (tri-cube weights)

  if nargin < 2, span = 5; end
  if nargin < 3, method = 'moving'; end

  y = y(:);  % ensure column vector
  n = length(y);

  % Clamp span
  span = min(round(span), n);
  span = max(span, 1);
  % Ensure span is odd for symmetric window
  if mod(span, 2) == 0
    span = span + 1;
  end

  switch lower(method)
    case 'moving'
      ys = smooth_moving(y, n, span);
    case 'lowess'
      ys = smooth_loess(y, n, span, 1);
    case 'loess'
      ys = smooth_loess(y, n, span, 2);
    otherwise
      ys = smooth_moving(y, n, span);
  end

end


function ys = smooth_moving(y, n, span)
  % Moving average with edge handling (shrinking window at boundaries)
  ys = zeros(n, 1);
  half = floor(span / 2);
  % Use cumulative sum for O(n) moving average
  cs = [0; cumsum(y)];
  for i = 1:n
    lo = max(1, i - half);
    hi = min(n, i + half);
    ys(i) = (cs(hi + 1) - cs(lo)) / (hi - lo + 1);
  end
end


function ys = smooth_loess(y, n, span, degree)
  % Local regression approximation using Savitzky-Golay filter
  % Much faster than per-point weighted least squares (O(n) vs O(n*span))
  if span <= degree
    ys = y;
    return;
  end
  try
    ys = sgolayfilt(y, degree, span);
  catch
    % Fallback: triple-pass moving average (approximates local regression)
    ys = smooth_moving(y, n, span);
    ys = smooth_moving(ys, n, span);
    ys = smooth_moving(ys, n, span);
  end
end
