function [H, pValue, ks2stat] = kstest2(x1, x2, varargin)
%
% Two-sample Kolmogorov-Smirnov test, drop-in replacement for the
% statistics package version so PIDscope does not depend on it.
%
%   [h, p] = kstest2(x1, x2)
%   [h, p] = kstest2(x1, x2, alpha)
%   [h, p] = kstest2(x1, x2, 'alpha', alpha)
%
% Two-sided test only. Asymptotic p-value after Numerical Recipes 14.3.

    alpha = 0.05;
    if numel(varargin) == 1 && isnumeric(varargin{1})
        alpha = varargin{1};
    elseif numel(varargin) == 2 && strcmpi(varargin{1}, 'alpha')
        alpha = varargin{2};
    elseif ~isempty(varargin)
        error('kstest2: unsupported arguments');
    end

    if ~isscalar(alpha) || ~isnumeric(alpha) || alpha <= 0 || alpha >= 1
        error('kstest2: alpha must be a scalar in (0,1)');
    end

    x1 = x1(:);
    x2 = x2(:);
    x1 = x1(~isnan(x1));
    x2 = x2(~isnan(x2));

    n1 = numel(x1);
    n2 = numel(x2);
    if n1 < 1 || n2 < 1
        error('kstest2: both samples must be non-empty');
    end

    edges = [-Inf; sort([x1; x2]); Inf];
    cdf1 = cumsum(histc(x1, edges)) / n1;
    cdf2 = cumsum(histc(x2, edges)) / n2;
    ks2stat = max(abs(cdf1(1:end-1) - cdf2(1:end-1)));

    n = n1 * n2 / (n1 + n2);
    lambda = max((sqrt(n) + 0.12 + 0.11 / sqrt(n)) * ks2stat, 0);

    v = 1:101;
    pValue = 2 * sum((-1) .^ (v - 1) .* exp(-2 * lambda * lambda * v .^ 2));
    pValue = min(max(pValue, 0), 1);

    H = (alpha >= pValue);
end
