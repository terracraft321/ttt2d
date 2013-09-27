local parse = parse

function Parse(cmd, ...)
    local str = cmd
    
    for k,v in pairs({...}) do
    
        if type(v) == 'string' then
            str = str .. ' "' .. v .. '"'
        else
            str = str .. ' ' .. v
        end
    end
    
    parse(str)
end
