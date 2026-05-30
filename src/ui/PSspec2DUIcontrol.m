%% PSspec2DUIcontrol - ui controls for spectral analyses plots

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
TooltipString_smooth=['Choose amount of smoothing'];
TooltipString_user=['Choose signal(s) to plot. Select up to 2.' ...
    newline, 'Gyro prefilt = pre-filter gyro (dotted line).' ...
    newline, 'BF 4.5+: uses gyroUnfilt (logged by default). Older BF: requires debug_mode = GYRO_SCALED.'];
TooltipString_sub100=['Zoom data to show sub 100Hz details',...
    newline, 'Typically used to see propwash or mid-throttle vibration in e.g. Gyro/Pterm/PIDerror'];


%%%
th = PStheme();
PScolormap;
% define
smat=[];%string
ampmat=[];%spec matrix
amp2d2=[];%spec 2d
freq2d2=[];% freq
  

clear posInfo.Spec2Pos
plotR = cpL - 0.04;  plotL2 = 0.05;  colGap2 = 0.02;
colW2 = (plotR - plotL2 - colGap2) / 2;
cols = [plotL2, plotL2 + colW2 + colGap2];
rows=[0.69 0.395 0.1];
k=0;
for c=1 : size(cols,2)
    for r=1 : size(rows,2)
        k=k+1;
        posInfo.Spec2Pos(k,:)=[cols(c) rows(r) colW2 0.25];
    end
end

% Control panel layout — cpL/cpW/rh/rs/cpM/ddh inherited from PIDscope.m
% yTop tracks where the TOP of the next element goes; Position Y = yTop - height
listH = 5*rs;  termH = round(4.3*rs);  gap = rs - rh;  fw = cpW-2*cpM;  hw = cpW/2-cpM;
tbOff_s2 = 40/screensz(4);
yTop = 1 - tbOff_s2 - cpTitleH - cpMv;
posInfo.fileListWindowSpec=  [cpL+cpM yTop-listH fw listH]; yTop=yTop-listH-gap;
posInfo.TermListWindowSpec=  [cpL+cpM yTop-termH fw termH]; yTop=yTop-termH-gap;

