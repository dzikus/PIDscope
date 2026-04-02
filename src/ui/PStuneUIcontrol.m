%% PStuneUIcontrol - ui controls for tuning-specific parameters

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    
if exist('fnameMaster','var') && ~isempty(fnameMaster)

th = PStheme();
if exist('PStunefig','var') && ishandle(PStunefig)
    figure(PStunefig);
else
    PStunefig=figure(4);
    set(PStunefig, 'Position', round([0 0 screensz(3) screensz(4)]));
    try set(PStunefig, 'WindowState', 'maximized'); catch, end
    set(PStunefig, 'NumberTitle', 'on');
    set(PStunefig, 'Name', ['PIDscope (' PsVersion ') - Step Response Tool']);
    set(PStunefig, 'InvertHardcopy', 'off');
    set(PStunefig,'color',bgcolor);
end

updateStep=0;

TooltipString_steprun=['Runs step response analysis.',...
    newline, 'Warning: Set subsampling dropdown @ or < medium for faster processing.'];
TooltipString_minRate=['Input the minimum rate of rotation for calculating the step response (lower bound must be > 0 but lower than upper bound).',...
    newline, 'Really low values may yield more noisy contributions to the data, whereas higher values limit the total data used.',...
    newline, 'The default of 40deg/s should be sufficient in most cases, but if N is low, try setting this to lower'];
TooltipString_maxRate=['Input the maximum rate of rotation for for calculating the step response (upper bound must be greater than lower bound).',...
    newline, 'This also marks the lower bound for step resp plots associated with the ''snap maneuvers'' selection.',...
    newline, 'The default of 500deg/s is sufficient in most cases'];
TooltipString_FastStepResp=['Plots the step response associated with snap maneuvers, whose lower cutoff is defined by upper deg/s dropdown.',...
    newline, 'Note: this requires that the log contains maneuvers > the selected upper deg/s, else the plot is left blank']; 
TooltipString_fileListWindowStep=['List of files available. Click to select which files to run']; 
TooltipString_clearPlot=['Clears lines from all subplots']; 

if ~exist('fcntSR','var'), fcntSR = 0; end

clear posInfo.TparamsPos
plotR = cpL - 0.02;  plotLt = 0.07;  colGapT = 0.015;
% Col 1 = step response, Col 2 = PID text, Col 3 = peak, Col 4 = latency
totalW = plotR - plotLt;
colFracs = [0.42, 0.12, 0.23, 0.23];
usableW = totalW - 3*colGapT;
wCols = usableW * colFracs / sum(colFracs);
cols = zeros(1,4);
cols(1) = plotLt;
for ci = 2:4, cols(ci) = cols(ci-1) + wCols(ci-1) + colGapT; end
rows=[0.69 0.395 0.1];
k=0;
for c=1:4
    for r=1:3
        k=k+1;
        posInfo.TparamsPos(k,:)=[cols(c) rows(r) wCols(c) 0.245];
    end
end

