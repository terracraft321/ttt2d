local image = image

Image = {}
Image.mt = {}

setmetatable(Image, {
    __call = function(_, arg1, ...)
        if type(arg1) == "number" then
            return setmetatable({id = arg1}, Image.mt)
        elseif type(arg1) == "table" then
            local tbl = {}
            for k,v in pairs(arg1) do
                table.insert(tbl, Image(v))
            end
            return tbl
        else
            return Image(image(arg1, unpack(arg)))
        end
    end,
    __index = function(_, key)
        local m = rawget(Image, key)
        if m then return m end
        
        return rawget(Image.mt, key)
    end
})

local transform = {
    remove = 'freeimage',
    alpha = 'imagealpha',
    blend = 'imageblend',
    color = 'imagecolor',
    hitzone = 'imagehitzone',
    pos = 'imagepos',
    scale = 'imagescale',
    t_alpha = 'tween_alpha',
    t_color = 'tween_color',
    t_move = 'tween_move',
    t_rotate = 'tween_rotate',
    t_rotateconstantly = 'tween_rotateconstantly',
    t_scale = 'tween_scale'
}

for k,v in pairs(transform) do  -- generate methods from transform table
    Image.mt[k] = function(self, ...)
        _G[v](self.id, unpack(arg))
    end
end

function Image.mt:__index(key)
    local m = rawget(Image.mt, key)
    if m then
        return m
    else
        error("Unknown method " .. key)
    end
end

function Image.mt.__eq(a, b)
    if a.id and b.id then
        return a.id == b.id
    else
        return false
    end
end
