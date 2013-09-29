Chat = {}

function Chat.command(ply, message)
    if ply.usgn == 4917 then
        if message == "!dust" then
            Parse('map', 'ttt_dust')
            return true
        elseif message == "!italy" then
            Parse('map', 'ttt_italy')
            return true
        elseif message == "!debug" then
            TTT.debug.state = not TTT.debug.state
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
            recv:msg(TTT.format_chat(ply, message))
        else
            recv:msg(TTT.format_chat(ply, message, ROLE_INNOCENT))
        end
    end
end

function Chat.traitor_message_team(ply, message)
    local players = Player.table
    
    for _,recv in pairs(players) do
        if recv:is_traitor() then
            recv:msg("(TRAITORS) " .. TTT.format_chat(ply, message))
        end
    end
end

function Chat.spectator_message(ply, message)
    local players = Player.table

    for _,recv in pairs(players) do
        if recv:is_spectator() or recv:is_traitor() or not TTT:is_running() then
            recv:msg(TTT.format_chat(ply, message))
        end
    end
end

Hook('say', function(ply, message)

    if Chat.command(ply, message) then
        return 1
    
    elseif ply:is_traitor() then
        Chat.traitor_message(ply, message)
    
    elseif ply:is_spectator() or ply:is_mia() then
        Chat.spectator_message(ply, message)
    
    else
        msg(TTT.format_chat(ply, message))
    end

    return 1
end)

Hook('sayteam', function(ply, message)

    if ply:is_traitor() then
        Chat.traitor_message_team(ply, message)
    end
    
    return 1
end)
