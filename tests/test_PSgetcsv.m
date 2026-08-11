%% Tests for PSgetcsv - blackbox_decode driver and multi-session selection
%% The session number is always passed explicitly so no dialog is ever reached.

%!function d = fake_decoder_(outdir, stdoutTxt, csvSpec)
%!  % Shell stub standing in for blackbox_decode: writes the requested csv
%!  % files into --output-dir and echoes canned decoder chatter.
%!  d = fullfile(outdir, 'fake_decode.sh');
%!  fid = fopen(d, 'w');
%!  fprintf(fid, '#!/bin/sh\n');
%!  fprintf(fid, 'out=\n');
%!  fprintf(fid, 'while [ $# -gt 0 ]; do\n');
%!  fprintf(fid, '  case "$1" in --output-dir) out="$2"; shift 2;; *) src="$1"; shift;; esac\n');
%!  fprintf(fid, 'done\n');
%!  % without --output-dir the real decoders write next to the input file
%!  fprintf(fid, '[ -n "$out" ] || out=$(dirname "$src")\n');
%!  fprintf(fid, 'base=$(basename "$src"); base=${base%%.*}\n');
%!  for k = 1:size(csvSpec, 1)
%!    fprintf(fid, 'printf "%%s" "%s" > "$out/$base%s"\n', csvSpec{k,2}, csvSpec{k,1});
%!  end
%!  fprintf(fid, 'printf "%%s" "%s"\n', stdoutTxt);
%!  fclose(fid);
%!  system(['chmod +x "' d '"']);
%!endfunction

%!function src = fake_log_(wd, name)
%!  src = fullfile(wd, name);
%!  fid = fopen(src, 'w'); fprintf(fid, 'x'); fclose(fid);
%!endfunction

%!test
%! % "duration" landing near the end of decoder output must not overrun the string
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, 'log 1 duration', {'.01.csv', ['a\n' bigrow]; '.02.csv', ['b\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! src = fake_log_(wd, 'LOG00001.BBL');
%! err = '';
%! try
%!   [~, csvFnames] = PSgetcsv(src, 1, wd, 1);
%! catch e
%!   err = e.message;
%! end
%! assert(isempty(err), 'PSgetcsv threw on truncated decoder output: %s', err);

%!test
%! % the session list is built from decoder chatter but indexed against the file
%! % list - a short log dropped for being <1KB must not desync the two
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, ...
%!   'log 1 duration 00:10.000 log 2 duration 00:20.000 log 3 duration 00:30.000 end', ...
%!   {'.01.csv', ['a\n' bigrow]; '.02.csv', 'tiny'; '.03.csv', ['c\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! src = fake_log_(wd, 'LOG00002.BBL');
%! [~, csvFnames] = PSgetcsv(src, 1, wd, 2);
%! assert(numel(csvFnames) == 1, 'expected one csv, got %d', numel(csvFnames));
%! % session 2 of the surviving logs is the .03 file, the tiny .02 is gone
%! assert(~isempty(strfind(csvFnames{1}, '.03.csv')), ...
%!        'selected the wrong session: %s', csvFnames{1});

%!test
%! % a selection past the end of the list must not index out of bounds
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, 'log 1 duration 00:10.000 log 2 duration 00:20.000 end', ...
%!   {'.01.csv', ['a\n' bigrow]; '.02.csv', ['b\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! src = fake_log_(wd, 'LOG00005.BBL');
%! [~, csvFnames] = PSgetcsv(src, 1, wd, [1 7]);
%! assert(numel(csvFnames) == 1, 'expected one csv, got %d', numel(csvFnames));

%!test
%! % .bbl.csv side output is filtered out, and must stay filtered after the
%! % junk-file cleanup refreshes the list
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, 'log 1 duration 00:10.000 end', ...
%!   {'.01.csv', ['a\n' bigrow]; '.bbl.csv', ['junk\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! src = fake_log_(wd, 'LOG00003.BBL');
%! [~, csvFnames] = PSgetcsv(src, 1, wd, 1);
%! assert(numel(csvFnames) == 1, 'expected one csv, got %d', numel(csvFnames));
%! assert(isempty(strfind(csvFnames{1}, '.bbl.csv')), ...
%!        'returned the filtered .bbl.csv: %s', csvFnames{1});

%!test
%! % A missing INAV decoder must not silently produce nothing - fall back to
%! % the standard decoder rather than shelling out to a path that isn't there
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, 'log 1 duration 00:10.000 end', {'.01.csv', ['a\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! setappdata(0, 'PSdecoderPathINAV', fullfile(wd, 'does_not_exist_INAV'));
%! src = fake_log_(wd, 'LOG00004.TXT');
%! [~, csvFnames] = PSgetcsv(src, 3, wd, 1);
%! setappdata(0, 'PSdecoderPathINAV', '');
%! assert(numel(csvFnames) == 1, ...
%!        'INAV import produced %d csv files when the INAV decoder is absent', numel(csvFnames));

%!test
%! % INAV runs the decoder on a copy inside outdir - when the log already lives
%! % there, copying it onto itself must not abort the import
%! wd = tempname(); mkdir(wd);
%! bigrow = repmat('9', 1, 1200);
%! dec = fake_decoder_(wd, 'log 1 duration 00:10.000 end', {'.01.csv', ['a\n' bigrow]});
%! setappdata(0, 'PSdecoderPath', dec);
%! setappdata(0, 'PSdecoderPathINAV', dec);
%! src = fake_log_(wd, 'LOG00006.TXT');
%! [~, csvFnames] = PSgetcsv(src, 3, wd, 1);
%! setappdata(0, 'PSdecoderPathINAV', '');
%! assert(numel(csvFnames) == 1, 'expected one csv, got %d', numel(csvFnames));
