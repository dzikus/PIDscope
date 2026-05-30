%% PSdispSetupInfo

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if exist('fnameMaster','var') && ~isempty(fnameMaster)

    fA_ = get(guiHandlesInfo.FileNumDispA, 'Value');
    siA = dataA(fA_).SetupInfo;
    keysA = strtrim(siA(:,1));
    valsA = strtrim(siA(:,2));
    nA = numel(keysA);
    str = repmat({':'}, nA, 1);
    setupA = strcat(keysA, str, valsA);

    th = PStheme();
    diffCol = th.diffBg;
    BGCol = repmat(th.panelBg, nA, 1);
    u = false(nA, 1);

    if Nfiles >= 2 && isfield(guiHandlesInfo, 'FileNumDispB') && ishandle(guiHandlesInfo.FileNumDispB)
        fB_ = get(guiHandlesInfo.FileNumDispB, 'Value');
        siB = dataA(fB_).SetupInfo;
        keysB = strtrim(siB(:,1));
        valsB = strtrim(siB(:,2));
        nB = numel(keysB);
        strB = repmat({':'}, nB, 1);
        setupB = strcat(keysB, strB, valsB);

        % renamed parameter aliases (BF version changes)
        aliases = { ...
            'gyro_lowpass_type',    'gyro_lpf1_type'; ...
            'gyro_lowpass_hz',      'gyro_lpf1_static_hz'; ...
            'gyro_lowpass2_type',   'gyro_lpf2_type'; ...
            'gyro_lowpass2_hz',     'gyro_lpf2_static_hz'; ...
            'dterm_lowpass_type',   'dterm_lpf1_type'; ...
            'dterm_lowpass_hz',     'dterm_lpf1_static_hz'; ...
            'dterm_lowpass2_type',  'dterm_lpf2_type'; ...
            'dterm_lowpass2_hz',    'dterm_lpf2_static_hz'; ...
            'd_min',                'd_max'; ...
            'feedforward_weight',   'ff_weight'; ...
            'dshot_idle_value',     'motor_idle'; ...
            'gyro_to_use',          'gyro_enabled_bitmask'; ...
        };

        % key-based matching: for each row in A, find matching key in B
        for i = 1:nA
            kA = keysA{i};
            idxB = find(strcmp(keysB, kA));
            if isempty(idxB)
                % try alias lookup
                ai = find(strcmp(aliases(:,1), kA));
                if ~isempty(ai)
                    idxB = find(strcmp(keysB, aliases{ai(1),2}));
                else
                    ai = find(strcmp(aliases(:,2), kA));
                    if ~isempty(ai)
                        idxB = find(strcmp(keysB, aliases{ai(1),1}));
                    end
                end
            end
            if isempty(idxB)
                % param only in A
                BGCol(i,:) = diffCol;
                u(i) = true;
            elseif ~strcmp(valsA{i}, valsB{idxB(1)})
                % same param, different value
                BGCol(i,:) = diffCol;
                u(i) = true;
            end
        end

        % mark B rows not in A
        BGColB = repmat(th.panelBg, nB, 1);
        uB = false(nB, 1);
        for i = 1:nB
            kB = keysB{i};
            idxA = find(strcmp(keysA, kB));
            if isempty(idxA)
                ai = find(strcmp(aliases(:,1), kB));
                if ~isempty(ai)
                    idxA = find(strcmp(keysA, aliases{ai(1),2}));
                else
                    ai = find(strcmp(aliases(:,2), kB));
                    if ~isempty(ai)
                        idxA = find(strcmp(keysA, aliases{ai(1),1}));
                    end
                end
            end
            if isempty(idxA)
                BGColB(i,:) = diffCol;
                uB(i) = true;
            elseif ~strcmp(valsB{i}, valsA{idxA(1)})
                BGColB(i,:) = diffCol;
                uB(i) = true;
            end
        end
    end

    delete(findobj(PSdisp, 'Type', 'uitable'));

    diffFg = [1.0 .55 .55];
    tbH = 0.88;
    if get(guiHandlesInfo.checkboxDIFF, 'Value') == 1
         nDiff = sum(u);
         diffBG = repmat(diffCol, max(nDiff,1), 1);
         st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA(u)))]);
         set(st,'units','normalized','Position',[.02 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', [fnameMaster{fA_}]);
         try set(st,'BackgroundColor', diffBG); catch, end
         try set(st,'ForegroundColor', diffFg); catch, end
         try set(st,'RowStriping', 'off'); catch, end
        if Nfiles > 1 && exist('setupB','var')
              nDiffB = sum(uB);
              diffBGB = repmat(diffCol, max(nDiffB,1), 1);
              st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB(uB)))]);
              set(st,'units','normalized','Position',[.52 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', fnameMaster{fB_});
              try set(st,'BackgroundColor', diffBGB); catch, end
              try set(st,'ForegroundColor', diffFg); catch, end
              try set(st,'RowStriping', 'off'); catch, end
        end
    else
        st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupA))]);
         set(st,'units','normalized','Position',[.02 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', [fnameMaster{fA_}]);
         try set(st,'BackgroundColor', BGCol); catch, end
         try set(st,'ForegroundColor', th.textPrimary); catch, end
         try set(st,'RowStriping', 'off'); catch, end
        if Nfiles > 1 && exist('setupB','var')
              st = uitable(PSdisp,'ColumnWidth',{columnWidth},'ColumnFormat',{'char'},'Data',[cellstr(char(setupB))]);
              set(st,'units','normalized','Position',[.52 .02 .45 tbH],'FontSize',fontsz, 'ColumnName', fnameMaster{fB_});
              try set(st,'BackgroundColor', BGColB); catch, end
              try set(st,'ForegroundColor', th.textPrimary); catch, end
              try set(st,'RowStriping', 'off'); catch, end
        end
    end
end
