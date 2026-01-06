--[[
    Jebiga Multi-Gamemode - TopTimes System
    Server-side top times management
]]

local toptimesCache = {}

-- Helper to get account ID
local function getAccountId(player)
    return getElementData(player, "jebiga:accountId")
end

-- Get top times for a map
function getTopTimes(mapName, gamemode, limit)
    limit = limit or (Config and Config.TopTimes and Config.TopTimes.showTop) or 10

    local cacheKey = mapName .. "_" .. gamemode
    if toptimesCache[cacheKey] and toptimesCache[cacheKey].expires > getTickCount() then
        return toptimesCache[cacheKey].data
    end

    local result = exports.jebiga_core:db_fetchAll([[
        SELECT t.*, a.username
        FROM toptimes t
        JOIN accounts a ON t.account_id = a.id
        JOIN maps m ON t.map_id = m.id
        WHERE m.resource_name = ?
        ORDER BY t.time_ms ASC
        LIMIT ?
    ]], mapName, limit)

    local times = {}
    if result then
        for i, row in ipairs(result) do
            table.insert(times, {
                position = i,
                username = row.username,
                time = row.time_ms,
                vehicleId = row.vehicle_id,
                date = row.recorded_at
            })
        end
    end

    -- Cache for 30 seconds
    toptimesCache[cacheKey] = {
        data = times,
        expires = getTickCount() + 30000
    }

    return times
end

-- Get map ID from name
local function getMapId(mapName)
    local result = exports.jebiga_core:db_fetchOne([[
        SELECT id FROM maps WHERE resource_name = ?
    ]], mapName)
    return result and result.id or nil
end

-- Add or update top time
function addTopTime(player, mapName, gamemode, timeMs, vehicleId)
    if not isElement(player) then return false, "Invalid player" end

    local accountId = getAccountId(player)
    if not accountId then return false, "Not logged in" end

    local mapId = getMapId(mapName)
    if not mapId then
        -- Create map entry if not exists
        exports.jebiga_core:db_execute([[
            INSERT IGNORE INTO maps (resource_name, display_name, gamemode) VALUES (?, ?, ?)
        ]], mapName, mapName, gamemode)
        mapId = getMapId(mapName)
    end

    if not mapId then return false, "Map not found" end

    -- Check existing top time
    local existingTime = getPlayerTopTime(player, mapName, gamemode)

    if existingTime and existingTime.time <= timeMs then
        return false, "Not a new record"
    end

    -- Insert or update
    local success = exports.jebiga_core:db_execute([[
        INSERT INTO toptimes (account_id, map_id, time_ms, vehicle_id, recorded_at)
        VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            time_ms = IF(VALUES(time_ms) < time_ms, VALUES(time_ms), time_ms),
            vehicle_id = IF(VALUES(time_ms) < time_ms, VALUES(vehicle_id), vehicle_id),
            recorded_at = IF(VALUES(time_ms) < time_ms, NOW(), recorded_at)
    ]], accountId, mapId, timeMs, vehicleId)

    if success then
        -- Invalidate cache
        local cacheKey = mapName .. "_" .. gamemode
        toptimesCache[cacheKey] = nil

        -- Check if it's a new top time
        local newTimes = getTopTimes(mapName, gamemode, 10)
        local playerName = getPlayerName(player)
        local position = nil

        for i, tt in ipairs(newTimes) do
            if tt.username == playerName then
                position = i
                break
            end
        end

        if position then
            -- Broadcast new top time
            if position <= 3 then
                local posNames = { "1st", "2nd", "3rd" }
                local timeStr = formatTime(timeMs)
                outputChatBox("#FFFF00[TopTime] #00FF00" .. playerName .. " #FFFFFFset " .. posNames[position] .. " place on " .. mapName .. " with " .. timeStr .. "!", root, 255, 255, 255, true)
            end

            -- Trigger event for achievements
            triggerEvent("weevil:newTopTime", player, mapName, gamemode, position, timeMs)

            -- Notify player
            if Events and Events.TopTimes and Events.TopTimes.NEW_TOPTIME then
                triggerClientEvent(player, Events.TopTimes.NEW_TOPTIME, player, {
                    map = mapName,
                    gamemode = gamemode,
                    position = position,
                    time = timeMs,
                    isNew = existingTime == nil
                })
            end
        end

        return true, position
    end

    return false, "Database error"
end

