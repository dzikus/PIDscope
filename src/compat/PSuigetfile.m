function [filenames, filepath] = PSuigetfile(filter_spec, dialog_title, initial_dir, varargin)
% PSuigetfile - File selection dialog with Flatpak zenity fallback
%
% Octave 10.x uigetfile in Flatpak returns the INITIAL directory instead of
% the directory the user navigated to. This wrapper uses zenity --file-selection
% when running inside a Flatpak sandbox (detected via /.flatpak-info).
%
% Usage is identical to uigetfile:
%   [filename, filepath] = PSuigetfile(filter, title, startdir, 'MultiSelect','on')

  multi_select = false;
  for k = 1:2:numel(varargin)
    if strcmpi(varargin{k}, 'MultiSelect') && strcmpi(varargin{k+1}, 'on')
      multi_select = true;
    end
  end

  % Use zenity in Flatpak (/.flatpak-info always exists inside sandbox)
  if exist('/.flatpak-info', 'file')
    [filenames, filepath] = zenity_dialog(filter_spec, dialog_title, initial_dir, multi_select);
  else
    if multi_select
      [filenames, filepath] = uigetfile(filter_spec, dialog_title, initial_dir, 'MultiSelect', 'on');
    else
      [filenames, filepath] = uigetfile(filter_spec, dialog_title, initial_dir);
    end
  end
end


function [filenames, filepath] = zenity_dialog(filter_spec, title, initial_dir, multi_select)
  cmd = 'zenity --file-selection';

  if nargin >= 2 && ~isempty(title)
    cmd = [cmd ' --title="' title '"'];
  end

  if multi_select
    cmd = [cmd ' --multiple --separator="|"'];
  end

  if nargin >= 3 && ~isempty(initial_dir) && exist(initial_dir, 'dir')
    if initial_dir(end) ~= filesep
      initial_dir = [initial_dir filesep];
    end
    cmd = [cmd ' --filename="' initial_dir '"'];
  end

  % Convert uigetfile filter to zenity format
  % uigetfile: {'*.bbl;*.BBL;*.bfl;*.BFL', 'Blackbox Logs'}
  % zenity:    --file-filter="Blackbox Logs | *.bbl *.BBL *.bfl *.BFL"
  if iscell(filter_spec) && size(filter_spec, 2) >= 2
    patterns = strsplit(filter_spec{1,1}, ';');
    filter_name = filter_spec{1,2};
    zf = ['"' filter_name ' |'];
    for k = 1:numel(patterns)
      zf = [zf ' ' strtrim(patterns{k})];
    end
    zf = [zf '"'];
    cmd = [cmd ' --file-filter=' zf];
  end
  cmd = [cmd ' --file-filter="All files | *"'];

  [status, result] = system(cmd);
  result = strtrim(result);

  if status ~= 0 || isempty(result)
    filenames = 0;
    filepath = 0;
    return;
  end

  if multi_select
    paths = strsplit(result, '|');
  else
    paths = {result};
  end

  % Extract directory from first file
  [dirpart, ~, ~] = fileparts(paths{1});
  filepath = [dirpart filesep];

  % Extract just filenames
  fnames = cell(1, numel(paths));
  for k = 1:numel(paths)
    [~, name, ext] = fileparts(paths{k});
    fnames{k} = [name ext];
  end

  if numel(fnames) == 1 && ~multi_select
    filenames = fnames{1};
  else
    filenames = fnames;
  end
end
