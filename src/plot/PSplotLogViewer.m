%% PSplotLogViewer - script to plot main line graphs

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------


if exist('fnameMaster','var') && ~isempty(fnameMaster)

    set(PSfig, 'pointer', 'watch')
    th = PStheme();

    global logviewerYscale 
    logviewerYscale = str2double(get(guiHandles.maxY_input, 'String'));

    set(0, 'CurrentFigure', PSfig);

    maxY=str2double(get(guiHandles.maxY_input, 'String'));

    alpha_red=.8;
    alpha_blue=.8;


    lineSmoothFactors = [1 10 20 40 80];

    if plotall_flag>=0
        allVal = get(guiHandles.checkbox15, 'Value');
        set(guiHandles.checkbox0, 'Value', allVal);
        set(guiHandles.checkbox1, 'Value', allVal);
        set(guiHandles.checkbox2, 'Value', allVal);
        set(guiHandles.checkbox3, 'Value', allVal);
        set(guiHandles.checkbox4, 'Value', allVal);
        set(guiHandles.checkbox5, 'Value', allVal);
        set(guiHandles.checkbox6, 'Value', allVal);
        set(guiHandles.checkbox7, 'Value', allVal);
        set(guiHandles.checkbox8, 'Value', allVal);
        set(guiHandles.checkbox9, 'Value', allVal);
        set(guiHandles.checkbox10, 'Value', allVal);
        set(guiHandles.checkbox11, 'Value', allVal);
        set(guiHandles.checkbox12, 'Value', allVal);
        set(guiHandles.checkbox13, 'Value', allVal);
        set(guiHandles.checkbox14, 'Value', allVal);
        set(guiHandles.checkboxTS, 'Value', allVal);
        for rk_=1:4, try set(guiHandles.(['checkboxRPM' int2str(rk_)]), 'Value', allVal); catch, end, end
    end
    plotall_flag=-1;

    dynCpL = getappdata(PSfig, 'PScpL'); if isempty(dynCpL), dynCpL = 0.875; end
    plotL = 0.095; plotGap = 0.01;
    plotW = dynCpL - plotL - plotGap;
    expandW = dynCpL - 0.05 - 0.01;
    expand_sz=[0.05 0.06 expandW posInfo.slider(2)-0.07];
    % Update linepos widths to match current CP position
    posInfo.linepos1(3) = plotW;
    posInfo.linepos2(3) = plotW;
    posInfo.linepos3(3) = plotW;
    posInfo.linepos4(3) = plotW;
    fullszPlot(3) = plotW;


    %% where you want full range of data
    fileIdx = get(guiHandles.FileNum, 'Value');

    % enable/disable RPM checkboxes based on eRPM data
    hasERPM_ = exist('T','var') && iscell(T) && numel(T) >= fileIdx && isfield(T{fileIdx}, 'eRPM_0_');
    rpmEn_ = 'off'; if hasERPM_, rpmEn_ = 'on'; end
    for rk_=1:4
        try
            set(guiHandles.(['checkboxRPM' int2str(rk_)]), 'Enable', rpmEn_);
            if ~hasERPM_, set(guiHandles.(['checkboxRPM' int2str(rk_)]), 'Value', 0); end
        catch, end
    end

    % Update Debug checkbox label for RC_INTERPOLATION mode (version-aware)
    tmpRCidx = RC_INTERPOLATION; % global default
    if exist('debugIdx','var') && numel(debugIdx) >= fileIdx
        tmpRCidx = debugIdx{fileIdx}.RC_INTERPOLATION;
    end
    if exist('debugmode','var') && numel(debugmode) >= fileIdx && debugmode(fileIdx) == tmpRCidx
        set(guiHandles.checkbox0, 'String', 'SP (raw)');
    else
        set(guiHandles.checkbox0, 'String', 'Debug');
    end

    % clamp epochs to valid data range
    if ~exist('tta','var') || ~iscell(tta) || numel(tta) < fileIdx
        set(PSfig, 'pointer', 'arrow'); return;
    end
    tStart = tta{fileIdx}(1) / us2sec;
    tEnd = tta{fileIdx}(end) / us2sec;
    if epoch1_A(fileIdx) >= tEnd || epoch2_A(fileIdx) <= tStart || epoch1_A(fileIdx) >= epoch2_A(fileIdx)
        epoch1_A(fileIdx) = tStart;
        epoch2_A(fileIdx) = tEnd;
    end

     y=[epoch1_A(fileIdx)*us2sec epoch2_A(fileIdx)*us2sec];
     idx1 = find(tta{fileIdx} >= y(1), 1);
     idx2 = find(tta{fileIdx} >= y(2), 1);
     if isempty(idx1), idx1 = 1; end
     if isempty(idx2), idx2 = length(tta{fileIdx}); end
     t1 = tta{fileIdx}(idx1) / us2sec;
     t2 = tta{fileIdx}(idx2) / us2sec;

    tIND{fileIdx} = (tta{fileIdx} > (t1*us2sec)) & (tta{fileIdx} < (t2*us2sec));

