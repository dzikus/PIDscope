% test_PSsliderToolMath.m — verify PTB and BF slider math formulas

%!function [rP,rI,rD, pP,pI,pD, yP,yI,yD] = ptb_calc(P0,I0,D0,yawD0, pd,pir,rpr,ywr,mst)
%!  rP = P0 * mst;
%!  rI = I0 * pir * mst;
%!  rD = D0 * pd * mst;
%!  pP = rP * rpr;
%!  pI = rI * rpr;
%!  pD = rD * rpr;
%!  yP = P0 * mst * ywr;
%!  yI = I0 * mst * ywr;
%!  yD = yawD0 * pd * mst * ywr;
%!endfunction

%!function [rP,rI,rD, pP,pI,pD, yP,yI,yD] = bf_calc(P0,I0,D0,yawD0, dg,pig,rpr,ywr,mst)
%!  rP = P0 * pig * mst;
%!  rI = I0 * pig * mst;
%!  rD = D0 * dg * mst;
%!  pP = rP * rpr;
%!  pI = rI * rpr;
%!  pD = rD * rpr;
%!  yP = rP * ywr;
%!  yI = rI * ywr;
%!  yD = yawD0 * dg * mst * ywr;
%!endfunction

%!test
%! % PTB: PD=0.75, all others default — only D changes
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = ptb_calc(4,0.05,15,2, 0.75,1.00,1.00,1.00,1.00);
%! assert(rP, 4, 0.01);
%! assert(rI, 0.050, 0.001);
%! assert(rD, 11.25, 0.01);
%! assert(pP, 4, 0.01);
%! assert(pI, 0.050, 0.001);
%! assert(pD, 11.25, 0.01);
%! assert(yP, 4, 0.01);
%! assert(yI, 0.050, 0.001);
%! assert(yD, 1.50, 0.01);

%!test
%! % PTB: PD=1.35, PI=0.90 — Yaw I = 0.050 (PI ratio excluded from Yaw)
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = ptb_calc(4,0.05,15,2, 1.35,0.90,1.00,1.00,1.00);
%! assert(rP, 4, 0.01);
%! assert(rI, 0.045, 0.001);
%! assert(rD, 20.25, 0.01);
%! assert(yI, 0.050, 0.001);
%! assert(yD, 2.70, 0.01);

%!test
%! % PTB: PD=1.35, PI=1.20, RP=1.40 — Pitch P round(5.6)=6
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = ptb_calc(4,0.05,15,2, 1.35,1.20,1.40,1.00,1.00);
%! assert(rP, 4, 0.01);
%! assert(rI, 0.060, 0.001);
%! assert(round(pP), 6);
%! assert(pI, 0.084, 0.001);
%! assert(pD, 28.35, 0.01);
%! assert(yI, 0.050, 0.001);

%!test
%! % PTB: all sliders non-default — P rounding: 5.4→5, 7.02→7, 7.29→7
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = ptb_calc(4,0.05,15,2, 1.35,1.20,1.30,1.35,1.35);
%! assert(round(rP), 5);
%! assert(rI, 0.081, 0.001);
%! assert(rD, 27.34, 0.02);
%! assert(round(pP), 7);
%! assert(pI, 0.105, 0.002);
%! assert(pD, 35.54, 0.02);
%! assert(round(yP), 7);
%! assert(yI, 0.091, 0.001);
%! assert(yD, 4.92, 0.02);

%!test
%! % PTB: PD=1.35, PI=1.20, RP=1.30, Yaw=1.05, Master=1.45
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = ptb_calc(4,0.05,15,2, 1.35,1.20,1.30,1.05,1.45);
%! assert(round(rP), 6);
%! assert(rI, 0.087, 0.001);
%! assert(rD, 29.36, 0.02);
%! assert(round(pP), 8);
%! assert(pI, 0.113, 0.002);
%! assert(pD, 38.17, 0.02);
%! assert(round(yP), 6);
%! assert(yI, 0.076, 0.001);
%! assert(yD, 4.11, 0.02);

%!test
%! % BF: PI Gain=0.90 scales P AND I together, Yaw I follows PI Gain
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = bf_calc(4,0.05,15,2, 1.35,0.90,1.00,1.00,1.00);
%! assert(rP, 3.6, 0.01);
%! assert(rI, 0.045, 0.001);
%! assert(rD, 20.25, 0.01);
%! assert(yI, 0.045, 0.001);

%!test
%! % BF: full combination — PD=1.35, PI=1.20, RP=1.30, Yaw=1.05, Master=1.45
%! [rP,rI,rD,pP,pI,pD,yP,yI,yD] = bf_calc(4,0.05,15,2, 1.35,1.20,1.30,1.05,1.45);
%! assert(rP, 6.96, 0.01);
%! assert(rI, 0.087, 0.001);
%! assert(rD, 29.3625, 0.01);
%! assert(pP, 9.048, 0.01);
%! assert(yI, 0.09135, 0.001);
