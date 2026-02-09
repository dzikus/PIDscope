%% PTtimeFreqUIcontrol - ui controls for spectral analyses plots

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    
if exist('fnameMaster','var') && ~isempty(fnameMaster)
   
%%% tooltips
TooltipString_specRun=['Run current spectral configuration'];
TooltipString_cmap=['Choose from a selection of colormaps'];
TooltipString_smooth=['Choose amount of smoothing along the freq axis'];
TooltipString_subsampling=['Choose amount of smoothing along the time axis'];
TooltipString_user=['Choose the variable you wish to plot'];
TooltipString_sub100=['Zoom data to show sub 100Hz details',...
    newline, 'Typically used to see propwash or mid-throttle vibration in e.g. Gyro/Pterm/PIDerror'];


%%%
clear posInfo.Spec3Pos
cols=[0.09 ];
rows=[0.69 0.395 0.1];
k=0;
for c=1 : size(cols,2)
    for r=1 : size(rows,2)
        k=k+1; 
        posInfo.Spec3Pos(k,:)=[cols(c) rows(r) 0.77 0.255];
    end
end

if exist('isOctave','var') && isOctave
    posInfo.Spec3Pos(:,3) = 0.74;
end

updateSpec = 0;
clear specMat

% Control panel layout (consistent with Log Viewer cpL/cpW)
cpL = .875; cpW = .12;

posInfo.fileListWindowSpec=  [cpL+.003 .86 cpW-.006 .03];
posInfo.TermListWindowSpec=  [cpL+.003 .83 cpW-.006 .03];

posInfo.computeSpec3=        [cpL+.006 .795 cpW/2-.006 .026];
posInfo.resetSpec3=          [cpL+cpW/2 .795 cpW/2-.006 .026];
posInfo.saveFig3=            [cpL+.006 .765 cpW/2-.006 .026];
posInfo.saveSettings3=       [cpL+cpW/2 .765 cpW/2-.006 .026];
posInfo.smooth_select3 =     [cpL+.003 .735 cpW-.006 .026];
posInfo.subsampling_select3= [cpL+.003 .705 cpW-.006 .026];
posInfo.ColormapSelect2 =    [cpL+.003 .675 cpW-.006 .026];

posInfo.clim3Max1_text =     [cpL+.003 .65 cpW/4 .024];
posInfo.clim3Max1_input =    [cpL+cpW/4 .625 cpW/4 .024];
posInfo.clim3Max2_text =     [cpL+cpW/2 .65 cpW/4 .024];
posInfo.clim3Max2_input =    [cpL+3*cpW/4 .625 cpW/4 .024];
ClimScale3 = [-30 10];

posInfo.sub100HzfreqTime  =  [cpL+.003 .60 cpW-.006 .024];

PTspecfig3=figure(31);
set(PTspecfig3, 'Position', round([.1*screensz(3) .1*screensz(4) .75*screensz(3) .8*screensz(4)]));
set(PTspecfig3, 'NumberTitle', 'off');
set(PTspecfig3, 'Name', ['PIDscope (' PtbVersion ') - Frequency x Time Spectrogram']);
set(PTspecfig3, 'InvertHardcopy', 'off');
set(PTspecfig3,'color',bgcolor);


try  % datacursormode not available in Octave
  dcm_obj2 = datacursormode(PTspecfig3);
  set(dcm_obj2,'UpdateFcn',@PTdatatip);
end

Spec3Crtlpanel = uipanel('Title','select file ','FontSize',fontsz,...
              'BackgroundColor',[.95 .95 .95],...
              'Position',[cpL .59 cpW .31]);
 
guiHandlesSpec3.computeSpec = uicontrol(PTspecfig3,'string','Run','fontsize',fontsz,'TooltipString', [TooltipString_specRun],'units','normalized','Position',[posInfo.computeSpec3],...
    'callback','updateSpec = 0; clear specMat; PTfreqTime;');
set(guiHandlesSpec3.computeSpec, 'ForegroundColor', colRun);

guiHandlesSpec3.resetSpec = uicontrol(PTspecfig3,'string','Reset','fontsize',fontsz,'TooltipString', ['Reset Spectral Tool'],'units','normalized','Position',[posInfo.resetSpec3],...
    'callback','updateSpec = 0; clear specMat; for k = 1 : 3, delete(subplot(''position'',posInfo.Spec3Pos(k,:))), end; set(PTspecfig3, ''pointer'', ''arrow'');');
set(guiHandlesSpec3.resetSpec, 'ForegroundColor', cautionCol);

guiHandlesSpec3.saveFig3 = uicontrol(PTspecfig3,'string','Save Fig','fontsize',fontsz,'TooltipString',[TooltipString_saveFig],'units','normalized','ForegroundColor',[saveCol],'Position',[posInfo.saveFig3],...
    'callback','set(guiHandlesSpec3.saveFig3, ''FontWeight'', ''bold'');PTsaveFig;set(guiHandlesSpec3.saveFig3, ''FontWeight'', ''normal'');'); 

