local hud_x = 105
local hud_y = 425
local hud = {
    detectives={}
}

local hud_txt1 = Hudtxt(0, 1)
local hud_timer = 0

Hook('second', function()
    if hud_timer > 0 then
        hud_timer = hud_timer - 1
    end
    draw_timer()
end)

function set_timer(value)
    hud_timer = value
end

function draw_timer()
    local minutes = math.floor(hud_timer/60)
    local seconds = hud_timer % 60
    local str = Color(220, 220, 220) .. string.format("%01d:%02d", minutes, seconds)
    hud_txt1:show(str, hud_x + 20, hud_y - 3, 0)
end

function draw_base(ply)
    if ply.bot then return end
    
    if ply.hud.base then
        ply.hud.base:remove()
    end

    ply.hud.base = Image('gfx/ttt_dev/base.png', hud_x, hud_y, 2, ply.id)
end

function draw_team(ply)
    if ply.bot then return end
    
    if ply.hud.team then
        ply.hud.team:remove()
    end
    
    local path = ''
    if ply.role == INNOCENT then
        path = 'gfx/ttt_dev/innocent.png'
    elseif ply.role == PREPARING then
        path = 'gfx/ttt_dev/preparing.png'
    elseif ply.role == TRAITOR then
        path = 'gfx/ttt_dev/traitor.png'
    elseif ply.role == DETECTIVE then
        path = 'gfx/ttt_dev/detective.png'
    else
        path = 'gfx/ttt_dev/spectator.png'
    end
    
    ply.hud.team = Image(path, hud_x, hud_y, 2, ply.id)
end

function draw_health(ply)
    if ply.bot then return end
    
    if not ply.hud.health then
        ply.hud.health = Image('gfx/ttt_dev/health.png', hud_x, hud_y, 2, ply.id)
        ply.hud.health:color(20, 170, 50)
        --ply.hud.health:color(255, 255, 255)
    end
     
    local speed = 300
    local scale = ply.health / ply.maxhealth
    local red = 100 * (1-scale) + 20
    local green = 120 * scale + 50
    local blue = 50
    
    ply.hud.health:t_scale(speed, scale, 1)
    ply.hud.health:t_move(speed, hud_x-100 + scale*100, hud_y)
    ply.hud.health:t_color(speed, red, green, blue)
end

function mark_traitors(ply) 
    if ply.bot then return end
    if ply.hud.traitors then
        clear_traitors(ply) 
    end
    
    ply.hud.traitors = {}
    
    local players = Player.tableliving
    for _,v in pairs(players) do
        if v.role and v.role == TRAITOR then
            local img = Image('gfx/shadow.bmp<a>', 2, 0, v.id + 100, ply.id)
            img:scale(1.5, 1.5)
            img:color(220, 20, 20)
            table.insert(ply.hud.traitors, img)
        end
    end
end

function mark_detectives()
    local players = Player.tableliving
    for _,v in pairs(players) do
        if v.role and v.role == DETECTIVE then
            local img = Image('gfx/shadow.bmp<a>', 2, 0, v.id + 100)
            img:scale(1.5, 1.5)
            img:color(60, 60, 220)
            table.insert(hud.detectives, img)
        end
    end
end

function clear_detectives()
    for k,v in pairs(hud.detectives) do
        v:remove()
    end
end

function clear_traitors(ply)
    if ply.bot then return end
    if ply.hud.traitors then
        for k,v in pairs(ply.hud.traitors) do
            v:remove()
        end
        ply.hud.traitors = nil
    end
end

function draw_hud(ply)
    draw_base(ply)
    draw_team(ply)
    draw_health(ply)
end
