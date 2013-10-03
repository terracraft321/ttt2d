-- list of traitor names
TTT.traitors = {}

-- get a table of player objects
function TTT.get_traitors()
    local players = Player.table
    for k,ply in pairs(players) do
        if not ply:is_traitor() then
            table.remove(players, k)
        end
    end
    return players
end

-- tell who were the traitors
function TTT.tell_traitors()
    msg(Color.white .. "Traitors were:")
    
    for _,str in pairs(TTT.traitors) do
        msg(Color.traitor .. str)
    end
end

function Player.mt:make_traitor()
    self:set_role(ROLE_TRAITOR)
    self:equip(32)
    self:equip(1)
    
    table.insert(TTT.traitors, self.name)
end

function Player.mt:collect_more(x, y)
    local itemlist = closeitems(self.id, 1)
    local found = false
    for _,id in pairs(itemlist) do
        if item(id,'x') == x and item(id,'y') == y then
            found = true
        end
    end
    
    if not found then return end
    
    -- test version of traitors collecting more weapons
    local weapons = self.weapons
    for _,item in pairs(weapons) do
        if item == 32 and self.weapon ~= 32 then
            TTT.debug("re-equip " .. self.id)
            self:strip(32)
            Timer(1, function()
                self:equip(32)
            end)
            return
        elseif item == 1 and self.weapon ~= 1 then
            TTT.debug("re-equip " .. self.id)
            self:strip(1)
            Timer(1, function()
                self:equip(1)
            end)
            return
        end
    end
end
