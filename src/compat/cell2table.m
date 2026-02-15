function T = cell2table(C, varargin)
%% CELL2TABLE - Octave-compatible cell array to table conversion
% Drop-in replacement for MATLAB's cell2table() returning a struct.
%
% Usage:
%   T = cell2table(C, 'VariableNames', {'col1', 'col2', ...})
%
% C is a cell array where each column becomes a field in the struct.

  % Parse VariableNames
  var_names = {};
  for i = 1:2:length(varargin)
    if strcmpi(varargin{i}, 'VariableNames')
      var_names = varargin{i+1};
      if ~iscell(var_names)
        var_names = cellstr(var_names);
      end
      var_names = var_names(:)';  % ensure row vector
    end
  end

  ncols = size(C, 2);
  if isempty(var_names)
    var_names = arrayfun(@(x) sprintf('Var%d', x), 1:ncols, 'UniformOutput', false);
  end

  T = struct();
  for j = 1:ncols
    col_data = C(:, j);
    % Check if all entries are numeric
    all_numeric = true;
    for k = 1:length(col_data)
      if ~isnumeric(col_data{k})
        all_numeric = false;
        break;
      end
    end
    if all_numeric
      T.(var_names{j}) = cell2mat(col_data);
    else
      T.(var_names{j}) = col_data;
    end
  end
  T.Properties = struct('VariableNames', {var_names});

end
