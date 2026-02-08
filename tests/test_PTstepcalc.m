% test_PTstepcalc.m - Tests for step response deconvolution
% NOTE: PTstepcalc expects SP,GY as column vectors, lograte in kHz

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
%! [stepresponse, t] = PTstepcalc(sp, gy, Fs_khz, 0, 1);
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
%! [~, t] = PTstepcalc(sp, gy, Fs_khz, 0, 1);
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
%! [stepresponse, ~] = PTstepcalc(sp, gy, Fs_khz, 0, 1);
%! if ~isempty(stepresponse)
%!   assert(all(isfinite(stepresponse(:))));
%! end
