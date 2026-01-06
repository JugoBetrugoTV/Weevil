--[[
    Jebiga Multi-Gamemode - Configuration
    Main configuration file for all server settings
    Modern, Custom-designed Gaming Experience
]]

Config = {}

-- Server Information
Config.ServerName = "Jebiga Gaming"
Config.ServerVersion = "2.0.0"
Config.ServerMotto = "The Ultimate MTA Experience"
Config.Website = "https://jebiga.gg"
Config.Discord = "https://discord.gg/jebiga"

-- Database Configuration (MySQL)
Config.Database = {
    host = "localhost",
    port = 3306,
    database = "jebiga_mgm",
    username = "root",
    password = "",
    options = "autoreconnect=1;charset=utf8mb4"
}

-- Lobby Settings
Config.Lobby = {
    spawnPosition = { x = 1481.09, y = -1770.53, z = 18.79 }, -- LS Beach
    spawnRotation = 180,
    dimension = 0,
    interior = 0,
    skinId = 0,
    weather = 0,
    time = { hour = 20, minute = 0 }, -- Night time for cool lighting
    cameraPositions = {
        { x = 1520, y = -1800, z = 50, lookX = 1481, lookY = -1770, lookZ = 18 },
        { x = 1430, y = -1720, z = 40, lookX = 1481, lookY = -1770, lookZ = 18 },
        { x = 1550, y = -1750, z = 35, lookX = 1481, lookY = -1770, lookZ = 18 }
    }
}

-- Currency Settings
Config.Currency = {
    startMoney = 5000,
    startPoints = 0,
    currencyName = "JCoins",
    pointsName = "JP", -- Jebiga Points
    dailyBonus = 500,
    weeklyBonus = 2500
}

-- Map Prefix Configuration (for auto-detection)
Config.MapPrefixes = {
    dm = {"[DM]", "[Deathmatch]", "DM-", "Deathmatch-"},
    race = {"[Race]", "[Oldschool]", "Race-", "[OS]"},
    dd = {"[DD]", "[Derby]", "DD-", "[Destruction]"},
    hunter = {"[Hunter]", "[Hunt]", "Hunter-"},
    shooter = {"[Shooter]", "[FPS]", "[CTF]", "Shooter-"},
    stuntage = {"[Stunt]", "[Stuntage]", "Stunt-"},
    trials = {"[Trials]", "[Trial]", "Trials-"},
    carball = {"[Carball]", "[CB]", "Carball-"},
    hotpursuit = {"[HP]", "[HotPursuit]", "[Pursuit]", "HP-"},
    runarena = {"[Run]", "[RunArena]", "[RA]", "Run-"},
    training = {"[Training]", "[Train]", "[Practice]", "Training-"}
}

