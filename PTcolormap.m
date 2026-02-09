%% PTcolormap - creates a few novel, more linear, colormap options
% this is a good place to continue improving colormaps
%
% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get colormap data without setting any figure's colormap (avoids stale colorbar errors)
try
    a=parula(64);
catch
    a=viridis(64);
end
viridis=[a(:,1) a(:,2) a(:,3)*.6];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) a couple more linear, gamma corrected, cmaps using dkl colorspace
% http://www.scholarpedia.org/article/Color_spaces

% 64 steps from -1 to 1, DKL color range
i=.01:1/64:1;%half
i2=-1:1/31.9:1;%full

% DKL 'red' white bg
for j=1:64,
    linearREDcmap(j,:)=dkl2rgb([-i2(j) i(j) 0])/255;
end
% DKL 'grey' white bg
for j=1:64,
    linearGREYcmap(j,:)=dkl2rgb([-i2(j) 0 0])/255;
end
