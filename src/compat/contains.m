function tf = contains(str, pat, varargin)
% contains - Octave compatibility shim for MATLAB's contains()
% Copyright (C) 2026 Grzegorz Sterniczuk
% License: GPL v3 (see LICENSE)

  ignorecase = false;
  for i = 1:2:numel(varargin)
    if strcmpi(varargin{i}, 'IgnoreCase')
      ignorecase = varargin{i+1};
    end
  end

  if iscell(str)
    tf = false(size(str));
    for k = 1:numel(str)
      tf(k) = check_contains(str{k}, pat, ignorecase);
    end
  else
    tf = check_contains(str, pat, ignorecase);
  end
end

function tf = check_contains(s, pat, ignorecase)
  if iscell(pat)
    tf = false;
    for k = 1:numel(pat)
      if check_one(s, pat{k}, ignorecase)
        tf = true;
        return;
      end
    end
  else
    tf = check_one(s, pat, ignorecase);
  end
end

function tf = check_one(s, p, ignorecase)
  if ignorecase
    tf = ~isempty(strfind(lower(s), lower(p)));
  else
    tf = ~isempty(strfind(s, p));
  end
end
