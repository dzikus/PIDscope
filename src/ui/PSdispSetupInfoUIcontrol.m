%% PSdispSetupInfo 

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

    
if exist('fnameMaster','var') && ~isempty(fnameMaster)

PSdisp=figure(5);
screensz = get(0,'ScreenSize');
set(PSdisp, 'Position', round([.1*screensz(3) .1*screensz(4) .75*screensz(3) .8*screensz(4)]));
set(PSdisp, 'NumberTitle', 'on');
set(PSdisp, 'Name', ['PIDscope (' PsVersion ') -  Setup Info']);
set(PSdisp,'color',bgcolor)

columnWidth=55*round(screensz_multiplier*prop_max_screen);

TooltipString_FileNumDispA=['List of files available. Click to view setup info for each']; 
posInfo.FileNumDispA=[.22 .95 .1 .04];
posInfo.FileNumDispB=[.72 .95 .1 .04];
posInfo.checkboxDIFF=[.04 .96 .1 .04];
  
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

else
     warndlg('Please select file(s)');
end

% functions
function selection(src,event)
    val = c.Value;
    str = c.String;
    str{val};
   % disp(['Selection: ' str{val}]);
end