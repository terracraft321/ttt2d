Walk = {}
Walk.tile = {}
Walk.list = {}

local function add_tile(x, y)
    if not Walk.tile[x] then
        Walk.tile[x] = {}
    end
    Walk.tile[x][y] = true
end

local function is_walkable(x, y)
    if tile(x, y, 'walkable') and not Walk.test(x,y) then
        return true
    else
        return false
    end
end

local function recursive(x, y)
    add_tile(x, y)
    
    if entity(x, y, 'typename') == 'Func_Teleport' then
        local tx = entity(x, y, 'int0')
        local ty = entity(x, y, 'int1')
        if is_walkable(tx, ty) then recursive(tx, ty) end
    end
        
    if is_walkable(x-1, y) then recursive(x-1, y) end
    if is_walkable(x+1, y) then recursive(x+1, y) end
    if is_walkable(x, y-1) then recursive(x, y-1) end
    if is_walkable(x, y+1) then recursive(x, y+1) end
end

function Walk.scan()
    Walk.tile = {}
    local sx, sy = randomentity(1)
    recursive(sx, sy)
    
    Walk.list = {}
    for x,v in pairs(Walk.tile) do
        for y,_ in pairs(v) do
            table.insert(Walk.list, {x=x, y=y})
        end
    end
end

function Walk.random()
    return Walk.list[math.random(#Walk.list)]
end

function Walk.test(x, y)
    return Walk.tile[x] and Walk.tile[x][y]
end
