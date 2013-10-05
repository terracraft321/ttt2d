function Player.mt:make_preparing()
    self:set_role(ROLE_PREPARING)
    if self.team ~= 1 then
        self:set_team(1)
    end
    --self:spawn(pos.x, pos.y)
end

function Player.mt:make_innocent()
    self:set_role(ROLE_INNOCENT)
end

function Player.mt:make_detective()
    self:set_role(ROLE_DETECTIVE)
    self:equip(79)
    self:equip(78)
end

function Player.mt:make_spectator()
    self:set_role(ROLE_SPECTATOR)
    if self.team ~= 0 then
        self:set_team(0)
    end    
end

function Player.mt:is_preparing()
    return self.role == ROLE_PREPARING
end

function Player.mt:is_innocent()
    return self.role == ROLE_INNOCENT
end

function Player.mt:is_traitor()
    return self.role == ROLE_TRAITOR
end

function Player.mt:is_detective()
    return self.role == ROLE_DETECTIVE
end

function Player.mt:is_mia()
    return self.role == ROLE_MIA
end

function Player.mt:is_spectator()
    return self.role == ROLE_SPECTATOR
end

function Player.mt:is_admin()
    return self.rank >= RANK_ADMIN
end

function Player.mt:is_moderator()
    return self.rank >= RANK_MODERATOR
end

function Player.mt:set_team(value)
    --lock_team = false
    self.allow_change = true
    self.team = value
    self.allow_change = false
    --lock_team = true
end

function Player.mt:set_role(role)
    self.role = role
    if self.hud then
        Hud.draw_role(self)
    end
end

function Player.mt:get_role()
    return self.role
end

function Player.mt:remind(message)
    self:msg(Color(120,220,120) .. message)
end

function Player.mt:remind_karma_limited(time)
    local time = time or 1
    Timer(time, function()
        self:remind("Your karma is limited because you're not logged in!@C")
    end)
end

function Player.mt:remind_new_player(time)
    local time = time or 1
    Timer(time, function()
        self:remind("If you're new to this gamemode, please read the instructions! (F1)@C")
    end)
end

function Player.mt:welcome_back(time)
    local time = time or 1
    Timer(time, function()
        self:remind("Welcome back, " .. self.name .. "!@C")
    end)
end

function Player.mt:reset_data()
    self.karma = Karma.base
    self.playtime = 0
    self.rank = RANK_GUEST
    self.savetime = os.time()
    self.points = 0
end

function Player.mt:save_data()
    if not self.usgn then
        return
    end
    
    local timenow = os.time()
    self.playtime = self.playtime + (timenow - self.savetime)
    self.savetime = timenow
    
    local f = File('sys/lua/ttt/saves/' .. self.usgn .. '.txt')
    f:write({
        karma = self.karma,
        playtime = self.playtime,
        rank = self.rank,
        points = self.points
    })
    
    TTT.debug('save ' .. self.name .. ' ' .. self.usgn)
end

function Player.mt:load_data()
    if not self.usgn then
        self.karma = Karma.player_base
        self:remind_karma_limited(5000)
        self:remind_new_player(7000)
        return
    end
    
    self.savetime = os.time()
    
    TTT.debug("load " .. self.name)
    local f = File('sys/lua/ttt/saves/' .. self.usgn .. '.txt')
    local data = f:read()
    
    if type(data) ~= 'table' then
        self:remind_new_player(3000)
        return
    end
    
    for k,v in pairs(data) do
        TTT.debug("load " .. k .. " = " .. v)
        self[k] = v
    end
    
    if self.karma < Karma.reset then
        self.karma = Karma.reset
    end
    
    self:welcome_back(3000)
    TTT.debug('loaded ' .. self.name)
end
