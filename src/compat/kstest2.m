function [H, pValue, ks2stat] = kstest2(x1, x2, varargin)
%
% Two-sample Kolmogorov-Smirnov test, drop-in replacement for the
% statistics package version so PIDscope does not depend on it.
%
%   [h, p] = kstest2(x1, x2)
%   [h, p] = kstest2(x1, x2, alpha)
%   [h, p] = kstest2(x1, x2, 'alpha', alpha)
%
% Two-sided test only. Asymptotic p-value from the Kolmogorov distribution,
% with Stephens' (1970) small-sample correction applied to lambda.

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

    [xs, idx] = sort([x1; x2]);
    in1 = idx <= n1;
    % both ECDFs have to include every copy of a tied value before comparing
    last = [diff(xs) ~= 0; true];
    d = cumsum(in1) / n1 - cumsum(~in1) / n2;
    ks2stat = max(abs(d(last)));

    nEff = n1 * n2 / (n1 + n2);
    lambda = (sqrt(nEff) + 0.12 + 0.11 / sqrt(nEff)) * ks2stat;
    pValue = min(max(ksSurvival(lambda), 0), 1);

    H = (pValue <= alpha);
end

function p = ksSurvival(lambda)
% P(K > lambda). The alternating series in exp(-2 j^2 lambda^2) needs many
% terms and cancels badly for small lambda; there the theta-function form
% of the same distribution converges in two or three terms.
    if lambda <= 0
        p = 1;
        return;
    end
    s = 0;
    if lambda < 1
        c = -pi^2 / (8 * lambda^2);
        for k = 1:50
            t = exp(c * (2*k - 1)^2);
            s = s + t;
            if t <= eps * s
                break;
            end
        end
        p = 1 - sqrt(2*pi) / lambda * s;
    else
        c = -2 * lambda^2;
        for j = 1:50
            t = exp(c * j^2);
            s = s + (-1)^(j - 1) * t;
            if t <= eps * abs(s)
                break;
            end
        end
        p = 2 * s;
    end
end
