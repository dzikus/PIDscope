% test_PSarduRead.m - tests for ArduPilot DataFlash binary parser

%!test
%! % Synthetic .bin with FMT + RATE messages
%! tmpfile = [tempname() '.bin'];
%! fid = fopen(tmpfile, 'wb', 'ieee-le');
%!
%! % Write FMT message for FMT itself (type 128)
%! header = uint8([0xA3, 0x95, 128]);
%! fwrite(fid, header, 'uint8');
%! fwrite(fid, uint8(128), 'uint8');  % type
%! fwrite(fid, uint8(89), 'uint8');   % length
%! name = uint8([70 77 84 0]);        % 'FMT\0'
%! fwrite(fid, name, 'uint8');
%! fmt_str = uint8(zeros(1,16)); fmt_str(1:5) = 'BBnNZ';
%! fwrite(fid, fmt_str, 'uint8');
%! labels = uint8(zeros(1,64)); lbl='Type,Length,Name,Format,Columns';
%! labels(1:length(lbl)) = lbl;
%! fwrite(fid, labels, 'uint8');
%!
%! % Write FMT for RATE (type 10): Qff = 3 fields, 16 bytes total (3+8+4+4=19... need proper calc)
%! % Simplified: just Q + 2 floats for RDes, R (enough to test parsing)
%! rate_fmt = 'Qff';
%! rate_labels = 'TimeUS,RDes,R';
%! rate_len = 3 + 8 + 4 + 4;  % header + Q + f + f = 19
%! fwrite(fid, uint8([0xA3, 0x95, 128]), 'uint8');
%! fwrite(fid, uint8(10), 'uint8');       % type=10 for RATE
%! fwrite(fid, uint8(rate_len), 'uint8'); % length
%! rname = uint8([82 65 84 69]);          % 'RATE'
%! fwrite(fid, rname, 'uint8');
%! rf = uint8(zeros(1,16)); rf(1:length(rate_fmt)) = rate_fmt;
%! fwrite(fid, rf, 'uint8');
%! rl = uint8(zeros(1,64)); rl(1:length(rate_labels)) = rate_labels;
%! fwrite(fid, rl, 'uint8');
%!
%! % Write 5 RATE messages
%! for k = 1:5
%!     fwrite(fid, uint8([0xA3, 0x95, 10]), 'uint8');
%!     fwrite(fid, uint64((k-1)*2500), 'uint64');   % TimeUS
%!     fwrite(fid, single(100.0 + k), 'float32');    % RDes
%!     fwrite(fid, single(99.0 + k), 'float32');     % R
%! end
%! fclose(fid);
%!
%! [data, parms] = PSarduRead(tmpfile);
%! delete(tmpfile);
%! assert(isfield(data, 'RATE'), 'should have RATE messages');
%! assert(length(data.RATE.TimeUS), 5, 'should have 5 RATE messages');
%! assert(data.RATE.RDes(1), 101, 1e-3);
%! assert(data.RATE.R(3), 102, 1e-3);

%!test
%! % Verify format code sizes: c, e, L scalings
%! tmpfile = [tempname() '.bin'];
%! fid = fopen(tmpfile, 'wb', 'ieee-le');
%!
%! % FMT for FMT
%! fwrite(fid, uint8([0xA3, 0x95, 128]), 'uint8');
%! fwrite(fid, uint8(128), 'uint8'); fwrite(fid, uint8(89), 'uint8');
%! name = uint8([70 77 84 0]); fwrite(fid, name, 'uint8');
%! fmt_str = uint8(zeros(1,16)); fmt_str(1:5) = 'BBnNZ'; fwrite(fid, fmt_str, 'uint8');
%! labels = uint8(zeros(1,64)); lbl='Type,Length,Name,Format,Columns';
%! labels(1:length(lbl)) = lbl; fwrite(fid, labels, 'uint8');
%!
%! % FMT for PARM (type 20): QNff = 35 bytes
%! fwrite(fid, uint8([0xA3, 0x95, 128]), 'uint8');
%! fwrite(fid, uint8(20), 'uint8');
%! fwrite(fid, uint8(3+8+16+4+4), 'uint8');
%! pn = uint8([80 65 82 77]); fwrite(fid, pn, 'uint8');  % PARM
%! pf = uint8(zeros(1,16)); pf(1:4) = 'QNff'; fwrite(fid, pf, 'uint8');
%! pl = uint8(zeros(1,64)); plbl = 'TimeUS,Name,Value,Default';
%! pl(1:length(plbl)) = plbl; fwrite(fid, pl, 'uint8');
%!
%! % Write one PARM message
%! fwrite(fid, uint8([0xA3, 0x95, 20]), 'uint8');
%! fwrite(fid, uint64(1000), 'uint64');
%! pname = uint8(zeros(1,16)); pname(1:13) = 'ATC_RAT_RLL_P';
%! fwrite(fid, pname(1:16), 'uint8');
%! fwrite(fid, single(0.135), 'float32');
%! fwrite(fid, single(0.100), 'float32');
%! fclose(fid);
%!
%! [data, parms] = PSarduRead(tmpfile);
%! delete(tmpfile);
%! assert(isfield(parms, 'ATC_RAT_RLL_P'), 'should parse PARM');
%! assert(parms.ATC_RAT_RLL_P, 0.135, 1e-3);

%!test
%! % PSarduConvert: basic conversion from synthetic RATE data
%! data = struct();
%! data.RATE.TimeUS = (0:2499:24990)';  % 10 samples at 400 Hz
%! data.RATE.RDes = ones(10,1) * 50;
%! data.RATE.R = ones(10,1) * 48;
%! data.RATE.PDes = ones(10,1) * 30;
%! data.RATE.P = ones(10,1) * 29;
%! data.RATE.YDes = ones(10,1) * 10;
%! data.RATE.Y = ones(10,1) * 9;
%! data.RATE.ROut = zeros(10,1);
%! data.RATE.POut = zeros(10,1);
%! data.RATE.YOut = zeros(10,1);
%! data.RATE.AOut = ones(10,1) * 0.5;
%! data.RATE.ADes = zeros(10,1);
%! data.RATE.A = zeros(10,1);
%! data.RATE.AOutSlew = zeros(10,1);
%! parms = struct();
%! parms.ATC_RAT_RLL_P = 0.135;
%! parms.ATC_RAT_RLL_I = 0.135;
%! parms.ATC_RAT_RLL_D = 0.003;
%! parms.ATC_RAT_PIT_P = 0.135;
%! parms.ATC_RAT_PIT_I = 0.135;
%! parms.ATC_RAT_PIT_D = 0.003;
%! parms.ATC_RAT_YAW_P = 0.18;
%! parms.ATC_RAT_YAW_I = 0.018;
%! parms.ATC_RAT_YAW_D = 0.0;
%! [T, SI, lr] = PSarduConvert(data, parms);
%! assert(length(T.gyroADC_0_), 10);
%! assert(T.setpoint_0_(1), 50, 1e-3);
%! assert(T.gyroADC_1_(1), 29, 1e-3);
%! % SetupInfo should have rollPID
%! idx = find(strcmp(SI(:,1), 'rollPID'));
%! assert(~isempty(idx), 'should have rollPID in SetupInfo');
