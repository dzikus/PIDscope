function idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)
%% PSdebugModeIndices - return debug mode index constants for a given firmware version
%  idx = PSdebugModeIndices(fwType, fwMajor, fwMinor)
%
%  Positions in debugType_e (src/main/build/debug.h), read at the firmware tags:
%
%    mode                  4.0   4.1-4.2   4.3-4.5   2025.12   2026.6
%    GYRO_FILTERED           3       3         3         3        3
%    GYRO_SCALED             6       6         6         -        -
%    RC_INTERPOLATION        7       7         7         6        6
%    FFT_FREQ               17      17        17        16       16
%    DSHOT_RPM_TELEMETRY    47      45        45        45       45
%    RPM_FILTER             48      46        46        46       46
%    FEEDFORWARD             -       -        59        59       59
%    CHIRP                   -       -         -        97       96
%
%  Dropping GYRO_SCALED in 2025.12 shifted RC_INTERPOLATION and FFT_FREQ down
%  by one but left the RPM and feedforward entries where they were - modes were
%  added ahead of them in the same release.

% Default: BF 4.3-4.5 / Emuflight / INAV / FETTEC / QuickSilver / Rotorflight / KISS
idx.GYRO_SCALED = 6;
idx.GYRO_FILTERED = 3;
idx.RC_INTERPOLATION = 7;
idx.FFT_FREQ = 17;
idx.DSHOT_RPM_TELEMETRY = 45;
idx.RPM_FILTER = 46;
idx.FEEDFORWARD = 59;
idx.CHIRP = -1;

isBF = strcmp(fwType, 'Betaflight');

if isBF && fwMajor == 4 && fwMinor < 3
    idx.FEEDFORWARD = -1;          % arrived in 4.3
    if fwMinor < 1
        idx.DSHOT_RPM_TELEMETRY = 47;
        idx.RPM_FILTER = 48;
    end
end

if isBF && fwMajor >= 2025
    idx.GYRO_SCALED = -1;
    idx.RC_INTERPOLATION = 6;
    idx.FFT_FREQ = 16;
    if fwMajor >= 2026
        idx.CHIRP = 96;
    else
        idx.CHIRP = 97;
    end
end

end
