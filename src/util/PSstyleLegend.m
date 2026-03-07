function PSstyleLegend(lg, th)
%% PSstyleLegend - apply dark theme to legend
if nargin < 2, th = PStheme(); end
set(lg, 'TextColor', th.legendFg, 'Color', th.legendBg, 'EdgeColor', th.legendEdge);
end
