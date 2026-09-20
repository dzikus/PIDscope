% test_PSautotuneCLI.m - the CLI text handed to the pilot

%!function it = mkit(name, ok, P, I, D, F, note)
%!  it = struct('axisName', name, 'ok', ok, ...
%!              'gains', struct('P',P,'I',I,'D',D,'F',F), 'note', note);
%!endfunction

%!test
%! % Three tuned axes produce exactly the lines Betaflight expects, and nothing
%! % else that looks like a setting
%! items = [mkit('Roll', true, 30, 43, 27, 0, ''), ...
%!          mkit('Pitch', true, 45, 67, 42, 0, ''), ...
%!          mkit('Yaw', true, 59, 128, 2, 0, '')];
%! txt = PSautotuneCLI(items, 50);
%! lines = strsplit(txt, char(10));
%! for want = {'set p_roll = 30', 'set i_roll = 43', 'set d_roll = 27', ...
%!             'set f_roll = 0', 'set p_pitch = 45', 'set i_pitch = 67', ...
%!             'set d_pitch = 42', 'set f_pitch = 0', 'set p_yaw = 59', ...
%!             'set i_yaw = 128', 'set d_yaw = 2', 'set f_yaw = 0', 'save'}
%!   assert(any(strcmp(lines, want{1})), sprintf('missing line: %s', want{1}));
%! end
%! assert(strcmp(strtrim(lines{end}), 'save'), 'the last line must be save');

%!test
%! % Every line is either a comment, one of the twelve settings, or save. A
%! % stray line is a stray command in someone's flight controller.
%! items = [mkit('Roll', true, 30, 43, 27, 0, ''), ...
%!          mkit('Pitch', false, 0,0,0,0, 'sweep stopped after 11 s'), ...
%!          mkit('Yaw', true, 59, 128, 2, 0, '')];
%! txt = PSautotuneCLI(items, 60);
%! lines = strsplit(txt, char(10));
%! for k = 1:numel(lines)
%!   L = strtrim(lines{k});
%!   if isempty(L), continue; end
%!   okLine = L(1) == '#' || strcmp(L, 'save') || ...
%!            ~isempty(regexp(L, '^set [pidf]_(roll|pitch|yaw) = -?\d+$', 'once'));
%!   assert(okLine, sprintf('unexpected line: %s', L));
%! end

%!test
%! % A refused axis is named, with its reason, and gets no settings at all -
%! % silence would look like "nothing to change" rather than "I could not tell"
%! items = [mkit('Roll', true, 30, 43, 27, 0, ''), ...
%!          mkit('Pitch', false, 0,0,0,0, 'sweep stopped after 11 s'), ...
%!          mkit('Yaw', false, 0,0,0,0, 'this axis was not swept')];
%! txt = PSautotuneCLI(items, 60);
%! assert(~isempty(strfind(txt, 'sweep stopped after 11 s')));
%! assert(~isempty(strfind(txt, 'this axis was not swept')));
%! lines = strsplit(txt, char(10));
%! assert(~any(strncmp(lines, 'set p_pitch', 11)), 'a refused axis must not be set');
%! assert(~any(strncmp(lines, 'set p_yaw', 9)), 'a refused axis must not be set');
%! assert(any(strncmp(lines, 'set p_roll', 10)), 'the axis that worked still is');

%!test
%! % The #5258 barrier, restated where the text is actually produced. The search
%! % has no filter fields to offer; this makes sure nothing invents one on the
%! % way out. Checked over every shape of input this function takes.
%! cases = { ...
%!   [mkit('Roll', true, 30, 43, 27, 0, ''), mkit('Pitch', true, 45, 67, 42, 9, ''), mkit('Yaw', true, 59, 128, 2, 0, '')], ...
%!   [mkit('Roll', false, 0,0,0,0, 'no candidate'), mkit('Pitch', false, 0,0,0,0, 'not swept'), mkit('Yaw', false, 0,0,0,0, 'saturated')], ...
%!   [mkit('Roll', true, 1, 1, 0, 0, ''), mkit('Pitch', false, 0,0,0,0, 'dterm_lpf1_hz was 120'), mkit('Yaw', true, 200, 200, 90, 200, '')] };
%! for k = 1:numel(cases)
%!   txt = PSautotuneCLI(cases{k}, 72.5);
%!   lines = strsplit(txt, char(10));
%!   for j = 1:numel(lines)
%!     L = strtrim(lines{j});
%!     if isempty(L) || L(1) == '#', continue; end
%!     assert(isempty(strfind(L, 'dterm_')), sprintf('case %d emitted: %s', k, L));
%!     assert(isempty(strfind(L, 'gyro_')), sprintf('case %d emitted: %s', k, L));
%!     assert(isempty(strfind(L, 'notch')), sprintf('case %d emitted: %s', k, L));
%!   end
%! end

%!test
%! % The header says what the numbers are for, because the text outlives the
%! % window it came from
%! items = [mkit('Roll', true, 30, 43, 27, 0, ''), ...
%!          mkit('Pitch', true, 45, 67, 42, 0, ''), ...
%!          mkit('Yaw', true, 59, 128, 2, 0, '')];
%! txt = PSautotuneCLI(items, 72.5);
%! assert(~isempty(strfind(txt, 'PIDscope')));
%! assert(~isempty(strfind(txt, '72.5')), 'the target must be recorded');
%! assert(~isempty(strfind(lower(txt), 'test flight')), 'and so must the caveat');

%!test
%! % Every axis refused still produces usable text rather than an empty string
%! items = [mkit('Roll', false, 0,0,0,0, 'no chirp'), ...
%!          mkit('Pitch', false, 0,0,0,0, 'no chirp'), ...
%!          mkit('Yaw', false, 0,0,0,0, 'no chirp')];
%! txt = PSautotuneCLI(items, 60);
%! assert(~isempty(strtrim(txt)));
%! lines = strsplit(txt, char(10));
%! assert(~any(strncmp(lines, 'set ', 4)), 'nothing to set means nothing set');
%! assert(~any(strcmp(strtrim(lines), 'save')), 'and nothing to save');
