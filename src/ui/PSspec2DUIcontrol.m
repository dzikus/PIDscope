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
TooltipString_user=['Choose the variable you wish to plot'];
TooltipString_sub100=['Zoom data to show sub 100Hz details',...
    newline, 'Typically used to see propwash or mid-throttle vibration in e.g. Gyro/Pterm/PIDerror'];


%%%
PScolormap;
% define
smat=[];%string
ampmat=[];%spec matrix
amp2d2=[];%spec 2d
freq2d2=[];% freq
  

clear posInfo.Spec2Pos
cols=[0.05 0.47];
rows=[0.69 0.395 0.1];
k=0;
for c=1 : size(cols,2)
    for r=1 : size(rows,2)
        k=k+1;
        posInfo.Spec2Pos(k,:)=[cols(c) rows(r) 0.37 0.25];
    end
end

vPosSpec2d = .037;
sp2_rh = .026; sp2_ddh = .04;
if exist('isOctave','var') && isOctave
    sp2_rh = .030; sp2_ddh = .035;
end

% Control panel layout (consistent with Log Viewer cpL/cpW)
cpL = .875; cpW = .12;

posInfo.fileListWindowSpec=  [cpL+.003 .7+vPosSpec2d cpW-.006 .20];
posInfo.TermListWindowSpec=  [cpL+.003 .55+vPosSpec2d cpW-.006 .14];

posInfo.computeSpec=         [cpL+.006 .52+vPosSpec2d cpW/2-.006 sp2_rh];
posInfo.resetSpec=           [cpL+cpW/2 .52+vPosSpec2d cpW/2-.006 sp2_rh];
posInfo.spectrogramButton2=  [cpL+.003 .49+vPosSpec2d cpW-.006 sp2_rh];
posInfo.spectrogramButton3=  [cpL+.003 .46+vPosSpec2d cpW-.006 sp2_rh];
posInfo.filterSimButton=     [cpL+.003 .43+vPosSpec2d cpW-.006 sp2_rh];
posInfo.motorNoiseButton=    [cpL+.003 .40+vPosSpec2d cpW-.006 sp2_rh];
posInfo.chirpButton=         [cpL+.003 .37+vPosSpec2d cpW-.006 sp2_rh];
posInfo.saveFig2=            [cpL+.006 .34+vPosSpec2d cpW/2-.006 sp2_rh];
posInfo.saveSettings2=       [cpL+cpW/2 .34+vPosSpec2d cpW/2-.006 sp2_rh];

posInfo.smooth_select =      [cpL+.003 .305+vPosSpec2d cpW-.006 sp2_ddh];
posInfo.Delay =              [cpL+.003 .27+vPosSpec2d cpW-.006 sp2_ddh];

posInfo.plotRspec =          [cpL+.005 .245+vPosSpec2d .035 .025];
posInfo.plotPspec =          [cpL+.04 .245+vPosSpec2d .035 .025];
posInfo.plotYspec =          [cpL+.075 .245+vPosSpec2d .035 .025];

posInfo.checkboxPSD =        [cpL+.005 .225+vPosSpec2d .04 .02];
posInfo.RPYcomboSpec =       [cpL+cpW/2-.01 .225+vPosSpec2d cpW/2+.004 .02];

posInfo.climMax1_text =      [cpL+.003 .202+vPosSpec2d cpW/4 .022];
posInfo.climMax1_input =     [cpL+cpW/4 .180+vPosSpec2d cpW/4 .022];
posInfo.climMax2_text =      [cpL+cpW/2 .202+vPosSpec2d cpW/4 .022];
posInfo.climMax2_input =     [cpL+3*cpW/4 .180+vPosSpec2d cpW/4 .022];

if exist('isOctave','var') && isOctave
    % Octave Qt widgets need more vertical space
    vPosSpec2d = .037;
    rr = .030; dd = .035;
    posInfo.computeSpec=         [cpL+.006 .52+vPosSpec2d cpW/2-.006 rr];
    posInfo.resetSpec=           [cpL+cpW/2 .52+vPosSpec2d cpW/2-.006 rr];
    posInfo.spectrogramButton2=  [cpL+.003 .485+vPosSpec2d cpW-.006 rr];
    posInfo.spectrogramButton3=  [cpL+.003 .450+vPosSpec2d cpW-.006 rr];
    posInfo.filterSimButton=     [cpL+.003 .415+vPosSpec2d cpW-.006 rr];
    posInfo.motorNoiseButton=    [cpL+.003 .380+vPosSpec2d cpW-.006 rr];
    posInfo.chirpButton=         [cpL+.003 .345+vPosSpec2d cpW-.006 rr];
    posInfo.saveFig2=            [cpL+.006 .310+vPosSpec2d cpW/2-.006 rr];
    posInfo.saveSettings2=       [cpL+cpW/2 .310+vPosSpec2d cpW/2-.006 rr];
    posInfo.smooth_select=       [cpL+.003 .270+vPosSpec2d cpW-.006 dd];
    posInfo.Delay=               [cpL+.003 .233+vPosSpec2d cpW-.006 dd];
    posInfo.plotRspec=           [cpL+.005 .208+vPosSpec2d .035 .025];
    posInfo.plotPspec=           [cpL+.04 .208+vPosSpec2d .035 .025];
    posInfo.plotYspec=           [cpL+.075 .208+vPosSpec2d .035 .025];
    posInfo.checkboxPSD=         [cpL+.005 .185+vPosSpec2d .04 .025];
    posInfo.RPYcomboSpec=        [cpL+cpW/2-.01 .185+vPosSpec2d cpW/2+.004 .025];
    posInfo.climMax1_text=       [cpL+.003 .162+vPosSpec2d cpW/4 .024];
    posInfo.climMax1_input=      [cpL+cpW/4 .140+vPosSpec2d cpW/4 .024];
    posInfo.climMax2_text=       [cpL+cpW/2 .162+vPosSpec2d cpW/4 .024];
    posInfo.climMax2_input=      [cpL+3*cpW/4 .140+vPosSpec2d cpW/4 .024];
