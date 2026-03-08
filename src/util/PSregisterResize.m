function PSregisterResize(fig, cpPx, cpItems, mode, topBarL)
%% PSregisterResize - register CP items for PSresizeCP callback
cpd = struct('px', cpPx, 'items', {cpItems}, 'mode', mode);
if nargin >= 5
    cpd.topBarL = topBarL;
end
setappdata(fig, 'PScp', cpd);
try set(fig, 'SizeChangedFcn', @PSresizeCP); catch
    try set(fig, 'ResizeFcn', @PSresizeCP); catch, end
end
% Ensure figure is rendered at final size before computing layout
drawnow;
PSresizeCP(fig, []);
end
