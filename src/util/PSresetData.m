%% PSresetData - clear all loaded data and reset UI state
% Called from Reset button and firmware-change dialog

clear T dataA tta A_lograte epoch1_A epoch2_A SetupInfo;
clear rollPIDF pitchPIDF yawPIDF filenameA fnameMaster loaded_firmware;
clear debugmode debugIdx fwType fwMajor fwMinor gyro_debug_axis;
clear notchData rpmFilterData ampmat freq2d2 amp2d2 specMat;
clear delayDataReady FilterDelayDterm SPGyroDelay Debug01 Debug02;
clear gyro_phase_shift_deg dterm_phase_shift_deg;
clear tuneCrtlpanel_init setupInfoWidgets_init;

fcnt = 0; filenameA = {}; fnameMaster = {}; Nfiles = 0; expandON = 0;

try, delete(checkpanel); clear checkpanel; catch, end
try
    delete(subplot('position', posInfo.linepos1));
    delete(subplot('position', posInfo.linepos2));
    delete(subplot('position', posInfo.linepos3));
    delete(subplot('position', posInfo.linepos4));
catch, end

% close all secondary figures
figs = findobj('Type', 'figure');
for fi = 1:numel(figs)
    if figs(fi) ~= PSfig
        try, close(figs(fi)); catch, end
    end
end

% clear secondary figure and panel handles
clear PSspecfig PSspecfig2 PSspecfig3 PStunefig PSerrfig PSstatsfig PSdisp;
clear errCrtlpanel statsCrtlpanel spec2Crtlpanel specCrtlpanel;
clear freqTimeCrtlpanel tuneCrtlpanel;

% reset UI
set(guiHandles.FileNum, 'String', ' ');
try
    set(guiHandles.Epoch1_A_Input, 'String', ' ');
    set(guiHandles.Epoch2_A_Input, 'String', ' ');
catch, end
