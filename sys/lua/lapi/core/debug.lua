Debug = {}
Debug.mt = {}

setmetatable(Debug, {
    __call = function(_, state, func)
        return setmetatable({state=state, func=func}, Debug.mt)
    end
})

function Debug.mt:__index(key)
    return rawget(Debug.mt, key)
end

function Debug.mt:state(state)
    self.state = state
end

function Debug.mt:__call(...)
    if self.state then
        return self.func(unpack({...}))
    end
end
