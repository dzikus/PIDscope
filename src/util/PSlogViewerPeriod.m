function PSlogViewerPeriod(fig)
%% PSlogViewerPeriod - click two points on log viewer trace, show period + frequency

th = PStheme();

% clear previous markers
delete(findobj(fig, 'Tag', 'PSperiodLV'));

% find all visible LV axes (PSrpy, PSmotor, PScombo)
allAx = findobj(fig, 'Type', 'axes', 'Visible', 'on');
lvAx = [];
for ai = 1:numel(allAx)
    t = get(allAx(ai), 'Tag');
    if any(strcmp(t, {'PSrpy', 'PSmotor', 'PScombo'}))
        lvAx(end+1) = allAx(ai);
    end
end
if isempty(lvAx), return; end

set(fig, 'pointer', 'crosshair');

% first click
try ginput(1); catch, set(fig,'pointer','arrow'); return; end
figPt = get(fig, 'CurrentPoint');
ax = [];
for ai = 1:numel(lvAx)
    p = getpixelposition(lvAx(ai));
    if figPt(1) >= p(1) && figPt(1) <= p(1)+p(3) && figPt(2) >= p(2) && figPt(2) <= p(2)+p(4)
        ax = lvAx(ai); break;
    end
end
if isempty(ax), set(fig,'pointer','arrow'); return; end

xl = get(ax, 'XLim');
p = getpixelposition(ax);
x1 = xl(1) + (figPt(1) - p(1)) / p(3) * (xl(2) - xl(1));

% second click
try ginput(1); catch, set(fig,'pointer','arrow'); return; end
figPt = get(fig, 'CurrentPoint');
p = getpixelposition(ax);
x2 = xl(1) + (figPt(1) - p(1)) / p(3) * (xl(2) - xl(1));

set(fig, 'pointer', 'arrow');

x = sort([x1 x2]);
dt_sec = x(2) - x(1);
if dt_sec <= 0, return; end
dt_ms = dt_sec * 1000;
freq = 1 / dt_sec;

% draw on all LV axes
for ai = 1:numel(lvAx)
    yl_i = get(lvAx(ai), 'YLim');
    line(lvAx(ai), [x(1) x(1)], yl_i, 'Color', th.periodMarker, 'LineWidth', 1.5, 'Tag', 'PSperiodLV');
    line(lvAx(ai), [x(2) x(2)], yl_i, 'Color', th.periodMarker, 'LineWidth', 1.5, 'Tag', 'PSperiodLV');
end
yl = get(ax, 'YLim');
text(mean(x), yl(2)*0.93, sprintf('%.1fms, %.2fHz', dt_ms, freq), ...
    'Parent', ax, 'Color', th.textPrimary, 'FontSize', th.fontsz, ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Tag', 'PSperiodLV');

end
