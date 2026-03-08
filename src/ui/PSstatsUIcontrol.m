%% PSplotStats - UI control for flight statistics

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    
if exist('fnameMaster','var') && ~isempty(fnameMaster)

if exist('PSstatsfig','var') && ishandle(PSstatsfig)
    figure(PSstatsfig);
else
    PSstatsfig=figure(6);
    set(PSstatsfig, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSstatsfig, 'WindowState', 'maximized'); catch, end
    set(PSstatsfig, 'NumberTitle', 'off');
    set(PSstatsfig, 'Name', ['PIDscope (' PsVersion ') - Flight stats']);
    set(PSstatsfig, 'InvertHardcopy', 'off');
    set(PSstatsfig,'color',bgcolor);
end

TooltipString_degsecStick=['Plots rate curve (Histograms Figs) in terms of degs per sec per stick-travel units, or how fast one''s rates change across stick travel '];
TooltipString_crossAxesStats=['Selects from several plotting options, from basic histograms of stick use per flight, to means',...
    newline 'and various between-axes representations.',... 
    newline ' ',...
    newline 'Histograms:',...
    newline 'Basic descriptive stats of the flight behavior.',...
    newline ' ',...
    newline 'Mean +/-SD:',...
    newline 'Bars represent the mean/average and lines represent the standard deviation (a measure of variability), ||=absolute value or unsigned average.',...
    newline 'Note: you can select out portions of the data to be examined if desired, by adjusting the selection window in the log viewer.',...
    newline ' ',...
    newline 'Topographic Mode1/2 plots:',...
    newline 'The plots show the topographic view (like looking down at your radio) of how the sticks were moved during the flight',...
    newline 'Line color represents throttle acceleration in red and deceleration in blue, with higher values more saturated.',...
    newline 'If throttle is neither accelerating nor decelerating the line color is white.',...
    newline 'Note: you can select out portions of the data to be examined if desired, by adjusting the selection window in the log viewer, and refreshing the Flight stats tool.',...
    newline ' ',...
    newline 'Axes x Throttle plots:',...
    newline 'Like the mode plots, line color represents throttle acceleration in red and deceleration in blue, with higher values more saturated.',...
    newline 'If throttle is neither accelerating nor decelerating the line color is white.',...
    newline 'The ''Mode and axes X throttle topography plots'' are useful for examining patterns in flight behavior,',...
    newline 'For example, flight behaviour associated with optimal lap times in a race, or the qualities or asymmetries in one''s flying style ',...
    newline 'Note: you can select out portions of the data to be examined if desired, by adjusting the selection window in the log viewer.'];
TooltipString_statScale=['For ''Mode and axes X throttle topography plots'':',...
    newline 'Scale: Z-axis (line color) scale, from 1 to infinity, with higher numbers yielding a wider scale,',...
    newline 'giving greater distinction between lines, where only the fastest movements (highest acceleration/deceleration) become visible.'];
TooltipString_statAlpha=['For ''Mode and axes X throttle topography plots'':',...
    newline 'Alpha: line transparency, from 0 (fully transparent) to 1 (not transparent)'];
updateStats=0;

zScale=1;
zTransparency=1;

fontsz5 = fontsz;

clear posInfo.statsPos
cols=[0.06 0.54];
rows=[0.69 0.48 0.27 0.06];
k=0;
for c=1:2
    for r=1:4
        k=k+1;
        posInfo.statsPos(k,:)=[cols(c) rows(r) 0.39 0.18];
    end
end

% Top bar layout — pixel-based sizes
topBtnW = 100/screensz(3); topBtnH = rh; topCbW = 150/screensz(3);
topDdW = 140/screensz(3); topEdtW = 50/screensz(3); topTxtW = 50/screensz(3);
topBarL = 0.065;
tbOff = 40/screensz(4);  % toolbar offset
topLblY = 1 - tbOff - rhs - cpMv;  topBtnY = topLblY - rhs - cpMv;
topX = topBarL + cpM;
posInfo.saveFig5=    [topX topBtnY topBtnW topBtnH]; topX=topX+topBtnW+cpM;
posInfo.refresh3=    [topX topBtnY topBtnW topBtnH]; topX=topX+topBtnW+cpM;
posInfo.degsecStick= [topX topBtnY topCbW topBtnH]; topX=topX+topCbW+cpM;
posInfo.crossAxesStats=[topX topBtnY topDdW topBtnH]; topX=topX+topDdW+cpM;
posInfo.crossAxesStats_text =  [topX topLblY topTxtW rhs];
posInfo.crossAxesStats_input = [topX topBtnY topEdtW topBtnH]; topX=topX+topEdtW+cpM;
posInfo.crossAxesStats_text2 =  [topX topLblY topTxtW rhs];
posInfo.crossAxesStats_input2 = [topX topBtnY topEdtW topBtnH]; topX=topX+topEdtW+cpM;
topDdW2 = 160/screensz(3);
posInfo.statsFileA = [topX topBtnY topDdW2 ddh]; topX=topX+topDdW2+cpM;
posInfo.statsFileB = [topX topBtnY topDdW2 ddh];
topPanelW = topX + topDdW2 + cpM - topBarL;

if ~exist('statsCrtlpanel','var') || ~ishandle(statsCrtlpanel)
statsCrtlpanel = uipanel('Title','','FontSize',fontsz5,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[topBarL topBtnY-cpMv topPanelW 1-tbOff-topBtnY+cpMv]);