posInfo.computeSpec=         [cpL+cpM yTop-rh hw rh];
posInfo.resetSpec=           [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.spectrogramButton2=  [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.spectrogramButton3=  [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.motorNoiseButton=    [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.chirpButton=         [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.saveFig2=            [cpL+cpM yTop-rh hw rh];
posInfo.saveSettings2=       [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;

posInfo.smooth_select =      [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.Delay =              [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;

posInfo.plotRspec =          [cpL+cpM        yTop-rh cbW rh];
posInfo.plotPspec =          [cpL+cpM+cbW    yTop-rh cbW rh];
posInfo.plotYspec =          [cpL+cpM+2*cbW  yTop-rh cbW rh]; yTop=yTop-rh-gap;

posInfo.checkboxPSD =        [cpL+cpM yTop-rh cbW rh];
posInfo.RPYcomboSpec =       [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;

posInfo.climMax1_text =      [cpL+cpM yTop-rhs cpW/4 rhs];
posInfo.climMax2_text =      [cpL+cpW/2 yTop-rhs cpW/4 rhs]; yTop=yTop-rhs-gap;
posInfo.climMax1_input =     [cpL+cpM yTop-rh cpW/4 rh];
posInfo.climMax2_input =     [cpL+cpW/2 yTop-rh cpW/4 rh]; yTop=yTop-rh-gap;

qw = fw/4;
posInfo.rpmMotor1 =          [cpL+cpM       yTop-rh qw rh];
posInfo.rpmMotor2 =          [cpL+cpM+qw    yTop-rh qw rh];
posInfo.rpmMotor3 =          [cpL+cpM+2*qw  yTop-rh qw rh];
posInfo.rpmMotor4 =          [cpL+cpM+3*qw  yTop-rh qw rh]; yTop=yTop-rh-gap;
posInfo.rpmHarmDd =          [cpL+cpM yTop-ddh hw ddh];
posInfo.rpmLwDd   =          [cpL+cpW/2 yTop-ddh hw ddh]; yTop=yTop-ddh-gap;

climScale1=[0 ; -50 ];
climScale2=[0.5 ; 20];

if exist('PSspecfig2','var') && ishandle(PSspecfig2)
    figure(PSspecfig2);
else
    PSspecfig2=figure(3);
    set(PSspecfig2, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PSspecfig2, 'WindowState', 'maximized'); catch, end
    set(PSspecfig2, 'NumberTitle', 'off');
    set(PSspecfig2, 'Name', ['PIDscope (' PsVersion ') - Spectral Analyzer']);
    set(PSspecfig2, 'InvertHardcopy', 'off');
    set(PSspecfig2,'color',bgcolor);
end


try  % datacursormode not available in Octave
  dcm_obj2 = datacursormode(PSspecfig2);
  set(dcm_obj2,'UpdateFcn',@PSdatatip);
end

sp2PanelBot = yTop - rh - gap;
sp2PanelH = vPos - sp2PanelBot + cpTitleH;
spec2CrtlpanelPos = [cpL sp2PanelBot cpW sp2PanelH];
if ~exist('spec2Crtlpanel','var') || ~ishandle(spec2Crtlpanel)
spec2Crtlpanel = uipanel('Title','select files (max 10)','FontSize',fontsz,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',spec2CrtlpanelPos);

guiHandlesSpec2.computeSpec = uicontrol(PSspecfig2,'string','Run','fontsize',fontsz,'TooltipString', [TooltipString_specRun],'units','normalized','Position',[posInfo.computeSpec],...
    'callback','PSplotSpec2D;');
set(guiHandlesSpec2.computeSpec, 'ForegroundColor', colRun);

guiHandlesSpec2.resetSpec = uicontrol(PSspecfig2,'string','Reset','fontsize',fontsz,'TooltipString', ['Reset Spectral Tool'],'units','normalized','Position',[posInfo.resetSpec],...
    'callback',' delete(findobj(PSspecfig2,''Type'',''axes'')); set(PSspecfig2, ''pointer'', ''arrow'');');
set(guiHandlesSpec2.resetSpec, 'ForegroundColor', cautionCol);

guiHandlesSpec2.saveFig2 = uicontrol(PSspecfig2,'string','Save Fig','fontsize',fontsz,'TooltipString',[TooltipString_saveFig],'units','normalized','ForegroundColor',[saveCol],'Position',[posInfo.saveFig2],...
    'callback','set(guiHandlesSpec2.saveFig2, ''FontWeight'', ''bold'');PSsaveFig;set(guiHandlesSpec2.saveFig2, ''FontWeight'', ''normal'');'); 

guiHandlesSpec2.saveSettings2 = uicontrol(PSspecfig2,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PIDscope defaults' ], 'units','normalized','Position',[posInfo.saveSettings2],...
    'callback','set(guiHandlesSpec2.saveSettings2, ''FontWeight'', ''bold'');PSsaveSettings; set(guiHandlesSpec2.saveSettings2, ''FontWeight'', ''normal'');');
set(guiHandlesSpec2.saveSettings2, 'ForegroundColor', saveCol);

% create string list for SpecSelect
sA={'Gyro','Gyro prefilt','Dterm','Dterm prefilt','Pterm','PID error','Set point','Fterm','PIDsum','Motors'};
if isfield(T{1}, 'testSignal_0_'), sA{end+1} = 'Test Signal'; end

guiHandlesSpec2.SpecList = uicontrol(PSspecfig2,'Style','listbox','string',[sA],'max',3,'min',1, 'fontsize',fontsz, 'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.TermListWindowSpec], 'callback', 'if length(get(guiHandlesSpec2.SpecList, ''Value'')) > 2, set(guiHandlesSpec2.SpecList, ''Value'', 1); end;');
specDef_ = [1]; if isfield(T{1}, 'gyroPrefilt_0_'), specDef_ = [1 2]; end
set(guiHandlesSpec2.SpecList, 'Value', specDef_);
 
guiHandlesSpec2.FileSelect = uicontrol(PSspecfig2,'Style','listbox','string',[fnameMaster],'max', 10, 'min', 1, 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fileListWindowSpec], 'callback', 'if length(get(guiHandlesSpec2.FileSelect, ''Value'')) > 10, set(guiHandlesSpec2.FileSelect, ''Value'', 1); end;');

guiHandlesSpec2.smoothFactor_select = uicontrol(PSspecfig2,'style','popupmenu','string',{'smoothing low' 'smoothing low-med' 'smoothing medium' 'smoothing med-high' 'smoothing high'},'fontsize',fontsz,'TooltipString', [TooltipString_smooth], 'units','normalized','Position',[posInfo.smooth_select],...
     'callback','@selection2;PSplotSpec2D;');

guiHandlesSpec2.spectrogramButton2 = uicontrol(PSspecfig2,'string','Freq x Throttle','fontsize',fontsz,'TooltipString', ['Opens Freq x Throttle Spectrogram in New Window'], 'units','normalized','Position',[posInfo.spectrogramButton2],...
    'callback','PSspecUIcontrol;');
set(guiHandlesSpec2.spectrogramButton2, 'ForegroundColor', th.btnDash1);

 guiHandlesSpec2.spectrogramButton3 = uicontrol(PSspecfig2,'string','Freq x Time','fontsize',fontsz,'TooltipString', ['Opens Freq x Time Spectrogram in New Window'], 'units','normalized','Position',[posInfo.spectrogramButton3],...
     'callback','PSfreqTimeUIcontrol;');
 set(guiHandlesSpec2.spectrogramButton3, 'ForegroundColor', th.btnDash2);

guiHandlesSpec2.rightColMode = uicontrol(PSspecfig2,'Style','popupmenu','String',{'sub 100Hz','Motor Noise'},...
    'fontsize',fontsz,'TooltipString','Right column: sub 100Hz PSD or Motor Noise per-harmonic',...
    'units','normalized','Position',[posInfo.motorNoiseButton],...
    'callback',['vis_=''off'';if get(guiHandlesSpec2.rightColMode,''Value'')==2,vis_=''on'';end;' ...
        'flds_={''rpmMotor1'',''rpmMotor2'',''rpmMotor3'',''rpmMotor4'',''rpmHarmDd'',''rpmLwDd''};' ...
        'for fi_=1:6,set(guiHandlesSpec2.(flds_{fi_}),''Visible'',vis_);end;' ...
        'try PSresizeCP(PSspecfig2,[]);catch,end;PSplotSpec2D;']);

guiHandlesSpec2.chirpButton = uicontrol(PSspecfig2,'string','Chirp Analysis','fontsize',fontsz,...
    'TooltipString','Frequency response from chirp log (BF 2025.12+, debug_mode=CHIRP)','units','normalized',...
    'Position',[posInfo.chirpButton],...
    'callback',['try,' ...
        'tmpFcnt=get(guiHandlesSpec2.FileSelect,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'tmpRPY=[get(guiHandlesSpec2.plotR,''Value'') get(guiHandlesSpec2.plotP,''Value'') get(guiHandlesSpec2.plotY,''Value'')];' ...
        'tmpAx=find(tmpRPY,1)-1;if isempty(tmpAx),tmpAx=0;end;' ...
        'PSrunChirpAnalysis(T{tmpFcnt},SetupInfo{tmpFcnt},debugIdx{tmpFcnt},1000*A_lograte(tmpFcnt),tIND{tmpFcnt},tmpAx);' ...
        'clear tmpFcnt tmpRPY tmpAx;' ...
    'catch e,warndlg([''Chirp: '' e.message]),end']);
set(guiHandlesSpec2.chirpButton, 'ForegroundColor', th.btnChirp);

 guiHandlesSpec2.Delay = uicontrol(PSspecfig2,'style','popupmenu','string',{'filter delay', 'SP-gyro delay', 'SP smoothing delay', 'phase shift'},'fontsize',fontsz,'TooltipString', ['Select which Delay Display'], 'units','normalized','Position',[posInfo.Delay],...
     'callback','PSplotSpec2D;');

guiHandlesSpec2.plotR =uicontrol(PSspecfig2,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisRoll,'Position',[posInfo.plotRspec], 'callback', 'PSplotSpec2D;');

guiHandlesSpec2.plotP =uicontrol(PSspecfig2,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisPitch,'Position',[posInfo.plotPspec], 'callback', 'PSplotSpec2D;');

guiHandlesSpec2.plotY =uicontrol(PSspecfig2,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisYaw,'Position',[posInfo.plotYspec], 'callback', 'PSplotSpec2D;');

guiHandlesSpec2.checkboxPSD =uicontrol(PSspecfig2,'Style','checkbox','String','PSD','fontsize',fontsz,'TooltipString', ['Power Spectral Density'],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkboxPSD],'callback', 'PSplotSpec2D;');
set(guiHandlesSpec2.checkboxPSD, 'Value', 1);

guiHandlesSpec2.RPYcomboSpec =uicontrol(PSspecfig2,'Style','checkbox','String','Single Panel','fontsize',fontsz,'TooltipString', ['Plot RPY in same panel '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.RPYcomboSpec],'callback', 'PSplotSpec2D;');

guiHandlesSpec2.climMax1_text = uicontrol(PSspecfig2,'style','text','string','Y min','fontsize',fontsz,'TooltipString',['Y min'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax1_text]);
guiHandlesSpec2.climMax1_input = uicontrol(PSspecfig2,'style','edit','string',[num2str(climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',['Y min'],'units','normalized','Position',[posInfo.climMax1_input],...
     'callback','@textinput_call2; climScale1(get(guiHandlesSpec2.checkboxPSD, ''Value'')+1, 1)=str2double(get(guiHandlesSpec2.climMax1_input, ''String''));PSplotSpec2D;');

 guiHandlesSpec2.climMax2_text = uicontrol(PSspecfig2,'style','text','string','Y max','fontsize',fontsz,'TooltipString',['Y max'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax2_text]);
guiHandlesSpec2.climMax2_input = uicontrol(PSspecfig2,'style','edit','string',[num2str(climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',['Y max'],'units','normalized','Position',[posInfo.climMax2_input],...
     'callback','@textinput_call2; climScale2(get(guiHandlesSpec2.checkboxPSD, ''Value'')+1, 1)=str2double(get(guiHandlesSpec2.climMax2_input, ''String''));PSplotSpec2D;');

motorCols = PStheme().sigMotor;
nMot_ = 4;
if exist('T','var') && ~isempty(T)
    for mi_ = 4:7
        if isfield(T{1}, ['motor_' int2str(mi_) '_']), nMot_ = mi_+1; end
    end
end
if nMot_ > 4
    motorNames = {sprintf('M1/%d',nMot_/2+1), sprintf('M2/%d',nMot_/2+2), sprintf('M3/%d',nMot_/2+3), sprintf('M4/%d',nMot_/2+4)};
else
    motorNames = {'M1','M2','M3','M4'};
end
guiHandlesSpec2.nMotors = nMot_;
rpmCb2 = 'PSplotSpec2D;';
for mi = 1:4
    fld = sprintf('rpmMotor%d', mi);
    guiHandlesSpec2.(fld) = uicontrol(PSspecfig2, 'Style','checkbox', 'String', motorNames{mi}, ...
        'fontsize', fontsz-1, 'Value', 1, 'Visible', 'off', ...
        'ForegroundColor', motorCols{mi}, 'BackgroundColor', bgcolor, ...
        'units','normalized', 'Position', posInfo.(fld), 'callback', rpmCb2);
end
guiHandlesSpec2.rpmHarmDd = uicontrol(PSspecfig2, 'Style','popupmenu', ...
    'String', {'All harm.','1st','2nd','3rd','1st & 2nd','1st & 3rd','2nd & 3rd'}, ...
    'fontsize', fontsz, 'Value', 1, 'Visible', 'off', ...
    'units','normalized', 'Position', posInfo.rpmHarmDd, 'callback', rpmCb2);
guiHandlesSpec2.rpmLwDd = uicontrol(PSspecfig2, 'Style','popupmenu', ...
    'String', {'lw 0.5','lw 1','lw 1.5','lw 2'}, ...
    'fontsize', fontsz, 'Value', 3, 'Visible', 'off', ...
    'units','normalized', 'Position', posInfo.rpmLwDd, 'callback', rpmCb2);

end % ishandle(spec2Crtlpanel)

% Register CP for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
cpI{end+1} = struct('h', spec2Crtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0);
listH_px = 5*rs_px;  termH_px = round(4.3*rs_px);
cpI{end+1} = struct('h', guiHandlesSpec2.FileSelect, 'type','full', 'row',0, 'col',0, 'hpx',listH_px);
cpI{end+1} = struct('h', guiHandlesSpec2.SpecList, 'type','full', 'row',0, 'col',0, 'hpx',termH_px);
cpI{end+1} = struct('h', guiHandlesSpec2.computeSpec, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.resetSpec, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.spectrogramButton2, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.spectrogramButton3, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rightColMode, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.chirpButton, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.saveFig2, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.saveSettings2, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.smoothFactor_select, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.Delay, 'type','dd_full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.plotR, 'type','cb', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.plotP, 'type','cb', 'row',0, 'col',1, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.plotY, 'type','cb_end', 'row',0, 'col',2, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.checkboxPSD, 'type','cb', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.RPYcomboSpec, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.climMax1_text, 'type','text_left', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec2.climMax2_text, 'type','text_right', 'row',0, 'col',0, 'hpx',rhs_px);
cpI{end+1} = struct('h', guiHandlesSpec2.climMax1_input, 'type','input_left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.climMax2_input, 'type','input_right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmMotor1, 'type','quarter1', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmMotor2, 'type','quarter2', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmMotor3, 'type','quarter3', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmMotor4, 'type','quarter4', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmHarmDd, 'type','dd_left', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesSpec2.rpmLwDd, 'type','dd_right', 'row',0, 'col',0, 'hpx',ddh_px);
setappdata(PSspecfig2, 'PSplotGrid', struct('plotL',plotL2, 'colGap',colGap2, ...
    'ncols',2, 'rows',rows, 'rowH',0.25, 'margin',0.04));
PSregisterResize(PSspecfig2, cpPx, cpI, 'seq');

try specSaved_ = [defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-term1'))) defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-term2')))];
    if ~isfield(T{1}, 'gyroPrefilt_0_'), specSaved_(specSaved_ == 2) = []; end
    if isempty(specSaved_), specSaved_ = 1; end
    set(guiHandlesSpec2.SpecList, 'Value', specSaved_);
catch, set(guiHandlesSpec2.SpecList, 'Value', specDef_), end
try set(guiHandlesSpec2.smoothFactor_select, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-smoothing')))), catch, set(guiHandlesSpec2.smoothFactor_select, 'Value', 3), end
try set(guiHandlesSpec2.Delay, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-delay')))), catch, set(guiHandlesSpec2.Delay, 'Value', 1), end
try set(guiHandlesSpec2.plotR, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-plotR')))), catch, set(guiHandlesSpec2.plotR, 'Value', 1), end
try set(guiHandlesSpec2.plotP, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-plotP')))), catch, set(guiHandlesSpec2.plotP, 'Value', 1), end
try set(guiHandlesSpec2.plotY, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-plotY')))), catch, set(guiHandlesSpec2.plotY, 'Value', 1), end
try set(guiHandlesSpec2.RPYcomboSpec, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-SinglePanel')))), catch, set(guiHandlesSpec2.RPYcomboSpec, 'Value', 0), end


% Delay/overlay data computed lazily in PSplotSpec2D on "Run" click
if ~exist('FilterDelayDterm','var'), FilterDelayDterm = {}; end
if ~exist('SPGyroDelay','var'), SPGyroDelay = []; end
if ~exist('Debug01','var'), Debug01 = {}; end
if ~exist('Debug02','var'), Debug02 = {}; end
if ~exist('gyro_phase_shift_deg','var'), gyro_phase_shift_deg = zeros(Nfiles,1); end
if ~exist('dterm_phase_shift_deg','var'), dterm_phase_shift_deg = zeros(Nfiles,1); end
if ~exist('notchData','var'), notchData = {}; end
if ~exist('rpmFilterData','var'), rpmFilterData = {}; end
delayDataReady = false;



else
     warndlg('Please select file(s)');
end
PSstyleControls(PSspecfig2);

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





