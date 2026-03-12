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
th.btnDash1    = [.85 .25 .25];   % Spectral Analyzer
th.btnDash2    = [.25 .50 .90];   % Step Response
th.btnDash3    = [.85 .55 .15];   % Filter Sim
th.btnDash4    = [.20 .70 .30];   % Motor Noise
th.btnDash5    = [.20 .80 .80];   % Chirp Analysis
th.btnLink     = [.85 .55 .15];   % Support PIDscope

% font size - single source of truth
screensz = get(0, 'ScreenSize');
th.fontsz = round(screensz(4) * .011);
% Octave Qt renders fonts bigger than MATLAB
if exist('OCTAVE_VERSION', 'builtin')
    th.fontsz = round(th.fontsz * 0.85);
end

% diff highlight (Setup Info)
th.diffBg      = [.45 .18 .18];

% checkbox / input bg
th.checkBg     = [.18 .18 .20];
th.inputBg     = [.14 .14 .16];
th.inputFg     = [.90 .90 .90];

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
th.sigThrottle  = [.85 .85 .85];

end
