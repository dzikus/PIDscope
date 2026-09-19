function b = PSautotuneBasis(gains, fp, Fs, freq)
%% PSautotuneBasis - the whole controller family as four fixed responses
%  gains - only axis and tpa are read; the four gains are set here
%  fp    - filter params from PSparseFilterParams, or [] for no dterm filtering
%  Fs    - PID loop rate (Hz)
%  freq  - frequency vector (Hz)
%
%  Every gain enters PSbuildController as a plain scalar multiplier, so two
%  calls span the family a scan walks over:
%      A = p*b.Ap + i*b.Ai,   D = d*b.D1,   F = f*b.F1
%  A thousand-cell scan then costs two controller builds instead of a thousand.
%
%  b.freq drops DC, where the integrator is Inf and a candidate with I = 0 would
%  ask for 0*Inf. b.keep maps b.freq back onto the grid that came in.

freq = freq(:);
b.keep = freq > 0;
b.freq = freq(b.keep);

g = struct('axis', 0, 'tpa', []);
if isfield(gains, 'axis') && ~isempty(gains.axis), g.axis = gains.axis; end
if isfield(gains, 'tpa'), g.tpa = gains.tpa; end

g.P = 1; g.I = 0; g.D = 1; g.F = 1;
[Ap, b.D1, b.F1] = PSbuildController(g, fp, Fs, b.freq);
b.Ap = Ap;

g.P = 0; g.I = 1; g.D = 0; g.F = 0;
b.Ai = PSbuildController(g, fp, Fs, b.freq);

end
