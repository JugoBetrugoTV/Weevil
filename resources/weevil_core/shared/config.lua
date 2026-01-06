--[[
    Weevil Multi-Gamemode - Configuration
    Main configuration file for all server settings
]]

Config = {}

-- Server Information
Config.ServerName = "Weevil Gaming"
Config.ServerVersion = "1.0.0"
Config.Website = "https://weevil.gg"
Config.Discord = "https://discord.gg/weevil"

-- Database Configuration (MySQL)
Config.Database = {
    host = "localhost",
    port = 3306,
    database = "weevil_mgm",
    username = "root",
    password = "",
    options = "autoreconnect=1;charset=utf8mb4"
}

-- Lobby Settings
Config.Lobby = {
    spawnPosition = { x = 0, y = 0, z = 3 },
    spawnRotation = 0,
    dimension = 0,
    interior = 0,
    skinId = 0, -- CJ default
    weather = 0,
    time = { hour = 12, minute = 0 }
}

-- Currency Settings
Config.Currency = {
    startMoney = 1000,
    startPoints = 0,
    currencyName = "Coins",
    pointsName = "Points"
}

-- Gamemodes Configuration
Config.Gamemodes = {
    dm = {
        name = "Deathmatch",
        shortName = "DM",
        description = "Race against others with weapons enabled",
        icon = "dm.png",
        color = "#FF4444",
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 100,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 10,
        moneyPerWin = 100
    },
    race = {
        name = "Race",
        shortName = "Race",
        description = "Classic oldschool racing",
        icon = "race.png",
        color = "#44FF44",
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 200,
        enabled = true,
        pointsPerFinish = 10,
        pointsPerWin = 50,
        moneyPerFinish = 20,
        moneyPerWin = 100
    },
    dd = {
        name = "Destruction Derby",
        shortName = "DD",
        description = "Destroy all opponents to win",
        icon = "dd.png",
        color = "#FF8844",
        minPlayers = 2,
        maxPlayers = 32,
        dimension = 300,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 15,
        moneyPerWin = 100
    },
    hunter = {
        name = "Hunter",
        shortName = "Hunter",
        description = "Helicopter combat arena",
        icon = "hunter.png",
        color = "#4488FF",
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 400,
        enabled = true,
        pointsPerKill = 5,
        pointsPerWin = 50,
        moneyPerKill = 20,
        moneyPerWin = 150
    },
    shooter = {
        name = "Shooter",
        shortName = "Shooter",
        description = "First-person shooter combat",
        icon = "shooter.png",
        color = "#FF44FF",
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 500,
        enabled = true,
        pointsPerKill = 3,
        pointsPerWin = 40,
        moneyPerKill = 8,
        moneyPerWin = 80
    },
    stuntage = {
        name = "Stuntage",
        shortName = "Stunt",
        description = "Complete stunts around San Andreas",
        icon = "stuntage.png",
        color = "#FFFF44",
        minPlayers = 1,
        maxPlayers = 32,
        dimension = 600,
        enabled = true,
        pointsPerStunt = 10,
        pointsPerWin = 100,
        moneyPerStunt = 25,
        moneyPerWin = 200
    },
    trials = {
        name = "Trials",
        shortName = "Trials",
        description = "Motorbike obstacle courses",
        icon = "trials.png",
        color = "#44FFFF",
        minPlayers = 1,
        maxPlayers = 16,
        dimension = 700,
        enabled = true,
        pointsPerFinish = 15,
        pointsPerWin = 60,
        moneyPerFinish = 30,
        moneyPerWin = 120
    },
    carball = {
        name = "Carball",
        shortName = "Carball",
        description = "Football with cars",
        icon = "carball.png",
        color = "#88FF88",
        minPlayers = 2,
        maxPlayers = 10,
        dimension = 800,
        enabled = true,
        pointsPerGoal = 10,
        pointsPerWin = 50,
        moneyPerGoal = 20,
        moneyPerWin = 100
    },
    hotpursuit = {
        name = "Hot Pursuit",
        shortName = "HP",
        description = "Racers vs Police",
        icon = "hotpursuit.png",
        color = "#8844FF",
        minPlayers = 4,
        maxPlayers = 32,
        dimension = 900,
        enabled = true,
        pointsPerCatch = 8,
        pointsPerEscape = 15,
        moneyPerCatch = 25,
        moneyPerEscape = 40
    },
    runarena = {
        name = "Run Arena",
        shortName = "Run",
        description = "Race on foot with combat",
        icon = "runarena.png",
        color = "#FF8888",
        minPlayers = 2,
        maxPlayers = 16,
        dimension = 1000,
        enabled = true,
        pointsPerKill = 3,
        pointsPerWin = 40,
        moneyPerKill = 8,
        moneyPerWin = 80
    },
    training = {
        name = "Training",
        shortName = "Train",
        description = "Practice your skills",
        icon = "training.png",
        color = "#888888",
        minPlayers = 1,
        maxPlayers = 8,
        dimension = 1100,
        enabled = true,
        pointsPerFinish = 0,
        moneyPerFinish = 0
    }
}

