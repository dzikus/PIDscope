function PSapplySpecPreset(pv, guiHandlesSpec)
% Apply Freq x Throttle preset to SpecSelect and Sub100Hz checkboxes
if pv < 2, return; end
switch pv
    case 2,  vals = [3 2 8 7]; sub = [0 0 0 0];
    case 3,  vals = [3 2 6 7]; sub = [0 0 0 0];
    case 4,  vals = [2 7 5 4]; sub = [0 0 1 1];
    case 5,  vals = [3 2 3 2]; sub = [0 0 0 0];
    case 6,  vals = [8 7 8 7]; sub = [0 0 0 0];
    case 7,  vals = [3 3 3 3]; sub = [0 0 0 0];
    case 8,  vals = [2 2 2 2]; sub = [0 0 0 0];
    case 9,  vals = [7 7 7 7]; sub = [0 0 0 0];
    case 10, vals = [4 4 4 4]; sub = [0 0 0 0];
    otherwise, return;
end
for k = 1:4
    set(guiHandlesSpec.SpecSelect{k}, 'Value', vals(k));
    set(guiHandlesSpec.Sub100HzCheck{k}, 'Value', sub(k));
end
end
