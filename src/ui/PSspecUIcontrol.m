%% PSspecUIcontrol - ui controls for spectral analyses plots

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    
if exist('fnameMaster','var') && ~isempty(fnameMaster)

%%% tooltips
TooltipString_specRun=['Run current spectral configuration',...
    newline, 'Warning: Set subsampling dropdown @ or < medium for faster processing.'];
TooltipString_presets=['Choose from a selection of PRESET configurations'];
TooltipString_cmap=['Choose from a selection of colormaps'];
TooltipString_smooth=['Choose amount of smoothing'];
TooltipString_2d=['Show 2 dimensional plots'];
TooltipString_user=['Choose the variable you wish to plot (consider PRESETs dropdown menu above for quick configurations)'];
TooltipString_sub100=['Zoom data to show sub 100Hz details',...
    newline, 'Typically used to see propwash or mid-throttle vibration in e.g. Gyro/Pterm/PIDerror'];
TooltipString_phase=['Estimated phase delay based on cross-correlation technique.',...
    newline, 'Note: estimate is most reliable with sufficient stick input so as to modulate the gyro and dterm.',...
    newline, 'Also requires that betaflight debug_mode is set to ''GYRO_SCALED'' '];
TooltipString_scale=['Colormap scaling. Note, the default is set such that an optimally filtered gyro ',...
    newline, 'should show little to no activity with the exception of a sub 100Hz band across throttle.',...
    newline, 'Dterm and motor outputs will typically be noisier, so sometimes scale adjustments ',...
    newline, 'are useful to see details. Otherwise, scaling should be the same when making comparisons'];
TooltipString_controlFreqCutoff=['Hz = Freq cutoff bounds for sub100Hz mean/peak analysis window.',...
    newline  'Changing this will move the yellow dashed lines representing this range (only in sub100Hz view).'];


%%%

% define
smat=[];%string
ampmat=[];%spec matrix
amp2d=[];%spec 2d
freq=[];% freq

% only need to call once to compute extra colormaps
try PScolormap; catch, end
SpecLineCols=[];
SpecLineCols(:,:,1) = [colorA; colorA; colorA; colorA];  
SpecLineCols(:,:,2) = [colorA; colorA; colorB; colorB]; 
SpecLineCols(:,:,3) = [colorA; colorB; colorC; colorD]; 
    

tbOff_spec = 40/screensz(4);
clear posInfo.SpecPos
cols=[0.04 0.25 0.46 0.67];
rows=[0.64-tbOff_spec 0.35-tbOff_spec 0.06-tbOff_spec];
k=0;
for c=1:4
    for r=1:3
        k=k+1;
        posInfo.SpecPos(k,:)=[cols(c) rows(r) 0.175 0.24];
    end
end


