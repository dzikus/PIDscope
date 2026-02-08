% run_tests.m - PIDscope test runner for GNU Octave
% Usage: octave --no-gui --eval "run('tests/run_tests.m')"

fprintf('\n=== PIDscope Test Suite ===\n\n');

% Setup paths
project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(project_root);
addpath(fullfile(project_root, 'compat'));
addpath(fullfile(project_root, 'tests'));

% Load required packages
if exist('OCTAVE_VERSION', 'builtin')
  pkg load signal;
  pkg load statistics;
end

% Collect test files
test_dir = fullfile(project_root, 'tests');
test_files = dir(fullfile(test_dir, 'test_*.m'));

total_pass = 0;
total_fail = 0;
total_skip = 0;
failed_files = {};

for i = 1:length(test_files)
  fname = test_files(i).name;
  fpath = fullfile(test_dir, fname);
  fprintf('Running %s ... ', fname);
  try
    % Octave test() returns [n, nmax, nxfail, nskip]
    % n = passed, nmax = total tests
    [n, nmax, nxfail, nskip] = test(fpath, 'quiet');
    nfail = nmax - n - nxfail;
    total_pass = total_pass + n;
    total_fail = total_fail + nfail;
    total_skip = total_skip + nskip;
    if nfail > 0
      fprintf('FAIL (%d/%d passed, %d failed)\n', n, nmax, nfail);
      failed_files{end+1} = fname;
    elseif nmax == 0
      fprintf('no tests\n');
    else
      fprintf('OK (%d passed', n);
      if nskip > 0, fprintf(', %d skipped', nskip); end
      fprintf(')\n');
    end
  catch e
    fprintf('ERROR: %s\n', e.message);
    total_fail = total_fail + 1;
    failed_files{end+1} = fname;
  end
end

fprintf('\n=== Results ===\n');
fprintf('Passed: %d\n', total_pass);
fprintf('Failed: %d\n', total_fail);
fprintf('Skipped: %d\n', total_skip);

if ~isempty(failed_files)
  fprintf('\nFailed test files:\n');
  for i = 1:length(failed_files)
    fprintf('  - %s\n', failed_files{i});
  end
  fprintf('\nSOME TESTS FAILED\n');
else
  fprintf('\nALL TESTS PASSED\n');
end