-- Gamemodes Configuration
Config.Gamemodes = {
    dm = {
        name = "Deathmatch",
        shortName = "DM",
        description = "Race with weapons - Destroy your enemies!",
        icon = "dm",
        color = {255, 68, 68},
        colorHex = "#FF4444",
        gradient = {255, 100, 100},
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 100,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 10,
        moneyPerWin = 100,
        teleportPos = { x = 2020.5, y = 1544.5, z = 10.8 }, -- LV Arena area
        lobbyPos = { x = 1481, y = -1780, z = 18.79 }
    },
    race = {
        name = "Race",
        shortName = "Race",
        description = "Classic oldschool racing - Pure skill!",
        icon = "race",
        color = {68, 255, 68},
        colorHex = "#44FF44",
        gradient = {100, 255, 100},
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 200,
        enabled = true,
        pointsPerFinish = 10,
        pointsPerWin = 50,
        moneyPerFinish = 20,
        moneyPerWin = 100,
        teleportPos = { x = -2666.5, y = 2327.2, z = 4.9 }, -- SF Airport
        lobbyPos = { x = 1485, y = -1780, z = 18.79 }
    },
    dd = {
        name = "Destruction Derby",
        shortName = "DD",
        description = "Last vehicle standing wins!",
        icon = "dd",
        color = {255, 136, 68},
        colorHex = "#FF8844",
        gradient = {255, 170, 100},
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 300,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 15,
        moneyPerWin = 100,
        teleportPos = { x = 1096.6, y = -842.1, z = 52.1 }, -- LS Stadium
        lobbyPos = { x = 1489, y = -1780, z = 18.79 }
    },
    hunter = {
        name = "Hunter",
        shortName = "Hunter",
        description = "Helicopter combat arena - Rule the skies!",
        icon = "hunter",
        color = {68, 136, 255},
        colorHex = "#4488FF",
        gradient = {100, 170, 255},
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 400,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 20,
        moneyPerWin = 150,
        teleportPos = { x = 391.5, y = 2534.7, z = 16.5 },
        lobbyPos = { x = 1493, y = -1780, z = 18.79 }
    },
    shooter = {
        name = "Shooter",
        shortName = "FPS",
        description = "First-person shooter - Team combat!",
        icon = "shooter",
        color = {255, 68, 255},
        colorHex = "#FF44FF",
        gradient = {255, 120, 255},
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 500,
        enabled = true,
        pointsPerKill = 3,
        pointsPerWin = 40,
        moneyPerKill = 8,
        moneyPerWin = 80,
        teleportPos = { x = 213.8, y = 1875.3, z = 13.1 },
        lobbyPos = { x = 1477, y = -1780, z = 18.79 }
    },
    stuntage = {
        name = "Stuntage",
        shortName = "Stunt",
        description = "Complete stunts for points!",
        icon = "stuntage",
        color = {255, 255, 68},
        colorHex = "#FFFF44",
        gradient = {255, 255, 120},
        minPlayers = 1,
        maxPlayers = 32,
        dimension = 600,
        enabled = true,
        pointsPerStunt = 10,
        pointsPerWin = 100,
        moneyPerStunt = 25,
        moneyPerWin = 200,
        teleportPos = { x = 687.5, y = -471.3, z = 16.5 },
        lobbyPos = { x = 1473, y = -1780, z = 18.79 }
    },
    trials = {
        name = "Trials",
        shortName = "Trials",
        description = "Motorbike obstacle courses!",
        icon = "trials",
        color = {68, 255, 255},
        colorHex = "#44FFFF",
        gradient = {120, 255, 255},
        minPlayers = 1,
        maxPlayers = 16,
        dimension = 700,
        enabled = true,
        pointsPerFinish = 15,
        pointsPerWin = 60,
        moneyPerFinish = 30,
        moneyPerWin = 120,
        teleportPos = { x = -1965.2, y = 127.8, z = 27.7 },
        lobbyPos = { x = 1469, y = -1780, z = 18.79 }
    },
    carball = {
        name = "Carball",
        shortName = "CB",
        description = "Football with cars!",
        icon = "carball",
        color = {136, 255, 136},
        colorHex = "#88FF88",
        gradient = {150, 255, 150},
        minPlayers = 2,
        maxPlayers = 10,
        dimension = 800,
        enabled = true,
        pointsPerGoal = 10,
        pointsPerWin = 50,
        moneyPerGoal = 20,
        moneyPerWin = 100,
        teleportPos = { x = 2540.7, y = 2022.8, z = 10.8 },
        lobbyPos = { x = 1465, y = -1780, z = 18.79 }
    },
    hotpursuit = {
        name = "Hot Pursuit",
        shortName = "HP",
        description = "Racers vs Police - Escape or catch!",
        icon = "hotpursuit",
        color = {136, 68, 255},
        colorHex = "#8844FF",
        gradient = {170, 120, 255},
        minPlayers = 4,
        maxPlayers = 32,
        dimension = 900,
        enabled = true,
        pointsPerCatch = 8,
        pointsPerEscape = 15,
        moneyPerCatch = 25,
        moneyPerEscape = 40,
        teleportPos = { x = 1699.0, y = -1469.8, z = 13.5 },
        lobbyPos = { x = 1461, y = -1780, z = 18.79 }
    },
    runarena = {
        name = "Run Arena",
        shortName = "Run",
        description = "Race on foot with combat!",
        icon = "runarena",
        color = {255, 136, 136},
        colorHex = "#FF8888",
        gradient = {255, 170, 170},
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 1000,
        enabled = true,
        pointsPerKill = 3,
        pointsPerWin = 40,
        moneyPerKill = 8,
        moneyPerWin = 80,
        teleportPos = { x = 1544.5, y = -1353.5, z = 329.5 },
        lobbyPos = { x = 1457, y = -1780, z = 18.79 }
    },
    training = {
        name = "Training",
        shortName = "Train",
        description = "Practice your skills - No pressure!",
        icon = "training",
        color = {136, 136, 136},
        colorHex = "#888888",
        gradient = {170, 170, 170},
        minPlayers = 1,
        maxPlayers = 8,
        dimension = 1100,
        enabled = true,
        pointsPerFinish = 0,
        moneyPerFinish = 0,
        teleportPos = { x = 1964.7, y = 1343.3, z = 15.4 },
        lobbyPos = { x = 1453, y = -1780, z = 18.79 }
    }
}

