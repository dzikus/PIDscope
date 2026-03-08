%% PSplotStats - flight statistics (histograms, mean+SD)

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if ~exist('fnameMaster','var') || isempty(fnameMaster), return; end

try

th = PStheme();
set(PSstatsfig, 'pointer', 'watch');


fA = get(guiHandlesStats.FileA, 'Value');
fB = [];
if Nfiles >= 2 && isfield(guiHandlesStats, 'FileB') && ishandle(guiHandlesStats.FileB)
    fB = get(guiHandlesStats.FileB, 'Value');
    if fB == fA, fB = []; end
end

plotMode = get(guiHandlesStats.crossAxesStats, 'Value');

%% Histograms
if plotMode == 1

    clear posInfo.statsPos
    cols = [0.06 0.54];
    rows = [0.69 0.48 0.27 0.06];
    k = 0;
    for c = 1:2
        for r = 1:4
            k = k + 1;
            posInfo.statsPos(k,:) = [cols(c) rows(r) 0.39 0.18];
        end
    end

    axLbl = {'% roll', '% pitch', '% yaw', '% throttle'};
    rcFields = {'rcCommand_0_', 'rcCommand_1_', 'rcCommand_2_'};

    % File 1
    if ~updateStats
        for q = 1:3
            rcRaw = T{fA}.(rcFields{q})(tIND{fA});
            Rpct_A{q} = PSPercent(rcRaw);
        end
        Tpct_A = T{fA}.setpoint_3_(tIND{fA}) / 10;
    end

    for sp = 1:4
        hhist = subplot('position', posInfo.statsPos(sp,:)); cla;
        set(hhist, 'Tag', 'PSgrid');
        if sp <= 3
            pctData = Rpct_A{sp};
        else
            pctData = Tpct_A;
        end
        [nn, xx] = hist(pctData, 0:1:100);
        nn = nn / sum(nn);
        hb = bar(xx, nn, 1);
        set(hb, 'FaceColor', colorA, 'EdgeColor', colorA);
        y = xlabel(axLbl{sp}, 'fontweight', 'bold');
        set(y, 'Units', 'normalized', 'position', [.5 -.1 1], 'color', th.textPrimary);
        ylabel('% of flight', 'fontweight', 'bold');
        set(hhist, 'tickdir', 'in', 'xlim', [0 100], 'xtick', [0 20 40 60 80 100], ...
            'ylim', [0 .1], 'ytick', [0 .05 .1], ...
            'xticklabel', {'0','20','40','60','80','100'}, ...
            'yticklabel', {'0','5','10'}, 'fontsize', fontsz5);
        axis([0 100 0 .1]);
        grid on;
    end

    % File 2
    if ~isempty(fB)
        if ~updateStats
            for q = 1:3
                rcRaw = T{fB}.(rcFields{q})(tIND{fB});
                Rpct_B{q} = PSPercent(rcRaw);
            end
            Tpct_B = T{fB}.setpoint_3_(tIND{fB}) / 10;
        end

        for sp = 1:4
            hhist = subplot('position', posInfo.statsPos(sp+4,:)); cla;
            set(hhist, 'Tag', 'PSgrid');
            if sp <= 3
                pctData = Rpct_B{sp};
            else
                pctData = Tpct_B;
            end
            [nn, xx] = hist(pctData, 0:1:100);
            nn = nn / sum(nn);
            hb = bar(xx, nn, 1);
            set(hb, 'FaceColor', colorB, 'EdgeColor', colorB);
            y = xlabel(axLbl{sp}, 'fontweight', 'bold');
            set(y, 'Units', 'normalized', 'position', [.5 -.1 1], 'color', th.textPrimary);
            ylabel('% of flight', 'fontweight', 'bold');
            set(hhist, 'tickdir', 'in', 'xlim', [0 100], 'xtick', [0 20 40 60 80 100], ...
                'ylim', [0 .1], 'ytick', [0 .05 .1], ...
                'xticklabel', {'0','20','40','60','80','100'}, ...
                'yticklabel', {'0','5','10'}, 'fontsize', fontsz5);
            axis([0 100 0 .1]);
            grid on;
        end
    end
end


