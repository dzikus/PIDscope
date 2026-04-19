function [T_out, SetupInfo, lograte_kHz] = PSarduConvert(data, parms)
%% PSarduConvert - convert ArduPilot data struct to PIDscope T{} format
%  [T_out, SetupInfo, lograte_kHz] = PSarduConvert(data, parms)
%  data:  struct from PSarduRead (data.RATE, data.PIDR, etc.)
%  parms: struct from PSarduRead (parameter name→value)

if ~isfield(data, 'RATE')
    error('No RATE messages in log - enable LOG_BITMASK bit 1 (ATTITUDE_FAST)');
end

% Older AP firmware (pre-2017) used TimeMS instead of TimeUS
msgNames = fieldnames(data);
for mi = 1:numel(msgNames)
    m = data.(msgNames{mi});
    if isstruct(m) && ~isfield(m, 'TimeUS') && isfield(m, 'TimeMS')
        m.TimeUS = double(m.TimeMS) * 1000;
        data.(msgNames{mi}) = m;
    end
end

rate = data.RATE;
N = length(rate.TimeUS);

T_out = struct();
T_out.loopIteration = (1:N)';
T_out.time_us_ = rate.TimeUS(:);

% gyro from RATE (already deg/s)
T_out.gyroADC_0_ = rate.R(:);
T_out.gyroADC_1_ = rate.P(:);
T_out.gyroADC_2_ = rate.Y(:);

% setpoint from RATE
T_out.setpoint_0_ = rate.RDes(:);
T_out.setpoint_1_ = rate.PDes(:);
T_out.setpoint_2_ = rate.YDes(:);

% throttle from RCIN.C3 or RATE.AOut
if isfield(data, 'RCIN') && isfield(data.RCIN, 'C3')
    T_out.setpoint_3_ = interp1(data.RCIN.TimeUS, (data.RCIN.C3 - 1000) / 10, ...
        rate.TimeUS, 'linear', 'extrap');
    T_out.setpoint_3_ = T_out.setpoint_3_(:);
elseif isfield(rate, 'AOut')
    T_out.setpoint_3_ = rate.AOut(:) * 100;
else
    T_out.setpoint_3_ = zeros(N, 1);
end

% PID terms - interpolate to RATE timestamps
axes_map = {'PIDR', '0'; 'PIDP', '1'; 'PIDY', '2'};
for ax = 1:3
    msgName = axes_map{ax, 1};
    axStr = axes_map{ax, 2};
    if ~isfield(data, msgName), continue; end
    pid = data.(msgName);
    tPID = pid.TimeUS(:);
    tR = rate.TimeUS(:);
    if isfield(pid, 'P')
        T_out.(['axisP_' axStr '_']) = interp1(tPID, pid.P(:), tR, 'linear', 'extrap');
    end
    if isfield(pid, 'I')
        T_out.(['axisI_' axStr '_']) = interp1(tPID, pid.I(:), tR, 'linear', 'extrap');
    end
    if isfield(pid, 'D')
        T_out.(['axisD_' axStr '_']) = interp1(tPID, pid.D(:), tR, 'linear', 'extrap');
    end
    if isfield(pid, 'FF')
        T_out.(['axisF_' axStr '_']) = interp1(tPID, pid.FF(:), tR, 'linear', 'extrap');
    end
end

% motor outputs from RCOU (PWM → percentage)
% ArduPilot: SERVOx_FUNCTION 33-36 = Motor1-4. Find which channels.
if isfield(data, 'RCOU')
    rcou = data.RCOU;
    tRC = rcou.TimeUS(:);
    tR = rate.TimeUS(:);
    motorChans = zeros(1, 8);
    for ch = 1:14
        pname = sprintf('SERVO%d_FUNCTION', ch);
        pname = regexprep(pname, '[^a-zA-Z0-9_]', '_');
        if isfield(parms, pname)
            fn = parms.(pname);
            if fn >= 33 && fn <= 40
                motorChans(fn - 32) = ch;
            end
        end
    end
    % fallback: if no SERVO params, try C1-C4 then C9-C12
    if all(motorChans(1:4) == 0)
        for ch = [1:4, 9:12]
            col = sprintf('C%d', ch);
            if isfield(rcou, col) && max(rcou.(col)) > 900
                idx = find(motorChans == 0, 1);
                if ~isempty(idx), motorChans(idx) = ch; end
            end
        end
    end
    pwmMin = getparm(parms, 'MOT_PWM_MIN', 1000);
    pwmMax = getparm(parms, 'MOT_PWM_MAX', 2000);
    for m = 0:7
        ch = motorChans(m+1);
        if ch == 0, continue; end
        col = sprintf('C%d', ch);
        if ~isfield(rcou, col), continue; end
        pwm = interp1(tRC, rcou.(col)(:), tR, 'linear', 'extrap');
        T_out.(sprintf('motor_%d_', m)) = (pwm - pwmMin) / (pwmMax - pwmMin) * 100;
    end
end

