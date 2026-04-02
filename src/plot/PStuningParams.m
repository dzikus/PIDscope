%% PStuningParams - scripts for plotting tune-related parameters

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

PStunefig=figure(4);
th = PStheme();



%% step resp computed directly from set point and gyro
ylab={'Roll';'Pitch';'Yaw'};
ylab2={'roll';'pitch';'yaw'};

% re-enable axes auto-hidden by previous run (only on fresh start)
if ~updateStep && fcntSR == 0
    rpyH_ = {guiHandlesTune.plotR, guiHandlesTune.plotP, guiHandlesTune.plotY};
    for pi_ = 1:3
        if strcmp(get(rpyH_{pi_}, 'Enable'), 'off')
            set(rpyH_{pi_}, 'Value', 1, 'Enable', 'on');
        end
    end
end

axesOptions = find([get(guiHandlesTune.plotR, 'Value') get(guiHandlesTune.plotP, 'Value') get(guiHandlesTune.plotY, 'Value')]);

% scale row heights to fill space when fewer than 3 RPY axes
nActiveTune = numel(axesOptions);
stdRows_t = [0.69 0.395 0.1]; stdRowH_t = 0.245;
if nActiveTune > 0 && nActiveTune < 3 && ~get(guiHandlesTune.RPYcombo, 'Value')
    topY_t = stdRows_t(1) + stdRowH_t; botY_t = stdRows_t(3); gapT = 0.05;
    rowH_t = (topY_t - botY_t - (nActiveTune-1)*gapT) / nActiveTune;
    ci = 0;
    for jj = axesOptions
        ci = ci + 1;
        yy = topY_t - ci*rowH_t - (ci-1)*gapT;
        for cc = 0:3
            posInfo.TparamsPos(jj + cc*3, 2) = yy;
            posInfo.TparamsPos(jj + cc*3, 4) = rowH_t;
        end
    end
else
    for jj = 1:3
        for cc = 0:3
            posInfo.TparamsPos(jj + cc*3, 2) = stdRows_t(jj);
            posInfo.TparamsPos(jj + cc*3, 4) = stdRowH_t;
        end
    end
end

lineStyle = {'-' ; '--' ; ':'};
lnLabels = {'solid' ; 'dashed'; 'dotted'};
p = {'    P, I, D, Dm, F'; '    P, I, D, Dm, F'; '    P, I, D, cD'; ...
     '    P, I, D'; '    P, I, D'; '    P, I, D, F'; '    P, I, D'; '    P, I, D'};
fwIdx = min(get(guiHandles.Firmware, 'Value'), numel(p));
pidlabels = p{fwIdx};

%%%%%%%%%%%%% step resp %%%%%%%%%%%%%
figure(PStunefig);

ymax = str2double(get(guiHandlesTune.maxYStepInput, 'String'));
ypos = [(ymax/3)*2.9 (ymax/3)*1.85 (ymax/3)*.8];
hwarn=[];
showBFsliders = isfield(guiHandlesTune, 'bfSliders') && get(guiHandlesTune.bfSliders, 'Value') == 2;

