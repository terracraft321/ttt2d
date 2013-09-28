Karma = {}
Karma.max = 2000


-- penalty calculations
function Karma.get_hurt_penalty(victim_karma, dmg)
    return victim_karma * dmg * 0.0015
end

function Karma.get_kill_penalty(victim_karma)
    return Karma.get_hurt_penalty(victim_karma, 15)
end

-- reward calculations
function Karma.get_hurt_reward(dmg)
    return Karma.max * dmg * 0.0003
end

function Karma.get_kill_reward()
    return Karma.get_hurt_reward(40)
end


-- live karma
function Karma.give_penalty(ply, value)
    ply.karma = math.max(ply.karma-value, 0)
    --ply:msg("karma -" .. ply.karma)
end

function Karma.give_reward(ply, value)
    if ply.karma > 1000 then
        value = value*math.exp((-0.69314718 / (Karma.max*0.25)) * (Karma.max-ply.karma))
    end
    ply.karma = math.min(ply.karma+value, Karma.max)
    --ply:msg("karma +" .. ply.karma)
end

function Karma.apply_karma(ply)
    if ply.karma < 1000 then
        local k = ply.karma - 1000
        ply.damagefactor = 1 + (0.0007 * k) + (-0.000002 * (k^2))
    else
        ply.damagefactor = 1
    end
    
    ply.damagefactor = math.max(ply.damagefactor, 0.1)
end

function Karma.reset(ply)
    ply.karma = 1000
end

function Karma.hurt(attacker, victim, dmg)
    if attacker == victim then return end
    
    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_hurt_reward(dmg)
        Karma.give_reward(attacker, reward)
    
        if (DEBUG) then
            print('Karma hurt reward ' .. attacker.name .. ' ' .. reward)
        end
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_hurt_penalty(victim.karma, dmg)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
    
        if (DEBUG) then
            print('Karma hurt penalty ' .. attacker.name .. ' ' .. penalty)
        end
    end
end

function Karma.killed(attacker, victim)
    if attacker == victim then return end

    if not attacker:is_traitor() and victim:is_traitor() then
        local reward = Karma.get_kill_reward()
        Karma.give_reward(attacker, reward)
        
        if (DEBUG) then
            print('Karma killed reward ' .. attacker.name .. ' ' .. reward)
        end
    
    elseif attacker:is_traitor() == victim:is_traitor() then
        local penalty = Karma.get_kill_penalty(victim.karma)
        Karma.give_penalty(attacker, penalty)
        attacker.karma_clean = false
        
        if (DEBUG) then
            print('Karma killed penalty ' .. attacker.name .. ' ' .. penalty)
        end
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
