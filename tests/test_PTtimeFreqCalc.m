% test_PTtimeFreqCalc.m - Tests for time x frequency computation
% NOTE: PTtimeFreqCalc expects Y as column vector, F in kHz

%!test
%! % Smoke test: function runs on synthetic data
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! signal = sin(2 * pi * 200 * (0:N-1)' / Fs);
%! [Tm, freq, specMat] = PTtimeFreqCalc(signal, Fs_khz, 1, 1);
%! assert(~isempty(specMat));
%! assert(~isempty(Tm));
%! assert(~isempty(freq));

%!test
%! % Time vector spans signal duration
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! duration = 5;
%! N = Fs * duration;
%! signal = randn(N, 1);
%! [Tm, ~, ~] = PTtimeFreqCalc(signal, Fs_khz, 1, 1);
%! assert(Tm(1) >= 0);
%! assert(Tm(end) <= duration + 1);

%!test
%! % Frequency vector reaches toward Nyquist
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! signal = randn(N, 1);
%! [~, freq, ~] = PTtimeFreqCalc(signal, Fs_khz, 1, 1);
%! assert(max(freq) <= Fs/2 + 100);
%! assert(max(freq) > 100);

%!test
%! % specMat is 2D with reasonable dimensions
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! signal = randn(N, 1);
%! [~, ~, specMat] = PTtimeFreqCalc(signal, Fs_khz, 1, 1);
%! assert(ndims(specMat), 2);
%! assert(size(specMat, 1) > 0);
%! assert(size(specMat, 2) > 0);
