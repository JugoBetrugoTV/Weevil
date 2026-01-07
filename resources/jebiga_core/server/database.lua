--[[
    Jebiga Multi-Gamemode - Database Module
    MySQL database connection and query handling
    All tables are auto-created on startup
]]

local connection = nil
local isConnected = false

-- Store original MTA functions
local mtaDbConnect = dbConnect
local mtaDbQuery = dbQuery
local mtaDbExec = dbExec
local mtaDbPoll = dbPoll
local mtaDbFree = dbFree

-- Initialize database connection
function initDatabase()
    local cfg = Config.Database

    outputServerLog("[Jebiga] Connecting to MySQL database...")
    outputServerLog("[Jebiga] Host: " .. cfg.host .. ":" .. cfg.port)
    outputServerLog("[Jebiga] Database: " .. cfg.database)

    local connectionString = string.format(
        "dbname=%s;host=%s;port=%d;%s",
        cfg.database,
        cfg.host,
        cfg.port,
        cfg.options
    )

    connection = mtaDbConnect("mysql", connectionString, cfg.username, cfg.password)

    if connection then
        isConnected = true
        outputServerLog("[Jebiga] Database connected successfully!")
        outputDebugString("[Jebiga] Database connected successfully")
        createAllTables()
        return true
    else
        isConnected = false
        outputServerLog("[Jebiga] ERROR: Database connection failed!")
        outputServerLog("[Jebiga] Check your database credentials in config.lua")
        outputDebugString("[Jebiga] Database connection failed!", 1)
        return false
    end
end

