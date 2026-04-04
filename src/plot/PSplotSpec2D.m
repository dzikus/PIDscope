%% PSplotSpec2D - script that computes and plots spectrograms 


% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if exist('fnameMaster','var') && ~isempty(fnameMaster)
th = PStheme();

set(guiHandlesSpec2.climMax1_input, 'String', num2str(climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1)));
set(guiHandlesSpec2.climMax2_input, 'String', num2str(climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1, 1)));


%%

s1={'gyroADC';'gyroPrefilt';'axisD';'axisDpf';'axisP';'piderr';'setpoint';'axisF';'pidsum';'motorAvg'};
if isfield(T{1}, 'testSignal_0_'), s1{end+1} = 'testSignal'; end

datSelectionString=[s1];
axesOptionsSpec = find([get(guiHandlesSpec2.plotR, 'Value') get(guiHandlesSpec2.plotP, 'Value') get(guiHandlesSpec2.plotY, 'Value')]);

% scale row heights to fill space when fewer than 3 RPY axes
nActiveSpec = numel(axesOptionsSpec);
stdRows = [0.69 0.395 0.1]; stdRowH = 0.25;
if nActiveSpec > 0 && nActiveSpec < 3 && ~get(guiHandlesSpec2.RPYcomboSpec, 'Value')
    topY_s = stdRows(1) + stdRowH; botY_s = stdRows(3); gapS = 0.045;
    rowH_s = (topY_s - botY_s - (nActiveSpec-1)*gapS) / nActiveSpec;
    ci = 0;
    for jj = axesOptionsSpec
        ci = ci + 1;
        yy = topY_s - ci*rowH_s - (ci-1)*gapS;
        posInfo.Spec2Pos(jj, 2) = yy; posInfo.Spec2Pos(jj, 4) = rowH_s;
        posInfo.Spec2Pos(jj+3, 2) = yy; posInfo.Spec2Pos(jj+3, 4) = rowH_s;
    end
else
    for jj = 1:3
        posInfo.Spec2Pos(jj, 2) = stdRows(jj); posInfo.Spec2Pos(jj, 4) = stdRowH;
        posInfo.Spec2Pos(jj+3, 2) = stdRows(jj); posInfo.Spec2Pos(jj+3, 4) = stdRowH;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% compute fft %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(PSspecfig2, 'pointer', 'watch')

%%% compute delay/overlay data (deferred from UI open to Run click)
if ~exist('delayDataReady','var') || ~delayDataReady
    hw_delay = waitbar(0, 'computing delays...');
    FilterDelayDterm={};
    SPGyroDelay=[];
    Debug01={};
    Debug02={};
    gyro_phase_shift_deg=zeros(Nfiles,1);
    dterm_phase_shift_deg=zeros(Nfiles,1);
    notchData={};
    rpmFilterData={};
    for k = 1 : Nfiles
        waitbar(k/Nfiles, hw_delay, ['computing delays... file ' int2str(k) '/' int2str(Nfiles)]);
        Fs=1000/A_lograte(k);
        maxlag=round(30000/Fs);

        try
            if isfield(T{k}, 'gyroPrefilt_0_')
                pg = smooth(T{k}.gyroPrefilt_0_(tIND{k}),50);
            else
                pg = smooth(T{k}.debug_0_(tIND{k}),50);
            end
        catch
            pg = [];
        end
        try
            g1 = smooth(T{k}.gyroADC_0_(tIND{k}),50);
            s1 = smooth(T{k}.setpoint_0_(tIND{k}),50);
            g2 = smooth(T{k}.gyroADC_1_(tIND{k}),50);
            s2 = smooth(T{k}.setpoint_1_(tIND{k}),50);
            g3 = smooth(T{k}.gyroADC_2_(tIND{k}),50);
            s3 = smooth(T{k}.setpoint_2_(tIND{k}),50);

            if isempty(pg), pg = zeros(size(g1)); end

            [c,lags] = xcorr(g1,pg,maxlag);
            d = lags(find(c==max(c),1));
            d = d * (Fs / 1000);
            if d<.1, Debug01{k} = ' '; else Debug01{k} = num2str(d); end

            [c,lags] = xcorr(s1,pg,maxlag);
            d = lags(find(c==max(c),1));
            d = d * (Fs / 1000);
            if d<.1, Debug02{k} = ' '; else Debug02{k} = num2str(d); end

            [c,lags] = xcorr(g1,s1,maxlag);
            d = lags(find(c==max(c),1)); d = d * (Fs / 1000);
            if d<.1, SPGyroDelay(k,1) = 0; else, SPGyroDelay(k,1) = d; end

            [c,lags] = xcorr(g2,s2,maxlag);
            d = lags(find(c==max(c),1)); d = d * (Fs / 1000);
            if d<.1, SPGyroDelay(k,2) = 0; else, SPGyroDelay(k,2) = d; end

            [c,lags] = xcorr(g3,s3,maxlag);
            d = lags(find(c==max(c),1)); d = d * (Fs / 1000);
            if d<.1, SPGyroDelay(k,3) = 0; else, SPGyroDelay(k,3) = d; end

            try
                d1 = smooth(T{k}.axisDpf_0_(tIND{k}),50);
                d2 = smooth(T{k}.axisD_0_(tIND{k}),50);
                [c,lags] = xcorr(d2,d1,maxlag);
                d = lags(find(c==max(c)));
                d = d * (Fs / 1000);
                if d<.1, FilterDelayDterm{k} = ' '; else FilterDelayDterm{k} = num2str(d); end
            catch
                FilterDelayDterm{k} = ' ';
            end
        catch
            Debug01{k} = ' '; Debug02{k} = ' '; FilterDelayDterm{k} = ' ';
        end

        try
            if ~isempty(str2double(Debug01{k})) && ~isnan(str2double(Debug01{k})) && SPGyroDelay(k,1) > 0
                gyro_phase_shift_deg(k,1) = round(PSphaseShiftDeg(str2double(Debug01{k}), 1000/(SPGyroDelay(k,1))));
            end
            if ~isempty(str2double(FilterDelayDterm{k})) && ~isnan(str2double(FilterDelayDterm{k})) && SPGyroDelay(k,1) > 0
                dterm_phase_shift_deg(k,1) = round(PSphaseShiftDeg(str2double(FilterDelayDterm{k}), 1000/(SPGyroDelay(k,1))));
            end
        catch, end

        % dynamic notch data for FFT_FREQ overlay
        tmpFFTidx = FFT_FREQ;
        if exist('debugIdx','var') && numel(debugIdx) >= k
            tmpFFTidx = debugIdx{k}.FFT_FREQ;
        end
        if exist('debugmode','var') && numel(debugmode) >= k && debugmode(k) == tmpFFTidx
            if exist('fwMajor','var') && numel(fwMajor) >= k && fwMajor(k) >= 2025
                notchData{k} = [T{k}.debug_1_(tIND{k}), T{k}.debug_2_(tIND{k}), T{k}.debug_3_(tIND{k})];
            else
                notchData{k} = [T{k}.debug_0_(tIND{k}), T{k}.debug_1_(tIND{k}), T{k}.debug_2_(tIND{k})];
            end
        else
            notchData{k} = [];
        end

        % RPM filter data for motor noise overlay
        tmpRPMidx = 46;
        if exist('debugIdx','var') && numel(debugIdx) >= k
            tmpRPMidx = debugIdx{k}.RPM_FILTER;
        end
        if exist('debugmode','var') && numel(debugmode) >= k && debugmode(k) == tmpRPMidx
            rpmFilterData{k} = [T{k}.debug_0_(tIND{k}), T{k}.debug_1_(tIND{k}), ...
                                T{k}.debug_2_(tIND{k}), T{k}.debug_3_(tIND{k})];
        else
            rpmFilterData{k} = [];
        end
    end
    delayDataReady = true;
    try close(hw_delay); catch, end
