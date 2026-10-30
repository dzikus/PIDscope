function txt = PSdatatip(obj, evt)
% datacursormode UpdateFcn, MATLAB only (Octave goes through PSdatatip_click).
% Log viewer traces get up to 6 significant digits on x so time keeps ms
% precision; below -logviewerYscale the lower panel reads in percent.
% Spectrogram images show %T, Hz and the value under the cursor.
%
% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
%

global logviewerYscale

fontsz2 = 16;
try
    a = evt.Target.Type;
    c = evt.Target.Color;
catch
end
c1 = [0.9300 0.5000 0.3000];
c2 = [0.3000 0.6500 0.9500];
p = get(evt, 'Position');

if ~strcmp(a, 'image')
    if p(1) < 100
        dgts = 5;
    else
        dgts = 6;
    end
    if p(2) > -logviewerYscale
        txt = {['x: ' num2str(p(1), dgts)], ['y: ' num2str(p(2), 4)]};
    else
        txt = {['sec: ' num2str(p(1), dgts)], ...
            ['%: ' num2str((p(2) + logviewerYscale*2) / (logviewerYscale/100), 4)]};
    end
    if c == c1 | c == c2
        txt = {['x: ' num2str(p(1), 4)], ['y: ' num2str(p(2), 4)]};
    end
    if numel(p) > 2
        txt{end+1} = ['Z: ' num2str(p(3), 4)];
    end
else
    hz = (obj.Parent.YLim(2) - p(2)) / .3;
    txt = {['%T: ' num2str(p(1), 4)], ['Hz: ' num2str(hz, 4)], ...
        ['Z: ' num2str(evt.Target.CData(p(2), p(1)), 4)]};
end
set(findall(gcf, 'type', 'hggroup'), 'FontSize', fontsz2, 'FontWeight', 'bold')
