%% PSsliderActions - script called when slider1 called

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

th = PStheme();
fileIdx = get(guiHandles.FileNum, 'Value');

% Get time range from visible axes (by Tag, not position)
motorAx = findobj(PSfig, 'Type', 'axes', 'Tag', 'PSmotor');
comboAx = findobj(PSfig, 'Type', 'axes', 'Tag', 'PScombo');
try
    if ~isempty(comboAx), a = xlim(comboAx(1));
    elseif ~isempty(motorAx), a = xlim(motorAx(1));
    else a = [0 tta{fileIdx}(end) / us2sec];
    end
catch
    a = [0 tta{fileIdx}(end) / us2sec];
end
adiff = a(2) - a(1);
x1 = a(1) + get(guiHandles.slider, 'Value') * adiff;

% Delete old cursor lines
try delete(hslider1); catch, end
try delete(hslider2); catch, end
try delete(hslider3); catch, end
try delete(hslider4); catch, end
try delete(hslider5); catch, end
hslider1=[]; hslider2=[]; hslider3=[]; hslider4=[]; hslider5=[];

lwVal = get(guiHandles.linewidth, 'Value') / 2;

% Draw cursor lines on TAGGED axes (never subplot — avoids position mismatch)
rpyAxes = findobj(PSfig, 'Type', 'axes', 'Tag', 'PSrpy');
if ~isempty(comboAx) && ishandle(comboAx(1))
    set(PSfig, 'CurrentAxes', comboAx(1)); hold on;
    hslider4 = plot([x1 x1], [-maxY maxY], '-', 'color', th.textPrimary, 'linewidth', lwVal);
else
    if numel(rpyAxes) > 1
        yy = zeros(numel(rpyAxes),1);
        for k=1:numel(rpyAxes), p=get(rpyAxes(k),'Position'); yy(k)=p(2); end
        [~,si] = sort(yy,'descend'); rpyAxes = rpyAxes(si);
    end
    for k = 1:min(3, numel(rpyAxes))
        set(PSfig, 'CurrentAxes', rpyAxes(k)); hold on;
        h = plot([x1 x1], [-maxY maxY], '-', 'color', th.textPrimary, 'linewidth', lwVal);
        if k==1, hslider1=h; elseif k==2, hslider2=h; else hslider3=h; end
    end
end
if ~isempty(motorAx) && ishandle(motorAx(1))
    set(PSfig, 'CurrentAxes', motorAx(1)); hold on;
    hslider5 = plot([x1 x1], [0 100], '-', 'color', th.textPrimary, 'linewidth', lwVal);
end

% Stick overlay — update persistent handles (created by PSviewerUIcontrol)
x2 = find(tta{fileIdx}/us2sec >= x1, 1);
if ~isempty(x2) && isfield(guiHandles, 'stickDotYT')
    T_f = T{fileIdx};

    if isfield(T_f, 'rcCommand_0_')
        rfMot = getappdata(PSfig, 'rfMotorCount');
        if ~isempty(rfMot)  % Rotorflight: collective is -500..500
            thrPct = (T_f.rcCommand_3_(x2) + 500) / 10;
        else
            thrPct = (T_f.rcCommand_3_(x2) - 1000) / 10;
        end
        try set(guiHandles.stickDotYT, 'XData', -T_f.rcCommand_2_(x2), ...
                'YData', thrPct); catch, end
        try set(guiHandles.stickDotRP, 'XData', T_f.rcCommand_0_(x2), ...
                'YData', T_f.rcCommand_1_(x2)); catch, end
    elseif isfield(T_f, 'setpoint_0_')
        try set(guiHandles.stickDotYT, 'XData', -T_f.setpoint_2_(x2), ...
                'YData', T_f.setpoint_3_(x2)); catch, end
        try set(guiHandles.stickDotRP, 'XData', T_f.setpoint_0_(x2), ...
                'YData', T_f.setpoint_1_(x2)); catch, end
    end

    set(guiHandles.overlayTime, 'String', sprintf('time: %.4f sec', tta{fileIdx}(x2)/us2sec));
    try set(guiHandles.overlayM1, 'String', sprintf('M1: %.0f%%', T_f.motor_0_(x2))); catch, end
    rfMot = getappdata(PSfig, 'rfMotorCount');
    if ~isempty(rfMot)
        si = 1;
        if rfMot >= 2
            try set(guiHandles.overlayM2, 'String', sprintf('M2: %.0f%%', T_f.motor_1_(x2))); catch, end
        else
            try set(guiHandles.overlayM2, 'String', sprintf('S%d: %.0f%%', si, T_f.motor_1_(x2))); catch, end
            si = si+1;
        end
        try set(guiHandles.overlayM3, 'String', sprintf('S%d: %.0f%%', si, T_f.motor_2_(x2))); catch, end
        si = si+1;
        try set(guiHandles.overlayM4, 'String', sprintf('S%d: %.0f%%', si, T_f.motor_3_(x2))); catch, end
    else
        try set(guiHandles.overlayM2, 'String', sprintf('M2: %.0f%%', T_f.motor_1_(x2))); catch, end
        try set(guiHandles.overlayM3, 'String', sprintf('M3: %.0f%%', T_f.motor_2_(x2))); catch, end
        try set(guiHandles.overlayM4, 'String', sprintf('M4: %.0f%%', T_f.motor_3_(x2))); catch, end
    end
    try set(guiHandles.overlayGR, 'String', sprintf('gyro R: %.0f deg/s', T_f.gyroADC_0_(x2))); catch, end
    try set(guiHandles.overlayGP, 'String', sprintf('gyro P: %.0f deg/s', T_f.gyroADC_1_(x2))); catch, end
    try set(guiHandles.overlayGY, 'String', sprintf('gyro Y: %.0f deg/s', T_f.gyroADC_2_(x2))); catch, end
end
