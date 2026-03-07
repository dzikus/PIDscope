%% PSload - script to load and organize main data and create main directories 

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------


% betaflight debug_modes
% https://github.com/betaflight/betaflight/wiki/Debug-Modes?fbclid=IwAR2bKepD_cNZNnRtlAxf7yf3CWjYm2-MbFuwoGn3tUm8wPefp9CCJQR7c9Y
    
try
    if ~isempty(filenameA)

        %% Detect firmware type change - mixing firmware types causes issues
        current_fw = get(guiHandles.Firmware, 'Value');
        if exist('loaded_firmware','var') && loaded_firmware ~= current_fw && exist('fnameMaster','var') && ~isempty(fnameMaster)
            fw_names = get(guiHandles.Firmware, 'String');
            choice = questdlg( ...
                ['Previously loaded: ' fw_names{loaded_firmware} char(10) ...
                 'Now selected: ' fw_names{current_fw} char(10) char(10) ...
                 'Mixing different firmware types is not supported.' char(10) ...
                 'Reset data before loading?'], ...
                'Firmware type changed', 'Reset & Load', 'Cancel', 'Reset & Load');
            if strcmp(choice, 'Reset & Load')
                clear T dataA tta A_lograte epoch1_A epoch2_A SetupInfo rollPIDF pitchPIDF yawPIDF debugmode debugIdx fwType fwMajor fwMinor gyro_debug_axis notchData;
                fcnt = 0; fnameMaster = {};
                try, delete(subplot('position',posInfo.linepos1)); catch, end
                try, delete(subplot('position',posInfo.linepos2)); catch, end
                try, delete(subplot('position',posInfo.linepos3)); catch, end
                try, delete(subplot('position',posInfo.linepos4)); catch, end
                set(guiHandles.FileNum, 'String', ' ');
                try, set(guiHandles.Epoch1_A_Input, 'String', ' '); set(guiHandles.Epoch2_A_Input, 'String', ' '); catch, end
            else
                return;
            end
        end
        loaded_firmware = current_fw;

        logfile_directory=filepathA;

        us2sec=1000000;
        maxMotorOutput=2000;

   %     set(PSfig, 'pointer', 'watch')
        set(guiHandles.fileA, 'FontWeight', 'Bold');

        pause(.2)
        
        try
            cd(configDir)
            if ~strcmp(main_directory, logfile_directory)
                fid = fopen('logfileDir.txt','w');
                fprintf(fid,'%c',logfile_directory);
                fclose(fid);
            end
        catch
        end

        cd(configDir)
        ldr = ['logfileDirectory: ' logfile_directory ];
        try
            defaults = readtable('PSdefaults.txt');
            a = char([cellstr([char(defaults.Parameters) num2str(defaults.Values)]); {rdr}; {mdr}; {ldr}]);
            t = uitable(PSfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
            set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
        catch
            defaults = ' '; 
            a = char(['Unable to set user defaults '; {rdr}; {mdr}; {ldr}]);
            t = uitable(PSfig, 'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
            set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
        end
        
        fnameMaster = [fnameMaster filenameA];
 
    %    clear T dataA tta A_lograte epoch1_A epoch2_A    SetupInfo rollPIDF pitchPIDF yawPIDF
    
        n = size(filenameA,2);
        waitbarFid = waitbar(0,'Please wait...');
        % Work in temp dir (main_directory may be read-only in AppImage)
        workdir = tempname();
        mkdir(workdir);
        prev_dir = pwd();

        % Copy blackbox_decode into workdir so ./blackbox_decode works
        if ispc()
            decoders = {'blackbox_decode.exe', 'blackbox_decode_INAV.exe'};
        else
            decoders = {'blackbox_decode', 'blackbox_decode_INAV'};
        end
        for dec = decoders
            src = fullfile(main_directory, dec{1});
            if exist(src, 'file')
                copyfile(src, workdir);
            end
        end

        cd(workdir);

        for ii = 1 : n
            source = fullfile(logfile_directory, filenameA{ii});
            try
                copyfile(source, workdir);
            catch e
                warning('PSload: cannot copy %s to workdir: %s', source, e.message);
                continue;
            end

            clear subFiles;
            [filenameA{ii} subFiles] = PSgetcsv(filenameA{ii}, get(guiHandles.Firmware, 'Value'));
            
             
            for jj = 1 : size(subFiles,2)
                waitbar((ii+jj)/(n+size(subFiles,2)+1) , waitbarFid,['Importing File ' int2str(ii) ', Subfile ' int2str(jj)]);

                fcnt = fcnt + 1;
                Nfiles= fcnt;

                [~, ~, sfext] = fileparts(subFiles{jj});
                if strcmpi(sfext, '.bin')
                    % ArduPilot DataFlash binary - direct parse
                    binpath = fullfile(logfile_directory, subFiles{jj});
                    [ardu_data, ardu_parms] = PSarduRead(binpath);
                    [T{fcnt}, SetupInfo{fcnt}, A_lograte(fcnt)] = PSarduConvert(ardu_data, ardu_parms);
                    fnameMaster{fcnt} = subFiles{jj};
                else
                    [dataA(fcnt) fnameMaster{fcnt}] = PSimport(subFiles{jj}, char(filenameA{ii}));
                    T{fcnt}=dataA(fcnt).T;
                    A_lograte(fcnt)=round((1000/median(diff(T{fcnt}.time_us_-T{fcnt}.time_us_(1)))) * 10) / 10;
                    SetupInfo{fcnt}=dataA(fcnt).SetupInfo;
                end

                tta{fcnt}=T{fcnt}.time_us_-T{fcnt}.time_us_(1);

                epoch1_A(fcnt)=round(((tta{fcnt}(1)/us2sec)+LogStDefault)*10) / 10;
                epoch2_A(fcnt)=round(((tta{fcnt}(end)/us2sec)-LogNdDefault)*10) / 10;

                clear a b r p y dm ff
                r = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'rollPID')),2));
                p = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'pitchPID')),2));
                y = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'yawPID')),2));

                %%%%%%%%%% parse firmware version for per-file debug mode indices %%%%%%%%%%
                [fwType{fcnt}, fwMajor(fcnt), fwMinor(fcnt)] = PSparseBFversion(SetupInfo{fcnt});
                debugIdx{fcnt} = PSdebugModeIndices(fwType{fcnt}, fwMajor(fcnt), fwMinor(fcnt));

                %%%%%%%%%% collect debug mode info %%%%%%%%%%
                try
                    debugmode(fcnt) = str2num(char(SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'debug_mode')),2)));
                catch
                    % BF 2025.12+: GYRO_SCALED removed, use GYRO_FILTERED as default
                    if debugIdx{fcnt}.GYRO_SCALED == -1
                        debugmode(fcnt) = debugIdx{fcnt}.GYRO_FILTERED;
                    else
                        debugmode(fcnt) = 6;% default to gyro_scaled
                    end
                end

                %%%%%%%%%% parse gyro_debug_axis (BF 2025.12+, for FFT_FREQ axis) %%%%%%%%%%
                try
                    gyro_debug_axis(fcnt) = str2num(char(SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'gyro_debug_axis')),2)));
                catch
                    gyro_debug_axis(fcnt) = 0; % default Roll
                end

                dm = {};
                % Try d_max first (BF 2025.12+), fallback to d_min (older)
                dm_idx = find(strcmp(SetupInfo{fcnt}(:,1), 'd_max'));
                if isempty(dm_idx)
                    dm_idx = find(strcmp(SetupInfo{fcnt}(:,1), 'd_min'));
                end
                if ~isempty(dm_idx) && ~isempty(SetupInfo{fcnt}(dm_idx,2))
                    dm = SetupInfo{fcnt}(dm_idx, 2);
                else
                    dm = {' , , '};
                end
                ff = {};
                if ~isempty(SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'feedforward_weight') | strcmp(SetupInfo{fcnt}(:,1), 'ff_weight')),2))
                    ff = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'feedforward_weight') | strcmp(SetupInfo{fcnt}(:,1), 'ff_weight')),2));
                else 
                    ff = {' , , '};
                end

                a=strfind(char(dm),',');
                b=strfind(char(ff),',');
                rollPIDF{fcnt} = [char(r) ',' dm{1}(1:a(1)-1) ',' ff{1}(1:b(1)-1)];
                pitchPIDF{fcnt} = [char(p) ',' dm{1}(a(1)+1:a(2)-1) ',' ff{1}(b(1)+1:b(2)-1)];
                yawPIDF{fcnt} = [char(y) ',' dm{1}(a(2)+1:end) ',' ff{1}(b(2)+1:end)];

                if get(guiHandles.Firmware, 'Value') == 3 % INAV
                    T{fcnt}.setpoint_0_ = T{fcnt}.axisRate_0_;
                    T{fcnt}.setpoint_1_ = T{fcnt}.axisRate_1_;
                    T{fcnt}.setpoint_2_ = T{fcnt}.axisRate_2_;
                    T{fcnt}.setpoint_3_ = (T{fcnt}.rcData_3_ - 1000);
                end

                isArduPilot = strcmpi(sfext, '.bin');

                Nsamples = length(T{fcnt}.loopIteration);
                isINAV = (get(guiHandles.Firmware, 'Value') == 3);
                for k = 0 : 3
                  if ~isArduPilot
                    dbg_f = ['debug_' int2str(k) '_'];
                    if ~isfield(T{fcnt}, dbg_f)
                        T{fcnt}.(dbg_f) = zeros(Nsamples, 1);
                    end
                    axF_f = ['axisF_' int2str(k) '_'];
                    if ~isfield(T{fcnt}, axF_f)
                        T{fcnt}.(axF_f) = zeros(Nsamples, 1);
                    end

                    mot_f = ['motor_' int2str(k) '_'];
                    mot8_f = ['motor_' int2str(k+4) '_'];
                    if isINAV
                        if isfield(T{fcnt}, mot_f)
                            T{fcnt}.(mot_f) = (T{fcnt}.(mot_f) - 1000) / 10;
                        end
                        if isfield(T{fcnt}, mot8_f)
                            T{fcnt}.(mot8_f) = (T{fcnt}.(mot8_f) - 1000) / 10;
                        end
                    else
                        if isfield(T{fcnt}, mot_f)
                            T{fcnt}.(mot_f) = T{fcnt}.(mot_f) / 2000 * 100;
                        end
                        if isfield(T{fcnt}, mot8_f)
                            T{fcnt}.(mot8_f) = T{fcnt}.(mot8_f) / 2000 * 100;
                        end
                    end
                  end % ~isArduPilot
                    if k < 3
                        ks = int2str(k);
                        if k < 2 % compute prefiltered dterm
                          try
                            dpf_f = ['axisDpf_' ks '_'];
                            T{fcnt}.(dpf_f) = -[0; diff(T{fcnt}.(['gyroADC_' ks '_']))];
                            d1 = smooth(T{fcnt}.(dpf_f), 100);
                            d2 = smooth(T{fcnt}.(['axisD_' ks '_']), 100);
                            d3 = d2 ./ d1;
                            sclr = nanmedian(d3(~isinf(d3) & d3 > 0));
                            T{fcnt}.(dpf_f) = T{fcnt}.(dpf_f) * sclr;
                          catch, end
                        end

                        T{fcnt}.(['piderr_' ks '_']) = T{fcnt}.(['gyroADC_' ks '_']) - T{fcnt}.(['setpoint_' ks '_']);
                        try
                            T{fcnt}.(['pidsum_' ks '_']) = T{fcnt}.(['axisP_' ks '_']) + T{fcnt}.(['axisI_' ks '_']) + T{fcnt}.(['axisD_' ks '_']) + T{fcnt}.(['axisF_' ks '_']);
                        catch
                            T{fcnt}.(['pidsum_' ks '_']) = T{fcnt}.(['axisP_' ks '_']) + T{fcnt}.(['axisI_' ks '_']) + T{fcnt}.(['axisF_' ks '_']);
                        end
                    end
                end
            end
        end
        % Clean up workdir
        cd(prev_dir);
        try if ispc(), system(['rmdir /s /q "' workdir '"']); else system(['rm -rf ' workdir]); end; catch, end
    end

    try close(waitbarFid), catch, end
catch  ME
    try cd(prev_dir); catch, end
    try if ispc(), system(['rmdir /s /q "' workdir '"']); else system(['rm -rf ' workdir]); end; catch, end
    try close(waitbarFid); catch, end
    warning('PSload error: %s', ME.message);
    for k = 1:numel(ME.stack)
        warning('  in %s at line %d', ME.stack(k).name, ME.stack(k).line);
    end
end

