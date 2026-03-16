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
if ~get(guiHandlesTune.clearPlots, 'Value')
    cnt = 0;
    set(PStunefig, 'pointer', 'watch')
    pause(.05);

    for f = get(guiHandlesTune.fileListWindowStep, 'Value')
        fcntSR = fcntSR + 1;
        if fcntSR <= 10
            cnt2 = 0;
            for p = axesOptions
                cnt = cnt + 1;
                cnt2 = cnt2 + 1;
                try
                    if ~updateStep
                        clear H G L
                        H = T{f}.(['setpoint_' int2str(p-1) '_'])(tIND{f});
                        G = T{f}.(['gyroADC_' int2str(p-1) '_'])(tIND{f});
                        [stepresp_A{p} tA] = PSstepcalc(H, G, A_lograte(f), get(guiHandlesTune.Ycorrection, 'Value'), get(guiHandlesTune.smoothFactor_select, 'Value'));
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
                            for si = 1:size(s,1)
                                plot(tA, s(si,:), 'Color', col_raw, 'LineWidth', 0.5);
                            end
                        end

                        h1=plot(tA,m);
                        set(h1, 'color', col_i, 'linewidth', get(guiHandles.linewidth, 'Value')/1.5);
                        if get(guiHandlesTune.srLatency, 'Value') == 2 && exist('xcorrLag_cache', 'var')
                            latencyHalfHeight(p, fcntSR) = xcorrLag_cache(p);
                        else
                            latencyHalfHeight(p, fcntSR) = (find(m>.5,1) / A_lograte(f)) - 1;
                        end
                        peakresp(p, fcntSR)=max(m(find(tA<150)));
                        peaktime(p, fcntSR)=find(m == max(m(find(tA<150)))) / A_lograte(f);

                        % per-segment metrics for error bars
                        peakIdx = find(tA < 150);
                        segPeaks = zeros(1, size(s,1));
                        segLats = zeros(1, size(s,1));
                        for si = 1:size(s,1)
                            segPeaks(si) = max(s(si, peakIdx));
                            idx50 = find(s(si,:) > 0.5, 1);
                            if ~isempty(idx50)
                                segLats(si) = (idx50 / A_lograte(f)) - 1;
                            else
                                segLats(si) = nan;
                            end
                        end
                        peakresp_std(p, fcntSR) = nanstd(segPeaks);
                        latencyHalfHeight_std(p, fcntSR) = nanstd(segLats);

                        pidvar = [ylab2{p} 'PIDF'];
                        PID = eval([pidvar '{f}']);
                    else
                        peakresp(p, fcntSR) = nan;
                        peaktime(p, fcntSR) = nan;
                        latencyHalfHeight(p, fcntSR) = nan;
                        peakresp_std(p, fcntSR) = nan;
                        latencyHalfHeight_std(p, fcntSR) = nan;
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
                        h=text(0.05, 0.97-(fcntSR*.09), [int2str(fcntSR) ') ' PID '  (n=' int2str(size(stepresp_A{p},1)) ')'],'fontsize',fontsz);
                        set(h, 'Color',[multiLineCols(fcntSR,:)],'fontweight','bold')
                    else
                        if cnt <= 3, h=text(0.05, 0.97, [pidlabels],'fontsize',fontsz,'fontweight','bold','Color',th.textPrimary); end
                        h=text(0.05, 0.97-(fcntSR*.09), [int2str(fcntSR) ') insufficient data'],'fontsize',fontsz);
                        set(h,'Color',[multiLineCols(fcntSR,:)],'fontweight','bold')
                    end

                    % Col 3: Peak
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
                    ymxP = ymxP + 0.05; ymnP = max(0, ymnP - 0.05);
                    set(gca,'fontsize',fontsz, 'ylim',[ymnP ymxP],'ytick',[ymnP:.1:ymxP],'xlim',[0.5 fcntSR+0.5],'xtick',[1:fcntSR])
                    ylabel([ylab{p} ' Peak '], 'fontweight','bold');
                    xlabel('test', 'fontweight','bold');
                    hold on
                    grid on
                    plot([0 10],[1 1],'--','Color',th.axesFg)

                    % Col 4: Latency
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

                    mn = min(latencyHalfHeight(p, :))-rem(min(latencyHalfHeight(p, :)),2);
                    mx = max(latencyHalfHeight(p, :))+rem(max(latencyHalfHeight(p, :)),2);
                    for ei = 1:size(latencyHalfHeight_std, 2)
                        if ~isnan(latencyHalfHeight_std(p, ei))
                            mn = min(mn, latencyHalfHeight(p, ei) - latencyHalfHeight_std(p, ei));
                            mx = max(mx, latencyHalfHeight(p, ei) + latencyHalfHeight_std(p, ei));
                        end
                    end
                    ymaxLat = mx+4;
                    yminLat = mn-4;
                    try
                    set(gca,'fontsize',fontsz,'ylim',[yminLat ymaxLat],'ytick',[yminLat:2:ymaxLat], 'xtick',[1:fcntSR],'xlim',[0.5 fcntSR+0.5])
                    catch
                    end
                    ylabel([ylab{p} ' Latency (ms) '], 'fontweight','bold');
                    xlabel('Test', 'fontweight','bold');
                    hold on
                    grid on


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
                            for si = 1:size(s,1)
                                plot(tA, s(si,:), 'Color', col_raw, 'LineWidth', 0.5);
                            end
                        end

                        h1=plot(tA,m);
                        set(h1, 'color', col_i, 'linewidth', get(guiHandles.linewidth, 'Value')/1.5, 'linestyle', lineStyle{cnt2});
                        if get(guiHandlesTune.srLatency, 'Value') == 2 && exist('xcorrLag_cache', 'var')
                            latencyHalfHeight(p, fcntSR) = xcorrLag_cache(p);
                        else
                            latencyHalfHeight(p, fcntSR) = (find(m>.5,1) / A_lograte(f)) - 1;
                        end
                        peakresp(p, fcntSR)=max(m(find(tA<150)));
                        peaktime(p, fcntSR)=find(m == max(m(find(tA<150)))) / A_lograte(f);

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
                        h=text(505, ypos(p)-(fcntSR*.044), [int2str(fcntSR) ') ' PID '  (n=' int2str(size(stepresp_A{p},1)) ')']);set(h,'fontsize',fontsz);
                        set(h, 'Color',[multiLineCols(fcntSR,:)],'fontweight','bold')
                        set(h,'fontsize',fontsz)
                    else
                        peakresp(p, fcntSR) = nan;
                        peaktime(p, fcntSR) = nan;
                        latencyHalfHeight(p, fcntSR) = nan;
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
    end
    h_del = findobj(PStunefig, 'Type', 'axes', 'Tag', 'PSstep_combo');
    if ~isempty(h_del), delete(h_del); end
end




