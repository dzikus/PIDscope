function PSplotBode(freq, G_track, G_plant, C, stepData, titleStr)
%% PSplotBode - Bode plot with magnitude, phase, coherence, and step response
%  freq      - frequency vector (Hz)
%  G_track   - complex tracking transfer function (setpoint → gyro)
%  G_plant   - complex plant transfer function (or [] to skip)
%  C         - coherence 0..1
%  stepData  - struct with .t_ms and .step (or [] to skip)
%  titleStr  - plot title suffix

th = PStheme();
screensz = get(0, 'ScreenSize');
fig = figure('Name', ['Chirp Analysis - ' titleStr], 'NumberTitle', 'off', ...
    'Color', th.figBg, ...
    'Position', round([.08*screensz(3) .06*screensz(4) .78*screensz(3) .82*screensz(4)]));

freq = freq(:);
fPlot = freq(freq > 0);  % skip DC for log plot

% --- magnitude ---
ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .72 .55 .22]);
mag_T = 20*log10(abs(G_track(freq > 0)));
semilogx(ax1, fPlot, mag_T, 'Color', [0 .8 1], 'LineWidth', 1.5);
hold(ax1, 'on');
if ~isempty(G_plant)
    mag_P = 20*log10(abs(G_plant(freq > 0)));
    semilogx(ax1, fPlot, mag_P, 'Color', [1 .5 0], 'LineWidth', 1.2);
    h_leg = legend(ax1, {'Tracking (T)', 'Plant (P)'}, 'Location', 'southwest');
    try PSstyleLegend(h_leg, th); catch, end
end
line(ax1, [fPlot(1) fPlot(end)], [0 0], 'Color', [.5 .5 .5], 'LineStyle', '--');
hold(ax1, 'off');
PSstyleAxes(ax1, th);
set(get(ax1, 'YLabel'), 'String', 'Magnitude (dB)');
th1 = title(ax1, ['Bode - ' titleStr]);

% --- phase ---
ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .42 .55 .22]);
phase_T = unwrap(angle(G_track(freq > 0))) * 180/pi;
semilogx(ax2, fPlot, phase_T, 'Color', [0 .8 1], 'LineWidth', 1.5);
hold(ax2, 'on');
if ~isempty(G_plant)
    phase_P = unwrap(angle(G_plant(freq > 0))) * 180/pi;
    semilogx(ax2, fPlot, phase_P, 'Color', [1 .5 0], 'LineWidth', 1.2);
end
line(ax2, [fPlot(1) fPlot(end)], [-180 -180], 'Color', [.8 .3 .3], 'LineStyle', '--');
hold(ax2, 'off');
PSstyleAxes(ax2, th);
set(get(ax2, 'YLabel'), 'String', 'Phase (deg)');

% --- coherence ---
ax3 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .08 .55 .26]);
semilogx(ax3, fPlot, C(freq > 0), 'Color', [.3 .9 .3], 'LineWidth', 1.2);
hold(ax3, 'on');
line(ax3, [fPlot(1) fPlot(end)], [.8 .8], 'Color', [.5 .5 .5], 'LineStyle', '--');
hold(ax3, 'off');
PSstyleAxes(ax3, th);
set(ax3, 'YLim', [0 1.05]);
set(get(ax3, 'XLabel'), 'String', 'Frequency (Hz)');
set(get(ax3, 'YLabel'), 'String', 'Coherence');

linkaxes([ax1 ax2 ax3], 'x');
if ~isempty(fPlot)
    set(ax1, 'XLim', [max(fPlot(1), 0.5) min(fPlot(end), 1000)]);
end

% --- step response (right side) ---
ax4 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.72 .42 .24 .52]);
if ~isempty(stepData) && isfield(stepData, 't_ms') && isfield(stepData, 'step')
    plot(ax4, stepData.t_ms, stepData.step, 'Color', [0 .8 1], 'LineWidth', 1.8);
    hold(ax4, 'on');
    line(ax4, [0 max(stepData.t_ms)], [1 1], 'Color', [.5 .5 .5], 'LineStyle', '--');
    % overshoot
    peak = max(stepData.step);
    if peak > 1.01
        os_pct = (peak - 1) * 100;
        [~, pk_idx] = max(stepData.step);
        plot(ax4, stepData.t_ms(pk_idx), peak, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        text(stepData.t_ms(pk_idx)+5, peak, sprintf('%.0f%%', os_pct), ...
            'Color', [1 .3 .3], 'FontSize', 12, 'FontWeight', 'bold', 'Parent', ax4);
    end
    hold(ax4, 'off');
end
PSstyleAxes(ax4, th);
set(get(ax4, 'XLabel'), 'String', 'Time (ms)');
set(get(ax4, 'YLabel'), 'String', 'Step Response');
title(ax4, 'Step (from FRD)');

% --- info panel (bottom right) ---
ax5 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.72 .08 .24 .26]);
set(ax5, 'Visible', 'off');

% gain/phase margins from tracking TF
[gm_dB, pm_deg, wcg, wcp] = margins_from_G(fPlot, G_track(freq > 0));

infoLines = {};
infoLines{end+1} = sprintf('Gain margin: %.1f dB @ %.0f Hz', gm_dB, wcg);
infoLines{end+1} = sprintf('Phase margin: %.1f deg @ %.0f Hz', pm_deg, wcp);
if ~isempty(stepData) && isfield(stepData, 'step')
    peak = max(stepData.step);
    infoLines{end+1} = sprintf('Overshoot: %.0f%%', max(0, (peak-1)*100));
    % settling time (2% band)
    settled = find(abs(stepData.step - 1) < 0.02 & stepData.t_ms > stepData.t_ms(end)*0.1, 1);
    if ~isempty(settled)
        infoLines{end+1} = sprintf('Settling (2%%): %.0f ms', stepData.t_ms(settled));
    end
end
text(0.05, 0.9, infoLines, 'Parent', ax5, 'Color', th.textAccent, ...
    'FontSize', 12, 'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
    'Units', 'normalized');

PSdatatipSetup(fig);

end



function [gm_dB, pm_deg, wcg, wcp] = margins_from_G(freq, G)
    % gain margin: gain at -180 deg phase crossing
    % phase margin: phase at 0 dB gain crossing
    mag = abs(G);
    phase = unwrap(angle(G)) * 180/pi;

    % 0 dB crossing → phase margin
    mag_dB = 20*log10(mag + 1e-12);
    crossings = find(diff(sign(mag_dB)) ~= 0);
    if ~isempty(crossings)
        ci = crossings(1);
        wcp = interp1(mag_dB(ci:ci+1), freq(ci:ci+1), 0, 'linear');
        pm_deg = interp1(freq(ci:ci+1), phase(ci:ci+1), wcp, 'linear') + 180;
    else
        wcp = NaN; pm_deg = NaN;
    end

    % -180 deg crossing → gain margin
    crossings = find(diff(sign(phase + 180)) ~= 0);
    if ~isempty(crossings)
        ci = crossings(end);
        wcg = interp1(phase(ci:ci+1), freq(ci:ci+1), -180, 'linear');
        gm_val = interp1(freq(ci:ci+1), mag(ci:ci+1), wcg, 'linear');
        gm_dB = -20*log10(gm_val + 1e-12);
    else
        wcg = NaN; gm_dB = NaN;
    end
end
