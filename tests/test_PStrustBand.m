% test_PStrustBand.m - tests for the coherence-gated top of the usable band

%!test
%! % Coherence never drops: the whole grid is usable
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! assert(PStrustBand(freq, C), 500);

%!test
%! % A sustained drop cuts the band just before it starts
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! C(freq >= 120) = 0.4;
%! f = PStrustBand(freq, C);
%! assert(f >= 119 && f < 120, 'band must end just below the drop');

%!test
%! % One noisy bin is not the end of the band - that is why a run is required
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! C(freq == 200) = 0.1;
%! assert(PStrustBand(freq, C), 500);
%! % but five in a row are
%! C(freq >= 200 & freq <= 202) = 0.1;
%! assert(PStrustBand(freq, C) < 200);

%!test
%! % Low frequency is exempt: a 2.5 s Welch segment holds too few cycles there
%! % for coherence to mean anything, and the chirp starts at 0.2 Hz
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! C(freq <= 2) = 0.1;
%! assert(PStrustBand(freq, C), 500);

%!test
%! % Threshold and run length are settable, and both actually bind
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! C(freq >= 100) = 0.7;
%! assert(PStrustBand(freq, C, 0.8), 99.5);
%! assert(PStrustBand(freq, C, 0.6), 500);
%! C2 = 0.95 * ones(size(freq));
%! C2(freq >= 100 & freq <= 101) = 0.1;    % 3 bins
%! assert(PStrustBand(freq, C2, 0.8, 5), 500);
%! assert(PStrustBand(freq, C2, 0.8, 3) < 100);

%!test
%! % A grid shorter than the run length cannot show a sustained drop
%! freq = (0:0.5:1)';
%! C = [0.1; 0.1; 0.1];
%! assert(PStrustBand(freq, C), 1);

%!test
%! % Row or column, same answer - callers pass both
%! freq = (0:0.5:500)';
%! C = 0.95 * ones(size(freq));
%! C(freq >= 120) = 0.4;
%! assert(PStrustBand(freq(:)', C(:)'), PStrustBand(freq, C));
