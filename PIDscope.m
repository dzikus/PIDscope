 %% PIDscope - main
%  script for main control panel and log viewer
%
% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
  

% Read version from VERSION file (generated from git tag)
try
  vfid = fopen(fullfile(fileparts(mfilename('fullpath')), 'VERSION'), 'r');
  PsVersion = ['v' strtrim(fgets(vfid))];
  fclose(vfid);
catch
  PsVersion = 'v0.0-dev';
end

%% Octave compatibility setup
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
  % Load required Octave packages (suppress warnings if already loaded)
  try pkg load signal; end
  try pkg load statistics; end
  try pkg load control; end
  try pkg load image; end
end

executableDir = fileparts(mfilename('fullpath'));
if isempty(executableDir), executableDir = pwd; end
addpath(executableDir);

% Add src/ and all subdirectories (core, ui, plot, util, compat) to path
src_dir = fullfile(executableDir, 'src');
if exist(src_dir, 'dir')
  addpath(genpath(src_dir));
end

setupStr = {'SET UP WORKING DIRECTORY!', ' ', 'Before running PIDscope, we have to determine the location of your ''main'' directory. After you click ''OK'', a navigator window will pop up.' , ['Simply Navigate to the location of your downloaded ''PIDscope_' PsVersion '\main\'' folder'], 'NOTE: Ideally, that folder and all of its contents should be placed on your desktop to avoid any issues!'};
resetupStr = {'RE-SET WORKING DIRECTORY!', ' ','Once you click ''OK'', a navigator window will pop up.' , ['Simply Navigate to the location of your downloaded ''PIDscope_' PsVersion '\main\'' folder'], 'NOTE: Ideally, that folder and all of its contents should be placed on your desktop to avoid any issues!'};

% Platform-specific config directory
if exist('/Users/Shared', 'dir')
    configDir = '/Users/Shared';
elseif ispc()
    appdata = getenv('APPDATA');
    if isempty(appdata), appdata = getenv('USERPROFILE'); end
    if isempty(appdata), appdata = executableDir; end
    configDir = fullfile(appdata, 'PIDscope');
    if ~exist(configDir, 'dir'), mkdir(configDir); end
else
    homeDir = getenv('HOME');
    if isempty(homeDir), homeDir = executableDir; end
    configDir = fullfile(homeDir, '.config', 'PIDscope');
    if ~exist(configDir, 'dir'), mkdir(configDir); end
end
cd(configDir)
if isempty(dir(['mainDir-PS' PsVersion '.txt']))
    % Auto-detect if blackbox_decode is in executableDir (e.g. AppImage)
    if exist(fullfile(executableDir, 'blackbox_decode'), 'file') || exist(fullfile(executableDir, 'blackbox_decode.exe'), 'file')
        main_directory = executableDir;
    else
        uiwait(helpdlg(setupStr));
        main_directory = uigetdir('Navigate to Main folder');
    end
    fid = fopen(['mainDir-PS' PsVersion '.txt'],'w');
    fprintf(fid,'%s\n',main_directory);
    fclose(fid);
end


%%%%%%%%%% debug mode defaults (BF 4.x) — overridden per-file by debugIdx{k} after loading
GYRO_SCALED = 6;
RC_INTERPOLATION = 7;
FEEDFORWARD = 59;
FFT_FREQ = 17;
debugIdx = {};
fwType = {};
fwMajor = [];
fwMinor = [];
gyro_debug_axis = [];

t = now;
currentDate = datestr(t, 'yyyy-mm-dd HH:MM:SS'); % Octave compatible (was: datetime)
currentDate = currentDate(1:strfind(currentDate,' ')-1);

set(0,'defaultUicontrolFontName', 'Helvetica')
% defaultUicontrolFontSize is set after fontsz is calculated (below)

%%%% assign main figure handle and define some UI variables
PSfig = figure(1);
drawnow;  % flush Qt event queue so figure is mapped before setting Position
set(PSfig, 'InvertHardcopy', 'off');
th = PStheme();
bgcolor = th.figBg;
panelBg = th.panelBg;
panelFg = th.panelFg;
panelBorder = th.panelBorder;
set(PSfig,'color',bgcolor);

wikipage = 'https://buymeacoffee.com/dzikus';

if ~exist('filenameA','var'), filenameA={}; end

expandON=0;
use_randsamp=0;
smp_sze=100;
choose_epoch=0;
epoch1_A=[];
epoch2_A=[];
tIND = [];
maxY =  500;
nLineCols = 8; multiLineCols=PSlinecmap(nLineCols);
updateSpec=0;
debugmode=0;%default to none
Nfiles=0;
fcnt=0;
filepathA=[];
filenameA={};

hexpand = {[], [], []};

errmsg=[];

plotall_flag=-1;

colorA = th.btnDash1;
colorB = th.btnDash2;
colorC=[1 .2 .2];
colorD=[.1 .7 .2];

colRun = th.btnRun;
saveCol = th.btnSave;
setUpCol = th.textSecondary;
cautionCol = th.btnReset;
%use_phsCorrErr=0;
flightSpec=0;
screensz = get(0,'ScreenSize');
% Octave Qt bug: setting figure units to 'normalized' permanently breaks uipanel
% Calculate pixel position manually instead
set(PSfig, 'Position', round([0 0 screensz(3) screensz(4)]));
try set(PSfig, 'WindowState', 'maximized'); catch, end
set(PSfig, 'NumberTitle', 'off');
set(PSfig, 'Name', ['PIDscope (' PsVersion ') - Log Viewer']);
drawnow; pause(0.2);
% Use ACTUAL figure size (accounts for dock/panel/taskbar)
figPos = get(PSfig, 'Position');
screensz(3) = figPos(3); screensz(4) = figPos(4);

th = PStheme();
fontsz = th.fontsz;
screensz_multiplier = screensz(4) * .011;
% Octave font scaling is done below in layout section
markerSz = round(screensz_multiplier * 0.75);

% CP dimensions — all derived from pixel sizes, then normalized
cpW_px = 200; rh_px = 22; rs_px = 24; cpM_px = 5; cpTitle_px = 28;
ddh_px = 28;   % dropdown height (taller than button)
cbW_px = 40;   % checkbox column width
rhs_px = 16;   % small text row height
infoH_px = 100; % info table height
if isOctave
    rh_px = 26; rs_px = 30; ddh_px = 32; rhs_px = 18;
end
cpW = cpW_px / screensz(3);
cpL = 1 - cpW - cpM_px/screensz(3);
rh = rh_px / screensz(4);
rs = rs_px / screensz(4);
cpM = cpM_px / screensz(3);   % horizontal margin
cpMv = cpM_px / screensz(4);  % vertical margin
cpTitleH = cpTitle_px / screensz(4);
cbW = cbW_px / screensz(3);
ddh = ddh_px / screensz(4);
rhs = rhs_px / screensz(4);
tbOff = 40 / screensz(4);    % figure toolbar offset
vPos = 1 - tbOff - cpTitleH - cpMv;   % top of first row (below toolbar + title bar)
set(0,'defaultUicontrolFontSize', fontsz)
set(0,'defaultUicontrolForegroundColor', th.textPrimary)
set(0,'defaultUicontrolBackgroundColor', th.panelBg)

row = 1;
posInfo.firmware =      [cpL+cpM   vPos-rs*row  cpW-2*cpM  rh]; row=row+1;
posInfo.fileA=          [cpL+cpM   vPos-rs*row  cpW/2-cpM rh];
posInfo.clr=            [cpL+cpW/2 vPos-rs*row  cpW/2-cpM rh]; row=row+1;
posInfo.fnameAText =    [cpL+cpM   vPos-rs*row  cpW-2*cpM  rh]; row=row+1;
posInfo.startEndButton= [cpL+cpM   vPos-rs*row  cpW/2-cpM  rh];
posInfo.RPYcomboLV =    [cpL+cpW/2 vPos-rs*row  cpW/2-cpM  rh]; row=row+1;
LogStDefault = 2;
LogNdDefault = 1;
posInfo.plotR_LV =      [cpL+cpM        vPos-rs*row  cbW rh];
posInfo.plotP_LV =      [cpL+cpM+cbW    vPos-rs*row  cbW rh];
posInfo.plotY_LV =      [cpL+cpM+2*cbW  vPos-rs*row  cbW rh]; row=row+1;
posInfo.lineSmooth =    [cpL+cpM   vPos-rs*row  cpW/2-cpM  rh];
posInfo.linewidth =     [cpL+cpW/2 vPos-rs*row  cpW/2-cpM  rh]; row=row+1;
posInfo.spectrogramButton = [cpL+cpM vPos-rs*row cpW-2*cpM rh]; row=row+1;
posInfo.TuningButton =  [cpL+cpM   vPos-rs*row  cpW-2*cpM  rh]; row=row+1;
posInfo.PIDsliderButton=[cpL+cpM   vPos-rs*row  cpW-2*cpM  rh]; row=row+1;
posInfo.filterSimButton=[cpL+cpM   vPos-rs*row  cpW/2-cpM  rh];
posInfo.testSignalButton=[cpL+cpW/2 vPos-rs*row cpW/2-cpM  rh]; row=row+1;
posInfo.PIDErrorButton = [cpL+cpM  vPos-rs*row  cpW/2-cpM  rh];
posInfo.FlightStatsButton=[cpL+cpW/2 vPos-rs*row cpW/2-cpM rh]; row=row+1;
posInfo.period2Hz =     [cpL+cpM   vPos-rs*row  cpW/2-cpM  rh];
posInfo.DispInfoButton =[cpL+cpW/2 vPos-rs*row  cpW/2-cpM  rh]; row=row+1;
posInfo.saveFig =       [cpL+cpM   vPos-rs*row  cpW/2-cpM  rh];
posInfo.saveSettings =  [cpL+cpW/2 vPos-rs*row  cpW/2-cpM  rh]; row=row+1;
posInfo.PIDtuningService = [cpL+cpM vPos-rs*row cpW-2*cpM  rh];
cpH = rs*row + cpTitleH + cpMv;  % small padding below last button
controlpanel = uipanel('Title','Control Panel','FontSize',fontsz,...
             'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
             'HighlightColor',panelBorder,...
             'Position',[cpL vPos-cpH+cpTitleH cpW cpH]);



fnameMaster = {}; 
fcnt = 0;

ColorSet=[th.sigDebug;...     % Debug
  th.sigGyro;...              % Gyro
  th.sigPterm;...             % Pterm
  th.sigIterm;...             % Iterm
  th.sigDprefilt;...          % Dterm prefilt
  th.sigDterm;...             % Dterm
  th.sigFterm;...             % Fterm
  th.sigSetpoint;...          % Setpoint
  th.sigPIDsum;...            % PIDsum
  th.sigPIDerr;...            % PIDerr
  th.sigMotor{1};...          % M1
  th.sigMotor{2};...          % M2
  th.sigMotor{3};...          % M3
  th.sigMotor{4};...          % M4
  th.sigThrottle;...          % Throttle
  th.textPrimary];            % All
for k=0:15
    linec.(['col' int2str(k)]) = ColorSet(k+1,:);
end
linec.colGyroPF = th.sigGyroPrefilt;

%%% tooltips
TooltipString_files=['Select the .BBL or .BFL file you wish to analyze. '];

TooltipString_loadRun=['Select one or more files to analyze. '];
TooltipString_Epochs=['Input the desired start and end points (in seconds) of the selected log file' , newline, 'Note: the selected time window denotes the data used for all other analyses.' , newline, 'The shaded regions indicate ignored data.'];
TooltipString_spec=['Opens spectral analysis tool in new window'];
TooltipString_step=['Opens step response tool in new window'];
TooltipString_setup=['Displays detailed setup information in new window'];
TooltipString_saveFig=['Saves current figure', newline,'Note: Clicking the ''Save fig'' button for the first time creates a folder using the log file names'];
TooltipString_wiki=['Link to the PIDscope project page'];
TooltipString_selectButton = ['With box checked, position mouse over desired start position,' , newline, 'then mouse click, then desired end position, then mouse click again;' , newline, 'to escape, deselect then click anywhere'];


%%%

guiHandles.Firmware = uicontrol(PSfig,'Style','popupmenu','string',[{'Betaflight logfiles'; 'Emuflight logfiles'; 'INAV logfiles'; 'FETTEC logfiles'; 'QuickSilver logfiles'; 'Rotorflight logfiles'; 'KISS Ultra logfiles'; 'ArduPilot logfiles'}], 'fontsize',fontsz, 'units','normalized','Position', [posInfo.firmware]);

guiHandles.fileA = uicontrol(PSfig,'string','Select ','fontsize',fontsz,'TooltipString', [TooltipString_loadRun], 'units','normalized','Position',[posInfo.fileA],...
     'callback','set(guiHandles.fileA, ''FontWeight'', ''Bold''); fwv=get(guiHandles.Firmware,''Value''); if fwv==5, filt={''*.json;*.btfl;*.BTFL;*.bbl;*.BBL;*.bfl;*.BFL;*.txt;*.TXT'',''QuickSilver Log Files''}; elseif fwv==8, filt={''*.bin;*.BIN;*.log;*.LOG'',''ArduPilot Log Files''}; else filt={''*.bbl;*.BBL;*.bfl;*.BFL;*.txt;*.TXT'',''Blackbox Log Files''}; end; [filenameA, filepathA] = PSuigetfile(filt, ''Select log file'', logfile_directory, ''MultiSelect'',''on''); if ischar(filenameA), filenameA={filenameA}; end; if iscell(filenameA), PSload; PSviewerUIcontrol; PSplotLogViewer; end');
set(guiHandles.fileA, 'ForegroundColor', colRun);

guiHandles.clr = uicontrol(PSfig,'string','Reset','fontsize',fontsz,'TooltipString', ['clear all data'], 'units','normalized','Position',[posInfo.clr],...
     'callback','PSresetData;');
set(guiHandles.clr, 'ForegroundColor', cautionCol);

guiHandles.startEndButton = uicontrol(PSfig,'style','checkbox', 'string','Trim ','fontsize',fontsz,'TooltipString', [TooltipString_selectButton], 'units','normalized','Position',[posInfo.startEndButton],...
    'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA) && get(guiHandles.startEndButton, ''Value''), try, [x y] = ginput(1); epoch1_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; [x y] = ginput(1); epoch2_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; catch, end, end');

guiHandles.plotR =uicontrol(PSfig,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisRoll,'Position',[posInfo.plotR_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.plotP =uicontrol(PSfig,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisPitch,'Position',[posInfo.plotP_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.plotY =uicontrol(PSfig,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'ForegroundColor',th.axisYaw,'Position',[posInfo.plotY_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.RPYcomboLV=uicontrol(PSfig,'Style','checkbox','String','Single Panel','fontsize',fontsz,'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.RPYcomboLV],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.FileNum = uicontrol(PSfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz, 'units','normalized','Position', [posInfo.fnameAText]);
set(guiHandles.FileNum, 'String', ' ');

guiHandles.lineSmooth = uicontrol(PSfig,'Style','popupmenu','string',{'line smooth off','line smooth low','line smooth med','line smooth med-high','line smooth high'},...
    'fontsize',fontsz,'TooltipString', ['zero-phase filter lines'], 'units','normalized','Position', [posInfo.lineSmooth],'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), expandON=0; PSplotLogViewer; end');

guiHandles.linewidth = uicontrol(PSfig,'Style','popupmenu','string',{'line width 1','line width 2','line width 3','line width 4','line width 5'},...
    'fontsize',fontsz, 'TooltipString', ['line thickness'], 'units','normalized','Position', [posInfo.linewidth],'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), expandON=0; PSplotLogViewer; end');

guiHandles.spectrogramButton = uicontrol(PSfig,'Style', 'pushbutton','string','Spectral Analyzer','fontsize',fontsz,'TooltipString', [TooltipString_spec],'units','normalized','Position',[posInfo.spectrogramButton],...
    'callback','PSspec2DUIcontrol;');
set(guiHandles.spectrogramButton, 'ForegroundColor', colorA);

guiHandles.TuningButton = uicontrol(PSfig,'string','Step Resp Tool','fontsize',fontsz,'TooltipString', [TooltipString_step],'units','normalized','Position',[posInfo.TuningButton],...
    'callback','PStuneUIcontrol');
set(guiHandles.TuningButton, 'ForegroundColor', colorB);

guiHandles.PIDsliderButton = uicontrol(PSfig,'string','PID Slider Tool','fontsize',fontsz,...
    'TooltipString','Interactive PID ratio calculator','units','normalized',...
    'Position',[posInfo.PIDsliderButton],...
    'callback',['try,' ...
        'tmpFcnt=get(guiHandles.FileNum,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'PSsliderTool(rollPIDF{tmpFcnt},pitchPIDF{tmpFcnt},yawPIDF{tmpFcnt});' ...
        'clear tmpFcnt;' ...
    'catch,' ...
        'PSsliderTool();' ...
    'end']);
set(guiHandles.PIDsliderButton, 'ForegroundColor', th.btnDash3);

guiHandles.filterSimButton = uicontrol(PSfig,'string','Filter Simulator','fontsize',fontsz,...
    'TooltipString','Simulate BF filter chain (theoretical response)','units','normalized',...
    'Position',[posInfo.filterSimButton],...
    'callback',['if ~exist(''A_lograte'',''var''),warndlg(''Please select file(s)'');' ...
        'else,tmpFcnt=get(guiHandles.FileNum,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'PSfilterSim([],1000*A_lograte(tmpFcnt),SetupInfo{tmpFcnt});' ...
        'clear tmpFcnt;end']);
set(guiHandles.filterSimButton, 'ForegroundColor', th.btnDash4);

guiHandles.testSignalButton = uicontrol(PSfig,'string','Test Signal','fontsize',fontsz,...
    'TooltipString','Configure and apply offline filter chain to log data','units','normalized',...
    'Position',[posInfo.testSignalButton],...
    'callback',['if ~exist(''T'',''var''),warndlg(''Please select file(s)'');' ...
        'else,tmpFcnt=get(guiHandles.FileNum,''Value'');tmpFcnt=tmpFcnt(1);' ...
        'PSTestSignalConfig(PSfig,T,Nfiles,A_lograte,SetupInfo,guiHandles,tIND);' ...
        'clear tmpFcnt;end']);
set(guiHandles.testSignalButton, 'ForegroundColor', th.btnDash5);

guiHandles.PIDErrorButton = uicontrol(PSfig,'string','PID Error','fontsize',fontsz,'TooltipString', ['PID error distribution analysis'],'units','normalized','Position',[posInfo.PIDErrorButton],...
    'callback','PSerrUIcontrol; PSplotPIDerror;');
set(guiHandles.PIDErrorButton, 'ForegroundColor', th.btnDash6);

guiHandles.FlightStatsButton = uicontrol(PSfig,'string','Flight Stats','fontsize',fontsz,'TooltipString', ['Flight statistics and stick analysis'],'units','normalized','Position',[posInfo.FlightStatsButton],...
    'callback','PSstatsUIcontrol; PSplotStats;');
set(guiHandles.FlightStatsButton, 'ForegroundColor', th.btnDash7);

guiHandles.period2Hz = uicontrol(PSfig,'string','Period','fontsize',fontsz,'TooltipString', ['Click two points on any trace to measure period and frequency.' , newline, 'Red vertical lines + ms/Hz annotation on all axes.'], 'units','normalized','Position',[posInfo.period2Hz],...
     'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), PSlogViewerPeriod(PSfig); end');

guiHandles.DispInfoButton = uicontrol(PSfig,'string','Setup Info','fontsize',fontsz,'TooltipString', [TooltipString_setup],'units','normalized','Position',[posInfo.DispInfoButton],...
    'callback','PSdispSetupInfoUIcontrol;PSdispSetupInfo;');
set(guiHandles.DispInfoButton, 'ForegroundColor', setUpCol);

guiHandles.saveFig = uicontrol(PSfig,'string','Save Fig','fontsize',fontsz, 'TooltipString',[TooltipString_saveFig], 'units','normalized','Position',[posInfo.saveFig],...
    'callback','set(guiHandles.saveFig, ''FontWeight'', ''bold'');PSsaveFig; set(guiHandles.saveFig, ''FontWeight'', ''normal'');'); 
set(guiHandles.saveFig, 'ForegroundColor', saveCol);

guiHandles.saveSettings = uicontrol(PSfig,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PIDscope defaults' ], 'units','normalized','Position',[posInfo.saveSettings],...
    'callback','set(guiHandles.saveSettings, ''FontWeight'', ''bold'');PSsaveSettings; set(guiHandles.saveSettings, ''FontWeight'', ''normal'');'); 
set(guiHandles.saveSettings, 'ForegroundColor', saveCol);

% guiHandles.wiki = uicontrol(PSfig,'string','User Guide','fontsize',fontsz,'FontName','arial','FontAngle','normal','TooltipString', [TooltipString_wiki],'units','normalized','Position',[posInfo.wiki],...
%     'callback','web(wikipage);'); 
% guiHandles.wiki.ForegroundColor=[cautionCol];

guiHandles.PIDtuningService = uicontrol(PSfig,'string','Support PIDscope','fontsize',fontsz ,'FontName','arial','FontAngle','normal','TooltipString', ['https://buymeacoffee.com/dzikus'],'units','normalized','Position',[posInfo.PIDtuningService],...
    'callback','if ispc(), system(''start https://buymeacoffee.com/dzikus''); elseif ismac(), system(''open https://buymeacoffee.com/dzikus''); else, system(''env -u LD_LIBRARY_PATH -u LD_PRELOAD xdg-open https://buymeacoffee.com/dzikus &''); end');
set(guiHandles.PIDtuningService, 'ForegroundColor', cautionCol);


 
 

rdr = ['rootDirectory: ' executableDir];
try
    fid = fopen(['mainDir-PS' PsVersion '.txt'],'r');
    main_directory = fscanf(fid, '%s');
    fclose(fid);
catch
end
if ~exist('main_directory','var') || isempty(main_directory) || ~exist(main_directory,'dir') ...
        || (~exist(fullfile(main_directory, 'blackbox_decode'), 'file') && ~exist(fullfile(main_directory, 'blackbox_decode.exe'), 'file'))
    main_directory = executableDir;
end

% Store decoder paths globally so PSgetcsv can use absolute paths
if ispc()
    setappdata(0, 'PSdecoderPath', fullfile(main_directory, 'blackbox_decode.exe'));
    setappdata(0, 'PSdecoderPathINAV', fullfile(main_directory, 'blackbox_decode_INAV.exe'));
else
    setappdata(0, 'PSdecoderPath', fullfile(main_directory, 'blackbox_decode'));
    setappdata(0, 'PSdecoderPathINAV', fullfile(main_directory, 'blackbox_decode_INAV'));
end

cd(configDir)

try
    fid = fopen('logfileDir.txt','r');
    logfile_directory = fscanf(fid, '%c');
    fclose(fid);
catch
    logfile_directory = getenv('HOME');
    if isempty(logfile_directory), logfile_directory = executableDir; end
end
    
mdr = ['mainDirectory: ' main_directory ];
ldr = ['logfileDirectory: ' logfile_directory ];


drawnow; pause(0.2);
try
    defaults = readtable('PSdefaults.txt');
catch
    defaults = ' ';
end


try set(guiHandles.Firmware, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'firmware')))), catch, set(guiHandles.Firmware, 'Value', 1), end
try set(guiHandles.RPYcomboLV, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-SinglePanel')))), catch, set(guiHandles.RPYcomboLV, 'Value', 0), end
try set(guiHandles.plotR, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotR')))), catch, set(guiHandles.plotR, 'Value', 1), end
try set(guiHandles.plotP, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotP')))), catch, set(guiHandles.plotP, 'Value', 1), end
try set(guiHandles.plotY, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotY')))), catch, set(guiHandles.plotY, 'Value', 1), end
try set(guiHandles.lineSmooth, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-lineSmooth')))), catch, set(guiHandles.lineSmooth, 'Value', 1), end
try set(guiHandles.linewidth, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-lineWidth')))), catch, set(guiHandles.linewidth, 'Value', 3), end

% Force Octave Qt to do a full layout pass so widgets render at correct size
if isOctave
    drawnow;
    tmpPos = get(PSfig, 'Position');
    set(PSfig, 'Position', tmpPos + [0 0 1 0]);
    drawnow;
    set(PSfig, 'Position', tmpPos);
    drawnow;
end
PSstyleControls(PSfig, th);

% Register CP elements for resize — keeps fixed pixel sizes when window changes
cpPx = struct('cpW', cpW_px, 'cpM', cpM_px, 'rh', rh_px, 'rs', rs_px, ...
              'ddh', ddh_px, 'cbW', cbW_px, 'rhs', rhs_px, 'cpTitle', cpTitle_px, 'infoH', infoH_px);
cpItems = {};
cpItems{end+1} = struct('h', guiHandles.Firmware, 'type','full', 'row',1, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.fileA, 'type','left', 'row',2, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.clr, 'type','right', 'row',2, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.FileNum, 'type','full', 'row',3, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.startEndButton, 'type','left', 'row',4, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.RPYcomboLV, 'type','right', 'row',4, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.plotR, 'type','cb', 'row',5, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.plotP, 'type','cb', 'row',5, 'col',1, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.plotY, 'type','cb', 'row',5, 'col',2, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.lineSmooth, 'type','left', 'row',6, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.linewidth, 'type','right', 'row',6, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.spectrogramButton, 'type','full', 'row',7, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.TuningButton, 'type','full', 'row',8, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.PIDsliderButton, 'type','full', 'row',9, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.filterSimButton, 'type','left', 'row',10, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.testSignalButton, 'type','right', 'row',10, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.PIDErrorButton, 'type','left', 'row',11, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.FlightStatsButton, 'type','right', 'row',11, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.period2Hz, 'type','left', 'row',12, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.DispInfoButton, 'type','right', 'row',12, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.saveFig, 'type','left', 'row',13, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.saveSettings, 'type','right', 'row',13, 'col',0, 'nrows',0);
cpItems{end+1} = struct('h', guiHandles.PIDtuningService, 'type','full', 'row',14, 'col',0, 'nrows',0);
nrows = max(cellfun(@(x) x.row, cpItems));
cpItems = [{struct('h', controlpanel, 'type','panel', 'row',0, 'col',0, 'nrows',nrows)}, cpItems];
PSregisterResize(PSfig, cpPx, cpItems, 'rows');
