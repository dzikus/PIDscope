%% PSdispSetupInfo 

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

    
if exist('fnameMaster','var') && ~isempty(fnameMaster)

if exist('PSdisp','var') && ishandle(PSdisp)
    figure(PSdisp);
else
    PSdisp=figure(5);
    screensz = get(0,'ScreenSize');
    set(PSdisp, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSdisp, 'WindowState', 'maximized'); catch, end
    set(PSdisp, 'NumberTitle', 'on');
    set(PSdisp, 'Name', ['PIDscope (' PsVersion ') -  Setup Info']);
    set(PSdisp,'color',bgcolor);
end

columnWidth = 55 * fontsz;

TooltipString_FileNumDispA=['List of files available. Click to view setup info for each'];
topDdW = 160/screensz(3); topCbW = 200/screensz(3);
tbOff = 40/screensz(4);  % toolbar offset
topBtnY = 1 - tbOff - rh - cpMv;
posInfo.FileNumDispA=[.22 topBtnY topDdW ddh];
posInfo.FileNumDispB=[.72 topBtnY topDdW ddh];
posInfo.checkboxDIFF=[.04 topBtnY topCbW rh];
  
if ~exist('setupInfoWidgets_init','var') || ~ishandle(guiHandlesInfo.FileNumDispA)
guiHandlesInfo.FileNumDispA = uicontrol(PSdisp,'Style','popupmenu','string',[fnameMaster],...
    'fontsize',fontsz, 'units','normalized','Position', [posInfo.FileNumDispA],'callback','@selection; PSdispSetupInfo;');
set(guiHandlesInfo.FileNumDispA, 'Value', 1);
if Nfiles > 1
    guiHandlesInfo.FileNumDispB = uicontrol(PSdisp,'Style','popupmenu','string',[fnameMaster],...
        'fontsize',fontsz, 'units','normalized','Position', [posInfo.FileNumDispB],'callback','@selection; PSdispSetupInfo;');
    set(guiHandlesInfo.FileNumDispB, 'Value', 2);
end

guiHandlesInfo.checkboxDIFF =uicontrol(PSdisp,'Style','checkbox','String','Show Differences Only','fontsize',fontsz,'TooltipString', [''],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkboxDIFF],'callback', 'PSdispSetupInfo;');
setupInfoWidgets_init = true;
end % ishandle widgets

% Register top bar for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', guiHandlesInfo.checkboxDIFF, 'type','cb', 'row',0, 'col',0, 'hpx',0, 'wpx',200);
cpI{end+1} = struct('h', guiHandlesInfo.FileNumDispA, 'type','dd', 'row',0, 'col',0, 'hpx',0, 'wpx',160);
if Nfiles > 1 && isfield(guiHandlesInfo, 'FileNumDispB') && ishandle(guiHandlesInfo.FileNumDispB)
    cpI{end+1} = struct('h', guiHandlesInfo.FileNumDispB, 'type','dd', 'row',0, 'col',0, 'hpx',0, 'wpx',160);
end
PSregisterResize(PSdisp, cpPx, cpI, 'topbar', 0.04);

else
     warndlg('Please select file(s)');
end
PSstyleControls(PSdisp);

% functions
function selection(src,event)
    val = c.Value;
    str = c.String;
    str{val};
   % disp(['Selection: ' str{val}]);
end