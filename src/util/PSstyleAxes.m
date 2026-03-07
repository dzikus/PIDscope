function PSstyleAxes(ax, th)
%% PSstyleAxes - apply dark theme to axes
if nargin < 2, th = PStheme(); end
if ~ishandle(ax), return; end
% skip colorbars - findobj('Type','axes') returns them in Octave
try tag = get(ax, 'Tag'); if strcmpi(tag, 'colorbar') || strcmpi(tag, 'Colorbar'), return; end; catch, end
set(ax, 'Color', th.axesBg, 'XColor', th.axesFg, 'YColor', th.axesFg, ...
    'GridColor', th.gridColor, 'FontWeight', 'bold');
try set(get(ax, 'Title'), 'Color', th.textPrimary); catch, end
try set(get(ax, 'XLabel'), 'Color', th.textPrimary); catch, end
try set(get(ax, 'YLabel'), 'Color', th.textPrimary); catch, end
try grid(ax, 'on'); catch, end
end
