function PSdatatip_click(ax)
% PSdatatip_click - Octave replacement for datacursormode click handler
%
% Called by axes ButtonDownFcn set up by PSdatatipSetup.
% On left-click: finds nearest data (line point or image pixel),
% shows formatted text annotation. On right-click: removes annotation.
%
% ax - axes handle (from ButtonDownFcn callback)

  global logviewerYscale

  fig = ancestor(ax, 'figure');

  % Right-click = remove annotation
  if strcmp(get(fig, 'SelectionType'), 'alt')
    delete(findobj(ax, 'Tag', 'PSdatatip'));
    return
  end

  % Only handle normal left-click
  if ~strcmp(get(fig, 'SelectionType'), 'normal')
    return
  end

  cp = get(ax, 'CurrentPoint');
  x = cp(1,1);
  y = cp(1,2);

  % Check if click is within axes limits
  xl = get(ax, 'XLim');
  yl = get(ax, 'YLim');
  if x < xl(1) || x > xl(2) || y < yl(1) || y > yl(2)
    return
  end

  % Remove previous annotation in this axes
  delete(findobj(ax, 'Tag', 'PSdatatip'));

  % Find what was clicked - scan axes children
  children = get(ax, 'Children');
  obj_type = '';
  img_obj = [];
  best_line = [];
  best_dist = inf;
  best_idx = 0;

  for i = 1:length(children)
    ch = children(i);
    t = get(ch, 'Type');
    if strcmp(t, 'image')
      obj_type = 'image';
      img_obj = ch;
      break  % image takes priority (heatmap background)
    elseif strcmp(t, 'line')
      % Check if line has visible data
      xd = get(ch, 'XData');
      yd = get(ch, 'YData');
      if isempty(xd) || length(xd) < 2, continue; end
      vis = get(ch, 'Visible');
      if strcmp(vis, 'off'), continue; end

      % Normalized distance to find nearest point
      xr = xl(2) - xl(1);
      yr = yl(2) - yl(1);
      if xr == 0 || yr == 0, continue; end
      dx = (xd - x) / xr;
      dy = (yd - y) / yr;
      dist = dx.^2 + dy.^2;
      [md, mi] = min(dist);
      if md < best_dist
        best_dist = md;
        best_line = ch;
        best_idx = mi;
      end
    end
  end

  % If no image found, check if we found a nearby line
  if isempty(obj_type) && ~isempty(best_line) && best_dist < 0.01
    obj_type = 'line';
  end

  if isempty(obj_type), return; end

  % Format output text and annotation position
  fontsz = 12;
  txt = {};
  ann_x = x;
  ann_y = y;

  if strcmp(obj_type, 'image')
    % --- Image (heatmap / spectrogram) ---
    cdata = get(img_obj, 'CData');
    xdata = get(img_obj, 'XData');
    ydata = get(img_obj, 'YData');
    [nr, nc] = size(cdata);

    % Map click position to pixel indices
    if length(xdata) == 2
      % imagesc(xrange, yrange, C) format
      col = round(1 + (x - xdata(1)) / (xdata(2) - xdata(1)) * (nc - 1));
      row = round(1 + (y - ydata(1)) / (ydata(2) - ydata(1)) * (nr - 1));
    else
      % imagesc(C) format - xdata/ydata are [1 nc] and [1 nr]
      col = round(x);
      row = round(y);
    end

    % Clamp to valid range
    col = max(1, min(nc, col));
    row = max(1, min(nr, row));
    z = cdata(row, col);

    % Convert axes coords to real-world values using tick labels
    real_x = tick_to_value(ax, 'X', x);
    real_y = tick_to_value(ax, 'Y', y);

    if ~isnan(real_x) && ~isnan(real_y)
      % Determine axis labels for context
      xlabel_str = get(get(ax, 'XLabel'), 'String');
      ylabel_str = get(get(ax, 'YLabel'), 'String');

      x_prefix = 'X';
      y_prefix = 'Y';
      if ~isempty(xlabel_str)
        if ~isempty(strfind(lower(xlabel_str), 'time'))
          x_prefix = 'sec';
        elseif ~isempty(strfind(lower(xlabel_str), 'throttle')) || ~isempty(strfind(xlabel_str, '%T'))
          x_prefix = '%T';
        end
      end
      if ~isempty(ylabel_str)
        if ~isempty(strfind(lower(ylabel_str), 'freq'))
          y_prefix = 'Hz';
        end
      end

      txt = {[x_prefix ': ' num2str(real_x, 4)], ...
             [y_prefix ': ' num2str(real_y, 4)], ...
             ['Z: ' num2str(z, 4)]};
    else
      txt = {['X: ' num2str(x, 4)], ...
             ['Y: ' num2str(y, 4)], ...
             ['Z: ' num2str(z, 4)]};
    end

  else
    % --- Line plot ---
    xd = get(best_line, 'XData');
    yd = get(best_line, 'YData');
    px = xd(best_idx);
    py = yd(best_idx);
    ann_x = px;
    ann_y = py;

    % Log Viewer percentage mode (uses logviewerYscale global)
    if ~isempty(logviewerYscale) && isnumeric(logviewerYscale) && logviewerYscale > 0
      if py <= -logviewerYscale
        pct = (py + logviewerYscale * 2) / (logviewerYscale / 100);
        if px < 100, dgts = 5; else dgts = 6; end
        txt = {['sec: ' num2str(px, dgts)], ...
               ['%: ' num2str(pct, 4)]};
      else
        if px < 100, dgts = 5; else dgts = 6; end
        txt = {['x: ' num2str(px, dgts)], ...
               ['y: ' num2str(py, 4)]};
      end
    else
      if px < 100, dgts = 5; else dgts = 6; end
      txt = {['x: ' num2str(px, dgts)], ...
             ['y: ' num2str(py, 4)]};
    end
  end

  if isempty(txt), return; end

  % Show annotation
  text(ann_x, ann_y, txt, 'Parent', ax, 'Tag', 'PSdatatip', ...
       'BackgroundColor', [1 1 0.88], 'EdgeColor', [0.3 0.3 0.3], ...
       'FontSize', fontsz, 'FontWeight', 'bold', ...
       'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
       'Margin', 4, 'Clipping', 'on');
end


function val = tick_to_value(ax, axis_char, pos)
% Convert axes pixel coordinate to real-world value using tick labels
%
% Interpolates between tick positions and their numeric labels.
% Returns NaN if interpolation not possible.

  ticks = get(ax, [axis_char 'Tick']);
  labels = get(ax, [axis_char 'TickLabel']);

  if isempty(ticks) || isempty(labels)
    val = NaN;
    return
  end

  % Convert labels to numbers
  if iscell(labels)
    nums = cellfun(@str2double, labels);
  else
    nums = str2double(cellstr(labels));
  end

  % Remove NaN entries (non-numeric labels)
  valid = ~isnan(nums);
  if sum(valid) < 2
    val = NaN;
    return
  end

  ticks_v = ticks(valid);
  nums_v = nums(valid);

  % Interpolate
  val = interp1(ticks_v, nums_v, pos, 'linear', 'extrap');
end
