function m = nanmedian(x, dim)
%% NANMEDIAN - Median value ignoring NaN entries
% Drop-in replacement for MATLAB/Statistics Toolbox nanmedian()
%
% Usage:
%   m = nanmedian(x)       - median along first non-singleton dimension
%   m = nanmedian(x, dim)  - median along specified dimension

  if nargin < 2
    % Vector case - just filter NaN and take median
    if isvector(x)
      x = x(~isnan(x));
      if isempty(x)
        m = NaN;
      else
        m = median(x);
      end
      return;
    end
    dim = 1;
  end

  sz = size(x);
  % Build output size (collapse dim to 1)
  out_sz = sz;
  out_sz(dim) = 1;
  m = NaN(out_sz);

  % Iterate over all slices along the target dimension
  n_slices = prod(sz) / sz(dim);
  % Reshape to put target dim first
  perm = [dim, 1:dim-1, dim+1:ndims(x)];
  xp = permute(x, perm);
  xp = reshape(xp, sz(dim), []);

  mv = NaN(1, size(xp, 2));
  for j = 1:size(xp, 2)
    col = xp(:, j);
    col = col(~isnan(col));
    if ~isempty(col)
      mv(j) = median(col);
    end
  end

  m = reshape(mv, out_sz);

end
