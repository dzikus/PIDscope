% test_PSbuildController.m - tests for the BF controller frequency response model

%!test
%! % P-only: flat at the scaled P gain, nothing on the other two paths
%! Fs = 8000; freq = (0:10:1000)';
%! g = struct('P', 45, 'I', 0, 'D', 0, 'F', 0);
%! [A, D, F] = PSbuildController(g, [], Fs, freq);
%! assert(max(abs(A - 45*0.032029)) < 1e-12, 'P-only controller must be flat at Kp');
%! assert(all(D == 0), 'D path must be zero when the D gain is zero');
%! assert(all(F == 0), 'F path must be zero when the FF gain is zero');

%!test
%! % Integrator: infinite at DC, follows Ki/(j*w) well below Nyquist.
%! % The accumulator BF runs leads the ideal integral by half a sample, so the
%! % comparison only holds where f << Fs - it is 8 % out by Nyquist/20.
%! Fs = 8000; freq = [0; (1:5:50)'];
%! g = struct('P', 0, 'I', 80, 'D', 0, 'F', 0);
%! A = PSbuildController(g, [], Fs, freq);
%! assert(isinf(A(1)), 'integrator must be infinite at DC');
%! ideal = 80*0.244381 ./ (1j*2*pi*freq(2:end));
%! assert(max(abs(A(2:end) - ideal) ./ abs(ideal)) < 0.02, ...
%!        'discrete integrator must match Ki/s below Nyquist');

%!test
%! % Unfiltered D path is a differentiator: |D| = Kd*w
%! Fs = 8000; freq = (10:10:200)';
%! g = struct('P', 0, 'I', 0, 'D', 30, 'F', 0);
%! [~, D] = PSbuildController(g, [], Fs, freq);
%! ideal = 30*0.000529 * 2*pi*freq;
%! assert(max(abs(abs(D) - ideal) ./ ideal) < 0.01, 'unfiltered D must be Kd*w');

%!test
%! % The dterm lowpass lands on the D path and nowhere else
%! Fs = 8000; freq = (50:50:500)';
%! g = struct('P', 0, 'I', 0, 'D', 30, 'F', 0);
%! [~, Draw] = PSbuildController(g, [], Fs, freq);
%! fp = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 100, ...
%!             'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
%!             'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
%! [~, Dlp] = PSbuildController(g, fp, Fs, freq);
%! [b, a] = PSbfFilters('pt1', 100, Fs);
%! H = freqz(b, a, freq, Fs);
%! assert(max(abs(Dlp - Draw .* H(:))) < 1e-12, 'D path must carry the dterm lowpass');
%! assert(abs(Dlp(end)) < 0.3*abs(Draw(end)), 'lowpass must cut the D path at 500 Hz');

%!test
%! % Feedforward carries an extra 0.01 the other three terms do not:
%! % pid_init.c has Kf = FEEDFORWARD_SCALE * (pid[axis].F * 0.01f)
%! Fs = 8000; freq = (10:10:200)';
%! g = struct('P', 0, 'I', 0, 'D', 0, 'F', 120);
%! [~, ~, F] = PSbuildController(g, [], Fs, freq);
%! ideal = 120 * 0.013754 * 0.01 * 2*pi*freq;
%! assert(max(abs(abs(F) - ideal) ./ ideal) < 0.01, 'FF must carry the 0.01 from pid_init');

%!test
%! % Yaw runs 2.5x the I gain of roll and pitch (pid_init.c), and nothing else
%! % on that axis is scaled
%! Fs = 8000; freq = (1:2:99)';
%! g = struct('P', 40, 'I', 80, 'D', 25, 'F', 100);
%! roll = g; roll.axis = 0;
%! yaw  = g; yaw.axis = 2;
%! [Ar, Dr, Fr] = PSbuildController(roll, [], Fs, freq);
%! [Ay, Dy, Fy] = PSbuildController(yaw,  [], Fs, freq);
%! assert(max(abs(Dy - Dr)) < 1e-18, 'yaw must not scale the D path');
%! assert(max(abs(Fy - Fr)) < 1e-18, 'yaw must not scale feedforward');
%! Kp = 40*0.032029;
%! assert(max(abs((Ay - Kp) - 2.5*(Ar - Kp))) < 1e-12, 'yaw I gain must be 2.5x');

%!test
%! % An axis that is not named behaves like roll
%! Fs = 8000; freq = (1:2:99)';
%! g = struct('P', 40, 'I', 80, 'D', 25, 'F', 0);
%! A0 = PSbuildController(g, [], Fs, freq);
%! g.axis = 0; A1 = PSbuildController(g, [], Fs, freq);
%! g.axis = 1; A2 = PSbuildController(g, [], Fs, freq);
%! assert(max(abs(A1 - A0)) < 1e-18);
%! assert(max(abs(A2 - A0)) < 1e-18);

%!test
%! % TPA scales P and D, never I or FF
%! Fs = 8000; freq = (20:20:400)';
%! g  = struct('P', 45, 'I', 80, 'D', 30, 'F', 120);
%! gt = g; gt.tpa = 0.5;
%! [A1, D1, F1] = PSbuildController(g,  [], Fs, freq);
%! [A2, D2, F2] = PSbuildController(gt, [], Fs, freq);
%! assert(max(abs(D2 - 0.5*D1)) < 1e-18, 'TPA must halve the D path');
%! assert(max(abs(F2 - F1)) < 1e-18, 'TPA must not touch feedforward');
%! Aint = A1 - 45*0.032029;
%! assert(max(abs(A2 - (0.5*45*0.032029 + Aint))) < 1e-12, ...
%!        'TPA must scale only the proportional part of A');

%!test
%! % The transfer functions must match the difference equations BF actually runs.
%! % Time domain is the reference here: it mirrors the C code sample by sample,
%! % the frequency response is the derived form under test.
%! Fs = 2000; Ts = 1/Fs; N = 40000;
%! randn('state', 7);
%! g = struct('P', 45, 'I', 80, 'D', 30, 'F', 0);
%! Kp = 45*0.032029; Ki = 80*0.244381; Kd = 30*0.000529;
%! e = randn(N, 1);
%! uA = Kp*e + Ki*Ts*cumsum(e);
%! y = randn(N, 1);
%! [b, a] = PSbfFilters('pt1', 90, Fs);
%! yd = filter(b, a, y);
%! uD = Kd * [0; diff(yd)] / Ts;
%! [Ahat, ~, freq] = PSestimateFreqResponse(e, uA, Fs);
%! [Dhat, ~, ~] = PSestimateFreqResponse(y, uD, Fs);
%! fp = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 90, ...
%!             'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
%!             'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
%! [A, D] = PSbuildController(g, fp, Fs, freq);
%! band = freq > 10 & freq < 400;  % below 10 Hz a 2.5 s Welch segment holds too few cycles
%! assert(max(abs(Ahat(band) - A(band)) ./ abs(A(band))) < 0.01, ...
%!        'A must match the PI difference equation');
%! assert(max(abs(Dhat(band) - D(band)) ./ abs(D(band))) < 0.01, ...
%!        'D must match the filtered-derivative difference equation');
