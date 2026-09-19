% test_PSidentifyChirp.m - chirp identification, with the plotting split off

%!shared T, si, Fs, tIND, kPlant, gPlant
%! % A Betaflight loop run sample by sample against a known plant, driven by a
%! % real 0.5 -> 400 Hz sweep, so the identified plant can be checked against
%! % algebra rather than against a previous run of this same code.
%! Fs = 2000; Ts = 1/Fs;
%! Tc = 20; Nc = Tc*Fs; pad = 2000; N = Nc + 2*pad;
%! f0 = 0.5; f1 = 400;
%! tt = (0:Nc-1)'/Fs;
%! ph = 2*pi*(f0*tt + (f1-f0)/(2*Tc)*tt.^2);
%! sinarg = zeros(N,1); sinarg(pad+1:pad+Nc) = mod(ph, 2*pi);
%! sp = zeros(N,1);     sp(pad+1:pad+Nc) = 200*sin(ph);
%! Kp = 45*0.032029; Ki = 60*0.244381; Kd = 20*0.000529;
%! pt1k = @(fc) (1/Fs) / (1/(2*pi*fc) + 1/Fs);
%! kPlant = pt1k(60 * 1.553773974);   % pt2 at 60 Hz, as PSbfFilters builds it
%! kDterm = pt1k(80);
%! gPlant = 0.5;
%! y = zeros(N,1); uP = zeros(N,1); uI = zeros(N,1); uD = zeros(N,1);
%! sd = 0; sdPrev = 0; Iacc = 0; s1 = 0; s2 = 0; yNext = 0;
%! for k = 1:N
%!   y(k) = yNext;
%!   ek = sp(k) - y(k);
%!   Iacc = Iacc + Ki*Ts*ek;
%!   sd = sd + kDterm*(y(k) - sd);
%!   uP(k) = Kp*ek; uI(k) = Iacc;
%!   uD(k) = -Kd*(sd - sdPrev)/Ts; sdPrev = sd;
%!   s1 = s1 + kPlant*(gPlant*(uP(k)+uI(k)+uD(k)) - s1);
%!   s2 = s2 + kPlant*(s1 - s2);
%!   yNext = s2;
%! end
%! assert(all(isfinite(y)) && max(abs(y)) < 1e6, 'simulated loop must stay stable');
%! T = struct();
%! T.debug_0_ = round(sinarg * 5000);
%! T.gyroADC_0_ = y; T.setpoint_0_ = sp; T.setpoint_3_ = 1500*ones(N,1);
%! T.axisP_0_ = uP; T.axisI_0_ = uI; T.axisD_0_ = uD; T.axisF_0_ = zeros(N,1);
%! si = {'rollPID','45,60,20'; 'ff_weight','0,0,0'; 'd_max','0,0,0'; ...
%!       'looptime','500'; 'pid_process_denom','1'; ...
%!       'dterm_lpf1_type','0'; 'dterm_lpf1_static_hz','80'; ...
%!       'dterm_lpf2_type','0'; 'dterm_lpf2_static_hz','0'; ...
%!       'dterm_notch_hz','0'; 'dterm_notch_cutoff','0'; ...
%!       'chirp_time_seconds','20'; 'pidsum_limit','800'; 'pidsum_limit_yaw','600'};
%! tIND = true(N,1);

%!test
%! % The identified plant must match the one the simulation actually contains:
%! % two PT1 sections and the one-sample delay of reading the gyro before the
%! % plant integrates this iteration's output
%! id = PSidentifyChirp(T, si, Fs, tIND, 0);
%! assert(id.ok, 'a clean simulated chirp must identify');
%! zinv = exp(-2j*pi*id.freq/Fs);
%! H = kPlant ./ (1 - (1-kPlant)*zinv);
%! Pexact = gPlant * H.^2 .* zinv;
%! band = id.freq > 10 & id.freq < 200;
%! err = abs(id.G_plant(band) - Pexact(band)) ./ abs(Pexact(band));
%! assert(max(err) < 0.02, sprintf('plant off by %.1f%% at worst', 100*max(err)));

