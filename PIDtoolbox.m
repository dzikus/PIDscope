 %% PIDtoolbox - main  
%  script for main control panel and log viewer
%
% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
  

PtbVersion='v0.58';

%% Octave compatibility setup
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
  % Load required Octave packages (suppress warnings if already loaded)
  try pkg load signal; end
  try pkg load statistics; end
  try pkg load control; end
  try pkg load image; end
  % Add compat/ shims for MATLAB functions not available in Octave
  % (smooth, finddelay, nanmean, nanmedian)
  compat_dir = fullfile(fileparts(mfilename('fullpath')), 'compat');
  if exist(compat_dir, 'dir')
    addpath(compat_dir);
  end
end

executableDir = fileparts(mfilename('fullpath'));
if isempty(executableDir), executableDir = pwd; end
addpath(executableDir);

setupStr = {'SET UP WORKING DIRECTORY!', ' ', 'Before running PIDtoolbox, we have to determine the location of your ''main'' directory. After you click ''OK'', a navigator window will pop up.' , ['Simply Navigate to the location of your downloaded ''PIDtoolbox_' PtbVersion '\main\'' folder'], 'NOTE: Ideally, that folder and all of its contents should be placed on your desktop to avoid any issues!'};
resetupStr = {'RE-SET WORKING DIRECTORY!', ' ','Once you click ''OK'', a navigator window will pop up.' , ['Simply Navigate to the location of your downloaded ''PIDtoolbox_' PtbVersion '\main\'' folder'], 'NOTE: Ideally, that folder and all of its contents should be placed on your desktop to avoid any issues!'};

% Platform-specific config directory
if exist('/Users/Shared', 'dir')
    configDir = '/Users/Shared';
else
    configDir = fullfile(getenv('HOME'), '.config', 'PIDtoolbox');
    if ~exist(configDir, 'dir'), mkdir(configDir); end
end
cd(configDir)
if isempty(dir(['mainDir-PTB' PtbVersion '.txt']))
    uiwait(helpdlg(setupStr));
    main_directory = uigetdir('Navigate to Main folder');
    fid = fopen(['mainDir-PTB' PtbVersion '.txt'],'w');
    fprintf(fid,'%s\n',main_directory);
    fclose(fid);
end


%%%%%%%%%% used debug modes %%%%%%% - must consider emu and INAV
GYRO_SCALED = 6;
RC_INTERPOLATION = 7;
FEEDFORWARD = 59;
FFT_FREQ = 17;

t = now;
currentDate = datestr(t, 'yyyy-mm-dd HH:MM:SS'); % Octave compatible (was: datetime)
currentDate = currentDate(1:strfind(currentDate,' ')-1);

set(0,'defaultUicontrolFontName', 'Helvetica')
set(0,'defaultUicontrolFontSize', 10)
% set(0,'defaultUicontrolFontName', 'Arial')
% set(0,'defaultUicontrolFontSize', 9)
% set(0,'defaultUicontrolFontWeight', 'bold')

%%%% assign main figure handle and define some UI variables 
PTfig = figure(1);
set(PTfig, 'InvertHardcopy', 'off');
bgcolor=[.95 .95 .95];
set(PTfig,'color',bgcolor);

wikipage = 'https://github.com/bw1129/PIDtoolbox/wiki/PIDtoolbox-user-guide';

if ~exist('filenameA','var'), filenameA={}; end

expandON=0;
use_randsamp=0;
smp_sze=100;
choose_epoch=0;
epoch1_A=[];
epoch2_A=[];
tIND = [];
maxY =  500;
nLineCols = 8; multiLineCols=PTlinecmap(nLineCols);
updateSpec=0;
debugmode=0;%default to none
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
set(PTfig, 'Position', figPos);
set(PTfig, 'NumberTitle', 'off');
set(PTfig, 'Name', ['PIDtoolbox (' PtbVersion ') - Log Viewer']);

pause(.1)% need to wait for figure to open before extracting screen values

screensz_multiplier = sqrt(screensz(4)^2) * .011; % based on vertical dimension only, to deal with for ultrawide monitors
prop_max_screen = figPos(4) / screensz(4);
fontsz = (screensz_multiplier*prop_max_screen);
if isOctave, fontsz = fontsz * 0.88; end % Octave Qt has larger widget padding
markerSz = round(screensz_multiplier * 0.75);
vPos = 0.92;
cpL = .875; % control panel left edge
cpW = .12;  % control panel width
rs = 0.025; % row step (vertical spacing between elements)
rh = 0.026; % row height
if isOctave, rs = 0.031; rh = 0.028; end % Octave Qt widgets need more space

r = 0; % row counter
r=r+1; posInfo.firmware =[cpL+.003 vPos-rs*1.6 cpW-.006 .04];
r=r+1; posInfo.fileA=[cpL+.006 vPos-rs*2 cpW/2-.006 rh];
        posInfo.clr=[cpL+cpW/2 vPos-rs*2 cpW/2-.006 rh];
r=r+1; posInfo.fnameAText = [cpL+.003 vPos-rs*3.6 cpW-.006 .04];
r=r+1; posInfo.startEndButton=[cpL+.005 vPos-rs*4 .04 rh];
LogStDefault = 2;% default ignore first 2 seconds of logfile
LogNdDefault = 1;% default ignore last 1 second of logfile
        posInfo.RPYcomboLV = [cpL+.05 vPos-rs*4 .065 rh];
r=r+1; posInfo.plotR_LV =  [cpL+.005 vPos-rs*5 .035 rh];
        posInfo.plotP_LV =  [cpL+.04 vPos-rs*5 .035 rh];
        posInfo.plotY_LV =  [cpL+.075 vPos-rs*5 .035 rh];
r=r+1; posInfo.lineSmooth = [cpL+.003 vPos-rs*6 cpW/2-.003 rh];
        posInfo.linewidth = [cpL+cpW/2 vPos-rs*6 cpW/2-.003 rh];
r=r+1; posInfo.spectrogramButton = [cpL+.003 vPos-rs*7 cpW-.006 rh];
r=r+1; posInfo.TuningButton = [cpL+.003 vPos-rs*8 cpW-.006 rh];
r=r+1; posInfo.period2Hz = [cpL+.003 vPos-rs*9 cpW/2-.003 rh];
        posInfo.DispInfoButton = [cpL+cpW/2 vPos-rs*9 cpW/2-.003 rh];
r=r+1; posInfo.saveFig = [cpL+.003 vPos-rs*10 cpW/2-.003 rh];
        posInfo.saveSettings = [cpL+cpW/2 vPos-rs*10 cpW/2-.003 rh];
%posInfo.wiki = [cpL+.003 vPos-rs*11 cpW/2-.003 rh];
r=r+1; posInfo.PIDtuningService = [cpL+.003 vPos-rs*11 cpW-.006 rh];
posInfo.resetMain = [cpL+.003 vPos-0.85 cpW-.006 rh];

cpH = rs*11 + 0.05; % control panel height = rows + title margin
controlpanel = uipanel('Title','Control Panel','FontSize',fontsz,...
             'BackgroundColor',[.95 .95 .95],...
             'Position',[cpL vPos-cpH+0.02 cpW cpH]);


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
TooltipString_wiki=['Link to the PIDtoolbox wiki in Github'];
TooltipString_selectButton = ['With box checked, position mouse over desired start position,' , newline, 'then mouse click, then desired end position, then mouse click again;' , newline, 'to escape, deselect then click anywhere'];


%%%

guiHandles.Firmware = uicontrol(PTfig,'Style','popupmenu','string',[{'Betaflight logfiles'; 'Emuflight logfiles'; 'INAV logfiles'}], 'fontsize',fontsz, 'units','normalized','Position', [posInfo.firmware]);

guiHandles.fileA = uicontrol(PTfig,'string','Select ','fontsize',fontsz,'TooltipString', [TooltipString_loadRun], 'units','normalized','Position',[posInfo.fileA],...
     'callback','set(guiHandles.fileA, ''FontWeight'', ''Bold''); [filenameA, filepathA] = uigetfile({[logfile_directory ''*.BBL;*.BFL;*.TXT'']}, ''MultiSelect'',''on''); if ischar(filenameA), filenameA={filenameA}; end; if iscell(filenameA), PTload; PTviewerUIcontrol; PTplotLogViewer; end'); 
set(guiHandles.fileA, 'ForegroundColor', colRun);

guiHandles.clr = uicontrol(PTfig,'string','Reset','fontsize',fontsz,'TooltipString', ['clear all data'], 'units','normalized','Position',[posInfo.clr],...
     'callback','delete *.bbl, delete *.bfl, delete *.csv, clear T dataA tta A_lograte epoch1_A epoch2_A SetupInfo rollPIDF pitchPIDF yawPIDF filenameA fnameMaster; fcnt = 0; filenameA={};fnameMaster = {}; try, delete(subplot(''position'',posInfo.linepos1)); delete(subplot(''position'',posInfo.linepos2)); delete(subplot(''position'',posInfo.linepos3)); delete(subplot(''position'',posInfo.linepos4)); catch, end; set(guiHandles.FileNum, ''String'', '' ''); set(guiHandles.Epoch1_A_Input, ''String'', '' ''); set(guiHandles.Epoch2_A_Input, ''String'', '' '');'); 
set(guiHandles.clr, 'ForegroundColor', cautionCol);

guiHandles.startEndButton = uicontrol(PTfig,'style','checkbox', 'string','Trim ','fontsize',fontsz,'TooltipString', [TooltipString_selectButton], 'units','normalized','Position',[posInfo.startEndButton],...
    'callback','if ~isempty(filenameA) && get(guiHandles.startEndButton, ''Value''), [x y] = ginput(1); epoch1_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PTplotLogViewer; [x y] = ginput(1); epoch2_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PTplotLogViewer, end'); 

guiHandles.plotR =uicontrol(PTfig,'Style','checkbox','String','R','fontsize',fontsz,'TooltipString', ['Plot Roll '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotR_LV], 'callback','if ~isempty(fnameMaster), PTplotLogViewer; end');

guiHandles.plotP =uicontrol(PTfig,'Style','checkbox','String','P','fontsize',fontsz,'TooltipString', ['Plot Pitch '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotP_LV], 'callback','if ~isempty(fnameMaster), PTplotLogViewer; end');

guiHandles.plotY =uicontrol(PTfig,'Style','checkbox','String','Y','fontsize',fontsz,'TooltipString', ['Plot Yaw '],...
    'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.plotY_LV], 'callback','if ~isempty(fnameMaster), PTplotLogViewer; end');

guiHandles.RPYcomboLV=uicontrol(PTfig,'Style','checkbox','String','Single Panel','fontsize',fontsz,'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.RPYcomboLV],'callback','if ~isempty(fnameMaster), PTplotLogViewer; end');

guiHandles.FileNum = uicontrol(PTfig,'Style','popupmenu','string',[fnameMaster], 'fontsize',fontsz, 'units','normalized','Position', [posInfo.fnameAText]);
set(guiHandles.FileNum, 'String', ' ');

guiHandles.lineSmooth = uicontrol(PTfig,'Style','popupmenu','string',{'line smooth off','line smooth low','line smooth med','line smooth med-high','line smooth high'},...
    'fontsize',fontsz,'TooltipString', ['zero-phase filter lines'], 'units','normalized','Position', [posInfo.lineSmooth],'callback','if ~isempty(filenameA), expandON=0; PTplotLogViewer; end');

guiHandles.linewidth = uicontrol(PTfig,'Style','popupmenu','string',{'line width 1','line width 2','line width 3','line width 4','line width 5'},...
    'fontsize',fontsz, 'TooltipString', ['line thickness'], 'units','normalized','Position', [posInfo.linewidth],'callback','if ~isempty(filenameA), expandON=0; PTplotLogViewer; end');

guiHandles.spectrogramButton = uicontrol(PTfig,'Style', 'pushbutton','string','Spectral Analyzer','fontsize',fontsz,'TooltipString', [TooltipString_spec],'units','normalized','Position',[posInfo.spectrogramButton],...
    'callback','PTspec2DUIcontrol;');
set(guiHandles.spectrogramButton, 'ForegroundColor', colorA);

guiHandles.TuningButton = uicontrol(PTfig,'string','Step Resp Tool','fontsize',fontsz,'TooltipString', [TooltipString_step],'units','normalized','Position',[posInfo.TuningButton],...
    'callback','PTtuneUIcontrol');
set(guiHandles.TuningButton, 'ForegroundColor', colorB);

guiHandles.period2Hz = uicontrol(PTfig,'string','Period','fontsize',fontsz,'TooltipString', ['Calculates peak to peak in Hz similar to the BBE ''Mark'' tool' , newline, 'press button, position mouse over 1st peak, mouse click,' , newline, 'then position over 2nd peak, then mouse click again'], 'units','normalized','Position',[posInfo.period2Hz],...
     'callback','if ~isempty(filenameA) && get(guiHandles.period2Hz, ''Value''), [x1 y1] = ginput(1); figure(PTfig); h=plot([x1 x1],[-(maxY*2) maxY],''-r'');set(h,''linewidth'' , get(guiHandles.linewidth, ''Value'')/2);  [x2 y2] = ginput(1); h=plot([x2 x2],[-(maxY*2) maxY],''-r''); set(h,''linewidth'' , get(guiHandles.linewidth, ''Value'')/2); plot([x1 x2],[y1 y2],'':k''); x3=[round(x1*1000) round(x2*1000)]; f = 1000/(x3(2)-x3(1)); text(x2, y2, [num2str(x3(2)-x3(1)) ''ms, '' num2str(f) ''Hz''],''FontSize'',fontsz, ''FontWeight'', ''Bold''), end');      

guiHandles.DispInfoButton = uicontrol(PTfig,'string','Setup Info','fontsize',fontsz,'TooltipString', [TooltipString_setup],'units','normalized','Position',[posInfo.DispInfoButton],...
    'callback','PTdispSetupInfoUIcontrol;PTdispSetupInfo;');
set(guiHandles.DispInfoButton, 'ForegroundColor', setUpCol);

guiHandles.saveFig = uicontrol(PTfig,'string','Save Fig','fontsize',fontsz, 'TooltipString',[TooltipString_saveFig], 'units','normalized','Position',[posInfo.saveFig],...
    'callback','set(guiHandles.saveFig, ''FontWeight'', ''bold'');PTsaveFig; set(guiHandles.saveFig, ''FontWeight'', ''normal'');'); 
set(guiHandles.saveFig, 'ForegroundColor', saveCol);

guiHandles.saveSettings = uicontrol(PTfig,'string','Save Settings','fontsize',fontsz, 'TooltipString',['Save current settings to PTB defaults' ], 'units','normalized','Position',[posInfo.saveSettings],...
    'callback','set(guiHandles.saveSettings, ''FontWeight'', ''bold'');PTsaveSettings; set(guiHandles.saveSettings, ''FontWeight'', ''normal'');'); 
set(guiHandles.saveSettings, 'ForegroundColor', saveCol);

% guiHandles.wiki = uicontrol(PTfig,'string','User Guide','fontsize',fontsz,'FontName','arial','FontAngle','normal','TooltipString', [TooltipString_wiki],'units','normalized','Position',[posInfo.wiki],...
%     'callback','web(wikipage);'); 
% guiHandles.wiki.ForegroundColor=[cautionCol];

guiHandles.PIDtuningService = uicontrol(PTfig,'string','www.pidtoolbox.com','fontsize',fontsz ,'FontName','arial','FontAngle','normal','TooltipString', ['www.pidtoolbox.com'],'units','normalized','Position',[posInfo.PIDtuningService],...
    'callback','web(''www.pidtoolbox.com'');'); 
set(guiHandles.PIDtuningService, 'ForegroundColor', cautionCol);


guiHandles.resetMain = uicontrol(PTfig,'string','Reset main directory','fontsize',fontsz ,'FontName','arial','FontAngle','normal','TooltipString', ['Donate to the PIDtoolbox project'],'units','normalized','Position',[posInfo.resetMain],...
    'callback','uiwait(helpdlg(resetupStr)), cd(configDir),  main_directory = uigetdir(''Navigate to Main folder''); fid = fopen([''mainDir-PTB'' PtbVersion ''.txt''],''w''); fprintf(fid,''%s\n'',main_directory); fclose(fid);  PIDtoolbox');
set(guiHandles.resetMain, 'ForegroundColor', cautionCol);
 
 

rdr = ['rootDirectory: ' executableDir];
try
    fid = fopen(['mainDir-PTB' PtbVersion '.txt'],'r');
    main_directory = fscanf(fid, '%s');
    fclose(fid);
catch
    main_directory = [pwd '/'];
end 
cd(main_directory)

try    
    fid = fopen('logfileDir.txt','r');
    logfile_directory = fscanf(fid, '%c');
    fclose(fid);
    if ~isempty(dir('*.bbl')), delete('*.bbl'); end
    if ~isempty(dir('*.bfl')), delete('*.bfl'); end
    if ~isempty(dir('*.csv')), delete('*.csv'); end
catch
    logfile_directory = [executableDir];
end
    
mdr = ['mainDirectory: ' main_directory ];
ldr = ['logfileDirectory: ' logfile_directory ];


pause(1);
try
    defaults = readtable('PTBdefaults.txt');
    a = char([cellstr([char(defaults.Parameters) num2str(defaults.Values)]); {rdr}; {mdr}; {ldr}]);
    t = uitable(PTfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',[cpL vPos-.82 cpW .3],'FontSize',fontsz*.8, 'ColumnName', [''])
catch
    defaults = ' '; 
    a = char(['Unable to set user defaults '; {rdr}; {mdr}; {ldr}]);
    t = uitable(PTfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',[cpL vPos-.82 cpW .3],'FontSize',fontsz*.8, 'ColumnName', [''])
end


try set(guiHandles.Firmware, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'firmware')))), catch, set(guiHandles.Firmware, 'Value', 1), end
try set(guiHandles.RPYcomboLV, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-SinglePanel')))), catch, set(guiHandles.RPYcomboLV, 'Value', 0), end
try set(guiHandles.plotR, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotR')))), catch, set(guiHandles.plotR, 'Value', 1), end
try set(guiHandles.plotP, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotP')))), catch, set(guiHandles.plotP, 'Value', 1), end
try set(guiHandles.plotY, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-plotY')))), catch, set(guiHandles.plotY, 'Value', 1), end
try set(guiHandles.lineSmooth, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-lineSmooth')))), catch, set(guiHandles.lineSmooth, 'Value', 1), end
try set(guiHandles.linewidth, 'Value', defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-lineWidth')))), catch, set(guiHandles.linewidth, 'Value', 3), end

