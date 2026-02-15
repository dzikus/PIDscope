function opts = detectImportOptions(filename)
%% DETECTIMPORTOPTIONS - Octave-compatible import options detector
% Simplified drop-in for MATLAB's detectImportOptions().
% Reads the header row of a CSV file and returns options with VariableNames.
%
% Usage:
%   opts = detectImportOptions(filename)

  fid = fopen(filename, 'r');
  if fid == -1
    error('detectImportOptions: cannot open file %s', filename);
  end

  header_line = fgetl(fid);
  fclose(fid);

  if ~ischar(header_line)
    opts = struct('VariableNames', {{}});
    return;
  end

  col_names = strsplit(strtrim(header_line), ',');
  clean_names = cell(size(col_names));
  for i = 1:length(col_names)
    s = strtrim(col_names{i});
    s = regexprep(s, '[\[\]\(\) ]+', '_');
    s = regexprep(s, '[^a-zA-Z0-9_]', '_');
    if ~isempty(s) && (s(1) >= '0' && s(1) <= '9')
      s = ['x' s];
    end
    s = regexprep(s, '_+', '_');
    if isempty(s)
      s = sprintf('Var%d', i);
    end
    clean_names{i} = s;
  end

  opts = struct('VariableNames', {clean_names});

end