% Control panel layout — cpL/cpW/rh/rs/ddh/cpM inherited from PIDscope.m (pixel-based)
% yTop tracks where TOP of next element goes; Position Y = yTop - height
gap = rs - rh;  fw = cpW-2*cpM;  hw = cpW/2-cpM;
tbOff_s1 = 40/screensz(4);
yTop = 1 - tbOff_s1 - cpTitleH - cpMv;
posInfo.computeSpec=            [cpL+cpM yTop-rh hw rh];
posInfo.resetSpec=              [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.saveFig1=               [cpL+cpM yTop-rh hw rh];
posInfo.saveSettings1=          [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.specPresets=            [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.ColormapSelect=         [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.smooth_select =         [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.controlFreqCutoff_text =[cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.controlFreq1Cutoff =    [cpL+cpM yTop-rh hw rh];
posInfo.controlFreq2Cutoff =    [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.checkbox2d=             [cpL+cpM yTop-rh hw rh];
posInfo.checkboxPSD=            [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.checkboxEstRPM=         [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.rpmLegend1=             [cpL+cpM yTop-rhs fw rhs]; yTop=yTop-rhs-cpMv;
posInfo.rpmLegend2=             [cpL+cpM yTop-rhs fw rhs]; yTop=yTop-rhs-cpMv;
posInfo.rpmLegend3=             [cpL+cpM yTop-rhs fw rhs];

posInfo.AphasedelayText1=[.06 .984-tbOff_spec .14 .02];
posInfo.AphasedelayText2=[.27 .984-tbOff_spec .14 .02];
posInfo.AphasedelayText3=[.48 .984-tbOff_spec .14 .02];
posInfo.AphasedelayText4=[.69 .984-tbOff_spec .14 .02];

posInfo.hCbar1pos=[0.04 0.89-tbOff_spec 0.175  0.02];
posInfo.hCbar2pos=[0.25 0.89-tbOff_spec 0.175  0.02];
posInfo.hCbar3pos=[0.46 0.89-tbOff_spec 0.175  0.02];
posInfo.hCbar4pos=[0.67 0.89-tbOff_spec 0.175  0.02];

ddh = 0.01; % dropdown height
if exist('isOctave','var') && isOctave, ddh = 0.025; end
posInfo.hDropdn1pos=[0.08 0.97-tbOff_spec 0.095   ddh];
posInfo.hDropdn2pos=[0.29 0.97-tbOff_spec 0.095   ddh];
posInfo.hDropdn3pos=[0.50 0.97-tbOff_spec 0.095   ddh];
posInfo.hDropdn4pos=[0.71 0.97-tbOff_spec 0.095   ddh];

posInfo.fDropdn1pos=[0.08 0.942-tbOff_spec 0.095  ddh];
posInfo.fDropdn2pos=[0.29 0.942-tbOff_spec 0.095  ddh];
posInfo.fDropdn3pos=[0.50 0.942-tbOff_spec 0.095  ddh];
posInfo.fDropdn4pos=[0.71 0.942-tbOff_spec 0.095  ddh];

posInfo.Sub100HzCheck1=[0.175 0.942-tbOff_spec .06 .025];
posInfo.Sub100HzCheck2=[.385 .942-tbOff_spec .06 .025];
posInfo.Sub100HzCheck3=[.595 .942-tbOff_spec .06 .025];
posInfo.Sub100HzCheck4=[.805 .942-tbOff_spec .06 .025];

posInfo.climMax_text = [.01 .913-tbOff_spec .025 .024];
posInfo.climMax_input = [.01 .888-tbOff_spec .025 .024];
posInfo.climMax_text2 = [.22 .913-tbOff_spec .025 .024];
posInfo.climMax_input2 = [.22 .888-tbOff_spec .025 .024];
posInfo.climMax_text3 = [.43 .913-tbOff_spec .025 .024];
posInfo.climMax_input3 = [.43 .888-tbOff_spec .025 .024];
posInfo.climMax_text4 = [.64 .913-tbOff_spec .025 .024];
posInfo.climMax_input4 = [.64 .888-tbOff_spec .025 .024];
climScale=[0.5 0.5 0.5 0.5; 10 10 10 10];
Flim1=20; % 3.3333Hz steps
Flim2=60;

if exist('PSspecfig','var') && ishandle(PSspecfig)
    figure(PSspecfig);
else
    PSspecfig=figure(2);
    set(PSspecfig, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSspecfig, 'WindowState', 'maximized'); catch, end
    set(PSspecfig, 'NumberTitle', 'off');
    set(PSspecfig, 'Name', ['PIDscope (' PsVersion ') - Frequency x Throttle Spectrogram']);
    set(PSspecfig, 'InvertHardcopy', 'off');
    set(PSspecfig,'color',bgcolor);
end


try  % datacursormode not available in Octave
  dcm_obj2 = datacursormode(PSspecfig);
  set(dcm_obj2,'UpdateFcn',@PSdatatip);
end

spPanelBot = yTop - rhs - cpMv;
if ~exist('specCrtlpanel','var') || ~ishandle(specCrtlpanel)
specCrtlpanel = uipanel('Title','Params','FontSize',fontsz,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[cpL spPanelBot cpW vPos-spPanelBot+cpTitleH]);

%%% PRESET CONFIGURATIONS

% guiHandles.FileNum = uicontrol(PSspecfig,'Style','popupmenu','string',[fnameMaster],'TooltipString', [TooltipString_FileNum],...
%     'fontsize',fontsz, 'units','normalized','Position', [posInfo.fnameASpec],'callback','PSplotSpec;');

guiHandlesSpec.specPresets = uicontrol(PSspecfig,'Style','popupmenu','string',{'Presets:'; '1. Gyro prefilt | Gyro | Dterm prefilt | Dterm' ;  '2. Gyro prefilt | Gyro | Pterm | Dterm' ; '3. Gyro | Dterm | Set point | PID error' ; '4. A|A|B|B Gyro prefilt | Gyro' ; '5. A|A|B|B Dterm prefilt | Dterm' ; '6. A|B|C|D Gyro prefilt ' ;'7. A|B|C|D Gyro '; '8. A|B|C|D Dterm '; '9. A|B|C|D PID error'},...
    'fontsize',fontsz,'TooltipString', [TooltipString_presets], 'units','normalized','Position', [posInfo.specPresets],...
    'callback','PSapplySpecPreset(get(guiHandlesSpec.specPresets,''Value''), guiHandlesSpec);updateSpec=1;PSplotSpec;');

guiHandlesSpec.computeSpec = uicontrol(PSspecfig,'string','Run','fontsize',fontsz,'TooltipString', [TooltipString_specRun],'units','normalized','Position',[posInfo.computeSpec],...
    'callback','PSplotSpec;');
set(guiHandlesSpec.computeSpec, 'ForegroundColor', colRun);

guiHandlesSpec.resetSpec = uicontrol(PSspecfig,'string','Reset','fontsize',fontsz,'TooltipString', ['Reset Spectral Tool'],'units','normalized','Position',[posInfo.resetSpec],...
    'callback','delete(findobj(PSspecfig,''Type'',''axes'')); set(guiHandlesSpec.specPresets, ''Value'', 1); PSspecUIcontrol; set(PSspecfig, ''pointer'', ''arrow'');');
set(guiHandlesSpec.resetSpec, 'ForegroundColor', cautionCol);

guiHandlesSpec.checkbox2d =uicontrol(PSspecfig,'Style','checkbox','String','2D','fontsize',fontsz,'TooltipString', [TooltipString_2d],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkbox2d],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), end;updateSpec=1;PSplotSpec;');

guiHandlesSpec.checkboxPSD =uicontrol(PSspecfig,'Style','checkbox','String','PSD','fontsize',fontsz,'TooltipString', ['Power Spectral Density'],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkboxPSD],'callback', 'PSplotSpec;');
set(guiHandlesSpec.checkboxPSD, 'Value', 0);

guiHandlesSpec.checkboxEstRPM =uicontrol(PSspecfig,'Style','checkbox','String','Est. RPM','fontsize',fontsz,'TooltipString', ['Estimate motor RPM from spectrum (2D heatmap only)'],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkboxEstRPM],'callback','updateSpec=1;PSplotSpec;');
set(guiHandlesSpec.checkboxEstRPM, 'Value', 0);

guiHandlesSpec.rpmLegend1 = uicontrol(PSspecfig,'style','text','string','--- 1st (fund)','fontsize',fontsz-1,'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',[0 .7 .15],'FontWeight','bold','Position',[posInfo.rpmLegend1]);
guiHandlesSpec.rpmLegend2 = uicontrol(PSspecfig,'style','text','string','-- 2nd harm','fontsize',fontsz-1,'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',[.9 .7 0],'FontWeight','bold','Position',[posInfo.rpmLegend2]);
guiHandlesSpec.rpmLegend3 = uicontrol(PSspecfig,'style','text','string','... 3rd harm','fontsize',fontsz-1,'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',[.9 .2 0],'FontWeight','bold','Position',[posInfo.rpmLegend3]);

guiHandlesSpec.controlFreqCutoff_text = uicontrol(PSspecfig,'style','text','string','freq lims Hz','fontsize',fontsz,'TooltipString',[TooltipString_controlFreqCutoff],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.controlFreqCutoff_text]);
guiHandlesSpec.controlFreq1Cutoff = uicontrol(PSspecfig,'style','edit','string',[num2str(round(Flim1))],'fontsize',fontsz,'TooltipString',[TooltipString_controlFreqCutoff],'units','normalized','Position',[posInfo.controlFreq1Cutoff],...
     'callback','@textinput_call2; Flim1=round(str2num(get(guiHandlesSpec.controlFreq1Cutoff, ''String'')));updateSpec=1;PSplotSpec;');
guiHandlesSpec.controlFreq2Cutoff = uicontrol(PSspecfig,'style','edit','string',[num2str(round(Flim2))],'fontsize',fontsz,'TooltipString',[TooltipString_controlFreqCutoff],'units','normalized','Position',[posInfo.controlFreq2Cutoff],...
     'callback','@textinput_call2; Flim2=round(str2num(get(guiHandlesSpec.controlFreq2Cutoff, ''String'')));updateSpec=1;PSplotSpec;');

guiHandlesSpec.saveFig1 = uicontrol(PSspecfig,'string','Save Fig','fontsize',fontsz,'TooltipString',[TooltipString_saveFig],'units','normalized','ForegroundColor',[saveCol],'Position',[posInfo.saveFig1],...
    'callback','set(guiHandlesSpec.saveFig1, ''FontWeight'', ''bold'');PSsaveFig;set(guiHandlesSpec.saveFig1, ''FontWeight'', ''normal'');'); 

guiHandlesSpec.saveSettings1 = uicontrol(PSspecfig,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PIDscope defaults' ], 'units','normalized','Position',[posInfo.saveSettings1],...
    'callback','set(guiHandlesSpec.saveSettings1, ''FontWeight'', ''bold'');PSsaveSettings; set(guiHandlesSpec.saveSettings1, ''FontWeight'', ''normal'');');
set(guiHandlesSpec.saveSettings1, 'ForegroundColor', saveCol);

guiHandlesSpec.Sub100HzCheck{1} =uicontrol(PSspecfig,'Style','checkbox','String','<100Hz','fontsize',fontsz,'TooltipString', [TooltipString_sub100], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.Sub100HzCheck1],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), end;updateSpec=1;PSplotSpec;');
guiHandlesSpec.Sub100HzCheck{2} =uicontrol(PSspecfig,'Style','checkbox','String','<100Hz','fontsize',fontsz,'TooltipString', [TooltipString_sub100], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.Sub100HzCheck2],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), end;updateSpec=1;PSplotSpec;');
guiHandlesSpec.Sub100HzCheck{3} =uicontrol(PSspecfig,'Style','checkbox','String','<100Hz','fontsize',fontsz,'TooltipString', [TooltipString_sub100], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.Sub100HzCheck3],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), end;updateSpec=1;PSplotSpec;');
guiHandlesSpec.Sub100HzCheck{4} =uicontrol(PSspecfig,'Style','checkbox','String','<100Hz','fontsize',fontsz,'TooltipString', [TooltipString_sub100], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.Sub100HzCheck4],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), end;updateSpec=1;PSplotSpec;');

% create string list for SpecSelect
sA={'NONE','Gyro','Gyro prefilt','PID error','Set point','Pterm','Dterm','Dterm prefilt','PIDsum'};

guiHandlesSpec.SpecSelect{1} = uicontrol(PSspecfig,'Style','popupmenu','string',sA, 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.hDropdn1pos]);
guiHandlesSpec.SpecSelect{2} = uicontrol(PSspecfig,'Style','popupmenu','string',sA, 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.hDropdn2pos]);
guiHandlesSpec.SpecSelect{3} = uicontrol(PSspecfig,'Style','popupmenu','string',sA,  'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.hDropdn3pos]);
guiHandlesSpec.SpecSelect{4} = uicontrol(PSspecfig,'Style','popupmenu','string',sA, 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.hDropdn4pos]);
 
