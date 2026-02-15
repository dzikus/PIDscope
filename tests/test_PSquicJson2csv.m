%% Tests for PSquicJson2csv - QuickSilver JSON blackbox parser

%!test
%! % Create a minimal QuickSilver JSON file
%! jsonFile = [tempname() '.json'];
%! RAD2DEG = 180 / pi;
%! fid = fopen(jsonFile, 'w');
%! fprintf(fid, '{\n');
%! fprintf(fid, '  "blackbox_rate": 1,\n');
%! fprintf(fid, '  "looptime": 125.0,\n');
%! fprintf(fid, '  "fields": ["loop", "time", "gyro_filter", "setpoint", "motor"],\n');
%! fprintf(fid, '  "entries": [\n');
%! % Entry 1: loop=0, time=1000, gyro=[1000,0,0] (1 rad/s), setpoint=[500,0,0,800], motor=[500,500,500,500]
%! fprintf(fid, '    [0, 1000, [1000, 0, 0], [500, 0, 0, 800], [500, 500, 500, 500]],\n');
%! % Entry 2: loop=1, time=2000
%! fprintf(fid, '    [1, 2000, [2000, 1000, -500], [1000, 500, -250, 900], [600, 600, 600, 600]]\n');
%! fprintf(fid, '  ]\n');
%! fprintf(fid, '}\n');
%! fclose(fid);
%!
%! [headerFile, csvFile] = PSquicJson2csv(jsonFile);
%!
%! % Check files were created
%! assert(exist(csvFile, 'file') == 2);
%! assert(exist(headerFile, 'file') == 2);
%!
%! % Check CSV has correct number of rows (header + 2 data rows)
%! fid = fopen(csvFile, 'r');
%! lines = {};
%! while ~feof(fid)
%!   l = fgetl(fid);
%!   if ischar(l) && ~isempty(strtrim(l)), lines{end+1} = l; end
%! end
%! fclose(fid);
%! assert(numel(lines) >= 3, 'Expected at least 3 lines (header + 2 data)');
%!
%! % Check header file has required fields
%! hdr = fileread(headerFile);
%! assert(~isempty(strfind(hdr, 'Firmware version')));
%! assert(~isempty(strfind(hdr, 'debug_mode')));
%! assert(~isempty(strfind(hdr, 'rollPID')));
%!
%! % Read CSV with readtable and check values
%! addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src')));
%! T = readtable(csvFile);
%!
%! % Check loop counter
%! assert(T.loopIteration(1), 0);
%! assert(T.loopIteration(2), 1);
%!
%! % Check time
%! assert(T.time_us_(1), 1000);
%!
%! % Check gyro conversion: 1000 / 1000 * RAD2DEG = 57.296 deg/s
%! assert(abs(T.gyroADC_0_(1) - RAD2DEG) < 0.1, 'Gyro should be converted to deg/s');
%!
%! % Check motor conversion: 500 / 1000 * 2000 = 1000
%! assert(T.motor_0_(1), 1000);
%!
%! % Cleanup
%! delete(jsonFile);
%! delete(csvFile);
%! delete(headerFile);

%!test
%! % Test with PID terms
%! jsonFile = [tempname() '.json'];
%! fid = fopen(jsonFile, 'w');
%! fprintf(fid, '{"blackbox_rate":1,"looptime":250,"fields":["loop","time","pid_p_term","pid_i_term","pid_d_term"],"entries":[[0,100,[300,-150,50],[100,200,50],[80,40,0]]]}');
%! fclose(fid);
%!
%! [headerFile, csvFile] = PSquicJson2csv(jsonFile);
%! addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src')));
%! T = readtable(csvFile);
%!
%! % PID P: 300/1000 = 0.3
%! assert(abs(T.axisP_0_(1) - 0.3) < 0.001);
%! assert(abs(T.axisP_1_(1) - (-0.15)) < 0.001);
%!
%! delete(jsonFile); delete(csvFile); delete(headerFile);

%!test
%! % Test yaw negation on setpoint and gyro
%! jsonFile = [tempname() '.json'];
%! RAD2DEG = 180 / pi;
%! fid = fopen(jsonFile, 'w');
%! fprintf(fid, '{"blackbox_rate":1,"looptime":125,"fields":["loop","time","setpoint","gyro_filter"],"entries":[[0,100,[0,0,1000,500],[0,0,1000]]]}');
%! fclose(fid);
%!
%! [headerFile, csvFile] = PSquicJson2csv(jsonFile);
%! addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src')));
%! T = readtable(csvFile);
%!
%! % Yaw setpoint: 1000/1000 * RAD2DEG = 57.296, but NEGATED -> -57.296
%! assert(T.setpoint_2_(1) < 0, 'Yaw setpoint should be negated');
%! assert(abs(T.setpoint_2_(1) + RAD2DEG) < 0.1);
%!
%! % Yaw gyro: same negation
%! assert(T.gyroADC_2_(1) < 0, 'Yaw gyro should be negated');
%!
%! % Throttle setpoint: 500/1000 * 1000 = 500
%! assert(T.setpoint_3_(1), 500);
%!
%! delete(jsonFile); delete(csvFile); delete(headerFile);
