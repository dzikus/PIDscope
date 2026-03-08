%% PSviewerUIcontrol 


% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------  
    

% Checkbox bar — pixel sizes (constant across resizes)
chkW_px = 130; chkMotW_px = 100; chkEdtW_px = 45; chkTxtW_px = 65;
figPos = get(PSfig, 'Position'); figW = figPos(3); figH = figPos(4);
chkW = chkW_px/figW; chkH = rh; chkMotW = chkMotW_px/figW;
chkEdtW = chkEdtW_px/figW; chkTxtW = chkTxtW_px/figW;
tbOff = 40/figH;
chkRow1 = 1 - tbOff;  chkRow2 = chkRow1 - rs;
chkX = 0.10;
posInfo.checkbox0=[chkX chkRow1 chkW chkH];
posInfo.checkbox1=[chkX chkRow2 chkW chkH];     chkX=chkX+chkW;
posInfo.checkbox2=[chkX chkRow1 chkW chkH];
posInfo.checkbox3=[chkX chkRow2 chkW chkH];      chkX=chkX+chkW;
posInfo.checkbox4=[chkX chkRow1 chkW chkH];
posInfo.checkbox5=[chkX chkRow2 chkW chkH];      chkX=chkX+chkW;
posInfo.checkbox6=[chkX chkRow1 chkW chkH];
posInfo.checkbox7=[chkX chkRow2 chkW chkH];      chkX=chkX+chkW;
posInfo.checkbox8=[chkX chkRow1 chkW chkH];
posInfo.checkbox9=[chkX chkRow2 chkW chkH];      chkX=chkX+chkW;
posInfo.checkbox13=[chkX chkRow1 chkMotW chkH];
posInfo.checkbox12=[chkX chkRow2 chkMotW chkH];      chkX=chkX+chkMotW;
posInfo.checkbox11=[chkX chkRow1 chkMotW chkH];
posInfo.checkbox10=[chkX chkRow2 chkMotW chkH];      chkX=chkX+chkMotW;
posInfo.checkbox14=[chkX chkRow1 chkMotW chkH];
posInfo.checkbox15=[chkX chkRow2 chkMotW chkH];      chkX=chkX+chkMotW;

posInfo.maxYtext =  [chkX chkRow1 chkTxtW chkH];
posInfo.maxYinput = [chkX+chkTxtW chkRow1 chkEdtW chkH];
posInfo.nCols_text =  [chkX chkRow2 chkTxtW chkH];
posInfo.nCols_input = [chkX+chkTxtW chkRow2 chkEdtW chkH];

posInfo.YTstick = [cpL+.005 vPos-0.39 .05 .085];
posInfo.RPstick = [cpL+cpW/2 vPos-0.39 .05 .085];

% Plot positions — right edge stops at CP left edge
plotL = 0.095; plotGap = 0.01;
dynCpL = getappdata(PSfig, 'PScpL'); if isempty(dynCpL), dynCpL = cpL; end
plotW = dynCpL - plotL - plotGap;
sliderW = dynCpL - 0.0826 - 0.005;
posInfo.slider = [0.0826 chkRow2-2*cpMv-0.02 sliderW 0.02];
plotTop = posInfo.slider(2) - 0.005;
gapV = 0.005;
linepos4H = 0.11;
plotH = (plotTop - 0.1 - linepos4H - 4*gapV) / 3;
posInfo.linepos1=[plotL plotTop-plotH plotW plotH];
posInfo.linepos2=[plotL plotTop-2*plotH-gapV plotW plotH];
posInfo.linepos3=[plotL plotTop-3*plotH-2*gapV plotW plotH];
posInfo.linepos4=[plotL 0.1 plotW linepos4H];

fullszPlot = [plotL posInfo.linepos3(2) plotW plotTop-posInfo.linepos3(2)];


if ~exist('checkpanel','var') || ~ishandle(checkpanel)
chkPanelW = chkX + chkTxtW + chkEdtW + cpM - 0.096;
checkpanel = uipanel('Title','','FontSize',fontsz,...
             'BackgroundColor',panelBg,'ForegroundColor',panelFg,...
             'HighlightColor',panelBorder,...
             'Position',[0.096 chkRow2-cpMv chkPanelW chkRow1+rh+cpMv-chkRow2+cpMv]);

