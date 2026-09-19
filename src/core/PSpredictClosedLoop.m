function [T, L, S, Guw] = PSpredictClosedLoop(P, A, D, F)
%% PSpredictClosedLoop - closed-loop response of the BF loop around a measured plant
%  P - plant, controller output to gyro (G_plant from PSrunChirpAnalysis)
%  A - PI response on the error        (from PSbuildController)
%  D - D response on the gyro
%  F - feedforward response on the setpoint
%
%  The loop the firmware runs is u = (A+F)*r - (A+D)*y with y = P*u, giving
%    L = P*(A+D), S = 1/(1+L), T = P*(A+F)*S, Guw = u/r = (A+F)*S
%  T./Guw is P again by construction, which is exactly how the plant was
%  measured in the first place - so Guw can be held against the logged
%  setpoint-to-axisSum response to check the controller model against a log.
%
%  All four are elementwise on the frequency grid P, A, D and F share.

P = P(:); A = A(:); D = D(:); F = F(:);

L = P .* (A + D);
S = 1 ./ (1 + L);
T = P .* (A + F) .* S;
Guw = (A + F) .* S;

% The integrator is infinite at DC, where the limits are exact: the loop
% tracks the setpoint and the controller has to invert the plant to do it.
open = ~isfinite(L);
S(open) = 0;
T(open) = 1;
Guw(open) = 1 ./ P(open);

end
