function writetable(T, filename)
%% WRITETABLE - Octave-compatible table-to-file writer
% Drop-in replacement for MATLAB's writetable().
%
% Usage:
%   writetable(T, filename)
%
% Writes the struct-based table T to a text file.
% Appends .txt extension if no extension present.

  % Ensure .txt extension
  if isempty(strfind(filename, '.'))
    filename = [filename '.txt'];
  end

  var_names = T.Properties.VariableNames;
  ncols = length(var_names);

  fid = fopen(filename, 'w');
  if fid == -1
    error('writetable: cannot open file %s for writing', filename);
  end

  % Write header
  fprintf(fid, '%s', var_names{1});
  for j = 2:ncols
    fprintf(fid, ',%s', var_names{j});
  end
  fprintf(fid, '\n');

  % Determine number of rows
  first_col = T.(var_names{1});
  if iscell(first_col)
    nrows = length(first_col);
  else
    nrows = size(first_col, 1);
  end

  % Write data rows
  for i = 1:nrows
    for j = 1:ncols
      col = T.(var_names{j});
      if j > 1
        fprintf(fid, ',');
      end
      if iscell(col)
        fprintf(fid, '%s', col{i});
      elseif isnumeric(col)
        fprintf(fid, '%g', col(i));
      else
        fprintf(fid, '%s', col(i));
      end
    end
    fprintf(fid, '\n');
  end

  fclose(fid);

end
