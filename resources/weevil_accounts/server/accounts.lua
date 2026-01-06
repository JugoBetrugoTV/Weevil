--[[
    Weevil Multi-Gamemode - Account System
    Server-side account management (Register/Login)
]]

local loggedInPlayers = {}
local loginAttempts = {}
local MAX_LOGIN_ATTEMPTS = 5
local LOCKOUT_TIME = 300 -- 5 minutes

-- Initialize
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Accounts] Account system initialized")
end)

-- Register new account
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
    local checkQuery = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT id FROM accounts WHERE username = ?
    ]], username)

    if checkQuery then
        local result = dbPoll(checkQuery, -1)
        dbFree(checkQuery)

        if result and #result > 0 then
            return false, "Username already exists"
        end
    end

    -- Hash password
    local hashedPassword = hashPassword(password)
    if not hashedPassword then
        return false, "Error processing password"
    end

    -- Get player info
    local serial = getPlayerSerial(player)
    local ip = getPlayerIP(player)

    -- Insert account
    local insertQuery = dbExec(exports.weevil_core:dbExec, [[
        INSERT INTO accounts (username, password, email, serial, ip, money, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ]], username, hashedPassword, email or "", serial, ip, Config.Currency.startMoney)

    if not insertQuery then
        return false, "Database error"
    end

    outputDebugString("[Weevil Accounts] New account registered: " .. username)
    outputServerLog("[Weevil] Account registered: " .. username .. " (Serial: " .. serial .. ")")

    return true, "Account created successfully! You can now login."
end

-- Login to account
function loginAccount(player, username, password)
    if not isElement(player) then return false, "Invalid player" end

    -- Check if already logged in
    if loggedInPlayers[player] then
        return false, "Already logged in"
    end

    -- Check login attempts
    local serial = getPlayerSerial(player)
    if isLockedOut(serial) then
        local remaining = getLocoutRemaining(serial)
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
    local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT * FROM accounts WHERE username = ?
    ]], username)

    if not queryHandle then
        return false, "Database error"
    end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if not result or #result == 0 then
        recordLoginAttempt(serial, false)
        return false, "Invalid username or password"
    end

    local account = result[1]

    -- Check ban status
    if account.banned == 1 then
        local banInfo = "You are banned"
        if account.ban_reason then
            banInfo = banInfo .. ": " .. account.ban_reason
        end
        if account.ban_expires then
            local now = getRealTime().timestamp
            local banExpires = account.ban_expires
            if banExpires and banExpires > now then
                banInfo = banInfo .. " (Expires: " .. os.date("%Y-%m-%d %H:%M", banExpires) .. ")"
            elseif not banExpires or banExpires == 0 then
                banInfo = banInfo .. " (Permanent)"
            else
                -- Ban expired, remove it
                dbExec(exports.weevil_core:dbExec, [[
                    UPDATE accounts SET banned = 0, ban_reason = NULL, ban_expires = NULL WHERE id = ?
                ]], account.id)
                -- Continue with login
                account.banned = 0
            end
        end
        if account.banned == 1 then
            return false, banInfo
        end
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
    dbExec(exports.weevil_core:dbExec, [[
        UPDATE accounts SET serial = ?, ip = ?, last_login = NOW() WHERE id = ?
    ]], serial, ip, account.id)

    -- Set logged in
    loggedInPlayers[player] = {
        accountId = account.id,
        username = account.username,
        loginTime = getTickCount()
    }

    -- Update core player data
    exports.weevil_core:setPlayerData(player, "accountId", account.id)
    exports.weevil_core:setPlayerData(player, "loggedIn", true)

    -- Load player data
    loadPlayerData(player, account.id)

    -- Set player name
    setPlayerName(player, account.username)

    outputDebugString("[Weevil Accounts] Player logged in: " .. username)

    return true, "Welcome back, " .. username .. "!"
end

