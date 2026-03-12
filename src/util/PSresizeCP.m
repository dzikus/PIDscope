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
setappdata(fig, 'PScpL', cpL);
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
                case 'quarter1', pos = [cpL+cpM          yTop-h fw/4 h];
                case 'quarter2', pos = [cpL+cpM+fw/4     yTop-h fw/4 h];
                case 'quarter3', pos = [cpL+cpM+fw/2     yTop-h fw/4 h];
                case 'quarter4', pos = [cpL+cpM+3*fw/4   yTop-h fw/4 h]; yTop = yTop-h-gap;
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
    % Always offset for checkbox bar + slider (present on main window)
    tbOff = 40 / figH;
    chkRow2 = (1 - tbOff) - rs;
    sliderBottom = chkRow2 - 2*cpMv - 0.02;
    vPos = sliderBottom - 0.005 - cpTitleH - cpMv;
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

% Reposition stick overlay below CP panel
ov = getappdata(fig, 'PSoverlay');
if ~isempty(ov)
    stickGap = cpM;
    stickW = (cpW - stickGap) / 2; stickH = stickW * 1.3;
    cpPanel = findobj(fig, 'Type', 'uipanel', 'Title', 'Control Panel');
    if ~isempty(cpPanel)
        pp = get(cpPanel(1), 'Position'); cpBot = pp(2);
    else
        cpBot = vPos - rs*14 - cpMv;
    end
    stickY = max(0.01, cpBot - stickH - cpMv);
    oH = rhs;
    try set(ov.axYT, 'Position', [cpL stickY stickW stickH]); catch, end
    try set(ov.axRP, 'Position', [cpL+stickW+stickGap stickY stickW stickH]); catch, end
    oY = max(0.001, stickY - oH - 2*cpMv); halfW = cpW/2; fullW = cpW;
    try set(ov.time, 'Position', [cpL oY fullW oH]); catch, end
    oY = oY - oH;
    try set(ov.M4, 'Position', [cpL oY halfW oH]); catch, end
    try set(ov.M1, 'Position', [cpL+halfW oY halfW oH]); catch, end
    oY = oY - oH;
    try set(ov.M3, 'Position', [cpL oY halfW oH]); catch, end
    try set(ov.M2, 'Position', [cpL+halfW oY halfW oH]); catch, end
    oY = oY - oH;
    try set(ov.GR, 'Position', [cpL oY fullW oH]); catch, end
    oY = oY - oH;
    try set(ov.GP, 'Position', [cpL oY fullW oH]); catch, end
    oY = oY - oH;
    try set(ov.GY, 'Position', [cpL oY fullW oH]); catch, end
end

% Reposition Log Viewer checkbox bar (fixed pixel sizes)
chkBar = getappdata(fig, 'PScheckboxBar');
if ~isempty(chkBar)
    tbOff = 40 / figH;
    chkH = rh;
    chkRow1 = 1 - tbOff;
    chkRow2 = chkRow1 - rs;
    chkX = chkBar.x0;
    for i = 1:numel(chkBar.items)
        it = chkBar.items{i};
        if ~ishandle(it.h), continue; end
        w = it.wpx / figW;
        row = chkRow1; if it.row == 2, row = chkRow2; end
        set(it.h, 'Position', [chkX row w chkH]);
        if it.advance, chkX = chkX + w; end
    end
    % Reposition panel background
    if isfield(chkBar, 'panel') && ishandle(chkBar.panel)
        panelW = chkX - chkBar.x0 + cpM;
        set(chkBar.panel, 'Position', [chkBar.x0 chkRow2-cpMv panelW chkRow1+chkH+cpMv-chkRow2+cpMv]);
    end
    % Reposition slider
    sliderY = chkRow2 - 2*cpMv - 0.02;
    if isfield(chkBar, 'slider') && ishandle(chkBar.slider)
        sliderW = cpL - 0.0826 - 0.005;
        set(chkBar.slider, 'Position', [0.0826 sliderY sliderW 0.02]);
    end

    % Reposition Log Viewer plot axes
    plotL = 0.095; plotGap = 0.01;
    gapV = 0.005; linepos4H = 0.11;
    plotTop = sliderY - 0.005;
    plotW = cpL - plotL - plotGap;

    motorAx = findobj(fig, 'Tag', 'PSmotor');
    rpyAxes = findobj(fig, 'Tag', 'PSrpy');
    comboAx = findobj(fig, 'Tag', 'PScombo');
    upperAxes = [];
    for k = 1:numel(rpyAxes), if ishandle(rpyAxes(k)), upperAxes(end+1) = rpyAxes(k); end; end
    for k = 1:numel(comboAx), if ishandle(comboAx(k)), upperAxes(end+1) = comboAx(k); end; end

    if ~isempty(motorAx) && ishandle(motorAx(1))
        set(motorAx(1), 'Position', [plotL 0.1 plotW linepos4H]);
    end

    nUpper = numel(upperAxes);
    if nUpper > 0
        upperBot = 0.1 + linepos4H + gapV;
        upperH = (plotTop - upperBot - max(0,nUpper-1)*gapV) / max(1,nUpper);
        if nUpper > 1
            yVals = zeros(nUpper, 1);
            for k = 1:nUpper, p = get(upperAxes(k), 'Position'); yVals(k) = p(2); end
            [~, si] = sort(yVals, 'descend');
            upperAxes = upperAxes(si);
        end
        for k = 1:nUpper
            y = plotTop - k*upperH - (k-1)*gapV;
            set(upperAxes(k), 'Position', [plotL y plotW upperH]);
        end
    end