% debug fields (empty - ArduPilot doesn't use BF debug channels)
for k = 0:3
    T_out.(sprintf('debug_%d_', k)) = zeros(N, 1);
end

% SIDD chirp data → debug_0_ (for chirp analysis compatibility)
if isfield(data, 'SIDD') && isfield(data.SIDD, 'F')
    sidd = data.SIDD;
    % store excitation signal in debug_1_, instantaneous freq in debug_2_
    T_out.sidd_Targ = interp1(sidd.TimeUS(:), sidd.Targ(:), rate.TimeUS, 'linear', 'extrap');
    T_out.sidd_F = interp1(sidd.TimeUS(:), sidd.F(:), rate.TimeUS, 'linear', 'extrap');
    T_out.sidd_Gx = interp1(sidd.TimeUS(:), sidd.Gx(:), rate.TimeUS, 'linear', 'extrap');
    T_out.sidd_Gy = interp1(sidd.TimeUS(:), sidd.Gy(:), rate.TimeUS, 'linear', 'extrap');
    T_out.sidd_Gz = interp1(sidd.TimeUS(:), sidd.Gz(:), rate.TimeUS, 'linear', 'extrap');
end

% log rate
dt = median(diff(rate.TimeUS)) / 1e6;
lograte_kHz = round((1/dt) / 100) / 10;  % round to 0.1 kHz

% build SetupInfo cell array (mimic BF header format for compatibility)
SetupInfo = {};
n = 1;

SetupInfo{n,1} = 'Firmware revision'; SetupInfo{n,2} = 'ArduPilot'; n = n+1;

% extract PID gains from PARM
pid_params = { ...
    'ATC_RAT_RLL_P', 'ATC_RAT_RLL_I', 'ATC_RAT_RLL_D', ...
    'ATC_RAT_PIT_P', 'ATC_RAT_PIT_I', 'ATC_RAT_PIT_D', ...
    'ATC_RAT_YAW_P', 'ATC_RAT_YAW_I', 'ATC_RAT_YAW_D'};

rP = getparm(parms, 'ATC_RAT_RLL_P', 0);
rI = getparm(parms, 'ATC_RAT_RLL_I', 0);
rD = getparm(parms, 'ATC_RAT_RLL_D', 0);
pP = getparm(parms, 'ATC_RAT_PIT_P', 0);
pI = getparm(parms, 'ATC_RAT_PIT_I', 0);
pD = getparm(parms, 'ATC_RAT_PIT_D', 0);
yP = getparm(parms, 'ATC_RAT_YAW_P', 0);
yI = getparm(parms, 'ATC_RAT_YAW_I', 0);
yD = getparm(parms, 'ATC_RAT_YAW_D', 0);

% BF-compatible format: "P,I,D"
SetupInfo{n,1} = 'rollPID'; SetupInfo{n,2} = sprintf('%.4f,%.4f,%.4f', rP, rI, rD); n = n+1;
SetupInfo{n,1} = 'pitchPID'; SetupInfo{n,2} = sprintf('%.4f,%.4f,%.4f', pP, pI, pD); n = n+1;
SetupInfo{n,1} = 'yawPID'; SetupInfo{n,2} = sprintf('%.4f,%.4f,%.4f', yP, yI, yD); n = n+1;

% d_min / feedforward_weight expected by PSload
rFF = getparm(parms, 'ATC_RAT_RLL_FF', 0);
pFF = getparm(parms, 'ATC_RAT_PIT_FF', 0);
yFF = getparm(parms, 'ATC_RAT_YAW_FF', 0);
SetupInfo{n,1} = 'd_min'; SetupInfo{n,2} = sprintf('0,0,0'); n = n+1;
SetupInfo{n,1} = 'feedforward_weight'; SetupInfo{n,2} = sprintf('%.0f,%.0f,%.0f', rFF*100, pFF*100, yFF*100); n = n+1;

% debug_mode - ArduPilot doesn't have BF debug modes
SetupInfo{n,1} = 'debug_mode'; SetupInfo{n,2} = '0'; n = n+1;

% looptime
looptime_us = median(diff(rate.TimeUS));
SetupInfo{n,1} = 'looptime'; SetupInfo{n,2} = sprintf('%.0f', looptime_us); n = n+1;

% gyro/dterm filter params (if available)
filt_params = {'INS_GYRO_FILTER', 'ATC_RAT_RLL_FLTE', 'ATC_RAT_RLL_FLTD', ...
    'INS_HNTCH_ENABLE', 'INS_HNTCH_FREQ', 'INS_HNTCH_BW', ...
    'INS_HNTC2_ENABLE', 'INS_HNTC2_FREQ', 'INS_HNTC2_BW', ...
    'SCHED_LOOP_RATE', 'LOG_BITMASK'};
for fp = filt_params
    v = getparm(parms, fp{1}, []);
    if ~isempty(v)
        SetupInfo{n,1} = fp{1}; SetupInfo{n,2} = sprintf('%g', v); n = n+1;
    end
end

% SID params
sid_params = {'SID_AXIS', 'SID_MAGNITUDE', 'SID_F_START_HZ', 'SID_F_STOP_HZ', 'SID_T_REC'};
for sp = sid_params
    v = getparm(parms, sp{1}, []);
    if ~isempty(v)
        SetupInfo{n,1} = sp{1}; SetupInfo{n,2} = sprintf('%g', v); n = n+1;
    end
end

end


function v = getparm(parms, name, default)
    name = regexprep(name, '[^a-zA-Z0-9_]', '_');
    if isfield(parms, name)
        v = parms.(name);
    else
        v = default;
    end
end
