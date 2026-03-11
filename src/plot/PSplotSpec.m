%% PSplotSpec - script that computes and plots spectrograms 


% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if exist('fnameMaster','var') && ~isempty(fnameMaster)

th = PStheme();

%% Read RPM overlay controls
rpmShowDN = true; rpmMotors = [1 2 3 4]; rpmHarms = [1 2 3]; rpmLw = 1; rpmShowEst = false;
if exist('guiHandlesSpec','var')
    try rpmShowDN = get(guiHandlesSpec.rpmDynNotch, 'Value'); catch, end
    try
        rpmMotors = [];
        if get(guiHandlesSpec.rpmMotor1, 'Value'), rpmMotors(end+1) = 1; end
        if get(guiHandlesSpec.rpmMotor2, 'Value'), rpmMotors(end+1) = 2; end
        if get(guiHandlesSpec.rpmMotor3, 'Value'), rpmMotors(end+1) = 3; end
        if get(guiHandlesSpec.rpmMotor4, 'Value'), rpmMotors(end+1) = 4; end
    catch, rpmMotors = [1 2 3 4]; end
    try
        harmSel = get(guiHandlesSpec.rpmHarmDd, 'Value');
        harmMap = {[], [1], [2], [3], [1 2], [1 3], [2 3], [1 2 3]};
        rpmHarms = harmMap{harmSel};
    catch, rpmHarms = [1 2 3]; end
    try
        lwSel = get(guiHandlesSpec.rpmLwDd, 'Value');
        lwMap = [0.5 1 1.5 2];
        rpmLw = lwMap(lwSel);
    catch, rpmLw = 1; end
    try rpmShowEst = get(guiHandlesSpec.rpmEstChk, 'Value'); catch, end
end

%% Compute RPM/notch data on-demand (mirrors PSplotSpec2D logic)
if exist('debugmode','var') && exist('debugIdx','var') && exist('T','var') && exist('tIND','var')
    if ~exist('notchData','var'), notchData = {}; end
    if ~exist('rpmFilterData','var'), rpmFilterData = {}; end
    for k_ = 1:numel(T)
        if numel(notchData) < k_ || isempty(notchData{k_})
            tmpFFT_ = FFT_FREQ;
            if numel(debugIdx) >= k_, tmpFFT_ = debugIdx{k_}.FFT_FREQ; end
            if debugmode(k_) == tmpFFT_
                try
                    if exist('fwMajor','var') && numel(fwMajor) >= k_ && fwMajor(k_) >= 2025
                        notchData{k_} = [T{k_}.debug_1_(tIND{k_}), T{k_}.debug_2_(tIND{k_}), T{k_}.debug_3_(tIND{k_})];
                    else
                        notchData{k_} = [T{k_}.debug_0_(tIND{k_}), T{k_}.debug_1_(tIND{k_}), T{k_}.debug_2_(tIND{k_})];
                    end
                catch, notchData{k_} = []; end
            end
        end
        if numel(rpmFilterData) < k_ || isempty(rpmFilterData{k_})
            tmpRPM_ = 46;
            if numel(debugIdx) >= k_, tmpRPM_ = debugIdx{k_}.RPM_FILTER; end
            if debugmode(k_) == tmpRPM_
                try rpmFilterData{k_} = [T{k_}.debug_0_(tIND{k_}), T{k_}.debug_1_(tIND{k_}), T{k_}.debug_2_(tIND{k_}), T{k_}.debug_3_(tIND{k_})];
                catch, rpmFilterData{k_} = []; end
            end
        end
    end
end

psdIdx = get(guiHandlesSpec.checkboxPSD, 'Value') + 1;
set(guiHandlesSpec.climMax_input, 'String', num2str(climScale(psdIdx, 1)));
set(guiHandlesSpec.climMax_input2, 'String', num2str(climScale(psdIdx, 2)));
set(guiHandlesSpec.climMax_input3, 'String', num2str(climScale(psdIdx, 3)));
set(guiHandlesSpec.climMax_input4, 'String', num2str(climScale(psdIdx, 4)));

%%

s1={'';'gyroADC';'debug';'piderr';'setpoint';'axisP';'axisD';'axisDpf';'pidsum'};