if ~get(guiHandlesTune.clearPlots, 'Value') && showBFsliders
    % BF Sliders view: read simplified_* headers and draw horizontal bars
    set(PStunefig, 'pointer', 'watch'); drawnow;
    sliderKeys_ = {'simplified_d_gain','simplified_pi_gain','simplified_feedforward_gain',...
        'simplified_d_max_gain','simplified_i_gain','simplified_pitch_d_gain',...
        'simplified_pitch_pi_gain','simplified_master_multiplier'};
    sliderLabels_ = {'Damping','Tracking','Stick Resp.','Dynamic D.',...
        'Drift-Wobble','Pitch D.','Pitch T.','Master'};
    nSliders_ = numel(sliderKeys_);
    selFiles_ = get(guiHandlesTune.fileListWindowStep, 'Value');

    h_sl = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_bfsliders');
    if isempty(h_sl)
        h_sl = axes('Parent', PStunefig, 'Position', [0.07 0.10 plotR-0.09 0.84], 'Tag', 'PSstep_bfsliders');
    else
        set(PStunefig, 'CurrentAxes', h_sl); cla;
    end
    hold on;

    % horizontal bar lines
    for si_ = 1:nSliders_
        plot([0 2], [si_ si_], '-', 'Color', th.textSecondary, 'LineWidth', 1.5);
    end

    hasData_ = false;
    for fi_ = 1:numel(selFiles_)
        f_ = selFiles_(fi_);
        if f_ > numel(SetupInfo), continue; end
        colIdx_ = min(fi_, size(multiLineCols,1));
        vals_ = ones(1, nSliders_);
        anyFound_ = false;
        for si_ = 1:nSliders_
            idx_ = find(strcmp(SetupInfo{f_}(:,1), sliderKeys_{si_}));
            if ~isempty(idx_)
                v_ = str2double(SetupInfo{f_}{idx_(1), 2});
                if ~isnan(v_), vals_(si_) = v_ / 100; anyFound_ = true; end
            end
        end
        if anyFound_
            hasData_ = true;
            for si_ = 1:nSliders_
                plot(vals_(si_), si_, 'o', 'MarkerSize', 10, 'MarkerFaceColor', multiLineCols(colIdx_,:), ...
                    'MarkerEdgeColor', 'none');
            end
        end
    end

    if ~hasData_
        text(1, nSliders_/2+0.5, 'No BF slider data in headers', 'fontsize', fontsz+2, ...
            'HorizontalAlignment', 'center', 'Color', th.textSecondary);
    end

    set(h_sl, 'YTick', 1:nSliders_, 'YTickLabel', sliderLabels_, 'YDir', 'reverse', ...
        'XLim', [0 2], 'YLim', [0.5 nSliders_+0.5], ...
        'XTick', 0:0.2:2, 'fontsize', fontsz, 'TickDir', 'out');
    xlabel('Slider Position', 'fontweight', 'bold');
    title('Betaflight PID Sliders', 'fontweight', 'bold');
    grid on; box off;
    PSstyleAxes(h_sl, th);

    % legend: file names with colors
    for fi_ = 1:numel(selFiles_)
        colIdx_ = min(fi_, size(multiLineCols,1));
        text(1.85, 0.7 + fi_*0.06, fnameMaster{selFiles_(fi_)}, 'fontsize', max(fontsz-1,6), ...
            'Color', multiLineCols(colIdx_,:), 'Units', 'normalized', ...
            'HorizontalAlignment', 'right', 'fontweight', 'bold');
    end

    % disable irrelevant controls in BF sliders mode
    bfOff_ = {'plotR','plotP','plotY','snapManeuver','RPYcombo','rawTraces',...
        'Ycorrection','maxYStepInput','smoothFactor_select','srLatency',...
        'subsample','minRateInput','maxRateInput','minRateTxt','maxYStepTxt',...
        'period','markup'};
    for bi_ = 1:numel(bfOff_)
        if isfield(guiHandlesTune, bfOff_{bi_}), set(guiHandlesTune.(bfOff_{bi_}), 'Enable', 'off'); end
    end

    try PSresizeCP(PStunefig, []); catch, end
    set(PStunefig, 'pointer', 'arrow');
    updateStep = 0;

