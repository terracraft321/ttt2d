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

function Player.mt:remind(message)
    self:msg(Color(120,220,120) .. message .. '@C')
end

function Player.mt:remind_karma_limited(time)
    local time = time or 1
    Timer(time, function()
        self:remind("Your karma is limited because you're not logged in!")
    end)
end

function Player.mt:remind_new_player(time)
    local time = time or 1
    Timer(time, function()
        self:remind("If you're new to this gamemode, please read the instructions! (F1)")
    end)
end

function Player.mt:welcome_back(time)
    local time = time or 1
    Timer(time, function()
        self:remind("Welcome back, " .. self.name .. "!")
    end)
end
