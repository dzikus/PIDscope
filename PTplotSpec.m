%% PTplotSpec - script that computes and plots spectrograms 


% ----------------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <brian.white@queensu.ca> wrote this file. As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return. -Brian White
% ----------------------------------------------------------------------------------

if exist('fnameMaster','var') && ~isempty(fnameMaster)
   
PTspecfig_pos = get(PTspecfig, 'Position');
screensz_tmp = get(0,'ScreenSize'); if PTspecfig_pos(3) > 10, PTspecfig_pos(3:4) = PTspecfig_pos(3:4) ./ screensz_tmp(3:4); end
prop_max_screen=(max([PTspecfig_pos(3) PTspecfig_pos(4)]));
fontsz=(screensz_multiplier*prop_max_screen);
%% update fonts

f = fields(guiHandlesSpec);
for i = 1 : size(f,1)
    try
        h = guiHandlesSpec.(f{i});
        if iscell(h)
            for ci = 1:numel(h), set(h{ci}, 'FontSize', fontsz); end
        else
            set(h, 'FontSize', fontsz);
        end
    catch
    end
end

guiHandlesSpec.climMax_input = uicontrol(PTspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 1))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 1)=str2num(get(guiHandlesSpec.climMax_input, ''String''));updateSpec=1;PTplotSpec;');

guiHandlesSpec.climMax_input2 = uicontrol(PTspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 2))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input2],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 2)=str2num(get(guiHandlesSpec.climMax_input2, ''String''));updateSpec=1;PTplotSpec;');

guiHandlesSpec.climMax_input3 = uicontrol(PTspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 3))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input3],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 3)=str2num(get(guiHandlesSpec.climMax_input3, ''String''));updateSpec=1;PTplotSpec;');
 
guiHandlesSpec.climMax_input4 = uicontrol(PTspecfig,'style','edit','string',[num2str(climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, 4))],'fontsize',fontsz,'TooltipString',[TooltipString_scale],'units','normalized','Position',[posInfo.climMax_input4],...
     'callback','@textinput_call2; climScale(get(guiHandlesSpec.checkboxPSD, ''Value'')+1, 4)=str2num(get(guiHandlesSpec.climMax_input4, ''String''));updateSpec=1;PTplotSpec;');

%%

s1={'';'gyroADC';'debug';'piderr';'setpoint';'axisP';'axisD';'axisDpf';'pidsum'};

datSelectionString=[s1];

clear vars
for i=1:4
    vars(i)=get(guiHandlesSpec.SpecSelect{i}, 'Value');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%% compute fft %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if get(guiHandlesSpec.SpecSelect{1}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{2}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{3}, 'Value')>1 || get(guiHandlesSpec.SpecSelect{4}, 'Value')>1
    set(PTspecfig, 'pointer', 'watch')
    if updateSpec==0 
        clear s dat ampmat amp2d freq a RC smat amp2d freq2d Throt
        p=0;
         hw = waitbar(0,['please wait... ' ]); 

        tmpPSDVal = get(guiHandlesSpec.checkboxPSD, 'Value');
        for k=1:length(vars)
            tmpFileSelK = get(guiHandlesSpec.FileSelect{k}, 'Value');
            s=char(datSelectionString(vars(k)));
            for a=1:3,
                if  ( ( ~isempty(strfind(s,'axisD'))) && a==3) || isempty(s)
                    p=p+1;
                    smat{p}=[];%string
                    ampmat{p}=[];%spec matrix
                    freq{p}=[];% freq matrix
                    amp2d{p}=[];%spec 2d
                    freq2d{p}=[];% freq2d
                else
                    p=p+1;
                    try
                    eval(['dat{k}(a,:) = T{tmpFileSelK}.' char(datSelectionString(vars(k))) '_' int2str(a-1) '_(tIND{tmpFileSelK});';])
                    Throt=T{tmpFileSelK}.setpoint_3_(tIND{tmpFileSelK}) / 10;% throttle
                    lograte = A_lograte(tmpFileSelK);%in kHz
                    waitbar(min(1, p/12), hw, ['processing spectrogram... '  int2str(p) ]);
                    smat{p}=s;
                    [freq{p} ampmat{p}]=PTthrSpec(Throt, dat{k}(a,:), lograte, tmpPSDVal); % compute matrices
                    [freq2d{p} amp2d{p}]=PTSpec2d(dat{k}(a,:),lograte, tmpPSDVal); %compute 2d amp spec at same time
                    catch ME
                        warning('PTplotSpec compute p=%d: %s', p, ME.message);
                        smat{p}=[]; ampmat{p}=[]; freq{p}=[]; amp2d{p}=[]; freq2d{p}=[];
                    end
               end
            end
        end
        close(hw)
    end