%     jRangeSlider = com.jidesoft.swing.RangeSlider(0,200,10,190);  % min,max,low,high
%     jRangeSlider = javacomponent(jRangeSlider,[50, 80, 500, 80], gcf);
%     set(jRangeSlider, 'MajorTickSpacing',50, 'PaintTicks',true, 'PaintLabels',true, 'Background',java.awt.Color.white)
%     jRangeSlider.LowValue = 20;, jRangeSlider.HighValue = 180;

    sliderPos = posInfo.slider;
    sliderPos(3) = dynCpL - sliderPos(1) - 0.005;
    guiHandles.slider = uicontrol(PSfig, 'style','slider','SliderStep',[0.001 0.01],'Visible', 'on', 'units','normalized','position',sliderPos,...
        'min',0,'max',1, 'callback','PSslider1Actions;');
    % Update resize data with slider handle
    chkBarData = getappdata(PSfig, 'PScheckboxBar');
    if ~isempty(chkBarData), chkBarData.slider = guiHandles.slider; setappdata(PSfig, 'PScheckboxBar', chkBarData); end

        
        
    %% log viewer line plots
    %%%%%%%% PLOT %%%%%%%
    axLabel={'Roll';'Pitch';'Yaw'};
    lineStyleLV = {'-'; '-'; '-'};
    lineStyle2LV = {'-'; '--'; ':'};
    lineStyle2LVnames = {'solid' ; 'dashed' ; 'dotted'};
    axesOptionsLV = find([get(guiHandles.plotR, 'Value') get(guiHandles.plotP, 'Value') get(guiHandles.plotY, 'Value')]);
    
    for ei=1:3, try delete(hexpand{ei}); catch, end, end
    expandON = 0;

    ylabelname='';
    for i = 1 : size(axesOptionsLV,2)
        if i == size(axesOptionsLV,2)
            ylabelname = [ylabelname axLabel{axesOptionsLV(i)} '-' lineStyle2LVnames{i} '   (deg/s) '];
        else
            ylabelname = [ylabelname axLabel{axesOptionsLV(i)} '-' lineStyle2LVnames{i} '   |   '];
        end
    end
    
    PSfig;
    
    try zoomOn = strcmp(get(zoom(PSfig), 'Enable'),'on'); catch, zoomOn = 0; end
    if ~zoomOn && ~expandON
         try delete(findobj(PSfig,'Tag','PSrpy')); catch, end
         try delete(findobj(PSfig,'Tag','PSmotor')); catch, end
         try delete(findobj(PSfig,'Tag','PScombo')); catch, end
         try delete(findobj(PSfig,'Tag','PSeRPMax')); catch, end
    end
    
    try delete(hch1); catch, end, try delete(hch2); catch, end
    try delete(hch3); catch, end, try delete(hch4); catch, end
    try delete(hch5); catch, end, try delete(hch6); catch, end
    try delete(hch7); catch, end, try delete(hch8); catch, end
    try delete(hch9); catch, end, try delete(hch10); catch, end
    try delete(hch11); catch, end, try delete(hch12); catch, end
    try delete(hch13); catch, end, try delete(hch14); catch, end
    try delete(hch15); catch, end, try delete(hch16); catch, end
    try delete(hch17); catch, end, try delete(hch18); catch, end
    try delete(hch19); catch, end

            
    try  % datacursormode not available in Octave
      dcm_obj = datacursormode(PSfig);
      set(dcm_obj,'UpdateFcn',@PSdatatip);
    end

    cntLV = 0;
    lnstyle = lineStyleLV;
    LVpanels = {[], [], []};

    if exist('fnameMaster','var') && ~isempty(fnameMaster)
        for ii = axesOptionsLV
            if get(guiHandles.RPYcomboLV, 'Value'), expandON = 0; end
            lpKey = ['linepos' int2str(ii)];
            if ~get(guiHandles.RPYcomboLV, 'Value') && ~expandON
                LVpanels{ii} = axes('Parent', PSfig, 'Position', posInfo.(lpKey), 'Tag', 'PSrpy');
                LVpanel5 = axes('Parent', PSfig, 'Position', posInfo.linepos4, 'Tag', 'PSmotor');
            end
            if ~get(guiHandles.RPYcomboLV, 'Value') && expandON
                try
                    set(hexpand{ii}, 'Position', expand_sz);
                catch
                end
            end

            hexp = []; try hexp = hexpand{ii}; catch, end
            if (~isempty(hexp) && ishandle(hexp)) || ~expandON

                cntLV = cntLV + 1;
                if get(guiHandles.RPYcomboLV, 'Value')
                    LVpanel4 = findobj(PSfig, 'Type', 'axes', 'Tag', 'PScombo');
                    if isempty(LVpanel4), LVpanel4 = axes('Parent', PSfig, 'Position', fullszPlot, 'Tag', 'PScombo');
                    else set(PSfig, 'CurrentAxes', LVpanel4); end
                    lnstyle = lineStyle2LV;
                end
                if ~get(guiHandles.RPYcomboLV, 'Value') && expandON == 0
                    set(PSfig, 'CurrentAxes', LVpanels{ii});
                    lnstyle = lineStyleLV;
                end

                xmax=max(tta{fileIdx}/us2sec);


                h=plot([0 xmax],[-maxY -maxY],'Color',th.axesFg);
                set(h,'linewidth',.2)
                hold on
                set(gca,'Color',th.axesBg);
                set(gca,'ytick',[  -(maxY/2) 0 maxY/2 ],'yticklabel',{num2str(-(maxY/2)) '0' num2str((maxY/2)) ''},'YColor',th.axesFg,'fontweight','bold')
                set(gca,'xtick',[round(xmax/10):round(xmax/10):round(xmax)],'XColor',th.axesFg,'GridColor',th.gridColor)  

                sFactor = lineSmoothFactors(get(guiHandles.lineSmooth, 'Value'));
                fileIdx = get(guiHandles.FileNum, 'Value');
                lwVal = get(guiHandles.linewidth, 'Value')/2;

                tSec = tta{fileIdx}/us2sec;
                if get(guiHandles.checkbox0, 'Value'), try hch1=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['debug_' int2str(ii-1) '_'], sFactor));hold on;set(hch1,'color', [linec.col0],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox1, 'Value'), try hch2=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['gyroADC_' int2str(ii-1) '_'], sFactor));hold on;set(hch2,'color', [linec.col1],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox2, 'Value'), try hch3=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['axisP_' int2str(ii-1) '_'], sFactor));hold on;set(hch3,'color', [linec.col2],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox3, 'Value'), try hch4=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['axisI_' int2str(ii-1) '_'], sFactor));hold on;set(hch4,'color', [linec.col3],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox4, 'Value') && ii<3, try hch5=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['axisDpf_' int2str(ii-1) '_'], sFactor));hold on;set(hch5,'color', [linec.col4],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox5, 'Value') && ii<3, try hch6=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['axisD_' int2str(ii-1) '_'], sFactor));hold on;set(hch6,'color', [linec.col5],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox6, 'Value'), try hch7=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['axisF_' int2str(ii-1) '_'], sFactor));hold on;set(hch7,'color', [linec.col6],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox7, 'Value'), try hch8=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['setpoint_' int2str(ii-1) '_'], sFactor));hold on;set(hch8,'color', [linec.col7],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox8, 'Value'), try hch9=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['pidsum_' int2str(ii-1) '_'], sFactor));hold on;set(hch9,'color', [linec.col8],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkbox9, 'Value'), try hch10=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['piderr_' int2str(ii-1) '_'], sFactor));hold on;set(hch10,'color', [linec.col9],'LineWidth',lwVal,'linestyle',[lnstyle{cntLV}]), catch, end, end
                if get(guiHandles.checkboxTS, 'Value') && isfield(T{fileIdx}, ['testSignal_' int2str(ii-1) '_']), try hchTS=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, ['testSignal_' int2str(ii-1) '_'], sFactor));hold on;set(hchTS,'color', th.sigTestSignal,'LineWidth',lwVal,'linestyle','--'), catch, end, end


                 h=fill([0,t1,t1,0],[-maxY,-maxY,maxY,maxY],th.epochFill);
                 set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);
                 h=fill([t2,xmax,xmax,t2],[-maxY,-maxY,maxY,maxY],th.epochFill);
                 set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);

                 try zoomOn2 = strcmp(get(zoom(PSfig), 'Enable'),'on'); catch, zoomOn2 = 0; end
                 if zoomOn2
                    v = axis;
                    axis(v)
                else
                    axis([0 xmax -maxY maxY])
                 end

                box off  
                if get(guiHandles.RPYcomboLV, 'Value') 
                    y=ylabel([ylabelname],'fontweight','bold','rotation', 90);  
                else
                    y=ylabel([axLabel{ii} ' (deg/s)'],'fontweight','bold','rotation', 90);  
                end


                set(y,'Units','normalized', 'position', [-.035 .5 1],'color',th.textPrimary);
                y=xlabel('Time (s)','fontweight','bold');
                set(y,'color',th.textPrimary);
                set(gca,'fontsize',fontsz,'XMinorGrid','on')
                grid on
                
                            %  Percent variables
                LVpanel5 = findobj(PSfig, 'Type', 'axes', 'Tag', 'PSmotor');
                if isempty(LVpanel5), LVpanel5 = axes('Parent', PSfig, 'Position', posInfo.linepos4, 'Tag', 'PSmotor');
                else set(PSfig, 'CurrentAxes', LVpanel5); end
                if get(guiHandles.checkbox10, 'Value'), try hch11=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_0_', sFactor));hold on;set(hch11,'color', [linec.col10],'LineWidth',lwVal), catch, end, end
                if get(guiHandles.checkbox11, 'Value'), try hch12=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_1_', sFactor));hold on;set(hch12,'color', [linec.col11],'LineWidth',lwVal), catch, end, end
                if get(guiHandles.checkbox12, 'Value'), try hch13=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_2_', sFactor));hold on;set(hch13,'color', [linec.col12],'LineWidth',lwVal), catch, end, end
                if get(guiHandles.checkbox13, 'Value'), try hch14=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_3_', sFactor));hold on;set(hch14,'color', [linec.col13],'LineWidth',lwVal), catch, end, end
                % motor sigs 4-7 for x8 configuration
                if get(guiHandles.checkbox10, 'Value'), try hch15=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_4_', sFactor));hold on;set(hch15,'color', [linec.col10],'LineWidth',lwVal, 'LineStyle', '--'), catch, end, end
                if get(guiHandles.checkbox11, 'Value'), try hch16=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_5_', sFactor));hold on;set(hch16,'color', [linec.col11],'LineWidth',lwVal, 'LineStyle', '--'), catch, end, end
                if get(guiHandles.checkbox12, 'Value'), try hch17=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_6_', sFactor));hold on;set(hch17,'color', [linec.col12],'LineWidth',lwVal, 'LineStyle', '--'), catch, end, end
                if get(guiHandles.checkbox13, 'Value'), try hch18=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_7_', sFactor));hold on;set(hch18,'color', [linec.col13],'LineWidth',lwVal, 'LineStyle', '--'), catch, end, end

                if get(guiHandles.checkbox14, 'Value'), hch19=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'setpoint_3_', sFactor, 0.1));hold on;set(hch19,'color', [linec.col14],'LineWidth',lwVal), end

                axis([0 xmax 0 100])
                set(gca,'Color',th.axesBg);
                 h=fill([0,t1,t1,0],[0, 0, 100, 100],th.epochFill);
                 set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);
                 h=fill([t2,xmax,xmax,t2],[0, 0, 100, 100],th.epochFill);
                 set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);

                y=xlabel('Time (s)','fontweight','bold');
                set(y,'color',th.textPrimary);
                y=ylabel({'Throttle | Motor (%)'},'fontweight','bold');
                set(gca,'fontsize',fontsz,'XMinorGrid','on','ylim',[0 100],'ytick',[0 20 40 60 80 100],'fontweight','bold')
                set(gca,'xtick',[round(xmax/10):round(xmax/10):round(xmax)],'XColor',th.axesFg,'YColor',th.axesFg,'GridColor',th.gridColor)
                set(y,'color',th.textPrimary);
                grid on
                
                
    
                
            end

            try
                if ~expandON && ~isempty(LVpanels{ii})
                    set(LVpanels{ii},'color',th.axesBg,'fontsize',fontsz,'tickdir','in','xminortick','on','yminortick','on','position',posInfo.(['linepos' int2str(ii)]),'Tag','PSrpy');
                end
                if ~expandON
                    set(LVpanel5,'color',th.axesBg,'fontsize',fontsz,'tickdir','in','xminortick','on','yminortick','on','position',[posInfo.linepos4],'Tag','PSmotor');
                end
            catch
            end
        end

        % motor-only mode: fill available space when all RPY disabled
        if isempty(axesOptionsLV) && ~get(guiHandles.RPYcomboLV, 'Value') && ~expandON
            plotTop_m = posInfo.slider(2) - 0.005;
            motorFullH = plotTop_m - 0.1 - 0.01;
            LVpanel5 = axes('Parent', PSfig, 'Position', [plotL 0.1 plotW motorFullH], 'Tag', 'PSmotor');
            fileIdx = get(guiHandles.FileNum, 'Value');
            sFactor = lineSmoothFactors(get(guiHandles.lineSmooth, 'Value'));
            lwVal = get(guiHandles.linewidth, 'Value')/2;
            xmax = max(tta{fileIdx}/us2sec);
            tSec = tta{fileIdx}/us2sec;
            if get(guiHandles.checkbox10, 'Value'), try hch11=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_0_', sFactor));hold on;set(hch11,'color', [linec.col10],'LineWidth',lwVal), catch, end, end
            if get(guiHandles.checkbox11, 'Value'), try hch12=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_1_', sFactor));hold on;set(hch12,'color', [linec.col11],'LineWidth',lwVal), catch, end, end
            if get(guiHandles.checkbox12, 'Value'), try hch13=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_2_', sFactor));hold on;set(hch13,'color', [linec.col12],'LineWidth',lwVal), catch, end, end
            if get(guiHandles.checkbox13, 'Value'), try hch14=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'motor_3_', sFactor));hold on;set(hch14,'color', [linec.col13],'LineWidth',lwVal), catch, end, end
            if get(guiHandles.checkbox14, 'Value'), try hch19=plot(tSec, PSsmoothLV(PSfig, T{fileIdx}, fileIdx, 'setpoint_3_', sFactor, 0.1));hold on;set(hch19,'color', [linec.col14],'LineWidth',lwVal), catch, end, end
            axis([0 xmax 0 100])
            set(gca,'Color',th.axesBg);
            h=fill([0,t1,t1,0],[0, 0, 100, 100],th.epochFill);
            set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);
            h=fill([t2,xmax,xmax,t2],[0, 0, 100, 100],th.epochFill);
            set(h,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill);
            y=xlabel('Time (s)','fontweight','bold'); set(y,'color',th.textPrimary);
            y=ylabel({'Throttle | Motor (%)'},'fontweight','bold'); set(y,'color',th.textPrimary);
            set(gca,'fontsize',fontsz,'XMinorGrid','on','ylim',[0 100],'ytick',[0 20 40 60 80 100],'fontweight','bold')
            set(gca,'xtick',[round(xmax/10):round(xmax/10):round(xmax)],'XColor',th.axesFg,'YColor',th.axesFg,'GridColor',th.gridColor)
            grid on
            set(LVpanel5,'color',th.axesBg,'fontsize',fontsz,'tickdir','in','xminortick','on','yminortick','on','Tag','PSmotor');
        end
    end

    % eRPM overlay on motor subplot (per-motor RPM checkboxes)
    try delete(findobj(PSfig,'Tag','PSeRPMax')); catch, end
    try
    rpmEnabled_ = false(1,4);
    for rk_=1:4, try rpmEnabled_(rk_) = get(guiHandles.(['checkboxRPM' int2str(rk_)]), 'Value'); catch, end, end
    if any(rpmEnabled_)
        motorAx = findobj(PSfig, 'Type', 'axes', 'Tag', 'PSmotor');
        if ~isempty(motorAx)
            motorAx = motorAx(1);
            fileIdx_ = get(guiHandles.FileNum, 'Value');
            hasERPM = isfield(T{fileIdx_}, 'eRPM_0_');
            if hasERPM
                mPoles = 14;
                try
                    mpRow = find(strcmp(SetupInfo{fileIdx_}(:,1), 'motor_poles'));
                    if ~isempty(mpRow), mPoles = str2double(SetupInfo{fileIdx_}(mpRow(1),2)); end
                catch, end
                if mPoles < 2, mPoles = 14; end

                mPos = get(motorAx, 'Position');
                mXL = get(motorAx, 'XLim');
                tSec_ = tta{fileIdx_}/us2sec;
                sFactor_ = lineSmoothFactors(get(guiHandles.lineSmooth, 'Value'));
                lwVal_ = get(guiHandles.linewidth, 'Value')/2;

                rpmAx = axes('Parent', PSfig, 'Position', mPos, ...
                    'Color', 'none', 'XLim', mXL, ...
                    'YAxisLocation', 'right', 'Box', 'off', ...
                    'XTick', [], 'Tag', 'PSeRPMax', 'HitTest', 'off');
                hold(rpmAx, 'on');

                rpmColors = th.sigRPM;
                nEm_ = 0;
                for mk = 0:7
                    if isfield(T{fileIdx_}, ['eRPM_' int2str(mk) '_']), nEm_ = mk+1; end
                end
                rpmMax = 0;
                for mk = 0:nEm_-1
                    ci_ = mod(mk, 4) + 1;
                    if ~rpmEnabled_(ci_), continue; end
                    fld = ['eRPM_' int2str(mk) '_'];
                    if isfield(T{fileIdx_}, fld)
                        raw = PSsmoothLV(PSfig, T{fileIdx_}, fileIdx_, fld, sFactor_);
                        hz = raw * 100 / (mPoles/2) / 60;
                        ls_ = ':'; if mk >= 4, ls_ = '--'; end
                        plot(rpmAx, tSec_, hz, 'Color', rpmColors{ci_}, 'LineWidth', lwVal_, 'LineStyle', ls_, 'HitTest', 'off');
                        rpmMax = max(rpmMax, max(hz));
                    end
                end
                if rpmMax > 0
                    rpmCeil = ceil(rpmMax/100)*100;
                    rpmStep = rpmCeil / 5;
                    set(rpmAx, 'YLim', [0 rpmCeil], 'YColor', th.textSecondary, ...
                        'YTick', 0:rpmStep:rpmCeil, 'fontsize', fontsz, ...
                        'XColor', 'none', 'TickDir', 'in');
                    yl_ = ylabel(rpmAx, 'eRPM (Hz)', 'fontweight', 'bold');
                    set(yl_, 'color', th.textSecondary);
                    % epoch trim fills on RPM overlay
                    hf_=fill(rpmAx,[0,t1,t1,0],[0,0,rpmCeil,rpmCeil],th.epochFill);
                    set(hf_,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill,'HitTest','off');
                    hf_=fill(rpmAx,[t2,mXL(2),mXL(2),t2],[0,0,rpmCeil,rpmCeil],th.epochFill);
                    set(hf_,'FaceAlpha',th.epochAlpha,'EdgeColor',th.epochFill,'HitTest','off');
                end
            end
        end
    end
    catch, end

    % i/o keyboard trim: 'i' sets in-point, 'o' sets out-point
    set(PSfig, 'KeyPressFcn', [ ...
        'if exist(''filenameA'',''var'') && ~isempty(filenameA), ' ...
        'kk=get(gcbo,''CurrentCharacter''); fIdx=get(guiHandles.FileNum,''Value''); ' ...
        'if kk==''i'', try, [xt,~]=ginput(1); epoch1_A(fIdx)=round(xt*10)/10; PSplotLogViewer; catch, end; ' ...
        'elseif kk==''o'', try, [xt,~]=ginput(1); epoch2_A(fIdx)=round(xt*10)/10; PSplotLogViewer; catch, end; ' ...
        'end, end']);

    PSdatatipSetup(PSfig);
    try PSresizeCP(PSfig, []); catch, end

    set(PSfig, 'pointer', 'arrow')
else
     warndlg('Please select file(s)');
end


