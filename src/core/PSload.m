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
                clear T dataA tta A_lograte epoch1_A epoch2_A SetupInfo rollPIDF pitchPIDF yawPIDF debugmode debugIdx fwType fwMajor fwMinor gyro_debug_axis notchData rpmFilterData ampmat freq2d2 amp2d2 specMat delayDataReady FilterDelayDterm SPGyroDelay Debug01 Debug02 gyro_phase_shift_deg dterm_phase_shift_deg tuneCrtlpanel_init setupInfoWidgets_init;
                fcnt = 0; fnameMaster = {}; Nfiles = 0;
                try, delete(checkpanel); clear checkpanel; catch, end
                % Delete tagged plot axes (never use subplot — creates blank axes)
                try delete(findobj(PSfig,'Tag','PSrpy')); catch, end
                try delete(findobj(PSfig,'Tag','PSmotor')); catch, end
                try delete(findobj(PSfig,'Tag','PScombo')); catch, end
                % Delete overlay widgets
                ov = getappdata(PSfig, 'PSoverlay');
                if ~isempty(ov)
                    flds = fieldnames(ov);
                    for fi=1:numel(flds), try delete(ov.(flds{fi})); catch, end; end
                    setappdata(PSfig, 'PSoverlay', []);
                end
                figs=findobj('Type','figure'); for fi=1:numel(figs), if figs(fi)~=PSfig, try, close(figs(fi)); catch, end; end; end
                clear PSspecfig PSspecfig2 PSspecfig3 PStunefig PSerrfig PSstatsfig PSdisp errCrtlpanel statsCrtlpanel spec2Crtlpanel specCrtlpanel freqTimeCrtlpanel tuneCrtlpanel;
                set(guiHandles.FileNum, 'String', ' ');
                try, set(guiHandles.Epoch1_A_Input, 'String', ' '); set(guiHandles.Epoch2_A_Input, 'String', ' '); catch, end
                try setappdata(PSfig, 'smoothCacheLV', struct()); catch, end
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
        catch
            defaults = ' ';
            a = char(['Unable to set user defaults '; {rdr}; {mdr}; {ldr}]);
        end
        
        fnameMaster = [fnameMaster filenameA];
 
    %    clear T dataA tta A_lograte epoch1_A epoch2_A    SetupInfo rollPIDF pitchPIDF yawPIDF
    
        n = size(filenameA,2);
        waitbarFid = waitbar(0,'Please wait...');
        workdir = tempname();
        mkdir(workdir);

        for ii = 1 : n
            srcFile = fullfile(logfile_directory, filenameA{ii});

            clear subFiles;
            [filenameA{ii} subFiles] = PSgetcsv(srcFile, get(guiHandles.Firmware, 'Value'), workdir);
            
             
            for jj = 1 : size(subFiles,2)
                waitbar((ii+jj)/(n+size(subFiles,2)+1) , waitbarFid,['Importing File ' int2str(ii) ', Subfile ' int2str(jj)]);

                fcnt = fcnt + 1;
                Nfiles= fcnt;

                [~, ~, sfext] = fileparts(subFiles{jj});
                if strcmpi(sfext, '.bin')
                    % ArduPilot DataFlash binary - direct parse
                    [ardu_data, ardu_parms] = PSarduRead(subFiles{jj});
                    [T{fcnt}, SetupInfo{fcnt}, A_lograte(fcnt)] = PSarduConvert(ardu_data, ardu_parms);
                    [~, sfname, sfx] = fileparts(subFiles{jj});
                    fnameMaster{fcnt} = [sfname sfx];
                else
                    [dataA(fcnt) fnameMaster{fcnt}] = PSimport(subFiles{jj}, filenameA{ii});
                    T{fcnt}=dataA(fcnt).T;
                    A_lograte(fcnt)=round((1000/median(diff(T{fcnt}.time_us_-T{fcnt}.time_us_(1)))) * 10) / 10;
                    SetupInfo{fcnt}=dataA(fcnt).SetupInfo;
                end

                tta{fcnt}=T{fcnt}.time_us_-T{fcnt}.time_us_(1);

                epoch1_A(fcnt)=round(((tta{fcnt}(1)/us2sec)+LogStDefault)*10) / 10;
                epoch2_A(fcnt)=round(((tta{fcnt}(end)/us2sec)-LogNdDefault)*10) / 10;

                clear a b r p y dm ff

                %%%%%%%%%% parse firmware version for per-file debug mode indices %%%%%%%%%%
                [fwType{fcnt}, fwMajor(fcnt), fwMinor(fcnt)] = PSparseBFversion(SetupInfo{fcnt});
                debugIdx{fcnt} = PSdebugModeIndices(fwType{fcnt}, fwMajor(fcnt), fwMinor(fcnt));

                %%%%%%%%%% collect debug mode info %%%%%%%%%%
                try
                    debugmode(fcnt) = str2double(char(SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'debug_mode')),2)));
                catch
                    if debugIdx{fcnt}.GYRO_SCALED == -1
                        debugmode(fcnt) = debugIdx{fcnt}.GYRO_FILTERED;
                    else
                        debugmode(fcnt) = 6;
                    end
                end

                try
                    gyro_debug_axis(fcnt) = str2double(char(SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'gyro_debug_axis')),2)));
                catch
                    gyro_debug_axis(fcnt) = 0;
                end

                try
                    r = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'rollPID')),2));
                    p = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'pitchPID')),2));
                    y = (SetupInfo{fcnt}(find(strcmp(SetupInfo{fcnt}(:,1), 'yawPID')),2));
                    dm_idx = find(strcmp(SetupInfo{fcnt}(:,1), 'd_max'));
                    if isempty(dm_idx), dm_idx = find(strcmp(SetupInfo{fcnt}(:,1), 'd_min')); end
                    if ~isempty(dm_idx) && ~isempty(SetupInfo{fcnt}(dm_idx,2))
                        dm = SetupInfo{fcnt}(dm_idx, 2);
                    else
                        dm = {' , , '};
                    end
                    ff_idx = find(strcmp(SetupInfo{fcnt}(:,1), 'feedforward_weight') | strcmp(SetupInfo{fcnt}(:,1), 'ff_weight'));
                    if ~isempty(ff_idx) && ~isempty(SetupInfo{fcnt}(ff_idx,2))
                        ff = SetupInfo{fcnt}(ff_idx, 2);
                    else
                        ff = {' , , '};
                    end
                    a=strfind(char(dm),',');
                    b=strfind(char(ff),',');
                    rollPIDF{fcnt} = [char(r) ',' dm{1}(1:a(1)-1) ',' ff{1}(1:b(1)-1)];
                    pitchPIDF{fcnt} = [char(p) ',' dm{1}(a(1)+1:a(2)-1) ',' ff{1}(b(1)+1:b(2)-1)];
                    yawPIDF{fcnt} = [char(y) ',' dm{1}(a(2)+1:end) ',' ff{1}(b(2)+1:end)];
                catch
                    rollPIDF{fcnt} = '0,0,0,0,0';
                    pitchPIDF{fcnt} = '0,0,0,0,0';
                    yawPIDF{fcnt} = '0,0,0,0,0';
                end

                fwSel = get(guiHandles.Firmware, 'Value');
                if fwSel == 3 % INAV
                    T{fcnt}.setpoint_0_ = T{fcnt}.axisRate_0_;
                    T{fcnt}.setpoint_1_ = T{fcnt}.axisRate_1_;
                    T{fcnt}.setpoint_2_ = T{fcnt}.axisRate_2_;
                    T{fcnt}.setpoint_3_ = (T{fcnt}.rcData_3_ - 1000);
                end
                if fwSel == 6 % Rotorflight: setpoint_3_ is collective, use rcCommand[4] as throttle
                    if isfield(T{fcnt}, 'rcCommand_4_')
                        T{fcnt}.setpoint_3_ = T{fcnt}.rcCommand_4_;
                    end
                end
                % KISS/FETTEC: synthesize setpoint from rcCommand if missing
                if ~isfield(T{fcnt}, 'setpoint_0_') && isfield(T{fcnt}, 'rcCommand_0_')
                    for ax = 0:2
                        T{fcnt}.(['setpoint_' int2str(ax) '_']) = T{fcnt}.(['rcCommand_' int2str(ax) '_']);
                    end
                    T{fcnt}.setpoint_3_ = (T{fcnt}.rcCommand_3_ - 1000) / 10;
                elseif ~isfield(T{fcnt}, 'setpoint_0_')
                    for ax = 0:3
                        T{fcnt}.(['setpoint_' int2str(ax) '_']) = zeros(length(T{fcnt}.loopIteration), 1);
                    end
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
                  % Rotorflight: fill empty motor slots with servo data
                  if fwSel == 6 && k == 3
                      nMotReal = 0;
                      for mm = 0:3
                          if isfield(T{fcnt}, ['motor_' int2str(mm) '_']), nMotReal = mm+1; end
                      end
                      si = 0;
                      for mm = nMotReal:3
                          sf = ['servo_' int2str(si) '_'];
                          mf = ['motor_' int2str(mm) '_'];
                          if isfield(T{fcnt}, sf)
                              T{fcnt}.(mf) = (T{fcnt}.(sf) - 1000) / 10;
                          end
                          si = si + 1;
                      end
                      try setappdata(PSfig, 'rfMotorCount', nMotReal); catch, end
                  end
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

                        try
                            T{fcnt}.(['piderr_' ks '_']) = T{fcnt}.(['gyroADC_' ks '_']) - T{fcnt}.(['setpoint_' ks '_']);
                        catch
                            T{fcnt}.(['piderr_' ks '_']) = zeros(Nsamples, 1);
                        end
                        try
                            T{fcnt}.(['pidsum_' ks '_']) = T{fcnt}.(['axisP_' ks '_']) + T{fcnt}.(['axisI_' ks '_']) + T{fcnt}.(['axisD_' ks '_']) + T{fcnt}.(['axisF_' ks '_']);
                        catch
                            try
                                T{fcnt}.(['pidsum_' ks '_']) = T{fcnt}.(['axisP_' ks '_']) + T{fcnt}.(['axisI_' ks '_']) + T{fcnt}.(['axisF_' ks '_']);
                            catch
                                T{fcnt}.(['pidsum_' ks '_']) = zeros(Nsamples, 1);
                            end
                        end
                    end
                end
            end
        end
        % Clean up workdir
        try if ispc(), system(['rmdir /s /q "' workdir '"']); else system(['rm -rf ' workdir]); end; catch, end
    end

    try close(waitbarFid), catch, end

catch  ME
    try if ispc(), system(['rmdir /s /q "' workdir '"']); else system(['rm -rf ' workdir]); end; catch, end
    try close(waitbarFid); catch, end
    warning('PSload error: %s', ME.message);
    for k = 1:numel(ME.stack)
        warning('  in %s at line %d', ME.stack(k).name, ME.stack(k).line);
    end
end

