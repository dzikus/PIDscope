function [idx_start, idx_end] = PSfindChirpWindow(sinarg_raw, gyro, varThresh)
%% PSfindChirpWindow - find evaluation window where chirp was active
%  sinarg_raw - debug_0_ column (sinarg * 5000)
%  gyro       - gyro data for the chirp axis
%  varThresh  - minimum gyro variance to accept window (default 500)

if nargin < 3, varThresh = 500; end

sinarg = sinarg_raw / 5000;
active = sinarg > 0.01 & sinarg < max(sinarg) * 0.99;

% find contiguous active regions
d = diff([0; active(:); 0]);
starts = find(d > 0.5);
ends = find(d < -0.5) - 1;

if isempty(starts)
    idx_start = 1; idx_end = length(sinarg);
    return
end

% pick longest window with sufficient gyro variance
best_len = 0;
idx_start = starts(1);
idx_end = ends(1);
for k = 1:length(starts)
    seg_len = ends(k) - starts(k) + 1;
    if seg_len < 100, continue; end
    gvar = var(gyro(starts(k):ends(k)));
    if gvar > varThresh && seg_len > best_len
        best_len = seg_len;
        idx_start = starts(k);
        idx_end = ends(k);
    end
end

end
