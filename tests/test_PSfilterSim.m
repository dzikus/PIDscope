% test_PSfilterSim.m - verify filter response calculations used in PSfilterSim

%!test
%! % PT1 at cutoff: forward Euler shifts -3dB point, expect -3 to -4 dB
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! [H, f] = freqz(b, a, 4096, Fs);
%! [~, ifc] = min(abs(f - fc));
%! mag_at_fc = 20*log10(abs(H(ifc)));
%! assert(mag_at_fc, -3, 1.0);

%!test
%! % PT2 at cutoff: BF corrects fc so -3dB lands near nominal fc
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt2', fc, Fs);
%! [H, f] = freqz(b, a, 4096, Fs);
%! [~, ifc] = min(abs(f - fc));
%! mag_at_fc = 20*log10(abs(H(ifc)));
%! assert(mag_at_fc, -3, 1.5);

%!test
%! % PT3 at cutoff: BF corrects fc so -3dB lands near nominal fc
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt3', fc, Fs);
%! [H, f] = freqz(b, a, 4096, Fs);
%! [~, ifc] = min(abs(f - fc));
%! mag_at_fc = 20*log10(abs(H(ifc)));
%! assert(mag_at_fc, -3, 2.0);

%!test
%! % DC gain of all lowpass types should be 0 dB
%! Fs = 4000; fc = 200;
%! for t = {'pt1', 'pt2', 'pt3', 'biquad'}
%!     [b, a] = PSbfFilters(t{1}, fc, Fs);
%!     [H, ~] = freqz(b, a, 4096, Fs);
%!     dc_dB = 20*log10(abs(H(1)));
%!     assert(abs(dc_dB) < 0.01);
%! end

%!test
%! % Notch filter: near-zero magnitude at center, unity elsewhere
%! Fs = 4000; fc = 300; Q = 5;
%! [b, a] = PSbfFilters('notch', fc, Fs, Q);
%! [H, f] = freqz(b, a, 4096, Fs);
%! [~, ifc] = min(abs(f - fc));
%! mag_notch = 20*log10(abs(H(ifc)));
%! mag_dc = 20*log10(abs(H(1)));
%! assert(mag_notch < -20);
%! assert(abs(mag_dc) < 0.01);

%!test
%! % Cascaded H multiplication matches sequential filtering
%! Fs = 4000;
%! [b1, a1] = PSbfFilters('pt1', 200, Fs);
%! [b2, a2] = PSbfFilters('pt2', 300, Fs);
%! Nfft = 2048;
%! [H1, ~] = freqz(b1, a1, Nfft, Fs);
%! [H2, ~] = freqz(b2, a2, Nfft, Fs);
%! H_cascade = H1(:) .* H2(:);
%! imp = [1; zeros(Nfft*2-1, 1)];
%! out = filter(b1, a1, imp);
%! out = filter(b2, a2, out);
%! H_seq = fft(out, Nfft*2);
%! H_seq = H_seq(1:Nfft);
%! mag_cascade = 20*log10(abs(H_cascade));
%! mag_seq = 20*log10(abs(H_seq));
%! assert(max(abs(mag_cascade - mag_seq)) < 0.5);

%!test
%! % Group delay of PT1 at DC should be ~1/(2*pi*fc) seconds
%! Fs = 8000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! [H, f] = freqz(b, a, 4096, Fs);
%! f = f(:);
%! dw = gradient(2*pi*f);
%! gd_s = -gradient(unwrap(angle(H(:)))) ./ dw;
%! gd_ms = gd_s * 1000;
%! gd_dc = gd_ms(2);  % skip f=0 edge artifact
%! expected_ms = 1/(2*pi*fc) * 1000;
%! assert(gd_dc, expected_ms, 0.15);

%!test
%! % Step response of PT1 should reach ~63.2% at t=RC
%! Fs = 8000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! stepIn = ones(round(Fs * 0.050), 1);
%! stepOut = filter(b, a, stepIn);
%! RC_samples = round(1/(2*pi*fc) * Fs);
%! val_at_RC = stepOut(RC_samples);
%! assert(val_at_RC, 0.632, 0.05);

%!test
%! % Step response of lowpass should settle to 1.0
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt2', fc, Fs);
%! stepIn = ones(round(Fs * 0.1), 1);
%! stepOut = filter(b, a, stepIn);
%! assert(stepOut(end), 1.0, 0.01);

