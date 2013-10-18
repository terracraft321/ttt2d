-- load Love API
dofile('sys/lua/lapi/lapi.lua')
lapi.load('plugins/walk.lua')

-- global table
TTT = {}

-- load other files
dofile('sys/lua/ttt/hud.lua')
dofile('sys/lua/ttt/player.lua')
dofile('sys/lua/ttt/karma.lua')
dofile('sys/lua/ttt/mia.lua')
dofile('sys/lua/ttt/traitor.lua')
dofile('sys/lua/ttt/config.lua')
dofile('sys/lua/ttt/chat.lua')

-- scan the map for walkable tiles
Walk.scan()
-- current game state
TTT.state = STATE_WAITING
-- time when round has started
TTT.round_started = os.time()
-- current round number
TTT.round_count = 0
-- setup debugging
TTT.debug = Debug(true, function(message)
    print("TTT " .. os.time() .. "| " .. message)
    --msg(Color(220, 150, 150) .. "TTT " .. message)
end)

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
Game.mp_shotweakening = 100
Parse('mp_wpndmg', 'USP', 35)

-- is the game starting?
function TTT.is_starting()
    return TTT.state == STATE_STARTING
end

-- is the game waiting?
function TTT.is_waiting()
    return TTT.state == STATE_WAITING
end

-- is the game preparing?
function TTT.is_preparing()
    return TTT.state == STATE_PREPARING
end

-- is the game running?
function TTT.is_running()
    return TTT.state == STATE_RUNNING
end

-- change game state
function TTT.set_state(state)
    TTT.debug("set_state " .. state)
    TTT.state = state
end

-- called when round begins
function TTT.round_begin()
    TTT.debug("round begin")
    -- clear all stuff from previous rounds
    --Karma.round_begin()
    Mia.clear_all()
    Hud.clear_marks()
    
    local players = Player.table
    for _,ply in pairs(players) do
        Hud.clear(ply)
    end
    
    -- modify variables
    TTT.round_started = os.time()
    TTT.round_count = TTT.round_count + 1
    
    -- start preparing state
    TTT.preparing_begin()
end

