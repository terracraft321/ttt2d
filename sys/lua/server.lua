local _image = image
local _freeimage = freeimage

function image(path, x, y, mode, ...)
    local i = _image(path, x, y, mode, unpack({...}))
    print("create image " .. i)
    return i
end

function freeimage(id)
    _freeimage(id)
    print("freeimage " .. id)    
end

dofile('sys/lua/ttt/ttt.lua')
