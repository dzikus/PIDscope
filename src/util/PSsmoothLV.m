function y = PSsmoothLV(fig, Tfile, fileIdx, fieldName, sFactor, scale)
%% PSsmoothLV - cached smooth() for Log Viewer performance
% Avoids recomputing loess on 100k+ samples when user only toggles checkboxes

if nargin < 6, scale = 1; end

sc = getappdata(fig, 'smoothCacheLV');
if isempty(sc) || ~isfield(sc, 'fIdx') || sc.fIdx ~= fileIdx
    sc = struct('fIdx', fileIdx);
end

cacheKey = [fieldName '_s' int2str(sFactor)];
if isfield(sc, cacheKey)
    y = sc.(cacheKey);
    return;
end

raw = Tfile.(fieldName);
if scale ~= 1, raw = raw * scale; end
y = smooth(raw, sFactor, 'loess');
sc.(cacheKey) = y;
setappdata(fig, 'smoothCacheLV', sc);
end