%!test
%! % Both paths carry the same fields, so three axes assemble into one struct
%! % array even when an axis refuses
%! want = {'ok','msg','freq','G_track','C_track','G_plant','G_uw','C_uw', ...
%!         'G_ff','gains','fp','FsPid','axisIdx','axisName','i0','i1', ...
%!         'nSamp','durSec','gyroVar','nSeg','fTrust','axisD','pidsumLimit'};
%! good = PSidentifyChirp(T, si, Fs, tIND, 0);
%! bad = PSidentifyChirp(struct('gyroADC_0_', zeros(10,1)), si, Fs, true(10,1), 0);
%! assert(isempty(setdiff(want, fieldnames(good))), 'a field the plan names is missing');
%! assert(isequal(fieldnames(good), fieldnames(bad)), 'both paths must agree on fields');
%! arr = [good bad];
%! assert(numel(arr) == 2, 'results must concatenate into a struct array');

%!test
%! % Identification must not draw and must not talk - the caller decides how to
%! % report, which is what lets three axes run without opening three windows
%! n0 = numel(findobj('Type', 'figure'));
%! out = evalc('id = PSidentifyChirp(T, si, Fs, tIND, 0);');
%! assert(numel(findobj('Type', 'figure')) == n0, 'must not open a figure');
%! assert(isempty(strtrim(out)), 'must not print');

%!test
%! % No debug column at all
%! id = PSidentifyChirp(struct('gyroADC_0_', zeros(100,1)), si, Fs, true(100,1), 0);
%! assert(~id.ok);
%! assert(~isempty(strfind(lower(id.msg), 'debug')), 'message must name what is missing');
%! assert(isempty(id.freq));

%!test
%! % Debug column present but no chirp was flown
%! Tz = T; Tz.debug_0_ = zeros(size(T.debug_0_));
%! id = PSidentifyChirp(Tz, si, Fs, tIND, 0);
%! assert(~id.ok);
%! assert(~isempty(strfind(lower(id.msg), 'chirp')));

%!test
%! % Without the PID terms there is no plant, but tracking is still measurable
%! Tn = rmfield(T, {'axisP_0_','axisI_0_','axisD_0_','axisF_0_'});
%! id = PSidentifyChirp(Tn, si, Fs, tIND, 0);
%! assert(id.ok, 'tracking alone is still a usable measurement');
%! assert(~isempty(id.G_track));
%! assert(isempty(id.G_plant), 'no PID terms means no plant');
%! assert(isempty(id.axisD));

%!test
%! % The plant is G_track / G_uw, so the band may never be wider than what
%! % either estimate alone supports. On a log where axisSum is an exact function
%! % of the logged signals C_uw sits at 1 and C_track binds, so this guards the
%! % direction rather than a number: widening it, or reading the band off G_uw
%! % alone, would let the prediction run past where the plant was measured.
%! id = PSidentifyChirp(T, si, Fs, tIND, 0);
%! assert(id.fTrust <= PStrustBand(id.freq, id.C_track));
%! assert(id.fTrust <= PStrustBand(id.freq, id.C_uw));
%! assert(id.fTrust > 50, 'a clean 400 Hz sweep must leave a usable band');

%!test
%! % The window and the header land in the result, because the gates and the UI
%! % read them from here rather than re-parsing the log
%! id = PSidentifyChirp(T, si, Fs, tIND, 0);
%! assert(strcmp(id.axisName, 'Roll'));
%! assert(id.axisIdx == 0);
%! assert(id.durSec > 19 && id.durSec < 20.2);
%! assert(id.nSeg > 8, 'too few Welch segments to average');
%! assert(id.fTrust > 50);
%! assert(id.pidsumLimit == 800);
%! assert(id.gains.P == 45);
%! assert(id.FsPid == 2000);
%! assert(numel(id.axisD) == id.nSamp, 'axisD is the window, ready for the noise budget');
