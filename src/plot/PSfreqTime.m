%% PStimeFreq - time freq spectrogram

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    

th = PStheme();
%% update fonts
set(PSspecfig3, 'pointer', 'watch')

figure(PSspecfig3)

specSmoothFactors = [1 5 10 20];
timeSmoothFactors = [1 2 5 10];

if get(guiHandlesSpec3.sub100HzfreqTime, 'Value')
    fLim_freqTime = 100;
else
    fLim_freqTime = 1000;
end

s1={'gyroADC';'debug';'axisD';'axisDpf';'axisP';'piderr';'setpoint';'pidsum'};
datSelectionString=[s1];
axisLabel ={'Roll'; 'Pitch' ; 'Yaw'};
tmpFileVal3 = get(guiHandlesSpec3.FileSelect, 'Value');
tmpSpecVal3 = get(guiHandlesSpec3.SpecList, 'Value');
tmpSmoothVal3 = get(guiHandlesSpec3.smoothFactor_select, 'Value');
tmpSubVal3 = get(guiHandlesSpec3.subsampleFactor_select, 'Value');

%% Read RPM overlay controls once (before axis loop)
rpmShowDN = true; rpmMotors = [1 2 3 4]; rpmHarms = [1 2 3]; rpmLw = 1; rpmShowEst = false;
if exist('guiHandlesSpec3','var')
    try rpmShowDN = get(guiHandlesSpec3.rpmDynNotch, 'Value'); catch, end
    try rpmShowEst = get(guiHandlesSpec3.rpmEstChk, 'Value'); catch, end
    try
        rpmMotors = [];
        if get(guiHandlesSpec3.rpmMotor1, 'Value'), rpmMotors(end+1) = 1; end
        if get(guiHandlesSpec3.rpmMotor2, 'Value'), rpmMotors(end+1) = 2; end
        if get(guiHandlesSpec3.rpmMotor3, 'Value'), rpmMotors(end+1) = 3; end
        if get(guiHandlesSpec3.rpmMotor4, 'Value'), rpmMotors(end+1) = 4; end
    catch, rpmMotors = [1 2 3 4]; end
    try
        harmSel = get(guiHandlesSpec3.rpmHarmDd, 'Value');
        harmMap = {[], [1], [2], [3], [1 2], [1 3], [2 3], [1 2 3]};
        rpmHarms = harmMap{harmSel};
    catch, rpmHarms = [1 2 3]; end
    try
        lwSel = get(guiHandlesSpec3.rpmLwDd, 'Value');
        lwMap = [0.5 1 1.5 2];
        rpmLw = lwMap(lwSel);
    catch, rpmLw = 1; end
end

%% Compute RPM/notch data on-demand (mirrors PSplotSpec2D logic)
if exist('debugmode','var') && exist('debugIdx','var') && exist('T','var') && exist('tIND','var')
    if ~exist('notchData','var'), notchData = {}; end
    if ~exist('rpmFilterData','var'), rpmFilterData = {}; end
    k_ = tmpFileVal3;
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

