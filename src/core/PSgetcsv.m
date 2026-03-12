function [filename csvFnames] = PSgetcsv(filename, firmware_flag, outdir)
%% [filename csvFnames] = PSgetcsv(filename, firmware_flag, outdir)
% Converts bbl files to csv using blackbox_decode
% filename: full path to BBL/BFL/TXT/BTFL/JSON/BIN file
% outdir: directory for CSV output (default: same as input file)

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

if strcmpi(fext, '.bin')
    csvFnames = {filename};
    return;
elseif strcmpi(fext, '.json')
    [headerFile, csvFile] = PSquicJson2csv(filename, outdir);
    filename = headerFile;
    files(1).name = csvFile;
    fnums = 1;
elseif any(strcmpi(fext, {'.BFL', '.BBL', '.TXT', '.BTFL'}))

    decoder_path = getappdata(0, 'PSdecoderPath');
    decoder_inav = getappdata(0, 'PSdecoderPathINAV');

    if firmware_flag == 3 && ~isempty(decoder_inav)
        % INAV decoder has no --output-dir; copy input to workdir first
        tmpSrc = fullfile(outdir, [fname fext]);
        copyfile(filename, tmpSrc);
        cmd = ['"' decoder_inav '" "' tmpSrc '" 2>&1'];
    else
        cmd = ['"' decoder_path '" --output-dir "' outdir '" "' filename '" 2>&1'];
    end
    [status, result] = system(cmd);

    fbase = fullfile(outdir, fname);
    files = dir([fbase '*.csv']);

    % filter out files with .bbl or .bfl in name
    valid = true(size(files,1), 1);
    for k = 1:size(files,1)
        if contains(files(k).name, '.bbl', 'IgnoreCase', true) || contains(files(k).name, '.bfl', 'IgnoreCase', true)
            valid(k) = false;
        end
    end
    files = files(valid, :);

    if isempty(files)
        set(gcf, 'pointer', 'arrow');
        csvFnames = {};
        return;
    end

    % clean up junk files in outdir
    fevt = dir([fbase '*.event']);
    for k = 1:size(fevt,1), delete(fullfile(outdir, fevt(k).name)); end
    fevt = dir([fbase '*.gps.gpx']);
    for k = 1:size(fevt,1), delete(fullfile(outdir, fevt(k).name)); end
    fevt = dir([fbase '*.gps.csv']);
    for k = 1:size(fevt,1), delete(fullfile(outdir, fevt(k).name)); end

    % refresh file list after cleanup
    files = dir([fbase '*.csv']);

    if size(files,1) > 1
        % remove empty subfiles (<1KB)
        valid = true(size(files,1), 1);
        for k = 1:size(files,1)
            if files(k).bytes < 1000
                delete(fullfile(outdir, files(k).name));
                valid(k) = false;
            end
        end
        files = files(valid, :);

        a = strfind(result, 'duration');
        logDurStr = '';
        for d = 1:length(a)
            logDurStr{d} = [int2str(d) ') ' result(a(d):a(d)+filename_nchars)];
        end

        if size(files,1) > 0
            x = size(files,1);
            if x > 1
                [fnums, tf] = listdlg('ListString', logDurStr, 'ListSize', [250, round(size(logDurStr,2)*20)], 'Name', 'Select file(s): ');
                for k = 1:x
                    if ~ismember(k, fnums), delete(fullfile(outdir, files(k).name)); end
                end
            end
        else
            validData = 0;
            a = errordlg(['no valid data in ' mainFname]); pause(3); close(a);
        end
    end
end

csvFnames = {};
for k = 1:length(fnums)
    csvFnames{k} = fullfile(outdir, files(fnums(k)).name);
end

end
