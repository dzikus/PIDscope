%% PTsaveSettings

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

%% create saveDirectory
if ~isempty(fnameMaster) 
  

%%
set(gcf, 'pointer', 'watch')
try
    cd(main_directory)
    clear defaults
    if ~isfile('PTBdefaults.txt')
        clear var
        var(1,:) = [{'firmware'  1}];
        var(2,:) = [{'LogViewer-SinglePanel' 0}];
        var(3,:) = [{'LogViewer-plotR' 1}];
        var(4,:) = [{'LogViewer-plotP' 1}];
        var(5,:) = [{'LogViewer-plotY' 1}];
        var(6,:) = [{'LogViewer-lineSmooth' 1}];
        var(7,:) = [{'LogViewer-lineWidth' 3}];  
        var(8,:) = [{'LogViewer-Ymax' 500}];
        var(9,:) = [{'LogViewer-Ncolors' 8}]; 
        var(10,:) = [{'spec2D-term1' 1}];
        var(11,:) = [{'spec2D-term2' 2}];
        var(12,:) = [{'spec2D-smoothing' 3}];
        var(13,:) = [{'spec2D-delay' 1}];
        var(14,:) = [{'spec2D-plotR' 1}];
        var(15,:) = [{'spec2D-plotP' 1}];
        var(16,:) = [{'spec2D-plotY' 1}];
        var(17,:) = [{'spec2D-SinglePanel' 0}];    
        var(18,:) = [{'FreqXthr-Column1' 3}];
        var(19,:) = [{'FreqXthr-Column2' 2}];
        var(20,:) = [{'FreqXthr-Column3' 8}];
        var(21,:) = [{'FreqXthr-Column4' 7}]; 
        var(22,:) = [{'FreqXthr-Preset' 1}];
        var(23,:) = [{'FreqXthr-Colormap' 3}];
        var(24,:) = [{'FreqXthr-Smoothing' 3}];
        var(25,:) = [{'FreqxTime-Preset' 2}];
        var(26,:) = [{'FreqxTime-FreqSmoothing' 2}];
        var(27,:) = [{'FreqxTime-TimeSmoothing' 2}];
        var(28,:) = [{'FreqxTime-Colormap' 3}];
        var(29,:) = [{'StepResp-plotR' 1}];
        var(30,:) = [{'StepResp-plotP' 1}];
        var(31,:) = [{'StepResp-plotY' 1}];
        var(32,:) = [{'StepResp-SinglePanel' 0}];
        var(33,:) = [{'StepResp-Ymax' 1.75}];

        defaults = cell2table(var, 'VariableNames',{'Parameters' ; 'Values'});
    else
        defaults = readtable('PTBdefaults.txt');
    end
catch
end

try
    defaults.Values(1) = get(guiHandles.Firmware, 'Value');
    defaults.Values(2) = get(guiHandles.RPYcomboLV, 'Value');
    defaults.Values(3) = get(guiHandles.plotR, 'Value');
    defaults.Values(4) = get(guiHandles.plotP, 'Value');
    defaults.Values(5) = get(guiHandles.plotY, 'Value');
    defaults.Values(6) = get(guiHandles.lineSmooth, 'Value');
    defaults.Values(7) = get(guiHandles.linewidth, 'Value');
    defaults.Values(8) = str2num(get(guiHandles.maxY_input, 'String'));
    defaults.Values(9) = str2num(get(guiHandles.nCols_input, 'String'));
catch
end
try
    tmpSpecListVal = get(guiHandlesSpec2.SpecList, 'Value');
    defaults.Values(10) = tmpSpecListVal(1);
    defaults.Values(11) = tmpSpecListVal(2);
    defaults.Values(12) = get(guiHandlesSpec2.smoothFactor_select, 'Value');
    defaults.Values(13) = get(guiHandlesSpec2.Delay, 'Value');
    defaults.Values(14) = get(guiHandlesSpec2.plotR, 'Value');
    defaults.Values(15) = get(guiHandlesSpec2.plotP, 'Value');
    defaults.Values(16) = get(guiHandlesSpec2.plotY, 'Value');
    defaults.Values(17) = get(guiHandlesSpec2.RPYcomboSpec, 'Value');
catch
end
try
    defaults.Values(18) = get(guiHandlesSpec.SpecSelect{1}, 'Value');
    defaults.Values(19) = get(guiHandlesSpec.SpecSelect{2}, 'Value');
    defaults.Values(20) = get(guiHandlesSpec.SpecSelect{3}, 'Value');
    defaults.Values(21) = get(guiHandlesSpec.SpecSelect{4}, 'Value');
    defaults.Values(22) = get(guiHandlesSpec.specPresets, 'Value');
    defaults.Values(23) = get(guiHandlesSpec.ColormapSelect, 'Value');
    defaults.Values(24) = get(guiHandlesSpec.smoothFactor_select, 'Value');
catch
end

try
    defaults.Values(25) = get(guiHandlesSpec3.SpecList, 'Value');
    defaults.Values(26) = get(guiHandlesSpec3.smoothFactor_select, 'Value');
    defaults.Values(27) = get(guiHandlesSpec3.subsampleFactor_select, 'Value');
    defaults.Values(28) = get(guiHandlesSpec3.ColormapSelect, 'Value');
catch
end
try
    defaults.Values(29) = get(guiHandlesTune.plotR, 'Value');
    defaults.Values(30) = get(guiHandlesTune.plotP, 'Value');
    defaults.Values(31) = get(guiHandlesTune.plotY, 'Value');
    defaults.Values(32) = get(guiHandlesTune.RPYcombo, 'Value');
    defaults.Values(33) = str2num(get(guiHandlesTune.maxYStepInput, 'String'));
catch
end

try
    writetable(defaults, 'PTBdefaults')
catch
end

try    
    fid = fopen('logfileDir.txt','r');
    logfile_directory = fscanf(fid, '%c');
    fclose(fid);
catch
    logfile_directory = [pwd '/'];
end

ldr = ['logfileDirectory: ' logfile_directory ];

try
    defaults = readtable('PTBdefaults.txt');
    a = char([cellstr([char(defaults.Parameters) num2str(defaults.Values)]); {rdr}; {mdr}; {ldr}]);
    t = uitable(PTfig,'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
catch
    defaults = ' '; 
    a = char(['Unable to set user defaults '; {rdr}; {mdr}; {ldr}]);
    t = uitable(PTfig,'ColumnWidth',{500},'ColumnFormat',{'char'},'Data',[cellstr(a)]);
    set(t,'units','normalized','Position',infoTablePos,'FontSize',fontsz*.8, 'ColumnName', [''])
end

clear var

set(gcf, 'pointer', 'arrow')

else
     warndlg('Please select file(s)');
end