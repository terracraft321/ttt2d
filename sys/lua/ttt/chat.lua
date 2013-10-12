Chat = {}
Chat.commands = {}
Chat.privileges = {}

function Chat.add_command(cmd, desc, rank, func)
    if Chat.commands[cmd] then
        error("Chat command already exists: " .. cmd)
    else
        Chat.commands[cmd] = {desc = desc, rank = rank, func = func}
    end
end

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
    local command = message:match("^[!/][%a_]+")
    
    if not command then
        return false
    end
    
    if not Chat.commands[command:sub(2)] then
        ply:msg(Color.traitor .. "Command not found!")
        return true
    end
    
    local func = Chat.commands[command:sub(2)].func
    local rank = Chat.commands[command:sub(2)].rank
    
    if ply.rank < rank then
        ply:msg(Color.traitor .. "You're not allowed to use that command!")
    else
        TTT.debug(ply.name .. " used command " .. message)
        func(ply, message:sub(command:len()+2))
    end
    return true
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

Chat.add_command("commands", "Show commands available", RANK_GUEST, function(ply, arg)
    for command,tbl in pairs(Chat.commands) do
        if ply.rank >= tbl.rank then
            ply:msg(Color.white .. command .. " | " .. tbl.desc)
        end
    end
end)

Chat.add_command("resethud", "Reset your hud", RANK_GUEST, function(ply, arg)
    Hud.clear(ply)
    Hud.draw(ply)
    Hud.update_health(ply)
end)

Chat.add_command("map", "Change map", RANK_MODERATOR, function(ply, arg)
    Parse('map', arg)
end)

Chat.add_command("maplist", "List official maps", RANK_MODERATOR, function(ply, arg)
    for _,map in pairs(TTT.maps) do
        ply:msg(Color.white .. map)
    end
end)

Chat.add_command("bc", "Broadcast a message", RANK_MODERATOR, function(ply, arg)
    msg(Color.white .. arg)
end)

Chat.add_command("t_win", "Traitors win", RANK_ADMIN, function(ply, arg)
    if TTT.is_running() then
        TTT.round_end(ROLE_TRAITOR)
    end
end)

Chat.add_command("i_win", "Innocent win", RANK_ADMIN, function(ply, arg)
    if TTT.is_running() then
        TTT.round_end(ROLE_TRAITOR)
    end
end)

Chat.add_command("reset", "Reset player's karma", RANK_ADMIN, function(ply, arg)
    local id = tonumber(arg)
    Player(id).karma = Karma.base
    Player(id).score = Karma.base
    Karma.apply_karma(Player(id))
end)

Chat.add_command("ban", "Ban player for 6 hours", RANK_MODERATOR, function(ply, arg)
    local id = tonumber(arg)
    if not Player(id) or not Player(id).exists then
        ply:msg(Color.traitor .. "Player with that ID doesn't exist")
        return
    end
    Player(id):banusgn(6*60, "Banned by " .. ply.name)
end)

Chat.add_command("kick", "Kick player", RANK_MODERATOR, function(ply, arg)
    local id = tonumber(arg)
    if not Player(id) or not Player(id).exists then
        ply:msg(Color.traitor .. "Player with that ID doesn't exist")
        return
    end
    Player(id):kick("Kicked by " .. ply.name)
end)

Chat.add_command("make_moderator", "Make moderator", RANK_ADMIN, function(ply, arg)
    local id = tonumber(arg)
    if not Player(id) or not Player(id).exists then
        ply:msg(Color.traitor .. "Player with that ID doesn't exist")
        return
    end
    Player(id).rank = RANK_MODERATOR
end)

Chat.add_command("points", "Show how many points you got", RANK_GUEST, function(ply, arg)
    ply:msg(Color.white .. "You got " .. Color.traitor .. math.floor(ply.points) .. Color.white .. " points.")
end)
