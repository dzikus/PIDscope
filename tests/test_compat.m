% test_compat.m - Tests for compat/ shim functions

%!test
%! % smooth() - moving average with span 5
%! y = [1 2 3 4 5 6 7 8 9 10]';
%! ys = smooth(y, 5);
%! assert(length(ys), 10);
%! assert(ys(3), 3, 1e-10);  % middle of window [1,2,3,4,5] = 3
%! assert(ys(5), 5, 1e-10);  % middle of window [3,4,5,6,7] = 5

%!test
%! % smooth() - moving average preserves length
%! y = randn(100, 1);
%! ys = smooth(y, 11);
%! assert(length(ys), 100);

%!test
%! % smooth() - lowess method runs without error
%! y = sin(linspace(0, 4*pi, 100))' + 0.1*randn(100, 1);
%! ys = smooth(y, 21, 'lowess');
%! assert(length(ys), 100);

%!test
%! % nanmean() - basic mean ignoring NaN
%! x = [1 2 NaN 4 5];
%! assert(nanmean(x), 3, 1e-10);

%!test
%! % nanmean() - column-wise with dim=1
%! x = [1 2; NaN 4; 3 6];
%! m = nanmean(x, 1);
%! assert(m(1), 2, 1e-10);
%! assert(m(2), 4, 1e-10);

%!test
%! % nanmedian() - basic median ignoring NaN
%! x = [1 NaN 3 4 5];
%! assert(nanmedian(x), 3.5, 1e-10);

%!test
%! % finddelay() - detect known delay
%! x = [zeros(1,10) ones(1,90)]';
%! y = [zeros(1,15) ones(1,85)]';  % delayed by 5 samples
%! d = finddelay(x, y, 20);
%! assert(abs(d), 5, 2);  % allow +-2 sample tolerance

%!test
%! % contains() - string matching
%! assert(contains('hello world', 'world'));
%! assert(!contains('hello world', 'foo'));

%!test
%! % contains() - cell array
%! c = {'alpha', 'beta', 'gamma'};
%! result = contains(c, 'bet');
%! assert(result, [false true false]);

%!test
%! % contains() - case insensitive
%! assert(contains('Hello', 'hello', 'IgnoreCase', true));

%!test
%! % kstest2() - samples from clearly different distributions
%! a = [0.1 0.5 0.3 0.9 0.2 0.7 0.44 0.61 0.15 0.83];
%! b = [1.1 1.5 0.95 2.0 1.2 1.7 1.44 1.61 1.05 1.83];
%! [h, p] = kstest2(a, b);
%! assert(h, true);
%! assert(p, 1.88797936571626e-05, 1e-15);

%!test
%! % kstest2() - samples that track each other closely
%! c = [1 2 3 4 5 6 7 8];
%! d = [1.2 2.1 3.3 3.9 5.2 5.8 7.1 8.3];
%! [h, p] = kstest2(c, d);
%! assert(h, false);
%! assert(p, 0.999999479887226, 1e-12);

%!test
%! % kstest2() - alpha controls the reject decision
%! a = [0.1 0.5 0.3 0.9 0.2 0.7 0.44 0.61 0.15 0.83];
%! b = [1.1 1.5 0.95 2.0 1.2 1.7 1.44 1.61 1.05 1.83];
%! assert(kstest2(a, b, 0.01), true);
%! assert(kstest2([1 2 3 4], [1.1 2.1 3.1 4.1], 0.01), false);

%!test
%! % kstest2() - p-values across lambda 0.24..1.44, taken from the 101-term
%! % series the shim summed first, so rewriting the series cannot move them.
%! % Shifting b by k - 0.5 makes D exactly k/10.
%! a = 1:10;
%! expected = [0.9999999942894181 0.97478924654099508 0.67507815371659508 ...
%!             0.31285267601695582 0.11084033741322809 0.031046781145641307];
%! for k = 1:6
%!   [~, p, d] = kstest2(a, (1:10) + k - 0.5);
%!   assert(d, k/10, 1e-15);
%!   assert(p, expected(k), 1e-14);
%! end

%!test
%! % kstest2() - tied values across both samples, D checked against the
%! % ECDF difference taken directly at every distinct value
%! x1 = [1 2 2 3 3 3];
%! x2 = [2 3 3 4 4 5 1];
%! [h, p, d] = kstest2(x1, x2);
%! assert(d, 3/7, 1e-15);
%! assert(p, 0.46838502154475359, 1e-14);
%! assert(h, false);

%!test
%! % fspecial() - gaussian column kernel, values from the image package
%! f = fspecial('gaussian', [5 1], 4);
%! assert(size(f), [5 1]);
%! assert(sum(f(:)), 1, 1e-14);
%! assert(f(1), 0.18762716195139, 1e-14);
%! assert(f(3), 0.212609428318537, 1e-14);
%! assert(f(1), f(5), 1e-14);

%!test
%! % fspecial() - non-square gaussian normalises to unit sum
%! f = fspecial('gaussian', [10 2], 4);
%! assert(size(f), [10 2]);
%! assert(sum(f(:)), 1, 1e-14);
%! assert(f(1), 0.0335293399098535, 1e-14);

%!test
%! % fspecial() - scalar size gives a square kernel
%! f = fspecial('gaussian', 5, 4);
%! assert(size(f), [5 5]);
%! assert(sum(f(:)), 1, 1e-14);
