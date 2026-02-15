function T = readtable(filename, varargin)
%% READTABLE - Octave-compatible CSV/text file reader
% Drop-in replacement for MATLAB's readtable() returning a struct
% with columns accessible via dot notation (T.colname).
%
% Copyright (C) 2026 Grzegorz Sterniczuk
% License: GPL v3 (see LICENSE)
%
% Usage:
%   T = readtable(filename)
%   T = readtable(filename, 'HeaderLines', N)
%   T = readtable(filename, 'Format', fmt)
%
% Returns a struct where each field is a column vector.
% T.Properties.VariableNames contains the column names.

  % Parse optional arguments
  headerlines = 0;
  fmt = '';
  for i = 1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    if strcmpi(key, 'HeaderLines')
      headerlines = val;
    elseif strcmpi(key, 'Format')
      fmt = val;
    end
  end

  fid = fopen(filename, 'r');
  if fid == -1
    error('readtable: cannot open file %s', filename);
  end

  % Skip header lines
  for i = 1:headerlines
    fgetl(fid);
  end

  % Read the first non-skipped line as column headers
  header_line = fgetl(fid);
  if ~ischar(header_line)
    fclose(fid);
    T = struct();
    T.Properties = struct('VariableNames', {{}});
    return;
  end

  % Parse column names from header
  col_names = strsplit(strtrim(header_line), ',');
  clean_names = sanitize_varnames(col_names);
  ncols = length(clean_names);

  % Read first data line to detect column types
  first_data_line = fgetl(fid);
  if ~ischar(first_data_line)
    fclose(fid);
    T = struct();
    for j = 1:ncols
      T.(clean_names{j}) = [];
    end
    T.Properties = struct('VariableNames', {clean_names});
    return;
  end

  % Detect which columns are numeric vs string
  is_numeric = true(1, ncols);
  first_fields = strsplit(first_data_line, ',');
  for j = 1:min(length(first_fields), ncols)
    val = strtrim(first_fields{j});
    num = str2double(val);
    % Non-numeric value, or column header contains "flags" -> force string
    if (isnan(num) && ~strcmpi(val, 'nan')) || ~isempty(regexpi(col_names{j}, 'flags'))
      is_numeric(j) = false;
    end
  end

  % Build format string based on detected types
  fmt_parts = cell(1, ncols);
  for j = 1:ncols
    if is_numeric(j)
      fmt_parts{j} = '%f';
    else
      fmt_parts{j} = '%s';
    end
  end
  fmt_str = strjoin(fmt_parts, '');

  % Rewind to start of data (skip headerlines + column header line)
  frewind(fid);
  for i = 1:(headerlines + 1)
    fgetl(fid);
  end

  % Use textscan directly on file handle - orders of magnitude faster
  % than reading lines into cells and joining them
  C = textscan(fid, fmt_str, 'Delimiter', ',', 'EmptyValue', NaN);
  fclose(fid);

  if length(C) == ncols && ~isempty(C{1})
    T = struct();
    for j = 1:ncols
      T.(clean_names{j}) = C{j};
    end
    T.Properties = struct('VariableNames', {clean_names});
    return;
  end

  % Fallback: reopen and parse line by line (slow, for edge cases)
  warning('readtable: textscan returned %d/%d columns, falling back to line-by-line', length(C), ncols);
  fid = fopen(filename, 'r');
  for i = 1:(headerlines + 1)
    fgetl(fid);
  end

  data_lines = {};
  while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
      data_lines{end+1} = line;
    end
  end
  fclose(fid);

  nrows = length(data_lines);
  string_cols = cell(nrows, ncols);
  numeric_cols = NaN(nrows, ncols);

  for i = 1:nrows
    fields = strsplit(data_lines{i}, ',');
    for j = 1:min(length(fields), ncols)
      val = strtrim(fields{j});
      num = str2double(val);
      if ~isnan(num) || strcmpi(val, 'nan')
        numeric_cols(i, j) = num;
      else
        is_numeric(j) = false;
        string_cols{i, j} = val;
      end
    end
  end

  T = struct();
  for j = 1:ncols
    if is_numeric(j)
      T.(clean_names{j}) = numeric_cols(:, j);
    else
      T.(clean_names{j}) = string_cols(:, j);
    end
  end
  T.Properties = struct('VariableNames', {clean_names});

end


function names = sanitize_varnames(raw_names)
  % Convert raw CSV header names to valid MATLAB/Octave variable names
  % Mimics MATLAB's readtable sanitization:
  %   'time (us)' -> 'time_us_'
  %   'axisP[0]'  -> 'axisP_0_'
  names = cell(size(raw_names));
  for i = 1:length(raw_names)
    s = strtrim(raw_names{i});
    % Replace brackets, spaces, parentheses with underscores
    s = regexprep(s, '[\[\]\(\) ]+', '_');
    % Replace any remaining non-alphanumeric/underscore chars
    s = regexprep(s, '[^a-zA-Z0-9_]', '_');
    % Ensure doesn't start with a number
    if ~isempty(s) && (s(1) >= '0' && s(1) <= '9')
      s = ['x' s];
    end
    % Collapse multiple underscores
    s = regexprep(s, '_+', '_');
    if isempty(s)
      s = sprintf('Var%d', i);
    end
    names{i} = s;
  end
end
