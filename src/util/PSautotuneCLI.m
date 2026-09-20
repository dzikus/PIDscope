function txt = PSautotuneCLI(items, pmTarget)
%% PSautotuneCLI - Betaflight CLI text for a set of autotune results
%  items     - one struct per axis with .axisName, .ok, .gains (P,I,D,F) and
%              .note (why it was refused, when it was)
%  pmTarget  - the phase margin the proposal was made for, recorded in the text
%
%  Only PID gains are ever emitted. A refused axis is named with its reason
%  rather than skipped silently, because silence reads as "nothing to change".

axKeys = struct('Roll', 'roll', 'Pitch', 'pitch', 'Yaw', 'yaw');

lines = {};
lines{end+1} = sprintf('# PIDscope autotune - phase margin target %g deg', pmTarget);
lines{end+1} = '# Verify on a test flight before trusting these in anger.';

nSet = 0;
for k = 1:numel(items)
    it = items(k);
    name = it.axisName;
    if ~isfield(axKeys, name), continue; end
    key = axKeys.(name);
    if ~it.ok
        lines{end+1} = sprintf('# %s: refused - %s', name, it.note);
        continue
    end
    lines{end+1} = sprintf('# %s', name);
    lines{end+1} = sprintf('set p_%s = %d', key, round(it.gains.P));
    lines{end+1} = sprintf('set i_%s = %d', key, round(it.gains.I));
    lines{end+1} = sprintf('set d_%s = %d', key, round(it.gains.D));
    lines{end+1} = sprintf('set f_%s = %d', key, round(it.gains.F));
    nSet = nSet + 1;
end

if nSet > 0
    lines{end+1} = 'save';
end

txt = strjoin(lines, char(10));

end