-- Create all required database tables
function createAllTables()
    if not isConnected then return end

    outputServerLog("[Jebiga] Creating/verifying database tables...")

    -- =============================================
    -- CORE TABLES
    -- =============================================

    -- Accounts table (main player data)
    execSync([[
        CREATE TABLE IF NOT EXISTS accounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            email VARCHAR(100),
            serial VARCHAR(50) NOT NULL,
            ip VARCHAR(45),
            admin_level INT DEFAULT 0,
            vip_level INT DEFAULT 0,
            vip_expires DATETIME,
            money BIGINT DEFAULT 5000,
            points BIGINT DEFAULT 0,
            total_points BIGINT DEFAULT 0,
            playtime INT DEFAULT 0,
            skin INT DEFAULT 0,
            last_login DATETIME,
            last_daily DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            banned TINYINT DEFAULT 0,
            ban_reason VARCHAR(255),
            ban_expires DATETIME,
            ban_admin VARCHAR(50),
            muted TINYINT DEFAULT 0,
            mute_expires DATETIME,
            settings TEXT,
            INDEX idx_serial (serial),
            INDEX idx_username (username)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Player statistics per gamemode
    execSync([[
        CREATE TABLE IF NOT EXISTS player_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            gamemode VARCHAR(20) NOT NULL,
            points INT DEFAULT 0,
            wins INT DEFAULT 0,
            losses INT DEFAULT 0,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            races_started INT DEFAULT 0,
            races_finished INT DEFAULT 0,
            best_position INT DEFAULT 0,
            playtime INT DEFAULT 0,
            last_played DATETIME,
            UNIQUE KEY unique_player_gamemode (account_id, gamemode),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- TOPTIMES & MAPS
    -- =============================================

    -- Maps registry
    execSync([[
        CREATE TABLE IF NOT EXISTS maps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            resource_name VARCHAR(100) NOT NULL,
            display_name VARCHAR(100),
            gamemode VARCHAR(20) NOT NULL,
            author VARCHAR(50),
            difficulty INT DEFAULT 1,
            plays INT DEFAULT 0,
            rating_sum INT DEFAULT 0,
            rating_count INT DEFAULT 0,
            added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_map (resource_name),
            INDEX idx_gamemode (gamemode)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- TopTimes
    execSync([[
        CREATE TABLE IF NOT EXISTS toptimes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            map_id INT NOT NULL,
            time_ms INT NOT NULL,
            checkpoints INT DEFAULT 0,
            vehicle_id INT,
            recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_toptime (account_id, map_id),
            INDEX idx_map_time (map_id, time_ms),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- CLANS
    -- =============================================

    -- Clans
    execSync([[
        CREATE TABLE IF NOT EXISTS clans (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            tag VARCHAR(10) NOT NULL,
            owner_id INT NOT NULL,
            description TEXT,
            color_r INT DEFAULT 46,
            color_g INT DEFAULT 204,
            color_b INT DEFAULT 113,
            logo VARCHAR(100),
            money BIGINT DEFAULT 0,
            level INT DEFAULT 1,
            wins INT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_tag (tag),
            FOREIGN KEY (owner_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Clan members
    execSync([[
        CREATE TABLE IF NOT EXISTS clan_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            clan_id INT NOT NULL,
            account_id INT NOT NULL,
            rank ENUM('member', 'officer', 'leader') DEFAULT 'member',
            contribution INT DEFAULT 0,
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_clan_member (account_id),
            FOREIGN KEY (clan_id) REFERENCES clans(id) ON DELETE CASCADE,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Clan invites
    execSync([[
        CREATE TABLE IF NOT EXISTS clan_invites (
            id INT AUTO_INCREMENT PRIMARY KEY,
            clan_id INT NOT NULL,
            account_id INT NOT NULL,
            invited_by INT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME,
            UNIQUE KEY unique_invite (clan_id, account_id),
            FOREIGN KEY (clan_id) REFERENCES clans(id) ON DELETE CASCADE,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- ACHIEVEMENTS
    -- =============================================

    -- Achievement definitions
    execSync([[
        CREATE TABLE IF NOT EXISTS achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            achievement_id VARCHAR(50) UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            category VARCHAR(50),
            points INT DEFAULT 10,
            reward_money INT DEFAULT 0,
            icon VARCHAR(50),
            secret TINYINT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Player unlocked achievements
    execSync([[
        CREATE TABLE IF NOT EXISTS player_achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            achievement_id VARCHAR(50) NOT NULL,
            progress INT DEFAULT 0,
            unlocked TINYINT DEFAULT 0,
            unlocked_at DATETIME,
            UNIQUE KEY unique_player_achievement (account_id, achievement_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- GARAGE & VEHICLES
    -- =============================================

    -- Player owned vehicles
    execSync([[
        CREATE TABLE IF NOT EXISTS player_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            vehicle_model INT NOT NULL,
            color1_r INT DEFAULT 255,
            color1_g INT DEFAULT 255,
            color1_b INT DEFAULT 255,
            color2_r INT DEFAULT 255,
            color2_g INT DEFAULT 255,
            color2_b INT DEFAULT 255,
            paintjob INT DEFAULT 0,
            upgrades TEXT,
            neon_r INT,
            neon_g INT,
            neon_b INT,
            plate VARCHAR(8),
            favorite TINYINT DEFAULT 0,
            purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_player_vehicle (account_id, vehicle_model),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- SOCIAL
    -- =============================================

    -- Friends
    execSync([[
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

    -- Private messages history
    execSync([[
        CREATE TABLE IF NOT EXISTS private_messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sender_id INT NOT NULL,
            receiver_id INT NOT NULL,
            message TEXT NOT NULL,
            read_at DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_receiver (receiver_id, created_at),
            FOREIGN KEY (sender_id) REFERENCES accounts(id) ON DELETE CASCADE,
            FOREIGN KEY (receiver_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- VIP & TRANSACTIONS
    -- =============================================

    -- VIP purchases/history
    execSync([[
        CREATE TABLE IF NOT EXISTS vip_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            vip_level INT NOT NULL,
            duration_days INT NOT NULL,
            price INT DEFAULT 0,
            purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Transaction log (money)
    execSync([[
        CREATE TABLE IF NOT EXISTS transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            type ENUM('earn', 'spend', 'transfer_in', 'transfer_out', 'admin', 'bonus') NOT NULL,
            amount BIGINT NOT NULL,
            reason VARCHAR(255),
            balance_after BIGINT,
            related_id INT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_account_transactions (account_id, created_at),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- ADMIN & LOGS
    -- =============================================

    -- Admin actions log
    execSync([[
        CREATE TABLE IF NOT EXISTS admin_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_id INT NOT NULL,
            action VARCHAR(50) NOT NULL,
            target_id INT,
            target_name VARCHAR(50),
            details TEXT,
            ip VARCHAR(45),
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_admin_actions (admin_id, created_at),
            INDEX idx_action_type (action, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Chat log (optional, for moderation)
    execSync([[
        CREATE TABLE IF NOT EXISTS chat_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            channel VARCHAR(20) DEFAULT 'global',
            message TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_account_chat (account_id, created_at),
            INDEX idx_channel (channel, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- PLAYER SETTINGS
    -- =============================================

    -- Player settings (separate table for easy querying)
    execSync([[
        CREATE TABLE IF NOT EXISTS player_settings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL UNIQUE,
            hud TINYINT DEFAULT 1,
            speedometer TINYINT DEFAULT 1,
            nametags TINYINT DEFAULT 1,
            nametag_health TINYINT DEFAULT 1,
            radar TINYINT DEFAULT 1,
            kill_messages TINYINT DEFAULT 1,
            sounds TINYINT DEFAULT 1,
            music TINYINT DEFAULT 1,
            music_volume INT DEFAULT 50,
            sound_volume INT DEFAULT 80,
            auto_respawn TINYINT DEFAULT 0,
            show_fps TINYINT DEFAULT 1,
            show_ping TINYINT DEFAULT 1,
            chat_timestamps TINYINT DEFAULT 0,
            chat_filter TINYINT DEFAULT 1,
            pm_notifications TINYINT DEFAULT 1,
            shaders TINYINT DEFAULT 1,
            particles TINYINT DEFAULT 1,
            neon_lights TINYINT DEFAULT 1,
            show_online_status TINYINT DEFAULT 1,
            allow_pm TINYINT DEFAULT 1,
            show_location TINYINT DEFAULT 1,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- =============================================
    -- MAP RATINGS & VOTES
    -- =============================================

    -- Map ratings
    execSync([[
        CREATE TABLE IF NOT EXISTS map_ratings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            map_id INT NOT NULL,
            rating INT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_rating (account_id, map_id),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Insert default achievements
    insertDefaultAchievements()

    outputServerLog("[Jebiga] All database tables created/verified successfully!")
    outputDebugString("[Jebiga] Database tables ready")
end

-- Insert default achievements
function insertDefaultAchievements()
    local achievements = {
        -- Racing
        { id = "first_win", name = "First Victory", desc = "Win your first race", cat = "Racing", pts = 10, money = 100 },
        { id = "win_10", name = "Getting Good", desc = "Win 10 races", cat = "Racing", pts = 25, money = 500 },
        { id = "win_50", name = "Racer", desc = "Win 50 races", cat = "Racing", pts = 50, money = 1000 },
        { id = "win_100", name = "Veteran", desc = "Win 100 races", cat = "Racing", pts = 100, money = 2500 },
        { id = "win_500", name = "Racing Legend", desc = "Win 500 races", cat = "Racing", pts = 250, money = 10000 },
        { id = "toptime_1", name = "Record Setter", desc = "Set your first top time", cat = "Racing", pts = 15, money = 200 },
        { id = "toptime_10", name = "Time Attack", desc = "Hold 10 top times", cat = "Racing", pts = 50, money = 1000 },
        { id = "toptime_50", name = "Time Master", desc = "Hold 50 top times", cat = "Racing", pts = 150, money = 5000 },

        -- Combat
        { id = "first_kill", name = "First Blood", desc = "Get your first kill", cat = "Combat", pts = 10, money = 50 },
        { id = "kill_100", name = "Warrior", desc = "Get 100 kills", cat = "Combat", pts = 50, money = 500 },
        { id = "kill_500", name = "Slayer", desc = "Get 500 kills", cat = "Combat", pts = 100, money = 1500 },
        { id = "kill_1000", name = "Terminator", desc = "Get 1000 kills", cat = "Combat", pts = 200, money = 5000 },
        { id = "streak_5", name = "Killing Spree", desc = "Get a 5 kill streak", cat = "Combat", pts = 25, money = 250 },
        { id = "streak_10", name = "Unstoppable", desc = "Get a 10 kill streak", cat = "Combat", pts = 75, money = 1000 },
        { id = "dd_win_10", name = "Demolition Expert", desc = "Win 10 DD matches", cat = "Combat", pts = 50, money = 750 },
        { id = "hunter_win_10", name = "Sky Hunter", desc = "Win 10 Hunter matches", cat = "Combat", pts = 50, money = 750 },

        -- Social
        { id = "play_1h", name = "Newcomer", desc = "Play for 1 hour", cat = "Social", pts = 5, money = 100 },
        { id = "play_10h", name = "Regular", desc = "Play for 10 hours", cat = "Social", pts = 25, money = 500 },
        { id = "play_50h", name = "Dedicated", desc = "Play for 50 hours", cat = "Social", pts = 75, money = 2000 },
        { id = "play_100h", name = "No-Lifer", desc = "Play for 100 hours", cat = "Social", pts = 150, money = 5000 },
        { id = "friend_1", name = "Friendly", desc = "Add your first friend", cat = "Social", pts = 5, money = 50 },
        { id = "friend_10", name = "Popular", desc = "Have 10 friends", cat = "Social", pts = 25, money = 250 },
        { id = "clan_join", name = "Team Player", desc = "Join a clan", cat = "Social", pts = 15, money = 200 },
        { id = "clan_create", name = "Leader", desc = "Create a clan", cat = "Social", pts = 50, money = 0 },

        -- Wealth
        { id = "money_10k", name = "Saver", desc = "Have 10,000 coins", cat = "Wealth", pts = 10, money = 0 },
        { id = "money_100k", name = "Wealthy", desc = "Have 100,000 coins", cat = "Wealth", pts = 50, money = 0 },
        { id = "money_1m", name = "Millionaire", desc = "Have 1,000,000 coins", cat = "Wealth", pts = 200, money = 0 },
        { id = "spend_100k", name = "Big Spender", desc = "Spend 100,000 coins total", cat = "Wealth", pts = 50, money = 1000 },

        -- Mastery
        { id = "all_gamemodes", name = "Explorer", desc = "Play all gamemodes", cat = "Mastery", pts = 50, money = 1000 },
        { id = "maps_50", name = "Traveler", desc = "Play 50 different maps", cat = "Mastery", pts = 30, money = 500 },
        { id = "maps_200", name = "Adventurer", desc = "Play 200 different maps", cat = "Mastery", pts = 100, money = 2500 },
        { id = "vip", name = "Supporter", desc = "Become a VIP", cat = "Mastery", pts = 100, money = 0 }
    }

    for _, ach in ipairs(achievements) do
        execSync([[
            INSERT IGNORE INTO achievements (achievement_id, name, description, category, points, reward_money)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], ach.id, ach.name, ach.desc, ach.cat, ach.pts, ach.money)
    end
end

-- =============================================
-- DATABASE HELPER FUNCTIONS
-- =============================================

-- Execute query synchronously (for table creation)
function execSync(query, ...)
    if not connection then return false end
    local handle = mtaDbQuery(connection, query, ...)
    if handle then
        local result = mtaDbPoll(handle, -1)
        mtaDbFree(handle)
        return result
    end
    return false
end

-- Execute query asynchronously
function queryAsync(callback, query, ...)
    if not connection then
        if callback then callback(false) end
        return
    end
    local args = {...}
    local handle = mtaDbQuery(function(handle)
        local result = mtaDbPoll(handle, 0)
        mtaDbFree(handle)
        if callback then callback(result) end
    end, connection, query, unpack(args))
end

-- Execute statement (INSERT, UPDATE, DELETE)
function execute(query, ...)
    if not connection then return false end
    return mtaDbExec(connection, query, ...)
end

-- Get single row
function fetchOne(query, ...)
    local result = execSync(query, ...)
    if result and #result > 0 then
        return result[1]
    end
    return nil
end

-- Get all rows
function fetchAll(query, ...)
    return execSync(query, ...) or {}
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

-- =============================================
-- EXPORTED FUNCTIONS (for other resources)
-- =============================================

function db_query(query, ...)
    return execSync(query, ...)
end

function db_execute(query, ...)
    return execute(query, ...)
end

function db_queryAsync(callback, query, ...)
    return queryAsync(callback, query, ...)
end

function db_fetchOne(query, ...)
    return fetchOne(query, ...)
end

function db_fetchAll(query, ...)
    return fetchAll(query, ...)
end

function db_isConnected()
    return isConnected
end

-- =============================================
-- PLAYER DATA HELPERS
-- =============================================

-- Get account by serial
function getAccountBySerial(serial)
    return fetchOne("SELECT * FROM accounts WHERE serial = ?", serial)
end

-- Get account by username
function getAccountByUsername(username)
    return fetchOne("SELECT * FROM accounts WHERE username = ?", username)
end

-- Get account by ID
function getAccountById(id)
    return fetchOne("SELECT * FROM accounts WHERE id = ?", id)
end

-- Save player data
function savePlayerData(accountId, data)
    local sets = {}
    local values = {}

    for key, value in pairs(data) do
        table.insert(sets, key .. " = ?")
        table.insert(values, value)
    end

    table.insert(values, accountId)

    local query = "UPDATE accounts SET " .. table.concat(sets, ", ") .. " WHERE id = ?"
    return execute(query, unpack(values))
end

-- Get player stats
function getPlayerStats(accountId, gamemode)
    if gamemode then
        return fetchOne("SELECT * FROM player_stats WHERE account_id = ? AND gamemode = ?", accountId, gamemode)
    else
        return fetchAll("SELECT * FROM player_stats WHERE account_id = ?", accountId)
    end
end

-- Whitelisted column names for stats updates (prevents SQL injection)
local allowedStatsColumns = {
    points = true,
    wins = true,
    losses = true,
    kills = true,
    deaths = true,
    races_finished = true,
    best_position = true,
    playtime = true,
    races_won = true,
    races_played = true,
    checkpoints_hit = true
}

-- Update player stats
function updatePlayerStats(accountId, gamemode, stats)
    -- First try to insert, if exists update
    local existing = getPlayerStats(accountId, gamemode)

    if existing then
        local sets = {}
        local values = {}

        for key, value in pairs(stats) do
            -- SECURITY: Only allow whitelisted column names
            if allowedStatsColumns[key] then
                table.insert(sets, key .. " = " .. key .. " + ?")
                table.insert(values, value)
            else
                outputDebugString("[Jebiga] WARNING: Rejected invalid stats column: " .. tostring(key), 2)
            end
        end

        if #sets == 0 then
            return false -- No valid columns to update
        end

        table.insert(values, accountId)
        table.insert(values, gamemode)

        return execute("UPDATE player_stats SET " .. table.concat(sets, ", ") .. " WHERE account_id = ? AND gamemode = ?", unpack(values))
    else
        -- Create new entry
        local keys = {"account_id", "gamemode"}
        local placeholders = {"?", "?"}
        local values = {accountId, gamemode}

        for key, value in pairs(stats) do
            -- SECURITY: Only allow whitelisted column names
            if allowedStatsColumns[key] then
                table.insert(keys, key)
                table.insert(placeholders, "?")
                table.insert(values, value)
            end
        end

        return execute("INSERT INTO player_stats (" .. table.concat(keys, ", ") .. ") VALUES (" .. table.concat(placeholders, ", ") .. ")", unpack(values))
    end
end

-- Get player settings
function getPlayerSettings(accountId)
    local settings = fetchOne("SELECT * FROM player_settings WHERE account_id = ?", accountId)
    if not settings then
        -- Create default settings
        execute("INSERT INTO player_settings (account_id) VALUES (?)", accountId)
        settings = fetchOne("SELECT * FROM player_settings WHERE account_id = ?", accountId)
    end
    return settings
end

-- Save player settings
function savePlayerSettings(accountId, settings)
    local sets = {}
    local values = {}

    for key, value in pairs(settings) do
        if key ~= "id" and key ~= "account_id" then
            table.insert(sets, key .. " = ?")
            table.insert(values, value)
        end
    end

    table.insert(values, accountId)

    return execute("UPDATE player_settings SET " .. table.concat(sets, ", ") .. " WHERE account_id = ?", unpack(values))
end

-- =============================================
-- INITIALIZATION
-- =============================================

-- Initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    initDatabase()
end)

-- Cleanup on resource stop
addEventHandler("onResourceStop", resourceRoot, function()
    closeDatabase()
end)

-- =============================================
-- GLOBAL EXPORTS
-- =============================================

_G.initDatabase = initDatabase
_G.closeDatabase = closeDatabase
_G.isConnected = function() return isConnected end
_G.execute = execute
_G.execSync = execSync
_G.fetchOne = fetchOne
_G.fetchAll = fetchAll
_G.getAccountById = getAccountById
_G.getAccountBySerial = getAccountBySerial
_G.getAccountByUsername = getAccountByUsername
_G.createAccount = createAccount
_G.updateAccount = updateAccount
_G.getPlayerStats = getPlayerStats
_G.updatePlayerStats = updatePlayerStats
_G.getPlayerSettings = getPlayerSettings
_G.savePlayerSettings = savePlayerSettings
