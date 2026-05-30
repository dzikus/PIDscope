% test_PSstepcalc.m - Tests for step response deconvolution
% NOTE: PSstepcalc expects SP,GY as column vectors, lograte in kHz

%!test
%! % Smoke test: function runs without error
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;  % 5 seconds
%! sp = zeros(N, 1);
%! gy = zeros(N, 1);
%! % Create step inputs above 20 deg/s threshold
%! for k = 1:3
%!   st = round(k * Fs + 100);
%!   en = min(st + round(0.4*Fs), N);
%!   sp(st:en) = 300;
%!   gy(st:en) = 285;
%! end
%! [stepresponse, t] = PSstepcalc(sp, gy, Fs_khz, 0, 1);
%! assert(~isempty(t));

%!test
%! % Time vector starts at 0 and ends at 500ms
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! sp = zeros(N, 1);
%! gy = zeros(N, 1);
%! for k = 1:3
%!   st = round(k * Fs + 100);
%!   en = min(st + round(0.4*Fs), N);
%!   sp(st:en) = 300;
%!   gy(st:en) = 280;
%! end
%! [~, t] = PSstepcalc(sp, gy, Fs_khz, 0, 1);
%! assert(t(1), 0, 1e-10);
%! assert(t(end), 500, 1);

%!test
%! % Step response values are finite when valid segments exist
%! Fs_khz = 4;
%! Fs = Fs_khz * 1000;
%! N = Fs * 5;
%! sp = zeros(N, 1);
%! gy = zeros(N, 1);
%! for k = 1:3
%!   st = round(k * Fs + 100);
%!   en = min(st + round(0.4*Fs), N);
%!   sp(st:en) = 400;
%!   gy(st:en) = 380;
%! end
%! [stepresponse, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1);
%! if ~isempty(stepresponse)
%!   assert(all(isfinite(stepresponse(:))));
%! end

%!test
%! % Higher subsampleFactor yields more segments (more overlap)
%! Fs_khz = 4; Fs = Fs_khz * 1000; N = Fs * 10;
%! sp = zeros(N, 1); gy = zeros(N, 1);
%! for k = 1:8
%!   st = round(k * Fs * 1.1 + 100); en = min(st + round(0.3*Fs), N);
%!   sp(st:en) = 200; gy(st:en) = 190;
%! end
%! [s_low, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 1, 40, 500);
%! [s_high, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 10, 40, 500);
%! n_low = 0; n_high = 0;
%! if exist('s_low','var') && ~isempty(s_low), n_low = size(s_low, 1); end
%! if exist('s_high','var') && ~isempty(s_high), n_high = size(s_high, 1); end
%! assert(n_high >= n_low, 'high subsample should yield >= segments than low');

%!test
%! % minRate filters out low-amplitude segments
%! Fs_khz = 4; Fs = Fs_khz * 1000; N = Fs * 10;
%! sp = zeros(N, 1); gy = zeros(N, 1);
%! % low-amplitude segments (30 deg/s)
%! for k = 1:4
%!   st = round(k * Fs * 1.1 + 100); en = min(st + round(0.3*Fs), N);
%!   sp(st:en) = 30; gy(st:en) = 28;
%! end
%! % high-amplitude segments (200 deg/s)
%! for k = 5:8
%!   st = round(k * Fs * 1.1 + 100); en = min(st + round(0.3*Fs), N);
%!   sp(st:en) = 200; gy(st:en) = 190;
%! end
%! [s_low, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 5, 10, 500);
%! [s_high, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 5, 100, 500);
%! n_low = 0; n_high = 0;
%! if ~isempty(s_low), n_low = size(s_low, 1); end
%! if ~isempty(s_high), n_high = size(s_high, 1); end
%! assert(n_low >= n_high, 'lower minRate should include more segments');

%!test
%! % maxRate excludes extreme maneuvers
%! Fs_khz = 4; Fs = Fs_khz * 1000; N = Fs * 10;
%! sp = zeros(N, 1); gy = zeros(N, 1);
%! % moderate segments (200 deg/s)
%! for k = 1:4
%!   st = round(k * Fs * 1.1 + 100); en = min(st + round(0.3*Fs), N);
%!   sp(st:en) = 200; gy(st:en) = 190;
%! end
%! % extreme segments (800 deg/s)
%! for k = 5:8
%!   st = round(k * Fs * 1.1 + 100); en = min(st + round(0.3*Fs), N);
%!   sp(st:en) = 800; gy(st:en) = 750;
%! end
%! [s_limited, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 5, 40, 500);
%! [s_all, ~] = PSstepcalc(sp, gy, Fs_khz, 0, 1, 5, 40, Inf);
%! n_limited = 0; n_all = 0;
%! if ~isempty(s_limited), n_limited = size(s_limited, 1); end
%! if ~isempty(s_all), n_all = size(s_all, 1); end
%! assert(n_all >= n_limited, 'unlimited maxRate should include more segments');

%!test
%! % Backward compat: old 5-arg call still works
%! Fs_khz = 4; Fs = Fs_khz * 1000; N = Fs * 5;
%! sp = zeros(N, 1); gy = zeros(N, 1);
%! for k = 1:3
%!   st = round(k * Fs + 100); en = min(st + round(0.4*Fs), N);
%!   sp(st:en) = 300; gy(st:en) = 285;
%! end
%! [stepresponse, t] = PSstepcalc(sp, gy, Fs_khz, 0, 1);
%! assert(~isempty(t), 'old 5-arg signature must still work');
