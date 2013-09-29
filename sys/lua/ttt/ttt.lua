dofile('sys/lua/lapi/lapi.lua')
lapi.load('plugins/walk.lua')

dofile('sys/lua/ttt/hud.lua')
dofile('sys/lua/ttt/player.lua')
dofile('sys/lua/ttt/karma.lua')
dofile('sys/lua/ttt/mia.lua')
dofile('sys/lua/ttt/chat.lua')

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
STATE_WAITING = 1
STATE_STARTING = 2
STATE_PREPARING = 3
STATE_RUNNING = 4

ROLE_INNOCENT = 1
ROLE_TRAITOR = 2
ROLE_DETECTIVE = 3
ROLE_MIA = 4
ROLE_SPECTATOR = 5
ROLE_PREPARING = 6

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
TTT.state = STATE_WAITING
TTT.traitors = {}
TTT.round_started = 0
TTT.round_count = 0
TTT.debug = Debug(false, function(message)
    msg(Color(220, 150, 150) .. "TTT " .. message)
end)


function TTT.is_starting()
    return TTT.state == STATE_STARTING
end

function TTT.is_waiting()
    return TTT.state == STATE_WAITING
end

function TTT.is_preparing()
    return TTT.state == STATE_PREPARING
end

function TTT.is_running()
    return TTT.state == STATE_RUNNING
end

function TTT.set_state(state)
    TTT.debug("set_state " .. state)
    TTT.state = state
end

function TTT.round_begin()
    TTT.debug("round begin")
    
    TTT.round_count = TTT.round_count + 1
    
    TTT.set_state(STATE_PREPARING)
    
    Karma.round_begin()
    TTT.clear_items()
    Mia.clear_all()
    Hud.clear_marks()
    
    local players = Player.table 
    for _,ply in pairs(players) do
        local tilex,tiley = randomentity(1)
        local pos = {x=tilex*32+16,y=tiley*32+16}
        
        Hud.draw(ply)
        ply:make_preparing(pos)
        
        Hud.update_health(ply)
    end
    
    TTT.spawn_items()
    
    TTT.round_started = os.time()
    Hud.set_timer(TIME_PREPARE)
    
    msg(Color.white .. "Go get your weapons!@C")
end

function TTT.round_end(winner)
    TTT.debug("round begin")
    
    TTT.tell_traitors()
    Mia.tell_killers()
    Karma.round_end(winner)
    TTT.set_state(STATE_WAITING)
    
    if TTT.round_count >= 10 then
        msg(Color.white .. "Map restart!@C")
        Parse("map", Map.name)
    end
end

function TTT.tell_traitors()
    msg(Color.white .. "Traitors were:")
    for _,str in pairs(TTT.traitors) do
        msg(Color.traitor .. str)
    end
end

function TTT.select_teams()
    TTT.debug("select teams")
    
    local players = Player.tableliving
    local t_num = math.ceil(#players / 6)
    local d_num = math.floor(#players / 10)
    
    TTT.traitors = {}
    --Player(1):make_traitor()
    for i=1,t_num do  -- select traitors
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_traitor()
    end
    
    Hud.mark_traitors()
    
    for i=1,d_num do  -- select detectives
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_detective()
    end
    
    Hud.mark_detectives()
    
    for _,ply in pairs(players) do  -- select innocents
        ply:make_innocent()
    end
end

function TTT.spawn_items()
    TTT.debug("spawn items")
    
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

function TTT.clear_items()
    TTT.debug("clear items")

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
    if role == ROLE_TRAITOR then
        return Color.traitor
    elseif role == ROLE_DETECTIVE then
        return Color.detective
    elseif role == ROLE_SPECTATOR or role == ROLE_MIA then
        return Color.spectator
    else
        return Color.innocent
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
    local players = Player.table
    
    for _,v in pairs(players) do
        ply:use_body(v)
    end
end)

Hook('leave', function(ply)
    print("leave " .. ply.name)
    ply:reset_mia()
    Karma.save_karma(ply)
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
    ply.joined = os.time()
    ply:set_role(ROLE_SPECTATOR)
    Karma.reset(ply)
    Karma.load_karma(ply)
    Timer(1000, function()
        Hud.draw(ply)
    end)
end)

Hook('die', function(ply)
    ply:make_spectator()
    Hud.update_health(ply)
    return 1
end)

Hook('team', function(ply, team)
    --if lock_team then
    if not ply.allow_change then
        return 1
    end
end)

Hook('walkover', function(ply, iid, wpn)
    if wpn == 78 and not ply:is_detective() then
        return 1
    end
end)

Hook('attack', function(ply)
    if not ply.weapon == 78 then return end
    if not ply:is_detective() then return end
    
    local players = Player.table
    
    for _,v in pairs(players) do
        if ply:scan_body(v) then
            return
        end
    end
end)

Hook('hit', function(ply, attacker, weapon, hpdmg, apdmg, rawdmg)
    TTT.debug("hit " .. ply.name .. " state " .. TTT.state)
    if not TTT:is_running() then return 1 end

    if weapon == 78 and attacker:is_detective() then
        TTT.debug("scanplayer " .. attacker.name .. " " .. ply.name)
        attacker:scan_player(ply)
        return 1
    end
    
    if type(attacker) ~= 'table' then return 0 end
    if attacker:is_mia() then return 1 end
    
    local newdmg = math.ceil(hpdmg * attacker.damagefactor)
    
    Karma.hurt(attacker, ply, newdmg)
    
    if ply.health-newdmg > 0 then
        ply.health = ply.health - newdmg
        
    else
        Karma.killed(attacker, ply)
        ply:make_mia(attacker)
    end
    
    Hud.update_health(ply)
    return 1
end)

Hook('second', function()
    local round_time = os.time() - TTT.round_started
    
    if TTT:is_preparing() then
        if round_time >= TIME_PREPARE then
            TTT.set_state(STATE_RUNNING)
            TTT.select_teams()
            Hud.set_timer(TIME_GAME-TIME_PREPARE)
        end
    
    elseif TTT:is_running() then
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
                    
            TTT.round_end(ROLE_INNOCENT)
            
        elseif i_num == 0 then
            msg(table.concat({
                    Color.traitor, "Traitors ",
                    Color.white, "won!@C"}))
                    
            TTT.round_end(ROLE_TRAITOR)
        
        elseif round_time >= TIME_GAME then
            msg(table.concat({
                    Color.white, "Time ran out! ",
                    Color.traitor, "Traitors ",
                    Color.white, "lost!@C"}))
            
            TTT.round_end(ROLE_INNOCENT)
        end
        
    elseif TTT:is_waiting() then
        local players = Player.table
        
        TTT.debug("waiting")
        if #players > 1 then
            TTT.debug("starting")
            TTT.set_state(STATE_STARTING)
            TTT.clear_items()
            
            msg(table.concat({
                    Color.white, "Next round in ",
                    Color.traitor, TIME_NEXTROUND,
                    Color.white, " seconds@C"}))


            Hud.set_timer(TIME_NEXTROUND)
            Timer(TIME_NEXTROUND*1000, function()
                TTT.round_begin()
            end)
        end
    end
end)