end

tmpSpecVal = get(guiHandlesSpec2.SpecList, 'Value');
tmpFileVal = get(guiHandlesSpec2.FileSelect, 'Value');
tmpPSDVal = get(guiHandlesSpec2.checkboxPSD, 'Value');

% skip PSD recompute when only right-column controls changed
needFFT_ = true;
if exist('prevPsdKey_','var') && exist('freq2d2','var') && ~isempty(freq2d2) && ~updateSpec
    if isequal(tmpSpecVal, prevPsdKey_.specVal) && isequal(tmpFileVal, prevPsdKey_.fileVal) && ...
       tmpPSDVal == prevPsdKey_.psdVal && isequal(axesOptionsSpec, prevPsdKey_.axes)
        needFFT_ = false;
    end
end

if needFFT_
clear s dat a RC smat amp2d2 freq2d2
freq2d2 = {};
amp2d2 = {};
p=0;
hw_fft = waitbar(0, 'computing FFT...');
for k = 1 : length(tmpSpecVal)
    s = char(datSelectionString(tmpSpecVal(k)));
    for f = 1 : size(tmpFileVal,2)
        for a = axesOptionsSpec
            if  ( ( ~isempty(strfind(s,'axisD'))) && a==3) || isempty(s)
                p=p+1;
                smat{p}=[];%string
                amp2d2{p}=[];%spec 2d
                freq2d2{p}=[];% freq2d2
            elseif strcmp(s, 'motorAvg')
                p = p + 1;
                mAvg = zeros(sum(tIND{tmpFileVal(f)}), 1);
                nMot = 0;
                for mi = 0:3
                    mf = ['motor_' int2str(mi) '_'];
                    if isfield(T{tmpFileVal(f)}, mf)
                        mAvg = mAvg + T{tmpFileVal(f)}.(mf)(tIND{tmpFileVal(f)});
                        nMot = nMot + 1;
                    end
                end
                if nMot > 0, mAvg = mAvg / nMot; end
                dat = mAvg';
                lograte = A_lograte(tmpFileVal(f));
                smat{p} = s;
                [tmpF tmpA] = PSSpec2d(dat, lograte, tmpPSDVal);
                if isempty(tmpF)
                    smat{p}=[]; amp2d2{p}=[]; freq2d2{p}=[];
                else
                    ff = ['f' int2str(f)];
                    freq2d2{p}.(ff) = tmpF;
                    amp2d2{p}.(ff) = tmpA;
                end
            elseif ~isfield(T{tmpFileVal(f)}, [s '_' int2str(a-1) '_'])
                p=p+1;
                smat{p}=[]; amp2d2{p}=[]; freq2d2{p}=[];
            else
                p = p + 1;
                fld = [s '_' int2str(a-1) '_'];
                dat = T{tmpFileVal(f)}.(fld)(tIND{tmpFileVal(f)})';
                lograte = A_lograte(tmpFileVal(f));
                smat{p}=s;
                waitbar(min(1, p/(length(tmpSpecVal)*size(tmpFileVal,2)*length(axesOptionsSpec))), hw_fft, ['computing FFT... ' int2str(p)]);
                ff = ['f' int2str(f)];
                [tmpF tmpA] = PSSpec2d(dat,lograte, tmpPSDVal);
                if isempty(tmpF)
                    smat{p}=[]; amp2d2{p}=[]; freq2d2{p}=[];
                else
                    freq2d2{p}.(ff) = tmpF;
                    amp2d2{p}.(ff) = tmpA;
                end
            end
       end
    end
