dofile('sys/lua/lapi/lapi.lua')
lapi.load('plugins/walk.lua')

dofile('sys/lua/ttt/hud.lua')
dofile('sys/lua/ttt/player.lua')
dofile('sys/lua/ttt/karma.lua')


Walk.scan()

-- game settings
Game.mp_autoteambalance = 0
Game.mp_teamkillpenalty = 0
Game.mp_damagefactor = 1.1
Game.mp_killinfo = 0
Game.sv_friendlyfire = 1
Game.mp_hud = 0
Game.mp_radar = 0
Game.sv_gamemode = 1
Game.sv_fow = 1
Game.mp_mapvoteratio = 0
Parse('mp_wpndmg', 'USP', 30)

-- constant
PREPARING = 1
INNOCENT = 2
TRAITOR = 3
DETECTIVE = 4
SPECTATOR = 5
RUNNING = 6
WAITING = 7
MIA = 8

-- config
DEBUG = false
WEAPON_1 = {30, 20, 10, 20, 20, 10, 23, 23, 35, 30, 39}
WEAPON_2 = {2, 2, 2, 2, 4, 4, 3, 69}
TIME_PREPARE = 15
TIME_GAME = 180
TIME_NEXTROUND = 5

Color.innocent = Color(20, 220, 20)
Color.traitor = Color(220, 20, 20)
Color.detective = Color(20, 20, 220)
Color.spectator = Color(220, 220, 20)
Color.white = Color(220, 220, 220)

TTT = {}

-- variables
state = WAITING
lock_team = true
time = 0
TTT.round_timer = nil
TTT.mia = {}

function TTT.round_begin()
    state = PREPARING
    
    Karma.round_begin()
    clear_items()
    TTT.clear_mia_all()
    Hud.clear_marks()
    
    local players = Player.table 
    
    lock_team = false
    for _,ply in pairs(players) do
        local tilex,tiley = randomentity(1)
        local pos = {x=tilex*32+16,y=tiley*32+16}
        
        ply.team = 1
        ply:spawn(pos.x, pos.y)
        ply:set_role(PREPARING)
        
        Hud.draw_health(ply)
    end
    lock_team = true
    
    spawn_items()
    
    msg(Color(20,220,20).."Go get your weapons!@C")
    Hud.set_timer(TIME_PREPARE)
    Timer(TIME_PREPARE*1000, function()
        state = RUNNING
        set_teams()
        Hud.set_timer(TIME_GAME)
        
        TTT.round_timer = Timer(TIME_GAME*1000, function()
            msg(Color(220, 20, 20).."Traitors lost!@C")
            TTT.round_end()
        end)
    end)
end

function TTT.round_end()
    if TTT.round_timer then
        TTT.round_timer:remove()
    end
    
    Karma.round_end()
       
    state = PREPARING
    Timer(2000, function()
        state = WAITING
    end)
end

function TTT.clear_mia_all()
    for _,v in pairs(TTT.mia) do
        v.img:remove()
    end
    TTT.mia = {}
end

function TTT.set_mia(ply)
    
    
    if ply.weapon then
        Parse("spawnitem", ply.weapon, ply.tilex, ply.tiley)
    end
    
    local img = Image('gfx/ttt_dev/body.png', ply.x, ply.y, 0)
    img:pos(ply.x, ply.y, ply.rot-180)
    
    local tbl = {
        ply = ply,
        tilex = ply.tilex,
        tiley = ply.tiley,
        img = img,
        found = false,
        role = ply.role
    }
    
    ply:set_role(MIA)
    
    TTT.mia[ply.id] = tbl
    
    local tilex, tiley = randomentity(2)

    ply.tilex = tilex
    ply.tiley = tiley
    ply.health = 100
    ply.weapons = {}
    
    ply:remind("You are currently Missing-in-Action (MIA)")
    Timer(2000, function()
        ply:remind("Yes, pratically you are dead but innocent don't know that")
    end)
    Timer(4000, function()
        ply:remind("You just have to wait for someone to find your body")
    end)
end

