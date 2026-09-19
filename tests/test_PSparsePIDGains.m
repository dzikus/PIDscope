% test_PSparsePIDGains.m - tests for reading PID gains out of a log header

%!shared si
%! si = {'Firmware revision', 'Betaflight 2025.12.0'; ...
%!       'rollPID', '46,66,32'; ...
%!       'pitchPID', '71,105,49'; ...
%!       'yawPID', '30,65,3'; ...
%!       'ff_weight', '85,90,100'; ...
%!       'd_max', '0,0,0'; ...
%!       'looptime', '125'; ...
%!       'pid_process_denom', '2'};

%!test
%! % Roll, pitch and yaw come back in firmware units, in that order
%! g = PSparsePIDGains(si, 0);
%! assert([g.P g.I g.D g.F], [46 66 32 85]);
%! g = PSparsePIDGains(si, 1);
%! assert([g.P g.I g.D g.F], [71 105 49 90]);
%! g = PSparsePIDGains(si, 2);
%! assert([g.P g.I g.D g.F], [30 65 3 100]);

%!test
%! % BF 4.x spells feedforward weight differently
%! si2 = {'rollPID', '45,60,30'; 'feedforward_weight', '120,120,120'};
%! g = PSparsePIDGains(si2, 0);
%! assert([g.P g.I g.D g.F], [45 60 30 120]);

%!test
%! % A missing key gives zero rather than an error
%! g = PSparsePIDGains({'looptime', '125'}, 0);
%! assert([g.P g.I g.D g.F], [0 0 0 0]);
%! g = PSparsePIDGains({'rollPID', '40,50,25'}, 0);
%! assert([g.P g.I g.D g.F], [40 50 25 0]);

%!test
%! % d_max above the D gain means dynamic D, which the controller model ignores
%! si3 = {'rollPID', '46,66,32'; 'd_max', '40,45,0'};
%! g = PSparsePIDGains(si3, 0);
%! assert(g.dMax, 40);
%! g = PSparsePIDGains(si, 0);
%! assert(g.dMax, 0);

%!test
%! % PID loop rate is the gyro rate divided by pid_process_denom
%! fp = PSparseFilterParams(si);
%! assert(fp.gyro_rate_hz, 8000);
%! assert(fp.pid_rate_hz, 4000);

%!test
%! % Without pid_process_denom the PID loop runs at the gyro rate
%! fp = PSparseFilterParams({'looptime', '125'});
%! assert(fp.pid_rate_hz, 8000);
%! fp = PSparseFilterParams({'gyro_lpf1_type', '0'});
%! assert(fp.pid_rate_hz, 0);
