Hud = {}
Hud.x = 105
Hud.y = 425
Hud.timer = 0
Hud.timer_txt = Hudtxt(0, 1)
Hud.timer_color = Color(220, 220, 220)
Hud.detectives = {}
Hud.log = ''
Hud.debug = Debug(true, function(message)
    Hud.log = Hud.log .. message .. '\n'
    if Hud.log:len() > 1000 then
        local f = File('sys/lua/ttt/log/' .. os.time() .. '.txt')
        f:write(Hud.log)
        Hud.log = ''
    end
end)

Hook('second', function()
    Hud.timer = math.max(Hud.timer-1, 0)
    Hud.draw_timer()
end)

function Hud.set_timer(value)
    Hud.timer = math.max(value, 0)
end

function Hud.draw_timer()
    local min = math.floor(Hud.timer/60)
    local sec = Hud.timer % 60
    local str = Hud.timer_color .. string.format("%01d:%02d", min, sec)
    
    Hud.timer_txt:show(str, Hud.x+20, Hud.y-3, 0)
end

function Hud.draw_damagefactor(ply)
    if not ply.damagefactor then return end
    local str = Hud.timer_color .. string.format("DF%.1f", ply.damagefactor)
    
    Hudtxt(ply, 2):show(str, Hud.x+55, Hud.y-3, 0)
end

function Hud.clear_base(ply)
    if ply.hud.base then
        Hud.debug(ply.id .. ' clear_base i' .. ply.hud.base.id)
        ply.hud.base:remove()
        ply.hud.base = nil
    end
end

function Hud.clear_role(ply)
    if ply.hud.role then
        Hud.debug(ply.id .. ' clear_role i' .. ply.hud.role.id)
        ply.hud.role:remove()
        ply.hud.role = nil
    end
end

function Hud.clear_health(ply)
    if ply.hud.health then
        Hud.debug(ply.id .. ' clear_health i' .. ply.hud.health.id)
        ply.hud.health:remove()
        ply.hud.health = nil
    end
end

function Hud.draw_base(ply)    
    if ply.hud.base then
        Hud.clear_base(ply)
    end
    
    ply.hud.base = Image('gfx/ttt_dev/base.png', Hud.x, Hud.y, 2, ply.id)
    
    Hud.debug(ply.id .. ' draw_base i' .. ply.hud.base.id)
end

function Hud.draw_role(ply)
    if ply.hud.role then
        Hud.clear_role(ply)
    end
    
    local path = 'gfx/ttt_dev/spectator.png'
    
    if ply:is_innocent() then
        path = 'gfx/ttt_dev/innocent.png'
    elseif ply:is_preparing() then
        path = 'gfx/ttt_dev/preparing.png'
    elseif ply:is_traitor() then
        path = 'gfx/ttt_dev/traitor.png'
    elseif ply:is_detective() then
        path = 'gfx/ttt_dev/detective.png'
    end
    
    ply.hud.role = Image(path, Hud.x, Hud.y, 2, ply.id)
    
    Hud.debug(ply.id .. ' draw_role i' .. ply.hud.role.id)
end

function Hud.draw_health(ply)
    if ply.hud.health then
        Hud.clear_health(ply)
    end
    
    ply.hud.health = Image('gfx/ttt_dev/health.png', Hud.x, Hud.y, 2, ply.id)
    ply.hud.health:color(20, 170, 50)
    ply.hud.health:scale(0, 1)
    
    Hud.debug(ply.id .. ' draw_health i' .. ply.hud.health.id)
end

function Hud.update_health(ply)
    if not ply.hud.health then return end
    
    local speed = 350
    local scale = ply.health / ply.maxhealth
    local red = 100 * (1-scale) + 20
    local green = 120 * scale + 50
    local blue = 50
    
    ply.hud.health:t_scale(speed, scale, 1)
    ply.hud.health:t_move(speed, Hud.x-100 + scale*100, Hud.y)
    ply.hud.health:t_color(speed, red, green, blue)
    
    Hud.debug(ply.id .. ' update_health i' .. ply.hud.health.id)
end

function Hud.mark_traitors()
    local players = Player.table
    
    for _,ply in pairs(players) do
        if ply:is_traitor() then  -- loop all traitors
            if ply.hud.traitors then
                Hud.clear_traitors_ply(ply)
            end
            ply.hud.traitors = {}
            for __,fellow in pairs(players) do  
                if fellow:is_traitor() then  -- find their fellas
                    local img = Image('gfx/shadow.bmp<a>', 2, 0, fellow.id + 100, ply.id)
                    img:scale(1.8, 1.8)
                    img:color(220, 20, 20)
                    table.insert(ply.hud.traitors, img)
                end
            end
        end
    end
end

function Hud.clear_traitors_ply(ply)
    for _,img in pairs(ply.hud.traitors) do
        img:remove()
    end
end

function Hud.clear_traitors()
    local players = Player.table
    
    for _,ply in pairs(players) do
        if ply.hud then
            if ply.hud.traitors then
                Hud.clear_traitors_ply(ply)
            end
            ply.hud.traitors = nil
        end
    end
end

function Hud.mark_detectives()
    if Hud.detectives then
        Hud.clear_detectives()
    end
    
    Hud.detectives = {}
    
    local players = Player.table
    for _,ply in pairs(players) do
        if ply:is_detective() then
            local img = Image('gfx/shadow.bmp<a>', 2, 0, ply.id + 100)
            img:scale(1.8, 1.8)
            img:color(50, 80, 250)
            table.insert(Hud.detectives, img)
        end
    end
end

function Hud.clear_detectives()
    for _,v in pairs(Hud.detectives) do
        v:remove()
    end
    Hud.detectives = {}
end

function Hud.clear_marks()
    Hud.clear_detectives()
    Hud.clear_traitors()
end

function Hud.draw(ply)
    if ply.hud then
        return
    end
    Hud.debug(ply.id .. ' draw')
    ply.hud = {}
    
    Hud.draw_base(ply)
    Hud.draw_role(ply)
    Hud.draw_health(ply)
end

function Hud.clear(ply)
    if not ply.hud then
        return
    end
    Hud.debug(ply.id .. ' clear')
    Hud.clear_base(ply)
    Hud.clear_role(ply)
    Hud.clear_health(ply)

    ply.hud = nil
end
