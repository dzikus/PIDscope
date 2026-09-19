% test_PSdebugModeIndices.m - tests for PSdebugModeIndices
%
% Values read out of debugType_e in src/main/build/debug.h at the firmware tags
% 4.0.6, 4.1.1, 4.2.11, 4.3.2, 4.5.5, 2025.12.5 and 2026.6.2:
%
%   mode                  4.0   4.1-4.2   4.3-4.5   2025.12   2026.6
%   GYRO_FILTERED           3       3         3         3        3
%   GYRO_SCALED             6       6         6         -        -
%   RC_INTERPOLATION        7       7         7         6        6
%   FFT_FREQ               17      17        17        16       16
%   DSHOT_RPM_TELEMETRY    47      45        45        45       45
%   RPM_FILTER             48      46        46        46       46
%   FEEDFORWARD             -       -        59        59       59
%   CHIRP                   -       -         -        97       96
%
% Dropping GYRO_SCALED in 2025.12 did not shift RPM_FILTER, FEEDFORWARD or
% DSHOT_RPM_TELEMETRY - entries were added ahead of them in the same release.

%!test
%! % BF 4.0: the RPM pair sits two higher than it does from 4.1 on
%! idx = PSdebugModeIndices('Betaflight', 4, 0);
%! assert(idx.GYRO_SCALED, 6);
%! assert(idx.GYRO_FILTERED, 3);
%! assert(idx.RC_INTERPOLATION, 7);
%! assert(idx.FFT_FREQ, 17);
%! assert(idx.DSHOT_RPM_TELEMETRY, 47);
%! assert(idx.RPM_FILTER, 48);
%! assert(idx.FEEDFORWARD, -1);
%! assert(idx.CHIRP, -1);

%!test
%! % BF 4.2: still no feedforward debug
%! idx = PSdebugModeIndices('Betaflight', 4, 2);
%! assert(idx.DSHOT_RPM_TELEMETRY, 45);
%! assert(idx.RPM_FILTER, 46);
%! assert(idx.FEEDFORWARD, -1);

%!test
%! % BF 4.5
%! idx = PSdebugModeIndices('Betaflight', 4, 5);
%! assert(idx.GYRO_SCALED, 6);
%! assert(idx.GYRO_FILTERED, 3);
%! assert(idx.RC_INTERPOLATION, 7);
%! assert(idx.FFT_FREQ, 17);
%! assert(idx.DSHOT_RPM_TELEMETRY, 45);
%! assert(idx.RPM_FILTER, 46);
%! assert(idx.FEEDFORWARD, 59);
%! assert(idx.CHIRP, -1);

%!test
%! % BF 2025.12: GYRO_SCALED gone, chirp arrives at 97
%! idx = PSdebugModeIndices('Betaflight', 2025, 12);
%! assert(idx.GYRO_SCALED, -1);
%! assert(idx.GYRO_FILTERED, 3);
%! assert(idx.RC_INTERPOLATION, 6);
%! assert(idx.FFT_FREQ, 16);
%! assert(idx.DSHOT_RPM_TELEMETRY, 45);
%! assert(idx.RPM_FILTER, 46);
%! assert(idx.FEEDFORWARD, 59);
%! assert(idx.CHIRP, 97);

%!test
%! % BF 2026.6: one entry ahead of chirp went away, so it moved down to 96
%! idx = PSdebugModeIndices('Betaflight', 2026, 6);
%! assert(idx.CHIRP, 96);
%! assert(idx.GYRO_SCALED, -1);
%! assert(idx.RC_INTERPOLATION, 6);
%! assert(idx.FFT_FREQ, 16);
%! assert(idx.DSHOT_RPM_TELEMETRY, 45);
%! assert(idx.RPM_FILTER, 46);
%! assert(idx.FEEDFORWARD, 59);

%!test
%! % INAV (uses default old indices)
%! idx = PSdebugModeIndices('INAV', 7, 1);
%! assert(idx.GYRO_SCALED, 6);
%! assert(idx.RC_INTERPOLATION, 7);
%! assert(idx.FFT_FREQ, 17);

%!test
%! % Emuflight (uses default old indices)
%! idx = PSdebugModeIndices('Emuflight', 0, 4);
%! assert(idx.GYRO_SCALED, 6);
%! assert(idx.FFT_FREQ, 17);
