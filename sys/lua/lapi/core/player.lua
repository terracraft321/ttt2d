local player = player
local playerweapons = playerweapons
local reqcld = reqcld

Player = {}
Player.mt = {}
Player.data = {}
Player.indextable = {
    armor = 'setarmor',
    health = 'sethealth',
    speedmod = 'speedmod',
    score = 'setscore',
    deaths = 'setdeaths',
    maxhealth = 'setmaxhealth',
    score = 'setscore',
    money = 'setmoney',
    weapon = 'setweapon'
}

setmetatable(Player, {
    __call = function(_, arg)
        if type(arg) == "number" then
            if Player.data[arg] then
                return Player.data[arg]
            elseif arg > 0 and arg <= 32 then
                local p = setmetatable({id = arg}, Player.mt)
                Player.data[arg] = p
                return p
            else
                return 0
            end
        elseif type(arg) == "table" then
            local tbl = {}
            for k,v in pairs(arg) do
                table.insert(tbl, Player(v))
            end
            return tbl
        end
    end,
    __index = function(_, key)
        local m = rawget(Player, key)
        if m then return m end
        
        m = rawget(Player.mt, key)
        if m then return m end
        
        return Player(player(0, key))
    end
})

function Player.mt:__index(key)
    local m = rawget(Player.mt, key)
    if m then
        return m
    else
        if key == 'enemy' then
            local team = self.team
            if team == 1 then
                return 2
            elseif team == 2 then
                return 1
            else 
                return 0
            end
        elseif key == 'weapons' then
            return playerweapons(self.id)
        else
            return player(self.id, key)
        end
    end
end

function Player.mt:__newindex(key, value)
    if Player.indextable[key] ~= nil then
        Parse(Player.indextable[key], self.id, value)
    elseif key == 'name' then
        Parse('setname', self.id, value, 1)
    elseif key == 'team' then
        if value == 1 then
            Parse('maket', self.id)
        elseif value == 2 then
            Parse('makect', self.id)
        else
            Parse('makespec', self.id)
        end
    elseif key == 'x' then
        self:setpos(value, self.y)
    elseif key == 'tilex' then
        self:setpos(value * 32 + 16, self.y)
    elseif key == 'y' then
        self:setpos(self.x, value)
    elseif key == 'tiley' then
        self:setpos(self.x, value * 32 + 16)
    elseif key == 'enemy' then
        return
    elseif key == 'weapons' then
        local tbl = playerweapons(self.id)
        
        for k,v in pairs(value) do
            local found = false
            for k2,v2 in pairs(tbl) do
                if v == v2 then
                    found = true
                end
            end
            if not found then
                self:equip(v)
            end
        end
        for k,v in pairs(tbl) do
            local found = false
            for k2,v2 in pairs(value) do
                if v == v2 then
                    found = true
                end
            end
            if not found then
                self:strip(v)
            end
        end
    else
        rawset(self, key, value)
    end
end

local methods = {
    equip = 'equip',
    setpos = 'setpos',
    kick = 'kick',
    banip = 'banip',
    spawn = 'spawnplayer',
    strip = 'strip',
    slap = 'slap',
    kill = 'killplayer',
    reroute = 'reroute',
    shake = 'shake',
    flash = 'flashplayer'
}

for k,v in pairs(methods) do

    Player.mt[k] = function(self, ...)
        Parse(v, self.id, unpack({...}))
    end
end

function Player.mt:reqcld(mode, ...)
    reqcld(self.id, mode, unpack(arg))
end

function Player.mt:banusgn(duration, reason)
    Parse('banusgn', self.usgn, duration, reason)
end

function Player.mt:customkill(killer, weapon)
    Parse('customkill', killer, weapon, self.id)
end

function Player.mt:msg(message)
    msg2(self.id, message)
end

function Player.mt:cmsg(message)
    Parse('cmsg', message, self.id)
end

-- bots

local methods = {
    'ai_aim',
    'ai_attack',
    'ai_build',
    'ai_buy',
    'ai_debug',
    'ai_drop',
    'ai_freeline',
    'ai_goto',
    'ai_iattack',
    'ai_move',
    'ai_radio',
    'ai_reload',
    'ai_respawn',
    'ai_rotate',
    'ai_say',
    'ai_sayteam',
    'ai_selectweapon',
    'ai_spray',
    'ai_use'
}


for k,v in pairs(methods) do
    local func = _G[v]
    
    Player.mt[v] = function(self, ...)
        return func(self.id, unpack({...}))
    end
end


function Player.mt:ai_findtarget()
    return Player(ai_findtarget(self.id))
end
