local game = game

Game = {}

setmetatable(Game, {
    __index = function(_, key)
        return game(key)
    end,
    __newindex = function(_, key, value)
        Parse(key, value)
    end
})