-- Arena Settings
Config.Arena = {
    countdownTime = 10,
    minPlayersToStart = 2,
    maxIdleTime = 300,
    respawnTime = 3,
    maxRoundTime = 600,
    voteTime = 20
}

-- Scoreboard Settings
Config.Scoreboard = {
    maxPlayersShown = 50,
    updateInterval = 1000,
    columns = {"Name", "Points", "Kills", "Deaths", "Money", "Ping"}
}

-- TopTimes Settings
Config.TopTimes = {
    maxEntries = 100,
    showTop = 10
}

-- Achievements Configuration
Config.Achievements = {
    list = {
        -- Racing
        { id = "first_race", name = "First Steps", desc = "Complete your first race", category = "Racing", reward = 100, icon = "trophy" },
        { id = "win_10_races", name = "Speed Demon", desc = "Win 10 races", category = "Racing", reward = 500, icon = "medal" },
        { id = "win_100_races", name = "Racing Legend", desc = "Win 100 races", category = "Racing", reward = 2500, icon = "crown" },
        { id = "perfect_race", name = "Flawless", desc = "Win a race without hitting anything", category = "Racing", reward = 1000, icon = "star" },

        -- Combat
        { id = "first_kill", name = "First Blood", desc = "Get your first kill", category = "Combat", reward = 100, icon = "skull" },
        { id = "kill_100", name = "Warrior", desc = "Get 100 kills", category = "Combat", reward = 500, icon = "sword" },
        { id = "kill_1000", name = "Destroyer", desc = "Get 1000 kills", category = "Combat", reward = 2500, icon = "fire" },
        { id = "dd_master", name = "DD Master", desc = "Win 50 DD rounds", category = "Combat", reward = 1500, icon = "car" },

        -- Social
        { id = "first_login", name = "Welcome", desc = "Join Jebiga Gaming", category = "Social", reward = 50, icon = "wave" },
        { id = "play_100_hours", name = "Dedicated", desc = "Play for 100 hours", category = "Social", reward = 2000, icon = "clock" },
        { id = "refer_friend", name = "Recruiter", desc = "Refer a friend", category = "Social", reward = 500, icon = "users" },

        -- Mastery
        { id = "all_gamemodes", name = "Jack of All Trades", desc = "Play all gamemodes", category = "Mastery", reward = 1000, icon = "globe" },
        { id = "top_10", name = "Elite", desc = "Reach top 10 in any gamemode", category = "Mastery", reward = 2000, icon = "chart" },
        { id = "millionaire", name = "Millionaire", desc = "Earn 1,000,000 JCoins total", category = "Mastery", reward = 5000, icon = "diamond" }
    },
    categories = {"Racing", "Combat", "Social", "Mastery"}
}

-- Admin Levels
Config.AdminLevels = {
    [1] = { name = "Moderator", color = "#00FF00", permissions = {"kick", "mute", "warn"} },
    [2] = { name = "Admin", color = "#00AAFF", permissions = {"kick", "mute", "warn", "ban", "teleport"} },
    [3] = { name = "Super Admin", color = "#FF00FF", permissions = {"kick", "mute", "warn", "ban", "teleport", "give", "setlevel"} },
    [4] = { name = "Owner", color = "#FF0000", permissions = {"*"} }
}

-- VIP Settings
Config.VIP = {
    enabled = true,
    bonusMultiplier = 2.0,
    features = {
        "Golden nametag",
        "VIP chat prefix [VIP]",
        "Exclusive vehicle skins",
        "Double rewards",
        "Priority queue",
        "Custom spawn vehicles",
        "Exclusive maps access"
    }
}

-- Anti-Cheat Settings
Config.AntiCheat = {
    enabled = true,
    checkSpeed = true,
    checkTeleport = true,
    checkWeapons = true,
    checkHealth = true,
    banOnDetection = false
}

