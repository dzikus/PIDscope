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
else
    configDir = fullfile(getenv('HOME'), '.config', 'PIDscope');
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
set(PSfig, 'InvertHardcopy', 'off');
bgcolor=[.95 .95 .95];
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

hexpand1=[];
hexpand2=[];
hexpand3=[];

errmsg=[];

plotall_flag=-1;

colorA=[.8 .1 .2];
colorA2=[.4 .0 .6];
colorB=[.1 .4 .8];
colorC=[1 .2 .2];
colorD=[.1 .7 .2];

colRun = [0 .5 0];
saveCol = [.1 .1 .1];
setUpCol = [.1 .1 .1];
cautionCol = [0.6    0.3    0];
%use_phsCorrErr=0;
flightSpec=0;
screensz = get(0,'ScreenSize');
screensz(3) = round(1.78 * screensz(4)); % force 16:9


% Octave Qt bug: setting figure units to 'normalized' permanently breaks uipanel
% Calculate pixel position manually instead
figPos = round([.1*screensz(3) .1*screensz(4) .75*screensz(3) .8*screensz(4)]);
set(PSfig, 'Position', figPos);
set(PSfig, 'NumberTitle', 'off');
set(PSfig, 'Name', ['PIDscope (' PsVersion ') - Log Viewer']);

pause(.1)% need to wait for figure to open before extracting screen values

screensz_multiplier = sqrt(screensz(4)^2) * .011; % based on vertical dimension only, to deal with for ultrawide monitors
prop_max_screen = figPos(4) / screensz(4);
fontsz = (screensz_multiplier*prop_max_screen);
% Octave font scaling is done below in layout section
markerSz = round(screensz_multiplier * 0.75);
vPos = 0.92;
cpL = .875; % control panel left edge
cpW = .12;  % control panel width
rs = 0.025; % row step (vertical spacing between elements)
rh = 0.026; % row height
if isOctave
    fontsz = fontsz * 0.85;
    rs = 0.034; rh = 0.030;
end
set(0,'defaultUicontrolFontSize', fontsz)

row = 1;
posInfo.firmware =[cpL+.003 vPos-rs*row cpW-.006 rh]; row=row+1;
posInfo.fileA=[cpL+.006 vPos-rs*row cpW/2-.006 rh];
posInfo.clr=[cpL+cpW/2 vPos-rs*row cpW/2-.006 rh]; row=row+1;
posInfo.fnameAText = [cpL+.003 vPos-rs*row cpW-.006 rh]; row=row+1;
posInfo.startEndButton=[cpL+.005 vPos-rs*row cpW/2-.005 rh];
posInfo.RPYcomboLV = [cpL+cpW/2 vPos-rs*row cpW/2-.003 rh]; row=row+1;
LogStDefault = 2;% default ignore first 2 seconds of logfile
LogNdDefault = 1;% default ignore last 1 second of logfile
posInfo.plotR_LV =  [cpL+.005 vPos-rs*row .035 rh];
posInfo.plotP_LV =  [cpL+.04 vPos-rs*row .035 rh];
posInfo.plotY_LV =  [cpL+.075 vPos-rs*row .035 rh]; row=row+1;
posInfo.lineSmooth = [cpL+.003 vPos-rs*row cpW/2-.003 rh];
posInfo.linewidth = [cpL+cpW/2 vPos-rs*row cpW/2-.003 rh]; row=row+1;
posInfo.spectrogramButton = [cpL+.003 vPos-rs*row cpW-.006 rh]; row=row+1;
posInfo.TuningButton = [cpL+.003 vPos-rs*row cpW-.006 rh]; row=row+1;
posInfo.period2Hz = [cpL+.003 vPos-rs*row cpW/2-.003 rh];
posInfo.DispInfoButton = [cpL+cpW/2 vPos-rs*row cpW/2-.003 rh]; row=row+1;
posInfo.saveFig = [cpL+.003 vPos-rs*row cpW/2-.003 rh];
posInfo.saveSettings = [cpL+cpW/2 vPos-rs*row cpW/2-.003 rh]; row=row+1;
%posInfo.wiki = [cpL+.003 vPos-rs*row cpW/2-.003 rh];
posInfo.PIDtuningService = [cpL+.003 vPos-rs*row cpW-.006 rh];
cpH = rs*row + 0.04; % control panel height = rows + title margin
controlpanel = uipanel('Title','Control Panel','FontSize',fontsz,...
             'BackgroundColor',[.95 .95 .95],...
             'Position',[cpL vPos-cpH+0.02 cpW cpH]);

% Position info table just below control panel
cpBottom = vPos - cpH + 0.02;
infoTableH = 0.30;
infoTableY = cpBottom - infoTableH - 0.01;
infoTablePos = [cpL infoTableY cpW infoTableH];
posInfo.resetMain = [cpL+.003 infoTableY - rh - 0.005 cpW-.006 rh];


fnameMaster = {}; 
fcnt = 0;

% ColorSet=colormap(jet);%hsv jet gray lines colorcube
% j=[1     8    17    20    23    27   45    50    58    64];
ColorSet=[.6 .6 .6;..., % gray - Gyro raw
  0   0  0;..., % black - Gyro filt
  0  .7  0;..., % green - Pterm
 .8  .65 .1;..., % yellow - I term
 .3  .7  .9;..., % light blue - Dterm raw
 .1  .2  .8;..., % dark blue -Dterm Filt
 .6  .3  .3;..., % brown - Fterm 
 .8  0  .2;..., % dark red
 1  .2  .9;..., % light purple
 .4 0 .9;...,    % dark purple
 .9 0 0;..., %M1 
 1  .6 0;..., %M2
0  0 .9;..., %M3
.1  1  .8;..., %M4
 0 0 0;..., % throttle
 0 0 0]; % all
