Karma = {}


-- penalty calculations
function Karma.get_hurt_penalty(victim_karma, dmg)
    return victim_karma * dmg * 0.001
end

function Karma.get_kill_penalty(victim_karma)
    return Karma.get_hurt_penalty(victim_karma, 15)
end

-- reward calculations
function Karma.get_hurt_reward(dmg)
    return 1500 * dmg * 0.0003
end

function Karma.get_kill_reward()
    return Karma.get_hurt_reward(40)
end


-- live karma
function Karma.give_penalty(ply, value)
    ply.karma = math.max(ply.karma-value, 0)
    ply:msg("karma -" .. ply.karma)
end

function Karma.give_reward(ply, value)
    ply.karma = math.min(ply.karma+value, 1500)
    ply:msg("karma +" .. ply.karma)
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

function Karma.hurt(attacker, victim, dmg)
    if attacker == victim then return end
    
    if attacker.role ~= TRAITOR and victim.role == TRAITOR then
        local reward = Karma.get_hurt_reward(dmg)
        Karma.give_reward(attacker, reward)
    
        if (DEBUG) then
            print('Karma hurt reward ' .. attacker.name .. ' ' .. reward)
        end
    
    elseif (attacker.role==TRAITOR) == (victim.role==TRAITOR) then
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

    if attacker.role ~= TRAITOR and victim.role == TRAITOR then
        local reward = Karma.get_kill_reward()
        Karma.give_reward(attacker, reward)
        
        if (DEBUG) then
            print('Karma killed reward ' .. attacker.name .. ' ' .. reward)
        end
    
    elseif (attacker.role==TRAITOR) == (victim.role==TRAITOR) then
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
        
        ply.karma = ply.karma + 5 + (ply.karma_clean and 30 or 0)
        
        if ply.karma < 450 and not ply.bot then
            ply:kick("Your karma went too low. Please read the rules!")
        end
        ply.score = ply.karma
    end
end
