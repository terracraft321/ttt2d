local map = map

Map = {}

setmetatable(Map, {
    __index = function(_, key)
        return map(key)
    end
})
