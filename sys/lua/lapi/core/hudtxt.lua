Hudtxt = {}
Hudtxt.mt = {}

setmetatable(Hudtxt, {
    __call = function(_, ply, id)
        return setmetatable({ply = ply, id = id}, Hudtxt.mt)
    end,
    __index = function(_, key)
        local m = rawget(Hudtxt, key)
        if m then return m end

        return rawget(Hudtxt.mt, key)
    end
})

function Hudtxt.mt:__index(key)
    local m = rawget(Hudtxt.mt, key)
    if m then return m end
end

function Player.mt:hudtxt(id)
    return Hudtxt(self, id)
end

function Hudtxt.mt:show(text, x, y, align)
    local prefix = 'hudtxt'
    if type(self.ply) == 'table' then
        prefix = prefix .. '2 ' .. self.ply.id
    end

    Parse(prefix, self.id, text, x, y, align)
end

function Hudtxt.mt:hide()
    local prefix = 'hudtxt'
    if type(self.ply) == 'table' then
        prefix = prefix .. '2 ' .. self.ply.id
    end

    Parse(prefix, self.id)
end

function Hudtxt.mt:move(duration, x, y)
    local player_id = 0
    if type(self.ply) == 'table' then player_id = self.ply.id end
    
    Parse('hudtxtmove', player_id, self.id, duration, x, y)
end

function Hudtxt.mt:alpha(duration, alpha)
    local player_id = 0
    if type(self.ply) == 'table' then player_id = self.ply.id end
    
    Parse('hudtxtalphafade', player_id, self.id, duration, alpha)
end

function Hudtxt.mt:color(duration, r, g, b)
    local player_id = 0
    if type(self.ply) == 'table' then player_id = self.ply.id end
    
    Parse('hudtxtcolorfade', player_id, self.id, duration, r, g, b)
end