-- Logout from account
function logoutAccount(player)
    if not isElement(player) then return false end

    if not loggedInPlayers[player] then
        return false, "Not logged in"
    end

    -- Save data
    savePlayerData(player)

    -- Clear login state
    loggedInPlayers[player] = nil

    -- Update core
    exports.weevil_core:setPlayerData(player, "accountId", nil)
    exports.weevil_core:setPlayerData(player, "loggedIn", false)

    -- Reset player name
    setPlayerName(player, "Guest_" .. math.random(1000, 9999))

    -- Return to lobby
    exports.weevil_core:teleportToLobby(player)

    return true, "Logged out successfully"
end

-- Check if player is logged in
function isLoggedIn(player)
    return loggedInPlayers[player] ~= nil
end

-- Get account data
function getAccountData(player)
    return loggedInPlayers[player]
end

-- Set account data
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

-- Login attempt tracking
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

function getLocoutRemaining(serial)
    if not loginAttempts[serial] then return 0 end
    local elapsed = (getTickCount() - loginAttempts[serial].lastAttempt) / 1000
    return LOCKOUT_TIME - elapsed
end

-- Load player data after login
function loadPlayerData(player, accountId)
    -- Query full account data
    local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT * FROM accounts WHERE id = ?
    ]], accountId)

    if not queryHandle then return end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if not result or #result == 0 then return end

    local account = result[1]

    -- Send data to client
    triggerClientEvent(player, Events.Account.DATA_UPDATE, player, {
        accountId = account.id,
        username = account.username,
        adminLevel = account.admin_level or 0,
        vipLevel = account.vip_level or 0,
        money = account.money or 0,
        totalPoints = account.total_points or 0,
        playtime = account.playtime or 0
    })

    -- Load into player manager
    exports.weevil_core:loadPlayerData(player, accountId)
end

-- Save player data on logout/disconnect
function savePlayerData(player)
    local accountData = loggedInPlayers[player]
    if not accountData then return end

    -- Calculate session playtime
    local sessionTime = math.floor((getTickCount() - accountData.loginTime) / 1000)

    -- Update playtime
    dbExec(exports.weevil_core:dbExec, [[
        UPDATE accounts SET playtime = playtime + ? WHERE id = ?
    ]], sessionTime, accountData.accountId)

    -- Save via player manager
    exports.weevil_core:savePlayerData(player)
end

-- Event handlers
addEvent(Events.Account.REQUEST_LOGIN, true)
addEventHandler(Events.Account.REQUEST_LOGIN, root, function(username, password)
    local success, message = loginAccount(client, username, password)

    if success then
        triggerClientEvent(client, Events.Account.LOGIN_SUCCESS, client, message)
    else
        triggerClientEvent(client, Events.Account.LOGIN_FAILED, client, message)
    end
end)

addEvent(Events.Account.REQUEST_REGISTER, true)
addEventHandler(Events.Account.REQUEST_REGISTER, root, function(username, password, email)
    local success, message = registerAccount(client, username, password, email)

    if success then
        triggerClientEvent(client, Events.Account.REGISTER_SUCCESS, client, message)
    else
        triggerClientEvent(client, Events.Account.REGISTER_FAILED, client, message)
    end
end)

addEvent(Events.Account.REQUEST_LOGOUT, true)
addEventHandler(Events.Account.REQUEST_LOGOUT, root, function()
    local success, message = logoutAccount(client)

    if success then
        triggerClientEvent(client, Events.Account.LOGOUT, client, message)
    end
end)

-- Handle player disconnect
addEventHandler("onPlayerQuit", root, function()
    if loggedInPlayers[source] then
        savePlayerData(source)
        loggedInPlayers[source] = nil
    end
end)

