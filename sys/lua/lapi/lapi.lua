if not lapi then
    lapi = {}
    lapi.version = "0.1"
    lapi.path = debug.getinfo(1).source:sub(2, -10)
    lapi.loaded = {}
    lapi.load = function(file)
        if not lapi.loaded[file] then
            lapi.loaded[file] = true
            print("Love API load script: " .. file)
            dofile(lapi.path .. '/' .. file)
        end
    end
    
    lapi.core = {
        'parse', 'player', 'object', 'image', 'hudtxt', 'hook',
        'menu', 'timer', 'map', 'game', 'color', 'file', 'shortcut'
    }
    
    for k,v in pairs(lapi.core) do
        lapi.load('core/' .. v .. '.lua')
    end
end
