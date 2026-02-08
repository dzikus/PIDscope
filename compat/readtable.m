function T = readtable(filename, varargin)
%% READTABLE - Octave-compatible CSV/text file reader
% Drop-in replacement for MATLAB's readtable() returning a struct
% with columns accessible via dot notation (T.colname).
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
  % Sanitize column names for use as struct field names
  clean_names = sanitize_varnames(col_names);
  ncols = length(clean_names);

  % Read all remaining data
  % Try numeric first, fall back to mixed
  data_lines = {};
  while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line))
      data_lines{end+1} = line;
    end
  end
  fclose(fid);

  if isempty(data_lines)
    T = struct();
    for j = 1:ncols
      T.(clean_names{j}) = [];
    end
    T.Properties = struct('VariableNames', {clean_names});
    return;
  end

  nrows = length(data_lines);

  % Try to parse all data as numeric
  numeric_data = NaN(nrows, ncols);
  is_numeric = true(1, ncols);

  % Use textscan for faster parsing
  all_text = strjoin(data_lines, '\n');
  try
    % Build format string: try all numeric
    fmt_str = repmat('%f', 1, ncols);
    C = textscan(all_text, fmt_str, 'Delimiter', ',', 'EmptyValue', NaN);
    if length(C) == ncols && ~isempty(C{1})
      T = struct();
      for j = 1:ncols
        T.(clean_names{j}) = C{j};
      end
      T.Properties = struct('VariableNames', {clean_names});
      return;
    end
  catch
  end

  % Fallback: parse as mixed (string/numeric) line by line
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
