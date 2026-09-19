function PSrunChirpAnalysis(T, setupInfo, debugIdx, Fs, tIND, axisIdx)
%% PSrunChirpAnalysis - extract chirp data and run frequency response analysis
%  T          - data struct for one file
%  setupInfo  - header cell array {param, value}
%  debugIdx   - debug mode indices struct
%  Fs         - sample rate (Hz)
%  tIND       - logical time index mask
%  axisIdx    - 0=Roll, 1=Pitch, 2=Yaw

id = PSidentifyChirp(T, setupInfo, Fs, tIND, axisIdx);

if ~id.ok
    warndlg(id.msg);
    return
end

fprintf('Chirp window: samples %d-%d (%d samples, %.1f s)\n', ...
    id.i0, id.i1, id.nSamp, id.nSamp / Fs);

stepData = struct();
try
    [stepData.t_ms, stepData.step] = PSstepFromFRD(id.freq, id.G_track, 300);
catch
    stepData = [];
end

pred = [];
if ~isempty(id.G_plant) && ~isempty(id.gains)
    pred = struct('gains', id.gains, 'fp', id.fp, 'FsPid', id.FsPid, 'Fref', id.G_ff);
end

PSplotBode(id.freq, id.G_track, id.G_plant, id.C_track, stepData, id.axisName, pred);

end
