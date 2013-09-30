Mia = {}

function Mia.clear_all()
    local players = Player.table
    for _,ply in pairs(players) do
        ply:reset_mia()
    end
end

function Mia.tell_killers()
    local players = Player.table
    for _,ply in pairs(players) do
        if ply.mia then
            local color = TTT.get_color(ply.mia.killer_role)
            ply:msg(table.concat({
                    Color.white, "You were killed by ",
                    color, ply.mia.killer_name}))
        end
    end
end

function Player.mt:scan_body(ply)
    if not ply.mia then return false end
    
    local mia = ply.mia
    local dist_x = math.abs(self.tilex - mia.tilex)
    local dist_y = math.abs(self.tiley - mia.tiley)
    
    if dist_x+dist_y > 1 then return false end
    
    self.scanner = mia.killer
    self:msg(table.concat({
                Color.detective,
                "You took a DNA sample from ",
                ply.name}))
    return true
end

function Player.mt:scan_player(ply)
    if not self.scanner then
        self:msg(Color.detective .. "No DNA sample set yet")
        return 
    end
    
    if self.scanner == ply then
        self:msg(table.concat({
                Color.detective, "The DNA sample ",
                Color.traitor, "matches",
                Color.detective, " with ",
                ply.name}))
    else
        self:msg(table.concat({
                Color.detective,
                "The DNA sample doesn't match with ",
                ply.name}))
    end
end

function Player.mt:use_body(ply)
    if not ply.mia then return end
    
    local mia = ply.mia
    local dist_x = math.abs(self.tilex - mia.tilex)
    local dist_y = math.abs(self.tiley - mia.tiley)
    
    if dist_x+dist_y > 1 then return end
    
    local color = TTT.get_color(mia.role)
    
    if mia.found then    
        self:msg(table.concat({
                Color.white, "This body belongs to ",
                color, ply.name}))
                
    else
        mia.found = true
        ply.body:t_alpha(2000, 1)
        ply:make_spectator()
        
        msg(table.concat({
                Color.innocent, self.name,
                Color.white, " found the body of ",
                color, ply.name, "@C"}))
    end
    
    if self:is_detective() then
        self:msg(table.concat({
                Color.detective,
                "The body is ",
                os.time()-mia.time,
                " seconds old"}))
    end
end

function Player.mt:remove_body()
    if self.body then
        local body = self.body
        
        body:t_alpha(2000, 0)
        Timer(2000, function()
            Hud.debug(self, self.id .. ' remove_body i' .. body.id)
            body:remove()
        end)
    end
end

function Player.mt:spawn_body()
    self:remove_body()
    
    self.body = Image('gfx/ttt_dev/body.png', self.x, self.y, 0)
    self.body:pos(self.x, self.y, self.rot-180)
    self.body:alpha(0)
    self.body:t_alpha(2000, 0.5)
end

function Player.mt:move_to_vip()
    local tilex, tiley = randomentity(2)

    self:spawn(tilex*32+16, tiley*32+16)
    --self.tilex = tilex
    --self.tiley = tiley
    self.health = 100
    self.weapons = {50}
    
    self:remind("You are currently Missing-in-Action (MIA)@C")
    Timer(2000, function()
        self:remind("Practically you are dead but innocent don't know that yet")
    end)
    Timer(4000, function()
        self:remind("You just have to wait for someone to find your body")
    end)
end

function Player.mt:make_mia(killer)
    if type(killer) ~= 'table' then
        killer = self
    end
    
    if self.weapon and self.weapon ~= 50 then
        Parse("spawnitem", self.weapon, self.tilex, self.tiley)
    end
    
    self:spawn_body()
    
    self.mia = {
        found = false,
        role = self.role,
        tilex = self.tilex,
        tiley = self.tiley,
        time = os.time(),
        killer = killer,
        killer_name = killer.name,
        killer_role = killer.role
    }
    
    local color = TTT.get_color(self.role)
    if killer:is_traitor() then
        killer:msg(table.concat({
                Color.white, "You killed ",
                color, self.name, "@C"}))
    end
    
    self:set_role(ROLE_MIA)
    self:move_to_vip()
end

function Player.mt:reset_mia()
    --self:remove_body()
    self.body = nil
    self.mia = nil
end
