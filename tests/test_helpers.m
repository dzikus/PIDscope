function out = test_helpers()
  % Test helpers - mock data generators for PIDtoolbox tests
  % Usage: h = test_helpers(); y = h.mock_sine(100, 2, 4);
  out.mock_sine = @mock_sine;
  out.mock_step = @mock_step;
  out.mock_throttle = @mock_throttle;
end

function y = mock_sine(freq_hz, duration_s, sample_rate_khz)
  % Generate pure sine wave
  % freq_hz - frequency in Hz
  % duration_s - duration in seconds
  % sample_rate_khz - sample rate in kHz (matching PTtoolbox convention)
  Fs = sample_rate_khz * 1000;
  t = (0 : 1/Fs : duration_s - 1/Fs)';
  y = sin(2 * pi * freq_hz * t);
end

function [sp, gy] = mock_step(delay_samples, duration_s, sample_rate_khz)
  % Generate step input (setpoint) and delayed step response (gyro)
  % delay_samples - response delay in samples
  % duration_s - total duration in seconds
  % sample_rate_khz - sample rate in kHz
  Fs = sample_rate_khz * 1000;
  N = round(Fs * duration_s);
  sp = zeros(N, 1);
  gy = zeros(N, 1);
  % Step at 25% of signal
  step_start = round(N * 0.25);
  sp(step_start:end) = 500; % 500 deg/s step (above 20 deg/s threshold)
  % Delayed response with first-order dynamics
  resp_start = step_start + delay_samples;
  if resp_start <= N
    tau = round(Fs * 0.02); % 20ms time constant
    t_resp = (0 : N - resp_start)';
    gy(resp_start:end) = 500 * (1 - exp(-t_resp / tau));
  end
end

function x = mock_throttle(level, duration_s, sample_rate_khz)
  % Generate constant throttle signal
  % level - throttle percentage (0-100)
  % duration_s - duration in seconds
  % sample_rate_khz - sample rate in kHz
  Fs = sample_rate_khz * 1000;
  N = round(Fs * duration_s);
  x = ones(N, 1) * level;
end
