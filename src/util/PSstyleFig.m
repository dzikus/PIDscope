function PSstyleFig(fig, titleStr)
%% PSstyleFig - apply dark theme to figure
th = PStheme();
set(fig, 'Color', th.figBg, 'InvertHardcopy', 'off');
if nargin >= 2, set(fig, 'Name', titleStr, 'NumberTitle', 'off'); end
end
