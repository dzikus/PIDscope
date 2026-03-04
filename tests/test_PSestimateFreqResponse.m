% test_PSestimateFreqResponse.m - tests for frequency response estimation

%!test
%! % Known system: unity gain (input = output) → G ≈ 1
%! Fs = 1000; N = 10000;
%! x = randn(N, 1);
%! [G, C, freq] = PSestimateFreqResponse(x, x, Fs);
%! % coherence should be 1, magnitude ~0 dB
%! mid = freq > 10 & freq < 400;
%! assert(mean(C(mid)) > 0.99, 'coherence should be ~1 for identical signals');
%! assert(all(abs(20*log10(abs(G(mid)))) < 1), 'gain should be ~0 dB');

%!test
%! % Known system: 2x gain → G ≈ 2 (6 dB)
%! Fs = 1000; N = 10000;
%! x = randn(N, 1);
%! y = 2 * x;
%! [G, C, freq] = PSestimateFreqResponse(x, y, Fs);
%! mid = freq > 10 & freq < 400;
%! mag_dB = 20*log10(abs(G(mid)));
%! assert(all(abs(mag_dB - 6.02) < 0.5), 'gain should be ~6 dB for 2x');

%!test
%! % Frequency vector length matches Nhalf
%! Fs = 4000; N = 20000;
%! x = randn(N, 1);
%! Nest = round(2.5 * Fs);
%! [G, C, freq] = PSestimateFreqResponse(x, x, Fs, Nest);
%! Nhalf = floor(Nest/2) + 1;
%! assert(length(freq), Nhalf);
%! assert(length(G), Nhalf);
%! assert(length(C), Nhalf);

%!test
%! % PSstepFromFRD returns reasonable step for unity system
%! Fs = 1000; N = 10000;
%! x = randn(N, 1);
%! [G, ~, freq] = PSestimateFreqResponse(x, x, Fs);
%! [t_ms, step] = PSstepFromFRD(freq, G, 300);
%! assert(length(t_ms) > 10, 'should have step data');
%! % step should settle near 1
%! assert(abs(step(end) - 1) < 0.3, 'step should settle near 1 for unity system');