-- Auto-login by serial (optional feature)
function autoLoginBySerial(player)
    local serial = getPlayerSerial(player)

    local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT id, username FROM accounts WHERE serial = ? AND banned = 0
    ]], serial)

    if not queryHandle then return false end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if result and #result == 1 then
        -- Found exactly one account with this serial
        local account = result[1]

        -- Set logged in
        loggedInPlayers[player] = {
            accountId = account.id,
            username = account.username,
            loginTime = getTickCount()
        }

        exports.weevil_core:setPlayerData(player, "accountId", account.id)
        exports.weevil_core:setPlayerData(player, "loggedIn", true)

        setPlayerName(player, account.username)
        loadPlayerData(player, account.id)

        outputChatBox("#00FF00[Weevil] #FFFFFFAuto-login: Welcome back, " .. account.username .. "!", player, 255, 255, 255, true)

        return true
    end

    return false
end

-- Guest mode (play without account)
function enableGuestMode(player)
    local guestName = "Guest_" .. math.random(10000, 99999)
    setPlayerName(player, guestName)

    outputChatBox("#FFFF00[Weevil] #FFFFFFPlaying as guest. Your progress won't be saved.", player, 255, 255, 255, true)
    outputChatBox("#FFFF00[Weevil] #FFFFFFUse /register to create an account.", player, 255, 255, 255, true)
end

-- Commands
addCommandHandler("register", function(player, cmd, username, password, email)
    if isLoggedIn(player) then
        outputChatBox("You are already logged in. Use /logout first.", player, 255, 0, 0)
        return
    end

    if not username or not password then
        outputChatBox("Usage: /register [username] [password] [email]", player, 255, 200, 0)
        return
    end

    local success, message = registerAccount(player, username, password, email)
    if success then
        outputChatBox("#00FF00[Weevil] #FFFFFF" .. message, player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Weevil] #FFFFFF" .. message, player, 255, 255, 255, true)
    end
end)

addCommandHandler("login", function(player, cmd, username, password)
    if isLoggedIn(player) then
        outputChatBox("You are already logged in.", player, 255, 0, 0)
        return
    end

    if not username or not password then
        outputChatBox("Usage: /login [username] [password]", player, 255, 200, 0)
        return
    end

    local success, message = loginAccount(player, username, password)
    if success then
        outputChatBox("#00FF00[Weevil] #FFFFFF" .. message, player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Weevil] #FFFFFF" .. message, player, 255, 255, 255, true)
    end
end)

addCommandHandler("logout", function(player)
    if not isLoggedIn(player) then
        outputChatBox("You are not logged in.", player, 255, 0, 0)
        return
    end

    local success, message = logoutAccount(player)
    outputChatBox("#00FF00[Weevil] #FFFFFF" .. message, player, 255, 255, 255, true)
end)

addCommandHandler("changepass", function(player, cmd, oldPass, newPass)
    if not isLoggedIn(player) then
        outputChatBox("You must be logged in to change your password.", player, 255, 0, 0)
        return
    end

    if not oldPass or not newPass then
        outputChatBox("Usage: /changepass [old password] [new password]", player, 255, 200, 0)
        return
    end

    if #newPass < 6 then
        outputChatBox("New password must be at least 6 characters.", player, 255, 0, 0)
        return
    end

    local accountData = loggedInPlayers[player]

    -- Verify old password
    local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT password FROM accounts WHERE id = ?
    ]], accountData.accountId)

    if not queryHandle then
        outputChatBox("Database error.", player, 255, 0, 0)
        return
    end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if not result or #result == 0 then
        outputChatBox("Account not found.", player, 255, 0, 0)
        return
    end

    if not verifyPassword(oldPass, result[1].password) then
        outputChatBox("Incorrect current password.", player, 255, 0, 0)
        return
    end

    -- Update password
    local newHash = hashPassword(newPass)
    dbExec(exports.weevil_core:dbExec, [[
        UPDATE accounts SET password = ? WHERE id = ?
    ]], newHash, accountData.accountId)

    outputChatBox("#00FF00[Weevil] #FFFFFFPassword changed successfully!", player, 255, 255, 255, true)
end)

-- Export functions
exports.weevil_accounts = exports.weevil_accounts or {}
exports.weevil_accounts.isLoggedIn = isLoggedIn
exports.weevil_accounts.getAccountData = getAccountData
exports.weevil_accounts.setAccountData = setAccountData