datSelectionString=[s1];

clear vars
for i=1:4
    vars(i)=get(guiHandlesSpec.SpecSelect{i}, 'Value');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%% compute fft %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if get(guiHandlesSpec.SpecSelect{1}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{2}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{3}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{4}, 'Value')>1
    set(PSspecfig, 'pointer', 'watch')
    if updateSpec==0 
        clear s dat ampmat amp2d freq a RC smat amp2d freq2d Throt
        p=0;
         hw = waitbar(0,['please wait... ' ]); 

        tmpPSDVal = get(guiHandlesSpec.checkboxPSD, 'Value');
        for k=1:length(vars)
            tmpFileSelK = get(guiHandlesSpec.FileSelect{k}, 'Value');
            s=char(datSelectionString(vars(k)));
            for a=1:3,
                if  ( ( ~isempty(strfind(s,'axisD'))) && a==3) || isempty(s)
                    p=p+1;
                    smat{p}=[];%string
                    ampmat{p}=[];%spec matrix
                    freq{p}=[];% freq matrix
                    amp2d{p}=[];%spec 2d
                    freq2d{p}=[];% freq2d
                else
                    p=p+1;
                    try
                    fld = [char(datSelectionString(vars(k))) '_' int2str(a-1) '_'];
                    dat{k}(a,:) = T{tmpFileSelK}.(fld)(tIND{tmpFileSelK});
                    Throt=T{tmpFileSelK}.setpoint_3_(tIND{tmpFileSelK}) / 10;% throttle
                    lograte = A_lograte(tmpFileSelK);%in kHz
                    waitbar(min(1, p/12), hw, ['processing spectrogram... '  int2str(p) ]);
                    smat{p}=s;
                    [freq{p} ampmat{p}]=PSthrSpec(Throt, dat{k}(a,:), lograte, tmpPSDVal); % compute matrices
                    [freq2d{p} amp2d{p}]=PSSpec2d(dat{k}(a,:),lograte, tmpPSDVal); %compute 2d amp spec at same time
                    catch ME
                        warning('PSplotSpec compute p=%d: %s', p, ME.message);
                        smat{p}=[]; ampmat{p}=[]; freq{p}=[]; amp2d{p}=[]; freq2d{p}=[];
                    end
               end
            end
        end
        close(hw)
    end
else
    hwarn=warndlg({'Dropdowns set to ''NONE''.'; 'Please select a preset or specific variables to analyze.'});
    pause(3);
    try
        close(hwarn);
    catch
    end
end

