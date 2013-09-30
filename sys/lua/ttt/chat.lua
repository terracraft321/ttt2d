Chat = {}

function Chat.literalize(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
end

function Chat.shortcut(message)
    local players = Player.table
    
    for word in string.gmatch(message, "%S+") do
        if word:sub(1,1) == "@" and word:len() > 1 then
            local name = word:sub(2):lower()
            
            for _,ply in pairs(players) do
                if string.starts(ply.name:lower(), name) then
                    message = message:gsub(Chat.literalize(word), ply.name)
                end
            end
        end
    end
    
    return message
end

function Chat.command(ply, message)
    if message == "!resethud" then
        Hud.clear(ply)
        Hud.draw(ply)
        Hud.update_health(ply)
        return true
    end
    
    if ply.usgn == 4917 then
        if message == "!update" then
            msg(Color.white.."The server will "..Color.innocent.."update"..Color.white.." in 5 seconds!@C")
            Timer(5000, function()
                Parse('map', Map.name)
            end)
            return true
        elseif message == "!dust" then
            Parse('map', 'ttt_dust')
            return true
        elseif message == "!italy" then
            Parse('map', 'ttt_italy')
            return true
        elseif message == "!suspicion" then
            Parse('map', 'ttt_suspicion')
            return true
        elseif message == "!debug" then
            TTT.debug.state = not TTT.debug.state
            return true
        elseif message == "!endt" then
            TTT.round_end(ROLE_TRAITOR)
            return true
        elseif message == "!endi" then
            TTT.round_end(ROLE_INNOCENT)
            return true
        elseif string.starts(message, "!reset") then
            local id = tonumber(message:sub(8))
            local t = Player(id)
            t.karma = 1000
            t.score = 1000
            return true
        elseif string.starts(message, "!bc") then
            local txt = message:sub(5)
            msg(Color.white .. txt .. "@C")
            return true
        end        
    end
end

function Chat.format(ply, message, role)
    local color = TTT.get_color(role or ply.role)
    message = message:gsub('[\169\166]', ''):gsub('@C', '')
    
    return color .. ply.name .. Color.white .. ': ' .. message
end

function Chat.traitor_message(ply, message)
    local players = Player.table
    
    for _,recv in pairs(players) do
        if recv:is_traitor() then
            recv:msg(Chat.format(ply, message))
        else
            recv:msg(Chat.format(ply, message, ROLE_INNOCENT))
        end
    end
end

function Chat.traitor_message_team(ply, message)
    local players = Player.table
    
    for _,recv in pairs(players) do
        if recv:is_traitor() then
            recv:msg("(TRAITORS) " .. Chat.format(ply, message))
        end
    end
end

function Chat.spectator_message(ply, message)
    local players = Player.table

    for _,recv in pairs(players) do
        if recv:is_spectator() or recv:is_mia() or not TTT:is_running() then
            recv:msg(Chat.format(ply, message))
        end
    end
end

Hook('say', function(ply, message)
    message = Chat.shortcut(message)

    if Chat.command(ply, message) then
        return 1
    
    elseif ply:is_traitor() then
        Chat.traitor_message(ply, message)
    
    elseif ply:is_spectator() or ply:is_mia() then
        Chat.spectator_message(ply, message)
    
    else
        msg(Chat.format(ply, message))
    end

    return 1
end)

Hook('sayteam', function(ply, message)

    if ply:is_traitor() then
        Chat.traitor_message_team(ply, message)
    end
    
    return 1
end)