guiHandlesStats.saveFig5 = uicontrol(PSstatsfig,'string','Save Fig','fontsize',fontsz5,'TooltipString',[TooltipString_saveFig],'units','normalized','Position',[posInfo.saveFig5],...
    'callback','PSsaveFig;');
set(guiHandlesStats.saveFig5, 'ForegroundColor', saveCol);

guiHandlesStats.refresh = uicontrol(PSstatsfig,'string','Refresh','fontsize',fontsz5,'TooltipString','Refresh plots','units','normalized','Position',[posInfo.refresh3],...
    'callback','updateStats=1;PSplotStats;');
set(guiHandlesStats.refresh, 'ForegroundColor', colRun);

guiHandlesStats.degsecStick =uicontrol(PSstatsfig,'Style','checkbox','String','rate of change','fontsize',fontsz5,'TooltipString',[TooltipString_degsecStick],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.degsecStick],'callback','PSplotStats;');
guiHandlesStats.crossAxesStats =uicontrol(PSstatsfig,'Style','popupmenu','String',{'Histograms'; 'Mean & Standard Deviation'; 'Mode 1 topography'; 'Mode 2 topography'; 'Axes X Throttle'},'fontsize',fontsz5,'TooltipString',[TooltipString_crossAxesStats],...
    'units','normalized','Position',[posInfo.crossAxesStats],'callback','PSplotStats;');
%guiHandlesStats.crossAxesStats.Value=0;

guiHandlesStats.crossAxesStats_text = uicontrol(PSstatsfig,'style','text','string','scale','fontsize',fontsz5,'TooltipString',[TooltipString_statScale],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.crossAxesStats_text]);
guiHandlesStats.crossAxesStats_input = uicontrol(PSstatsfig,'style','edit','string',[num2str(zScale)],'fontsize',fontsz5,'TooltipString',[TooltipString_statScale],'units','normalized','Position',[posInfo.crossAxesStats_input],...
     'callback','zScale=str2double(get(guiHandlesStats.crossAxesStats_input, ''String''));updateStats=1;PSplotStats;');
 
guiHandlesStats.crossAxesStats_text2 = uicontrol(PSstatsfig,'style','text','string','alpha','fontsize',fontsz5,'TooltipString',[TooltipString_statAlpha],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.crossAxesStats_text2]);
guiHandlesStats.crossAxesStats_input2 = uicontrol(PSstatsfig,'style','edit','string',[num2str(zTransparency)],'fontsize',fontsz5,'TooltipString',[TooltipString_statAlpha],'units','normalized','Position',[posInfo.crossAxesStats_input2],...
     'callback','zTransparency=str2double(get(guiHandlesStats.crossAxesStats_input2, ''String'')); if (zTransparency>1), zTransparency=1; end; if (zTransparency<0), zTransparency=0; end; updateStats=1;PSplotStats;');

guiHandlesStats.FileA = uicontrol(PSstatsfig,'Style','popupmenu','string',[fnameMaster],...
    'fontsize',fontsz5,'TooltipString','File A (red)','units','normalized','Position',[posInfo.statsFileA],...
    'callback','updateStats=0;PSplotStats;');
set(guiHandlesStats.FileA, 'Value', 1);
if Nfiles > 1
    guiHandlesStats.FileB = uicontrol(PSstatsfig,'Style','popupmenu','string',[fnameMaster],...
        'fontsize',fontsz5,'TooltipString','File B (blue)','units','normalized','Position',[posInfo.statsFileB],...
        'callback','updateStats=0;PSplotStats;');
    set(guiHandlesStats.FileB, 'Value', min(2, Nfiles));
end
end % ishandle(statsCrtlpanel)

% Register top bar for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', guiHandlesStats.saveFig5, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',100);
cpI{end+1} = struct('h', guiHandlesStats.refresh, 'type','btn', 'row',0, 'col',0, 'hpx',0, 'wpx',100);
cpI{end+1} = struct('h', guiHandlesStats.degsecStick, 'type','cb', 'row',0, 'col',0, 'hpx',0, 'wpx',150);
cpI{end+1} = struct('h', guiHandlesStats.crossAxesStats, 'type','dd', 'row',0, 'col',0, 'hpx',0, 'wpx',140);
cpI{end+1} = struct('h', guiHandlesStats.crossAxesStats_text, 'type','lbl', 'row',0, 'col',0, 'hpx',0, 'wpx',50);
cpI{end+1} = struct('h', guiHandlesStats.crossAxesStats_input, 'type','input', 'row',0, 'col',0, 'hpx',0, 'wpx',50);
cpI{end+1} = struct('h', guiHandlesStats.crossAxesStats_text2, 'type','lbl', 'row',0, 'col',0, 'hpx',0, 'wpx',50);
cpI{end+1} = struct('h', guiHandlesStats.crossAxesStats_input2, 'type','input', 'row',0, 'col',0, 'hpx',0, 'wpx',50);
cpI{end+1} = struct('h', guiHandlesStats.FileA, 'type','dd', 'row',0, 'col',0, 'hpx',0, 'wpx',160);
if Nfiles > 1 && isfield(guiHandlesStats, 'FileB') && ishandle(guiHandlesStats.FileB)
    cpI{end+1} = struct('h', guiHandlesStats.FileB, 'type','dd', 'row',0, 'col',0, 'hpx',0, 'wpx',160);
end
cpI{end+1} = struct('h', statsCrtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0, 'wpx',0);
PSregisterResize(PSstatsfig, cpPx, cpI, 'topbar', topBarL);

PSstyleControls(PSstatsfig);

else
    errordlg('Please select file(s) then click ''load+run''', 'Error, no data');
    pause(2);
end