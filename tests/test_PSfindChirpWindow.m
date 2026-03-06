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
