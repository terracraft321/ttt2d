local image = image

Image = {}
Image.mt = {}

setmetatable(Image, {
    __call = function(_, path, x, y, mode, ...)
        if type(path) == 'string' then
            local img = image(path, x, y, mode, unpack({...}))
            return setmetatable({id = img}, Image.mt)
        elseif type(path) == 'number' then
            return setmetatable({id = path}, Image.mt)
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
        _G[v](self.id, unpack({...}))
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
