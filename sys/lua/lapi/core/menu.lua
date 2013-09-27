local menu = menu

Menu = {}
Menu.mt = {}
Menu.next_page = "Next page"

function Player.mt:menu(title)
    local m = setmetatable({
        ply = self,
        title = title,
        flag = '',
        buttons = {}
    }, Menu.mt)
    
    self.Menu = m
    return m
end

Hook('menu', function(ply, title, button)
    if not ply.Menu or ply.Menu.old_title ~= title then return end
    
    local data = {}
    local page = ply.Menu.old_page
    
    if button == 0 then  -- cancel
        data = {0, "cancel"}

    elseif #ply.Menu.buttons <= 9 then  -- only 9 buttons
        data = ply.Menu.buttons[button]
    
    elseif button == 9 then  -- "next page"
        if page == ply.Menu.last_page then
            ply.Menu:show(1)
        else
            ply.Menu:show(page + 1)
        end
        
        return
    else
        data = ply.Menu.buttons[(page-1) * 8 + button]
    end
    
    local func = ply.Menu.func
    
    ply.Menu = nil
    func(ply, data[1], data[2])
end)

function Menu.mt:__index(key)
    local m = rawget(Menu.mt, key)
    if m then return m end
end

function Menu.mt:button(key, value)
    table.insert(self.buttons, {key, value})
    return self
end

function Menu.mt:bind(func)
    self.func = func
    
    if #self.buttons > 9 then
        self.last_page = math.ceil(#self.buttons / 8)
    else
        self.last_page = 1
    end
    
    self:show(1)
end

function Menu.mt:show(page)
    
    local menu_title = self.title
    local menu_str = ''
    
    local start = (page-1) * 8 + 1
    local stop = start + 7
    
    for i = start, stop do
        if self.buttons[i] then
            menu_str = menu_str .. ',' .. self.buttons[i][2]
        else
            menu_str = menu_str .. ','
        end
    end
    
    if #self.buttons > 9 then
        menu_title = menu_title .. ' ' .. page .. '/' .. self.last_page 
        menu_str = menu_str .. ',' .. Menu.next_page
    end
    
    menu(self.ply.id, menu_title .. self.flag .. menu_str)
    
    self.old_title = menu_title
    self.old_page = page
end
