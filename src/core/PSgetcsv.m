function [filename csvFnames] = PSgetcsv(filename, firmware_flag, outdir, sel)
%% [filename csvFnames] = PSgetcsv(filename, firmware_flag, outdir, sel)
% Converts bbl files to csv using blackbox_decode
% filename: full path to BBL/BFL/TXT/BTFL/JSON/BIN file
% outdir: directory for CSV output (default: same as input file)
% sel: session numbers to keep from a multi-log file; omit to ask the user

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------


fnums = 1;
filename_nchars = 17;

mainFname = filename;
[fdir, fname, fext] = fileparts(filename);

if nargin < 3 || isempty(outdir)
    outdir = fdir;
end
if nargin < 4, sel = []; end
askUser = isempty(sel);

if strcmpi(fext, '.bin')
    csvFnames = {filename};
    return;
elseif strcmpi(fext, '.json')
    [headerFile, csvFile] = PSquicJson2csv(filename, outdir);
    filename = headerFile;
    [~, csvName, csvExt] = fileparts(csvFile);
    files(1).name = [csvName csvExt];
    fnums = 1;
elseif any(strcmpi(fext, {'.BFL', '.BBL', '.TXT', '.BTFL'}))

    decoder_path = getappdata(0, 'PSdecoderPath');
    decoder_inav = getappdata(0, 'PSdecoderPathINAV');

    if firmware_flag == 3 && ~isempty(decoder_inav) && exist(decoder_inav, 'file') == 2
        % INAV decoder has no --output-dir; run it on a copy inside outdir
        tmpSrc = fullfile(outdir, [fname fext]);
        if ~strcmp(tmpSrc, filename), copyfile(filename, tmpSrc); end
        cmd = ['"' decoder_inav '" "' tmpSrc '" 2>&1'];
    else
        cmd = ['"' decoder_path '" --output-dir "' outdir '" "' filename '" 2>&1'];
    end
    [status, result] = system(cmd);
    if status ~= 0
        warning('blackbox_decode failed (exit %d): %s', status, result);
        csvFnames = {};
        return;
    end

    fbase = fullfile(outdir, fname);

    % junk the decoder drops next to the csv output
    for pat = {'*.event', '*.gps.gpx', '*.gps.csv'}
        junk = dir([fbase pat{1}]);
        for k = 1:size(junk,1), delete(fullfile(outdir, junk(k).name)); end
    end

    % side outputs keep the source extension in the name
    files = dir([fbase '*.csv']);
    valid = true(size(files,1), 1);
    for k = 1:size(files,1)
        if contains(files(k).name, '.bbl', 'IgnoreCase', true) || contains(files(k).name, '.bfl', 'IgnoreCase', true)
            valid(k) = false;
        end
    end
    files = files(valid, :);

    if isempty(files)
        csvFnames = {};
        return;
    end

    if size(files,1) > 1
        % the decoder prints one duration per log, in the order it wrote them,
        % so pair them up before anything is dropped from the list
        a = strfind(result, 'duration');
        labels = cell(size(files,1), 1);
        for k = 1:size(files,1)
            if k <= length(a)
                labels{k} = result(a(k):min(a(k)+filename_nchars, length(result)));
            else
                labels{k} = files(k).name;
            end
        end

        % logs under 1KB hold no flight data - drop them and their labels together
        small = [files.bytes] < 1000;
        for k = find(small), delete(fullfile(outdir, files(k).name)); end
        files = files(~small, :);
        labels = labels(~small);

        if isempty(files)
            if askUser
                a = errordlg(['no valid data in ' mainFname]); pause(3); close(a);
            else
                warning('PSgetcsv: no valid data in %s', mainFname);
            end
            csvFnames = {};
            return;
        end
    end

    if size(files,1) > 1
        if askUser
            for k = 1:size(files,1)
                labels{k} = [int2str(k) ') ' labels{k}];
            end
            % the dialog opens behind the import waitbar on Windows and looks like a hang
            wb = findall(0, 'Type', 'figure', 'Tag', 'waitbar');
            set(wb, 'Visible', 'off');
            [fnums, tf] = listdlg('ListString', labels, 'ListSize', [250, round(numel(labels)*20)], 'Name', 'Select file(s): ');
            set(wb, 'Visible', 'on');
            if ~tf || isempty(fnums)
                for k = 1:size(files,1), delete(fullfile(outdir, files(k).name)); end
                csvFnames = {};
                return;
            end
        else
            fnums = sel(sel >= 1 & sel <= size(files,1));
        end
        for k = 1:size(files,1)
            if ~ismember(k, fnums), delete(fullfile(outdir, files(k).name)); end
        end
    end
end

csvFnames = {};
for k = 1:length(fnums)
    csvFnames{k} = fullfile(outdir, files(fnums(k)).name);
end

end
