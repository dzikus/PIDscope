%% PTsaveFig

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

%% create saveDirectory
if exist('fnameMaster','var') && ~isempty(fnameMaster)
    saveDirectory='PTB_FIGS';
    saveDirectory = [saveDirectory '_' currentDate];

    % Try logfile_directory first, fall back to configDir (Flatpak: home is read-only)
    saveBase = '';
    try
        cd(logfile_directory);
        if ~isfolder(saveDirectory), mkdir(saveDirectory); end
        saveBase = logfile_directory;
    catch
        try
            cd(configDir);
            if ~isfolder(saveDirectory), mkdir(saveDirectory); end
            saveBase = configDir;
        catch
        end
    end

    if isempty(saveBase)
        warndlg('Cannot create save directory (file system may be read-only)');
        return;
    end

%%
set(gcf, 'pointer', 'watch')
cd(saveBase)
cd(saveDirectory)
FigDoesNotExist=1;
n=0;
while FigDoesNotExist,
    n=n+1;
    FigDoesNotExist=isfile([saveDirectory '-' int2str(n) '.png']);
end
figname=[saveDirectory '-' int2str(n)];
saveas(gcf, [figname '.png'] );
print(figname,'-dpng','-r200')

set(gcf, 'pointer', 'arrow')
cd(configDir)

else
     warndlg('Please select file(s)');
end