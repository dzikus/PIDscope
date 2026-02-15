function PSdatatipSetup(h)
% PSdatatipSetup - Set up click-to-show-value on axes (Octave) or figure (MATLAB)
%
% In Octave: sets ButtonDownFcn on each axes + HitTest='off' on children
% In MATLAB: uses datacursormode with @PSdatatip callback (original behavior)
%
% Usage:
%   PSdatatipSetup(fig)  - find all axes in figure and set up each (Octave)
%                        - set datacursormode (MATLAB)
%   PSdatatipSetup(ax)   - set up single axes (Octave only)
%
% Call this AFTER plots are created (in plotting functions, not UI setup).

  if ~exist('OCTAVE_VERSION', 'builtin')
    % MATLAB: datacursormode on figure (only if figure handle)
    if strcmp(get(h, 'Type'), 'figure')
      dcm_obj = datacursormode(h);
      set(dcm_obj, 'UpdateFcn', @PSdatatip);
    end
    return
  end

  % Octave: axes-level ButtonDownFcn
  t = get(h, 'Type');
  if strcmp(t, 'figure')
    % Find all axes in figure and set up each
    allax = findobj(h, 'Type', 'axes');
    for k = 1:length(allax)
      setup_axes(allax(k));
    end
  elseif strcmp(t, 'axes')
    setup_axes(h);
  end
end


function setup_axes(ax)
  set(ax, 'ButtonDownFcn', @(src, ~) PSdatatip_click(src));
  % Make children pass clicks through to axes ButtonDownFcn
  ch = get(ax, 'Children');
  for k = 1:length(ch)
    try
      set(ch(k), 'HitTest', 'off');
    catch
    end
  end
end
