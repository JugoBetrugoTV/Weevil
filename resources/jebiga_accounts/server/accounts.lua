--[[
    Jebiga Multi-Gamemode - Account System
    Server-side account management (Register/Login)
    Uses centralized MySQL database from jebiga_core
]]

local loggedInPlayers = {}
local loginAttempts = {}
local MAX_LOGIN_ATTEMPTS = 5
local LOCKOUT_TIME = 300 -- 5 minutes

-- ============================================
-- DATABASE HELPER FUNCTIONS
-- ============================================

local function dbQuery(query, ...)
    return exports.jebiga_core:db_fetchAll(query, ...)
end

local function dbFetchOne(query, ...)
    return exports.jebiga_core:db_fetchOne(query, ...)
end

local function dbExecute(query, ...)
    return exports.jebiga_core:db_execute(query, ...)
end

-- ============================================
-- INITIALIZATION
-- ============================================

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Accounts] Account system initialized")
end)

-- ============================================
-- REGISTRATION
-- ============================================

function registerAccount(player, username, password, email)
    if not isElement(player) then return false, "Invalid player" end

    -- Validate username
    if not username or #username < 3 or #username > 20 then
        return false, "Username must be 3-20 characters"
    end

    if not username:match("^[%w_]+$") then
        return false, "Username can only contain letters, numbers, and underscores"
    end

    -- Validate password
    if not password or #password < 6 then
        return false, "Password must be at least 6 characters"
    end

    -- Validate email (optional)
    if email and email ~= "" and not email:match("^[%w.+-]+@[%w.-]+%.%w+$") then
        return false, "Invalid email format"
    end

    -- Check if username exists
    local existing = dbFetchOne([[
        SELECT id FROM accounts WHERE username = ?
    ]], username)

    if existing then
        return false, "Username already exists"
    end

    -- Check if serial already has account
    local serial = getPlayerSerial(player)
    local serialCheck = dbFetchOne([[
        SELECT id, username FROM accounts WHERE serial = ?
    ]], serial)

    if serialCheck then
        return false, "You already have an account: " .. serialCheck.username
    end

    -- Hash password
    local hashedPassword = hashPassword(password)
    if not hashedPassword then
        return false, "Error processing password"
    end

    -- Get player info
    local ip = getPlayerIP(player)
    local startMoney = Config and Config.Currency and Config.Currency.startMoney or 5000

    -- Insert account
    local success = dbExecute([[
        INSERT INTO accounts (username, password, email, serial, ip, money, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ]], username, hashedPassword, email or "", serial, ip, startMoney)

    if not success then
        return false, "Database error - please try again"
    end

    outputDebugString("[Jebiga Accounts] New account registered: " .. username)
    outputServerLog("[Jebiga] Account registered: " .. username .. " (Serial: " .. serial .. ")")

    return true, "Account created successfully! You can now login."
end

-- ============================================
-- LOGIN
-- ============================================

function loginAccount(player, username, password)
    if not isElement(player) then return false, "Invalid player" end

    -- Check if already logged in
    if loggedInPlayers[player] then
        return false, "Already logged in"
    end

    -- Check login attempts
    local serial = getPlayerSerial(player)
    if isLockedOut(serial) then
        local remaining = getLockoutRemaining(serial)
        return false, "Too many login attempts. Try again in " .. math.ceil(remaining / 60) .. " minutes"
    end

    -- Validate input
    if not username or username == "" then
        return false, "Please enter a username"
    end

    if not password or password == "" then
        return false, "Please enter a password"
    end

    -- Query account
    local account = dbFetchOne([[
        SELECT * FROM accounts WHERE username = ?
    ]], username)

    if not account then
        recordLoginAttempt(serial, false)
        return false, "Invalid username or password"
    end

    -- Check ban status
    if account.banned == 1 then
        local banInfo = "You are banned"
        if account.ban_reason then
            banInfo = banInfo .. ": " .. account.ban_reason
        end
        if account.ban_expires then
            local now = getRealTime().timestamp
            -- Check if ban expired
            if account.ban_expires ~= 0 then
                -- Has expiry time
                banInfo = banInfo .. " (Expires: " .. tostring(account.ban_expires) .. ")"
            else
                banInfo = banInfo .. " (Permanent)"
            end
        end
        return false, banInfo
    end

    -- Verify password
    if not verifyPassword(password, account.password) then
        recordLoginAttempt(serial, false)
        local attempts = getLoginAttempts(serial)
        local remaining = MAX_LOGIN_ATTEMPTS - attempts
        return false, "Invalid username or password (" .. remaining .. " attempts remaining)"
    end

    -- Successful login
    recordLoginAttempt(serial, true)

    -- Update account info
    local ip = getPlayerIP(player)
    dbExecute([[
        UPDATE accounts SET serial = ?, ip = ?, last_login = NOW() WHERE id = ?
    ]], serial, ip, account.id)

    -- Set logged in
    loggedInPlayers[player] = {
        accountId = account.id,
        username = account.username,
        loginTime = getTickCount()
    }

    -- Set element data
    setElementData(player, "jebiga:accountId", account.id)
    setElementData(player, "jebiga:loggedIn", true)
    setElementData(player, "jebiga:username", account.username)

    -- Load player data via core
    local coreRes = getResourceFromName("jebiga_core")
    if coreRes and getResourceState(coreRes) == "running" then
        exports.jebiga_core:loadPlayerData(player, account.id)
    end

    -- Set player name
    setPlayerName(player, account.username)

    -- Send success to client
    triggerClientEvent(player, "jebiga:account:loginSuccess", player, {
        accountId = account.id,
        username = account.username,
        adminLevel = account.admin_level or 0,
        vipLevel = account.vip_level or 0,
        money = account.money or 0,
        totalPoints = account.total_points or 0
    })

    -- Trigger the core event that player is now logged in
    -- This will show the lobby panel (player still not spawned)
    triggerEvent("jebiga:onPlayerLoggedIn", player, account.id)

    outputDebugString("[Jebiga Accounts] Player logged in: " .. username)

    return true, "Welcome back, " .. username .. "!"
end

-- ============================================
-- LOGOUT
-- ============================================

function logoutAccount(player)
    if not isElement(player) then return false end

    if not loggedInPlayers[player] then
        return false, "Not logged in"
    end

    -- Save data
    savePlayerData(player)

    -- Clear login state
    loggedInPlayers[player] = nil

    -- Clear element data
    setElementData(player, "jebiga:accountId", nil)
    setElementData(player, "jebiga:loggedIn", false)
    setElementData(player, "jebiga:username", nil)

    -- Reset player name
    setPlayerName(player, "Guest_" .. math.random(1000, 9999))

    -- Trigger client event
    triggerClientEvent(player, "jebiga:account:logout", player)

    return true, "Logged out successfully"
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function isLoggedIn(player)
    return loggedInPlayers[player] ~= nil
end

function getAccountData(player)
    return loggedInPlayers[player]
end

function setAccountData(player, key, value)
    if loggedInPlayers[player] then
        loggedInPlayers[player][key] = value
        return true
    end
    return false
end

-- Hash password using SHA256 with salt
function hashPassword(password)
    local salt = md5(tostring(getTickCount()) .. tostring(math.random(100000, 999999)))
    local hash = sha256(salt .. password)
    return salt .. ":" .. hash
end

-- Verify password
function verifyPassword(password, storedHash)
    if not storedHash then return false end

    local parts = split(storedHash, ":")
    if #parts ~= 2 then
        -- Legacy MD5 hash
        return md5(password) == storedHash
    end

    local salt = parts[1]
    local hash = parts[2]
    return sha256(salt .. password) == hash
end

-- Split string helper
function split(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- ============================================
-- LOGIN ATTEMPT TRACKING
-- ============================================

function recordLoginAttempt(serial, success)
    if success then
        loginAttempts[serial] = nil
    else
        if not loginAttempts[serial] then
            loginAttempts[serial] = { attempts = 0, lastAttempt = 0 }
        end
        loginAttempts[serial].attempts = loginAttempts[serial].attempts + 1
        loginAttempts[serial].lastAttempt = getTickCount()
    end
end

function getLoginAttempts(serial)
    if not loginAttempts[serial] then return 0 end
    return loginAttempts[serial].attempts
end

function isLockedOut(serial)
    if not loginAttempts[serial] then return false end
    if loginAttempts[serial].attempts < MAX_LOGIN_ATTEMPTS then return false end

    local elapsed = (getTickCount() - loginAttempts[serial].lastAttempt) / 1000
    if elapsed >= LOCKOUT_TIME then
        loginAttempts[serial] = nil
        return false
    end

    return true
end

function getLockoutRemaining(serial)
    if not loginAttempts[serial] then return 0 end
    local elapsed = (getTickCount() - loginAttempts[serial].lastAttempt) / 1000
    return math.max(0, LOCKOUT_TIME - elapsed)
end

-- ============================================
-- PLAYER DATA
-- ============================================

function loadPlayerData(player, accountId)
    local account = dbFetchOne([[
        SELECT * FROM accounts WHERE id = ?
    ]], accountId)

    if not account then return end

    -- Send data to client
    triggerClientEvent(player, "jebiga:account:dataUpdate", player, {
        accountId = account.id,
        username = account.username,
        adminLevel = account.admin_level or 0,
        vipLevel = account.vip_level or 0,
        money = account.money or 0,
        totalPoints = account.total_points or 0,
        playtime = account.playtime or 0
    })
end

function savePlayerData(player)
    local accountData = loggedInPlayers[player]
    if not accountData then return end

    -- Calculate session playtime
    local sessionTime = math.floor((getTickCount() - accountData.loginTime) / 1000)

    -- Update playtime
    dbExecute([[
        UPDATE accounts SET playtime = playtime + ? WHERE id = ?
    ]], sessionTime, accountData.accountId)

    -- Save via player manager if available
    local coreRes = getResourceFromName("jebiga_core")
    if coreRes and getResourceState(coreRes) == "running" then
        pcall(function()
            exports.jebiga_core:savePlayerData(player)
        end)
    end
end

-- ============================================
-- AUTO-LOGIN
-- ============================================

function autoLoginBySerial(player)
    local serial = getPlayerSerial(player)

    local account = dbFetchOne([[
        SELECT id, username FROM accounts WHERE serial = ? AND banned = 0
    ]], serial)

    if account then
        -- Set logged in
        loggedInPlayers[player] = {
            accountId = account.id,
            username = account.username,
            loginTime = getTickCount()
        }

        setElementData(player, "jebiga:accountId", account.id)
        setElementData(player, "jebiga:loggedIn", true)
        setElementData(player, "jebiga:username", account.username)

        setPlayerName(player, account.username)

        -- Load player data
        local coreRes = getResourceFromName("jebiga_core")
        if coreRes and getResourceState(coreRes) == "running" then
            exports.jebiga_core:loadPlayerData(player, account.id)
        end

        -- Trigger the core event that player is now logged in
        triggerEvent("jebiga:onPlayerLoggedIn", player, account.id)

        outputChatBox("#00FF00[Jebiga] #FFFFFFAuto-login: Welcome back, " .. account.username .. "!", player, 255, 255, 255, true)

        return true
    end

    return false
end

function enableGuestMode(player)
    local guestName = "Guest_" .. math.random(10000, 99999)
    setPlayerName(player, guestName)
    setElementData(player, "jebiga:loggedIn", true) -- Treat guest as "logged in" for lobby access
    setElementData(player, "jebiga:isGuest", true)

    -- Trigger the core event so they can access the lobby
    -- Account ID is nil for guests
    triggerEvent("jebiga:onPlayerLoggedIn", player, nil)

    outputChatBox("#FFFF00[Jebiga] #FFFFFFPlaying as guest. Your progress won't be saved.", player, 255, 255, 255, true)
    outputChatBox("#FFFF00[Jebiga] #FFFFFFUse /register to create an account.", player, 255, 255, 255, true)
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

addEvent("jebiga:account:requestLogin", true)
addEventHandler("jebiga:account:requestLogin", root, function(username, password)
    local success, message = loginAccount(client, username, password)

    if success then
        triggerClientEvent(client, "jebiga:account:loginSuccess", client, message)
    else
        triggerClientEvent(client, "jebiga:account:loginFailed", client, message)
    end
end)

addEvent("jebiga:account:requestRegister", true)
addEventHandler("jebiga:account:requestRegister", root, function(username, password, email)
    local success, message = registerAccount(client, username, password, email)

    if success then
        triggerClientEvent(client, "jebiga:account:registerSuccess", client, message)
    else
        triggerClientEvent(client, "jebiga:account:registerFailed", client, message)
    end
end)

addEvent("jebiga:account:requestLogout", true)
addEventHandler("jebiga:account:requestLogout", root, function()
    local success, message = logoutAccount(client)

    if success then
        triggerClientEvent(client, "jebiga:account:logout", client, message)
    end
end)

addEvent("jebiga:account:requestGuestLogin", true)
addEventHandler("jebiga:account:requestGuestLogin", root, function()
    -- Enable guest mode - this will trigger the lobby
    enableGuestMode(client)
    triggerClientEvent(client, "jebiga:account:loginSuccess", client, "Playing as Guest")
end)

-- Handle player disconnect
addEventHandler("onPlayerQuit", root, function()
    if loggedInPlayers[source] then
        savePlayerData(source)
        loggedInPlayers[source] = nil
    end
    loginAttempts[getPlayerSerial(source)] = nil
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("register", function(player, cmd, username, password, email)
    if isLoggedIn(player) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFYou are already logged in. Use /logout first.", player, 255, 255, 255, true)
        return
    end

    if not username or not password then
        outputChatBox("#FFFF00[Jebiga] #FFFFFFUsage: /register [username] [password] [email]", player, 255, 255, 255, true)
        return
    end

    local success, message = registerAccount(player, username, password, email)
    if success then
        outputChatBox("#00FF00[Jebiga] #FFFFFF" .. message, player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Jebiga] #FFFFFF" .. message, player, 255, 255, 255, true)
    end
end)

addCommandHandler("login", function(player, cmd, username, password)
    if isLoggedIn(player) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFYou are already logged in.", player, 255, 255, 255, true)
        return
    end

    if not username or not password then
        outputChatBox("#FFFF00[Jebiga] #FFFFFFUsage: /login [username] [password]", player, 255, 255, 255, true)
        return
    end

    local success, message = loginAccount(player, username, password)
    if success then
        outputChatBox("#00FF00[Jebiga] #FFFFFF" .. message, player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Jebiga] #FFFFFF" .. message, player, 255, 255, 255, true)
    end
end)

addCommandHandler("logout", function(player)
    if not isLoggedIn(player) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFYou are not logged in.", player, 255, 255, 255, true)
        return
    end

    local success, message = logoutAccount(player)
    outputChatBox("#00FF00[Jebiga] #FFFFFF" .. message, player, 255, 255, 255, true)
end)

addCommandHandler("changepass", function(player, cmd, oldPass, newPass)
    if not isLoggedIn(player) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFYou must be logged in to change your password.", player, 255, 255, 255, true)
        return
    end

    if not oldPass or not newPass then
        outputChatBox("#FFFF00[Jebiga] #FFFFFFUsage: /changepass [old password] [new password]", player, 255, 255, 255, true)
        return
    end

    if #newPass < 6 then
        outputChatBox("#FF0000[Jebiga] #FFFFFFNew password must be at least 6 characters.", player, 255, 255, 255, true)
        return
    end

    local accountData = loggedInPlayers[player]

    -- Verify old password
    local account = dbFetchOne([[
        SELECT password FROM accounts WHERE id = ?
    ]], accountData.accountId)

    if not account then
        outputChatBox("#FF0000[Jebiga] #FFFFFFAccount not found.", player, 255, 255, 255, true)
        return
    end

    if not verifyPassword(oldPass, account.password) then
        outputChatBox("#FF0000[Jebiga] #FFFFFFIncorrect current password.", player, 255, 255, 255, true)
        return
    end

    -- Update password
    local newHash = hashPassword(newPass)
    dbExecute([[
        UPDATE accounts SET password = ? WHERE id = ?
    ]], newHash, accountData.accountId)

    outputChatBox("#00FF00[Jebiga] #FFFFFFPassword changed successfully!", player, 255, 255, 255, true)
end)

-- ============================================
-- EXPORTS
-- ============================================

_G.isLoggedIn = isLoggedIn
_G.getAccountData = getAccountData
_G.setAccountData = setAccountData
_G.autoLoginBySerial = autoLoginBySerial
_G.enableGuestMode = enableGuestMode
