function math.exponential_decay(halflife, t)
    return math.exp((-0.69314718 / halflife) * t)
end