-- called when round ends
function TTT.round_end(winner)
    TTT.debug("round end")
    
    -- set the game state to waiting
    TTT.set_state(STATE_WAITING)
    
    -- tell who were the traitors
    TTT.tell_traitors()
    -- tell the killers of players
    Mia.tell_killers()
    -- update and save karma
    Karma.round_end(winner)
    
    -- save every player
    local players = Player.table
    for _,ply in pairs(players) do
        ply:save_data()
    end
    
    -- map rotating
    if TTT.round_count > 10 then
        local map = Map.name
        local id = 1
        for k,v in pairs(TTT.maps) do
            if v == map then
                id = k
            end
        end
        TTT.debug("map id " .. id)
        local newmap = TTT.maps[(id % #TTT.maps) + 1]
        msg(Color.white .. "Mapchange!@C")
        Timer(4000, function()
            Parse('map', newmap)
        end)
    end
end

-- called when preparing state begins
function TTT.preparing_begin()
    TTT.debug("preparing begin")
    
    -- set the game state to preparing and update timer
    TTT.set_state(STATE_PREPARING)
    Hud.set_timer(TIME_PREPARE)
    
    -- clear players and change their role to preparing
    local players = Player.table
    for _,ply in pairs(players) do
        if ply.health > 0 then
            ply.weapons = {50}
        end
        ply:make_preparing()
    end
    
    -- spawn ground items
    TTT.spawn_items()
end

-- called when preparing state ends
function TTT.preparing_end()
    TTT.debug("preparing end")
    
    -- set the game state to running and update timer
    TTT.set_state(STATE_RUNNING)
    Hud.set_timer(TIME_GAME-TIME_PREPARE)
    
    -- move all dead players to spectators if they didn't spawn yet
    local players = Player.table
    for _,ply in pairs(players) do
        if ply.health == 0 then
            ply:make_spectator()
        end
    end
    
    -- select traitors and detectives
    TTT.select_teams()
end

-- select traitors and detectives
function TTT.select_teams()
    TTT.debug("select teams")
    
    -- seed the random
    math.randomseed(os.time())
    
    local players = Player.tableliving
    local t_num = math.ceil(#players / 6)
    local d_num = math.floor(#players / 9)
    
    -- remove mias from list
    for k,ply in pairs(players) do
        if ply:is_mia() then
            table.remove(players, k)
        end
    end
    
    -- select traitors
    TTT.traitors = {}
    for i=1,t_num do
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_traitor()
    end
    
    -- mark traitors with a red shadow
    Hud.mark_traitors()
    
    -- select detectives
    for i=1,d_num do
        local rnd = math.random(#players)
        local ply = table.remove(players, rnd)
        
        ply:make_detective()
    end
    
    -- mark detectives with a blue shadow
    Hud.mark_detectives()
    
    -- all other players are innocent
    for _,ply in pairs(players) do
        ply:make_innocent()
    end
end

-- spawn items on the map
-- TODO: rewrite this part
function TTT.spawn_items()
    TTT.debug("spawn items")
    
    local players = Player.tableliving
    local wpn_1 = math.max(math.random(#players, #players*2), 8)
    local wpn_2 = math.max(math.random(#players, #players*2), 8)
    
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

-- get color code for the specific role
-- TODO: this function doesn't belong to ttt.lua
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

-- join hook
Hook('join', function(ply)
    TTT.debug("join i" .. ply.id)
    
    -- init player variables
    ply.joined = os.time()

    -- reset player data
    ply:reset_data()

    -- load player data from saves
    ply:load_data()
    
    -- if the game is still preparing, let the player spawn
    if TTT.is_preparing() then
        ply:make_preparing()
    -- else set its role to spectator
    else
        ply:set_role(ROLE_SPECTATOR)
        -- after 1000ms draw hud
        Timer(1000, function()
            Hud.draw(ply)
        end)
    end
end)

-- startround_prespawn hook
Hook('startround_prespawn', function()
    -- begin the round
    TTT.round_begin()
end)

-- spawn hook
Hook('spawn', function(ply)
    TTT.debug("spawn i" .. ply.id)
    
    -- mias are allowed to spawn
    if ply:is_mia() then
        return 'x'
    end
    
    -- if the game is already running, don't allow spawning
    if TTT.is_running() then -- don't allow spawning
        TTT.debug("spawn deny " .. ply.id)
        
        -- a slight workaround
        Timer(1, function()
            ply:make_spectator()
        end)
        return 'x'
    -- else let the player spawn
    else
        TTT.debug("spawn allow " .. ply.id)
        -- draw player's hud
        Timer(1, function()
            Karma.spawn(ply)
            Hud.draw(ply)
            Hud.update_health(ply)
        end)
        return 'x'
    end
end)

-- startround hook
-- not used anymore
Hook('startround', function()
    TTT.debug("startround ")
end)

-- endround hook
-- not used anymore
Hook('endround', function()
    TTT.debug("endround")
end)

-- radio hook
Hook('radio', function()
    -- don't show message
    return 1
end)

-- movetile hook
Hook('movetile', function(ply, x, y)
    if ply:is_traitor() then
        ply:collect_more(x, y)
    end
end)

-- drop hook
Hook('drop', function(ply, iid, weapon)
    -- switch weapon to knife
    Timer(1, function()
        ply.weapon = 50
    end)
end)

-- use hook
Hook('use', function(ply)
    -- loop all players
    local players = Player.table
    for _,v in pairs(players) do
        -- check if there's a body
        ply:use_body(v)
    end
end)

-- leave hook
Hook('leave', function(ply)
    TTT.debug("leave i" .. ply.id)
    
    -- reset player specific data
    ply:reset_mia()
    ply:save_data()
    Hud.clear_traitors_ply(ply)
    Hud.clear(ply)
end)

-- vote hook
Hook('vote', function(ply)
    -- voting costs some karma
    Karma.give_penalty(ply, Karma.vote_penalty)
end)

-- buy hook
Hook('buy', function(ply)
    ply:msg(Color.traitor .. "Buying is not allowed!@C")
    return 1
end)

-- die hook
Hook('die', function(ply)
    TTT.debug("die " .. ply.id .. " " .. ply.health)
    
    if ply:is_mia() then
        ply:spawn(ply.x, ply.y)
    
    elseif not ply:is_spectator() then
        ply:make_mia()
    end
    
    Hud.update_health(ply)
    return 1
end)

-- team hook
Hook('team', function(ply, team)
    -- don't change if not allowed to
    if not ply.allow_change then
        return 1
    end
end)

-- walkover hook
Hook('walkover', function(ply, iid, wpn)
    -- don't collect claws
    if wpn == 78 and not ply:is_detective() then
        return 1
    end
end)

-- attack hook
-- TODO: rewrite DNA scanner
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

-- hit hook
Hook('hit', function(ply, attacker, weapon, hpdmg, apdmg, rawdmg)
    TTT.debug("hit i" .. ply.id .. " w" .. weapon)
    -- don't take damage if the game isn't running
    if not TTT:is_running() then return 1 end

    -- TODO: rewrite DNA scanner
    if weapon == 78 and attacker:is_detective() then
        TTT.debug("scanplayer " .. attacker.name .. " " .. ply.name)
        attacker:scan_player(ply)
        return 1
    end
    
    -- if there's no attacker, he hit himself
    if type(attacker) ~= 'table' then
        attacker = ply
    end
    
    -- MIAs can hit eachother
    if attacker:is_mia() or ply:is_mia() then return 1 end
    
    -- calculate new damage
    local newdmg = math.ceil(hpdmg * attacker.damagefactor)
    -- calculate karma rewards/penalties for hurting
    Karma.hurt(attacker, ply, newdmg)
    
    -- if the player didn't die
    if ply.health-newdmg > 0 then
        ply.health = ply.health - newdmg
    
    else
        -- calculate karma rewards/penalties for killing
        Karma.killed(attacker, ply)
        -- make the player Missing-in-Action
        ply:make_mia(attacker)
    end
    
    -- update health bar
    Hud.update_health(ply)
    return 1
end)

-- second hook
Hook('second', function()
    -- current round time
    local time = os.time() - TTT.round_started
    --TTT.debug("time " .. time)
    
    -- check if the preparing state should end
    if TTT:is_preparing() then
        if time >= TIME_PREPARE then
            TTT.preparing_end()
        end    
    -- if the game is running
    elseif TTT:is_running() then
        local players = Player.tableliving
        local t_num = 0
        local i_num = 0
        -- count number of traitors and not traitors alive
        for _,ply in pairs(players) do
            if ply:is_traitor() then
                t_num = t_num + 1
            elseif not ply:is_mia() then
                i_num = i_num + 1
            end
        end
        
        -- if there isn't any traitors
        if t_num == 0 then
            msg(table.concat({
                    Color.white, "All traitors are gone! ",
                    Color.innocent, "Innocent won!@C"}))
                    
            TTT.round_end(ROLE_INNOCENT)
        -- if there isn't any innocent or detectives
        elseif i_num == 0 then
            msg(table.concat({
                    Color.traitor, "Traitors ",
                    Color.white, "won!@C"}))
                    
            TTT.round_end(ROLE_TRAITOR)
        -- if the time ran out
        elseif time >= TIME_GAME then
            msg(table.concat({
                    Color.white, "Time ran out! ",
                    Color.traitor, "Traitors ",
                    Color.white, "lost!@C"}))
            
            TTT.round_end(ROLE_INNOCENT)
        end
    -- if the game is waiting
    elseif TTT:is_waiting() then
        TTT.debug("waiting")
        
        local players = Player.table
        -- if there's one than one player
        if #players > 1 then
            TTT.debug("starting")
            -- start new round
            TTT.set_state(STATE_STARTING)
            Parse('endround', 1)
            msg(table.concat({
                    Color.white, "Next round in ",
                    Color.traitor, 5,
                    Color.white, " seconds@C"}))

            Hud.set_timer(5)
        end
    end
end)
