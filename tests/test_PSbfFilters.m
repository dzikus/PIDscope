% test_PSbfFilters.m - tests for BF-compatible filter implementations

%!test
%! % PT1 lowpass attenuates above cutoff
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! t = (0:4000-1)'/Fs;
%! sig_lo = sin(2*pi*50*t);   % 50 Hz — should pass
%! sig_hi = sin(2*pi*800*t);  % 800 Hz — should be attenuated
%! out_lo = filter(b, a, sig_lo);
%! out_hi = filter(b, a, sig_hi);
%! rms_lo = sqrt(mean(out_lo(2000:end).^2));
%! rms_hi = sqrt(mean(out_hi(2000:end).^2));
%! assert(rms_lo > 0.5);   % passes through
%! assert(rms_hi < 0.2);   % attenuated

%!test
%! % PT2 steeper rolloff than PT1
%! Fs = 4000; fc = 200;
%! [b1, a1] = PSbfFilters('pt1', fc, Fs);
%! [b2, a2] = PSbfFilters('pt2', fc, Fs);
%! t = (0:4000-1)'/Fs;
%! sig = sin(2*pi*400*t);
%! out1 = filter(b1, a1, sig);
%! out2 = filter(b2, a2, sig);
%! rms1 = sqrt(mean(out1(2000:end).^2));
%! rms2 = sqrt(mean(out2(2000:end).^2));
%! assert(rms2 < rms1);  % PT2 attenuates more at 2x cutoff

%!test
%! % Notch filter removes target frequency
%! Fs = 4000; fc = 300; Q = 5;
%! [b, a] = PSbfFilters('notch', fc, Fs, Q);
%! t = (0:8000-1)'/Fs;
%! sig = sin(2*pi*300*t) + sin(2*pi*100*t);
%! out = filter(b, a, sig);
%! % 300 Hz should be removed, 100 Hz should remain
%! N = length(out); f = (0:N/2)*Fs/N;
%! Y = abs(fft(out .* hann(N)));
%! Y = Y(1:N/2+1);
%! [~, i100] = min(abs(f - 100));
%! [~, i300] = min(abs(f - 300));
%! assert(Y(i100) > Y(i300) * 5);  % 100 Hz much stronger than 300 Hz

%!test
%! % Edge case: fc=0 returns passthrough
%! [b, a] = PSbfFilters('pt1', 0, 4000);
%! assert(b, 1);
%! assert(a, 1);

%!test
%! % Biquad is second-order lowpass
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('biquad', fc, Fs);
%! assert(length(b), 3);
%! assert(length(a), 3);
%! % DC gain should be ~1
%! dc_gain = sum(b) / sum(a);
%! assert(abs(dc_gain - 1) < 0.01);
