function x = PStrimWaitClick(fig, trimBtn, lvAx)
% Wait for one left-click on the log-viewer axes and return its x-position.
% Returns [] if the Trim box gets un-clicked (cancel) or the window closes (#21).
% A short pause loop replaces blocking ginput so the cancel click can break it.

  set(lvAx, 'ButtonDownFcn', @(src, ~) PStrimClick(src));
  setappdata(0, 'PStrimX', []);
  while isempty(getappdata(0, 'PStrimX'))
    if ~ishghandle(fig) || get(trimBtn, 'Value') == 0
      x = [];
      return
    end
    pause(0.02);
  end
  x = getappdata(0, 'PStrimX');
end
