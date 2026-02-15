function idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)
%% PSdebugModeIndices - return debug mode index constants for a given firmware version
%  idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)
%  Returns struct with fields: GYRO_SCALED, GYRO_FILTERED, RC_INTERPOLATION, FFT_FREQ, FEEDFORWARD

% Default: BF 4.x / Emuflight / INAV / FETTEC / QuickSilver / Rotorflight
idx.GYRO_SCALED = 6;
idx.GYRO_FILTERED = 3;
idx.RC_INTERPOLATION = 7;
idx.FFT_FREQ = 17;
idx.FEEDFORWARD = 59;

% BF 2025.12+ (aka "4.6"): GYRO_SCALED removed at index 6, all indices >= 6 shift by -1
if strcmp(fwType, 'Betaflight') && fwMajor >= 2025
    idx.GYRO_SCALED = -1;       % removed, use GYRO_FILTERED instead
    idx.RC_INTERPOLATION = 6;   % was 7
    idx.FFT_FREQ = 16;          % was 17
    idx.FEEDFORWARD = 58;       % was 59
end

end
