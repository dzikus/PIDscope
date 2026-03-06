function idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)
%% PSdebugModeIndices - return debug mode index constants for a given firmware version
%  idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)

% Default: BF 4.x / Emuflight / INAV / FETTEC / QuickSilver / Rotorflight / KISS
idx.GYRO_SCALED = 6;
idx.GYRO_FILTERED = 3;
idx.RC_INTERPOLATION = 7;
idx.FFT_FREQ = 17;
idx.RPM_FILTER = 46;
idx.FEEDFORWARD = 59;
idx.DSHOT_RPM_TELEMETRY = 37;
idx.CHIRP = -1;  % not available in BF 4.x

% BF 2025.12+ (aka "4.6"): GYRO_SCALED removed at index 6, all indices >= 6 shift by -1
if strcmp(fwType, 'Betaflight') && fwMajor >= 2025
    idx.GYRO_SCALED = -1;
    idx.RC_INTERPOLATION = 6;
    idx.FFT_FREQ = 16;
    idx.RPM_FILTER = 45;
    idx.FEEDFORWARD = 58;
    idx.DSHOT_RPM_TELEMETRY = 36;
    idx.CHIRP = 119;
end

end
