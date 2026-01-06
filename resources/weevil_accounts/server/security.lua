--[[
    Weevil Multi-Gamemode - Security Module
    Anti-cheat and security measures
]]

local suspiciousPlayers = {}
local bannedSerials = {}
local bannedIPs = {}

-- Load banned serials/IPs from database
addEventHandler("onResourceStart", resourceRoot, function()
    loadBanList()
end)

function loadBanList()
    -- Load banned serials
    local queryHandle = dbQuery(exports.weevil_core:dbQuery, [[
        SELECT serial FROM accounts WHERE banned = 1 AND serial IS NOT NULL
    ]])

    if queryHandle then
        local result = dbPoll(queryHandle, -1)
        dbFree(queryHandle)

        if result then
            for _, row in ipairs(result) do
                if row.serial and row.serial ~= "" then
                    bannedSerials[row.serial] = true
                end
            end
        end
    end

    outputDebugString("[Weevil Security] Loaded " .. tableCount(bannedSerials) .. " banned serials")
end

function tableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Check player on join
addEventHandler("onPlayerJoin", root, function()
    local player = source
    local serial = getPlayerSerial(player)
    local ip = getPlayerIP(player)

    -- Check serial ban
    if bannedSerials[serial] then
        kickPlayer(player, "You are banned from this server.")
        return
    end

    -- Check IP ban
    if bannedIPs[ip] then
        kickPlayer(player, "Your IP is banned from this server.")
        return
    end

    -- Initialize security tracking
    suspiciousPlayers[player] = {
        warnings = 0,
        lastPosition = nil,
        lastHealth = 100,
        speedViolations = 0,
        teleportViolations = 0
    }
end)

-- Cleanup on disconnect
addEventHandler("onPlayerQuit", root, function()
    suspiciousPlayers[source] = nil
end)

-- Anti-speedhack check
local MAX_VEHICLE_SPEED = 300 -- km/h
local MAX_FOOT_SPEED = 50 -- km/h

function checkSpeed(player)
    if not Config.AntiCheat or not Config.AntiCheat.enabled or not Config.AntiCheat.checkSpeed then
        return true
    end

    if not isElement(player) then return true end

    local vehicle = getPedOccupiedVehicle(player)
    local speed

    if vehicle then
        local vx, vy, vz = getElementVelocity(vehicle)
        speed = math.sqrt(vx^2 + vy^2 + vz^2) * 180 -- Convert to km/h
    else
        local vx, vy, vz = getElementVelocity(player)
        speed = math.sqrt(vx^2 + vy^2 + vz^2) * 180
    end

    local maxSpeed = vehicle and MAX_VEHICLE_SPEED or MAX_FOOT_SPEED

    if speed > maxSpeed then
        recordViolation(player, "speed", speed)
        return false
    end

    return true
end

-- Anti-teleport check
local MAX_TELEPORT_DISTANCE = 100 -- meters per second

function checkTeleport(player)
    if not Config.AntiCheat or not Config.AntiCheat.enabled or not Config.AntiCheat.checkTeleport then
        return true
    end

    if not isElement(player) or not suspiciousPlayers[player] then return true end

    local x, y, z = getElementPosition(player)
    local lastPos = suspiciousPlayers[player].lastPosition

    if lastPos then
        local distance = getDistanceBetweenPoints3D(x, y, z, lastPos.x, lastPos.y, lastPos.z)

        -- Allow teleports in lobby dimension
        if getElementDimension(player) == 0 then
            suspiciousPlayers[player].lastPosition = { x = x, y = y, z = z }
            return true
        end

        if distance > MAX_TELEPORT_DISTANCE then
            recordViolation(player, "teleport", distance)
            suspiciousPlayers[player].lastPosition = { x = x, y = y, z = z }
            return false
        end
    end

    suspiciousPlayers[player].lastPosition = { x = x, y = y, z = z }
    return true
end

-- Anti-health hack check
function checkHealth(player)
    if not Config.AntiCheat or not Config.AntiCheat.enabled or not Config.AntiCheat.checkHealth then
        return true
    end

    if not isElement(player) or not suspiciousPlayers[player] then return true end

    local health = getElementHealth(player)
    local lastHealth = suspiciousPlayers[player].lastHealth

    -- Check if health increased without valid reason
    if health > lastHealth + 50 and health > 100 then
        recordViolation(player, "health", health)
        setElementHealth(player, 100)
        return false
    end

    suspiciousPlayers[player].lastHealth = health
    return true
end