try delete(findobj(PSspecfig3, 'Tag', 'PScbar')); catch, end
for i = 1 : 3
    delete(subplot('position',posInfo.Spec3Pos(i,:)));
    try
    if ~updateSpec
        fld = [char(datSelectionString(tmpSpecVal3)) '_' int2str(i-1) '_'];
        dat = T{tmpFileVal3}.(fld)(tIND{tmpFileVal3})';
        [Tm F specMat{i}] = PStimeFreqCalc(dat', A_lograte(tmpFileVal3), specSmoothFactors(tmpSmoothVal3), timeSmoothFactors(tmpSubVal3));
    end

    h2=subplot('position',posInfo.Spec3Pos(i,:));
    set(h2, 'Tag', 'PSgrid');
    h = imagesc(specMat{i});

    set(gca,'Clim',[ClimScale3], 'fontsize',fontsz,'fontweight','bold')
    title('');
    set(get(gca,'Ylabel'), 'String', ['Frequency (Hz) ' axisLabel{i}], 'Color', th.textPrimary);
    if i == 3
        set(get(gca,'Xlabel'), 'String', 'Time (sec)', 'Color', th.textPrimary);
    end
    F2 = F(F<=fLim_freqTime);
    freqStr = flipud(int2str((0: F2(end) / 5: F2(end))'));
    timeStr = int2str((0: round(Tm(end)) / 10: round(Tm(end)))');

    st = find(fliplr(F<=fLim_freqTime),1, 'first');
    nd = find(fliplr(F<=fLim_freqTime),1, 'last');
    set(gca,'YLim', [st nd])
    set(gca,'Ytick', [st : (nd-st) / 5: nd], 'YTickLabel',[freqStr], 'YMinorTick', 'on', 'Xtick', [0 : round( (size(specMat{i},2)-1) / 10) : size(specMat{i},2)],'XTickLabel',[timeStr], 'XMinorTick', 'on', 'TickDir', 'out');

    try
        tmpCmapVal = get(guiHandlesSpec3.ColormapSelect, 'Value');
        if tmpCmapVal <= 7
            tmpCmapStr = get(guiHandlesSpec3.ColormapSelect, 'String');
            cm = feval(char(tmpCmapStr(tmpCmapVal)), 64);
        elseif tmpCmapVal == 8
            cm = linearREDcmap;
        else
            cm = linearGREYcmap;
        end
        set(PSspecfig3, 'Colormap', cm);
    catch, end
    cbar = colorbar('EastOutside');
    set(cbar, 'Tag', 'PScbar', 'UserData', 'east');
    set(get(cbar, 'Label'), 'String', 'Power Spectral density (dB)', 'Color', th.textPrimary);
    try set(cbar, 'Color', th.axesFg); catch, end

    if i == 3 && (strcmp(char(datSelectionString(get(guiHandlesSpec3.SpecList, 'Value'))), 'axisD') || strcmp(char(datSelectionString(get(guiHandlesSpec3.SpecList, 'Value'))), 'axisDpf'))
        delete(subplot('position',posInfo.Spec3Pos(i,:)));
    end
    box off

    %% Dynamic notch overlay for FFT_FREQ mode
    if rpmShowDN && exist('notchData','var') && exist('debugmode','var') && exist('debugIdx','var')
        tmpFFTft = FFT_FREQ;
        if numel(debugIdx) >= tmpFileVal3
            tmpFFTft = debugIdx{tmpFileVal3}.FFT_FREQ;
        end
        if debugmode(tmpFileVal3) == tmpFFTft && numel(notchData) >= tmpFileVal3 && ~isempty(notchData{tmpFileVal3})
            PSplotDynNotchOverlay(gca, notchData{tmpFileVal3}, size(specMat{i}, 2), size(specMat{i}, 1), F(end), 'time', rpmLw);
        end
    end

    %% RPM filter overlay (motor frequencies + harmonics)
    if ~isempty(rpmHarms) && ~isempty(rpmMotors) && exist('rpmFilterData','var') && exist('debugmode','var') && exist('debugIdx','var')
        tmpRPMft = 46;
        if numel(debugIdx) >= tmpFileVal3
            tmpRPMft = debugIdx{tmpFileVal3}.RPM_FILTER;
        end
        if debugmode(tmpFileVal3) == tmpRPMft && numel(rpmFilterData) >= tmpFileVal3 && ~isempty(rpmFilterData{tmpFileVal3})
            PSplotRPMOverlay(gca, rpmFilterData{tmpFileVal3}, size(specMat{i}, 2), size(specMat{i}, 1), F(end), 'time', 3, rpmMotors, rpmHarms, rpmLw);
        end
    end

    %% RPM estimator overlay (works on any log — estimates from spectrum peaks)
    if rpmShowEst && ~isempty(rpmHarms) && ~isempty(specMat{i})
        ampForEst = flipud(specMat{i})';
        [~, estHarm] = PSestimateRPM(F, ampForEst, 3);
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
        hz_per_px = F(end) / size(specMat{i}, 1);
        hold on;
        estCol = [0 .9 .2; .9 .7 0; .9 .2 0];
        estStyle = {'-'; '--'; ':'};
        numWin = size(specMat{i}, 2);
        for nh = rpmHarms
            if nh > size(estHarm, 2), continue; end
            xPts = []; yPts = [];
            for w = 1:numWin
                if ~isnan(estHarm(w, nh)) && estHarm(w, nh) > 0 && estHarm(w, nh) < F(end)
                    y_px = size(specMat{i}, 1) - round(estHarm(w, nh) / hz_per_px);
                    if y_px >= 1 && y_px <= size(specMat{i}, 1)
                        xPts(end+1) = w;
                        yPts(end+1) = y_px;
                    end
                end
            end
            if ~isempty(xPts)
                plot(gca, xPts, yPts, estStyle{nh}, 'LineWidth', rpmLw, 'Color', estCol(nh,:), 'HitTest', 'off');
            end
        end
    end

    catch
        delete(subplot('position',posInfo.Spec3Pos(i,:)));
    end
end
updateSpec = 0;

allax = findobj(PSspecfig3, 'Type', 'axes');
for axi = 1:numel(allax), PSstyleAxes(allax(axi), th); end
PSdatatipSetup(PSspecfig3);
try PSresizeCP(PSspecfig3, []); catch, end

set(PSspecfig3, 'pointer', 'arrow')

