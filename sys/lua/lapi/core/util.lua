function math.exponential_decay(halflife, t)
    return math.exp((-0.69314718 / halflife) * t)
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
