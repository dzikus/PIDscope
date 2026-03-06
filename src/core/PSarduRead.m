function [data, parms] = PSarduRead(filename)
%% PSarduRead - parse ArduPilot DataFlash .bin log file (vectorized)
%  [data, parms] = PSarduRead(filename)

fid = fopen(filename, 'rb', 'ieee-le');
if fid < 0, error('cannot open %s', filename); end
raw = fread(fid, inf, '*uint8')';
fclose(fid);
N = length(raw);

% phase 1: scan for all headers [0xA3 0x95], parse FMT messages
fmtLen = zeros(256, 1);
fmtParsed = false(256, 1);
fmtName = cell(256, 1);
fmtFormat = cell(256, 1);
fmtLabels = cell(256, 1);

% find all potential header positions
h1 = find(raw(1:end-2) == 0xA3 & raw(2:end-1) == 0x95);

% first pass: extract FMT messages to learn message lengths
for k = 1:length(h1)
    pos = h1(k);
    if pos + 88 > N, continue; end
    if raw(pos+2) ~= 128, continue; end
    t = raw(pos+3);
    fmtLen(t+1) = raw(pos+4);
    fmtName{t+1} = deblank(char(raw(pos+5:pos+8)));
    fmtFormat{t+1} = deblank(char(raw(pos+9:pos+24)));
    fmtLabels{t+1} = deblank(char(raw(pos+25:pos+88)));
    fmtParsed(t+1) = true;
end

% sequential scan to collect valid message offsets (respects message boundaries)
wanted = {'RATE','PIDR','PIDP','PIDY','RCIN','RCOU','PARM','SIDD','SIDS','IMU','ATT'};
wantedIds = zeros(1, length(wanted));
for w = 1:length(wanted)
    for t = 0:255
        if fmtParsed(t+1) && strcmp(fmtName{t+1}, wanted{w})
            wantedIds(w) = t; break;
        end
    end
end
wantedSet = false(256, 1);
for w = 1:length(wantedIds)
    if wantedIds(w) > 0, wantedSet(wantedIds(w)+1) = true; end
end

% pre-allocate offset storage
offCell = cell(256, 1);
for t = 0:255
    if wantedSet(t+1), offCell{t+1} = zeros(1, 10000); end
end
offCount = zeros(256, 1);

pos = 1;
while pos <= N - 2
    if raw(pos) ~= 0xA3 || raw(pos+1) ~= 0x95
        pos = pos + 1; continue;
    end
    msgid = raw(pos+2);
    if ~fmtParsed(msgid+1) || fmtLen(msgid+1) == 0
        pos = pos + 1; continue;
    end
    mlen = fmtLen(msgid+1);
    if pos + mlen - 1 > N, break; end
    if wantedSet(msgid+1)
        c = offCount(msgid+1) + 1;
        if c > length(offCell{msgid+1})
            offCell{msgid+1}(end+1:end*2) = 0;
        end
        offCell{msgid+1}(c) = pos;
        offCount(msgid+1) = c;
    end
    pos = pos + mlen;
end

% phase 2: vectorized field extraction
data = struct();
parms = struct();

for w = 1:length(wanted)
    tid = wantedIds(w);
    if tid == 0, continue; end
    name = wanted{w};
    nMsg = offCount(tid+1);
    if nMsg == 0, continue; end
    offsets = offCell{tid+1}(1:nMsg);

    fstr = fmtFormat{tid+1};
    labels = strsplit(fmtLabels{tid+1}, ',');
    mlen = fmtLen(tid+1);
    payLen = mlen - 3;

    % build payload matrix: nMsg × payLen
    idx = repmat(offsets(:), 1, payLen) + repmat(3:(payLen+2), nMsg, 1);
    payloads = raw(idx);  % nMsg × payLen

    if strcmp(name, 'PARM')
        parse_parms(payloads, nMsg, fstr, parms);
        % reassign since nested function modifies parms via caller
        continue;
    end

    s = decode_bulk(payloads, nMsg, fstr, labels);
    data.(name) = s;
end

