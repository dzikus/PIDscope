function [fwType, fwMajor, fwMinor] = PTparseBFversion(setupInfo)
%% PTparseBFversion - parse firmware type and version from SetupInfo cell array
%  [fwType, fwMajor, fwMinor] = PTparseBFversion(setupInfo)
%  setupInfo: Nx2 cell array (column 1 = param name, column 2 = value)
%  Returns: fwType string ('Betaflight','INAV','Emuflight',...), fwMajor, fwMinor numbers

fwType = 'Unknown';
fwMajor = 0;
fwMinor = 0;

try
    % Find 'Firmware version' or 'Firmware revision' row
    idx = find(strcmp(setupInfo(:,1), 'Firmware version'));
    if isempty(idx)
        idx = find(strcmp(setupInfo(:,1), 'Firmware revision'));
    end
    if isempty(idx)
        return;
    end

    verStr = strtrim(char(setupInfo(idx(1), 2)));
    % Example: " Betaflight / STM32F405 4.5.3 Dec 14 2024 / 11:27:01"
    % Example: " Betaflight / STM32F405 2025.12.2 Jan 5 2026 / 09:15:00"
    % Example: " INAV / STM32F405 7.1.0 ..."
    % Example: " Emuflight / STM32F405 0.4.1 ..."
    % Example: "QuickSilver" (from PTquicJson2csv synthetic header)

    % Extract firmware type (first word before ' /' or end of string)
    parts = strsplit(verStr, '/');
    fwType = strtrim(parts{1});

    % Extract version: find pattern X.Y.Z or X.Y anywhere in string
    tok = regexp(verStr, '(\d+)\.(\d+)\.(\d+)', 'tokens');
    if ~isempty(tok)
        % Could have multiple matches (e.g. board name with numbers) - use last one
        % Actually first match after '/' is the version
        for t = 1:numel(tok)
            maj = str2double(tok{t}{1});
            mnr = str2double(tok{t}{2});
            % Heuristic: version is the token with major >= 2 (BF 2025.x or 3.x/4.x)
            % or after the board name
            if maj >= 2
                fwMajor = maj;
                fwMinor = mnr;
                break;
            end
        end
        % If no match with major >= 2, use first token
        if fwMajor == 0 && ~isempty(tok)
            fwMajor = str2double(tok{1}{1});
            fwMinor = str2double(tok{1}{2});
        end
    end
catch
end

end
