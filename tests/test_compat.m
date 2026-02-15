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