end

climScale1=[0 ; -50 ];
climScale2=[0.5 ; 20];

PSspecfig2=figure(3);
set(PSspecfig2, 'Position', round([.1*screensz(3) .1*screensz(4) .75*screensz(3) .8*screensz(4)]));
set(PSspecfig2, 'NumberTitle', 'off');
set(PSspecfig2, 'Name', ['PIDscope (' PsVersion ') - Spectral Analyzer']);
set(PSspecfig2, 'InvertHardcopy', 'off');
set(PSspecfig2,'color',bgcolor);


try  % datacursormode not available in Octave
  dcm_obj2 = datacursormode(PSspecfig2);
  set(dcm_obj2,'UpdateFcn',@PSdatatip);
end

spec2CrtlpanelPos = [cpL .21+vPosSpec2d cpW .71];
if exist('isOctave','var') && isOctave
    spec2CrtlpanelPos = [cpL .16+vPosSpec2d cpW .76];
end
spec2Crtlpanel = uipanel('Title','select files (max 10)','FontSize',fontsz,...
              'BackgroundColor',[.95 .95 .95],...
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
sA={'Gyro','Gyro prefilt','Dterm','Dterm prefilt','Pterm','PID error','Set point','PIDsum'};

guiHandlesSpec2.SpecList = uicontrol(PSspecfig2,'Style','listbox','string',[sA],'max',3,'min',1, 'fontsize',fontsz, 'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.TermListWindowSpec], 'callback', 'if length(get(guiHandlesSpec2.SpecList, ''Value'')) > 2, set(guiHandlesSpec2.SpecList, ''Value'', 1); end;');
set(guiHandlesSpec2.SpecList, 'Value', [1 2]);
 
guiHandlesSpec2.FileSelect = uicontrol(PSspecfig2,'Style','listbox','string',[fnameMaster],'max', 10, 'min', 1, 'fontsize',fontsz,'TooltipString',[TooltipString_user],'units','normalized','Position', [posInfo.fileListWindowSpec], 'callback', 'if length(get(guiHandlesSpec2.FileSelect, ''Value'')) > 10, set(guiHandlesSpec2.FileSelect, ''Value'', 1); end;');

guiHandlesSpec2.smoothFactor_select = uicontrol(PSspecfig2,'style','popupmenu','string',{'smoothing low' 'smoothing low-med' 'smoothing medium' 'smoothing med-high' 'smoothing high'},'fontsize',fontsz,'TooltipString', [TooltipString_smooth], 'units','normalized','Position',[posInfo.smooth_select],...
     'callback','@selection2;PSplotSpec2D;');

guiHandlesSpec2.spectrogramButton2 = uicontrol(PSspecfig2,'string','Freq x Throttle','fontsize',fontsz,'TooltipString', ['Opens Freq x Throttle Spectrogram in New Window'], 'units','normalized','Position',[posInfo.spectrogramButton2],...
    'callback','PSspecUIcontrol;');
set(guiHandlesSpec2.spectrogramButton2, 'ForegroundColor', colorA);

 guiHandlesSpec2.spectrogramButton3 = uicontrol(PSspecfig2,'string','Freq x Time','fontsize',fontsz,'TooltipString', ['Opens Freq x Time Spectrogram in New Window'], 'units','normalized','Position',[posInfo.spectrogramButton3],...
     'callback','PSfreqTimeUIcontrol;');
 set(guiHandlesSpec2.spectrogramButton3, 'ForegroundColor', colorB);

guiHandlesSpec2.filterSimButton = uicontrol(PSspecfig2,'string','Filter Sim','fontsize',fontsz,...
    'TooltipString','Simulate BF filter chain on gyro data','units','normalized',...
    'Position',[posInfo.filterSimButton],...
    'callback',['try,' ...
        'tmpFcnt=get(guiHandlesSpec2.FileSelect,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'tmpGyro.r=T{tmpFcnt}.gyroADC_0_(tIND{tmpFcnt});' ...
        'tmpGyro.p=T{tmpFcnt}.gyroADC_1_(tIND{tmpFcnt});' ...
        'tmpGyro.y=T{tmpFcnt}.gyroADC_2_(tIND{tmpFcnt});' ...
        'PSfilterSim(tmpGyro,1000*A_lograte(tmpFcnt),SetupInfo{tmpFcnt});' ...
        'clear tmpGyro tmpFcnt;' ...
    'catch e,warndlg([''Filter Sim: '' e.message]),end']);
set(guiHandlesSpec2.filterSimButton, 'ForegroundColor', [.8 .5 0]);

guiHandlesSpec2.motorNoiseButton = uicontrol(PSspecfig2,'string','Motor Noise','fontsize',fontsz,...
    'TooltipString','Per-motor spectral analysis and noise comparison','units','normalized',...
    'Position',[posInfo.motorNoiseButton],...
    'callback',['try,' ...
        'tmpFcnt=get(guiHandlesSpec2.FileSelect,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'PSplotMotorNoise(T{tmpFcnt},tmpFcnt,tIND{tmpFcnt},1000*A_lograte(tmpFcnt));' ...
        'clear tmpFcnt;' ...
    'catch e,warndlg([''Motor Noise: '' e.message]),end']);
set(guiHandlesSpec2.motorNoiseButton, 'ForegroundColor', [.2 .7 .2]);

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
set(guiHandlesSpec2.chirpButton, 'ForegroundColor', [.8 .3 .8]);

 guiHandlesSpec2.Delay = uicontrol(PSspecfig2,'style','popupmenu','string',{'filter delay', 'SP-gyro delay', 'SP smoothing delay', 'phase shift'},'fontsize',fontsz,'TooltipString', ['Select which Delay Display'], 'units','normalized','Position',[posInfo.Delay],...
     'callback','PSplotSpec2D;');

guiHandlesSpec2.plotR =uicontrol(PSspecfig2,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotRspec], 'callback', 'delete(findobj(PSspecfig2,''Type'',''axes'')); set(PSspecfig2, ''pointer'', ''arrow'');');

guiHandlesSpec2.plotP =uicontrol(PSspecfig2,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotPspec], 'callback', 'delete(findobj(PSspecfig2,''Type'',''axes'')); set(PSspecfig2, ''pointer'', ''arrow'');');

