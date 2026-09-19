% test_PSfindChirpWindow.m - tests for chirp window detection

%!test
%! % Finds active window in synthetic sinarg
%! N = 10000;
%! sinarg_raw = zeros(N, 1);
%! sinarg_raw(2000:8000) = linspace(0.1, 30000, 6001)';
%! gyro = randn(N, 1) * 50;
%! [i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
%! assert(i0 >= 1900 && i0 <= 2100, 'start should be near 2000');
%! assert(i1 >= 7900 && i1 <= 8100, 'end should be near 8000');

%!test
%! % Returns full range when sinarg is all zero
%! N = 1000;
%! sinarg_raw = zeros(N, 1);
%! gyro = randn(N, 1);
%! [i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
%! assert(i0, 1);
%! assert(i1, N);

%!test
%! % The firmware logs sinarg as a phase wrapping through [0, 2*pi], so a run
%! % sweeping to 600 Hz wraps hundreds of times per second. The whole run is one
%! % window, not one window per wrap.
%! Fs = 2000; Tc = 20; N = 60*Fs;
%! sinarg_raw = zeros(N, 1); gyro = 2*randn(N, 1);
%! a = 10*Fs; b = a + Tc*Fs - 1;
%! tt = (0:Tc*Fs-1)'/Fs;
%! ph = 2*pi*(0.2*tt + (600-0.2)/(2*Tc)*tt.^2);
%! sinarg_raw(a:b) = round(mod(ph, 2*pi) * 5000);
%! gyro(a:b) = 200*sin(ph);
%! [i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
%! assert(i1-i0+1 > 0.98*Tc*Fs, 'must return the whole sweep, not one phase cycle');
%! assert(abs(i0-a) < 0.01*Fs && abs(i1-b) < 0.01*Fs, 'window must line up with the run');

%!test
%! % A log holds one run per axis; pick the run that moved this axis
%! Fs = 2000; Tc = 10; N = 50*Fs;
%! sinarg_raw = zeros(N, 1); gyro = 2*randn(N, 1);
%! tt = (0:Tc*Fs-1)'/Fs;
%! ph = 2*pi*(0.2*tt + (400-0.2)/(2*Tc)*tt.^2);
%! for k = 0:2
%!   a = (5 + k*14)*Fs; b = a + Tc*Fs - 1;
%!   sinarg_raw(a:b) = round(mod(ph, 2*pi) * 5000);
%!   if k == 1, gyro(a:b) = 200*sin(ph); end
%! end
%! [i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
%! assert(abs(i0 - 19*Fs) < 0.01*Fs, 'must pick the run where the axis responded');

%!test
%! % Every run in a log is the same length by construction, so run length is
%! % noise and cannot decide which axis a run swept. Block sizes and variances
%! % here are the ones measured on 20250907_flipmini_00, where roll answers in
%! % blocks 1 and 4 while the other four still carry 1e3 of cross-axis coupling -
%! % well clear of the 500 floor, and the longest block of the six is #6.
%! nSamp = [39987 39988 39942 39950 39986 39996];
%! gvar  = [561000 853 211 562000 1365 225];
%! randn('state', 31);
%! sinarg = []; gyro = [];
%! for k = 1:6
%!   sinarg = [sinarg; 15000*ones(nSamp(k),1); zeros(2000,1)];
%!   gyro = [gyro; sqrt(gvar(k))*randn(nSamp(k),1); zeros(2000,1)];
%! end
%! [i0, i1] = PSfindChirpWindow(sinarg, gyro);
%! starts = 1 + cumsum([0 nSamp(1:5) + 2000]);
%! picked = find(starts == i0);
%! assert(any(picked == [1 4]), 'must pick a run that actually moved this axis');

%!test
%! % Two longer runs carrying only cross-axis coupling clear the variance floor
%! % but must not outrank the run that was swept
%! randn('state', 20);
%! sinarg = [ones(3000,1); zeros(2000,1); ones(9000,1); zeros(2000,1); ones(5000,1)];
%! gyro = [700*randn(3000,1); zeros(2000,1); 30*randn(9000,1); ...
%!         zeros(2000,1); 30*randn(5000,1)];
%! [i0, i1] = PSfindChirpWindow(sinarg, gyro);
%! assert(isequal([i0 i1], [1 3000]), 'the swept run wins over the longer ones');

%!test
%! % A sample landing exactly on the wrap logs a zero; it must not split the run
%! Fs = 2000; Tc = 10; N = 30*Fs;
%! sinarg_raw = zeros(N, 1); gyro = 2*randn(N, 1);
%! a = 5*Fs; b = a + Tc*Fs - 1;
%! sinarg_raw(a:b) = 15000;
%! gyro(a:b) = 200*randn(Tc*Fs, 1);
%! sinarg_raw(a + 3*Fs) = 0;
%! [i0, i1] = PSfindChirpWindow(sinarg_raw, gyro);
%! assert(i1-i0+1 > 0.98*Tc*Fs, 'one stray zero must not halve the window');