else
    hwarn=warndlg({'Dropdowns set to ''NONE''.'; 'Please select a preset or specific variables to analyze.'});
    pause(3);
    try
        close(hwarn);
    catch
    end
end

if get(guiHandlesSpec.checkbox2d, 'Value')==0 && ~isempty(ampmat)
    figure(PTspecfig);
    %%%%% plot spec mattrices
    c1=[1 1 1 2 2 2 3 3 3 4 4 4];
    c2=[1 2 3 1 2 3 1 2 3 1 2 3];
    baselineY = [0 -40];
    ftr = fspecial('gaussian',[get(guiHandlesSpec.smoothFactor_select, 'Value')*5 get(guiHandlesSpec.smoothFactor_select, 'Value')],4);
    for p=1:size(ampmat,2)
        try delete(subplot('position',posInfo.SpecPos(p,:))); catch, end
        if ~isempty(ampmat{p})
        try
            delete(subplot('position',posInfo.SpecPos(p,:)));
            h1=subplot('position',posInfo.SpecPos(p,:)); cla
            img = flipud((filter2(ftr, ampmat{p} ))') + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
            imagesc(img); 

            lograte=A_lograte(get(guiHandlesSpec.FileSelect{c1(p)}, 'Value'));

             axLabel={'roll';'pitch';'yaw'};
            
            if get(guiHandlesSpec.Sub100HzCheck{c1(p)}, 'Value')==1
                hold on;h=plot([0 100],[size(ampmat{p},2)-round(Flim1/3.33) size(ampmat{p},2)-round(Flim1/3.33)],'y--');set(h,'linewidth',2) 
                hold on;h=plot([0 100],[size(ampmat{p},2)-round(Flim2/3.33) size(ampmat{p},2)-round(Flim2/3.33)],'y--');set(h,'linewidth',2)
                % sub100Hz scaling           
                xticks=[1 size(ampmat{p},1)/5:size(ampmat{p},1)/5:size(ampmat{p},1)];
                yticks=[(size(ampmat{p},2)-30):6:size(ampmat{p},2)];
                set(h1,'PlotBoxAspectRatioMode','auto','ylim',[size(ampmat{p},2)-30 size(ampmat{p},2)])
                set(h1,'fontsize',fontsz,'CLim',[baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'YTick',yticks,'yticklabel',{'100';'80';'60';'40';'20';'0'},'XTick',xticks,'xticklabel',{'0';'20';'40';'60';'80';'100'},'tickdir','out','xminortick','on','yminortick','on');
                a=[];a2=[];a=filter2(ftr, ampmat{p}) + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
                a2 = a(:,(round(Flim1/3.33))+1:(round(Flim2/3.33)));
                meanspec=nanmean(a2(:));
                peakspec=max(max(a(:,(round(Flim1/3.33))+1:(round(Flim2/3.33)))));
                if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9          
                    h=text(64,(size(ampmat{p},2)-30)+3,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                    h=text(64,(size(ampmat{p},2)-30)+1,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                else
                    h=text(64,(size(ampmat{p},2)-30)+3,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                    h=text(64,(size(ampmat{p},2)-30)+1,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                end  
                h=text(xticks(1)+1,(size(ampmat{p},2)-30)+1,axLabel{c2(p)});
                set(h,'Color',[1 1 1],'fontsize',fontsz,'fontweight','bold')                       
            else % full scaling
                xticks=[1 size(ampmat{p},1)/5:size(ampmat{p},1)/5:size(ampmat{p},1)];
                yticks=[1:(size(ampmat{p},2))/10:size(ampmat{p},2) size(ampmat{p},2)];
                maxHz = max(round(yticks * 3.333));
                ytlbl = {num2str(maxHz), '', num2str(round(maxHz*4/5)), '', num2str(round(maxHz*3/5)), '', num2str(round(maxHz*2/5)), '', num2str(round(maxHz*1/5)), '', '0'};
                set(h1,'fontsize',fontsz,'CLim',[baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'YTick',yticks,'yticklabel',ytlbl,'XTick',xticks,'xticklabel',{'0';'20';'40';'60';'80';'100'},'tickdir','out','xminortick','on','yminortick','on');
                set(h1,'PlotBoxAspectRatioMode','auto','ylim',[1 size(ampmat{p},2)])  
                a=[];a2=[];a=filter2(ftr, ampmat{p}) + baselineY(get(guiHandlesSpec.checkboxPSD, 'Value')+1);
                a2 = a(:,(size(ampmat{p},2)/10):size(ampmat{p},2));
                meanspec=nanmean(a2(:));
                peakspec=max(max(a(:,(size(ampmat{p},2)/10):size(ampmat{p},2))));
                if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9
                    h=text(64,size(ampmat{p},2)*.04,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                    h=text(64,size(ampmat{p},2)*.13,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','k','fontsize',fontsz,'fontweight','bold');
                else
                    h=text(64,size(ampmat{p},2)*.04,['mean=' num2str(meanspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                    h=text(64,size(ampmat{p},2)*.13,['peak=' num2str(peakspec,3)]);
                    set(h,'Color','w','fontsize',fontsz,'fontweight','bold');
                end    
                h=text(xticks(1)+1,size(ampmat{p},2)*.04,axLabel{c2(p)});
                set(h,'Color',[1 1 1],'fontsize',fontsz,'fontweight','bold')   
            end
            
                        
            grid on
            ax = gca;
            set(ax, 'GridColor', [1 1 1]);
            if get(guiHandlesSpec.ColormapSelect, 'Value')==8 || get(guiHandlesSpec.ColormapSelect, 'Value')==9
                set(ax, 'GridColor', [0 0 0]); % black on white background
                set(h,'Color',[0 0 0],'fontsize',fontsz,'fontweight','bold')             
            end
             ylabel('Frequency (Hz)','fontweight','bold') 
             xlabel('% Throttle','fontweight','bold')
        catch ME
            warning('PTplotSpec render p=%d: %s', p, ME.message);
        end
        end
    end

    % color bar2 at the top 
    try
    delete(hCbar1);delete(hCbar2);delete(hCbar3);delete(hCbar4)
    catch
    end
    if vars(1)>1 % 1=none
        subplot('position',posInfo.SpecPos(1,:));
        hCbar1= colorbar('NorthOutside');
        set(hCbar1,'Position', [posInfo.hCbar1pos]);
    end
    if vars(2)>1 % 1=none
        subplot('position',posInfo.SpecPos(4,:));
        hCbar2= colorbar('NorthOutside');
        set(hCbar2,'Position', [posInfo.hCbar2pos])
    end
    if vars(3)>1 % 1=none
        subplot('position',posInfo.SpecPos(7,:));
        hCbar3= colorbar('NorthOutside');
        set(hCbar3,'Position', [posInfo.hCbar3pos])
    end
    if vars(4)>1 % 1=none
        subplot('position',posInfo.SpecPos(10,:));
        hCbar4= colorbar('NorthOutside');
        set(hCbar4,'Position', [posInfo.hCbar4pos])
    end

    % color maps
    % standard set (Octave: viridis replaces parula at index 1)
    try
    if get(guiHandlesSpec.ColormapSelect, 'Value')<=7,
        tmpCmapStr = get(guiHandlesSpec.ColormapSelect, 'String');
        tmpCmapVal = get(guiHandlesSpec.ColormapSelect, 'Value');
        colormap(char(tmpCmapStr(tmpCmapVal)));
    end
    if get(guiHandlesSpec.ColormapSelect, 'Value')==8, colormap(linearREDcmap); end
    if get(guiHandlesSpec.ColormapSelect, 'Value')==9, colormap(linearGREYcmap); end
    catch, end

end

if get(guiHandlesSpec.checkbox2d, 'Value')==1 && ~isempty(amp2d)
    figure(PTspecfig);
    try
    delete(hCbar1);delete(hCbar2);delete(hCbar3);delete(hCbar4)
    catch
    end
    baselineYlines = [0 -50];
    c1=[1 1 1 2 2 2 3 3 3 4 4 4];
    c2=[1 2 3 1 2 3 1 2 3 1 2 3]; 
    %%%%% plot 2d amp spec
    for p=1:size(amp2d,2)
         axLabel={'roll';'pitch';'yaw'};
       
        delete(subplot('position',posInfo.SpecPos(p,:)));
        if ~isempty(amp2d{p})
            h2=subplot('position',posInfo.SpecPos(p,:)); cla
            h=plot(freq2d{p}, smooth(amp2d{p}, log10(size(amp2d{p},1)) * (get(guiHandlesSpec.smoothFactor_select, 'Value')^2), 'lowess'));hold on
            set(h, 'linewidth', get(guiHandles.linewidth, 'Value')/2)
            set(h2,'fontsize',fontsz,'fontweight','bold')
            if get(guiHandlesSpec.specPresets, 'Value') <= 3
                set(h,'Color',[SpecLineCols(c1(p),:,1)])
            end
            if get(guiHandlesSpec.specPresets, 'Value') > 4 && get(guiHandlesSpec.specPresets, 'Value') <= 6
                set(h,'Color',[SpecLineCols(c1(p),:,2)])
            end
            if get(guiHandlesSpec.specPresets, 'Value') > 6
                set(h,'Color',[SpecLineCols(c1(p),:,3)])
            end
            
            if get(guiHandlesSpec.Sub100HzCheck{c1(p)}, 'Value')==1
                set(h2,'xtick',[0 20 40 60 80 100], 'yminortick','on')
                axis([0 100 baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))])
                h=plot([round(Flim1) round(Flim1)],[baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'k--');
                set(h,'linewidth',1)
                h=plot([round(Flim2) round(Flim2)],[baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))],'k--');
                set(h,'linewidth',1)
            else    
                set(h2,'xtick',[0 : ((A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000 / 5) : (A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000],'yminortick','on')
                axis([0 (A_lograte(get(guiHandlesSpec.FileSelect{k}, 'Value')) / 2) * 1000 baselineYlines(get(guiHandlesSpec.checkboxPSD, 'Value')+1) climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))])
            end

            xlabel('Frequency (Hz)')
            if get(guiHandlesSpec.checkboxPSD, 'Value')
                ylabel(['PSD (dB)'])
            else
                ylabel(['Amplitude'])
            end
                

            h=text(2,climScale(get(guiHandlesSpec.checkboxPSD, 'Value')+1, c1(p))*.95,axLabel{c2(p)});
            set(h,'Color',[.2 .2 .2],'fontsize',fontsz,'fontweight','bold')

            grid on
        end
    end
end
set(PTspecfig, 'pointer', 'arrow')
updateSpec=0;

end