-- Format time helper
function formatTime(ms)
    local mins = math.floor(ms / 60000)
    local secs = math.floor((ms % 60000) / 1000)
    local millis = ms % 1000
    return string.format("%02d:%02d.%03d", mins, secs, millis)
end

-- Get player's top time on a map
function getPlayerTopTime(player, mapName, gamemode)
    local accountId = getAccountId(player)
    if not accountId then return nil end

    local result = exports.jebiga_core:db_fetchOne([[
        SELECT t.time_ms, t.vehicle_id, t.recorded_at
        FROM toptimes t
        JOIN maps m ON t.map_id = m.id
        WHERE t.account_id = ? AND m.resource_name = ?
    ]], accountId, mapName)

    if result then
        return {
            time = result.time_ms,
            vehicleId = result.vehicle_id,
            date = result.recorded_at
        }
    end

    return nil
end

-- Get player's ranking on a map
function getPlayerRanking(player, mapName, gamemode)
    local accountId = getAccountId(player)
    if not accountId then return nil end

    local result = exports.jebiga_core:db_fetchOne([[
        SELECT COUNT(*) + 1 as ranking
        FROM toptimes t1
        JOIN maps m ON t1.map_id = m.id
        WHERE m.resource_name = ?
        AND t1.time_ms < (
            SELECT t2.time_ms FROM toptimes t2
            JOIN maps m2 ON t2.map_id = m2.id
            WHERE t2.account_id = ? AND m2.resource_name = ?
        )
    ]], mapName, accountId, mapName)

    if result then
        return result.ranking
    end

    return nil
end

-- Get total top times for a player
function getPlayerTopTimesCount(player)
    local accountId = getAccountId(player)
    if not accountId then return 0 end

    local result = exports.jebiga_core:db_fetchOne([[
        SELECT COUNT(*) as count FROM toptimes WHERE account_id = ?
    ]], accountId)

    if result then
        return result.count
    end

    return 0
end

-- Request handler
addEvent("jebiga:toptimes:request", true)
addEventHandler("jebiga:toptimes:request", root, function(mapName, gamemode)
    local times = getTopTimes(mapName, gamemode)
    local playerTime = getPlayerTopTime(client, mapName, gamemode)
    local playerRank = getPlayerRanking(client, mapName, gamemode)

    triggerClientEvent(client, "jebiga:toptimes:update", client, {
        map = mapName,
        gamemode = gamemode,
        times = times,
        playerTime = playerTime,
        playerRank = playerRank
    })
end)

-- Achievement check event
addEvent("weevil:newTopTime", false)
addEventHandler("weevil:newTopTime", root, function(mapName, gamemode, position, timeMs)
    local player = source
    local totalToptimes = getPlayerTopTimesCount(player)

    -- Try to unlock achievements
    local achievementsRes = getResourceFromName("jebiga_achievements")
    if achievementsRes and getResourceState(achievementsRes) == "running" then
        pcall(function()
            if totalToptimes >= 1 then
                exports.jebiga_achievements:unlockAchievement(player, "toptime_1")
            end
            if totalToptimes >= 10 then
                exports.jebiga_achievements:unlockAchievement(player, "toptime_10")
            end
            if totalToptimes >= 50 then
                exports.jebiga_achievements:unlockAchievement(player, "toptime_50")
            end
        end)
    end
end)

-- Command to view top times
addCommandHandler("toptimes", function(player, cmd, mapName)
    if not mapName then
        outputChatBox("Usage: /toptimes [mapname]", player, 255, 200, 0)
        return
    end

    local gamemode = exports.jebiga_core:getCurrentGamemode(player) or "race"
    local times = getTopTimes(mapName, gamemode, 10)

    if #times == 0 then
        outputChatBox("No top times found for this map.", player, 255, 200, 0)
        return
    end

    outputChatBox("#FFFF00=== Top Times: " .. mapName .. " ===", player, 255, 255, 255, true)

    for i, tt in ipairs(times) do
        local timeStr = formatTime(tt.time)
        outputChatBox("#FFFFFF" .. i .. ". " .. tt.username .. " - " .. timeStr, player, 255, 255, 255, true)
    end
end)

-- Export functions
_G.getTopTimes = getTopTimes
_G.addTopTime = addTopTime
_G.getPlayerTopTime = getPlayerTopTime
_G.getPlayerRanking = getPlayerRanking
_G.getPlayerTopTimesCount = getPlayerTopTimesCount