% nested function to parse PARM (has string fields, can't fully vectorize)
    function parse_parms(payloads, nMsg, fstr, ~)
        layout = field_layout(fstr);
        for m = 1:nMsg
            row = payloads(m, :);
            pname = deblank(char(row(layout(2).off : layout(2).off + layout(2).sz - 1)));
            pname(pname == 0) = [];
            pname = regexprep(pname, '[^a-zA-Z0-9_]', '_');
            if isempty(pname), continue; end
            vbytes = row(layout(3).off : layout(3).off + 3);
            parms.(pname) = double(typecast(uint8(vbytes), 'single'));
        end
    end

end


function s = decode_bulk(payloads, nMsg, fstr, labels)
% Vectorized extraction: typecast columns of the payload matrix
s = struct();
layout = field_layout(fstr);
nFields = length(layout);
for f = 1:min(nFields, length(labels))
    lbl = strtrim(labels{f});
    if isempty(lbl), continue; end
    lo = layout(f);
    cols = payloads(:, lo.off : lo.off + lo.sz - 1);

    switch lo.type
        case 'Q'
            s.(lbl) = double(typecast_col(cols, 'uint64'));
        case 'q'
            s.(lbl) = double(typecast_col(cols, 'int64'));
        case 'I'
            s.(lbl) = double(typecast_col(cols, 'uint32'));
        case 'i'
            s.(lbl) = double(typecast_col(cols, 'int32'));
        case 'H'
            s.(lbl) = double(typecast_col(cols, 'uint16'));
        case 'h'
            s.(lbl) = double(typecast_col(cols, 'int16'));
        case 'f'
            s.(lbl) = double(typecast_col(cols, 'single'));
        case 'd'
            s.(lbl) = double(typecast_col(cols, 'double'));
        case 'B'
            s.(lbl) = double(cols(:,1));
        case 'b'
            s.(lbl) = double(typecast(uint8(cols(:,1)), 'int8'));
        case 'M'
            s.(lbl) = double(cols(:,1));
        case 'c'
            s.(lbl) = double(typecast_col(cols, 'int16')) / 100;
        case 'C'
            s.(lbl) = double(typecast_col(cols, 'uint16')) / 100;
        case 'e'
            s.(lbl) = double(typecast_col(cols, 'int32')) / 100;
        case 'E'
            s.(lbl) = double(typecast_col(cols, 'uint32')) / 100;
        case 'L'
            s.(lbl) = double(typecast_col(cols, 'int32')) / 1e7;
        case {'n','N','Z'}
            s.(lbl) = cell(nMsg, 1);
            for m = 1:nMsg
                s.(lbl){m} = deblank(char(cols(m,:)));
            end
        case 'a'
            s.(lbl) = zeros(nMsg, 32);
            for m = 1:nMsg
                s.(lbl)(m,:) = double(typecast(uint8(cols(m,:)), 'int16'));
            end
        case 'g'
            bits = double(typecast_col(cols, 'uint16'));
            sgn = 1 - 2 * bitshift(uint16(bits), -15);
            ex = double(bitand(uint16(bits), uint16(0x7C00))) / 1024;
            frac = double(bitand(uint16(bits), uint16(0x03FF)));
            s.(lbl) = double(sgn) .* 2.^(ex-15) .* (1 + frac/1024);
            z = ex == 0;
            s.(lbl)(z) = double(sgn(z)) .* 2^(-14) .* (frac(z) / 1024);
    end
end
end


function v = typecast_col(cols, dtype)
% typecast Nx(bytesPerElem) uint8 matrix to Nx1 typed vector
bytes = uint8(cols');  % bytesPerElem × N
v = typecast(bytes(:), dtype);
end


function layout = field_layout(fstr)
% compute byte offset and size for each field in format string
sizes = struct('b',1,'B',1,'h',2,'H',2,'i',4,'I',4,'f',4,'d',8,...
    'q',8,'Q',8,'c',2,'C',2,'e',4,'E',4,'L',4,'M',1,...
    'n',4,'N',16,'Z',64,'a',64,'g',2);
layout = struct('off',{},'sz',{},'type',{});
off = 1;
for i = 1:length(fstr)
    c = fstr(i);
    if isfield(sizes, c)
        sz = sizes.(c);
    else
        break;
    end
    layout(i).off = off;
    layout(i).sz = sz;
    layout(i).type = c;
    off = off + sz;
end
end
