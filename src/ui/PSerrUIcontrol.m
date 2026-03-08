%% PSerrUIcontrol - ui controls for PID error analyses

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------


if exist('fnameMaster','var') && ~isempty(fnameMaster)

if exist('PSerrfig','var') && ishandle(PSerrfig)
    figure(PSerrfig);
else
    PSerrfig=figure(7);
    set(PSerrfig, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSerrfig, 'WindowState', 'maximized'); catch, end
    set(PSerrfig, 'NumberTitle', 'off');
    set(PSerrfig, 'Name', ['PIDscope (' PsVersion ') - PID Error Tool']);
    set(PSerrfig, 'InvertHardcopy', 'off');
    set(PSerrfig,'color',bgcolor);
end

fontsz3 = fontsz;
maxDegsec=100;
updateErr=0;

TooltipString_degsec=['Sets the maximum rate used in the PID error analysis (distribution plots only).',...
    newline , 'E.g., the default means only data in which set point was <= 100deg/s is used.',...
    newline , 'This cutoff helps to reduce inclusion of data with inflated PID error as a result of snap maneuvers' ];

clear posInfo.PIDerrAnalysis
cols=[0.1 0.55];
rows=[0.63 0.36 0.09];
k=0;
for c=1:2
    for r=1:3
        k=k+1;
        posInfo.PIDerrAnalysis(k,:)=[cols(c) rows(r) 0.39 0.24];
    end
end

% Top bar layout — pixel-based sizes
topBtnW = 100/screensz(3); topBtnH = rh; topEdtW = 80/screensz(3);
topTxtW = 120/screensz(3); topBarL = 0.09;
tbOff = 40/screensz(4);  % toolbar offset
topBtnY = 1 - tbOff - rh - cpMv;
topX = topBarL + cpM;
posInfo.refresh2=    [topX topBtnY topBtnW topBtnH]; topX=topX+topBtnW+cpM;
posInfo.saveFig3=    [topX topBtnY topBtnW topBtnH]; topX=topX+topBtnW+cpM;
posInfo.maxStick=    [topX topBtnY topEdtW topBtnH]; topX=topX+topEdtW+cpM;
posInfo.maxSticktext=[topX topBtnY topTxtW topBtnH];
topPanelW = topX + topTxtW + cpM - topBarL;
topPanelH = 1 - tbOff - topBtnY + cpMv;

if ~exist('errCrtlpanel','var') || ~ishandle(errCrtlpanel)
errCrtlpanel = uipanel('Title','','FontSize',fontsz3,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[topBarL topBtnY-cpMv topPanelW topPanelH]);

guiHandlesPIDerr.refresh = uicontrol(PSerrfig,'string','Refresh','fontsize',fontsz3,'TooltipString','Refresh plots','units','normalized','Position',[posInfo.refresh2],...
    'callback','updateErr=1;PSplotPIDerror;');
set(guiHandlesPIDerr.refresh, 'ForegroundColor', colRun);

guiHandlesPIDerr.maxSticktext = uicontrol(PSerrfig,'style','text','string','max stick deg/s','fontsize',fontsz3,'TooltipString',[TooltipString_degsec],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.maxSticktext]);
guiHandlesPIDerr.maxStick = uicontrol(PSerrfig,'style','edit','string',[int2str(maxDegsec)],'fontsize',fontsz3,'TooltipString',[TooltipString_degsec],'units','normalized','Position',[posInfo.maxStick],...
     'callback','maxDegsec=str2double(get(guiHandlesPIDerr.maxStick, ''String'')); updateErr=1;PSplotPIDerror; ');

guiHandlesPIDerr.saveFig3 = uicontrol(PSerrfig,'string','Save Fig','fontsize',fontsz3,'TooltipString',[TooltipString_saveFig],'units','normalized','Position',[posInfo.saveFig3],...
    'callback','PSsaveFig;');
set(guiHandlesPIDerr.saveFig3, 'ForegroundColor', saveCol);
end % ishandle(errCrtlpanel)

% Register top bar for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', guiHandlesPIDerr.refresh, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',100);
cpI{end+1} = struct('h', guiHandlesPIDerr.saveFig3, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',100);
cpI{end+1} = struct('h', guiHandlesPIDerr.maxStick, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',80);
cpI{end+1} = struct('h', guiHandlesPIDerr.maxSticktext, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',120);
cpI{end+1} = struct('h', errCrtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0, 'wpx',0);
PSregisterResize(PSerrfig, cpPx, cpI, 'topbar', topBarL);

PSstyleControls(PSerrfig);

else
    errordlg('Please select file(s) then click ''load+run''', 'Error, no data');
    pause(2);
end
