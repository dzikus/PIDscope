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
     
    th = PStheme();
    diffCol = th.diffBg;
    nA = size(setupA,1);
    BGCol = repmat(th.panelBg, nA, 1);
    u = false(nA, 1);
    try
        for i = 1 : min(nA, size(setupB,1))
            if ~strcmp(setupA{i}, setupB{i})
                BGCol(i,:) = diffCol;
                u(i) = true;
            end
        end
        for i = size(setupB,1)+1 : nA
            BGCol(i,:) = diffCol;
            u(i) = true;
        end
    catch
    end

    delete(findobj(PSdisp, 'Type', 'uitable'));

    tbH = 0.88;
    if get(guiHandlesInfo.checkboxDIFF, 'Value') == 1
         nDiff = sum(u);
         diffBG = repmat(diffCol, max(nDiff,1), 1);
         st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA(u)))]);
         set(st,'units','normalized','Position',[.02 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', [fnameMaster{get(guiHandlesInfo.FileNumDispA, 'Value')}]);
         try set(st,'BackgroundColor', diffBG); catch, end
         try set(st,'ForegroundColor', th.textPrimary); catch, end
         try set(st,'RowStriping', 'off'); catch, end
        if Nfiles > 1
              st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB(u)))]);
              set(st,'units','normalized','Position',[.52 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', fnameMaster{get(guiHandlesInfo.FileNumDispB, 'Value')});
              try set(st,'BackgroundColor', diffBG); catch, end
              try set(st,'ForegroundColor', th.textPrimary); catch, end
              try set(st,'RowStriping', 'off'); catch, end
        end
    else
        st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA))]);
         set(st,'units','normalized','Position',[.02 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', [fnameMaster{get(guiHandlesInfo.FileNumDispA, 'Value')}]);
         try set(st,'BackgroundColor', BGCol); catch, end
         try set(st,'ForegroundColor', th.textPrimary); catch, end
         try set(st,'RowStriping', 'off'); catch, end
        if Nfiles > 1
              st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB))]);
              set(st,'units','normalized','Position',[.52 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', fnameMaster{get(guiHandlesInfo.FileNumDispB, 'Value')});
              try set(st,'BackgroundColor', BGCol); catch, end
              try set(st,'ForegroundColor', th.textPrimary); catch, end
              try set(st,'RowStriping', 'off'); catch, end
        end
    end
end

    