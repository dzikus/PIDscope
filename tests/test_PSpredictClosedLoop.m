% test_PSpredictClosedLoop.m - tests for the predicted closed-loop response

%!test
%! % T/Guw must give the plant back - that is the identity PSrunChirpAnalysis
%! % relies on when it measures the plant as G_track./G_uw
%! freq = (0.5:0.5:500)'; w = 2*pi*freq;
%! P = 0.6 ./ (1 + 1j*w/(2*pi*70));
%! A = 1.4 + 15 ./ (1j*w);
%! D = 0.015 * 1j*w ./ (1 + 1j*w/(2*pi*90));
%! F = 1.2 * 1j*w ./ (1 + 1j*w/(2*pi*50));
%! [T, L, S, Guw] = PSpredictClosedLoop(P, A, D, F);
%! assert(max(abs(T ./ Guw - P)) < 1e-9, 'T/Guw must return the plant');
%! assert(max(abs(S .* (1 + L) - 1)) < 1e-9, 'S must be 1/(1+L)');
%! assert(max(abs(L - P .* (A + D))) < 1e-12, 'L must be P*(A+D)');

%!test
%! % An integrator makes A infinite at DC: the loop tracks exactly there
%! freq = [0; 1; 10];
%! P = [0.6; 0.6; 0.5];
%! A = [Inf; 10; 1.5];
%! D = zeros(3,1); F = zeros(3,1);
%! [T, ~, S, Guw] = PSpredictClosedLoop(P, A, D, F);
%! assert(T(1), 1, 1e-12);
%! assert(S(1), 0, 1e-12);
%! assert(Guw(1), 1/0.6, 1e-12);
%! assert(all(isfinite(T)), 'T must stay finite everywhere');

%!test
%! % Proportional control around a plant: plain T = PC/(1+PC)
%! freq = (1:1:200)';
%! P = 0.8 ./ (1 + 1j*2*pi*freq/(2*pi*50));
%! Kp = 1.44;
%! A = Kp * ones(size(freq));
%! T = PSpredictClosedLoop(P, A, zeros(size(freq)), zeros(size(freq)));
%! expected = (P*Kp) ./ (1 + P*Kp);
%! assert(max(abs(T - expected)) < 1e-12, 'P-only loop must reduce to PC/(1+PC)');

%!test
%! % Raising P must raise the closed-loop bandwidth
%! freq = (1:1:400)';
%! P = 0.8 ./ (1 + 1j*freq/50);
%! Tlow  = PSpredictClosedLoop(P, 0.5*ones(size(freq)), zeros(size(freq)), zeros(size(freq)));
%! Thigh = PSpredictClosedLoop(P, 4.0*ones(size(freq)), zeros(size(freq)), zeros(size(freq)));
%! bw = @(T) freq(find(abs(T) < abs(T(1))/sqrt(2), 1));
%! assert(bw(Thigh) > bw(Tlow), 'more P must widen the closed loop');