guiHandlesSpec.FileSelect{1} = uicontrol(PSspecfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fDropdn1pos]);
guiHandlesSpec.FileSelect{2} = uicontrol(PSspecfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fDropdn2pos]);
guiHandlesSpec.FileSelect{3} = uicontrol(PSspecfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fDropdn3pos]);
guiHandlesSpec.FileSelect{4} = uicontrol(PSspecfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fDropdn4pos]);

guiHandlesSpec.smoothFactor_select = uicontrol(PSspecfig,'style','popupmenu','string',{'smoothing low' 'smoothing low-med' 'smoothing medium' 'smoothing med-high' 'smoothing high'},'fontsize',fontsz,'TooltipString', [TooltipString_smooth], 'units','normalized','Position',[posInfo.smooth_select],...
     'callback','@selection2;updateSpec=1;PSplotSpec;');

guiHandlesSpec.climMax_text = uicontrol(PSspecfig,'style','text','string','scale','fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax_text]);
guiHandlesSpec.climMax_input = uicontrol(PSspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 1)=str2num(get(guiHandlesSpec.climMax_input, ''String''));updateSpec=1;PSplotSpec;');

 guiHandlesSpec.climMax_text2 = uicontrol(PSspecfig,'style','text','string','scale','fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax_text2]);
guiHandlesSpec.climMax_input2 = uicontrol(PSspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 2))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input2],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 2)=str2num(get(guiHandlesSpec.climMax_input2, ''String''));updateSpec=1;PSplotSpec;');
 
 guiHandlesSpec.climMax_text3 = uicontrol(PSspecfig,'style','text','string','scale','fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax_text3]);
guiHandlesSpec.climMax_input3 = uicontrol(PSspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 3))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input3],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 3)=str2num(get(guiHandlesSpec.climMax_input3, ''String''));updateSpec=1;PSplotSpec;');
 
 guiHandlesSpec.climMax_text4 = uicontrol(PSspecfig,'style','text','string','scale','fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax_text4]);
guiHandlesSpec.climMax_input4 = uicontrol(PSspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 4))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input4],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 4)=str2num(get(guiHandlesSpec.climMax_input4, ''String''));updateSpec=1;PSplotSpec;');
 
 guiHandlesSpec.ColormapSelect = uicontrol(PSspecfig,'Style','popupmenu','string',{'viridis','jet','hot','cool','gray','bone','copper','linear-RED','linear-GREY'},...
    'fontsize',fontsz,'TooltipString', [TooltipString_cmap], 'units','normalized','Position',[posInfo.ColormapSelect],'callback','@selection2;updateSpec=1; PSplotSpec;');