end
try close(hw_fft); catch, end
prevPsdKey_ = struct('specVal', tmpSpecVal, 'fileVal', tmpFileVal, 'psdVal', tmpPSDVal, 'axes', axesOptionsSpec);
end

figure(PSspecfig2);
baselineYlines = [0 -50];
multilineStyle = {'-' ; ':'; '--'};
rpyLineStyle = {'-' ; '--'; ':'};

% skip left-column rerender when only right-column controls changed
tmpSmoothVal = get(guiHandlesSpec2.smoothFactor_select, 'Value');
rightMode_chk_ = 1; try rightMode_chk_ = get(guiHandlesSpec2.rightColMode, 'Value'); catch, end
leftKey_ = struct('specVal', tmpSpecVal, 'fileVal', tmpFileVal, 'psdVal', tmpPSDVal, ...
    'axes', axesOptionsSpec, 'smooth', tmpSmoothVal, 'rightCol', rightMode_chk_);
try leftKey_.clim1 = get(guiHandlesSpec2.climMax1_input, 'String');
    leftKey_.clim2 = get(guiHandlesSpec2.climMax2_input, 'String');
    leftKey_.delay = get(guiHandlesSpec2.Delay, 'Value');
    leftKey_.combo = get(guiHandlesSpec2.RPYcomboSpec, 'Value');
catch, end
skipLeftRender_ = ~needFFT_ && exist('prevLeftKey_','var') && isequal(leftKey_, prevLeftKey_);
% invalidate if axes were deleted externally
if skipLeftRender_ && isempty(findobj(PSspecfig2, 'Type', 'axes', 'Tag', 'PSspec2_1')), skipLeftRender_ = false; end

if ~skipLeftRender_
% cla active panels, delete unchecked ones so they don't linger at old positions
for di_=1:3
    for si_=[di_ di_+3]
        h_cla=findobj(PSspecfig2,'Type','axes','Tag',sprintf('PSspec2_%d',si_));
        if ~isempty(h_cla)
            if any(axesOptionsSpec == di_), cla(h_cla); hold(h_cla,'off');
            else delete(h_cla); end
        end
    end
end
h_del=findobj(PSspecfig2,'Type','axes','Tag','PSspec2_combo'); if ~isempty(h_del), delete(h_del); end
h_del=findobj(PSspecfig2,'Type','axes','Tag','legend'); if ~isempty(h_del), delete(h_del); end
%%%%% plot 2d amp spec
axLabel={'Roll';'Pitch';'Yaw'};

