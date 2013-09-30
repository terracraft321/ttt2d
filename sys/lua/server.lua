local _image = image
local _freeimage = freeimage

function image(path, x, y, mode, pl)
    if ply then
        local i = _image(path, x, y, mode, pl)
        print("create image " .. i)
        return i
    else
        local i = _image(path, x, y, mode)
        print("create image " .. i)
        return i
    end
end

function freeimage(id)
    _freeimage(id)
    print("freeimage " .. id)    
end

dofile('sys/lua/ttt/ttt.lua')
