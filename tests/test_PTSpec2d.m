% test_PTSpec2d.m - Tests for FFT computation engine
% NOTE: PTSpec2d expects Y as ROW vector, F in kHz

%!test
%! % Pure 100Hz sine at 4kHz -> peak at 100Hz
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! t = (0 : 1/Fs : 0.3 - 1/Fs);  % row vector
%! y = sin(2 * pi * 100 * t);
%! [freq, spec] = PTSpec2d(y, Fs_khz, 0);
%! [~, peak_idx] = max(spec);
%! peak_freq = freq(peak_idx);
%! assert(abs(peak_freq - 100) < 10);

%!test
%! % Output has N/2+1 frequencies (DC to Nyquist)
%! Fs_khz = 4;
%! N = 1200;
%! y = randn(1, N);
%! [freq, spec] = PTSpec2d(y, Fs_khz, 0);
%! assert(length(freq), N/2 + 1);
%! assert(length(spec), N/2 + 1);

%!test
%! % PSD mode produces values in dB range
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! t = (0 : 1/Fs : 0.3 - 1/Fs);
%! y = sin(2 * pi * 200 * t);
%! [~, spec_psd] = PTSpec2d(y, Fs_khz, 1);
%! % PSD in dB should have negative values for most bins
%! assert(any(spec_psd < 0));

%!test
%! % Frequency vector spans 0 to Nyquist
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = 1200;
%! y = randn(1, N);
%! [freq, ~] = PTSpec2d(y, Fs_khz, 0);
%! assert(freq(1), 0, 1e-10);  % DC at 0
%! assert(abs(freq(end) - Fs/2) < Fs/N);  % last bin near Nyquist