elseif ~get(guiHandlesTune.clearPlots, 'Value')
    % delete BF sliders axes if switching back to normal view
    h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_bfsliders');
    if ~isempty(h_del), delete(h_del); end

    % re-enable controls when leaving BF sliders mode
    bfOff_ = {'plotR','plotP','plotY','snapManeuver','RPYcombo','rawTraces',...
        'Ycorrection','maxYStepInput','smoothFactor_select','srLatency',...
        'subsample','minRateInput','maxRateInput','minRateTxt','maxYStepTxt',...
        'period','markup'};
    for bi_ = 1:numel(bfOff_)
        if isfield(guiHandlesTune, bfOff_{bi_}), set(guiHandlesTune.(bfOff_{bi_}), 'Enable', 'on'); end
    end

    if ~updateStep && fcntSR == 0
        peakresp = []; peakresp_std = []; peaktime = [];
        latencyHalfHeight = []; latencyHalfHeight_std = [];
        settlingMin = []; settlingMax = [];
    end
    cnt = 0;
    set(PStunefig, 'pointer', 'watch')
    drawnow;

    for f = get(guiHandlesTune.fileListWindowStep, 'Value')
        fcntSR = fcntSR + 1;
        if fcntSR <= 10
            cnt2 = 0;
            for p = axesOptions
                cnt = cnt + 1;
                cnt2 = cnt2 + 1;
                try
                    if ~updateStep
                        H = T{f}.(['setpoint_' int2str(p-1) '_'])(tIND{f});
                        G = T{f}.(['gyroADC_' int2str(p-1) '_'])(tIND{f});
                        subMap_ = [0 1 3 5 7 10];
                        subVal_ = subMap_(get(guiHandlesTune.subsample, 'Value'));
                        if subVal_ == 0
                            fileDurSec_ = length(H) / (A_lograte(f)*1000);
                            if fileDurSec_ <= 20, subVal_ = 10;
                            elseif fileDurSec_ <= 60, subVal_ = 7;
                            else subVal_ = 3; end
                        end
                        minR_ = str2double(get(guiHandlesTune.minRateInput, 'String'));
                        maxR_ = str2double(get(guiHandlesTune.maxRateInput, 'String'));
                        if isnan(minR_), minR_ = 40; end
                        if isnan(maxR_), maxR_ = 500; end
                        if get(guiHandlesTune.snapManeuver, 'Value')
                            minR_ = maxR_; maxR_ = Inf;
                        end
                        [stepresp_A{p} tA] = PSstepcalc(H, G, A_lograte(f), get(guiHandlesTune.Ycorrection, 'Value'), get(guiHandlesTune.smoothFactor_select, 'Value'), subVal_, minR_, maxR_);
                        try xcorrLag_cache(p) = finddelay(H, G) / A_lograte(f); catch, xcorrLag_cache(p) = nan; end
                    end
                catch
                    stepresp_A{p}=[];
                end

                if get(guiHandlesTune.RPYcombo, 'Value') == 0
                    stag_ = sprintf('PSstep_%d', p);
                    h1 = findobj(PStunefig, 'Type', 'axes', 'Tag', stag_);
                    if isempty(h1), h1 = axes('Parent', PStunefig, 'Position', posInfo.TparamsPos(p,:), 'Tag', stag_);
                    else set(PStunefig, 'CurrentAxes', h1); end
                    hold on

                     if size(stepresp_A{p},1)>1
                        s = [];
                        s = stepresp_A{p};
                        m=nanmean(s);
                        sd=nanstd(s);

                        col_i = multiLineCols(fcntSR,:);

                        % SD shading band
                        tFlip = [tA fliplr(tA)];
                        sdBand = [m+sd fliplr(m-sd)];
                        patch(tFlip, sdBand, col_i, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'Parent', gca);

                        % raw segment traces - blend toward bg to simulate low alpha
                        if isfield(guiHandlesTune, 'rawTraces') && get(guiHandlesTune.rawTraces, 'Value')
                            col_raw = col_i * 0.12 + th.axesBg * 0.88;
                            nSeg_ = size(s,1);
                            tAll_ = repmat([tA NaN], 1, nSeg_);
                            sAll_ = reshape([s'; NaN(1, nSeg_)], 1, []);
                            plot(tAll_, sAll_, 'Color', col_raw, 'LineWidth', 0.5);
                        end

                        h1=plot(tA,m);
                        set(h1, 'color', col_i, 'linewidth', get(guiHandles.linewidth, 'Value')/1.5);
                        if get(guiHandlesTune.srLatency, 'Value') == 2 && exist('xcorrLag_cache', 'var')
                            latencyHalfHeight(p, fcntSR) = xcorrLag_cache(p);
                        else
                            idx50_ = find(m > .5, 1);
                            if ~isempty(idx50_)
                                latencyHalfHeight(p, fcntSR) = (idx50_ / A_lograte(f)) - 1;
                            else
                                latencyHalfHeight(p, fcntSR) = nan;
                            end
                        end
                        peakIdx = find(tA < 150);
                        peakresp(p, fcntSR) = max(m(peakIdx));
                        [~, pkI_] = max(m(peakIdx));
                        peaktime(p, fcntSR) = pkI_(1) / A_lograte(f);

                        % per-segment metrics for error bars (vectorized)
                        segPeaks = max(s(:, peakIdx), [], 2)';
                        above50 = s > 0.5;
                        [~, firstAbove] = max(above50, [], 2);
                        segLats = (firstAbove' / A_lograte(f)) - 1;
                        segLats(~any(above50, 2)') = nan;
                        peakresp_std(p, fcntSR) = nanstd(segPeaks);
                        latencyHalfHeight_std(p, fcntSR) = nanstd(segLats);

                        % settling metrics (200-500ms window)
                        settleIdx_ = find(tA > 200 & tA < 500);
                        if ~isempty(settleIdx_)
                            settlingMin(p, fcntSR) = min(m(settleIdx_));
                            settlingMax(p, fcntSR) = max(m(settleIdx_));
                        else
                            settlingMin(p, fcntSR) = nan;
                            settlingMax(p, fcntSR) = nan;
                        end

                        pidvar = [ylab2{p} 'PIDF'];
                        PID = eval([pidvar '{f}']);
                    else
                        peakresp(p, fcntSR) = nan;
                        peaktime(p, fcntSR) = nan;
                        latencyHalfHeight(p, fcntSR) = nan;
                        peakresp_std(p, fcntSR) = nan;
                        latencyHalfHeight_std(p, fcntSR) = nan;
                        settlingMin(p, fcntSR) = nan;
                        settlingMax(p, fcntSR) = nan;
                        PID = '';
                    end

                    set(gca,'fontsize',fontsz,'xminortick','on','yminortick','on','xtick',[0 100 200 300 400 500],'xticklabel',{'0' '100' '200' '300' '400' '500'},'ytick',[0 .25 .5 .75 1 1.25 1.5 1.75 2],'tickdir','out');

                    box off
                    if cnt <= 3, h=ylabel([ylab{p} ' Response '], 'fontweight','bold'); end

                    xlabel('Time (ms)', 'fontweight','bold');

                    if p==1, title('Step Response Functions');end
                    h=plot([0 500],[1 1],'--','Color',th.axesFg);
                    set(h,'linewidth',.5)
                    axis([0 500 0 ymax])
                    grid on

                    % Col 2: PID text in dedicated column
                    stag_ = sprintf('PSstep_%d', p+3);
                    hTxt = findobj(PStunefig, 'Type', 'axes', 'Tag', stag_);
                    if isempty(hTxt), hTxt = axes('Parent', PStunefig, 'Position', posInfo.TparamsPos(p+3,:), 'Tag', stag_, 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);
                    else set(PStunefig, 'CurrentAxes', hTxt); end
                    hold on
                    if size(stepresp_A{p},1)>1
                        if cnt <= 3, h=text(0.05, 0.97, [pidlabels],'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary); end
                        yBase_ = 0.88 - (fcntSR-1)*0.11;
                        h=text(0.05, yBase_, [int2str(fcntSR) ') ' PID '  (n=' int2str(size(stepresp_A{p},1)) ')'],'fontsize',fontsz);
                        set(h, 'Color',[multiLineCols(fcntSR,:)],'fontweight','bold')
                        metStr_ = sprintf('Pk=%.2f @%dms L=%dms S=[%.2f %.2f]', ...
                            peakresp(p,fcntSR), round(peaktime(p,fcntSR)), round(latencyHalfHeight(p,fcntSR)), ...
                            settlingMin(p,fcntSR), settlingMax(p,fcntSR));
                        h=text(0.07, yBase_-0.045, metStr_,'fontsize',max(fontsz-1,6));
                        set(h, 'Color',[multiLineCols(fcntSR,:)])
                    else
                        if cnt <= 3, h=text(0.05, 0.97, [pidlabels],'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary); end
                        yBase_ = 0.88 - (fcntSR-1)*0.11;
                        h=text(0.05, yBase_, [int2str(fcntSR) ') insufficient data'],'fontsize',fontsz);
                        set(h,'Color',[multiLineCols(fcntSR,:)],'fontweight','bold')
                    end

                    % Col 3: Peak (skip if no data)
                    if ~isnan(peakresp(p, fcntSR))
                    stag_ = sprintf('PSstep_%d', p+6);
                    h2 = findobj(PStunefig, 'Type', 'axes', 'Tag', stag_);
                    if isempty(h2), h2 = axes('Parent', PStunefig, 'Position', posInfo.TparamsPos(p+6,:), 'Tag', stag_);
                    else set(PStunefig, 'CurrentAxes', h2); end
                    h=plot(fcntSR, peakresp(p, fcntSR),'sk');
                    set(h,'Markersize',markerSz, 'MarkerFaceColor', [multiLineCols(fcntSR,:)])
                    if ~isnan(peakresp_std(p, fcntSR)) && peakresp_std(p, fcntSR) > 0
                        ey = peakresp_std(p, fcntSR);
                        yc = peakresp(p, fcntSR);
                        line([fcntSR fcntSR], [yc-ey yc+ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                        capW = 0.15;
                        line([fcntSR-capW fcntSR+capW], [yc-ey yc-ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                        line([fcntSR-capW fcntSR+capW], [yc+ey yc+ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                    end
                    ymxP = ymax; ymnP = 0.8;
                    for ei = 1:size(peakresp_std, 2)
                        if ~isnan(peakresp_std(p, ei))
                            ymxP = max(ymxP, peakresp(p, ei) + peakresp_std(p, ei));
                            ymnP = min(ymnP, peakresp(p, ei) - peakresp_std(p, ei));
                        end
                    end
                    ymnP = floor(ymnP * 10) / 10;
                    ymxP = ceil(ymxP * 10) / 10;
                    set(gca,'fontsize',fontsz, 'ylim',[ymnP ymxP],'ytick',[ymnP:.1:ymxP],'xlim',[0.5 fcntSR+0.5],'xtick',[1:fcntSR])
                    if cnt <= 3, title([ylab{p} ' Peak'], 'fontweight','bold'); end
                    hold on
                    grid on
                    plot([0 10],[1 1],'--','Color',th.axesFg)
                    end

                    % Col 4: Latency (skip if no data)
                    if ~isnan(latencyHalfHeight(p, fcntSR))
                    stag_ = sprintf('PSstep_%d', p+9);
                    h3 = findobj(PStunefig, 'Type', 'axes', 'Tag', stag_);
                    if isempty(h3), h3 = axes('Parent', PStunefig, 'Position', posInfo.TparamsPos(p+9,:), 'Tag', stag_);
                    else set(PStunefig, 'CurrentAxes', h3); end
                    h=plot(fcntSR, latencyHalfHeight(p, fcntSR),'sk');
                    set(h,'Markersize',markerSz, 'MarkerFaceColor', [multiLineCols(fcntSR,:)])
                    if ~isnan(latencyHalfHeight_std(p, fcntSR)) && latencyHalfHeight_std(p, fcntSR) > 0
                        ey = latencyHalfHeight_std(p, fcntSR);
                        yc = latencyHalfHeight(p, fcntSR);
                        line([fcntSR fcntSR], [yc-ey yc+ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                        capW = 0.15;
                        line([fcntSR-capW fcntSR+capW], [yc-ey yc-ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                        line([fcntSR-capW fcntSR+capW], [yc+ey yc+ey], 'Color', multiLineCols(fcntSR,:), 'LineWidth', 1.2);
                    end

                    mn = min(latencyHalfHeight(p, :));
                    mx = max(latencyHalfHeight(p, :));
                    for ei = 1:size(latencyHalfHeight_std, 2)
                        if ~isnan(latencyHalfHeight_std(p, ei))
                            mn = min(mn, latencyHalfHeight(p, ei) - latencyHalfHeight_std(p, ei));
                            mx = max(mx, latencyHalfHeight(p, ei) + latencyHalfHeight_std(p, ei));
                        end
                    end
                    yminLat = 2*floor((mn-2)/2);
                    ymaxLat = 2*ceil((mx+2)/2);
                    latRange_ = ymaxLat - yminLat;
                    if latRange_ > 40, latStep_ = 10;
                    elseif latRange_ > 20, latStep_ = 5;
                    else latStep_ = 2; end
                    yminLat = latStep_*floor((mn-2)/latStep_);
                    ymaxLat = latStep_*ceil((mx+2)/latStep_);
                    try
                    set(gca,'fontsize',fontsz,'ylim',[yminLat ymaxLat],'ytick',[yminLat:latStep_:ymaxLat], 'xtick',[1:fcntSR],'xlim',[0.5 fcntSR+0.5])
                    catch
                    end
                    if cnt <= 3, title([ylab{p} ' Latency (ms)'], 'fontweight','bold'); end
                    hold on
                    grid on
                    end


                end


                if get(guiHandlesTune.RPYcombo, 'Value') == 1
                    h1 = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_combo');
                    if isempty(h1), h1 = axes('Parent', PStunefig, 'Position', [0.0500 0.1 0.72 0.84], 'Tag', 'PSstep_combo');
                    else set(PStunefig, 'CurrentAxes', h1); end
                    hold on

                     if size(stepresp_A{p},1)>1
                        s = [];
                        s = stepresp_A{p};
                        m=nanmean(s);
                        sd=nanstd(s);

                        col_i = multiLineCols(fcntSR,:);

                        % SD shading band
                        tFlip = [tA fliplr(tA)];
                        sdBand = [m+sd fliplr(m-sd)];
                        patch(tFlip, sdBand, col_i, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'Parent', gca);

                        if isfield(guiHandlesTune, 'rawTraces') && get(guiHandlesTune.rawTraces, 'Value')
                            col_raw = col_i * 0.12 + th.axesBg * 0.88;
                            nSeg_ = size(s,1);
                            tAll_ = repmat([tA NaN], 1, nSeg_);
                            sAll_ = reshape([s'; NaN(1, nSeg_)], 1, []);
                            plot(tAll_, sAll_, 'Color', col_raw, 'LineWidth', 0.5);
                        end

                        h1=plot(tA,m);
                        set(h1, 'color', col_i, 'linewidth', get(guiHandles.linewidth, 'Value')/1.5, 'linestyle', lineStyle{cnt2});
                        if get(guiHandlesTune.srLatency, 'Value') == 2 && exist('xcorrLag_cache', 'var')
                            latencyHalfHeight(p, fcntSR) = xcorrLag_cache(p);
                        else
                            idx50_ = find(m > .5, 1);
                            if ~isempty(idx50_)
                                latencyHalfHeight(p, fcntSR) = (idx50_ / A_lograte(f)) - 1;
                            else
                                latencyHalfHeight(p, fcntSR) = nan;
                            end
                        end
                        peakIdx_ = find(tA < 150);
                        peakresp(p, fcntSR) = max(m(peakIdx_));
                        [~, pkI_] = max(m(peakIdx_));
                        peaktime(p, fcntSR) = pkI_(1) / A_lograte(f);
                        settleIdx_ = find(tA > 200 & tA < 500);
                        if ~isempty(settleIdx_)
                            settlingMin(p, fcntSR) = min(m(settleIdx_));
                            settlingMax(p, fcntSR) = max(m(settleIdx_));
                        else
                            settlingMin(p, fcntSR) = nan;
                            settlingMax(p, fcntSR) = nan;
                        end

                        PID = eval([ylab2{p} 'PIDF{f}']);
                        if cnt <= 3
                            if size(axesOptions,2) < 2
                                h=text(505, ypos(p)+0.04, [ylab{p}]);
                            else
                                h=text(505, ypos(p)+0.04, [ylab{p} ' (' lnLabels{cnt2} ')']);
                            end

                            set(h,'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary);
                            h=text(505, ypos(p), [pidlabels]);
                            set(h,'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary);
                        end
                        h=text(505, ypos(p)-(fcntSR*.07), [int2str(fcntSR) ') ' PID '  (n=' int2str(size(stepresp_A{p},1)) ')']);
                        set(h, 'Color',[multiLineCols(fcntSR,:)],'fontweight','bold','fontsize',fontsz)
                        metStr_ = sprintf('Pk=%.2f @%dms  L=%dms  S=[%.2f-%.2f]', ...
                            peakresp(p,fcntSR), round(peaktime(p,fcntSR)), round(latencyHalfHeight(p,fcntSR)), ...
                            settlingMin(p,fcntSR), settlingMax(p,fcntSR));
                        h=text(510, ypos(p)-(fcntSR*.07)-0.03, metStr_,'fontsize',max(fontsz-1,6));
                        set(h, 'Color',[multiLineCols(fcntSR,:)])
                    else
                        peakresp(p, fcntSR) = nan;
                        peaktime(p, fcntSR) = nan;
                        latencyHalfHeight(p, fcntSR) = nan;
                        settlingMin(p, fcntSR) = nan;
                        settlingMax(p, fcntSR) = nan;
                        if cnt <= 3
                            if size(axesOptions,2) < 2
                                h=text(505, ypos(p)+0.04, [ylab{p}]);
                            else
                                h=text(505, ypos(p)+0.04, [ylab{p} ' (' lnLabels{cnt2} ')']);
                            end

                            set(h,'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary);
                            h=text(505, ypos(p), [pidlabels]);
                            set(h,'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary);
                        end
                        h=text(505, ypos(p)-(fcntSR*.044), [int2str(fcntSR) ') insufficient data']);
                        set(h,'Color',[multiLineCols(fcntSR,:)],'fontsize',fontsz, 'fontweight','bold')
                    end

                    set(gca,'fontsize',fontsz,'xminortick','on','yminortick','on','xtick',[0 100 200 300 400 500],'xticklabel',{'0' '100' '200' '300' '400' '500'},'ytick',[0 .25 .5 .75 1 1.25 1.5 1.75 2],'tickdir','out');

                    box off
                    if cnt <= 3, h=ylabel(['Response '], 'fontweight','bold'); end

                    xlabel('Time (ms)', 'fontweight','bold');

                    title('Step Response Functions');
                    h=plot([0 500],[1 1],'--','Color',th.axesFg);
                    set(h,'linewidth',.5)
                    axis([0 500 0 ymax])
                    grid on
                end
            end

        elseif fcntSR == 11
            warndlg('10 files maximum. Click reset.');
        end
    end
   % auto-hide axes where ALL files had insufficient data
   if ~updateStep && ~isempty(peakresp)
       rpyH_ = {guiHandlesTune.plotR, guiHandlesTune.plotP, guiHandlesTune.plotY};
       needRedraw_ = false;
       for pi_ = 1:3
           if get(rpyH_{pi_}, 'Value') == 1 && size(peakresp,1) >= pi_
               if all(isnan(peakresp(pi_, :)))
                   set(rpyH_{pi_}, 'Value', 0, 'Enable', 'off');
                   for off_ = [0 3 6 9]
                       h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', sprintf('PSstep_%d', pi_+off_));
                       if ~isempty(h_del), delete(h_del); end
                   end
                   needRedraw_ = true;
               end
           end
       end
       if needRedraw_
           axesOptions = find([get(guiHandlesTune.plotR,'Value') get(guiHandlesTune.plotP,'Value') get(guiHandlesTune.plotY,'Value')]);
           nActiveTune = numel(axesOptions);
           if nActiveTune > 0 && nActiveTune < 3
               topY_t = stdRows_t(1) + stdRowH_t; botY_t = stdRows_t(3); gapT = 0.05;
               rowH_t = (topY_t - botY_t - (nActiveTune-1)*gapT) / nActiveTune;
               ci = 0;
               for jj = axesOptions
                   ci = ci + 1;
                   yy = topY_t - ci*rowH_t - (ci-1)*gapT;
                   for cc = 0:3
                       htmp_ = findobj(PStunefig,'Type','axes','Tag',sprintf('PSstep_%d',jj+cc*3));
                       if ~isempty(htmp_)
                           pos_ = get(htmp_(1),'Position');
                           pos_(2) = yy; pos_(4) = rowH_t;
                           set(htmp_(1),'Position',pos_);
                       end
                   end
               end
           end
       end
   end

   allax = findobj(PStunefig, 'Type', 'axes', 'Visible', 'on');
   for axi = 1:numel(allax), PSstyleAxes(allax(axi), th); end
   try PSresizeCP(PStunefig, []); catch, end
   set(PStunefig, 'pointer', 'arrow')

    updateStep=0;
else
    for p = 1 : 3
        for off_ = [0 3 6 9]
            stag_ = sprintf('PSstep_%d', p+off_);
            h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', stag_);
            if ~isempty(h_del), delete(h_del); end
        end
        peaktime = [];
        peakresp = [];
        latencyHalfHeight = [];
        latencyHalfHeight_std = [];
        peakresp_std = [];
        settlingMin = [];
        settlingMax = [];
    end
    h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_combo');
    if ~isempty(h_del), delete(h_del); end
    h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_bfsliders');
    if ~isempty(h_del), delete(h_del); end
end