guiHandlesSpec2.plotY =uicontrol(PSspecfig2,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotYspec], 'callback', 'delete(findobj(PSspecfig2,''Type'',''axes'')); set(PSspecfig2, ''pointer'', ''arrow'');');

guiHandlesSpec2.checkboxPSD =uicontrol(PSspecfig2,'Style','checkbox','String','PSD','fontsize',fontsz,'TooltipString', ['Power Spectral Density'],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.checkboxPSD],'callback', 'PSplotSpec2D;');
set(guiHandlesSpec2.checkboxPSD, 'Value', 1);

guiHandlesSpec2.RPYcomboSpec =uicontrol(PSspecfig2,'Style','checkbox','String','Single Panel','fontsize',fontsz,'TooltipString', ['Plot RPY in same panel '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.RPYcomboSpec],'callback', 'PSplotSpec2D;');

guiHandlesSpec2.climMax1_text = uicontrol(PSspecfig2,'style','text','string','Y min','fontsize',fontsz,'TooltipString',['Y min'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax1_text]);
guiHandlesSpec2.climMax1_input = uicontrol(PSspecfig2,'style','edit','string',[num2str(climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',['Y min'],'units','normalized','Position',[posInfo.climMax1_input],...
     'callback','@textinput_call2; climScale1(get(guiHandlesSpec2.checkboxPSD, ''Value'')+1, 1)=str2num(get(guiHandlesSpec2.climMax1_input, ''String''));PSplotSpec2D;');

 guiHandlesSpec2.climMax2_text = uicontrol(PSspecfig2,'style','text','string','Y max','fontsize',fontsz,'TooltipString',['Y max'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.climMax2_text]);
guiHandlesSpec2.climMax2_input = uicontrol(PSspecfig2,'style','edit','string',[num2str(climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',['Y max'],'units','normalized','Position',[posInfo.climMax2_input],...
     'callback','@textinput_call2; climScale2(get(guiHandlesSpec2.checkboxPSD, ''Value'')+1, 1)=str2num(get(guiHandlesSpec2.climMax2_input, ''String''));PSplotSpec2D;');


try set(guiHandlesSpec2.SpecList, 'Value', [defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-term1'))) defaults.Values(find(strcmp(defaults.Parameters, 'spec2D-term2')))]), catch, set(guiHandlesSpec2.SpecList, 'Value', [1 2]), end
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





