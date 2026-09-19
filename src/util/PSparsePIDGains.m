function g = PSparsePIDGains(si, axisIdx)
%% PSparsePIDGains - PID gains for one axis out of the log header
%  si      - setupInfo cell array {param, value}
%  axisIdx - 0=Roll, 1=Pitch, 2=Yaw
%
%  Values are as entered in the firmware, not scaled - PSbuildController does
%  the scaling. dMax above D means dynamic D was active, which the controller
%  model does not cover.

axKeys = {'rollPID', 'pitchPID', 'yawPID'};
pid = hlist(si, axKeys{axisIdx + 1}, [0 0 0]);

g.P = pid(1);
g.I = pid(2);
g.D = pid(3);

ff = hlist(si, 'feedforward_weight', []);
if isempty(ff), ff = hlist(si, 'ff_weight', [0 0 0]); end
g.F = pick(ff, axisIdx + 1);

g.dMax = pick(hlist(si, 'd_max', [0 0 0]), axisIdx + 1);

end


function v = hlist(si, key, default)
    v = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            tmp = str2double(strsplit(strtrim(si{k,2}), ','));
            if ~any(isnan(tmp)), v = tmp; end
            return;
        end
    end
end


function v = pick(list, n)
    v = 0;
    if numel(list) >= n, v = list(n); end
end
