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
  % Local regression with tri-cube weight function
  % degree=1: LOWESS (linear), degree=2: LOESS (quadratic)
  ys = zeros(n, 1);
  half = floor(span / 2);

  for i = 1:n
    lo = max(1, i - half);
    hi = min(n, i + half);
    m = hi - lo + 1;

    x_local = (lo:hi)' - i;  % centered at current point
    y_local = y(lo:hi);

    % Tri-cube weight function
    max_dist = max(abs(x_local)) + 1;
    u = abs(x_local) / max_dist;
    w = (1 - u.^3).^3;

    % Build design matrix
    if degree == 1
      X = [ones(m, 1), x_local];
    else
      X = [ones(m, 1), x_local, x_local.^2];
    end

    % Weighted least squares: beta = (X'WX) \ (X'Wy)
    W = diag(w);
    beta = (X' * W * X) \ (X' * (w .* y_local));
    ys(i) = beta(1);  % fitted value at center (x_local=0)
  end
end