-- Arena Settings
Config.Arena = {
    countdownTime = 10, -- seconds
    minPlayersToStart = 2,
    maxIdleTime = 300, -- 5 minutes
    respawnTime = 3, -- seconds
    maxRoundTime = 600, -- 10 minutes
    voteTime = 20 -- seconds for map voting
}

-- Scoreboard Settings
Config.Scoreboard = {
    maxPlayersShown = 50,
    updateInterval = 1000, -- ms
    columns = {"Name", "Points", "Kills", "Deaths", "Money", "Ping"}
}

-- TopTimes Settings
Config.TopTimes = {
    maxEntries = 100,
    showTop = 10
}

-- Achievements Configuration
Config.Achievements = {
    categories = {
        "Racing",
        "Combat",
        "Social",
        "Exploration",
        "Mastery"
    }
}

-- Admin Levels
Config.AdminLevels = {
    [1] = { name = "Moderator", color = "#00FF00" },
    [2] = { name = "Admin", color = "#0000FF" },
    [3] = { name = "Super Admin", color = "#FF00FF" },
    [4] = { name = "Owner", color = "#FF0000" }
}

-- VIP Settings
Config.VIP = {
    enabled = true,
    bonusMultiplier = 1.5, -- 50% more points/money
    features = {
        "Custom nametag color",
        "VIP chat prefix",
        "Exclusive vehicle skins",
        "Double rewards",
        "Priority queue"
    }
}

-- Anti-Cheat Settings
Config.AntiCheat = {
    enabled = true,
    checkSpeed = true,
    checkTeleport = true,
    checkWeapons = true,
    checkHealth = true,
    banOnDetection = false -- Set to true to auto-ban
}

-- Chat Settings
Config.Chat = {
    globalPrefix = "[Global]",
    teamPrefix = "[Team]",
    arenaPrefix = "[Arena]",
    pmPrefix = "[PM]",
    adminPrefix = "[Admin]"
}

-- Sound Settings
Config.Sounds = {
    enabled = true,
    volume = 0.5,
    notifications = true,
    music = true
}

-- GUI Theme Colors
Config.Theme = {
    primary = tocolor(41, 128, 185, 255),    -- Blue
    secondary = tocolor(52, 73, 94, 255),     -- Dark Blue-Gray
    success = tocolor(39, 174, 96, 255),      -- Green
    danger = tocolor(231, 76, 60, 255),       -- Red
    warning = tocolor(241, 196, 15, 255),     -- Yellow
    info = tocolor(52, 152, 219, 255),        -- Light Blue
    dark = tocolor(44, 62, 80, 255),          -- Dark
    light = tocolor(236, 240, 241, 255),      -- Light Gray
    background = tocolor(30, 30, 30, 220),    -- Dark Background
    panel = tocolor(40, 40, 40, 240),         -- Panel Background
    text = tocolor(255, 255, 255, 255),       -- White Text
    textSecondary = tocolor(180, 180, 180, 255) -- Gray Text
}

return Config
