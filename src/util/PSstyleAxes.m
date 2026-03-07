function PSstyleAxes(ax, th)
%% PSstyleAxes - apply dark theme to axes
if nargin < 2, th = PStheme(); end
set(ax, 'Color', th.axesBg, 'XColor', th.axesFg, 'YColor', th.axesFg, ...
    'GridColor', th.gridColor, 'FontWeight', 'bold');
grid(ax, 'on');
end