%!test
%! % End to end: run the BF loop around a known plant sample by sample, identify
%! % the plant the way PSrunChirpAnalysis does, then predict the loop back from
%! % it. The identified plant is model-free, so a wrong controller model (sign,
%! % sample offset, scaling) shows up here even though the plant still matches.
%! % The loop below is transcribed from the firmware, not from PSbuildController -
%! % if both sides came from the same belief this test would only confirm it:
%! %   pid.c:1294        P = Kp * errorRate
%! %   pid.c:1318,1326   I = previousIterm + Ki * dT * errorRate
%! %   pid.c:1359-1360   D = Kd * -(dtermGyro[k] - dtermGyro[k-1]) * pidFrequency
%! %   pid.c:1410        F = Kf * pidSetpointDelta
%! %   pid_init.c:376    Kf carries an extra 0.01 the other three do not
%! % Known gap: the firmware differentiates the setpoint at the RX rate and runs
%! % it through PT3 smoothing, boost and jitter reduction (rc.c:439,463,505,510).
%! % This models a plain derivative at the PID rate, so the F path is an
%! % approximation - see the header of PSbuildController.
%! Fs = 2000; Ts = 1/Fs; N = 60000;
%! g = struct('P', 45, 'I', 60, 'D', 20, 'F', 90);
%! fp = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 80, ...
%!             'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
%!             'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
%! Kp = 45*0.032029; Ki = 60*0.244381; Kd = 20*0.000529; Kf = 90*0.013754*0.01;
%! pt1k = @(fc) (1/Fs) / (1/(2*pi*fc) + 1/Fs);
%! kPlant = pt1k(60 * 1.553773974);   % pt2 at 60 Hz, as PSbfFilters builds it
%! kDterm = pt1k(80);
%! gPlant = 0.5;
%! randn('state', 11);
%! [br, ar] = PSbfFilters('pt2', 250, Fs);   % a setpoint the feedforward can differentiate
%! r = filter(br, ar, randn(N, 1)); r = 40 * r / std(r);
%! y = zeros(N, 1); u = zeros(N, 1);
%! s1 = 0; s2 = 0; sd = 0; Iacc = 0; sdPrev = 0; rPrev = 0; yNext = 0;
%! for k = 1:N
%!     y(k) = yNext;                        % gyro the controller consumes now
%!     ek = r(k) - y(k);
%!     Iacc = Iacc + Ki*Ts*ek;
%!     sd = sd + kDterm*(y(k) - sd);
%!     uD = Kd*(sd - sdPrev)/Ts; sdPrev = sd;
%!     uF = Kf*(r(k) - rPrev)/Ts; rPrev = r(k);
%!     u(k) = Kp*ek + Iacc - uD + uF;
%!     s1 = s1 + kPlant*(gPlant*u(k) - s1); % plant acts on this iteration's output
%!     s2 = s2 + kPlant*(s1 - s2);
%!     yNext = s2;
%! end
%! assert(all(isfinite(y)) && max(abs(y)) < 1e6, 'simulated loop must stay stable');
%! [G_track, ~, freq] = PSestimateFreqResponse(r, y, Fs);
%! [G_uw, ~, ~] = PSestimateFreqResponse(r, u, Fs);
%! G_plant = G_track ./ (G_uw + 1e-12);
%! [A, D, F] = PSbuildController(g, fp, Fs, freq);
%! [T, ~, ~, Guw] = PSpredictClosedLoop(G_plant, A, D, F);
%! band = freq > 10 & freq < 250;  % below 10 Hz a 2.5 s Welch segment holds too few cycles
%! assert(max(abs(T(band) - G_track(band)) ./ abs(G_track(band))) < 0.01, ...
%!        'predicted tracking response must reproduce the simulated loop');
%! assert(max(abs(Guw(band) - G_uw(band)) ./ abs(G_uw(band))) < 0.01, ...
%!        'predicted controller output must reproduce the simulated one');

%!test
%! % Predicting a gain change must move the step response the way it should:
%! % same measured plant, more P, faster rise
%! Fs = 2000; freq = (0:0.4:1000)'; w = 2*pi*freq;
%! P = 0.6 * exp(-1j*w*0.002) ./ (1 + 1j*w/(2*pi*60)).^2;
%! fp = [];
%! g = struct('P', 40, 'I', 50, 'D', 20, 'F', 0);
%! [A1, D1, F1] = PSbuildController(g, fp, Fs, freq);
%! g.P = 70;
%! [A2, D2, F2] = PSbuildController(g, fp, Fs, freq);
%! T1 = PSpredictClosedLoop(P, A1, D1, F1);
%! T2 = PSpredictClosedLoop(P, A2, D2, F2);
%! [t1, s1] = PSstepFromFRD(freq, T1, 300);
%! [t2, s2] = PSstepFromFRD(freq, T2, 300);
%! rise = @(t, s) t(find(s > 0.63, 1));
%! assert(rise(t2, s2) < rise(t1, s1), 'more P must reach 63 %% sooner');

