-- colors
Color.innocent = Color(20, 220, 20)
Color.traitor = Color(220, 20, 20)
Color.detective = Color(50, 80, 250)
Color.spectator = Color(220, 220, 20)
Color.white = Color(220, 220, 220)

-- game states
STATE_WAITING = 1
STATE_STARTING = 2
STATE_PREPARING = 3
STATE_RUNNING = 4

-- player roles
ROLE_INNOCENT = 1
ROLE_TRAITOR = 2
ROLE_DETECTIVE = 3
ROLE_MIA = 4
ROLE_SPECTATOR = 5
ROLE_PREPARING = 6

-- player ranks
RANK_GUEST = 1
RANK_VIP = 2
RANK_MODERATOR = 3
RANK_ADMIN = 4

-- ground items
WEAPON_1 = {30, 20, 10}
WEAPON_2 = {2, 4, 69}

-- time
TIME_PREPARE = 15
TIME_GAME = 180

-- karma
Karma.base = 1000
Karma.player_base = 800
Karma.max = 1500
Karma.kick = 500
Karma.reset = 600
Karma.halflife = 0.2
Karma.regen = 5
Karma.clean = 30
Karma.speedmod = 4
Karma.hurt_reward = 0.0003
Karma.kill_reward = 40
Karma.traitor_reward = 50
Karma.hurt_penalty = 0.0015
Karma.kill_penalty = 15
Karma.vote_penalty = 100
Karma.traitor_penalty = 50
Karma.min_players = 4

-- maps
TTT.maps = {
    "ttt_suspicion",
    "ttt_trauma",
    "ttt_dust",
    "ttt_italy"
}
