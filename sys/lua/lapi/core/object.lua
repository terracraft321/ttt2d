local object = object

Object = {}
Object.mt = {}
Object.names = {}
Object.names["Barricade"] = 1
Object.names["Barbed Wire"] = 2
Object.names["Wall I"] = 3
Object.names["Wall II"] = 4
Object.names["Wall III"] = 5
Object.names["Gate Field"] = 6
Object.names["Dispenser"] = 7
Object.names["Turret"] = 8
Object.names["Supply"] = 9
Object.names["Build Place"] = 10
Object.names["Dual Turret"] = 11
Object.names["Triple Turret"] = 12
Object.names["Teleporter Entrance"] = 13
Object.names["Teleporter Exit"] = 14
Object.names["Super Supply"] = 15
Object.names["Mine"] = 20
Object.names["Laser Mine"] = 21
Object.names["Portal 1"] = 22
Object.names["Portal 2"] = 23
Object.names["NPC"] = 30
Object.names["Dynamic Image"] = 40


setmetatable(Object, {
    __call = function(_, arg)
        if type(arg) == "number" then
            if arg > 0 then
                return setmetatable({id = arg}, Object.mt)
            else
                return 0
            end
        elseif type(arg) == "table" then
            local tbl = {}
            for k,v in pairs(arg) do
                table.insert(tbl, Object(v))
            end
            return tbl
        else
            return Object.names[arg]
        end
    end,
    __index = function(_, key)
        local m = rawget(Object, key)
        if m then return m end
        
        m = rawget(Object.mt, key)
        if m then return m end
        
        return Object(object(0, key))
    end
})

function Object.spawn(objtype, x, y, rot, mode, team, player)
    Parse('spawnobject', objtype, x, y, rot, mode, team, player)
end

function Object.mt:__index(key)
    local m = rawget(Object.mt, key)
    if m then
        return m
    else
        return object(self.id, key)
    end
end

function Object.mt.__eq(a, b)
    if a.id and b.id then
        return a.id == b.id
    else
        return false
    end
end

function Object.mt:kill()
    Parse('killobject', self.id)
end