%!test
%! % The firmware builds feedforward from the RX-rate setpoint delta and then
%! % smooths it (rc.c:439,463,505,510) - none of which PSbuildController models.
%! % So the F path is taken from the log instead: axisF against the logged
%! % setpoint is the same measured-FRF trick the plant already uses. This loop
%! % carries a PT3 on the F path that the model knows nothing about; predicting
%! % with the modelled F must miss, predicting with the measured F must not.
%! Fs = 2000; Ts = 1/Fs; N = 60000;
%! g = struct('P', 45, 'I', 60, 'D', 20, 'F', 90);
%! fp = struct('dterm_lpf1_type', 0, 'dterm_lpf1_hz', 80, ...
%!             'dterm_lpf2_type', 0, 'dterm_lpf2_hz', 0, ...
%!             'dterm_notch_hz', 0, 'dterm_notch_cut', 0);
%! Kp = 45*0.032029; Ki = 60*0.244381; Kd = 20*0.000529; Kf = 90*0.013754*0.01;
%! pt1k = @(fc) (1/Fs) / (1/(2*pi*fc) + 1/Fs);
%! kPlant = pt1k(60 * 1.553773974);
%! kDterm = pt1k(80);
%! kFF = pt1k(25 * 1.961459177);      % pt3 at 25 Hz on the feedforward
%! gPlant = 0.5;
%! randn('state', 11);
%! [br, ar] = PSbfFilters('pt2', 250, Fs);
%! r = filter(br, ar, randn(N, 1)); r = 40 * r / std(r);
%! y = zeros(N, 1); u = zeros(N, 1); aF = zeros(N, 1);
%! s1 = 0; s2 = 0; sd = 0; f1 = 0; f2 = 0; f3 = 0;
%! Iacc = 0; sdPrev = 0; rPrev = 0; yNext = 0;
%! for k = 1:N
%!     y(k) = yNext;
%!     ek = r(k) - y(k);
%!     Iacc = Iacc + Ki*Ts*ek;
%!     sd = sd + kDterm*(y(k) - sd);
%!     uD = Kd*(sd - sdPrev)/Ts; sdPrev = sd;
%!     uFraw = Kf*(r(k) - rPrev)/Ts; rPrev = r(k);
%!     f1 = f1 + kFF*(uFraw - f1);
%!     f2 = f2 + kFF*(f1 - f2);
%!     f3 = f3 + kFF*(f2 - f3);
%!     aF(k) = f3;
%!     u(k) = Kp*ek + Iacc - uD + aF(k);
%!     s1 = s1 + kPlant*(gPlant*u(k) - s1);
%!     s2 = s2 + kPlant*(s1 - s2);
%!     yNext = s2;
%! end
%! assert(all(isfinite(y)) && max(abs(y)) < 1e6, 'simulated loop must stay stable');
%! [G_track, ~, freq] = PSestimateFreqResponse(r, y, Fs);
%! [G_uw, ~, ~] = PSestimateFreqResponse(r, u, Fs);
%! [G_ff, ~, ~] = PSestimateFreqResponse(r, aF, Fs);
%! G_plant = G_track ./ (G_uw + 1e-12);
%! [A, D, Fmod] = PSbuildController(g, fp, Fs, freq);
%! Tmod = PSpredictClosedLoop(G_plant, A, D, Fmod);
%! Tmea = PSpredictClosedLoop(G_plant, A, D, G_ff);
%! band = freq > 10 & freq < 250;
%! eMea = max(abs(Tmea(band) - G_track(band)) ./ abs(G_track(band)));
%! eMod = max(abs(Tmod(band) - G_track(band)) ./ abs(G_track(band)));
%! assert(eMea < 0.01, 'the measured F path must reproduce the loop');
%! assert(eMod > 0.05, 'the modelled F path must visibly miss, or this proves nothing');
