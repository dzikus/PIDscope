function PSplotBode(freq, G_track, G_plant, C, stepData, titleStr, pred)
%% PSplotBode - Bode plot with magnitude, phase, coherence, and step response
%  freq      - frequency vector (Hz)
%  G_track   - complex tracking transfer function (setpoint → gyro)
%  G_plant   - complex plant transfer function (or [] to skip)
%  C         - coherence 0..1
%  stepData  - struct with .t_ms and .step (or [] to skip)
%  titleStr  - plot title suffix
%  pred      - struct with .gains, .fp and .FsPid to enable the prediction
%              sliders (or [] / omitted for the plain plot)

if nargin < 7, pred = []; end
hasPred = ~isempty(pred) && ~isempty(G_plant);

th = PStheme();
fontsz = th.fontsz;
screensz = get(0, 'ScreenSize');
figName = ['Chirp Analysis - ' titleStr];
fig = findobj('Type', 'figure', 'Name', figName);
if ~isempty(fig), close(fig); end
fig = figure('Name', figName, 'NumberTitle', 'off', ...
    'Color', th.figBg, ...
    'Position', round([0 0 screensz(3) screensz(4)]));
try set(fig, 'WindowState', 'maximized'); catch, end

freq = freq(:);
fPlot = freq(freq > 0);  % skip DC for log plot
fMask = freq > 0;

% The prediction is only worth as much as the plant under it, and the plant
% stops meaning anything once the chirp no longer moves the airframe. Cut it at
% the same 0.8 coherence the plot already draws a line at, and take a run of
% bins rather than the first one so a single noisy bin does not end the band.
low = freq > 2 & C(:) < 0.8;
run = 5;
iBad = [];
if numel(low) >= run
    iBad = find(conv(double(low), ones(run, 1), 'valid') == run, 1);
end
if isempty(iBad)
    fTrust = max(freq);
else
    fTrust = freq(max(iBad - 1, 2));
end
predMask = fMask & freq <= fTrust;
fPred = freq(predMask);

if hasPred
    pos4 = [.72 .58 .24 .37];
    pos5 = [.72 .38 .24 .17];
else
    pos4 = [.72 .42 .24 .52];
    pos5 = [.72 .08 .24 .26];
end

% --- magnitude ---
ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .72 .55 .22]);
mag_T = 20*log10(abs(G_track(fMask)));
semilogx(ax1, fPlot, mag_T, 'Color', th.bodeMain, 'LineWidth', 1.5);
hold(ax1, 'on');
legEntries = {'Tracking (T)'};
if ~isempty(G_plant)
    mag_P = 20*log10(abs(G_plant(fMask)));
    semilogx(ax1, fPlot, mag_P, 'Color', th.bodeSecondary, 'LineWidth', 1.2);
    legEntries{end+1} = 'Plant (P)';
end
hPredMag = [];
if hasPred
    hPredMag = semilogx(ax1, fPred, nan(size(fPred)), ...
        'Color', th.bodePredicted, 'LineWidth', 1.5);
    legEntries{end+1} = 'Predicted';
end
if numel(legEntries) > 1
    h_leg = legend(ax1, legEntries, 'Location', 'southwest');
    try PSstyleLegend(h_leg, th); catch, end
end
line(ax1, [fPlot(1) fPlot(end)], [0 0], 'Color', th.bodeRef, 'LineStyle', '--');
hold(ax1, 'off');
PSstyleAxes(ax1, th);
set(get(ax1, 'YLabel'), 'String', 'Magnitude (dB)');
title(ax1, ['Bode - ' titleStr]);

% --- phase ---
ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .42 .55 .22]);
phase_T = unwrap(angle(G_track(fMask))) * 180/pi;
semilogx(ax2, fPlot, phase_T, 'Color', th.bodeMain, 'LineWidth', 1.5);
hold(ax2, 'on');
if ~isempty(G_plant)
    phase_P = unwrap(angle(G_plant(fMask))) * 180/pi;
    semilogx(ax2, fPlot, phase_P, 'Color', th.bodeSecondary, 'LineWidth', 1.2);
end
hPredPh = [];
if hasPred
    hPredPh = semilogx(ax2, fPred, nan(size(fPred)), ...
        'Color', th.bodePredicted, 'LineWidth', 1.5);
end
line(ax2, [fPlot(1) fPlot(end)], [-180 -180], 'Color', th.btnDash1, 'LineStyle', '--');
hold(ax2, 'off');
PSstyleAxes(ax2, th);
set(get(ax2, 'YLabel'), 'String', 'Phase (deg)');

