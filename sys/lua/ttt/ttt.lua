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

-- config
DEBUG = false
WEAPON_1 = {30, 20, 10}
WEAPON_2 = {2, 4, 69}
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
round_timer = nil

function TTT.round_begin()
    state = PREPARING
    
    Karma.round_begin()
    clear_items()
    Hud.clear_marks()
    
    local players = Player.table 
    
    lock_team = false
    for _,ply in pairs(players) do
        local rnd = Walk.random()
        local pos = {x=rnd.x*32+16,y=rnd.y*32+16}
        
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
        
        round_timer = Timer(TIME_GAME*1000, function()
            msg(Color(220, 20, 20).."Traitors lost!@C")
            TTT.round_end()
        end)
    end)
end

function TTT.round_end()
    if round_timer then
        round_timer:remove()
    end
    
    Karma.round_end()
       
    state = PREPARING
    Timer(2000, function()
        state = WAITING
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

Hook('buy', function(ply)
    ply:msg(Color(220,20,20) .. "Buying is not allowed!@C")
    return 1
end)

Hook('spawn', function(ply)
    return 'x'
end)

Hook('join', function(ply)
    ply.hud = {}
    ply:set_role(SPECTATOR)
    Karma.reset(ply)
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
    if team ~= 0 and lock_team then
        return 1
    end
end)

Hook('hit', function(ply, attacker, weapon, hpdmg, apdmg, rawdmg)
    if state ~= RUNNING then return 1 end
    
    if type(attacker) ~= 'table' then return 0 end
    
    local newdmg = math.ceil(hpdmg * attacker.damagefactor)
    
    Karma.hurt(attacker, ply, newdmg)
    
    if ply.health-newdmg > 0 then
        ply.health = ply.health - newdmg
        
    else
        Karma.killed(attacker, ply)
        
        ply:set_role(SPECTATOR)
        ply.team = 0
    end
    
    Hud.draw_health(ply)
    
    return 1
end)

Hook('second', function()
    time = time + 1
    
    
    if state == RUNNING then
        local players = Player.tableliving
        local t_num = 0
        
        for _,ply in pairs(players) do
            if ply:is_traitor() then
                t_num = t_num + 1
            end
        end
        
        if t_num == 0 then
            msg(Color(20,220,20).."All traitors are gone! Innocent won!@C")
            TTT.round_end()
        elseif t_num == #players then
            msg(Color(220,20,20).."Traitors won!@C")
            TTT.round_end()
        end
    elseif state == WAITING then
        local players = Player.table
        if #players > 1 then
            state = PREPARING
            msg(Color(220,20,220).."Next round in " .. TIME_NEXTROUND .. " seconds@C")
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
    if ply.team == 0 then
        local players = Player.table
        for _,v in pairs(players) do
            if v.team == 0 or state ~= RUNNING then
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
