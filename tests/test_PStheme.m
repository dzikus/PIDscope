% test_PStheme.m - tests for the theme constants

%!test
%! % A toolkit with no display reports ScreenSize [1 1 1 1], and round(1*.011)
%! % is zero. uipanel refuses any FontSize <= 0, so the control panel fails to
%! % build and PIDscope dies at startup.
%! th = PStheme(1);
%! assert(th.fontsz >= 8, 'font size must stay usable on a degenerate display');
%! th = PStheme(0);
%! assert(th.fontsz >= 8);

%!test
%! % and it still tracks screen height where there is one
%! small = PStheme(1080);
%! big = PStheme(2160);
%! assert(big.fontsz > small.fontsz, 'font size must scale with screen height');
%! assert(small.fontsz >= 8 && big.fontsz <= 40);

%!test
%! % no argument still reads the screen
%! th = PStheme();
%! assert(th.fontsz >= 8);
