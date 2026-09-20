function ok = PScopyToClipboard(str)
%% PScopyToClipboard - put text on the system clipboard
%  Returns false when no clipboard helper is available, which is the normal
%  case on a bare X session - the caller is expected to fall back to showing
%  the text.

ok = false;
tmpf = [tempname '.txt'];
fid = fopen(tmpf, 'w'); fprintf(fid, '%s', str); fclose(fid);
if ismac()
    [st, ~] = system(sprintf('pbcopy < %s 2>&1', tmpf));
    ok = (st == 0);
elseif ispc()
    [st, ~] = system(sprintf('clip < %s 2>&1', tmpf));
    ok = (st == 0);
else
    cmds = {'xclip -selection clipboard', 'xsel --clipboard --input', 'wl-copy'};
    for k = 1:numel(cmds)
        [st, ~] = system(sprintf('%s < %s 2>&1', cmds{k}, tmpf));
        if st == 0, ok = true; break; end
    end
end
delete(tmpf);

end