guiHandlesSpec3.saveSettings3 = uicontrol(PTspecfig3,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PTB defaults' ], 'units','normalized','Position',[posInfo.saveSettings3],...
    'callback','set(guiHandlesSpec3.saveSettings3, ''FontWeight'', ''bold'');PTsaveSettings; set(guiHandlesSpec3.saveSettings3, ''FontWeight'', ''normal'');');
set(guiHandlesSpec3.saveSettings3, 'ForegroundColor', saveCol);

% create string list for SpecSelect
sA={'Gyro','Gyro prefilt','Dterm','Dterm prefilt','Pterm','PID error','Set point','PIDsum'};

guiHandlesSpec3.SpecList = uicontrol(PTspecfig3,'Style','popupmenu','string',[sA], 'fontsize',fontsz, 'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.TermListWindowSpec]);
 
guiHandlesSpec3.FileSelect = uicontrol(PTspecfig3,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fileListWindowSpec]);
set(guiHandlesSpec3.FileSelect, 'Value', 1);

guiHandlesSpec3.smoothFactor_select = uicontrol(PTspecfig3,'style','popupmenu','string',{'smooth freq axis off' 'smooth freq axis low' 'smooth freq axis med' 'smooth freq axis high'},'fontsize',fontsz,'TooltipString', [TooltipString_smooth], 'units','normalized','Position',[posInfo.smooth_select3],...
     'callback','PTfreqTime;');
set(guiHandlesSpec3.smoothFactor_select, 'Value', 2);

guiHandlesSpec3.subsampleFactor_select = uicontrol(PTspecfig3,'style','popupmenu','string',{'smooth time axis off' 'smooth time axis low' 'smooth time axis med' 'smooth time axis high'},'fontsize',fontsz,'TooltipString', [TooltipString_subsampling], 'units','normalized','Position',[posInfo.subsampling_select3],...
     'callback','PTfreqTime;');
set(guiHandlesSpec3.subsampleFactor_select, 'Value', 2);

 guiHandlesSpec3.ColormapSelect = uicontrol(PTspecfig3,'Style','popupmenu','string',{'viridis','jet','hot','cool','gray','bone','copper','linear-RED','linear-GREY'},...
    'fontsize',fontsz,'TooltipString', [TooltipString_cmap], 'units','normalized','Position',[posInfo.ColormapSelect2],'callback','@selection2;updateSpec=1; PTfreqTime;');

guiHandlesSpec3.climMax1_text = uicontrol(PTspecfig3,'style','text','string','Z min','fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.clim3Max1_text]);
guiHandlesSpec3.climMax1_input = uicontrol(PTspecfig3,'style','edit','string',[num2str(ClimScale3(1))],'fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','Position',[posInfo.clim3Max1_input],...
     'callback','@textinput_call2; ClimScale3(1)=str2num(get(guiHandlesSpec3.climMax1_input, ''String''));updateSpec=1;PTfreqTime;');

 guiHandlesSpec3.climMax2_text = uicontrol(PTspecfig3,'style','text','string','Z max','fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.clim3Max2_text]);
guiHandlesSpec3.climMax2_input = uicontrol(PTspecfig3,'style','edit','string',[num2str(ClimScale3(2))],'fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','Position',[posInfo.clim3Max2_input],...
     'callback','@textinput_call2; ClimScale3(2)=str2num(get(guiHandlesSpec3.climMax2_input, ''String''));updateSpec=1;PTfreqTime;');

 guiHandlesSpec3.sub100HzfreqTime = uicontrol(PTspecfig3,'Style','checkbox','String','sub 100Hz','fontsize',fontsz,'ForegroundColor',[.2 .2 .2],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.sub100HzfreqTime],'callback','@selection2;updateSpec=1; PTfreqTime;');
 

try set(guiHandlesSpec3.SpecList, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-Preset')))), catch, set(guiHandlesSpec3.SpecList, 'Value', 1), end
try set(guiHandlesSpec3.smoothFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-FreqSmoothing')))), catch, set(guiHandlesSpec3.smoothFactor_select, 'Value', 2), end
try set(guiHandlesSpec3.subsampleFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-TimeSmoothing')))), catch, set(guiHandlesSpec3.subsampleFactor_select, 'Value', 2), end
try set(guiHandlesSpec3.ColormapSelect, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-Colormap')))), catch, set(guiHandlesSpec3.ColormapSelect, 'Value', 3), end


else
     warndlg('Please select file(s)');
end


% functions
function selection2(src,event)
    val = c.Value;
    str = c.String;
    str{val};
end
 
function getList2(hObj,event)
v=get(hObj,'value')
end

function textinput_call2(src,eventdata)
str=get(src,'String');
    if isempty(str2num(str))
        set(src,'string','0');
        warndlg('Input must be numerical');  
    end
end





