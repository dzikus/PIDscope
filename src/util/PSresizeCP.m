function PSresizeCP(fig, ~)
%% PSresizeCP - resize callback: keeps CP elements at fixed pixel sizes
cpd = getappdata(fig, 'PScp');
if isempty(cpd), return; end

figPos = get(fig, 'Position');
figW = figPos(3); figH = figPos(4);
if figW < 300 || figH < 200, return; end

px = cpd.px;
cpW = px.cpW / figW;
cpL = 1 - cpW - px.cpM / figW;
cpM = px.cpM / figW;
cpMv = px.cpM / figH;
rh = px.rh / figH;
rs = px.rs / figH;
ddh = px.ddh / figH;
cbW = px.cbW / figW;
rhs = px.rhs / figH;
cpTitleH = px.cpTitle / figH;
vPos = 1 - cpTitleH - cpMv;
hw = cpW/2 - cpM;
fw = cpW - 2*cpM;
gap = rs - rh;

mode = 'rows';
if isfield(cpd, 'mode'), mode = cpd.mode; end

if strcmp(mode, 'seq')
    % Sequential layout: items placed top-to-bottom, each with its own height
    tbOff = 40 / figH;  % toolbar offset
    vPos = 1 - tbOff - cpTitleH - cpMv;
    yTop = vPos;
    panelH = 0; panelBot = 0;
    for i = 1:numel(cpd.items)
        it = cpd.items{i};
        if ~ishandle(it.h), continue; end
        try
            hpx = it.hpx;
            h = hpx / figH;
            switch it.type
                case 'full',    pos = [cpL+cpM yTop-h fw h];          yTop = yTop-h-gap;
                case 'left',    pos = [cpL+cpM yTop-h hw h];
                case 'right',   pos = [cpL+cpW/2 yTop-h hw h];        yTop = yTop-h-gap;
                case 'cb',      pos = [cpL+cpM+it.col*cbW yTop-h cbW h];
                case 'cb_end',  pos = [cpL+cpM+it.col*cbW yTop-h cbW h]; yTop = yTop-h-gap;
                case 'dd_full', pos = [cpL+cpM yTop-h fw h];          yTop = yTop-h-gap;
                case 'dd_left', pos = [cpL+cpM yTop-h hw h];
                case 'dd_right',pos = [cpL+cpW/2 yTop-h hw h];        yTop = yTop-h-gap;
                case 'text_left',  pos = [cpL+cpM yTop-h cpW/4 h];
                case 'text_right', pos = [cpL+cpW/2 yTop-h cpW/4 h];  yTop = yTop-h-gap;
                case 'input_left', pos = [cpL+cpM yTop-h cpW/4 h];
                case 'input_right',pos = [cpL+cpW/2 yTop-h cpW/4 h];  yTop = yTop-h-gap;
                case 'panel'
                    continue;
                otherwise, continue;
            end
            set(it.h, 'Position', pos);
        catch
        end
    end
    % Panel sized to wrap all items
    for i = 1:numel(cpd.items)
        it = cpd.items{i};
        if strcmp(it.type, 'panel') && ishandle(it.h)
            panelBot = yTop - gap;
            panelH = vPos - panelBot + cpTitleH;
            set(it.h, 'Position', [cpL panelBot cpW panelH]);
        end
    end

elseif strcmp(mode, 'topbar')
    % Horizontal top-bar layout (PID Error, Flight Stats, Setup Info)
    topBtnH = rh;
    tbOff = 40 / figH;  % toolbar offset
    % Check if any items use 'lbl' type — if not, no label row above buttons
    hasLbl = false;
    for i = 1:numel(cpd.items), if strcmp(cpd.items{i}.type,'lbl'), hasLbl = true; break; end; end
    if hasLbl
        topLblY = 1 - tbOff - rhs - cpMv;
        topBtnY = topLblY - rhs - cpMv;
    else
        topBtnY = 1 - tbOff - rh - cpMv;
        topLblY = topBtnY;
    end
    topX = cpd.topBarL + cpM;
    for i = 1:numel(cpd.items)
        it = cpd.items{i};
        if ~ishandle(it.h), continue; end
        try
            w = it.wpx / figW;
            switch it.type
                case 'btn', pos = [topX topBtnY w topBtnH]; topX = topX+w+cpM;
                case 'lbl', pos = [topX topLblY w rhs];
                case 'input', pos = [topX topBtnY w topBtnH]; topX = topX+w+cpM;
                case 'cb',  pos = [topX topBtnY w topBtnH]; topX = topX+w+cpM;
                case 'dd',  pos = [topX topBtnY w topBtnH]; topX = topX+w+cpM;
                case 'panel'
                    panelW = topX - cpd.topBarL;
                    topPanelH = 1 - tbOff - topBtnY + cpMv;
                    pos = [cpd.topBarL topBtnY-cpMv panelW topPanelH];
                otherwise, continue;
            end
            set(it.h, 'Position', pos);
        catch
        end
    end

else
    % Row-based layout (PIDscope.m main CP)
    tbOff = 40 / figH;  % toolbar offset
    vPos = 1 - tbOff - cpTitleH - cpMv;
    for i = 1:numel(cpd.items)
        it = cpd.items{i};
        if ~ishandle(it.h), continue; end
        try
            row = it.row;
            switch it.type
                case 'full'
                    pos = [cpL+cpM vPos-rs*row fw rh];
                case 'left'
                    pos = [cpL+cpM vPos-rs*row hw rh];
                case 'right'
                    pos = [cpL+cpW/2 vPos-rs*row hw rh];
                case 'cb'
                    pos = [cpL+cpM+it.col*cbW vPos-rs*row cbW rh];
                case 'dd_left'
                    pos = [cpL+cpM vPos-rs*row hw rh];
                case 'dd_right'
                    pos = [cpL+cpW/2 vPos-rs*row hw rh];
                case 'panel'
                    cpH = rs * it.nrows + cpTitleH + cpMv;
                    pos = [cpL vPos-cpH+cpTitleH cpW cpH];
                case 'infotable'
                    cpH = rs * it.nrows + cpTitleH + cpMv;
                    cpBot = vPos - cpH + cpTitleH;
                    infoH = px.infoH / figH;
                    pos = [cpL cpBot-infoH-cpMv cpW infoH];
                case 'below_info'
                    cpH = rs * it.nrows + cpTitleH + cpMv;
                    cpBot = vPos - cpH + cpTitleH;
                    infoH = px.infoH / figH;
                    infoY = cpBot - infoH - cpMv;
                    pos = [cpL+cpM infoY-rh-cpMv fw rh];
                otherwise
                    continue;
            end
            set(it.h, 'Position', pos);
        catch
        end
    end
end
end
