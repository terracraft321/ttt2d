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