p = 0;
tmpSpecVal = get(guiHandlesSpec2.SpecList, 'Value');
tmpFileVal = get(guiHandlesSpec2.FileSelect, 'Value');
tmpPSDVal = get(guiHandlesSpec2.checkboxPSD, 'Value');
for k = 1 : length(tmpSpecVal)
    s = char(datSelectionString(tmpSpecVal(k)));
    for f = 1 : size(tmpFileVal,2)
        lineCol = multiLineCols(f,:);
        isTS = strcmp(s, 'testSignal');
        if isTS, lineCol = th.sigTestSignal; end
        cnt = 0;
        for a = axesOptionsSpec
            cnt = cnt + 1;
            p = p + 1;
            if ~isempty(freq2d2)
                if ~isempty(freq2d2{p}) && ~isempty(amp2d2{p})
                    
                    if get(guiHandlesSpec2.RPYcomboSpec, 'Value') == 0

                        stag_ = sprintf('PSspec2_%d', a);
                        h2 = findobj(PSspecfig2, 'Type', 'axes', 'Tag', stag_);
                        if isempty(h2), h2 = axes('Parent', PSspecfig2, 'Position', posInfo.Spec2Pos(a,:), 'Tag', stag_);
                        else set(h2, 'Position', posInfo.Spec2Pos(a,:)); set(PSspecfig2, 'CurrentAxes', h2); end
                        ff = ['f' int2str(f)];
                        h=plot(freq2d2{p}.(ff), smooth(amp2d2{p}.(ff), log10(size(amp2d2{p}.(ff),1)) * (tmpSmoothVal^3), 'lowess')); hold on
                        hold on
                        lsty = multilineStyle{k}; if isTS, lsty = '-'; end
                        lw_ = get(guiHandles.linewidth, 'Value')/2;
                        if k > 1, lw_ = lw_ * 0.6; end
                        set(h, 'linewidth', lw_,'linestyle',lsty)
                        set(h2,'fontsize',fontsz)
                        set(h,'Color',[lineCol])
                        m = (A_lograte(tmpFileVal(f)) * 1000) / 2;
                        set(h2,'xtick',[0:m/10:m], 'yminortick','on')
                        if ~strcmp(s, 'motorAvg')
                            axis([0 m climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1) climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)])
                        else
                            set(h2, 'XLim', [0 m]);
                        end
                        xlabel('Frequency (Hz)','fontweight','bold','Color',th.textPrimary);
                        if get(guiHandlesSpec2.checkboxPSD, 'Value')
                            ylabel(['Power Spectral Density (dB)'],'fontweight','bold','Color',th.textPrimary);
                        else
                            ylabel(['Amplitude'],'fontweight','bold','Color',th.textPrimary);
                        end
                        if a == 1
                            title('Full Spectrum','fontweight','bold','Color',th.textPrimary);
                        end
                        if p < 4
                        h=text(2,climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)*.92,axLabel{a});
                        set(h,'Color',th.textPrimary,'fontsize',fontsz,'fontweight','bold');
                        end
                        grid on

                        rightMode_ = 1;
                        try rightMode_ = get(guiHandlesSpec2.rightColMode, 'Value'); catch, end

                        if rightMode_ ~= 2
                        stag2_ = sprintf('PSspec2_%d', a+3);
                        h2 = findobj(PSspecfig2, 'Type', 'axes', 'Tag', stag2_);
                        if isempty(h2), h2 = axes('Parent', PSspecfig2, 'Position', posInfo.Spec2Pos(a+3,:), 'Tag', stag2_);
                        else set(h2, 'Position', posInfo.Spec2Pos(a+3,:)); set(PSspecfig2, 'CurrentAxes', h2); end

                        if strcmp(s, 'motorAvg')
                            set(h2, 'Visible', 'on');
                            PSstyleAxes(h2, th);
                        else
                        % Sub 100Hz PSD
                        ff = ['f' int2str(f)];
                        h=plot(freq2d2{p}.(ff), smooth(amp2d2{p}.(ff), log10(size(amp2d2{p}.(ff),1)) * (tmpSmoothVal^3), 'lowess')); hold on
                        hold on
                        lsty = multilineStyle{k}; if isTS, lsty = '-'; end
                        lw_ = get(guiHandles.linewidth, 'Value')/2;
                        if k > 1, lw_ = lw_ * 0.6; end
                        set(h, 'linewidth', lw_,'linestyle',lsty)
                        set(h2,'fontsize',fontsz)
                        set(h,'Color',[lineCol])
                        m = (A_lograte(tmpFileVal(f)) * 1000) / 2;
                        set(h2,'xtick',[0 20 40 60 80 100],'yminortick','on')
                        axis([0 100 climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1) climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)])
                        xlabel('Frequency (Hz)','fontweight','bold','Color',th.textPrimary);
                        if get(guiHandlesSpec2.checkboxPSD, 'Value')
                            ylabel(['Power Spectral Density (dB)'],'fontweight','bold','Color',th.textPrimary);
                        else
                            ylabel(['Amplitude'],'fontweight','bold','Color',th.textPrimary);
                        end
                        if a == 1
                            title('Sub 100Hz','fontweight','bold','Color',th.textPrimary);
                        end
                        if p < 4
                        h=text(1,climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)*.92,axLabel{a});
                        set(h,'Color',th.textPrimary,'fontsize',fontsz,'fontweight','bold');
                        end
                        end  % motorAvg
                        end  % rightMode_
                        
                        %%%%%%%%%%%%%%%%%%% Plot Latencies %%%%%%%%%%%%%%%
                        tmpFileSelVals = get(guiHandlesSpec2.FileSelect, 'Value');
                        tmpFileIdx = tmpFileSelVals(f);
                        % Per-file debug mode indices (BF version-aware)
                        if exist('debugIdx','var') && numel(debugIdx) >= tmpFileIdx
                            tmpDbgIdx = debugIdx{tmpFileIdx};
                        else
                            tmpDbgIdx = struct('GYRO_SCALED',6,'GYRO_FILTERED',3,'RC_INTERPOLATION',7,'FFT_FREQ',17,'FEEDFORWARD',59);
                        end
                        if get(guiHandlesSpec2.Delay, 'Value') == 1 && a == 1
                            if debugmode(tmpFileIdx) == tmpDbgIdx.GYRO_SCALED || debugmode(tmpFileIdx) == tmpDbgIdx.GYRO_FILTERED || debugmode(tmpFileIdx) == 1 || debugmode(tmpFileIdx) == 0
                                h=text(65, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['Gyro Filter: ' Debug01{tmpFileIdx} 'ms | Dterm Filter: ' FilterDelayDterm{tmpFileIdx} 'ms']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            else
                                h=text(65, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['Gyro Filter: ' 'ms | Dterm Filter: ' FilterDelayDterm{tmpFileIdx} 'ms']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            end
                        end
                        if get(guiHandlesSpec2.Delay, 'Value') == 2
                            h=text(80, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['SP-Gyro: ' int2str(SPGyroDelay(tmpFileIdx, a)) 'ms']);
                            set(h,'Color',[lineCol],'fontsize',fontsz);
                        end
                        if get(guiHandlesSpec2.Delay, 'Value') == 3  && a == 1
                            if debugmode(tmpFileIdx) == tmpDbgIdx.RC_INTERPOLATION || debugmode(tmpFileIdx) == tmpDbgIdx.FEEDFORWARD
                                h=text(75, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['SP smoothing delay: ' Debug02{tmpFileIdx} 'ms']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            else
                                h=text(80, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['debug mode not set ']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            end
                        end
                         if get(guiHandlesSpec2.Delay, 'Value') == 4 && a == 1
                            if debugmode(tmpFileIdx) == tmpDbgIdx.GYRO_SCALED || debugmode(tmpFileIdx) == tmpDbgIdx.GYRO_FILTERED || debugmode(tmpFileIdx) == 1 || debugmode(tmpFileIdx) == 0
                                h=text(65, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['Gyro Phase: ' num2str(gyro_phase_shift_deg(tmpFileIdx)) 'deg | Dterm Phase: ' num2str(dterm_phase_shift_deg(tmpFileIdx)) 'deg']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            else
                                h=text(65, climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)-(f*4), ['Gyro Phase: ' 'deg | Dterm Phase: ' num2str(dterm_phase_shift_deg(tmpFileIdx)) 'deg']);
                                set(h,'Color',[lineCol],'fontsize',fontsz);
                            end
                        end

                    
                    else
                        % combine R P Y
                        h2 = findobj(PSspecfig2, 'Type', 'axes', 'Tag', 'PSspec2_combo');
                        if isempty(h2), h2 = axes('Parent', PSspecfig2, 'Position', [0.0500 0.1000 cpL-0.1 0.840], 'Tag', 'PSspec2_combo');
                        else set(PSspecfig2, 'CurrentAxes', h2); end
                        ff = ['f' int2str(f)];
                        h=plot(freq2d2{p}.(ff), smooth(amp2d2{p}.(ff), log10(size(amp2d2{p}.(ff),1)) * (tmpSmoothVal^3), 'lowess')); hold on
                        hold on
                        if k == 1
                            set(h, 'linewidth', get(guiHandles.linewidth, 'Value')/1.4,'linestyle',rpyLineStyle{cnt})
                        end
                        if k == 2
                            set(h, 'linewidth', get(guiHandles.linewidth, 'Value')/2.6,'linestyle',rpyLineStyle{cnt})
                        end
                        set(h2,'fontsize',fontsz)
                        set(h,'Color',[lineCol]) 
                        m = (A_lograte(tmpFileVal(f)) * 1000) / 2;
                        set(h2,'xtick',[0:m/10:m], 'yminortick','on')
                        axis([0 m climScale1(get(guiHandlesSpec2.checkboxPSD, 'Value')+1) climScale2(get(guiHandlesSpec2.checkboxPSD, 'Value')+1)])             
                        xlabel('Frequency (Hz)','fontweight','bold','Color',th.textPrimary);
                        if get(guiHandlesSpec2.checkboxPSD, 'Value')
                            ylabel(['Power Spectral Density (dB)'],'fontweight','bold','Color',th.textPrimary);
                        else
                            ylabel(['Amplitude'],'fontweight','bold','Color',th.textPrimary);
                        end
                        if a == 1
                            title('Full Spectrum','fontweight','bold','Color',th.textPrimary);
                        end
                        grid on


                    end
                    
                    grid on

                else
                end
            end
        end
    end
end

l=0;legnd={};
l2=0;
tmpSpecListStr = get(guiHandlesSpec2.SpecList, 'String');
tmpSpecListVal = get(guiHandlesSpec2.SpecList, 'Value');
tmpFileSelStr = get(guiHandlesSpec2.FileSelect, 'String');
tmpFileSelVal = get(guiHandlesSpec2.FileSelect, 'Value');
for m = 1 : length(tmpSpecListVal)
    sLeg = char(datSelectionString(tmpSpecListVal(m)));
    for n = 1 : length(tmpFileSelVal)
        fIdx_ = tmpFileSelVal(n);
        if ~isfield(T{fIdx_}, [sLeg '_0_']), continue; end
        l = l + 1;
        clear fstr fltDelayStr
        fstr = char(tmpFileSelStr(tmpFileSelVal(n)));
        if size(fstr,2) > 12, fstr = fstr(1,1:12); end
        if get(guiHandlesSpec2.RPYcomboSpec, 'Value') == 0
            legnd{l} = [char(tmpSpecListStr(tmpSpecListVal(m))) ' | ' fstr];
        else
            for a = axesOptionsSpec
                l2 = l2 + 1;
                legnd{l2} = [axLabel{a} ' | ' char(tmpSpecListStr(tmpSpecListVal(m))) ' | ' fstr ];
            end
        end
    end
end
try
    if ~isempty(freq2d2) && ~isempty(amp2d2)
        if get(guiHandlesSpec2.RPYcomboSpec, 'Value') == 0
            h=legend(legnd);
            hPos = get(h, 'Position'); set(h, 'Position', [0.35 0.01 hPos(3:4)]);
        else
            h=legend(legnd, 'Location','NorthEast');
        end
        try PSstyleLegend(h, th); catch, end
    end
catch, end
% warn if "Gyro prefilt" selected but no data available
if any(tmpSpecVal == 2)
    hasPF_ = false;
    for fi_ = 1:size(tmpFileVal,2)
        if isfield(T{tmpFileVal(fi_)}, 'gyroPrefilt_0_'), hasPF_ = true; break; end
    end
    if ~hasPF_
        delete(findobj(PSspecfig2, 'Tag', 'prefiltWarn'));
        axW_ = findobj(PSspecfig2, 'Type', 'axes', 'Tag', 'PSspec2_1');
        if ~isempty(axW_)
            text(axW_, 0.5, 0.5, {'No pre-filter gyro data.', 'Requires gyroUnfilt (BF 4.5+) or debug\_mode = GYRO\_SCALED.'}, ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', fontsz+1, ...
                'Color', [.8 .3 .3], 'Tag', 'prefiltWarn');
        end
    else
        delete(findobj(PSspecfig2, 'Tag', 'prefiltWarn'));
    end
end
prevLeftKey_ = leftKey_;
else
    % right-column only: clear just axes 4-6
    for di_=4:6, h_cla=findobj(PSspecfig2,'Type','axes','Tag',sprintf('PSspec2_%d',di_)); if ~isempty(h_cla), cla(h_cla); hold(h_cla,'off'); end; end
end % skipLeftRender_


% Motor Noise panels (right column, when rightColMode == 2)
rightMode_final = 1;
try rightMode_final = get(guiHandlesSpec2.rightColMode, 'Value'); catch, end
if rightMode_final == 2
    axLabel_mn = {'Roll','Pitch','Yaw'};
    axesOpt_mn = find([get(guiHandlesSpec2.plotR, 'Value') get(guiHandlesSpec2.plotP, 'Value') get(guiHandlesSpec2.plotY, 'Value')]);
    tmpFileVal_mn = get(guiHandlesSpec2.FileSelect, 'Value');

    % read RPM controls
    rpmMotors_mn = [1 2 3 4];
    try
        rpmMotors_mn = [];
        nMot_mn = 4; try nMot_mn = guiHandlesSpec2.nMotors; catch, end
        for mi_ = 1:4
            if get(guiHandlesSpec2.(sprintf('rpmMotor%d', mi_)), 'Value')
                rpmMotors_mn(end+1) = mi_;
                if nMot_mn > 4, rpmMotors_mn(end+1) = mi_ + nMot_mn/2; end
            end
        end
    catch, rpmMotors_mn = [1 2 3 4]; end

    nHarm_sel = [1 2 3];
    try
        harmSel_ = get(guiHandlesSpec2.rpmHarmDd, 'Value');
        harmMap_ = {[1 2 3], [1], [2], [3], [1 2], [1 3], [2 3]};
        nHarm_sel = harmMap_{harmSel_};
    catch, end

    rpmLw_mn = 1.5;
    try
        lwSel_ = get(guiHandlesSpec2.rpmLwDd, 'Value');
        lwMap_ = [0.5 1 1.5 2];
        rpmLw_mn = lwMap_(lwSel_);
    catch, end

    % two-level cache: L1=FFT matrices (file/epoch), L2=interp results (motor sel)
    fftKey_ = struct('fileVal', tmpFileVal_mn);
    fftKey_.nSamp = zeros(1, numel(tmpFileVal_mn));
    for fi_ = 1:numel(tmpFileVal_mn), fftKey_.nSamp(fi_) = sum(tIND{tmpFileVal_mn(fi_)}); end
    fftCache_ = [];
    try fftCache_ = getappdata(PSspecfig2, 'mnFftCache'); catch, end
    fftHit_ = ~isempty(fftCache_) && isstruct(fftCache_) && isfield(fftCache_, 'key') && ...
        isequal(fftCache_.key.fileVal, fftKey_.fileVal) && isequal(fftCache_.key.nSamp, fftKey_.nSamp);

    if ~fftHit_
        % L1: compute RPM Hz (all motors) + PSD matrices per file per axis
        fftData_ = cell(numel(tmpFileVal_mn), 1);
        nHarm_mn = 3;
        for fi_mn = 1:numel(tmpFileVal_mn)
            fIdx_mn = tmpFileVal_mn(fi_mn);
            fd_ = struct('valid', false);
            try
                if ~isfield(T{fIdx_mn}, 'eRPM_0_'), fftData_{fi_mn} = fd_; continue; end
                nSamp_ = sum(tIND{fIdx_mn});
                mPoles_ = 14;
                try mp_ = find(strcmp(SetupInfo{fIdx_mn}(:,1), 'motor_poles'));
                    if ~isempty(mp_), mPoles_ = str2double(SetupInfo{fIdx_mn}(mp_(1),2)); end
                catch, end
                if mPoles_ < 2, mPoles_ = 14; end
                nEm_ = 0;
                for mi_ = 0:7
                    if isfield(T{fIdx_mn}, ['eRPM_' int2str(mi_) '_']), nEm_ = mi_+1; end
                end
                rpmHz_ = zeros(nSamp_, nEm_);
                for mi_ = 0:nEm_-1
                    ef_ = ['eRPM_' int2str(mi_) '_'];
                    if isfield(T{fIdx_mn}, ef_)
                        rpmHz_(:, mi_+1) = T{fIdx_mn}.(ef_)(tIND{fIdx_mn}) * 100 / (mPoles_/2) / 60;
                    end
                end
                winLen_ = min(512, floor(nSamp_/4));
                nWin_ = floor(nSamp_ / winLen_);
                if nWin_ < 2, nWin_ = 1; winLen_ = nSamp_; end
                fd_.rpmHz = rpmHz_(1:nWin_*winLen_, :);
                fd_.nEm = nEm_; fd_.nSamp = nSamp_; fd_.lr = A_lograte(fIdx_mn);
                fd_.winLen = winLen_; fd_.nWin = nWin_;
                hannW_ = hann(winLen_);
                Fs_ = fd_.lr * 1000;
                halfN_ = floor(winLen_/2) + 1;
                fd_.halfN = halfN_;
                fd_.df = Fs_ * (1) / winLen_;
                fd_.Fs = Fs_;
                fd_.psd = cell(1, 3);
                fd_.prePsd = cell(1, 3);
                fd_.hasPre = false(1, 3);
                for ai_ = 1:3
                    gyroFld_ = ['gyroADC_' int2str(ai_-1) '_'];
                    if ~isfield(T{fIdx_mn}, gyroFld_), continue; end
                    gSig_ = T{fIdx_mn}.(gyroFld_)(tIND{fIdx_mn});
                    gSig_ = gSig_(:);
                    sigMat_ = reshape(gSig_(1:nWin_*winLen_), winLen_, nWin_) .* hannW_;
                    fftMat_ = fft(sigMat_);
                    psdMat_ = abs(fftMat_(1:halfN_, :)).^2 / (Fs_ * winLen_);
                    psdMat_(2:end-1, :) = 2 * psdMat_(2:end-1, :);
                    fd_.psd{ai_} = 10*log10(psdMat_);
                    % pre-filter (gyroPrefilt synthesized in PSload)
                    preFld_ = ['gyroPrefilt_' int2str(ai_-1) '_'];
                    hp_ = isfield(T{fIdx_mn}, preFld_);
                    fd_.hasPre(ai_) = hp_;
                    if hp_
                        preSig_ = T{fIdx_mn}.(preFld_)(tIND{fIdx_mn});
                        preSig_ = preSig_(:);
                        preMat_ = reshape(preSig_(1:nWin_*winLen_), winLen_, nWin_) .* hannW_;
                        prePsd_ = abs(fft(preMat_)(1:halfN_, :)).^2 / (Fs_ * winLen_);
                        prePsd_(2:end-1, :) = 2 * prePsd_(2:end-1, :);
                        fd_.prePsd{ai_} = 10*log10(prePsd_);
                    end
                end
                fd_.valid = true;
            catch
            end
            fftData_{fi_mn} = fd_;
        end
        fftS_ = struct(); fftS_.key = fftKey_; fftS_.data = fftData_;
        setappdata(PSspecfig2, 'mnFftCache', fftS_);
    else
        fftData_ = fftCache_.data;
    end

    % L2: interp from cached PSD using current motor selection (cheap)
    nHarm_mn = 3;
    mnData_ = cell(numel(tmpFileVal_mn), 3);
    for fi_mn = 1:numel(tmpFileVal_mn)
        fd_ = fftData_{fi_mn};
        if ~isstruct(fd_) || ~fd_.valid, continue; end
        selCols_ = rpmMotors_mn(rpmMotors_mn <= fd_.nEm);
        if isempty(selCols_), selCols_ = 1:min(4, fd_.nEm); end
        rpmSel_ = fd_.rpmHz(:, selCols_);
        winRpmMean_ = mean(reshape(mean(rpmSel_, 2), fd_.winLen, fd_.nWin), 1)';
        wIdx_ = (1:fd_.nWin)';
        for ai_ = 1:3
            d_ = struct('valid', false, 'hasPre', fd_.hasPre(ai_), 'avgN', [], 'stdN', [], 'avgPre', [], 'stdPre', []);
            if isempty(fd_.psd{ai_}), mnData_{fi_mn, ai_} = d_; continue; end
            psd_ = fd_.psd{ai_};
            noisePost_ = NaN(fd_.nWin, nHarm_mn);
            for hi_ = 1:nHarm_mn
                ft_ = winRpmMean_ * hi_;
                bin_ = ft_ / fd_.df;
                lo_ = floor(bin_) + 1;
                frac_ = bin_ - floor(bin_);
                ok_ = ft_ > 0 & lo_ >= 1 & lo_ < fd_.halfN;
                vi_ = wIdx_(ok_);
                if ~isempty(vi_)
                    iL_ = sub2ind(size(psd_), lo_(ok_), vi_);
                    iH_ = sub2ind(size(psd_), lo_(ok_)+1, vi_);
                    noisePost_(vi_, hi_) = psd_(iL_) .* (1-frac_(ok_)) + psd_(iH_) .* frac_(ok_);
                end
            end
            d_.avgN = nanmean(noisePost_, 1);
            d_.stdN = nanstd(noisePost_, 0, 1);
            if fd_.hasPre(ai_)
                pp_ = fd_.prePsd{ai_};
                noisePre_ = NaN(fd_.nWin, nHarm_mn);
                for hi_ = 1:nHarm_mn
                    ft_ = winRpmMean_ * hi_;
                    bin_ = ft_ / fd_.df;
                    lo_ = floor(bin_) + 1;
                    frac_ = bin_ - floor(bin_);
                    ok_ = ft_ > 0 & lo_ >= 1 & lo_ < fd_.halfN;
                    vi_ = wIdx_(ok_);
                    if ~isempty(vi_)
                        iL_ = sub2ind(size(pp_), lo_(ok_), vi_);
                        iH_ = sub2ind(size(pp_), lo_(ok_)+1, vi_);
                        noisePre_(vi_, hi_) = pp_(iL_) .* (1-frac_(ok_)) + pp_(iH_) .* frac_(ok_);
                    end
                end
                d_.avgPre = nanmean(noisePre_, 1);
                d_.stdPre = nanstd(noisePre_, 0, 1);
            end
            d_.valid = true;
            mnData_{fi_mn, ai_} = d_;
        end
    end

    % plot from cached data
    for ai = axesOpt_mn
        stag_mn = sprintf('PSspec2_%d', ai+3);
        h_mn = findobj(PSspecfig2, 'Type', 'axes', 'Tag', stag_mn);
        if isempty(h_mn), h_mn = axes('Parent', PSspecfig2, 'Position', posInfo.Spec2Pos(ai+3,:), 'Tag', stag_mn);
        else cla(h_mn); set(h_mn, 'Position', posInfo.Spec2Pos(ai+3,:)); set(PSspecfig2, 'CurrentAxes', h_mn); title(h_mn, ''); xlabel(h_mn, ''); ylabel(h_mn, ''); end
        for fi_mn = 1:numel(tmpFileVal_mn)
            fCol_mn = multiLineCols(fi_mn, :);
            d_ = mnData_{fi_mn, ai};
            if isempty(d_) || ~isstruct(d_) || ~d_.valid
                if fi_mn == 1
                    text(0.5, 0.5, 'No RPM data', 'Parent', h_mn, 'Units', 'normalized', ...
                        'HorizontalAlignment', 'center', 'Color', th.textSecondary, 'FontSize', fontsz);
                end
                continue;
            end
            if d_.hasPre
                h_eb = errorbar(h_mn, nHarm_sel, d_.avgPre(nHarm_sel), d_.stdPre(nHarm_sel), 'o:');
                set(h_eb, 'Color', fCol_mn, 'LineWidth', rpmLw_mn, 'MarkerSize', 8);
                hold(h_mn, 'on');
            end
            h_eb = errorbar(h_mn, nHarm_sel, d_.avgN(nHarm_sel), d_.stdN(nHarm_sel), 'o-');
            set(h_eb, 'Color', fCol_mn, 'LineWidth', rpmLw_mn+0.5, 'MarkerFaceColor', fCol_mn, 'MarkerSize', 8);
            hold(h_mn, 'on');
        end
        harmLabels_ = {'1st','2nd','3rd'};
        set(h_mn, 'XTick', nHarm_sel, 'XTickLabel', harmLabels_(nHarm_sel));
        % auto-scale Y to data + error bars
        yVals_ = [];
        yErr_ = [];
        for fi2_ = 1:numel(tmpFileVal_mn)
            d2_ = mnData_{fi2_, ai};
            if isempty(d2_) || ~isstruct(d2_) || ~d2_.valid, continue; end
            yVals_ = [yVals_; d2_.avgN(nHarm_sel)(:)];
            yErr_ = [yErr_; d2_.stdN(nHarm_sel)(:)];
            if d2_.hasPre
                yVals_ = [yVals_; d2_.avgPre(nHarm_sel)(:)];
                yErr_ = [yErr_; d2_.stdPre(nHarm_sel)(:)];
            end
        end
        ok_ = isfinite(yVals_) & isfinite(yErr_);
        if any(ok_)
            yLo_ = min(yVals_(ok_) - yErr_(ok_));
            yHi_ = max(yVals_(ok_) + yErr_(ok_));
            yPad_ = max(3, (yHi_ - yLo_) * 0.15);
            axis(h_mn, [min(nHarm_sel)-0.5 max(nHarm_sel)+0.5 yLo_-yPad_ yHi_+yPad_]);
        else
            axis(h_mn, [min(nHarm_sel)-0.5 max(nHarm_sel)+0.5 -60 20]);
        end
        xlabel(h_mn, 'Motor Harmonic', 'fontweight', 'bold', 'Color', th.textPrimary);
        ylabel(h_mn, [axLabel_mn{ai} ' | Avg Motor Noise (dB)'], 'fontweight', 'bold', 'Color', th.textPrimary);
        if ai == axesOpt_mn(1)
            fIdx1_mn = tmpFileVal_mn(1);
            try
                fwStr = ''; qStr = '';
                fwRow = find(strcmp(SetupInfo{fIdx1_mn}(:,1), 'rpm_filter_weights'));
                if ~isempty(fwRow), fwStr = SetupInfo{fIdx1_mn}{fwRow(1),2}; end
                qRow = find(strcmp(SetupInfo{fIdx1_mn}(:,1), 'rpm_filter_q'));
                if ~isempty(qRow), qStr = ['Q' SetupInfo{fIdx1_mn}{qRow(1),2}]; end
                if ~isempty(fwStr) || ~isempty(qStr)
                    fCol1_mn = multiLineCols(1,:);
                    text(0.98, 0.95, ['Filter Weights | ' qStr], 'Parent', h_mn, 'Units', 'normalized', ...
                        'HorizontalAlignment', 'right', 'Color', fCol1_mn, 'FontSize', fontsz-1, 'FontWeight', 'bold');
                    text(0.98, 0.85, fwStr, 'Parent', h_mn, 'Units', 'normalized', ...
                        'HorizontalAlignment', 'right', 'Color', fCol1_mn, 'FontSize', fontsz-1);
                end
            catch, end
        end
        grid(h_mn, 'on');
        PSstyleAxes(h_mn, th);
    end
end

allax = findobj(PSspecfig2, 'Type', 'axes');
for axi = 1:numel(allax), PSstyleAxes(allax(axi), th); end
PSdatatipSetup(PSspecfig2);
try PSresizeCP(PSspecfig2, []); catch, end

set(PSspecfig2, 'pointer', 'arrow')
updateSpec=0;
end


