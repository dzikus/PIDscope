% test_PSnotchQ.m - tests for the BF notch quality factor

%!test
%! % filterGetNotchQ in BF common/filter.c:
%! %   centerFreq * cutoffFreq / (centerFreq^2 - cutoffFreq^2)
%! assert(PSnotchQ(500, 350), 1.3725490196, 1e-9);
%! assert(PSnotchQ(300, 200), 1.2, 1e-9);
%! assert(PSnotchQ(200, 100), 0.6666666667, 1e-9);
%! assert(PSnotchQ(150, 120), 2.2222222222, 1e-9);

%!test
%! % What the formula is for: cutoff is the lower -3 dB corner of the notch,
%! % so the response there must be down 3 dB and not somewhere else.
%! Fs = 8000;
%! for c = [300 500 700]
%!   for cut = [0.5 0.7 0.85] * c
%!     [b, a] = PSbfFilters('notch', c, Fs, PSnotchQ(c, cut));
%!     H = freqz(b, a, [cut c], Fs);
%!     assert(20*log10(abs(H(1))), -3.01, 0.3);
%!     assert(abs(H(2)) < 0.01, 'the notch must still be deep at its centre');
%!   end
%! end

%!test
%! % A cutoff closer to the centre means a narrower, higher Q notch
%! q = arrayfun(@(cut) PSnotchQ(500, cut), [100 200 300 400 450]);
%! assert(all(diff(q) > 0), 'Q must rise as the cutoff approaches the centre');

%!test
%! % Unusable settings disable the notch rather than returning a negative Q
%! assert(PSnotchQ(500, 0), 0);
%! assert(PSnotchQ(0, 350), 0);
%! assert(PSnotchQ(350, 350), 0);
%! assert(PSnotchQ(350, 500), 0);
%! assert(PSnotchQ(-1, 350), 0);
