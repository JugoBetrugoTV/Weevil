--[[
    Jebiga Multi-Gamemode - TopTimes System
    Server-side top times management
]]

local toptimesCache = {}

-- Get top times for a map
function getTopTimes(mapName, gamemode, limit)
    limit = limit or Config.TopTimes.showTop

    local cacheKey = mapName .. "_" .. gamemode
    if toptimesCache[cacheKey] and toptimesCache[cacheKey].expires > getTickCount() then
        return toptimesCache[cacheKey].data
    end

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT t.*, a.username
        FROM toptimes t
        JOIN accounts a ON t.account_id = a.id
        WHERE t.map_name = ? AND t.gamemode = ?
        ORDER BY t.time_ms ASC
        LIMIT ?
    ]], mapName, gamemode, limit)

    if not queryHandle then return {} end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

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

-- Add or update top time
function addTopTime(player, mapName, gamemode, timeMs, vehicleId)
    if not isElement(player) then return false, "Invalid player" end

    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return false, "Not logged in" end

    -- Check existing top time
    local existingTime = getPlayerTopTime(player, mapName, gamemode)

    if existingTime and existingTime.time <= timeMs then
        return false, "Not a new record"
    end

    -- Insert or update
    local success = dbExec(exports.jebiga_core:dbExec, [[
        INSERT INTO toptimes (account_id, map_name, gamemode, time_ms, vehicle_id, recorded_at)
        VALUES (?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            time_ms = IF(? < time_ms, ?, time_ms),
            vehicle_id = IF(? < time_ms, ?, vehicle_id),
            recorded_at = IF(? < time_ms, NOW(), recorded_at)
    ]], accountId, mapName, gamemode, timeMs, vehicleId,
        timeMs, timeMs, timeMs, vehicleId, timeMs)

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
                exports.jebiga_core:broadcastToGamemode(gamemode,
                    "#FFFF00[TopTime] #00FF00" .. playerName .. " #FFFFFFset " .. posNames[position] .. " place on " .. mapName .. " with " .. Utils.formatTime(timeMs) .. "!"
                )
            end

            -- Trigger event for achievements
            triggerEvent("weevil:newTopTime", player, mapName, gamemode, position, timeMs)

            -- Notify player
            triggerClientEvent(player, Events.TopTimes.NEW_TOPTIME, player, {
                map = mapName,
                gamemode = gamemode,
                position = position,
                time = timeMs,
                isNew = existingTime == nil
            })
        end

        return true, position
    end

    return false, "Database error"
end

-- Get player's top time on a map
function getPlayerTopTime(player, mapName, gamemode)
    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return nil end

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT time_ms, vehicle_id, recorded_at
        FROM toptimes
        WHERE account_id = ? AND map_name = ? AND gamemode = ?
    ]], accountId, mapName, gamemode)

    if not queryHandle then return nil end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if result and #result > 0 then
        return {
            time = result[1].time_ms,
            vehicleId = result[1].vehicle_id,
            date = result[1].recorded_at
        }
    end

    return nil
end

-- Get player's ranking on a map
function getPlayerRanking(player, mapName, gamemode)
    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return nil end

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT COUNT(*) + 1 as ranking
        FROM toptimes t1
        WHERE t1.map_name = ? AND t1.gamemode = ?
        AND t1.time_ms < (
            SELECT time_ms FROM toptimes t2
            WHERE t2.account_id = ? AND t2.map_name = ? AND t2.gamemode = ?
        )
    ]], mapName, gamemode, accountId, mapName, gamemode)

    if not queryHandle then return nil end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if result and #result > 0 then
        return result[1].ranking
    end

    return nil
end

-- Get total top times for a player
function getPlayerTopTimesCount(player)
    local accountId = exports.jebiga_core:getPlayerAccountId(player)
    if not accountId then return 0 end

    local queryHandle = dbQuery(exports.jebiga_core:dbQuery, [[
        SELECT COUNT(*) as count FROM toptimes WHERE account_id = ?
    ]], accountId)

    if not queryHandle then return 0 end

    local result = dbPoll(queryHandle, -1)
    dbFree(queryHandle)

    if result and #result > 0 then
        return result[1].count
    end

    return 0
end

-- Request handler
addEvent(Events.TopTimes.REQUEST_TOPTIMES, true)
addEventHandler(Events.TopTimes.REQUEST_TOPTIMES, root, function(mapName, gamemode)
    local times = getTopTimes(mapName, gamemode)
    local playerTime = getPlayerTopTime(client, mapName, gamemode)
    local playerRank = getPlayerRanking(client, mapName, gamemode)

    triggerClientEvent(client, Events.TopTimes.UPDATE_LIST, client, {
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

    -- Check top time achievements
    local totalToptimes = getPlayerTopTimesCount(player)

    if totalToptimes >= 1 then
        exports.jebiga_achievements:unlockAchievement(player, "toptime_1")
    end
    if totalToptimes >= 10 then
        exports.jebiga_achievements:unlockAchievement(player, "toptime_10")
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
        local timeStr = Utils.formatTime(tt.time)
        outputChatBox("#FFFFFF" .. i .. ". " .. tt.username .. " - " .. timeStr, player, 255, 255, 255, true)
    end
end)

-- Export functions
exports.jebiga_toptimes = exports.jebiga_toptimes or {}
exports.jebiga_toptimes.getTopTimes = getTopTimes
exports.jebiga_toptimes.addTopTime = addTopTime
exports.jebiga_toptimes.getPlayerTopTime = getPlayerTopTime
