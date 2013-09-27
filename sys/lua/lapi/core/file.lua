File = {}
File.mt = {}

setmetatable(File, {
    __call = function(_, path)
        return setmetatable({path = path}, File.mt)
    end
})

function File.mt:__index(key)
    return rawget(File.mt, key)
end

function File.mt:read()
    local f = io.open(self.path, 'r')
    
    if not f then return false end
    
    local content = ''
    for line in io.lines(self.path) do
        content = content .. line .. '\n'
    end
    
    f:close()
    return loadstring('return ' .. content)()
end

function File.mt:write(data)
    local f = io.open(self.path, 'wb')
    if not f then return false end
    
    f:write(File.serialize(data))
    f:close()
    return true
end

function File.serialize(data, key, indent)
    indent = indent or ''
    
    local str = indent
    
    if key then
        str = str .. key .. ' = '
    end
    
    if type(data) == 'table' then
        str = str .. '{\n'
        for k,v in pairs(data) do
            str = str .. File.serialize(v, (type(k)=='string' and k or nil), indent .. '  ') .. ',\n'
        end
        str = str .. indent .. '}'
    elseif type(data) == 'string' then
        str = str .. string.format('%q', data)
    elseif type(data) == 'number' then
        str = str .. tostring(data)
    elseif type(data) == 'boolean' then
        str = str .. (data and 'true' or 'false')
    else
        str = str .. '"unknown"'
    end
    
    return str
end
