%% PSplotPIDerror - PID error distribution and error vs stick deflection

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

try

set(PSerrfig, 'pointer', 'watch');
th = PStheme();

if exist('fnameMaster','var') && ~isempty(fnameMaster)


    fA = 1;
    fB = []; if Nfiles >= 2, fB = 2; end

    axPIDerr = {'piderr_0_', 'piderr_1_', 'piderr_2_'};
    axSP = {'setpoint_0_', 'setpoint_1_', 'setpoint_2_'};

    %% PID error distributions
    ylab2 = {'roll'; 'pitch'; 'yaw'};
    figure(PSerrfig);
    for p = 1:3
        delete(subplot('position', posInfo.PIDerrAnalysis(p,:)));
        h1 = subplot('position', posInfo.PIDerrAnalysis(p,:)); cla;
        hold on;

        piderr_A = T{fA}.(axPIDerr{p})(tIND{fA})';
        mask_A = true(size(piderr_A));
        for q = 1:3
            mask_A = mask_A & abs(T{fA}.(axSP{q})(tIND{fA})') < maxDegsec ...
                             & abs(T{fA}.(axPIDerr{q})(tIND{fA})') < maxDegsec;
        end

        [yA, xA] = hist(piderr_A(mask_A), -1000:1:1000);
        yA = yA / max(yA);
        h = plot(xA, yA);
        set(h, 'color', colorA, 'Linewidth', 2);
        if p == 3
            set(h1, 'xtick', -40:10:40, 'ytick', 0:.25:1, 'tickdir', 'out', ...
                'xminortick', 'on', 'yminortick', 'on', 'fontsize', fontsz3);
            xlabel('PID error (deg/s)', 'fontweight', 'bold');
        else
            set(h1, 'xtick', -40:10:40, 'xticklabel', {}, 'ytick', 0:.25:1, ...
                'tickdir', 'out', 'xminortick', 'on', 'yminortick', 'on', 'fontsize', fontsz3);
        end
        ylabel('normalized freq', 'fontweight', 'bold');
        h = text(-37, .9, ylab2{p});
        set(h, 'fontsize', fontsz3, 'fontweight', 'bold');
        grid on;
        axis([-40 40 0 1]);
        h = text(10, .9, ['[1]s.d.=' num2str(round(std(piderr_A(mask_A))*10)/10)]);
        set(h, 'fontsize', fontsz3, 'color', colorA, 'fontweight', 'bold');

        if ~isempty(fB)
            piderr_B = T{fB}.(axPIDerr{p})(tIND{fB})';
            mask_B = true(size(piderr_B));
            for q = 1:3
                mask_B = mask_B & abs(T{fB}.(axSP{q})(tIND{fB})') < maxDegsec ...
                                 & abs(T{fB}.(axPIDerr{q})(tIND{fB})') < maxDegsec;
            end
            [yB, xB] = hist(piderr_B(mask_B), -1000:1:1000);
            yB = yB / max(yB);
            h = plot(xB, yB);
            set(h, 'color', colorB, 'Linewidth', 2);
            h = text(10, .8, ['[2]s.d.=' num2str(round(std(piderr_B(mask_B))*10)/10)]);
            set(h, 'fontsize', fontsz3, 'color', colorB, 'fontweight', 'bold');

            try
                [~, pval] = kstest2(yA, yB);
                if pval <= .05, sigflag = '*'; else, sigflag = ''; end
                h = text(10, .7, ['p=' num2str(pval) sigflag]);
                set(h, 'fontsize', fontsz3, 'fontweight', 'bold');
            catch
            end
        end

        box off;
        if p == 1, title('normalized PID error distributions'); end
    end


    %% PID error x stick deflection
    if ~updateErr
        t = [.1 .2 .3 .4 .5 .6 .7 .8 .9 1];

        sp_A = zeros(3, sum(tIND{fA}));
        err_A = zeros(3, sum(tIND{fA}));
        for q = 1:3
            sp_A(q,:) = T{fA}.(axSP{q})(tIND{fA})';
            err_A(q,:) = T{fA}.(axPIDerr{q})(tIND{fA})';
        end
        maxSP_A = max(abs(sp_A(:)));

        Perr_a_m = zeros(3, length(t));
        Perr_a_se = zeros(3, length(t));
        for i = 1:length(t)
            m = maxSP_A * t(i);
            msk = abs(sp_A(1,:)) < m & abs(sp_A(2,:)) < m & abs(sp_A(3,:)) < m ...
                & abs(err_A(1,:)) < m & abs(err_A(2,:)) < m & abs(err_A(3,:)) < m;
            for j = 1:3
                pe = abs(err_A(j, msk));
                Perr_a_m(j,i) = mean(pe);
                Perr_a_se(j,i) = std(pe) / sqrt(numel(pe));
            end
        end

        if ~isempty(fB)
            sp_B = zeros(3, sum(tIND{fB}));
            err_B = zeros(3, sum(tIND{fB}));
            for q = 1:3
                sp_B(q,:) = T{fB}.(axSP{q})(tIND{fB})';
                err_B(q,:) = T{fB}.(axPIDerr{q})(tIND{fB})';
            end
            maxSP_B = max(abs(sp_B(:)));

            Perr_b_m = zeros(3, length(t));
            Perr_b_se = zeros(3, length(t));
            for i = 1:length(t)
                m = maxSP_B * t(i);
                msk = abs(sp_B(1,:)) < m & abs(sp_B(2,:)) < m & abs(sp_B(3,:)) < m ...
                    & abs(err_B(1,:)) < m & abs(err_B(2,:)) < m & abs(err_B(3,:)) < m;
                for j = 1:3
                    pe = abs(err_B(j, msk));
                    Perr_b_m(j,i) = mean(pe);
                    Perr_b_se(j,i) = std(pe) / sqrt(numel(pe));
                end
            end
        end
        updateErr = 0;
    end

    %% plot error x stick
    ylab = ['R'; 'P'; 'Y'];
    for p = 1:3
        delete(subplot('position', posInfo.PIDerrAnalysis(p+3,:)));
        h1 = subplot('position', posInfo.PIDerrAnalysis(p+3,:)); cla;
        posAx = .8:1:9.8;
        posBx = 1.2:1:10.2;

        minyA = min(Perr_a_m(p,:)) - .5; if minyA < 0, minyA = 0; end
        maxyA = max(Perr_a_m(p,:)) + .5;
        h = errorbar(posAx, Perr_a_m(p,:), Perr_a_se(p,:)); hold on;
        set(h, 'color', th.axesFg, 'LineStyle', 'none');
        h = bar(posAx, Perr_a_m(p,:));
        set(h, 'facecolor', colorA, 'BarWidth', .4);
        set(h1, 'tickdir', 'out', 'xminortick', 'off', 'yminortick', 'on', 'fontsize', fontsz3);
        ylabel(['mean |' ylab(p) ' error| ^o/s'], 'fontweight', 'bold');
        set(h1, 'xtick', 0:2:10, 'xticklabel', {''}, 'ygrid', 'on');
        axis([0 11 minyA maxyA]);
        box off;
        if p == 3
            set(h1, 'xtick', 0:1:10, 'xticklabel', ...
                {'0','','20','','40','','60','','80','','100'});
            xlabel('stick deflection (% of max)', 'fontweight', 'bold');
        else
            set(h1, 'xtick', 0:1:10, 'xticklabel', ...
                {'','','','','','','','','','',''});
        end

        if ~isempty(fB)
            minyB = min(Perr_b_m(p,:)) - .5; if minyB < 0, minyB = 0; end
            maxyB = max(Perr_b_m(p,:)) + .5;
            h = errorbar(posBx, Perr_b_m(p,:), Perr_b_se(p,:));
            set(h, 'color', th.axesFg, 'LineStyle', 'none');
            h = bar(posBx, Perr_b_m(p,:));
            set(h, 'facecolor', colorB, 'BarWidth', .4);
            axis([0 11 min([minyA minyB]) max([maxyA maxyB])]);
            box off;
            if p == 3
                set(h1, 'xtick', 0:1:10, 'xticklabel', ...
                    {'0','','20','','40','','60','','80','','100'});
                xlabel('stick deflection (% of max)', 'fontweight', 'bold');
            else
                set(h1, 'xtick', 0:1:10, 'xticklabel', ...
                    {'','','','','','','','','','',''});
            end
        end

        if p == 1, title('mean abs PID error X stick deflection'); end
    end

end

allax = findobj(PSerrfig, 'Type', 'axes');
for axi = 1:numel(allax), PSstyleAxes(allax(axi), th); end
set(PSerrfig, 'pointer', 'arrow');

catch err
    msgPSplotPIDerror = PSerrorMessages('PSplotPIDerror', err);
end