-- Chat Settings
Config.Chat = {
    globalPrefix = "",
    teamPrefix = "[TEAM]",
    arenaPrefix = "",
    pmPrefix = "[PM]",
    adminPrefix = "[STAFF]"
}

-- Sound Settings
Config.Sounds = {
    enabled = true,
    volume = 0.5,
    notifications = true,
    music = true
}

-- ============================================
-- CUSTOM THEME SYSTEM - Modern Design
-- ============================================
Config.Theme = {
    -- Main Brand Colors
    brand = {
        primary = {41, 128, 185},      -- Main blue
        secondary = {155, 89, 182},    -- Purple accent
        accent = {46, 204, 113},       -- Green accent
        gold = {241, 196, 15}          -- VIP/Premium gold
    },

    -- Semantic Colors
    colors = {
        success = {46, 204, 113},      -- Green
        danger = {231, 76, 60},        -- Red
        warning = {241, 196, 15},      -- Yellow
        info = {52, 152, 219},         -- Blue
        neutral = {149, 165, 166}      -- Gray
    },

    -- Background Colors
    backgrounds = {
        dark = {18, 18, 24},           -- Main dark bg
        darker = {12, 12, 16},         -- Darker sections
        panel = {25, 28, 36},          -- Panel backgrounds
        panelHover = {35, 38, 48},     -- Panel hover state
        overlay = {0, 0, 0},           -- Modal overlay (with alpha)
        glass = {255, 255, 255}        -- Glass effect (with low alpha)
    },

    -- Text Colors
    text = {
        primary = {255, 255, 255},     -- Main text
        secondary = {160, 170, 180},   -- Secondary text
        muted = {100, 110, 120},       -- Muted text
        link = {52, 152, 219},         -- Link text
        inverse = {18, 18, 24}         -- Dark text for light bg
    },

    -- Border Colors
    borders = {
        default = {45, 50, 60},        -- Default border
        hover = {60, 70, 80},          -- Hover border
        focus = {41, 128, 185},        -- Focus border (primary)
        separator = {35, 40, 50}       -- Separator lines
    },

    -- Gradients (start, end colors)
    gradients = {
        primary = {{41, 128, 185}, {155, 89, 182}},     -- Blue to purple
        success = {{46, 204, 113}, {39, 174, 96}},      -- Green gradient
        danger = {{231, 76, 60}, {192, 57, 43}},        -- Red gradient
        gold = {{241, 196, 15}, {243, 156, 18}},        -- Gold gradient
        dark = {{25, 28, 36}, {18, 18, 24}}             -- Dark gradient
    },

    -- Shadows (for glow effects)
    shadows = {
        small = {0, 0, 0, 100},
        medium = {0, 0, 0, 150},
        large = {0, 0, 0, 200},
        glow = {41, 128, 185, 100}     -- Primary color glow
    },

    -- Font Settings
    fonts = {
        title = "bankgothic",
        heading = "pricedown",
        body = "default-bold",
        small = "default",
        scale = {
            title = 2.5,
            heading = 1.5,
            body = 1.0,
            small = 0.85
        }
    },

    -- Animation Settings
    animation = {
        duration = 300,                 -- ms
        easing = "OutQuad",
        hoverScale = 1.05,
        clickScale = 0.95
    },

    -- Border Radius (conceptual - drawn with custom shapes)
    radius = {
        small = 4,
        medium = 8,
        large = 12,
        full = 9999
    },

    -- Spacing
    spacing = {
        xs = 4,
        sm = 8,
        md = 16,
        lg = 24,
        xl = 32,
        xxl = 48
    }
}

-- Quick access color functions (will be expanded in UI lib)
function Config.getColor(colorTable, alpha)
    alpha = alpha or 255
    return tocolor(colorTable[1], colorTable[2], colorTable[3], alpha)
end

function Config.getGradientColors(gradientName, alpha)
    alpha = alpha or 255
    local grad = Config.Theme.gradients[gradientName]
    if not grad then return nil end
    return {
        tocolor(grad[1][1], grad[1][2], grad[1][3], alpha),
        tocolor(grad[2][1], grad[2][2], grad[2][3], alpha)
    }
end

-- Export function for other resources
function getConfig()
    return Config
end

return Config
