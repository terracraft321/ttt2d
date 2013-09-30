local addhook = addhook
local freehook = freehook

Hook = {}
Hook.count = 0
Hook.mt = {}
Hook.support = {
    attack = true,
    attack2 = true,
    bombdefuse = true,
    bombexplode = true,
    bombplant = true,
    build = true,
    buildattempt = true,
    buy = true,
    clientdata = true,
    collect = true,
    die = true,
    dominate = true,
    drop = true,
    flagcapture = true,
    flagtake = true,
    flashlight = true,
    hit = true,
    hostagerescue = true,
    join = true,
    kill = true,
    leave = true,
    menu = true,
    move = true,
    movetile = true,
    name = true,
    radio = true,
    reload = true,
    say = true,
    sayteam = true,
    select = true,
    serveraction = true,
    spawn = true,
    spray = true,
    team = true,
    use = true,
    usebutton = true,
    vipescape = true,
    vote = true,
    walkover = true,
    hitzone = true,
    objectdamage = true,
    objectkill = true,
    objectupgrade = true,
    projectile = true,
    rcon = true
}
Hook.support['break'] = true

setmetatable(Hook, {
    __call = function(_, hook, func, prio)
        local id = 'Hook_' .. Hook.count
        
        if Hook.support[hook] then
            if hook == 'kill' then
                Hook[id] = function(killer, victim, ...)
                    return func(Player(killer), Player(victim), unpack({...}))
                end
            elseif hook == 'hit' then
                Hook[id] = function(ply, source, weapon, ...)
                    return func(Player(ply), Player(source), weapon, unpack({...}))
                end
            elseif hook == 'hitzone' then
                Hook[id] = function(img, ply, obj, ...)
                    return func(Image(img), Player(ply), Object(obj), unpack({...}))
                end
            elseif hook == 'objectdamage' then
                Hook[id] = function(id, dmg, ply)
                    return func(Object(id), dmg, Player(ply))
                end
            elseif hook == 'objectkill' then
                Hook[id] = function(id, ply)
                    return func(Object(id), Player(ply))
                end
            elseif hook == 'objectupgrade' then
                Hook[id] = function(id, ply, ...)
                    return func(Object(id), Player(ply), unpack({...}))
                end
            elseif hook == 'break' then
                Hook[id] = function(x, y, ply)
                    return func(x, y, Player(ply))
                end
            elseif hook == 'rcon' then
                Hook[id] = function(cmds, ply, ...)
                    return func(cmds, Player(ply), unpack({...}))
                end
            else
                Hook[id] = function(id, ...) -- create a wrapper function
                    return func(Player(id), unpack({...}))
                end
            end
        else
            Hook[id] = function(...)
                return func(unpack({...}))
            end
        end
        
        if prio then
            addhook(hook, 'Hook.' .. id, prio)
        else
            addhook(hook, 'Hook.' .. id)
        end
        Hook.count = Hook.count + 1
        
        local tbl = {
            hook = hook,
            func = func,
            prio = prio,
            id = 'Hook.' .. id
        }
        return setmetatable(tbl, Hook.mt)
    end
})

function Hook.mt:remove()
    freehook(self.hook, self.id)
end

