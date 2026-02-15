function [headerFile, csvFile] = PSquicJson2csv(jsonFile)
%% PSquicJson2csv - Convert QuickSilver JSON blackbox export to CSV
%
% Reads JSON exported by BossHobby Configurator ("QUIC download") and
% produces CSV + synthetic header compatible with PSimport/PSload pipeline.
%
% Unit conversions applied:
%   gyro/setpoint RPY: rad/s -> deg/s (multiply by 180/pi)
%   yaw: negated (QS convention opposite to BF)
%   motor: 0-1 range -> 0-2000 (BF scale, PSload does /2000*100)
%   PID terms: divided by 1000 (stored as int16*1000)
%   throttle setpoint: 0-1 -> 0-1000 (BF scale)
%
% [headerFile, csvFile] = PSquicJson2csv(jsonFile)

  RAD2DEG = 180 / pi;

  % Read and parse JSON
  jsonText = fileread(jsonFile);
  data = jsondecode(jsonText);

  % Extract metadata
  if isfield(data, 'looptime')
    looptime_us = data.looptime;
  else
    looptime_us = 125;  % default 8kHz
  end
  if isfield(data, 'blackbox_rate')
    bb_rate = data.blackbox_rate;
  else
    bb_rate = 1;
  end

  % Get field list
  if iscell(data.fields)
    fields = data.fields;
  else
    fields = cellstr(data.fields);
  end

  % Get entries
  entries = data.entries;
  if ~iscell(entries)
    % If jsondecode made it a matrix (unlikely for mixed types), convert
    entries = num2cell(entries, 2);
  end
  nEntries = numel(entries);

  % Initialize output arrays
  loopIter   = zeros(nEntries, 1);
  time_us    = zeros(nEntries, 1);
  gyro       = zeros(nEntries, 3);  % RPY filtered
  gyro_raw   = zeros(nEntries, 3);  % RPY raw
  setpt      = zeros(nEntries, 4);  % RPY + throttle
  axisP      = zeros(nEntries, 3);
  axisI      = zeros(nEntries, 3);
  axisD      = zeros(nEntries, 3);
  motors     = zeros(nEntries, 4);
  rx_cmd     = zeros(nEntries, 4);
  dbg        = zeros(nEntries, 4);

  % Parse entries - each entry is ordered by fields list
  for i = 1:nEntries
    entry = entries{i};
    if ~iscell(entry)
      entry = num2cell(entry);
    end

    col = 0;
    for f = 1:numel(fields)
      col = col + 1;
      if col > numel(entry), break; end
      val = entry{col};
      if iscell(val), val = cell2mat(val); end

      switch fields{f}
        case 'loop'
          loopIter(i) = val;
        case 'time'
          time_us(i) = val;
        case 'pid_p_term'
          axisP(i, 1:min(3,numel(val))) = val(1:min(3,numel(val))) / 1000;
        case 'pid_i_term'
          axisI(i, 1:min(3,numel(val))) = val(1:min(3,numel(val))) / 1000;
        case 'pid_d_term'
          axisD(i, 1:min(3,numel(val))) = val(1:min(3,numel(val))) / 1000;
        case 'rx'
          rx_cmd(i, 1:min(4,numel(val))) = val(1:min(4,numel(val))) / 1000;
        case 'setpoint'
          n = min(4, numel(val));
          sp = val(1:n) / 1000;
          % RPY: rad/s -> deg/s, negate yaw
          if n >= 1, sp(1) = sp(1) * RAD2DEG; end
          if n >= 2, sp(2) = sp(2) * RAD2DEG; end
          if n >= 3, sp(3) = -sp(3) * RAD2DEG; end  % negate yaw
          % Throttle: 0-1 -> 0-1000
          if n >= 4, sp(4) = sp(4) * 1000; end
          setpt(i, 1:n) = sp;
        case 'gyro_filter'
          n = min(3, numel(val));
          g = val(1:n) / 1000 * RAD2DEG;
          if n >= 3, g(3) = -g(3); end  % negate yaw
          gyro(i, 1:n) = g;
        case 'gyro_raw'
          n = min(3, numel(val));
          g = val(1:n) / 1000 * RAD2DEG;
          if n >= 3, g(3) = -g(3); end  % negate yaw
          gyro_raw(i, 1:n) = g;
        case 'motor'
          n = min(4, numel(val));
          % 0-1 range * 1000 -> 0-2000 (BF scale)
          motors(i, 1:n) = val(1:n) / 1000 * 2000;
        case 'accel_raw'
          % not used by PIDscope, skip
        case 'accel_filter'
          % not used by PIDscope, skip
        case 'cpu_load'
          % not used by PIDscope, skip
        case 'debug'
          n = min(4, numel(val));
          dbg(i, 1:n) = val(1:n);
      end
    end
  end

  % If no gyro_filter but have gyro_raw, use raw as filtered
  if all(gyro(:) == 0) && any(gyro_raw(:) ~= 0)
    gyro = gyro_raw;
  end

  % Build CSV output
  [fdir, fname, ~] = fileparts(jsonFile);
  csvFile = fullfile(fdir, [fname '.01.csv']);

  % Column names matching blackbox_decode output
  header = 'loopIteration,time (us),axisP[0],axisP[1],axisP[2],axisI[0],axisI[1],axisI[2],axisD[0],axisD[1],axisD[2],gyroADC[0],gyroADC[1],gyroADC[2],rcCommand[0],rcCommand[1],rcCommand[2],rcCommand[3],setpoint[0],setpoint[1],setpoint[2],setpoint[3],motor[0],motor[1],motor[2],motor[3],debug[0],debug[1],debug[2],debug[3]';

  % Build data matrix
  M = [loopIter, time_us, axisP, axisI, axisD, gyro, rx_cmd, setpt, motors, dbg];

  % Write CSV
  fid = fopen(csvFile, 'w');
  fprintf(fid, '%s\n', header);
  fclose(fid);
  dlmwrite(csvFile, M, '-append', 'delimiter', ',', 'precision', '%.6g');

  % Write synthetic header file (mimics BBL header for PSimport)
  headerFile = fullfile(fdir, [fname '.quic_header.txt']);
  fid = fopen(headerFile, 'w');
  fprintf(fid, 'H Firmware version:QuickSilver\n');
  fprintf(fid, 'H Firmware revision:QUICKSILVER\n');
  fprintf(fid, 'H looptime:%d\n', round(looptime_us));
  fprintf(fid, 'H rollPID:0, 0, 0\n');
  fprintf(fid, 'H pitchPID:0, 0, 0\n');
  fprintf(fid, 'H yawPID:0, 0, 0\n');
  fprintf(fid, 'H d_min:0, 0, 0\n');
  fprintf(fid, 'H feedforward_weight:0, 0, 0\n');
  fprintf(fid, 'H debug_mode:0\n');
  fclose(fid);

end
