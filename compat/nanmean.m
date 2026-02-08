function m = nanmean(x, dim)
%% NANMEAN - Mean value ignoring NaN entries
% Drop-in replacement for MATLAB/Statistics Toolbox nanmean()
%
% Usage:
%   m = nanmean(x)       - mean along first non-singleton dimension
%   m = nanmean(x, dim)  - mean along specified dimension

  if nargin < 2
    if isvector(x)
      dim = find(size(x) > 1, 1);
      if isempty(dim), dim = 1; end
    else
      dim = 1;
    end
  end

  mask = ~isnan(x);
  x(~mask) = 0;
  n = sum(mask, dim);
  n(n == 0) = NaN;
  m = sum(x, dim) ./ n;

end
