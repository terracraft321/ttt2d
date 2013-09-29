dofile('sys/lua/lapi/lapi.lua')
lapi.load('plugins/walk.lua')

dofile('sys/lua/ttt/hud.lua')
dofile('sys/lua/ttt/player.lua')
dofile('sys/lua/ttt/karma.lua')
dofile('sys/lua/ttt/mia.lua')

Walk.scan()

-- game settings
Game.mp_autoteambalance = 0
Game.mp_teamkillpenalty = 0
Game.mp_damagefactor = 1.1
Game.mp_killinfo = 0
Game.sv_friendlyfire = 1
Game.mp_hud = 0
Game.mp_radar = 0
Game.sv_gamemode = 2
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
STARTING = 9

-- config
DEBUG = false
WEAPON_1 = {30, 20, 10}
WEAPON_2 = {2, 4, 69}
TIME_PREPARE = 15
TIME_GAME = 180
TIME_NEXTROUND = 5

Color.innocent = Color(20, 220, 20)
Color.traitor = Color(220, 20, 20)
Color.detective = Color(50, 80, 250)
Color.spectator = Color(220, 220, 20)
Color.white = Color(220, 220, 220)

TTT = {}

-- variables
state = WAITING
lock_team = true
TTT.traitors = {}
TTT.round_started = 0

function TTT.round_begin()
    print("round_begin")
    state = PREPARING
    
    Karma.round_begin()
    clear_items()
    Mia.clear_all()
    Hud.clear_marks()
    
    local players = Player.table 
    for _,ply in pairs(players) do
        local tilex,tiley = randomentity(1)
        local pos = {x=tilex*32+16,y=tiley*32+16}
        
        ply:set_role(PREPARING)
        ply:set_team(1)
        ply:spawn(pos.x, pos.y)
        
        Hud.draw_health(ply)
    end
    
    spawn_items()
    
    TTT.round_started = os.time()
    Hud.set_timer(TIME_PREPARE)
    
    msg(Color.white .. "Go get your weapons!@C")
end

function TTT.tell_traitors()
    msg(Color.white .. "Traitors were:")
    for _,str in pairs(TTT.traitors) do
        msg(Color.traitor .. str)
    end
end

function TTT.round_end(winner)
    print("round_end")
    
    TTT.tell_traitors()
    Mia.tell_killers()
    Karma.round_end(winner)
       
    state = WAITING
end

function set_teams()
    local players = Player.tableliving
    local t_num = math.ceil(#players / 6)
    local d_num = math.floor(#players / 10)
    
    TTT.traitors = {}
    for i=1,t_num do  -- select traitors
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_traitor()
    end
    
    for i=1,d_num do  -- select detectives
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_detective()
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
        Timer(i*50, function()
            local wep = WEAPON_1[math.random(#WEAPON_1)]
            local pos = Walk.random()
            Parse('spawnitem', wep, pos.x, pos.y)
        end)
    end
    
    for i=1,wpn_2 do
        Timer(i*50, function()
            local wep = WEAPON_2[math.random(#WEAPON_1)]
            local pos = Walk.random()
            Parse('spawnitem', wep, pos.x, pos.y)
        end)
    end
end

function clear_items()
    local items = item(0,"table")
    for i,id in pairs(items) do
        Timer(i*50, function()
            if item(id, "player") == 0 then
                Parse('removeitem', id)
            end
        end)
    end
end

function TTT.get_color(role)
    if role == TRAITOR then
        return Color.traitor
    elseif role == DETECTIVE then
        return Color.detective
    else
        return Color.innocent
    end
end

function TTT.color_format(tbl)
    local str = ''
    for k,v in pairs(tbl) do
        str = str .. v
    end
end

Hook('radio', function()
    return 1
end)

Hook('drop', function(ply, iid, weapon)
    Timer(1, function()
        ply.weapon = 50
    end)
end)

Hook('use', function(ply)
    local tilex = ply.tilex
    local tiley = ply.tiley
    local players = Player.table
    
    for _,v in pairs(players) do
        ply:use_body(v)
    end
end)

Hook('leave', function(ply)
    ply:reset_mia()
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

Hook('die', function(ply)
    ply:make_spectator()
    return 1
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
        ply:make_mia(attacker)
    end
    
    Hud.draw_health(ply)
    
    return 1
end)

Hook('second', function()
    local round_time = os.time() - TTT.round_started
    
    if state == PREPARING then
        if round_time >= TIME_PREPARE then
            state = RUNNING
            set_teams()
            Hud.set_timer(TIME_GAME-TIME_PREPARE)
        end
    elseif state == RUNNING then
        
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
            msg(table.concat({
                    Color.white, "All traitors are gone! ",
                    Color.innocent, "Innocent won!@C"}))
                    
            TTT.round_end(INNOCENT)
            
        elseif i_num == 0 then
            msg(table.concat({
                    Color.traitor, "Traitors ",
                    Color.white, "won!@C"}))
                    
            TTT.round_end(TRAITOR)
        
        elseif round_time >= TIME_GAME then
            msg(table.concat({
                    Color.white, "Time ran out! ",
                    Color.traitor, "Traitors ",
                    Color.white, "lost!@C"}))
            
            TTT.round_end(INNOCENT)
        end
        
    elseif state == WAITING then
        local players = Player.table
        if #players > 1 then
            state = STARTING
            msg(table.concat({
                    Color.white, "Next round in ",
                    Color.traitor, TIME_NEXTROUND,
                    Color.white, " seconds@C"}))
           -- msg(Color(220,220,220).."Next round in " .. TIME_NEXTROUND .. " seconds@C")
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
