function s = nanstd(x, flag, dim)
%% NANSTD - Standard deviation ignoring NaN entries

  if nargin < 2 || isempty(flag), flag = 0; end
  if nargin < 3
    if isvector(x)
      dim = find(size(x) > 1, 1);
      if isempty(dim), dim = 1; end
    else
      dim = 1;
    end
  end

  mask = ~isnan(x);
  n = sum(mask, dim);
  mu = nanmean(x, dim);
  x(~mask) = 0;
  x2 = (x - mu).^2;
  x2(~mask) = 0;

  if flag == 0
    denom = max(n - 1, 1);
  else
    denom = max(n, 1);
  end
  denom(n == 0) = NaN;
  s = sqrt(sum(x2, dim) ./ denom);

end