guiHandles.checkbox0=uicontrol(PSfig,'Style','checkbox','String','Debug','fontsize',fontsz,'ForegroundColor',[linec.col0],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox0],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox1=uicontrol(PSfig,'Style','checkbox','String','Gyro','fontsize',fontsz,'ForegroundColor',[linec.col1],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox1],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox2=uicontrol(PSfig,'Style','checkbox','String','P-term','fontsize',fontsz,'ForegroundColor',[linec.col2],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox2],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox3=uicontrol(PSfig,'Style','checkbox','String','I-term','fontsize',fontsz,'ForegroundColor',[linec.col3],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox3],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox4=uicontrol(PSfig,'Style','checkbox','String','D-term (prefilt)','fontsize',fontsz,'ForegroundColor',[linec.col4],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox4],'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), PSplotLogViewer; end');
guiHandles.checkbox5=uicontrol(PSfig,'Style','checkbox','String','D-term','fontsize',fontsz,'ForegroundColor',[linec.col5],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox5],'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), PSplotLogViewer; end');
guiHandles.checkbox6=uicontrol(PSfig,'Style','checkbox','String','F-term','fontsize',fontsz,'ForegroundColor',[linec.col6],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox6],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox7=uicontrol(PSfig,'Style','checkbox','String','Set point','fontsize',fontsz,'ForegroundColor',[linec.col7],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox7],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox8=uicontrol(PSfig,'Style','checkbox','String','PID sum','fontsize',fontsz,'ForegroundColor',[linec.col8],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox8],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox9=uicontrol(PSfig,'Style','checkbox','String','PID error','fontsize',fontsz,'ForegroundColor',[linec.col9],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox9],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox10=uicontrol(PSfig,'Style','checkbox','String','Motor 1','fontsize',fontsz,'ForegroundColor',[linec.col10],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox10],'callback','if exist(''filenameA'',''var'') && ~isempty(filenameA), PSplotLogViewer; end');
guiHandles.checkbox11=uicontrol(PSfig,'Style','checkbox','String','Motor 2','fontsize',fontsz,'ForegroundColor',[linec.col11],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox11],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox12=uicontrol(PSfig,'Style','checkbox','String','Motor 3','fontsize',fontsz,'ForegroundColor',[linec.col12],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox12],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox13=uicontrol(PSfig,'Style','checkbox','String','Motor 4','fontsize',fontsz,'ForegroundColor',[linec.col13],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox13],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');
guiHandles.checkbox14=uicontrol(PSfig,'Style','checkbox','String','Throttle','fontsize',fontsz,'ForegroundColor',[linec.col14],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox14],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), PSplotLogViewer; end');

set(guiHandles.checkbox1, 'Value', 1);
set(guiHandles.checkbox7, 'Value', 1);
set(guiHandles.checkbox10, 'Value', 1);
set(guiHandles.checkbox11, 'Value', 1);
set(guiHandles.checkbox12, 'Value', 1);
set(guiHandles.checkbox13, 'Value', 1);
set(guiHandles.checkbox14, 'Value', 1);

guiHandles.checkbox15=uicontrol(PSfig,'Style','checkbox','String','All','fontsize',fontsz,'TooltipString', ['Plot or clear all lines '],'ForegroundColor',[linec.col15],'BackgroundColor',bgcolor,...
    'units','normalized','Position',[posInfo.checkbox15],'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), plotall_flag=get(guiHandles.checkbox15, ''Value''); PSplotLogViewer; end');
 
TooltipString_FileNum=['Select the file you wish to plot in the logviewer. '];
set(guiHandles.FileNum, 'string', fnameMaster, 'TooltipString', TooltipString_FileNum,...
    'callback','if exist(''fnameMaster'',''var'') && ~isempty(fnameMaster), try set(zoom, ''Enable'',''off''); catch, end, expandON=0; PSplotLogViewer; if exist(''filenameA'',''var'') && ~isempty(filenameA) && get(guiHandles.startEndButton, ''Value''), try, [x y] = ginput(1); epoch1_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; [x y] = ginput(1); epoch2_A(get(guiHandles.FileNum, ''Value'')) = round(x(1)*10)/10; PSplotLogViewer; catch, end, end, end');
