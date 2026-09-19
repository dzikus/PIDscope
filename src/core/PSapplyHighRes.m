function T = PSapplyHighRes(T, setupInfo)
%% PSapplyHighRes - undo blackbox high resolution scaling
%  With blackbox_high_resolution on, BF logs gyroADC, gyroUnfilt, rcCommand and
%  setpoint multiplied by 10 (blackbox.c). setpoint[3] carries the mixer throttle
%  and is written past that loop without the scale, so it is left alone.
%  blackbox_decode keeps the raw values; Blackbox Explorer divides on load and
%  this does the same, so everything downstream stays in deg/s and stick units.

scale = 1;
for k = 1:size(setupInfo, 1)
    if strcmp(strtrim(setupInfo{k,1}), 'blackbox_high_resolution')
        v = str2double(strtrim(setupInfo{k,2}));
        if ~isnan(v) && v > 0, scale = 10; end
        break
    end
end

if scale == 1, return; end

fn = fieldnames(T);
for k = 1:numel(fn)
    nm = fn{k};
    scaled = ~isempty(regexp(nm, '^(gyroADC|gyroUnfilt|rcCommand)_\d+_$', 'once')) || ...
             ~isempty(regexp(nm, '^setpoint_[0-2]_$', 'once'));
    if scaled && isnumeric(T.(nm))
        T.(nm) = T.(nm) / scale;
    end
end

end