%!test
%! % PT1 phase is 0 at DC and negative in passband
%! Fs = 4000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! [H, f] = freqz(b, a, 512, Fs);
%! ph = angle(H) * 180/pi;
%! assert(abs(ph(1)) < 0.1);  % 0 at DC
%! [~, ifc] = min(abs(f - fc));
%! assert(ph(ifc) < 0);  % negative at cutoff

%!test
%! % PT1 phase at cutoff should be -45 degrees
%! Fs = 8000; fc = 200;
%! [b, a] = PSbfFilters('pt1', fc, Fs);
%! [H, f] = freqz(b, a, 4096, Fs);
%! [~, ifc] = min(abs(f - fc));
%! ph_deg = angle(H(ifc)) * 180/pi;
%! assert(ph_deg, -45, 3);

%!test
%! % Emuflight per-axis keys: dterm_lowpass_hz_roll, gyro_lowpass_hz_roll
%! si = {
%!   'Firmware revision', 'EmuFlight 0.4.1 HELIOSPRING';
%!   'gyro_lowpass_type', '0';
%!   'gyro_lowpass_hz_roll', '200';
%!   'gyro_lowpass_hz_pitch', '200';
%!   'gyro_lowpass_hz_yaw', '200';
%!   'gyro_lowpass2_type', '0';
%!   'gyro_lowpass2_hz_roll', '150';
%!   'gyro_lowpass2_hz_pitch', '150';
%!   'gyro_lowpass2_hz_yaw', '150';
%!   'dterm_lowpass_hz_roll', '110';
%!   'dterm_lowpass_hz_pitch', '110';
%!   'dterm_lowpass_hz_yaw', '110';
%!   'dterm_lowpass2_hz_roll', '185';
%!   'dterm_lowpass2_hz_pitch', '185';
%!   'dterm_lowpass2_hz_yaw', '185';
%!   'dterm_notch_hz', '0';
%!   'dterm_notch_cutoff', '0';
%!   'gyro_notch_hz', '0,0';
%!   'gyro_notch_cutoff', '0,0';
%! };
%! fp = PSparseFilterParams(si);
%! assert(fp.gyro_lpf1_hz, 200);
%! assert(fp.gyro_lpf2_hz, 150);
%! assert(fp.dterm_lpf1_hz, 110);
%! assert(fp.dterm_lpf2_hz, 185);

%!test
%! % PSparseFilterParams must return gyro loop rate from headers
%! % looptime:125 = 125us = 8kHz gyro rate
%! si = {
%!   'looptime', '125';
%!   'gyro_sync_denom', '1';
%!   'pid_process_denom', '1';
%!   'gyro_lowpass_type', '0';
%!   'gyro_lowpass_hz', '300';
%!   'dterm_lowpass_hz', '100';
%!   'gyro_notch_hz', '0,0';
%!   'gyro_notch_cutoff', '0,0';
%!   'dterm_notch_hz', '0';
%!   'dterm_notch_cutoff', '0';
%! };
%! fp = PSparseFilterParams(si);
%! assert(fp.gyro_rate_hz, 8000, 'looptime:125 should give 8kHz gyro rate');

%!test
%! % looptime:250 with gyro_sync_denom:2 = 500us gyro, 1000us pid -> gyro 4kHz
%! si = {
%!   'looptime', '250';
%!   'gyro_sync_denom', '2';
%!   'pid_process_denom', '2';
%!   'gyro_lowpass_hz', '300';
%!   'gyro_notch_hz', '0,0';
%!   'gyro_notch_cutoff', '0,0';
%!   'dterm_notch_hz', '0';
%!   'dterm_notch_cutoff', '0';
%! };
%! fp = PSparseFilterParams(si);
%! assert(fp.gyro_rate_hz, 4000, 'looptime 250us / gyro_sync_denom 2 = 4kHz');

%!test
%! % No looptime header -> gyro_rate_hz should be 0 (use log rate as fallback)
%! si = {
%!   'gyro_lowpass_hz', '300';
%!   'gyro_notch_hz', '0,0';
%!   'gyro_notch_cutoff', '0,0';
%!   'dterm_notch_hz', '0';
%!   'dterm_notch_cutoff', '0';
%! };
%! fp = PSparseFilterParams(si);
%! assert(fp.gyro_rate_hz, 0, 'no looptime header -> gyro_rate_hz = 0');