%% Mean +/- SD
if plotMode == 2

    cols = [0.06 0.30 0.54 0.78];
    rows = [0.69 0.48 0.27 0.06];
    k = 0;
    for c = 1:length(cols)
        for r = 1:length(rows)
            k = k + 1;
            posInfo.statsPos2(k,:) = [cols(c) rows(r) 0.18 0.16];
        end
    end
    lineThickness = 2;

    % field groups: {field_prefix, nAxes, xlabel, useAbs}
    groups = {
        {'gyroADC_', 3, '|Gyro|', true};
        {'axisP_',   3, '|Pterm|', true};
        {'axisI_',   3, '|Iterm|', true};
        {'axisD_',   2, '|Dterm|', true};
        {'setpoint_',3, '% RPYT', true};
        {'axisF_',   3, '|Fterm|', true};
        {'motor_',   4, 'Motors', false};
        {'debug_',   4, '|Debug|', true};
    };
    % subplot indices: col1=[1,2,3,4] col2=[5,6,7,8] col3=[9..] col4=[13..]
    % File A: slots 1-8, File B: slots 9-16
    slotA = [1 2 3 7 5 6 4 8];
    slotB = [9 10 11 15 13 14 12 16];
    axLabelsRPY = {'R','P','Y'};
    axLabelsRPYT = {'R','P','Y','T'};
    axLabelsM = {'1','2','3','4'};
    axLabelsD4 = {'0','1','2','3'};

    for fi = 1:2
        if fi == 1, f = fA; clr = colorA; slots = slotA; tag = '[1]';
        else
            if isempty(fB), continue; end
            f = fB; clr = colorB; slots = slotB; tag = '[2]';
        end

        for g = 1:length(groups)
            grp = groups{g};
            prefix = grp{1};
            nAx = grp{2};
            xlbl = grp{3};
            useAbs = grp{4};

            h1 = subplot('position', posInfo.statsPos2(slots(g),:)); cla;
            set(h1, 'Tag', 'PSgrid');

            vals = zeros(nAx, 1);
            sds = zeros(nAx, 1);
            for q = 1:nAx
                fld = [prefix int2str(q-1) '_'];
                if ~isfield(T{f}, fld), continue; end
                d = T{f}.(fld)(tIND{f});
                if useAbs, d = abs(d); end
                vals(q) = mean(d);
                sds(q) = std(d);
            end

            % special: setpoint group adds throttle as 4th bar
            if strcmp(prefix, 'setpoint_')
                nAx = 4;
                d = T{f}.setpoint_3_(tIND{f}) / 10;
                vals(4) = mean(d);
                sds(4) = std(d);
            end

            for q = 1:nAx
                s = errorbar(q, vals(q), sds(q)); hold on;
                set(s, 'color', th.axesFg, 'linewidth', lineThickness);
                s = bar(q, vals(q));
                set(s, 'FaceColor', clr);
            end

            if nAx == 2
                set(gca, 'Xtick', 1:nAx, 'xticklabel', axLabelsRPY(1:2));
                axis([.5 2.5 0 max(vals+sds)*1.2+1]);
            elseif nAx == 3
                set(gca, 'Xtick', 1:nAx, 'xticklabel', axLabelsRPY);
                axis([.5 3.5 0 max(vals+sds)*1.2+1]);
            elseif nAx == 4 && strcmp(prefix, 'setpoint_')
                set(gca, 'Xtick', 1:4, 'xticklabel', axLabelsRPYT);
                axis([.5 4.5 0 100]);
            elseif nAx == 4 && strcmp(prefix, 'motor_')
                set(gca, 'Xtick', 1:4, 'xticklabel', axLabelsM);
                axis([.5 4.5 0 100]);
            elseif nAx == 4
                set(gca, 'Xtick', 1:4, 'xticklabel', axLabelsD4);
                ymax = max(vals+sds)*1.2+1; if ymax < 1, ymax = 10; end
                axis([.5 4.5 0 ymax]);
            end

            set(gca, 'xcolor', clr, 'ycolor', clr, 'YMinorGrid', 'on');
            set(h1, 'fontsize', fontsz5);
            xlabel([xlbl ' ' tag], 'fontsize', fontsz5, 'fontweight', 'bold', 'color', clr);
            ylabel('Mean +SD', 'fontsize', fontsz5, 'fontweight', 'bold', 'color', clr);
            box off;
        end
    end
end


%% Topography and Axes x Throttle (modes 3-5)
if plotMode >= 3
    ax_msg = axes('Parent', PSstatsfig, 'Position', [.1 .3 .8 .4]);
    set(ax_msg, 'Visible', 'off');
    text(0.5, 0.5, {'Topography and Axes x Throttle modes', 'not yet ported to new data model.'}, ...
        'HorizontalAlignment', 'center', 'FontSize', fontsz, 'FontWeight', 'bold', ...
        'Color', th.textPrimary, 'Parent', ax_msg, 'Units', 'normalized');
end


allax = findobj(PSstatsfig, 'Type', 'axes');
for axi = 1:numel(allax), PSstyleAxes(allax(axi), th); end
try PSresizeCP(PSstatsfig, []); catch, end
set(PSstatsfig, 'pointer', 'arrow');

catch err
    msgPSplotStats = PSerrorMessages('PSplotStats', err);
end
