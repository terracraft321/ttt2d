Karma = {}
Karma.base = 1000
Karma.max = 1500
Karma.halflife = 0.2
Karma.hurt_reward = 0.0003
Karma.kill_reward = 40
Karma.hurt_penalty = 0.0015
Karma.kill_penalty = 15
Karma.debug = Debug(false, function(message)
    msg(Color(220, 20, 220) .. message)
end)


function Karma.get_penalty_multiplier(karma)
    local halflife = Karma.max * Karma.halflife
    return math.exponential_decay(halflife, Karma.base-karma)
end

-- rewards
function Karma.get_hurt_reward(dmg)
    return Karma.max * dmg * Karma.hurt_reward
end

function Karma.get_kill_reward()
    return Karma.get_hurt_reward(Karma.kill_reward)
end

function Karma.give_reward(ply, value)
    if ply.karma > 1000 then -- make it harder to reach Karma.max
        local halflife = (Karma.max-Karma.base) * Karma.halflife
        value = value * math.exponential_decay(halflife, ply.karma-Karma.base)
    end
    
    ply.karma = math.min(ply.karma+value, Karma.max)
end

-- penalties
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
    ply.karma = math.max(ply.karma-value, 0)
end


-- modify damagefactor based on karma
function Karma.apply_karma(ply)
    if ply.karma < 1000 then
        ply.damagefactor = Karma.get_penalty_multiplier(ply.karma)
    else
        ply.damagefactor = 1
    end
    
    ply.damagefactor = math.max(ply.damagefactor, 0.1)
    Karma.debug('Karma damagefactor ' .. ply.name .. ' ' .. ply.damagefactor)
end

function Karma.reset(ply)
    ply.karma = 1000
end

function Karma.hurt(attacker, victim, dmg)
    if attacker == victim then return end
    
    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_hurt_reward(dmg)
        Karma.give_reward(attacker, reward)
    
        Karma.debug('Karma hurt reward ' .. attacker.name .. ' ' .. reward)
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_hurt_penalty(victim.karma, dmg)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
    
        Karma.debug('Karma hurt penalty ' .. attacker.name .. ' ' .. penalty)
    end
end

function Karma.killed(attacker, victim)
    if attacker == victim then return end

    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_kill_reward()
        Karma.give_reward(attacker, reward)
        
        Karma.debug('Karma killed reward ' .. attacker.name .. ' ' .. reward)
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_kill_penalty(victim.karma)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
        
        Karma.debug('Karma killed penalty ' .. attacker.name .. ' ' .. penalty)
    end
end

function Karma.round_begin()
    local players = Player.table
    
    for _,ply in pairs(players) do
        if not ply.karma then
            ply.karma = 1000
        end
        ply.score = ply.karma
        ply.karma_clean = true
        Karma.apply_karma(ply)
        Hud.draw_damagefactor(ply)
    end
end

function Karma.round_end()
    local players = Player.table
    
    for _,ply in pairs(players) do
        if not ply.karma then
            ply.karma = 1000
        end
        
        Karma.give_reward(ply, 2 + (ply.karma_clean and 30 or 0))
        
        if ply.karma < 500 and not ply.bot then
            ply:kick("Your karma went too low. Please read the rules!")
        end
        ply.score = ply.karma
    end
end
