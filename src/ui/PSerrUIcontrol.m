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
    set(PSerrfig, 'Position', round([.1*screensz(3) .1*screensz(4) .75*screensz(3) .8*screensz(4)]));
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
rows=[0.66 0.38 0.1];
k=0;
for c=1:2
    for r=1:3
        k=k+1;
        posInfo.PIDerrAnalysis(k,:)=[cols(c) rows(r) 0.39 0.24];
    end
end

posInfo.refresh2=[.09 .94 .06 .04];
posInfo.saveFig3=[.16 .94 .06 .04];

posInfo.maxSticktext=[.23 .966 .12 .03];
posInfo.maxStick=[.26 .94 .06 .03];

if ~exist('errCrtlpanel','var') || ~ishandle(errCrtlpanel)
errCrtlpanel = uipanel('Title','','FontSize',fontsz3,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[.085 .93 .28 .06]);

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

PSstyleControls(PSerrfig);

else
    errordlg('Please select file(s) then click ''load+run''', 'Error, no data');
    pause(2);
end
