%% PStrimSelect - set the trim window for the current file by clicking two points
% Other controls grey out during capture so a stray click can't re-enter a callback
% mid-ginput (#21); the Trim box stays live, so clicking it again cancels the phase.

if getappdata(0, 'PStrimming'), return; end   % ignore re-entry while already capturing

if ~(exist('filenameA','var') && ~isempty(filenameA) && get(guiHandles.startEndButton,'Value'))
    return;
end

fnum_ = get(guiHandles.FileNum, 'Value');

ctrls_ = findobj(PSfig, 'Type', 'uicontrol');
ctrls_ = ctrls_(ctrls_ ~= guiHandles.startEndButton);
styles_ = get(ctrls_, 'Style');
if ~iscell(styles_), styles_ = {styles_}; end
ctrls_ = ctrls_(~strcmp(styles_, 'text'));   % disabled static text greys to white in Qt
prevEnable_ = get(ctrls_, 'Enable');
if ~iscell(prevEnable_), prevEnable_ = {prevEnable_}; end
prevKey_ = get(PSfig, 'KeyPressFcn');

set(ctrls_, 'Enable', 'off');
setappdata(0, 'PStrimming', 1);

unwind_protect
    for click_ = 1:2
        lvAx_ = [];
        ax_ = findobj(PSfig, 'Type', 'axes');
        for ai_ = 1:numel(ax_)
            if any(strcmp(get(ax_(ai_), 'Tag'), {'PSrpy', 'PSmotor', 'PScombo'}))
                lvAx_(end+1) = ax_(ai_);
            end
        end
        if isempty(lvAx_), break; end

        set(PSfig, 'KeyPressFcn', '');   % stop 'i'/'o' from nesting another capture
        x_ = PStrimWaitClick(PSfig, guiHandles.startEndButton, lvAx_);
        if isempty(x_), break; end       % Trim un-clicked = cancel the phase

        if click_ == 1
            epoch1_A(fnum_) = round(x_*10)/10;
        else
            epoch2_A(fnum_) = round(x_*10)/10;
        end
        PSplotLogViewer;
    end
unwind_protect_cleanup
    setappdata(0, 'PStrimming', 0);
    for i_ = 1:numel(ctrls_)
        try set(ctrls_(i_), 'Enable', prevEnable_{i_}); catch, end
    end
    set(PSfig, 'KeyPressFcn', prevKey_);
    try PSdatatipSetup(PSfig); catch, end
end_unwind_protect
