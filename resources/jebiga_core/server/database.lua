--[[
    Jebiga Multi-Gamemode - Database Module
    MySQL database connection and query handling
]]

local connection = nil
local isConnected = false

-- Initialize database connection
function initDatabase()
    local cfg = Config.Database
    local connectionString = string.format(
        "dbname=%s;host=%s;port=%d;%s",
        cfg.database,
        cfg.host,
        cfg.port,
        cfg.options
    )

    connection = dbConnect("mysql", connectionString, cfg.username, cfg.password)

    if connection then
        isConnected = true
        outputDebugString("[Jebiga] Database connected successfully")
        createTables()
        return true
    else
        isConnected = false
        outputDebugString("[Jebiga] Database connection failed!", 1)
        return false
    end
end

-- Create all required database tables
function createTables()
    if not isConnected then return end

    -- Accounts table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS accounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            email VARCHAR(100),
            serial VARCHAR(50),
            ip VARCHAR(45),
            admin_level INT DEFAULT 0,
            vip_level INT DEFAULT 0,
            vip_expires DATETIME,
            money INT DEFAULT 1000,
            total_points INT DEFAULT 0,
            playtime INT DEFAULT 0,
            last_login DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            banned TINYINT DEFAULT 0,
            ban_reason VARCHAR(255),
            ban_expires DATETIME,
            muted TINYINT DEFAULT 0,
            mute_expires DATETIME,
            settings TEXT,
            INDEX idx_serial (serial),
            INDEX idx_username (username)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Player statistics table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS player_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            gamemode VARCHAR(20) NOT NULL,
            points INT DEFAULT 0,
            wins INT DEFAULT 0,
            losses INT DEFAULT 0,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            races_finished INT DEFAULT 0,
            best_position INT DEFAULT 0,
            playtime INT DEFAULT 0,
            UNIQUE KEY unique_player_gamemode (account_id, gamemode),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- TopTimes table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS toptimes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            map_name VARCHAR(100) NOT NULL,
            gamemode VARCHAR(20) NOT NULL,
            time_ms INT NOT NULL,
            vehicle_id INT,
            recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_toptime (account_id, map_name, gamemode),
            INDEX idx_map_time (map_name, time_ms),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Achievements table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            achievement_id VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            category VARCHAR(50),
            points INT DEFAULT 10,
            icon VARCHAR(100),
            secret TINYINT DEFAULT 0,
            UNIQUE KEY unique_achievement (achievement_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Player achievements table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS player_achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            achievement_id VARCHAR(50) NOT NULL,
            unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_player_achievement (account_id, achievement_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Garage/Vehicles table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS player_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            vehicle_id INT NOT NULL,
            color1 INT DEFAULT 0,
            color2 INT DEFAULT 0,
            paintjob INT DEFAULT 0,
            upgrades TEXT,
            purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_player_vehicle (account_id, vehicle_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Friends table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS friends (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            friend_id INT NOT NULL,
            status ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_friendship (account_id, friend_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            FOREIGN KEY (friend_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Clans table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS clans (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            tag VARCHAR(10) NOT NULL,
            owner_id INT NOT NULL,
            description TEXT,
            color VARCHAR(10) DEFAULT '#FFFFFF',
            logo VARCHAR(100),
            money INT DEFAULT 0,
            level INT DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (owner_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Clan members table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS clan_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            clan_id INT NOT NULL,
            account_id INT NOT NULL,
            rank INT DEFAULT 0,
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_clan_member (clan_id, account_id),
            FOREIGN KEY (clan_id) REFERENCES clans(id) ON DELETE CASCADE,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Transaction log table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS transaction_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            type VARCHAR(20) NOT NULL,
            amount INT NOT NULL,
            reason VARCHAR(255),
            balance_after INT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_account_transactions (account_id, created_at),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Admin log table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS admin_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_id INT NOT NULL,
            action VARCHAR(50) NOT NULL,
            target_id INT,
            details TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_admin_actions (admin_id, created_at),
            FOREIGN KEY (admin_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Maps table
    dbExec(connection, [[
        CREATE TABLE IF NOT EXISTS maps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            resource_name VARCHAR(100) NOT NULL,
            gamemode VARCHAR(20) NOT NULL,
            author VARCHAR(50),
            difficulty INT DEFAULT 1,
            plays INT DEFAULT 0,
            rating FLOAT DEFAULT 0,
            votes INT DEFAULT 0,
            added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_map (resource_name, gamemode),
            INDEX idx_gamemode (gamemode)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Insert default achievements
    insertDefaultAchievements()

    outputDebugString("[Jebiga] Database tables created/verified")
end

-- Insert default achievements
function insertDefaultAchievements()
    local achievements = {
        -- Racing achievements
        { id = "first_win", name = "First Victory", desc = "Win your first race", category = "Racing", points = 10 },
        { id = "win_10", name = "Getting Started", desc = "Win 10 races", category = "Racing", points = 25 },
        { id = "win_100", name = "Veteran Racer", desc = "Win 100 races", category = "Racing", points = 100 },
        { id = "win_1000", name = "Racing Legend", desc = "Win 1000 races", category = "Racing", points = 500 },
        { id = "toptime_1", name = "Record Breaker", desc = "Set your first top time", category = "Racing", points = 15 },
        { id = "toptime_10", name = "Time Attack Master", desc = "Hold 10 top times", category = "Racing", points = 50 },

        -- Combat achievements
        { id = "first_kill", name = "First Blood", desc = "Get your first kill", category = "Combat", points = 10 },
        { id = "kill_100", name = "Warrior", desc = "Get 100 kills", category = "Combat", points = 50 },
        { id = "kill_1000", name = "Terminator", desc = "Get 1000 kills", category = "Combat", points = 200 },
        { id = "dd_survivor", name = "Survivor", desc = "Win a DD without taking damage", category = "Combat", points = 75 },
        { id = "hunter_ace", name = "Hunter Ace", desc = "Win 50 Hunter matches", category = "Combat", points = 100 },

        -- Social achievements
        { id = "play_1h", name = "Newcomer", desc = "Play for 1 hour", category = "Social", points = 5 },
        { id = "play_24h", name = "Regular", desc = "Play for 24 hours", category = "Social", points = 25 },
        { id = "play_100h", name = "Dedicated", desc = "Play for 100 hours", category = "Social", points = 100 },
        { id = "friend_5", name = "Social Butterfly", desc = "Add 5 friends", category = "Social", points = 15 },
        { id = "clan_join", name = "Team Player", desc = "Join a clan", category = "Social", points = 10 },

        -- Exploration achievements
        { id = "gamemode_all", name = "Explorer", desc = "Play all gamemodes", category = "Exploration", points = 50 },
        { id = "maps_50", name = "Map Collector", desc = "Play 50 different maps", category = "Exploration", points = 30 },
        { id = "stunt_100", name = "Stunt Master", desc = "Complete 100 stunts", category = "Exploration", points = 75 },

        -- Mastery achievements
        { id = "points_10k", name = "Rising Star", desc = "Earn 10,000 points", category = "Mastery", points = 50 },
        { id = "points_100k", name = "Elite", desc = "Earn 100,000 points", category = "Mastery", points = 200 },
        { id = "money_100k", name = "Wealthy", desc = "Have 100,000 coins", category = "Mastery", points = 75 },
        { id = "all_vehicles", name = "Collector", desc = "Own all vehicles", category = "Mastery", points = 500 }
    }

    for _, ach in ipairs(achievements) do
        dbExec(connection, [[
            INSERT IGNORE INTO achievements (achievement_id, name, description, category, points)
            VALUES (?, ?, ?, ?, ?)
        ]], ach.id, ach.name, ach.desc, ach.category, ach.points)
    end
end

-- Execute database query (async)
function dbQuery(query, ...)
    if not isConnected then return nil end
    return dbQuery(connection, query, ...)
end

-- Execute database statement
function dbExec(query, ...)
    if not isConnected then return false end
    return dbExec(connection, query, ...)
end

-- Poll query result (blocking)
function dbPoll(queryHandle, timeout)
    return dbPoll(queryHandle, timeout or -1)
end

-- Free query handle
function dbFree(queryHandle)
    if queryHandle then
        dbFree(queryHandle)
    end
end

-- Get connection status
function isDatabaseConnected()
    return isConnected
end

-- Close database connection
function closeDatabase()
    if connection then
        destroyElement(connection)
        connection = nil
        isConnected = false
        outputDebugString("[Jebiga] Database connection closed")
    end
end

-- Export functions
_G.dbQuery = function(query, ...)
    if not isConnected or not connection then return nil end
    return _dbQuery(connection, query, ...)
end

_G.dbExec = function(query, ...)
    if not isConnected or not connection then return false end
    return _dbExec(connection, query, ...)
end

-- Store original functions
local _dbQuery = dbQuery
local _dbExec = dbExec

-- Initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    initDatabase()
end)

-- Cleanup on resource stop
addEventHandler("onResourceStop", resourceRoot, function()
    closeDatabase()
end)
