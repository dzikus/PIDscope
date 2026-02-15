function [P] = PSPercent(X) 
% converts raw RCcommand to percent    
    rcCommandf = abs(X);  
    P = ((rcCommandf-0) / (500)) * 100;
end


