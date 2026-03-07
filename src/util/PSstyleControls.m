function PSstyleControls(fig, th)
%% PSstyleControls - apply dark theme to all uicontrols on figure
if nargin < 2, th = PStheme(); end
controls = findobj(fig, 'Type', 'uicontrol');
for i = 1:numel(controls)
    style = get(controls(i), 'Style');
    if strcmp(style, 'pushbutton'), continue; end
    fg = get(controls(i), 'ForegroundColor');
    % fix controls still at default black [0 0 0]
    if all(abs(fg) < 0.01)
        set(controls(i), 'ForegroundColor', th.textPrimary);
    end
    if strcmp(style, 'edit')
        set(controls(i), 'BackgroundColor', th.inputBg, 'ForegroundColor', th.inputFg);
    end
    if strcmp(style, 'popupmenu') || strcmp(style, 'listbox')
        try set(controls(i), 'BackgroundColor', th.inputBg, 'ForegroundColor', th.inputFg); catch, end
    end
end
end
