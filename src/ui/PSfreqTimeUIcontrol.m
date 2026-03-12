%% PStimeFreqUIcontrol - ui controls for spectral analyses plots

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
plotR = cpL - 0.10;  plotL1 = 0.09;
colW1 = plotR - plotL1;
cols=[plotL1];
rows=[0.69 0.395 0.1];
k=0;
for c=1 : size(cols,2)
    for r=1 : size(rows,2)
        k=k+1;
        posInfo.Spec3Pos(k,:)=[cols(c) rows(r) colW1 0.255];
    end
end

updateSpec = 0;
clear specMat

% Control panel layout — cpL/cpW/rh/rs/ddh/cpM inherited from PIDscope.m (pixel-based)
% yTop tracks where TOP of next element goes; Position Y = yTop - height
gap = rs - rh;  fw = cpW-2*cpM;  hw = cpW/2-cpM;
tbOff_s3 = 40/screensz(4);
yTop = 1 - tbOff_s3 - cpTitleH - cpMv;
posInfo.fileListWindowSpec=  [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.TermListWindowSpec=  [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.computeSpec3=        [cpL+cpM yTop-rh hw rh];
posInfo.resetSpec3=          [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.saveFig3=            [cpL+cpM yTop-rh hw rh];
posInfo.saveSettings3=       [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.smooth_select3 =     [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.subsampling_select3= [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.ColormapSelect2 =    [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.clim3Max1_text =     [cpL+cpM yTop-rhs cpW/4 rhs];
posInfo.clim3Max2_text =     [cpL+cpW/2 yTop-rhs cpW/4 rhs]; yTop=yTop-rhs-gap;
posInfo.clim3Max1_input =    [cpL+cpM yTop-rh cpW/4 rh];
posInfo.clim3Max2_input =    [cpL+cpW/2 yTop-rh cpW/4 rh]; yTop=yTop-rh-gap;
ClimScale3 = [-30 10];
posInfo.sub100HzfreqTime  =  [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
% RPM overlay controls
qw = fw/4;
posInfo.rpmMotor1 =          [cpL+cpM       yTop-rh qw rh];
posInfo.rpmMotor2 =          [cpL+cpM+qw    yTop-rh qw rh];
posInfo.rpmMotor3 =          [cpL+cpM+2*qw  yTop-rh qw rh];
posInfo.rpmMotor4 =          [cpL+cpM+3*qw  yTop-rh qw rh]; yTop=yTop-rh-gap;
posInfo.rpmHarmDd =          [cpL+cpM yTop-ddh hw ddh];
posInfo.rpmLwDd   =          [cpL+cpW/2 yTop-ddh hw ddh]; yTop=yTop-ddh-gap;
posInfo.rpmDynNotch =        [cpL+cpM yTop-rh hw rh];
posInfo.rpmEstChk =          [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.playerBtn3        =  [cpL+cpM yTop-rh fw rh];

if exist('PSspecfig3','var') && ishandle(PSspecfig3)
    figure(PSspecfig3);
else
    PSspecfig3=figure(31);
    set(PSspecfig3, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSspecfig3, 'WindowState', 'maximized'); catch, end
    set(PSspecfig3, 'NumberTitle', 'off');
    set(PSspecfig3, 'Name', ['PIDscope (' PsVersion ') - Frequency x Time Spectrogram']);
    set(PSspecfig3, 'InvertHardcopy', 'off');
    set(PSspecfig3,'color',bgcolor);
end


try  % datacursormode not available in Octave
  dcm_obj2 = datacursormode(PSspecfig3);
  set(dcm_obj2,'UpdateFcn',@PSdatatip);
end

if ~exist('Spec3Crtlpanel','var') || ~ishandle(Spec3Crtlpanel)
Spec3Crtlpanel = uipanel('Title','select file ','FontSize',fontsz,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[cpL yTop-rh-gap cpW vPos-(yTop-rh-gap)+cpTitleH]);

guiHandlesSpec3.computeSpec = uicontrol(PSspecfig3,'string','Run','fontsize',fontsz,'TooltipString', [TooltipString_specRun],'units','normalized','Position',[posInfo.computeSpec3],...
    'callback','updateSpec = 0; clear specMat; PSfreqTime;');
set(guiHandlesSpec3.computeSpec, 'ForegroundColor', colRun);

guiHandlesSpec3.resetSpec = uicontrol(PSspecfig3,'string','Reset','fontsize',fontsz,'TooltipString', ['Reset Spectral Tool'],'units','normalized','Position',[posInfo.resetSpec3],...
    'callback','updateSpec = 0; clear specMat; delete(findobj(PSspecfig3,''Type'',''axes'')); set(PSspecfig3, ''pointer'', ''arrow'');');
set(guiHandlesSpec3.resetSpec, 'ForegroundColor', cautionCol);

guiHandlesSpec3.saveFig3 = uicontrol(PSspecfig3,'string','Save Fig','fontsize',fontsz,'TooltipString',[TooltipString_saveFig],'units','normalized','ForegroundColor',[saveCol],'Position',[posInfo.saveFig3],...
    'callback','set(guiHandlesSpec3.saveFig3, ''FontWeight'', ''bold'');PSsaveFig;set(guiHandlesSpec3.saveFig3, ''FontWeight'', ''normal'');'); 

guiHandlesSpec3.saveSettings3 = uicontrol(PSspecfig3,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PIDscope defaults' ], 'units','normalized','Position',[posInfo.saveSettings3],...
    'callback','set(guiHandlesSpec3.saveSettings3, ''FontWeight'', ''bold'');PSsaveSettings; set(guiHandlesSpec3.saveSettings3, ''FontWeight'', ''normal'');');
set(guiHandlesSpec3.saveSettings3, 'ForegroundColor', saveCol);

% create string list for SpecSelect
sA={'Gyro','Gyro prefilt','Dterm','Dterm prefilt','Pterm','PID error','Set point','PIDsum'};

guiHandlesSpec3.SpecList = uicontrol(PSspecfig3,'Style','popupmenu','string',[sA], 'fontsize',fontsz, 'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.TermListWindowSpec]);
 
guiHandlesSpec3.FileSelect = uicontrol(PSspecfig3,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fileListWindowSpec]);
set(guiHandlesSpec3.FileSelect, 'Value', 1);

guiHandlesSpec3.smoothFactor_select = uicontrol(PSspecfig3,'style','popupmenu','string',{'smooth freq axis off' 'smooth freq axis low' 'smooth freq axis med' 'smooth freq axis high'},'fontsize',fontsz,'TooltipString', [TooltipString_smooth], 'units','normalized','Position',[posInfo.smooth_select3],...
     'callback','PSfreqTime;');
set(guiHandlesSpec3.smoothFactor_select, 'Value', 2);

guiHandlesSpec3.subsampleFactor_select = uicontrol(PSspecfig3,'style','popupmenu','string',{'smooth time axis off' 'smooth time axis low' 'smooth time axis med' 'smooth time axis high'},'fontsize',fontsz,'TooltipString', [TooltipString_subsampling], 'units','normalized','Position',[posInfo.subsampling_select3],...
     'callback','PSfreqTime;');
set(guiHandlesSpec3.subsampleFactor_select, 'Value', 2);

 guiHandlesSpec3.ColormapSelect = uicontrol(PSspecfig3,'Style','popupmenu','string',{'viridis','jet','hot','cool','gray','bone','copper','linear-RED','linear-GREY'},...
    'fontsize',fontsz,'TooltipString', [TooltipString_cmap], 'units','normalized','Position',[posInfo.ColormapSelect2],'callback','@selection2;updateSpec=1; PSfreqTime;');

guiHandlesSpec3.climMax1_text = uicontrol(PSspecfig3,'style','text','string','Z min','fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.clim3Max1_text]);
guiHandlesSpec3.climMax1_input = uicontrol(PSspecfig3,'style','edit','string',[num2str(ClimScale3(1))],'fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','Position',[posInfo.clim3Max1_input],...
     'callback','@textinput_call2; ClimScale3(1)=str2double(get(guiHandlesSpec3.climMax1_input, ''String''));updateSpec=1;PSfreqTime;');

 guiHandlesSpec3.climMax2_text = uicontrol(PSspecfig3,'style','text','string','Z max','fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.clim3Max2_text]);
guiHandlesSpec3.climMax2_input = uicontrol(PSspecfig3,'style','edit','string',[num2str(ClimScale3(2))],'fontsize',fontsz,'TooltipString',['adjusts the color limits'],'units','normalized','Position',[posInfo.clim3Max2_input],...
     'callback','@textinput_call2; ClimScale3(2)=str2double(get(guiHandlesSpec3.climMax2_input, ''String''));updateSpec=1;PSfreqTime;');

 guiHandlesSpec3.sub100HzfreqTime = uicontrol(PSspecfig3,'Style','checkbox','String','sub 100Hz','fontsize',fontsz,'ForegroundColor',panelFg,'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.sub100HzfreqTime],'callback','@selection2;updateSpec=1; PSfreqTime;');

% RPM overlay motor checkboxes
motorCols = PStheme().sigMotor;
motorNames = {'M1','M2','M3','M4'};
rpmCb = 'updateSpec=1; PSfreqTime;';
for mi = 1:4
    fld = sprintf('rpmMotor%d', mi);
    guiHandlesSpec3.(fld) = uicontrol(PSspecfig3, 'Style','checkbox', 'String', motorNames{mi}, ...
        'fontsize', fontsz-1, 'Value', 0, ...
        'ForegroundColor', motorCols{mi}, 'BackgroundColor', bgcolor, ...
        'units','normalized', 'Position', posInfo.(fld), 'callback', rpmCb);
end

guiHandlesSpec3.rpmHarmDd = uicontrol(PSspecfig3, 'Style','popupmenu', ...
    'String', {'RPM off','1st','2nd','3rd','1st & 2nd','1st & 3rd','2nd & 3rd','All harm.'}, ...
    'fontsize', fontsz, 'Value', 2, ...
    'units','normalized', 'Position', posInfo.rpmHarmDd, 'callback', rpmCb);

guiHandlesSpec3.rpmLwDd = uicontrol(PSspecfig3, 'Style','popupmenu', ...
    'String', {'lw 0.5','lw 1','lw 1.5','lw 2'}, ...
    'fontsize', fontsz, 'Value', 2, ...
    'units','normalized', 'Position', posInfo.rpmLwDd, 'callback', rpmCb);

guiHandlesSpec3.rpmDynNotch = uicontrol(PSspecfig3, 'Style','checkbox', 'String','Dyn Notch', ...
    'fontsize', fontsz, 'Value', 0, ...
    'ForegroundColor', [0 .8 .8], 'BackgroundColor', bgcolor, ...
    'units','normalized', 'Position', posInfo.rpmDynNotch, 'callback', rpmCb);

guiHandlesSpec3.rpmEstChk = uicontrol(PSspecfig3, 'Style','checkbox', 'String','RPM est.', ...
    'fontsize', fontsz, 'Value', 0, ...
    'ForegroundColor', [.6 .9 .6], 'BackgroundColor', bgcolor, ...
    'units','normalized', 'Position', posInfo.rpmEstChk, 'callback', rpmCb);

guiHandlesSpec3.playerBtn = uicontrol(PSspecfig3,'string','Player','fontsize',fontsz,...
    'TooltipString','Animated spectrum playback over time','units','normalized',...
    'Position',[posInfo.playerBtn3],...
    'callback',['if exist(''specMat'',''var'') && ~isempty(specMat),' ...
        'tmpSA3={''Gyro'',''Gyro prefilt'',''Dterm'',''Dterm prefilt'',''Pterm'',''PID error'',''Set point'',''PIDsum''};' ...
        'PSdynSpecPlayer(specMat,Tm,F,{''Roll'',''Pitch'',''Yaw''},tmpSA3{get(guiHandlesSpec3.SpecList,''Value'')});' ...
    'else,warndlg(''Run spectrogram first''),end']);
set(guiHandlesSpec3.playerBtn, 'ForegroundColor', [0 .4 .8]);
end % ishandle(Spec3Crtlpanel)

% Register CP for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', Spec3Crtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0);
cpI{end+1} = struct('h', guiHandlesSpec3.FileSelect, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.SpecList, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.computeSpec, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.resetSpec, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.saveFig3, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.saveSettings3, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.smoothFactor_select, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.subsampleFactor_select, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.ColormapSelect, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.climMax1_text, 'type','text_left', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec3.climMax2_text, 'type','text_right', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec3.climMax1_input, 'type','input_left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.climMax2_input, 'type','input_right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.sub100HzfreqTime, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmMotor1, 'type','quarter1', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmMotor2, 'type','quarter2', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmMotor3, 'type','quarter3', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmMotor4, 'type','quarter4', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmHarmDd, 'type','dd_left', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmLwDd, 'type','dd_right', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmDynNotch, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.rpmEstChk, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec3.playerBtn, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
setappdata(PSspecfig3, 'PSplotGrid', struct('plotL',plotL1, 'colGap',0, ...
    'ncols',1, 'rows',rows, 'rowH',0.255, 'margin',0.10));
PSregisterResize(PSspecfig3, cpPx, cpI, 'seq');

try set(guiHandlesSpec3.SpecList, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-Preset')))), catch, set(guiHandlesSpec3.SpecList, 'Value', 1), end
try set(guiHandlesSpec3.smoothFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-FreqSmoothing')))), catch, set(guiHandlesSpec3.smoothFactor_select, 'Value', 2), end
try set(guiHandlesSpec3.subsampleFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-TimeSmoothing')))), catch, set(guiHandlesSpec3.subsampleFactor_select, 'Value', 2), end
try set(guiHandlesSpec3.ColormapSelect, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqxTime-Colormap')))), catch, set(guiHandlesSpec3.ColormapSelect, 'Value', 3), end


else
     warndlg('Please select file(s)');
end
PSstyleControls(PSspecfig3);

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
    if isnan(str2double(str))
        set(src,'string','0');
        warndlg('Input must be numerical');  
    end
end