% Control panel layout — cpL/cpW/rh/rs/ddh/cpM/cbW inherited from PIDscope.m (pixel-based)
% yTop tracks where TOP of next element goes; Position Y = yTop - height
listH_step = 8*rs;  gap = rs - rh;  fw = cpW-2*cpM;  hw = cpW/2-cpM;
tbOff_s4 = 40/screensz(4);
yTop = 1 - tbOff_s4 - cpTitleH - cpMv;
posInfo.fileListWindowStep=  [cpL+cpM yTop-listH_step fw listH_step]; yTop=yTop-listH_step-gap;
posInfo.run4=                [cpL+cpM yTop-rh hw rh];
posInfo.clearPlots=          [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.saveFig4=            [cpL+cpM yTop-rh hw rh];
posInfo.saveSettings4=       [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.period=              [cpL+cpM yTop-rh hw rh];
posInfo.markup=              [cpL+cpW/2 yTop-rh hw rh]; yTop=yTop-rh-gap;
posInfo.smooth_tuning=       [cpL+cpM yTop-ddh fw/2-gap ddh];
posInfo.srLatency=           [cpL+cpM+fw/2 yTop-ddh fw/2 ddh]; yTop=yTop-ddh-gap;
posInfo.subsample=           [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
w3_ = (fw - 2*gap) / 3;
posInfo.minRateTxt=          [cpL+cpM yTop-rhs w3_ rhs];
posInfo.minRateInput=        [cpL+cpM+w3_+gap yTop-rh w3_ rh];
posInfo.maxRateInput=        [cpL+cpM+2*(w3_+gap) yTop-rh w3_ rh]; yTop=yTop-rh-gap;
posInfo.snapManeuver=        [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.plotR=               [cpL+cpM yTop-rh cbW rh];
posInfo.plotP=               [cpL+cpM+cbW yTop-rh cbW rh];
posInfo.plotY=               [cpL+cpM+2*cbW yTop-rh cbW rh]; yTop=yTop-rh-gap;
posInfo.RPYcombo=            [cpL+cpM yTop-rh fw/2-gap rh];
posInfo.rawTraces=           [cpL+cpM+fw/2 yTop-rh fw/2 rh]; yTop=yTop-rh-gap;
posInfo.Ycorrection=         [cpL+cpM yTop-rh fw rh]; yTop=yTop-rh-gap;
posInfo.bfSliders=           [cpL+cpM yTop-ddh fw ddh]; yTop=yTop-ddh-gap;
posInfo.maxYStepInput=       [cpL+cpM yTop-rh cpW/3 rh];
posInfo.maxYStepTxt=         [cpL+cpW/3+cpM yTop-rhs cpW/2 rhs];

if ~exist('tuneCrtlpanel_init','var') || ~ishandle(guiHandlesTune.tuneCrtlpanel)
guiHandlesTune.tuneCrtlpanel = uipanel('Title','select files (max 10)','FontSize',fontsz,...
              'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
              'HighlightColor',panelBorder,...
              'Position',[cpL yTop-rh-gap cpW vPos-(yTop-rh-gap)+cpTitleH+cpMv]);

guiHandlesTune.run4 = uicontrol(PStunefig,'string','Run','fontsize',fontsz,'TooltipString',[TooltipString_steprun],'units','normalized','Position',[posInfo.run4],...
    'callback','updateStep = 0; PStuningParams;');
set(guiHandlesTune.run4, 'ForegroundColor', colRun);

guiHandlesTune.fileListWindowStep = uicontrol(PStunefig,'Style','listbox','string',[fnameMaster],'max',10,'min',1,...
    'fontsize',fontsz,'TooltipString', [TooltipString_fileListWindowStep],'units','normalized','Position', [posInfo.fileListWindowStep]);
set(guiHandlesTune.fileListWindowStep, 'Value', 1);

guiHandlesTune.saveFig4 = uicontrol(PStunefig,'string','Save Fig','fontsize',fontsz,'TooltipString',[TooltipString_saveFig],'units','normalized','Position',[posInfo.saveFig4],...
    'callback','set(guiHandlesTune.saveFig4, ''FontWeight'', ''bold'');PSsaveFig; set(guiHandlesTune.saveFig4, ''FontWeight'', ''normal'');');
set(guiHandlesTune.saveFig4, 'ForegroundColor', saveCol);

guiHandlesTune.saveSettings = uicontrol(PStunefig,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PIDscope defaults' ], 'units','normalized','Position',[posInfo.saveSettings4],...
    'callback','set(guiHandlesTune.saveSettings, ''FontWeight'', ''bold'');PSsaveSettings; set(guiHandlesTune.saveSettings, ''FontWeight'', ''normal'');');
set(guiHandlesTune.saveSettings, 'ForegroundColor', saveCol);

guiHandlesTune.period = uicontrol(PStunefig,'string','Period','fontsize',fontsz,'TooltipString', 'Click two points to measure period + frequency', 'units','normalized','Position',[posInfo.period],...
    'callback','PSstepPeriod(PStunefig);');
guiHandlesTune.markup = uicontrol(PStunefig,'string','Markup','fontsize',fontsz,'TooltipString', 'Clear period markers', 'units','normalized','Position',[posInfo.markup],...
    'callback','delete(findobj(PStunefig, ''Tag'', ''PSperiod''));');

guiHandlesTune.smoothFactor_select = uicontrol(PStunefig,'style','popupmenu','string',{'smoothin...' 'smooth low' 'smooth med' 'smooth high'},'fontsize',fontsz,'TooltipString', ['Smooth the gyro when step response traces are too noisy'], 'units','normalized','Position',[posInfo.smooth_tuning],...
     'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.smoothFactor_select, 'Value', 1);
guiHandlesTune.srLatency = uicontrol(PStunefig,'style','popupmenu','string',{'SR Latency' 'Xcorr Latency'},'fontsize',fontsz,'TooltipString', 'Latency measurement method', 'units','normalized','Position',[posInfo.srLatency],...
     'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');

guiHandlesTune.subsample = uicontrol(PStunefig,'style','popupmenu','string',{'sub auto' 'sub low (fastest)' 'sub med-low' 'sub medium' 'sub med-high' 'sub high (slowest)'},...
    'fontsize',fontsz,'TooltipString', [TooltipString_steprun], 'units','normalized','Position',[posInfo.subsample],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.subsample, 'Value', 1);

guiHandlesTune.minRateTxt = uicontrol(PStunefig,'style','text','string','deg/s','fontsize',fontsz,...
    'TooltipString', [TooltipString_minRate], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.minRateTxt]);
guiHandlesTune.minRateInput = uicontrol(PStunefig,'style','edit','string','40','fontsize',fontsz,...
    'TooltipString', [TooltipString_minRate], 'units','normalized','Position',[posInfo.minRateInput],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
guiHandlesTune.maxRateInput = uicontrol(PStunefig,'style','edit','string','500','fontsize',fontsz,...
    'TooltipString', [TooltipString_maxRate], 'units','normalized','Position',[posInfo.maxRateInput],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');

guiHandlesTune.snapManeuver = uicontrol(PStunefig,'Style','checkbox','String','Snap maneuvers','fontsize',fontsz,...
    'TooltipString', [TooltipString_FastStepResp], 'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.snapManeuver],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.snapManeuver, 'Value', 0);

guiHandlesTune.plotR =uicontrol(PStunefig,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisRoll,'Position',[posInfo.plotR],'callback', 'delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.plotR, 'Value', 1);

guiHandlesTune.plotP =uicontrol(PStunefig,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisPitch,'Position',[posInfo.plotP],'callback', 'delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.plotP, 'Value', 1);

guiHandlesTune.plotY =uicontrol(PStunefig,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisYaw,'Position',[posInfo.plotY],'callback', 'delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.plotY, 'Value', 1);

guiHandlesTune.clearPlots = uicontrol(PStunefig,'string','Reset','fontsize',fontsz,'TooltipString',[TooltipString_clearPlot],'units','normalized','Position',[posInfo.clearPlots],...
    'callback','set(guiHandlesTune.clearPlots, ''Value'', 1); set(guiHandlesTune.clearPlots, ''FontWeight'', ''bold''); fcntSR = 0; PStuningParams; set(guiHandlesTune.clearPlots, ''Value'', 0); set(guiHandlesTune.clearPlots, ''FontWeight'', ''normal''); set(PStunefig, ''pointer'', ''arrow'');'); 
set(guiHandlesTune.clearPlots, 'ForegroundColor', cautionCol);

guiHandlesTune.Ycorrection =uicontrol(PStunefig,'Style','checkbox','String','Y correction','fontsize',fontsz,'TooltipString', ['Y axis offset correction '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.Ycorrection],'callback', 'set(guiHandlesTune.clearPlots, ''Value'', 1); fcntSR = 0; PStuningParams; set(guiHandlesTune.clearPlots, ''Value'', 0); set(guiHandlesTune.clearPlots, ''FontWeight'', ''normal''); fcntSR = 0; updateStep = 0; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.Ycorrection, 'Value', 0);

guiHandlesTune.RPYcombo =uicontrol(PStunefig,'Style','checkbox','String','Single Panel','fontsize',fontsz,'TooltipString', ['Plot RPY in same panel '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.RPYcombo],'callback', 'delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.RPYcombo, 'Value', 0);

guiHandlesTune.rawTraces =uicontrol(PStunefig,'Style','checkbox','String','Raw','fontsize',fontsz,'TooltipString', ['Show individual segment traces'],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.rawTraces],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
set(guiHandlesTune.rawTraces, 'Value', 0);

guiHandlesTune.bfSliders =uicontrol(PStunefig,'Style','popupmenu','String',{'Peak-Latency' 'BF sliders'},'fontsize',fontsz,'TooltipString', ['Switch between Peak/Latency scatter and BF slider positions'],...
    'units','normalized','Position',[posInfo.bfSliders],...
    'callback','delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');

guiHandlesTune.maxYStepTxt = uicontrol(PStunefig,'style','text','string','Y max ','fontsize',fontsz,'TooltipString', ['Y scale max'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.maxYStepTxt]);
guiHandlesTune.maxYStepInput = uicontrol(PStunefig,'style','edit','string','1.75','fontsize',fontsz,'TooltipString', ['Y scale max'],'units','normalized','Position',[posInfo.maxYStepInput],...
     'callback','@textinput_call3; delete(findobj(PStunefig,''Type'',''axes'')); fcntSR = 0; updateStep = 1; PStuningParams; set(PStunefig, ''pointer'', ''arrow'');');
tuneCrtlpanel_init = true;
end % ishandle(tuneCrtlpanel)

% Register CP for fixed-pixel resize
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', 0);
cpI = {};
listH_step_px = 8*rs_px;
cpI{end+1} = struct('h', guiHandlesTune.tuneCrtlpanel, 'type','panel', 'row',0, 'col',0, 'hpx',0);
cpI{end+1} = struct('h', guiHandlesTune.fileListWindowStep, 'type','full', 'row',0, 'col',0, 'hpx',listH_step_px);
cpI{end+1} = struct('h', guiHandlesTune.run4, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.clearPlots, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.saveFig4, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.saveSettings, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.period, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.markup, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.smoothFactor_select, 'type','left', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesTune.srLatency, 'type','right', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesTune.subsample, 'type','full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesTune.minRateTxt, 'type','cb', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.minRateInput, 'type','cb', 'row',0, 'col',1, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.maxRateInput, 'type','cb_end', 'row',0, 'col',2, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.snapManeuver, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.plotR, 'type','cb', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.plotP, 'type','cb', 'row',0, 'col',1, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.plotY, 'type','cb_end', 'row',0, 'col',2, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.RPYcombo, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.rawTraces, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.Ycorrection, 'type','full', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.bfSliders, 'type','full', 'row',0, 'col',0, 'hpx',ddh_px);
cpI{end+1} = struct('h', guiHandlesTune.maxYStepInput, 'type','left', 'row',0, 'col',0, 'hpx',rh_px);
cpI{end+1} = struct('h', guiHandlesTune.maxYStepTxt, 'type','right', 'row',0, 'col',0, 'hpx',rh_px);
setappdata(PStunefig, 'PSplotGrid', struct('plotL',plotLt, 'colGap',colGapT, ...
    'ncols',4, 'rows',rows, 'rowH',0.245, 'margin',0.02, 'colWidthFracs',colFracs));
PSregisterResize(PStunefig, cpPx, cpI, 'seq');

try idx_=find(strcmp(defaults.Parameters,'StepResp-plotR')); if ~isempty(idx_), set(guiHandlesTune.plotR,'Value',defaults.Values(idx_)); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-plotP')); if ~isempty(idx_), set(guiHandlesTune.plotP,'Value',defaults.Values(idx_)); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-plotY')); if ~isempty(idx_), set(guiHandlesTune.plotY,'Value',defaults.Values(idx_)); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-SinglePanel')); if ~isempty(idx_), set(guiHandlesTune.RPYcombo,'Value',defaults.Values(idx_)); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-Ymax')); if ~isempty(idx_), set(guiHandlesTune.maxYStepInput,'String',num2str(defaults.Values(idx_))); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-Subsample')); if ~isempty(idx_), set(guiHandlesTune.subsample,'Value',defaults.Values(idx_)); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-MinRate')); if ~isempty(idx_), set(guiHandlesTune.minRateInput,'String',num2str(defaults.Values(idx_))); end, catch, end
try idx_=find(strcmp(defaults.Parameters,'StepResp-MaxRate')); if ~isempty(idx_), set(guiHandlesTune.maxRateInput,'String',num2str(defaults.Values(idx_))); end, catch, end

else
    warndlg('Please select file(s)');
end
PSstyleControls(PStunefig);

% functions
function textinput_call3(src,eventdata)
str=get(src,'String');
    if isnan(str2double(str))
        set(src,'string','0');
        warndlg('Input must be numerical');  
    end
end

% functions
function selection2(src,event)
    val = c.Value;
    str = c.String;
    str{val};
   % disp(['Selection: ' str{val}]);
end

