function [idx_start, idx_end] = PSfindChirpWindow(sinarg_raw, gyro, varThresh)
%% PSfindChirpWindow - find evaluation window where chirp was active
%  sinarg_raw - debug_0_ column (sinarg * 5000)
%  gyro       - gyro data for the chirp axis
%  varThresh  - minimum gyro variance to accept window (default 500)

if nargin < 3, varThresh = 500; end

sinarg_raw = sinarg_raw(:);

% sinarg is a phase wrapping through [0, 2*pi], so it passes near zero on every
% cycle - hundreds of times a second at the top of the sweep. Only a real gap
% between runs separates two windows, not a wrap or a sample landing on one.
maxGap = 50;
act = find(sinarg_raw ~= 0);

if isempty(act)
    idx_start = 1; idx_end = length(sinarg_raw);
    return
end

brk = find(diff(act) > maxGap);
starts = act([1; brk+1]);
ends = act([brk; numel(act)]);

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
