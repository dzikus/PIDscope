%% PTtimeFreq - time freq spectrogram

% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------
    

%% update fonts 
set(PTspecfig3, 'pointer', 'watch')

figure(PTspecfig3)
PTspecfig3_pos = get(PTspecfig3, 'Position');
if PTspecfig3_pos(3) > 10, PTspecfig3_pos(3:4) = PTspecfig3_pos(3:4) ./ get(0,'ScreenSize')(3:4); end
prop_max_screen=(max([PTspecfig3_pos(3) PTspecfig3_pos(4)]));
fontsz=(screensz_multiplier*prop_max_screen);

f = fields(guiHandlesSpec3);
for i = 1 : size(f,1)
    try set(guiHandlesSpec3.(f{i}), 'FontSize', fontsz); catch, end
end

specSmoothFactors = [1 5 10 20];
timeSmoothFactors = [1 2 5 10];

if get(guiHandlesSpec3.sub100HzfreqTime, 'Value')
    fLim_freqTime = 100;
else
    fLim_freqTime = 1000;
end

s1={'gyroADC';'debug';'axisD';'axisDpf';'axisP';'piderr';'setpoint';'pidsum'};
datSelectionString=[s1];
axisLabel ={'Roll'; 'Pitch' ; 'Yaw'};
tmpFileVal3 = get(guiHandlesSpec3.FileSelect, 'Value');
tmpSpecVal3 = get(guiHandlesSpec3.SpecList, 'Value');
tmpSmoothVal3 = get(guiHandlesSpec3.smoothFactor_select, 'Value');
tmpSubVal3 = get(guiHandlesSpec3.subsampleFactor_select, 'Value');
for i = 1 : 3
    delete(subplot('position',posInfo.Spec3Pos(i,:)));
    try
    if ~updateSpec
        eval(['dat = T{tmpFileVal3}.' char(datSelectionString(tmpSpecVal3)) '_' int2str(i-1) '_(tIND{tmpFileVal3})'';';])
        [Tm F specMat{i}] = PTtimeFreqCalc(dat', A_lograte(tmpFileVal3), specSmoothFactors(tmpSmoothVal3), timeSmoothFactors(tmpSubVal3));
    end
    
    h2=subplot('position',posInfo.Spec3Pos(i,:));
    h = imagesc(specMat{i});

    set(gca,'Clim',[ClimScale3], 'fontsize',fontsz,'fontweight','bold')
    title('');
    set(get(gca,'Ylabel'), 'String', ['Frequency (Hz) ' axisLabel{i}]);
    set(get(gca,'Xlabel'), 'String', 'Time (sec)');
    F2 = F(F<=fLim_freqTime);
    freqStr = flipud(int2str((0: F2(end) / 5: F2(end))'));
    timeStr = int2str((0: round(Tm(end)) / 10: round(Tm(end)))');
    
    st = find(fliplr(F<=fLim_freqTime),1, 'first');
    nd = find(fliplr(F<=fLim_freqTime),1, 'last');
    set(gca,'YLim', [st nd])
    set(gca,'Ytick', [st : (nd-st) / 5: nd], 'YTickLabel',[freqStr], 'YMinorTick', 'on', 'Xtick', [0 : round( (size(specMat{i},2)-1) / 10) : size(specMat{i},2)],'XTickLabel',[timeStr], 'XMinorTick', 'on', 'TickDir', 'out');
        
    if get(guiHandlesSpec3.ColormapSelect, 'Value')<=7,
        colormap(char(get(guiHandlesSpec3.ColormapSelect, 'String')(get(guiHandlesSpec3.ColormapSelect, 'Value'))));
    end
    if get(guiHandlesSpec3.ColormapSelect, 'Value')==8, colormap(linearREDcmap); end
    if get(guiHandlesSpec3.ColormapSelect, 'Value')==9, colormap(linearGREYcmap); end
    cbar = colorbar('EastOutside');
    set(get(cbar, 'Label'), 'String', 'Power Spectral density (dB)');
  
    if i == 3 && (strcmp(char(datSelectionString(get(guiHandlesSpec3.SpecList, 'Value'))), 'axisD') || strcmp(char(datSelectionString(get(guiHandlesSpec3.SpecList, 'Value'))), 'axisDpf'))
        delete(subplot('position',posInfo.Spec3Pos(i,:))); 
    end
    box off
    
    catch
        delete(subplot('position',posInfo.Spec3Pos(i,:))); 
    end
end
updateSpec = 0;

set(PTspecfig3, 'pointer', 'arrow')