maxY_textToolTip = ['+/- Scaling factor for the Y axis in degs/s'];
guiHandles.maxY_text = uicontrol(PSfig,'style','text','string','y scale','fontsize',fontsz,'TooltipString', [maxY_textToolTip],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.maxYtext]);
guiHandles.maxY_input = uicontrol(PSfig,'style','edit','string',int2str(maxY),'fontsize',fontsz,'TooltipString', [maxY_textToolTip],'units','normalized','Position',[posInfo.maxYinput],...
     'callback','PSplotLogViewer; ');

guiHandles.nCols_text = uicontrol(PSfig,'style','text','string','N colors','fontsize',fontsz,'TooltipString', ['sets the number of colors for other tools (allowable range 1 - 20)'],'units','normalized','BackgroundColor',bgcolor,'Position',[posInfo.nCols_text]);
guiHandles.nCols_input = uicontrol(PSfig,'style','edit','string',int2str(nLineCols),'fontsize',fontsz,'TooltipString', ['sets the number of colors for other tools (allowable range 1 - 20)'],'units','normalized','Position',[posInfo.nCols_input],...
     'callback','if str2double(get(guiHandles.nCols_input, ''String'')) > 20, set(guiHandles.nCols_input, ''String'', ''20''); end; if str2double(get(guiHandles.nCols_input, ''String'')) < 1, set(guiHandles.nCols_input, ''String'', ''1''); end; multiLineCols=PSlinecmap(str2double(get(guiHandles.nCols_input, ''String''))); ');

% Register checkbox bar for pixel-based resize
chkBarItems = {};
chkBarItems{end+1} = struct('h', guiHandles.checkbox0, 'wpx', chkW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox1, 'wpx', chkW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox2, 'wpx', chkW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox3, 'wpx', chkW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox4, 'wpx', chkW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox5, 'wpx', chkW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox6, 'wpx', chkW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox7, 'wpx', chkW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox8, 'wpx', chkW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox9, 'wpx', chkW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox13, 'wpx', chkMotW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox12, 'wpx', chkMotW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox11, 'wpx', chkMotW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox10, 'wpx', chkMotW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.checkbox14, 'wpx', chkMotW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.checkbox15, 'wpx', chkMotW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.maxY_text, 'wpx', chkTxtW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.nCols_text, 'wpx', chkTxtW_px, 'row', 2, 'advance', true);
chkBarItems{end+1} = struct('h', guiHandles.maxY_input, 'wpx', chkEdtW_px, 'row', 1, 'advance', false);
chkBarItems{end+1} = struct('h', guiHandles.nCols_input, 'wpx', chkEdtW_px, 'row', 2, 'advance', true);
chkBarData = struct('x0', 0.10, 'items', {chkBarItems}, 'panel', checkpanel);
if exist('guiHandles','var') && isfield(guiHandles, 'slider') && ishandle(guiHandles.slider)
    chkBarData.slider = guiHandles.slider;
end
setappdata(PSfig, 'PScheckboxBar', chkBarData);

subplot('position',[posInfo.YTstick]);
set(gca, 'xlim', [-500 500], 'ylim', [0 100], 'xticklabel',[], 'yticklabel',[],'xtick',[0], 'ytick',[50], 'xgrid', 'on', 'ygrid', 'on');
box on
subplot('position',[posInfo.RPstick])
set(gca, 'xlim', [-500 500], 'ylim', [0 100], 'xticklabel',[], 'yticklabel',[],'xtick',[0], 'ytick',[50], 'xgrid', 'on', 'ygrid', 'on');
box on
end % ishandle(checkpanel)

fileIdx = get(guiHandles.FileNum, 'Value');
if exist('tta','var') && iscell(tta) && numel(tta) >= fileIdx
    if numel(epoch1_A) < fileIdx || numel(epoch2_A) < fileIdx
        epoch1_A(fileIdx)=tta{fileIdx}(1)/us2sec;
        epoch2_A(fileIdx)=tta{fileIdx}(end)/us2sec;
    end
end

% set IND for data subset. Updated in logviewer.
if exist('tta','var') && iscell(tta)
    for f = 1 : min(Nfiles, numel(tta))
        tIND{f} = tta{f} > (epoch1_A(f)*us2sec) & tta{f} < (epoch2_A(f)*us2sec);
    end
end

try set(guiHandles.maxY_input, 'String', num2str(defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-Ymax'))))), catch, end
try set(guiHandles.nCols_input, 'String', num2str(defaults.Values(find(strcmp(defaults.Parameters, 'LogViewer-Ncolors'))))), catch, end
PSstyleControls(PSfig);


