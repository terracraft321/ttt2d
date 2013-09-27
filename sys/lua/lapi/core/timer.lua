local timer = timer
local freetimer = freetimer

Timer = {}
Timer.mt = {}
Timer.count = 0

setmetatable(Timer, {
    __call = function(_, time, func, ...)
        local id = 'Timer_' .. Timer.count
        
        Timer[id] = function(timer_id)
            Timer[timer_id] = nil
            func(unpack(arg))
        end
        
        timer(time, 'Timer.' .. id, id)
        
        Timer.count = Timer.count + 1
        
        return setmetatable({id = id}, Timer.mt)
    end
})

function Timer.mt:__index(key)
    local m = rawget(Timer.mt, key)
    if m then
        return m
    end
end

function Timer.mt:remove()
    Timer[self.id] = nil
    freetimer('Timer.' .. self.id, self.id)
end
