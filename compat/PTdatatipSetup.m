function PTdatatipSetup(fig)
% PTdatatipSetup - Set up click-to-show-value on a figure
%
% In Octave: uses WindowButtonDownFcn + text annotation (replaces datacursormode)
% In MATLAB: uses datacursormode with @PTdatatip callback (original behavior)
%
% Usage: PTdatatipSetup(fig)
%   fig - figure handle

  if exist('OCTAVE_VERSION', 'builtin')
    set(fig, 'WindowButtonDownFcn', @(src, ~) PTdatatip_click(src));
  else
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'UpdateFcn', @PTdatatip);
  end
end
