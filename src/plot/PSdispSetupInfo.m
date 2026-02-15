%% PSdispSetupInfo 

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if exist('fnameMaster','var') && ~isempty(fnameMaster)
    if Nfiles < 2
        str=repmat({':'}, size(dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo,1), 1); % Octave compatible (was: strings)
        str2=strcat(dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo(:,1), str);
        setupA=strcat(str2, dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo(:,2)); % Octave compatible (was: string())
    else
        str=repmat({':'}, size(dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo,1), 1);
        str2=strcat(dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo(:,1), str);
        setupA=strcat(str2, dataA(get(guiHandlesInfo.FileNumDispA, 'Value')).SetupInfo(:,2));

        str=repmat({':'}, size(dataA(get(guiHandlesInfo.FileNumDispB, 'Value')).SetupInfo,1), 1);
        str2=strcat(dataA(get(guiHandlesInfo.FileNumDispB, 'Value')).SetupInfo(:,1), str);
        setupB=strcat(str2, dataA(get(guiHandlesInfo.FileNumDispB, 'Value')).SetupInfo(:,2));
    end
     
    BGCol = [];
    try
        for i = 1 : size(setupA,1)
            if strcmp(setupA{i}, setupB{i})
                BGCol(i,:) = [1 1 1];
            else
                BGCol(i,:) = [1 .7 .7];
            end
        end
    catch
        BGCol=[1 1 1];
    end
    u=[];
    u = (sum(BGCol,2)/3) < 1;

    if get(guiHandlesInfo.checkboxDIFF, 'Value') == 1
         t = uitable('ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA(u)))]);
         set(t,'units','normalized','Position',[.02 .05 .45 .9],'FontSize',fontsz, 'ColumnName', [fnameMaster{get(guiHandlesInfo.FileNumDispA, 'Value')}])
         set(t,'BackgroundColor', [1 .7 .7])
        if Nfiles > 1
              t = uitable('ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB(u)))]);
              set(t,'units','normalized','Position',[.52 .05 .45 .9],'FontSize',fontsz, 'ColumnName', fnameMaster{get(guiHandlesInfo.FileNumDispB, 'Value')})
              set(t,'BackgroundColor', [1 .7 .7])
        end
    else
        t = uitable('ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA))]);
         set(t,'units','normalized','Position',[.02 .05 .45 .9],'FontSize',fontsz, 'ColumnName', [fnameMaster{get(guiHandlesInfo.FileNumDispA, 'Value')}])
         set(t,'BackgroundColor', [BGCol])
        if Nfiles > 1
              t = uitable('ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB))]);
              set(t,'units','normalized','Position',[.52 .05 .45 .9],'FontSize',fontsz, 'ColumnName', fnameMaster{get(guiHandlesInfo.FileNumDispB, 'Value')})
              set(t,'BackgroundColor', [BGCol])
        end
    end
end

    