function set_teams()
    local players = Player.tableliving
    local t_num = math.ceil(#players / 7)
    local d_num = math.floor(#players / 12)
    
    lock_team = false
    for i=1,t_num do  -- select traitors
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        ply:set_role(TRAITOR)
        ply:equip(32)
        
        Timer(1, function()
            Hud.mark_traitors(ply)
        end)
    end
    
    for i=1,d_num do  -- select detectives
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        ply:set_role(DETECTIVE)
        
        Hud.mark_detective(ply)
    end
    
    for _,ply in pairs(players) do  -- select innocents
        ply:set_role(INNOCENT)
    end
    
    lock_team = true
end

function spawn_items()
    local players = Player.tableliving
    local wpn_1 = math.max(#players, 5)
    local wpn_2 = math.max(math.floor(#players * 1.5), 10)
    
    for i=1,wpn_1 do
        local wep = WEAPON_1[math.random(#WEAPON_1)]
        local pos = Walk.random()
        Parse('spawnitem', wep, pos.x, pos.y)
    end
    
    for i=1,wpn_2 do
        local wep = WEAPON_2[math.random(#WEAPON_1)]
        local pos = Walk.random()
        Parse('spawnitem', wep, pos.x, pos.y)
    end
end

function clear_items()
    local items = item(0,"table")
    for _,id in pairs(items) do
       Parse('removeitem', id)
    end
end

function get_mia_role(mia)
    local role = "INNOCENT"
    local color = Color.innocent
    if mia.role == TRAITOR then
        role = "TRAITOR"
        color = Color.traitor
    elseif mia.role == DETECTIVE then
        role = "DETECTIVE"
        color = Color.detective
    end
    return color..role
end

Hook('use', function(ply)
    local tilex = ply.tilex
    local tiley = ply.tiley
    
    for _,v in pairs(TTT.mia) do
        local dist = math.abs(tilex-v.tilex) + math.abs(tiley-v.tiley)
        if dist < 2 then
            
            if not v.found then
                lock_team = false
                
                v.ply:set_role(SPECTATOR)
                v.ply.team = 0
                v.found = true
                
                local role = get_mia_role(v)

                msg(Color.innocent .. ply.name .. " found the body of " .. v.ply.name .. " who was " .. role .. "@C")
                
                lock_team = true
            else
                local role = get_mia_role(v)
                ply:msg(Color.innocent .. "This body belongs to " .. v.ply.name .. " who was " .. role .. "@C")
            end
        end
    end
end)

Hook('leave', function(ply)
    if TTT.mia[ply.id] then
        TTT.mia[ply.id].img:remove()
        TTT.mia[ply.id] = nil
    end
    Karma.save_karma(ply)
    Hud.clear_traitor_marks(ply)
    Hud.clear(ply)
end)

Hook('vote', function(ply)
    Karma.give_penalty(ply, 100)
end)

Hook('buy', function(ply)
    ply:msg(Color.traitor .. "Buying is not allowed!@C")
    return 1
end)

Hook('spawn', function(ply)
    return 'x'
end)

Hook('join', function(ply)
    ply.hud = {}
    ply:set_role(SPECTATOR)
    Karma.reset(ply)
    Karma.load_karma(ply)
    Timer(1000, function()
        Hud.draw(ply)
    end)
end)

Hook('die', function()
    if not lock_team then
        return 1
    end
end)

Hook('team', function(ply, team)
    if lock_team then
        return 1
    end
end)

Hook('hit', function(ply, attacker, weapon, hpdmg, apdmg, rawdmg)
    if state ~= RUNNING or ply:is_mia() then return 1 end
    
    if type(attacker) ~= 'table' then return 0 end
    
    local newdmg = math.ceil(hpdmg * attacker.damagefactor)
    
    Karma.hurt(attacker, ply, newdmg)
    
    if ply.health-newdmg > 0 then
        ply.health = ply.health - newdmg
        
    else
        Karma.killed(attacker, ply)
        
        TTT.set_mia(ply)
    end
    
    Hud.draw_health(ply)
    
    return 1
end)

Hook('second', function()
    time = time + 1
    
    
    if state == RUNNING then
        local players = Player.tableliving
        local t_num = 0
        local i_num = 0
        
        for _,ply in pairs(players) do
            if ply:is_traitor() then
                t_num = t_num + 1
            elseif not ply:is_mia() then
                i_num = i_num + 1
            end
        end
        
        if t_num == 0 then
            msg(Color(20,220,20).."All traitors are gone! Innocent won!@C")
            TTT.round_end()
        elseif i_num == 0 then
            msg(Color(220,20,20).."Traitors won!@C")
            TTT.round_end()
        end
    elseif state == WAITING then
        local players = Player.table
        if #players > 1 then
            state = PREPARING
            msg(Color(220,220,220).."Next round in " .. TIME_NEXTROUND .. " seconds@C")
            clear_items()
            
            Hud.set_timer(TIME_NEXTROUND)
            Timer(TIME_NEXTROUND*1000, function()
                TTT.round_begin()
            end)
        end
    end
end)

function format_message(ply, message, role)
    local color = Color.spectator
    if role == DETECTIVE then
        color = Color.detective
    elseif role == INNOCENT then
        color = Color.innocent
    elseif role == TRAITOR then
        color = Color.traitor
    end
    
    return color .. ply.name .. Color.white .. ': ' .. message
end

Hook('sayteam', function(ply, message)
    if ply.role == TRAITOR then
        local players = Player.table
        for _,v in pairs(players) do
            if v:is_traitor() then
                v:msg('(TEAM)'..format_message(ply, message, TRAITOR))
            end
        end
    end
    return 1
end)

Hook('say', function(ply, message)
    if ply.team == 0 or ply:is_mia() then
        local players = Player.table
        for _,v in pairs(players) do
            if v.team == 0 or v:is_mia() or state ~= RUNNING then
                v:msg(format_message(ply, message, SPECTATOR))
            end
        end
    elseif ply.role == TRAITOR then
        local players = Player.table
        for _,v in pairs(players) do
            if v:is_traitor() then
                v:msg(format_message(ply, message, TRAITOR))
            else
                v:msg(format_message(ply, message, INNOCENT))
            end
        end
    else
        msg(format_message(ply, message, ply.role))
    end
    return 1
end)
