% test_PSchirpWindows.m - scoring every chirp block in a log, not just the longest

%!test
%! % Three runs separated by real gaps are three blocks, and a phase wrap that
%! % lands exactly on zero inside a run must not split it
%! blk = round(5000 * mod((1:10000)' * 0.01, 2*pi) / (2*pi));
%! blk(500:500:9500) = 0;
%! gap = zeros(2000, 1);
%! sinarg = [blk; gap; blk; gap; blk];
%! randn('state', 11);
%! gyro = 100 * randn(size(sinarg));
%! w = PSchirpWindows(sinarg, gyro);
%! assert(numel(w) == 3, 'a wrap through zero must not split a run');
%! assert([w.i0], [1 12001 24001]);
%! assert([w.i1], [10000 22000 34000]);
%! assert([w.nSamp], [10000 10000 10000]);

%!test
%! % A sweep that ran to the end is complete; one cut short is not, and the
%! % short one still reports a plausible window
%! Fs = 1000;
%! si = {'chirp_time_seconds', '20'};
%! sinarg = [ones(20000,1); zeros(2000,1); ones(10000,1)];
%! randn('state', 12);
%! gyro = 100 * randn(size(sinarg));
%! w = PSchirpWindows(sinarg, gyro, [], [], Fs, si, 0);
%! assert(numel(w), 2);
%! assert(w(1).durSec, 20, 1e-9);
%! assert(w(1).chirpTime, 20);
%! assert(w(1).complete);
%! assert(w(2).durSec, 10, 1e-9);
%! assert(~w(2).complete, 'half a sweep has no top of band');

%!test
%! % Without chirp_time_seconds nothing can be certified complete, and the
%! % caller can tell it apart from a short sweep because chirpTime is unknown
%! Fs = 1000;
%! randn('state', 13);
%! w = PSchirpWindows(ones(20000,1), 100*randn(20000,1), [], [], Fs, {}, 0);
%! assert(isnan(w.chirpTime));
%! assert(~w.complete, 'unknown sweep length must not read as complete');

%!test
%! % Saturation counts from 0.98 of pidsum_limit, in both directions - the loop
%! % stops being linear before the sum reaches the clip
%! Fs = 1000;
%! si = {'chirp_time_seconds', '10'; 'pidsum_limit', '800'; 'pidsum_limit_yaw', '600'};
%! randn('state', 14);
%! axisSum = 100 * ones(10000, 1);
%! axisSum(1:1500) = 790;
%! axisSum(2001:3000) = -790;
%! w = PSchirpWindows(ones(10000,1), 100*randn(10000,1), axisSum, [], Fs, si, 0);
%! assert(w.pidsumLimit, 800);
%! assert(w.satFrac, 0.25, 1e-12);

%!test
%! % Yaw has its own limit - scoring it against the roll one hides a third of
%! % the saturation
%! Fs = 1000;
%! si = {'chirp_time_seconds', '10'; 'pidsum_limit', '800'; 'pidsum_limit_yaw', '600'};
%! randn('state', 15);
%! gyro = 100 * randn(10000, 1);
%! axisSum = 100 * ones(10000, 1);
%! axisSum(1:1500) = 700;          % over 0.98*600, under 0.98*800
%! wRoll = PSchirpWindows(ones(10000,1), gyro, axisSum, [], Fs, si, 0);
%! wYaw  = PSchirpWindows(ones(10000,1), gyro, axisSum, [], Fs, si, 2);
%! assert(wYaw.pidsumLimit, 600);
%! assert(wRoll.satFrac, 0, 1e-12);
%! assert(wYaw.satFrac, 0.15, 1e-12);

%!test
%! % Variance is per block, so a run that swept another axis scores low on this
%! % one - that is how a three-axis log keeps its axes apart
%! Fs = 1000;
%! si = {'chirp_time_seconds', '10'};
%! randn('state', 16);
%! sinarg = [ones(10000,1); zeros(2000,1); ones(10000,1)];
%! gyro = [0.5*randn(10000,1); zeros(2000,1); 100*randn(10000,1)];
%! w = PSchirpWindows(sinarg, gyro, [], [], Fs, si, 0);
%! assert(w(1).gyroVar < 10);
%! assert(w(2).gyroVar > 1000);

%!test
%! % Throttle spread is per block as well - TPA moves with throttle, so a block
%! % flown on a drifting stick is not the same measurement as a steady one
%! Fs = 1000;
%! si = {'chirp_time_seconds', '10'};
%! randn('state', 17);
%! sinarg = [ones(10000,1); zeros(2000,1); ones(10000,1)];
%! gyro = 100 * randn(size(sinarg));
%! thr = [1500*ones(10000,1); zeros(2000,1); [1400*ones(5000,1); 1600*ones(5000,1)]];
%! w = PSchirpWindows(sinarg, gyro, [], thr, Fs, si, 0);
%! assert(w(1).thrStd, 0, 1e-12);
%! assert(w(2).thrStd, 100, 0.02);

%!test
%! % A log with no chirp has no blocks to score
%! randn('state', 18);
%! w = PSchirpWindows(zeros(5000,1), randn(5000,1));
%! assert(isempty(w));

%!test
%! % PSfindChirpWindow needs only the blocks and their variance, so the rest is
%! % optional and reports as unknown rather than as a passing score
%! randn('state', 19);
%! w = PSchirpWindows(ones(3000,1), 100*randn(3000,1));
%! assert(w.i0, 1); assert(w.i1, 3000);
%! assert(w.gyroVar > 1000);
%! assert(isnan(w.durSec)); assert(isnan(w.satFrac)); assert(isnan(w.thrStd));
%! assert(isnan(w.pidsumLimit));
%! assert(~w.complete);