end

end % if/elseif/else mode

% Recompute subplot grid positions based on current cpL
grid = getappdata(fig, 'PSplotGrid');
if ~isempty(grid) && isfield(grid, 'ncols')
    plotR = cpL - grid.margin;
    totalW = plotR - grid.plotL;
    if totalW > 0.1
        if isfield(grid, 'colWidthFracs') && numel(grid.colWidthFracs) == grid.ncols
            usable = totalW - (grid.ncols-1)*grid.colGap;
            colWidths = usable * grid.colWidthFracs / sum(grid.colWidthFracs);
        elseif isfield(grid, 'bigColFrac') && ~isempty(grid.bigColFrac)
            wBig = totalW * grid.bigColFrac;
            wSmall = (totalW - wBig - (grid.ncols-1)*grid.colGap) / max(1, grid.ncols-1);
            colWidths = [wBig, repmat(wSmall, 1, grid.ncols-1)];
        else
            colW_new = (totalW - (grid.ncols-1)*grid.colGap) / grid.ncols;
            colWidths = repmat(colW_new, 1, grid.ncols);
        end
        newCols = zeros(1, grid.ncols);
        newCols(1) = grid.plotL;
        for c = 2:grid.ncols
            newCols(c) = newCols(c-1) + colWidths(c-1) + grid.colGap;
        end

        allAx = findobj(fig, 'Type', 'axes', 'Tag', 'PSgrid');
        validAx = []; validPos = [];
        for i = 1:numel(allAx)
            try
                axP = get(allAx(i), 'Position');
                if axP(3) >= 0.05 && axP(4) >= 0.04
                    validAx(end+1) = allAx(i);
                    validPos(end+1,:) = axP;
                end
            catch, end
        end

        for ri = 1:numel(grid.rows)
            rowIdx = [];
            rowX = [];
            for j = 1:numel(validAx)
                [~, best_ri] = min(abs(grid.rows - validPos(j,2)));
                if best_ri == ri && abs(grid.rows(ri) - validPos(j,2)) < 0.15
                    rowIdx(end+1) = j;
                    rowX(end+1) = validPos(j,1);
                end
            end
            if numel(rowIdx) < 1 || numel(rowIdx) > grid.ncols, continue; end
            [~, si] = sort(rowX);
            for k = 1:numel(si)
                ci = min(k, grid.ncols);
                j = rowIdx(si(k));
                set(validAx(j), 'Position', [newCols(ci) grid.rows(ri) colWidths(ci) grid.rowH]);
            end
        end

        % Store grid results for plot files
        setappdata(fig, 'PSgridCols', newCols);
        setappdata(fig, 'PSgridWidths', colWidths);

        % Reposition tagged colorbars
        cbars = findobj(fig, 'Tag', 'PScbar');
        for cbi = 1:numel(cbars)
            try
                cpos = get(cbars(cbi), 'Position');
                ud = get(cbars(cbi), 'UserData');
                if ischar(ud) && strcmp(ud, 'north')
                    [~, cci] = min(abs(newCols - cpos(1)));
                    if cci <= numel(colWidths)
                        set(cbars(cbi), 'Position', [newCols(cci) cpos(2) colWidths(cci) cpos(4)]);
                    end
                elseif ischar(ud) && strcmp(ud, 'east')
                    cbarX = plotR + 0.005;
                    cbarW = max(0.02, grid.margin * 0.35);
                    set(cbars(cbi), 'Position', [cbarX cpos(2) cbarW cpos(4)]);
                end
            catch, end
        end

        % Reposition per-column top-bar widgets (Freq x Throttle)
        pci = getappdata(fig, 'PSperColItems');
        if ~isempty(pci)
            for pii = 1:numel(pci)
                try
                    ph = pci{pii}{1}; pci_col = pci{pii}{2}; pci_xOff = pci{pii}{3};
                    if pci_col <= numel(newCols) && ishandle(ph)
                        ppos = get(ph, 'Position');
                        ppos(1) = newCols(pci_col) + pci_xOff;
                        set(ph, 'Position', ppos);
                    end
                catch, end
            end
        end
    end
end

end
