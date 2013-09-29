function Player.mt:make_spectator()
    self:set_role(SPECTATOR)
    self:set_team(0)
end

function Player.mt:make_traitor()
    self:set_role(TRAITOR)
    self:equip(32)
    self:equip(1)
    
    table.insert(TTT.traitors, self.name)
    
    Timer(1, function()
        Hud.mark_traitors(self)
    end)
end

function Player.mt:make_detective()
    self:set_role(DETECTIVE)
    self:equip(41)
    
    Hud.mark_detective(self)
end

function Player.mt:set_team(value)
    lock_team = false
    self.team = value
    lock_team = true
end

function Player.mt:set_role(role)
    self.role = role
    Hud.draw_role(self)
end

function Player.mt:get_role()
    return self.role
end

function Player.mt:is_traitor()
    return self.role == TRAITOR
end

function Player.mt:is_mia()
    return self.role == MIA
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
