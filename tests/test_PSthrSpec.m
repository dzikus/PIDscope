% test_PSthrSpec.m - Tests for throttle x frequency spectrogram
% NOTE: PSthrSpec expects X,Y as column vectors, F in kHz

%!test
%! % Smoke test: function runs on synthetic data
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! duration = 5;
%! N = Fs * duration;
%! throttle = ones(N, 1) * 50;
%! signal = sin(2 * pi * 150 * (0:N-1)' / Fs);
%! [freq, ampMat] = PSthrSpec(throttle, signal, Fs_khz, 0);
%! assert(~isempty(ampMat));
%! assert(~isempty(freq));

%!test
%! % Output matrix is 100 rows (throttle bins)
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! throttle = ones(N, 1) * 50;
%! signal = randn(N, 1);
%! [~, ampMat] = PSthrSpec(throttle, signal, Fs_khz, 0);
%! assert(size(ampMat, 1), 100);

%!test
%! % Energy concentrated at correct throttle bin
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 10;
%! throttle = ones(N, 1) * 50;
%! signal = sin(2 * pi * 100 * (0:N-1)' / Fs);
%! [~, ampMat] = PSthrSpec(throttle, signal, Fs_khz, 0);
%! energy_at_50 = sum(ampMat(50, :));
%! energy_at_10 = sum(ampMat(10, :));
%! assert(energy_at_50 > energy_at_10);
