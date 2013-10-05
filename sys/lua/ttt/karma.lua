Karma = {}
Karma.debug = Debug(false, function(message)
    TTT.debug(Color(220, 20, 220) .. "Karma " ..message)
end)

-- rewards
function Karma.get_hurt_reward(dmg)
    return Karma.max * dmg * Karma.hurt_reward
end

function Karma.get_kill_reward()
    return Karma.get_hurt_reward(Karma.kill_reward)
end

function Karma.give_reward(ply, value)
    if #Player.table < Karma.min_players then
        return
    end
    if ply.karma > 1000 then -- make it harder to reach Karma.max
        local halflife = (Karma.max-Karma.base) * Karma.halflife
        value = value * math.exponential_decay(halflife, ply.karma-Karma.base)
    end
    
    ply.karma = math.min(ply.karma+value, Karma.max)
end

-- penalties
function Karma.get_penalty_multiplier(karma)
    local halflife = Karma.max * Karma.halflife
    return math.exponential_decay(halflife, Karma.base-karma)
end

function Karma.get_hurt_penalty(victim_karma, dmg)
    if victim_karma < 1000 then
        dmg = dmg * Karma.get_penalty_multiplier(victim_karma)
    end
    return victim_karma * dmg * Karma.hurt_penalty
end

function Karma.get_kill_penalty(victim_karma)
    return Karma.get_hurt_penalty(victim_karma, Karma.kill_penalty)
end

function Karma.give_penalty(ply, value)
    if #Player.table < Karma.min_players then
        return
    end
    ply.karma = math.max(ply.karma-value, 0)
end

function Karma.apply_karma(ply)
    if ply.karma < 1000 then
        ply.damagefactor = Karma.get_penalty_multiplier(ply.karma)
    else
        ply.damagefactor = 1
    end
    
    ply.damagefactor = math.max(ply.damagefactor, 0.1)
    Karma.debug('damagefactor ' .. ply.name .. ' ' .. ply.damagefactor)
    ply.speedmod = (ply.karma-Karma.base)/(Karma.base/Karma.speedmod)
    Karma.debug('speedmod ' .. ply.name .. ' ' .. ply.speedmod)
end

function Karma.reset(ply)
    ply.karma = Karma.base
end

function Karma.hurt(attacker, victim, dmg)
    if attacker == victim then return end
    
    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_hurt_reward(dmg)
        Karma.give_reward(attacker, reward)
    
        Karma.debug('hurt reward ' .. attacker.name .. ' ' .. reward)
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_hurt_penalty(victim.karma, dmg)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
    
        Karma.debug('hurt penalty ' .. attacker.name .. ' ' .. penalty)
    end
end

function Karma.killed(attacker, victim)
    if attacker == victim then return end

    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_kill_reward()
        Karma.give_reward(attacker, reward)
        
        if #Player.table >= Karma.min_players then
            attacker.points = attacker.points + (attacker.karma/Karma.base)
        end
        
        Karma.debug('killed reward ' .. attacker.name .. ' ' .. reward)
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_kill_penalty(victim.karma)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
        
        Karma.debug('killed penalty ' .. attacker.name .. ' ' .. penalty)
    end
end
-- TODO: remove this
function Karma.load_karma(ply)
    if not ply.usgn then
        ply.karma = Karma.player_base
        ply:remind_karma_limited(5000)
        ply:remind_new_player(7000)
        return
    end
    
    Karma.debug('load ' .. ply.name .. ' ' .. ply.usgn)
    
    local f = File('sys/lua/ttt/karma/' .. ply.usgn .. '.txt')
    local data = f:read()
    if type(data) == 'table' and data.karma then
        ply.karma = data.karma
        
        if ply.karma < 600 then
            ply.karma = Karma.reset
        end
        
        ply:welcome_back(3000)
    else
        ply.karma = Karma.base
        ply:remind_new_player(3000)
    end
    
    Karma.debug('loaded ' .. ply.name .. ' ' .. ply.karma)
end

-- TODO: remove this
function Karma.save_karma(ply)
    if not ply.usgn then
        return
    end
    
    local f = File('sys/lua/ttt/karma/' .. ply.usgn .. '.txt')
    f:write({karma=ply.karma})
    
    Karma.debug('save ' .. ply.name .. ' ' .. ply.usgn)
end

function Karma.spawn(ply)
    if not ply.karma then
        ply:reset_data()
        ply:load_data()
    end
    if ply:is_preparing() then
        ply.score = ply.karma
        ply.karma_clean = true
        Karma.apply_karma(ply)
        Hud.draw_damagefactor(ply)
    end
end

function Karma.round_begin()
    local players = Player.table
    
    for _,ply in pairs(players) do
        Karma.spawn(ply)
    end
end

function Karma.round_end(winner)
    local players = Player.table
    
    for _,ply in pairs(players) do
        if not ply.karma then
            ply:reset_data()
            ply:load_data()
        end
        
        if ply:is_traitor() then
            if ply.role == winner then
                Karma.give_reward(ply, Karma.traitor_reward)
            else
                Karma.give_penalty(ply, Karma.traitor_penalty)
            end
        end
        
        if ply.karma < Karma.base then
            Karma.give_reward(ply, Karma.regen + (ply.karma_clean and Karma.clean or 0))
        end
        
        if ply.karma < Karma.kick and not ply.bot then
            ply:banusgn(5, "Your karma went too low. Banned for 5 minutes!")
        end
        ply.score = ply.karma
    end
end