% --- coherence ---
ax3 = axes('Parent', fig, 'Units', 'normalized', 'Position', [.08 .08 .55 .26]);
semilogx(ax3, fPlot, C(fMask), 'Color', th.bodeCoherence, 'LineWidth', 1.2);
hold(ax3, 'on');
line(ax3, [fPlot(1) fPlot(end)], [.8 .8], 'Color', th.bodeRef, 'LineStyle', '--');
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
ax4 = axes('Parent', fig, 'Units', 'normalized', 'Position', pos4);
hold(ax4, 'on');
if ~isempty(stepData) && isfield(stepData, 't_ms') && isfield(stepData, 'step')
    plot(ax4, stepData.t_ms, stepData.step, 'Color', th.bodeMain, 'LineWidth', 1.8);
    line(ax4, [0 max(stepData.t_ms)], [1 1], 'Color', th.bodeRef, 'LineStyle', '--');
    peak = max(stepData.step);
    if peak > 1.01
        [~, pk_idx] = max(stepData.step);
        plot(ax4, stepData.t_ms(pk_idx), peak, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        text(stepData.t_ms(pk_idx)+5, peak, sprintf('%.0f%%', (peak-1)*100), ...
            'Color', th.btnDash1, 'FontSize', fontsz, 'FontWeight', 'bold', 'Parent', ax4);
    end
end
hPredStep = [];
if hasPred
    hPredStep = plot(ax4, nan, nan, 'Color', th.bodePredicted, 'LineWidth', 1.8);
end
hold(ax4, 'off');
PSstyleAxes(ax4, th);
set(get(ax4, 'XLabel'), 'String', 'Time (ms)');
set(get(ax4, 'YLabel'), 'String', 'Step Response');
title(ax4, 'Step (from FRD)');

% --- info panel ---
ax5 = axes('Parent', fig, 'Units', 'normalized', 'Position', pos5);
set(ax5, 'Visible', 'off');

infoLines = {};
if ~isempty(stepData) && isfield(stepData, 'step')
    peak = max(stepData.step);
    infoLines{end+1} = sprintf('Measured overshoot: %.0f%%', max(0, (peak-1)*100));
    settled = find(abs(stepData.step - 1) < 0.02 & stepData.t_ms > stepData.t_ms(end)*0.1, 1);
    if ~isempty(settled)
        infoLines{end+1} = sprintf('Measured settling (2%%): %.0f ms', stepData.t_ms(settled));
    end
end
if ~hasPred
    % Margins need the open loop. Without the PID terms in the log there is no
    % plant and so no open loop - the numbers that used to go here were taken
    % off the closed loop and meant nothing.
    infoLines{end+1} = 'Margins need the PID terms in the log';
end
hInfo = text(0.05, 0.95, infoLines, 'Parent', ax5, 'Color', th.bodeMain, ...
    'FontSize', fontsz, 'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
    'Units', 'normalized');

hPredInfo = [];
hSl = []; hLbl = [];
gNames = {'P', 'I', 'D', 'FF'};
g0 = [0 0 0 0];

if hasPred
    hPredInfo = text(0.05, 0.45, {''}, 'Parent', ax5, 'Color', th.bodePredicted, ...
        'FontSize', fontsz, 'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
        'Units', 'normalized');
    g0 = [pred.gains.P pred.gains.I pred.gains.D pred.gains.F];
    buildPanel();
    redraw();
    PSstyleControls(fig, th);
end

PSdatatipSetup(fig);


    function buildPanel()
        % zero has no scale of its own, so fall back to a firmware-typical range
        fallbackHi = [100 100 100 200];
        yTop = .30; rh = .032; dy = .048;
        for k = 1:4
            hi = 2.5 * g0(k);
            if hi <= 0, hi = fallbackHi(k); end
            yy = yTop - (k-1)*dy;
            hLbl(k) = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
                'String', sprintf('%s %g', gNames{k}, g0(k)), ...
                'Position', [.700 yy-.004 .052 rh], 'FontSize', fontsz, ...
                'HorizontalAlignment', 'right', ...
                'ForegroundColor', th.textPrimary, 'BackgroundColor', th.figBg);
            hSl(k) = uicontrol(fig, 'Style', 'slider', 'Units', 'normalized', ...
                'Position', [.758 yy .200 rh], ...
                'Min', 0, 'Max', hi, 'Value', min(g0(k), hi), ...
                'SliderStep', [1/hi, 10/hi], ...
                'Callback', @(~,~) redraw());
        end
        uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
            'String', 'Reset to log', 'Position', [.758 yTop-4.6*dy .095 rh], ...
            'FontSize', fontsz, 'ForegroundColor', th.textPrimary, ...
            'Callback', @(~,~) resetGains());
    end


    function resetGains()
        for k = 1:4
            set(hSl(k), 'Value', min(g0(k), get(hSl(k), 'Max')));
        end
        redraw();
    end


    function redraw()
        v = zeros(1, 4);
        for k = 1:4
            v(k) = round(get(hSl(k), 'Value'));
            set(hLbl(k), 'String', sprintf('%s %g', gNames{k}, v(k)));
        end

        g = struct('P', v(1), 'I', v(2), 'D', v(3), 'F', v(4));
        [A, D, F] = PSbuildController(g, pred.fp, pred.FsPid, freq);
        [Tp, Lp] = PSpredictClosedLoop(G_plant, A, D, F);

        set(hPredMag, 'YData', 20*log10(abs(Tp(predMask)) + 1e-12));
        set(hPredPh, 'YData', unwrap(angle(Tp(predMask))) * 180/pi);

        [tp, sp] = PSstepFromFRD(freq, Tp, min(fTrust, 300));
        set(hPredStep, 'XData', tp, 'YData', sp);

        lines = {};
        pk = max(sp);
        lines{end+1} = sprintf('Predicted overshoot: %.0f%%', max(0, (pk-1)*100));
        st = find(abs(sp - 1) < 0.02 & tp > tp(end)*0.1, 1);
        if ~isempty(st)
            lines{end+1} = sprintf('Predicted settling (2%%): %.0f ms', tp(st));
        end
        % margins belong to the open loop, which only exists once a controller
        % is put around the measured plant
        [gm, pm, wg, wp] = PSmarginsFromL(fPred, Lp(predMask));
        if isnan(pm)
            lines{end+1} = 'Phase margin: no 0 dB crossing in band';
        else
            lines{end+1} = sprintf('Phase margin: %.0f deg @ %.0f Hz', pm, wp);
        end
        if isnan(gm)
            lines{end+1} = 'Gain margin: no phase crossover in band';
        else
            lines{end+1} = sprintf('Gain margin: %.1f dB @ %.0f Hz', gm, wg);
        end
        lines{end+1} = sprintf('Plant good to %.0f Hz', fTrust);
        set(hPredInfo, 'String', lines);
    end

end
