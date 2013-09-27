dofile('sys/lua/lapi/lapi.lua')
lapi.load('plugins/menu.lua')

Hook('say', function(ply, message)

    if message == 'money' then
        local menu = ply:menu('Set your money')
        
        --          key   value (text)
        menu:button(1000, '$1000')
        menu:button(2000, '$2000')
        menu:button(3000, '$3000')
        menu:button(4000, '$4000')
        menu:button(5000, '$5000')
        
        menu:bind(function(_, key, value)
        
            if key ~= 0 then
                ply.money = key
                ply:msg('You set your money to ' .. value)
            end
        end)
        
        return 1
    end
end)
