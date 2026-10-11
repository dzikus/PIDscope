% test_PSestimateMultiWindow.m - pooling several chirp windows into one estimate

%!test
%! % The segment count is reported, and it follows the documented geometry
%! Fs = 1000; N = 20000;
%! randn('state', 1);
%! x = randn(N, 1);
%! [~, ~, ~, nSeg] = PSestimateFreqResponse(x, x, Fs);
%! Nest = round(2.5*Fs); Nstep = Nest - round(0.9*Nest);
%! assert(nSeg, floor((N - Nest)/Nstep) + 1);

%!test
%! % One window in a cell is the same as passing it bare
%! Fs = 1000; N = 20000;
%! randn('state', 2);
%! x = randn(N, 1); y = filter(1, [1 -0.8], x);
%! [G1, C1, f1, n1] = PSestimateFreqResponse(x, y, Fs);
%! [G2, C2, f2, n2] = PSestimateFreqResponse({x}, {y}, Fs);
%! assert(max(abs(G1 - G2)), 0, 1e-12);
%! assert(max(abs(C1 - C2)), 0, 1e-12);
%! assert(f1, f2); assert(n1, n2);

%!test
%! % Two windows contribute their segments to one estimate
%! Fs = 1000; N = 20000;
%! randn('state', 3);
%! x1 = randn(N,1); x2 = randn(N,1);
%! y1 = 2*x1; y2 = 2*x2;
%! [G, C, freq, nSeg] = PSestimateFreqResponse({x1, x2}, {y1, y2}, Fs);
%! [~, ~, ~, n1] = PSestimateFreqResponse(x1, y1, Fs);
%! assert(nSeg, 2*n1);
%! mid = freq > 10 & freq < 400;
%! assert(max(abs(abs(G(mid)) - 2)) < 0.01, 'pooled gain must still be 2');
%! assert(min(C(mid)) > 0.99);

%!test
%! % Pooling the Welch accumulators is not the same as averaging the two G's,
%! % and it is the right one: a weakly driven window carries less weight instead
%! % of the same weight. Averaging G would let the noisy window pull the answer.
%! Fs = 1000; N = 20000;
%! randn('state', 5);
%! trueG = 2;
%! xStrong = 10*randn(N,1);           % well excited
%! xWeak = 0.2*randn(N,1);            % barely excited
%! nz = 0.5*randn(N,1);               % same output noise on both
%! yStrong = trueG*xStrong + nz;
%! yWeak = trueG*xWeak + 0.5*randn(N,1);
%! [Gp, ~, freq] = PSestimateFreqResponse({xStrong, xWeak}, {yStrong, yWeak}, Fs);
%! Gs = PSestimateFreqResponse(xStrong, yStrong, Fs);
%! Gw = PSestimateFreqResponse(xWeak, yWeak, Fs);
%! Gmean = (Gs + Gw) / 2;
%! mid = freq > 10 & freq < 400;
%! ePooled = mean(abs(Gp(mid) - trueG));
%! eMean = mean(abs(Gmean(mid) - trueG));
%! assert(ePooled < eMean, 'pooled accumulators must beat averaging the G estimates');
%! assert(ePooled < 0.05, 'pooled estimate must land near the true gain');

%!test
%! % A window too short to hold one segment is skipped, not an error
%! Fs = 1000; N = 20000;
%! randn('state', 7);
%! x = randn(N,1); y = 3*x;
%! [G, ~, freq, nSeg] = PSestimateFreqResponse({x, randn(100,1)}, {y, randn(100,1)}, Fs);
%! [~, ~, ~, n1] = PSestimateFreqResponse(x, y, Fs);
%! assert(nSeg == n1, 'the short window must contribute nothing');
%! mid = freq > 10 & freq < 400;
%! assert(max(abs(abs(G(mid)) - 3)) < 0.01);

%!test
%! % Mismatched cell lengths are a caller bug and must say so
%! Fs = 1000;
%! x = randn(20000,1);
%! err = '';
%! try
%!   PSestimateFreqResponse({x, x}, {x}, Fs);
%! catch e
%!   err = e.message;
%! end
%! assert(~isempty(err), 'mismatched window counts must raise');

%!test
%! % No usable window at all returns zeros rather than NaN
%! Fs = 1000;
%! [G, C, freq, nSeg] = PSestimateFreqResponse({randn(50,1)}, {randn(50,1)}, Fs);
%! assert(nSeg, 0);
%! assert(all(G == 0)); assert(all(C == 0));
%! assert(numel(freq), floor(round(2.5*Fs)/2) + 1);
