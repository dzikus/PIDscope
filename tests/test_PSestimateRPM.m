% test_PSestimateRPM.m - tests for PSestimateRPM

%!test
%! % Synthetic motor noise at 200 Hz fundamental
%! freqAxis = 1:500;
%! ampMatrix = zeros(100, 500);
%! for t = 30:80
%!   f0 = 150 + t;  % fundamental scales with throttle
%!   ampMatrix(t, round(f0)) = 10;       % fundamental
%!   ampMatrix(t, round(f0*2)) = 5;      % 2nd harmonic
%! end
%! [fund, harm] = PSestimateRPM(freqAxis, ampMatrix, 3);
%! % check mid-throttle detection
%! assert(~isnan(fund(50)));
%! assert(abs(fund(50) - 200) < 20);  % should be near 200 Hz at throttle=50

%!test
%! % Empty matrix returns NaN
%! freqAxis = 1:100;
%! ampMatrix = zeros(100, 100);
%! [fund, harm] = PSestimateRPM(freqAxis, ampMatrix, 2);
%! assert(all(isnan(fund)));
%! assert(size(harm, 2), 2);

%!test
%! % Harmonics are multiples of fundamental
%! freqAxis = 1:500;
%! ampMatrix = zeros(100, 500);
%! ampMatrix(50, 180) = 10;
%! ampMatrix(50, 360) = 5;
%! [fund, harm] = PSestimateRPM(freqAxis, ampMatrix, 3);
%! assert(~isnan(fund(50)));
%! assert(size(harm), [100 3]);
%! % 2nd harmonic should be ~2x fundamental
%! assert(abs(harm(50,2) / harm(50,1) - 2) < 0.1);