if get(guiHandlesSpec.checkbox2d, 'Value')==0 && ~isempty(ampmat)
    figure(PSspecfig);
    %%%%% plot spec mattrices
    c1=[1 1 1 2 2 2 3 3 3 4 4 4];
    c2=[1 2 3 1 2 3 1 2 3 1 2 3];
    baselineY = [0 -40];
    ftr = fspecial('gaussian',[get(guiHandlesSpec.smoothFactor_select, 'Value')*5 get(guiHandlesSpec.smoothFactor_select, 'Value')],4);
    for p=1:size(ampmat,2)
        try delete(subplot('position',posInfo.SpecPos(p,:))); catch, end
        if ~isempty(ampmat{p})
        try
            delete(subplot('position',posInfo.SpecPos(p,:)));
            h1=subplot('position',posInfo.SpecPos(p,:)); cla
            set(h1, 'Tag', 'PSgrid');
            img = flipud((filter2(ftr, ampmat{p} ))') + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
            imagesc(img); 

            lograte=A_lograte(get(guiHandlesSpec.FileSelect{c1(p)}, 'Value'));

             axLabel={'roll';'pitch';'yaw'};
            
            if get(guiHandlesSpec.Sub100HzCheck{c1(p)}, 'Value')==1
                hold on;h=plot([0 100],[size(ampmat{p},2)-round(Flim1/3.33) size(ampmat{p},2)-round(Flim1/3.33)],'y--');set(h,'linewidth',2) 
                hold on;h=plot([0 100],[size(ampmat{p},2)-round(Flim2/3.33) size(ampmat{p},2)-round(Flim2/3.33)],'y--');set(h,'linewidth',2)
                % sub100Hz scaling           
                xticks=round([1 size(ampmat{p},1)/5:size(ampmat{p},1)/5:size(ampmat{p},1)]);
                yticks=round([(size(ampmat{p},2)-30):6:size(ampmat{p},2)]);
                set(h1,'PlotBoxAspectRatioMode','auto','ylim',[size(ampmat{p},2)-30 size(ampmat{p},2)])
                set(h1,'fontsize',fontsz,'CLim',[baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'YTick',yticks,'yticklabel',{'100';'80';'60';'40';'20';'0'},'XTick',xticks,'xticklabel',{'0';'20';'40';'60';'80';'100'},'tickdir','out','xminortick','on','yminortick','on');
                a=[];a2=[];a=filter2(ftr, ampmat{p}) + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
                a2 = a(:,(round(Flim1/3.33))+1:(round(Flim2/3.33)));
                meanspec=nanmean(a2(:));
                peakspec=max(max(a(:,(round(Flim1/3.33))+1:(round(Flim2/3.33)))));
                if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9          
                    h=text(64,(size(ampmat{p},2)-30)+3,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                    h=text(64,(size(ampmat{p},2)-30)+1,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                else
                    h=text(64,(size(ampmat{p},2)-30)+3,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                    h=text(64,(size(ampmat{p},2)-30)+1,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                end  
                h=text(xticks(1)+1,(size(ampmat{p},2)-30)+1,axLabel{c2(p)});
                set(h,'Color',[1 1 1],'fontsize',fontsz,'fontweight','bold')                       
            else % full scaling
                xticks=round([1 size(ampmat{p},1)/5:size(ampmat{p},1)/5:size(ampmat{p},1)]);
                yticks=round([1:(size(ampmat{p},2))/10:size(ampmat{p},2) size(ampmat{p},2)]);
                maxHz = max(round(yticks * 3.333));
                ytlbl = {num2str(maxHz), '', num2str(round(maxHz*4/5)), '', num2str(round(maxHz*3/5)), '', num2str(round(maxHz*2/5)), '', num2str(round(maxHz*1/5)), '', '0'};
                set(h1,'fontsize',fontsz,'CLim',[baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'YTick',yticks,'yticklabel',ytlbl,'XTick',xticks,'xticklabel',{'0';'20';'40';'60';'80';'100'},'tickdir','out','xminortick','on','yminortick','on');
                set(h1,'PlotBoxAspectRatioMode','auto','ylim',[1 size(ampmat{p},2)])  
                a=[];a2=[];a=filter2(ftr, ampmat{p}) + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
                a2 = a(:,round(size(ampmat{p},2)/10):size(ampmat{p},2));
                meanspec=nanmean(a2(:));
                peakspec=max(max(a(:,round(size(ampmat{p},2)/10):size(ampmat{p},2))));
                if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9
                    h=text(64,size(ampmat{p},2)*.04,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                    h=text(64,size(ampmat{p},2)*.13,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                else
                    h=text(64,size(ampmat{p},2)*.04,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                    h=text(64,size(ampmat{p},2)*.13,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                end    
                h=text(xticks(1)+1,size(ampmat{p},2)*.04,axLabel{c2(p)});
                set(h,'Color',[1 1 1],'fontsize',fontsz,'fontweight','bold')   
            end
            
                        
            grid on
            ax = gca;
            PSstyleAxes(ax, th);
            set(ax, 'GridColor', [1 1 1]);
            if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9
                set(ax, 'GridColor', [0 0 0]);
                set(h,'Color',[0 0 0],'fontsize',fontsz,'fontweight','bold')
            end
             ylabel('Frequency (Hz)','fontweight','bold','Color',th.textPrimary)
             xlabel('% Throttle','fontweight','bold','Color',th.textPrimary)

            %% Dynamic notch overlay for FFT_FREQ mode
            if rpmShowDN && exist('notchData','var') && exist('debugmode','var') && exist('debugIdx','var')
                tmpFileK = get(guiHandlesSpec.FileSelect{c1(p)}, 'Value');
                tmpFFTk = FFT_FREQ;
                if numel(debugIdx) >= tmpFileK
                    tmpFFTk = debugIdx{tmpFileK}.FFT_FREQ;
                end
                if debugmode(tmpFileK) == tmpFFTk && numel(notchData) >= tmpFileK && ~isempty(notchData{tmpFileK})
                    maxHzOverlay = (A_lograte(tmpFileK) / 2) * 1000;
                    PSplotDynNotchOverlay(gca, notchData{tmpFileK}, T{tmpFileK}.setpoint_3_(tIND{tmpFileK}) / 10, size(img, 1), maxHzOverlay, 'throttle', rpmLw);
                end
            end

            %% RPM filter overlay (motor frequencies + harmonics)
            if ~isempty(rpmHarms) && ~isempty(rpmMotors) && exist('rpmFilterData','var') && exist('debugmode','var') && exist('debugIdx','var')
                tmpFileK2 = get(guiHandlesSpec.FileSelect{c1(p)}, 'Value');
                tmpRPMk = 46;
                if numel(debugIdx) >= tmpFileK2
                    tmpRPMk = debugIdx{tmpFileK2}.RPM_FILTER;
                end
                if debugmode(tmpFileK2) == tmpRPMk && numel(rpmFilterData) >= tmpFileK2 && ~isempty(rpmFilterData{tmpFileK2})
                    maxHzOverlay2 = (A_lograte(tmpFileK2) / 2) * 1000;
                    PSplotRPMOverlay(gca, rpmFilterData{tmpFileK2}, T{tmpFileK2}.setpoint_3_(tIND{tmpFileK2}) / 10, size(img, 1), maxHzOverlay2, 'throttle', 3, rpmMotors, rpmHarms, rpmLw);
                end
            end

            %% Estimated RPM overlay from spectrum peak detection
            if rpmShowEst && ~isempty(rpmHarms) && ~isempty(ampmat{p}) && ~isempty(freq{p})
                % find a throttle row that has freq data (not all zeros)
                freqAx = [];
                for rr = 1:size(freq{p}, 1)
                    if any(freq{p}(rr,:) > 0), freqAx = freq{p}(rr,:); break; end
                end
                if ~isempty(freqAx)
                [estFund, estHarm] = PSestimateRPM(freqAx, ampmat{p}, 3);
                % smooth estimated harmonics (moving average, NaN-safe)
                smK = 7;
                for sc = 1:size(estHarm, 2)
                    col = estHarm(:, sc);
                    sm = col;
                    for sw = 1:numel(col)
                        lo = max(1, sw - floor(smK/2));
                        hi = min(numel(col), sw + floor(smK/2));
                        chunk = col(lo:hi);
                        chunk = chunk(~isnan(chunk) & chunk > 0);
                        if numel(chunk) >= 2, sm(sw) = mean(chunk); else sm(sw) = NaN; end
                    end
                    estHarm(:, sc) = sm;
                end
                maxHzEst = (A_lograte(get(guiHandlesSpec.FileSelect{c1(p)}, 'Value')) / 2) * 1000;
                hz_per_px = maxHzEst / size(img, 1);
                hold on;
                estCol = [0 .9 .2; .9 .7 0; .9 .2 0];
                estStyle = {'-'; '--'; ':'};
                for nh = rpmHarms
                    if nh > size(estHarm, 2), continue; end
                    xPts = []; yPts = [];
                    for tb = 1:100
                        if ~isnan(estHarm(tb, nh)) && estHarm(tb, nh) > 0 && estHarm(tb, nh) < maxHzEst
                            y_px = size(img, 1) - round(estHarm(tb, nh) / hz_per_px);
                            if y_px >= 1 && y_px <= size(img, 1)
                                xPts(end+1) = tb;
                                yPts(end+1) = y_px;
                            end
                        end
                    end
                    if ~isempty(xPts)
                        h = plot(xPts, yPts, estStyle{nh}, 'LineWidth', rpmLw);
                        set(h, 'Color', estCol(nh,:), 'HitTest', 'off');
                    end
                end
                end % ~isempty(freqAx)
            end

        catch ME
            warning('PSplotSpec render p=%d: %s', p, ME.message);
        end
        end
    end

    % color bar2 at the top 
    try
    delete(findobj(PSspecfig, 'Tag', 'PScbar'))
    catch
    end
    % Standalone colorbar axes — avoids colorbar('NorthOutside') which resizes subplots in Octave
    bY = baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
    cbarPosAll = {posInfo.hCbar1pos, posInfo.hCbar2pos, posInfo.hCbar3pos, posInfo.hCbar4pos};
    for ci = 1:4
        if vars(ci) > 1
            cHi = climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, ci);
            hCb = axes('Position', cbarPosAll{ci});
            imagesc(hCb, linspace(bY, cHi, 256));
            set(hCb, 'CLim', [bY cHi], 'XTick', [], 'YTick', [], 'Tag', 'PScbar', 'UserData', 'north');
        end
    end

    % color maps
    try
        if ishandle(PSspecfig)
            tmpCmapVal = get(guiHandlesSpec.ColormapSelect, 'Value');
            if tmpCmapVal <= 7
                tmpCmapStr = get(guiHandlesSpec.ColormapSelect, 'String');
                cm = feval(char(tmpCmapStr(tmpCmapVal)), 64);
            elseif tmpCmapVal == 8
                cm = linearREDcmap;
            else
                cm = linearGREYcmap;
            end
            colormap(PSspecfig, cm);
        end
    catch, end

end

if get(guiHandlesSpec.checkbox2d, 'Value')==1 && ~isempty(amp2d)
    figure(PSspecfig);
    try
    delete(findobj(PSspecfig, 'Tag', 'PScbar'))
    catch
    end
    baselineYlines = [0 -50];
    c1=[1 1 1 2 2 2 3 3 3 4 4 4];
    c2=[1 2 3 1 2 3 1 2 3 1 2 3]; 
    %%%%% plot 2d amp spec
    for p=1:size(amp2d,2)
         axLabel={'roll';'pitch';'yaw'};
       
        delete(subplot('position',posInfo.SpecPos(p,:)));
        if ~isempty(amp2d{p})
            h2=subplot('position',posInfo.SpecPos(p,:)); cla
            set(h2, 'Tag', 'PSgrid');
            h=plot(freq2d{p}, smooth(amp2d{p}, log10(size(amp2d{p},1)) * (get(guiHandlesSpec.smoothFactor_select, 'Value')^2), 'lowess'));hold on
            set(h, 'linewidth', get(guiHandles.linewidth, 'Value')/2)
            set(h2,'fontsize',fontsz,'fontweight','bold')
            if get(guiHandlesSpec.specPresets, 'Value') <= 3
                set(h,'Color',[SpecLineCols(c1(p),:,1)])
            end
            if get(guiHandlesSpec.specPresets, 'Value') > 4 && get(guiHandlesSpec.specPresets, 'Value') <= 6
                set(h,'Color',[SpecLineCols(c1(p),:,2)])
            end
            if get(guiHandlesSpec.specPresets, 'Value') > 6
                set(h,'Color',[SpecLineCols(c1(p),:,3)])
            end
            
            if get(guiHandlesSpec.Sub100HzCheck{c1(p)}, 'Value')==1
                set(h2,'xtick',[0 20 40 60 80 100], 'yminortick','on')
                axis([0 100 baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))])
                h=plot([round(Flim1) round(Flim1)],[baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'--','Color',th.axesFg);
                set(h,'linewidth',1)
                h=plot([round(Flim2) round(Flim2)],[baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'--','Color',th.axesFg);
                set(h,'linewidth',1)
            else    
                set(h2,'xtick',[0 : ((A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000 / 5) : (A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000],'yminortick','on')
                axis([0 (A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000 baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))])
            end

            xlabel('Frequency (Hz)','Color',th.textPrimary)
            if get(guiHandlesSpec.checkboxPSD, 'Value')
                ylabel(['PSD (dB)'],'Color',th.textPrimary)
            else
                ylabel(['Amplitude'],'Color',th.textPrimary)
            end
                

            h=text(2,climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))*.95,axLabel{c2(p)});
            set(h,'Color',th.textPrimary,'fontsize',fontsz,'fontweight','bold')

            grid on
            PSstyleAxes(gca, th);
        end
    end
end
PSdatatipSetup(PSspecfig);
try PSresizeCP(PSspecfig, []); catch, end

set(PSspecfig, 'pointer', 'arrow')
updateSpec=0;

end

