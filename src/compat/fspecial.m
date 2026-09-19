function h = fspecial(type, hsize, sigma)
%
% Gaussian filter kernel, drop-in replacement for the image package
% version so PIDscope does not depend on it.
%
%   h = fspecial('gaussian', [rows cols], sigma)
%   h = fspecial('gaussian', n, sigma)

    if nargin < 1 || ~ischar(type) || ~strcmpi(type, 'gaussian')
        error('fspecial: only the ''gaussian'' type is implemented');
    end
    if nargin < 2 || isempty(hsize)
        hsize = [3 3];
    end
    if nargin < 3 || isempty(sigma)
        sigma = 0.5;
    end

    if isscalar(hsize)
        hsize = [hsize hsize];
    end
    if numel(hsize) ~= 2
        error('fspecial: hsize must be a scalar or a two-element vector');
    end
    if ~isscalar(sigma) || sigma <= 0
        error('fspecial: sigma must be a positive scalar');
    end

    nr = hsize(1);
    nc = hsize(2);
    [x, y] = meshgrid(-(nc - 1) / 2 : (nc - 1) / 2, ...
                      -(nr - 1) / 2 : (nr - 1) / 2);

    h = exp(-(x .^ 2 + y .^ 2) / (2 * sigma ^ 2));
    h(h < eps * max(h(:))) = 0;

    s = sum(h(:));
    if s ~= 0
        h = h / s;
    end
end