set(guiHandlesSpec.ColormapSelect, 'Value', 3);% jet 2 hot 3 viridis 8
end % ishandle(specCrtlpanel)

% Register CP for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', specCrtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0);
cpI{end+1} = struct('h', guiHandlesSpec.computeSpec, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.resetSpec, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.saveFig1, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.saveSettings1, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.specPresets, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec.ColormapSelect, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec.smoothFactor_select, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec.controlFreqCutoff_text, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.controlFreq1Cutoff, 'type','input_left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.controlFreq2Cutoff, 'type','input_right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.checkbox2d, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.checkboxPSD, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.checkboxEstRPM, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec.rpmLegend1, 'type','full', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec.rpmLegend2, 'type','full', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec.rpmLegend3, 'type','full', 'row',0, 'col',0, 'hpx',rhs_px);
PSregisterResize(PSspecfig, cpPx, cpI, 'seq');

try set(guiHandlesSpec.SpecSelect{1}, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Column1')))), catch, set(guiHandlesSpec.SpecSelect{1}, 'Value', 3); end
try set(guiHandlesSpec.SpecSelect{2}, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Column2')))), catch, set(guiHandlesSpec.SpecSelect{2}, 'Value', 2); end
try set(guiHandlesSpec.SpecSelect{3}, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Column3')))), catch, set(guiHandlesSpec.SpecSelect{3}, 'Value', 8); end
try set(guiHandlesSpec.SpecSelect{4}, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Column4')))), catch, set(guiHandlesSpec.SpecSelect{4}, 'Value', 7); end
try set(guiHandlesSpec.specPresets, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Preset')))), catch, set(guiHandlesSpec.specPresets, 'Value', 1); end
try set(guiHandlesSpec.ColormapSelect, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Colormap')))), catch, set(guiHandlesSpec.ColormapSelect, 'Value', 3); end
try set(guiHandlesSpec.smoothFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'FreqXthr-Smoothing')))), catch, set(guiHandlesSpec.smoothFactor_select, 'Value', 3); end


else
     warndlg('Please select file(s)');
end
PSstyleControls(PSspecfig);

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