j=[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];

k=1;
for i=1:length(j)
    eval(['linec.col' int2str(k-1) '=ColorSet(j(i),:);']);
    k=k+1;
end

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

guiHandles.Firmware = uicontrol(PSfig,'Style','popupmenu','string',[{'Betaflight logfiles'; 'Emuflight logfiles'; 'INAV logfiles'; 'FETTEC logfiles'; 'QuickSilver logfiles'; 'Rotorflight logfiles'}], 'fontsize',fontsz, 'units','normalized','Position', [posInfo.firmware]);

guiHandles.fileA = uicontrol(PSfig,'string','Select ','fontsize',fontsz,'TooltipString', [TooltipString_loadRun], 'units','normalized','Position',[posInfo.fileA],...
     'callback','set(guiHandles.fileA, ''FontWeight'', ''Bold''); fwv=get(guiHandles.Firmware,''Value''); if fwv==5, filt={''*.json;*.btfl;*.BTFL;*.bbl;*.BBL;*.bfl;*.BFL;*.txt;*.TXT'',''QuickSilver Log Files''}; else filt={''*.bbl;*.BBL;*.bfl;*.BFL;*.txt;*.TXT'',''Blackbox Log Files''}; end; [filenameA, filepathA] = PSuigetfile(filt, ''Select log file'', logfile_directory, ''MultiSelect'',''on''); if ischar(filenameA), filenameA={filenameA}; end; if iscell(filenameA), PSload; PSviewerUIcontrol; PSplotLogViewer; end');
set(guiHandles.fileA, 'ForegroundColor', colRun);

guiHandles.clr = uicontrol(PSfig,'string','Reset','fontsize',fontsz,'TooltipString', ['clear all data'], 'units','normalized','Position',[posInfo.clr],...
     'callback','clear T dataA tta A_lograte epoch1_A epoch2_A SetupInfo rollPIDF pitchPIDF yawPIDF filenameA fnameMaster loaded_firmware debugmode debugIdx fwType fwMajor fwMinor gyro_debug_axis notchData; fcnt = 0; filenameA={};fnameMaster = {}; try, delete(subplot(''position'',posInfo.linepos1)); delete(subplot(''position'',posInfo.linepos2)); delete(subplot(''position'',posInfo.linepos3)); delete(subplot(''position'',posInfo.linepos4)); catch, end; set(guiHandles.FileNum, ''String'', '' ''); try, set(guiHandles.Epoch1_A_Input, ''String'', '' ''); set(guiHandles.Epoch2_A_Input, ''String'', '' ''); catch, end;');
set(guiHandles.clr, 'ForegroundColor', cautionCol);

guiHandles.startEndButton = uicontrol(PSfig,'style','checkbox', 'string','Trim ','fontsize',fontsz,'TooltipString', [TooltipString_selectButton], 'units','normalized','Position',[posInfo.startEndButton],...
    'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA) && get(guiHandles.startEndButton, ''Value''), try, [x y] = ginput(1); epoch1_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; [x y] = ginput(1); epoch2_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; catch, end, end');

guiHandles.plotR =uicontrol(PSfig,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotR_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.plotP =uicontrol(PSfig,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotP_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

guiHandles.plotY =uicontrol(PSfig,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotY_LV], 'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

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

guiHandles.period2Hz = uicontrol(PSfig,'string','Period','fontsize',fontsz,'TooltipString', ['Calculates peak to peak in Hz similar to the BBE ''Mark'' tool' , newline, 'press button, position mouse over 1st peak, mouse click,' , newline, 'then position over 2nd peak, then mouse click again'], 'units','normalized','Position',[posInfo.period2Hz],...
     'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA) && get(guiHandles.period2Hz, ''Value''), try, [x1 y1] = ginput(1); figure(PSfig); h=plot([x1 x1],[-(maxY*2) maxY],''-r'');set(h,''linewidth'' , get(guiHandles.linewidth, ''Value'')/2);  [x2 y2] = ginput(1); h=plot([x2 x2],[-(maxY*2) maxY],''-r''); set(h,''linewidth'' , get(guiHandles.linewidth, ''Value'')/2); plot([x1 x2],[y1 y2],'':k''); x3=[round(x1*1000) round(x2*1000)]; f = 1000/(x3(2)-x3(1)); text(x2, y2, [num2str(x3(2)-x3(1)) ''ms, '' num2str(f) ''Hz''],''FontSize'',fontsz, ''FontWeight'', ''Bold''); catch, end, end');      

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
    'callback','web(''https://buymeacoffee.com/dzikus'');');
set(guiHandles.PIDtuningService, 'ForegroundColor', cautionCol);


guiHandles.resetMain = uicontrol(PSfig,'string','Reset main directory','fontsize',fontsz ,'FontName','arial','FontAngle','normal','TooltipString', ['Donate to the PIDscope project'],'units','normalized','Position',[posInfo.resetMain],...
    'callback','uiwait(helpdlg(resetupStr)), cd(configDir),  main_directory = uigetdir(''Navigate to Main folder''); fid = fopen([''mainDir-PS'' PsVersion ''.txt''],''w''); fprintf(fid,''%s\n'',main_directory); fclose(fid);  PIDscope');
set(guiHandles.resetMain, 'ForegroundColor', cautionCol);
 
 

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
    a = char([cellstr([char(defaults.Parameters) num2str(defaults.Values)]); {rdr}; {mdr}; {ldr}]);
    t = uitable(PSfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
catch
    defaults = ' '; 
    a = char(['Unable to set user defaults '; {rdr}; {mdr}; {ldr}]);
    t = uitable(PSfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
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
