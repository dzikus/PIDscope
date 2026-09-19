% test_PSapplyHighRes.m - tests for undoing blackbox high resolution scaling

%!shared T0, si_on, si_off
%! T0 = struct();
%! T0.gyroADC_0_ = [10; 20; 30];
%! T0.gyroADC_1_ = [-40; 50; 60];
%! T0.gyroUnfilt_0_ = [70; 80; 90];
%! T0.rcCommand_0_ = [100; 200; 300];
%! T0.rcCommand_3_ = [10000; 15000; 20000];
%! T0.setpoint_0_ = [1000; 2000; 3000];
%! T0.setpoint_2_ = [11; 22; 33];
%! T0.setpoint_3_ = [1500; 1600; 1700];
%! T0.axisP_0_ = [5; 6; 7];
%! T0.debug_0_ = [31415; 0; 100];
%! si_on  = {'Firmware revision', 'Betaflight 2025.12.0'; 'blackbox_high_resolution', '1'};
%! si_off = {'Firmware revision', 'Betaflight 2025.12.0'; 'blackbox_high_resolution', '0'};

%!test
%! % Flag on: the four scaled field groups come back to real units
%! T = PSapplyHighRes(T0, si_on);
%! assert(T.gyroADC_0_, [1; 2; 3], 1e-12);
%! assert(T.gyroADC_1_, [-4; 5; 6], 1e-12);
%! assert(T.gyroUnfilt_0_, [7; 8; 9], 1e-12);
%! assert(T.rcCommand_0_, [10; 20; 30], 1e-12);
%! assert(T.rcCommand_3_, [1000; 1500; 2000], 1e-12);
%! assert(T.setpoint_0_, [100; 200; 300], 1e-12);
%! assert(T.setpoint_2_, [1.1; 2.2; 3.3], 1e-12);

%!test
%! % setpoint[3] is the mixer throttle, written past the scaled loop in blackbox.c
%! T = PSapplyHighRes(T0, si_on);
%! assert(T.setpoint_3_, [1500; 1600; 1700], 1e-12);

%!test
%! % PID terms and debug are logged unscaled and must stay untouched
%! T = PSapplyHighRes(T0, si_on);
%! assert(T.axisP_0_, [5; 6; 7], 1e-12);
%! assert(T.debug_0_, [31415; 0; 100], 1e-12);

%!test
%! % Flag off or absent leaves every field alone
%! T = PSapplyHighRes(T0, si_off);
%! assert(T.gyroADC_0_, [10; 20; 30], 1e-12);
%! assert(T.setpoint_0_, [1000; 2000; 3000], 1e-12);
%! T = PSapplyHighRes(T0, {'looptime', '125'});
%! assert(T.gyroADC_0_, [10; 20; 30], 1e-12);
%! T = PSapplyHighRes(T0, {});
%! assert(T.gyroADC_0_, [10; 20; 30], 1e-12);

%!test
%! % Missing fields are fine - not every firmware logs gyroUnfilt
%! Tmin = struct('gyroADC_0_', [10; 20], 'axisP_0_', [1; 2]);
%! T = PSapplyHighRes(Tmin, si_on);
%! assert(T.gyroADC_0_, [1; 2], 1e-12);
%! assert(T.axisP_0_, [1; 2], 1e-12);

%!test
%! % readtable hands back a struct carrying Properties; it must survive intact
%! Tp = T0;
%! Tp.Properties = struct('VariableNames', {{'gyroADC_0_', 'axisP_0_'}});
%! T = PSapplyHighRes(Tp, si_on);
%! assert(isfield(T, 'Properties'), 'Properties must be preserved');
%! assert(T.Properties.VariableNames{1}, 'gyroADC_0_');