-- Record violation
function recordViolation(player, type, value)
    if not suspiciousPlayers[player] then return end

    suspiciousPlayers[player].warnings = suspiciousPlayers[player].warnings + 1

    local warningMsg = string.format("[AntiCheat] %s - %s violation: %.2f", getPlayerName(player), type, value or 0)
    outputDebugString(warningMsg, 2)

    -- Log to admins
    for _, admin in ipairs(getElementsByType("player")) do
        if exports.weevil_core:isPlayerAdmin(admin, 1) then
            outputChatBox("#FF0000" .. warningMsg, admin, 255, 255, 255, true)
        end
    end

    -- Take action based on warnings
    local warnings = suspiciousPlayers[player].warnings

    if warnings >= 10 then
        if Config.AntiCheat.banOnDetection then
            -- Auto-ban
            local serial = getPlayerSerial(player)
            bannedSerials[serial] = true

            dbExec(exports.weevil_core:dbExec, [[
                INSERT INTO accounts (username, password, serial, banned, ban_reason)
                VALUES (?, '', ?, 1, 'Anti-cheat auto-ban')
                ON DUPLICATE KEY UPDATE banned = 1, ban_reason = 'Anti-cheat auto-ban'
            ]], getPlayerName(player), serial)

            kickPlayer(player, "Banned: Anti-cheat detection")
        else
            kickPlayer(player, "Kicked: Too many anti-cheat warnings")
        end
    elseif warnings >= 5 then
        outputChatBox("#FF0000[Warning] #FFFFFFStop cheating or you will be kicked!", player, 255, 255, 255, true)
    end
end

-- Periodic anti-cheat checks
setTimer(function()
    for player, data in pairs(suspiciousPlayers) do
        if isElement(player) then
            checkSpeed(player)
            checkTeleport(player)
            checkHealth(player)
        end
    end
end, 1000, 0)

-- Validate client-side data
addEvent("weevil:validateClientData", true)
addEventHandler("weevil:validateClientData", root, function(data)
    local player = client
    if not player or not isElement(player) then return end

    -- Validate the data sent from client
    -- This prevents modified clients from sending fake data

    if data.money and type(data.money) == "number" then
        local serverMoney = exports.weevil_core:getPlayerMoney(player)
        if data.money ~= serverMoney then
            recordViolation(player, "money_mismatch", data.money - serverMoney)
        end
    end

    if data.position then
        local x, y, z = getElementPosition(player)
        local distance = getDistanceBetweenPoints3D(data.position.x, data.position.y, data.position.z, x, y, z)
        if distance > 10 then
            recordViolation(player, "position_mismatch", distance)
        end
    end
end)

-- Prevent packet tampering
addEventHandler("onPlayerNetworkStatus", root, function(status, ticks)
    if status == 1 then -- Connection trouble
        -- Player might be trying to manipulate network
        outputDebugString("[Security] Network issues for: " .. getPlayerName(source))
    end
end)

-- Rate limiting for events
local eventRateLimits = {}
local EVENT_RATE_LIMIT = 10 -- max events per second

function checkEventRateLimit(player, eventName)
    if not eventRateLimits[player] then
        eventRateLimits[player] = {}
    end

    local now = getTickCount()
    local events = eventRateLimits[player][eventName] or {}

    -- Remove old events
    local newEvents = {}
    for _, timestamp in ipairs(events) do
        if now - timestamp < 1000 then
            table.insert(newEvents, timestamp)
        end
    end

    if #newEvents >= EVENT_RATE_LIMIT then
        recordViolation(player, "event_flood", #newEvents)
        return false
    end

    table.insert(newEvents, now)
    eventRateLimits[player][eventName] = newEvents

    return true
end

-- Secure random token generation
function generateSecureToken(length)
    length = length or 32
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local token = ""

    for i = 1, length do
        local index = math.random(1, #chars)
        token = token .. chars:sub(index, index)
    end

    return token
end

-- Session tokens for secure communication
local sessionTokens = {}

function createSessionToken(player)
    local token = generateSecureToken(64)
    sessionTokens[player] = {
        token = token,
        created = getTickCount(),
        expires = getTickCount() + 3600000 -- 1 hour
    }
    return token
end

function validateSessionToken(player, token)
    local session = sessionTokens[player]
    if not session then return false end
    if session.token ~= token then return false end
    if getTickCount() > session.expires then
        sessionTokens[player] = nil
        return false
    end
    return true
end

-- Cleanup expired sessions
setTimer(function()
    local now = getTickCount()
    for player, session in pairs(sessionTokens) do
        if not isElement(player) or now > session.expires then
            sessionTokens[player] = nil
        end
    end
end, 60000, 0)

-- Export security functions
_G.checkEventRateLimit = checkEventRateLimit
_G.generateSecureToken = generateSecureToken
_G.createSessionToken = createSessionToken
_G.validateSessionToken = validateSessionToken
