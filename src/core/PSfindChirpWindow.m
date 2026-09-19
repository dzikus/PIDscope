function [idx_start, idx_end] = PSfindChirpWindow(sinarg_raw, gyro, varThresh)
%% PSfindChirpWindow - find evaluation window where chirp was active
%  sinarg_raw - debug_0_ column (sinarg * 5000)
%  gyro       - gyro data for the chirp axis
%  varThresh  - minimum gyro variance to accept window (default 500)

if nargin < 3, varThresh = 500; end

w = PSchirpWindows(sinarg_raw, gyro);

if isempty(w)
    idx_start = 1; idx_end = length(sinarg_raw);
    return
end

% Every run in a log lasts chirp_time_seconds, so run length differs only by
% sampling noise and says nothing about which axis a run swept - the response
% does. Cross-axis coupling on a real log reaches 1e3, which clears varThresh,
% so the threshold only answers "was this axis swept at all".
best_var = 0;
idx_start = w(1).i0;
idx_end = w(1).i1;
for k = 1:numel(w)
    if w(k).nSamp < 100, continue; end
    if w(k).gyroVar > varThresh && w(k).gyroVar > best_var
        best_var = w(k).gyroVar;
        idx_start = w(k).i0;
        idx_end = w(k).i1;
    end
end

end
