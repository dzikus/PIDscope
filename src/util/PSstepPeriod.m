function PSstepPeriod(fig)
%% PSstepPeriod - click two points on step response trace, show period + frequency

th = PStheme();

% clear previous period markers
delete(findobj(fig, 'Tag', 'PSperiod'));

allAx = findobj(fig, 'Type', 'axes', 'Visible', 'on');
if isempty(allAx), return; end

% first click - determines target axes
try ginput(1); catch, return; end
figPt = get(fig, 'CurrentPoint');
ax = [];
for ai = 1:numel(allAx)
    p = getpixelposition(allAx(ai));
    if figPt(1) >= p(1) && figPt(1) <= p(1)+p(3) && figPt(2) >= p(2) && figPt(2) <= p(2)+p(4)
        ax = allAx(ai); break;
    end
end
if isempty(ax), return; end

xl = get(ax, 'XLim');
x1 = xl(1) + (figPt(1) - p(1)) / p(3) * (xl(2) - xl(1));

% second click
try ginput(1); catch, return; end
figPt = get(fig, 'CurrentPoint');
p = getpixelposition(ax);
x2 = xl(1) + (figPt(1) - p(1)) / p(3) * (xl(2) - xl(1));

x = sort([x1 x2]);
dt = x(2) - x(1);
freq = 1000 / dt;

% draw on all step trace axes (XLim > 100ms excludes scatter plots)
stepAxes = [];
for ai = 1:numel(allAx)
    xl_chk = get(allAx(ai), 'XLim');
    if xl_chk(2) > 100, stepAxes(end+1) = allAx(ai); end
end
if isempty(stepAxes), stepAxes = ax; end
for ai = 1:numel(stepAxes)
    yl_i = get(stepAxes(ai), 'YLim');
    line(stepAxes(ai), [x(1) x(1)], yl_i, 'Color', th.periodMarker, 'LineWidth', 1.5, 'Tag', 'PSperiod');
    line(stepAxes(ai), [x(2) x(2)], yl_i, 'Color', th.periodMarker, 'LineWidth', 1.5, 'Tag', 'PSperiod');
end
yl = get(ax, 'YLim');
text(mean(x), yl(2)*0.93, sprintf('%.0fms, %.4fHz', dt, freq), ...
    'Parent', ax, 'Color', th.textPrimary, 'FontSize', th.fontsz, ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Tag', 'PSperiod');

end
