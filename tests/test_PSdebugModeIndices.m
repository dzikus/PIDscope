% test_PSdebugModeIndices.m - tests for PSdebugModeIndices

%!test
%! % BF 4.5 (old indices)
%! idx = PSdebugModeIndices('Betaflight', 4, 5);
%! assert(idx.GYRO_SCALED, 6);
%! assert(idx.GYRO_FILTERED, 3);
%! assert(idx.RC_INTERPOLATION, 7);
%! assert(idx.FFT_FREQ, 17);
%! assert(idx.FEEDFORWARD, 59);

%!test
%! % BF 2025.12 (new indices, GYRO_SCALED removed)
%! idx = PSdebugModeIndices('Betaflight', 2025, 12);
%! assert(idx.GYRO_SCALED, -1);
%! assert(idx.GYRO_FILTERED, 3);
%! assert(idx.RC_INTERPOLATION, 6);
%! assert(idx.FFT_FREQ, 16);
%! assert(idx.FEEDFORWARD, 58);

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
