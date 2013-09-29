function Player.mt:make_preparing(pos)
    self:set_team(1)
    self:spawn(pos.x, pos.y)
    self:set_role(ROLE_PREPARING)
end

function Player.mt:make_innocent()
    self:set_role(ROLE_INNOCENT)
end

function Player.mt:make_traitor()
    self:set_role(ROLE_TRAITOR)
    self:equip(32)
    self:equip(1)
    
    table.insert(TTT.traitors, self.name)
end

function Player.mt:make_detective()
    self:set_role(ROLE_DETECTIVE)
    self:equip(41)
    self:equip(78)
end

function Player.mt:make_spectator()
    self:set_role(ROLE_SPECTATOR)
    self:set_team(0)
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
