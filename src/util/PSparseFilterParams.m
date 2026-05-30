function fp = PSparseFilterParams(si)
%% PSparseFilterParams - extract BF filter settings from setupInfo headers
%  BF enum: 0=PT1, 1=BIQUAD, 2=PT2, 3=PT3
%  Filter disabled when hz == 0 (not by type value)
%  Header key names differ: BF 4.3+ uses gyro_lpf1_*, BF 4.2 uses gyro_lowpass_*

fp.gyro_lpf1_type = hval(si, 'gyro_lpf1_type', hval(si, 'gyro_lowpass_type', 0));
fp.gyro_lpf1_hz = hval(si, 'gyro_lpf1_static_hz', hval(si, 'gyro_lowpass_hz', hval(si, 'gyro_lowpass_hz_roll', 0)));
fp.gyro_lpf2_type = hval(si, 'gyro_lpf2_type', hval(si, 'gyro_lowpass2_type', 0));
fp.gyro_lpf2_hz = hval(si, 'gyro_lpf2_static_hz', hval(si, 'gyro_lowpass2_hz', hval(si, 'gyro_lowpass2_hz_roll', 0)));
fp.dterm_lpf1_type = hval(si, 'dterm_lpf1_type', hval(si, 'dterm_lowpass_type', 0));
fp.dterm_lpf1_hz = hval(si, 'dterm_lpf1_static_hz', hval(si, 'dterm_lowpass_hz', hval(si, 'dterm_lowpass_hz_roll', 0)));
fp.dterm_lpf2_type = hval(si, 'dterm_lpf2_type', hval(si, 'dterm_lowpass2_type', 0));
fp.dterm_lpf2_hz = hval(si, 'dterm_lpf2_static_hz', hval(si, 'dterm_lowpass2_hz', hval(si, 'dterm_lowpass2_hz_roll', 0)));
fp.dterm_notch_hz = hval(si, 'dterm_notch_hz', 0);
fp.dterm_notch_cut = hval(si, 'dterm_notch_cutoff', 0);
tmp = hstr(si, 'gyro_notch_hz', '0,0'); v = str2double(strsplit(tmp, ','));
if any(isnan(v)), v = [0 0]; end
fp.gyro_notch1_hz = v(1);
fp.gyro_notch2_hz = 0; if numel(v) > 1, fp.gyro_notch2_hz = v(2); end
tmp = hstr(si, 'gyro_notch_cutoff', '0,0'); v = str2double(strsplit(tmp, ','));
if any(isnan(v)), v = [0 0]; end
fp.gyro_notch1_cut = v(1);
fp.gyro_notch2_cut = 0; if numel(v) > 1, fp.gyro_notch2_cut = v(2); end

% Gyro loop rate from headers (filters run at gyro rate, not logging rate)
lt = hval(si, 'looptime', 0);
if lt > 0
  fp.gyro_rate_hz = round(1e6 / lt);
else
  fp.gyro_rate_hz = 0;
end
end

function v = hval(si, key, default)
    v = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            tmp = str2double(strtrim(si{k,2}));
            if ~isnan(tmp), v = tmp; end
            return;
        end
    end
end

function s = hstr(si, key, default)
    s = default;
    for k = 1:size(si, 1)
        if strcmp(strtrim(si{k,1}), key)
            s = strtrim(si{k,2});
            return;
        end
    end
end
