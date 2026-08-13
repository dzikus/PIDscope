function PStrimClick(ax)
% Records the x-position of a left-click on a log-viewer axes.
% Armed by PStrimWaitClick only while a trim capture is running (#21).

  if ~strcmp(get(ancestor(ax, 'figure'), 'SelectionType'), 'normal')
    return
  end
  cp = get(ax, 'CurrentPoint');
  setappdata(0, 'PStrimX', cp(1,1));
end
