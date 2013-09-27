Color = {}

setmetatable(Color, {
    __call = function(_, red, green, blue)
        return string.char(169) .. string.format("%03d%03d%03d", red, green, blue)
    end
})
