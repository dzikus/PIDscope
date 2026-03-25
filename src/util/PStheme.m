function th = PStheme()
%% PStheme - central UI theme for PIDscope (dark)

% figure & panel
th.figBg       = [.18 .18 .20];
th.panelBg     = [.22 .22 .24];
th.panelFg     = [.90 .90 .90];
th.panelBorder = [.35 .35 .38];

% axes
th.axesBg      = [.10 .10 .12];
th.axesFg      = [.75 .75 .75];
th.gridColor   = [.28 .28 .30];

% text
th.textPrimary   = [.90 .90 .90];
th.textSecondary = [.65 .65 .65];
th.textAccent    = [.40 .80 1.0];

% legend
th.legendBg    = [.16 .16 .18];
th.legendFg    = [.80 .80 .80];
th.legendEdge  = [.35 .35 .38];

% epoch shading (trim regions)
th.epochFill   = [.30 .30 .32];
th.epochAlpha  = 0.7;

% buttons
th.btnBg       = [.30 .30 .32];
th.btnRun      = [.15 .85 .25];
th.btnReset    = [.95 .55 .15];
th.btnSave     = [.70 .70 .70];
th.btnDash1    = [.95 .30 .30];   % Spectral Analyzer - vivid red
th.btnDash2    = [.30 .50 .95];   % Step Response - vivid blue
th.btnDash3    = [.20 .80 .90];   % PID Slider Tool - vivid cyan
th.btnDash4    = [.95 .60 .15];   % Filter Sim - vivid amber
th.btnDash5    = [.90 .75 .20];   % Test Signal - vivid gold
th.btnDash6    = [.90 .30 .60];   % PID Error - vivid magenta
th.btnDash7    = [.25 .75 .65];   % Flight Stats - vivid teal
th.btnMotNoise = [.20 .85 .30];   % Motor Noise - vivid green
th.btnChirp    = [.70 .40 .95];   % Chirp Analysis - vivid purple
th.btnLink     = [.95 .60 .15];   % Support PIDscope - amber
th.btnPlayer   = [.40 .75 1.0];   % Player button - bright sky blue

% overlay indicator colors (checkboxes in CP)
th.overlayDynNotch = [0 .8 .8];   % Dyn Notch - cyan
th.overlayRPM      = [.6 .9 .6];  % RPM est - light green

% font size - single source of truth
screensz = get(0, 'ScreenSize');
th.fontsz = round(screensz(4) * .011);
% Octave Qt renders fonts bigger than MATLAB
if exist('OCTAVE_VERSION', 'builtin')
    th.fontsz = round(th.fontsz * 0.85);
end

% period marker (Step Response)
th.periodMarker  = [.95 .20 .20];

% diff highlight (Setup Info)
th.diffBg      = [.45 .18 .18];

% checkbox / input bg
th.checkBg     = [.18 .18 .20];
th.inputBg     = [.14 .14 .16];
th.inputFg     = [.90 .90 .90];

% datatip tooltip
th.datatipBg   = [1.0 1.0 .88];    % pale yellow

% RPY axis colors (FPV standard: Roll=red, Pitch=green, Yaw=blue)
th.axisRoll      = [.95 .35 .15];   % red-orange
th.axisRollFilt  = [1.0 .45 .45];   % light red (distinct from M2 orange)
th.axisPitch     = [.20 .85 .25];   % green
th.axisPitchFilt = [.55 1.0 .55];   % lighter lime
th.axisYaw       = [.30 .45 .95];   % blue
th.axisYawFilt   = [.60 .75 1.0];   % lighter sky blue

% filter section headers
th.secNotch      = [1.0 .70 .30];   % amber/orange
th.secDtermLPF   = [.40 1.0 .40];   % green
th.secDtermNotch = [1.0 .50 .50];   % salmon
th.refLine3dB    = [.60 .60 .20];   % -3dB / 0.707 reference

% Bode / chirp analysis
th.bodeMain      = [0 .80 1.0];     % tracking TF - bright cyan
th.bodeSecondary = [1.0 .50 0];     % plant TF - orange
th.bodeCoherence = [.30 .90 .30];   % coherence - green
th.bodeRef       = [.50 .50 .50];   % reference lines (0dB, -180, unity)

% transport buttons (Player)
th.btnPlay       = [0 .60 0];       % play - dark green
th.btnPause      = [.80 .20 0];     % pause - dark red-orange
th.btnStop       = [.70 0 0];       % stop - crimson

% signal colors (bright for dark bg)
th.sigDebug     = [.50 .50 .50];
th.sigGyro      = [.85 .85 .85];
th.sigPterm     = [.20 .85 .20];
th.sigIterm     = [.90 .75 .20];
th.sigDprefilt  = [.45 .80 .95];
th.sigDterm     = [.30 .40 .95];
th.sigFterm     = [.75 .45 .45];
th.sigSetpoint  = [.90 .25 .35];
th.sigPIDsum    = [1.0 .35 .90];
th.sigPIDerr    = [.55 .20 .95];
th.sigMotor     = {[.95 .20 .20], [.95 .65 .10], [.20 .85 .25], [.20 .45 .95]};
th.sigRPM       = {[1.0 .50 .50], [1.0 .80 .40], [.50 1.0 .55], [.50 .65 1.0]};
th.sigThrottle  = [.85 .85 .85];
th.sigTestSignal = [1.0 1.0 1.0];  % white (matches Log Viewer overlay)

end
