--[[
    Jebiga Multi-Gamemode - Map Manager
    Handles map loading, voting, rotation, and synchronization
    Uses centralized MySQL database from jebiga_core
]]

-- Map data
local loadedMaps = {}
local currentMap = nil
local mapQueue = {}
local mapVotes = {}
local votingActive = false
local votingTimer = nil

-- Configuration
local config = {
    voteDuration = 30,           -- Seconds for voting
    minPlayersForVote = 2,       -- Minimum players to start vote
    mapsInVote = 5,              -- Number of maps to show in vote
    mapCooldown = 3,             -- Maps before same map can be played again
    autoSkipTime = 600,          -- Auto skip map after 10 minutes (0 = disabled)
    rtv = {
        enabled = true,
        percentage = 0.6,        -- 60% of players need to /rtv
        cooldown = 120           -- Cooldown between RTV attempts
    }
}

local recentMaps = {}
local rtvVotes = {}
local lastRTV = 0

-- ============================================
-- DATABASE HELPERS
-- ============================================

function getMapFromDatabase(resourceName)
    return exports.jebiga_core:db_fetchOne(
        "SELECT * FROM maps WHERE resource_name = ?", resourceName
    )
end

function saveMapToDatabase(mapData)
    local existing = getMapFromDatabase(mapData.name)

    if existing then
        -- Update plays
        exports.jebiga_core:db_execute(
            "UPDATE maps SET plays = plays + 1 WHERE resource_name = ?",
            mapData.name
        )
        return existing.id
    else
        -- Insert new map
        exports.jebiga_core:db_execute(
            "INSERT INTO maps (resource_name, display_name, gamemode, author) VALUES (?, ?, ?, ?)",
            mapData.name,
            mapData.displayName or mapData.name,
            mapData.gamemode or "unknown",
            mapData.author or "Unknown"
        )

        local newMap = getMapFromDatabase(mapData.name)
        return newMap and newMap.id or nil
    end
end

function rateMap(player, mapName, rating)
    local accountId = getElementData(player, "jebiga:accountId")
    if not accountId then return false end

    local mapData = getMapFromDatabase(mapName)
    if not mapData then return false end

    -- Check if already rated
    local existing = exports.jebiga_core:db_fetchOne(
        "SELECT * FROM map_ratings WHERE account_id = ? AND map_id = ?",
        accountId, mapData.id
    )

    if existing then
        -- Update rating
        local oldRating = existing.rating
        exports.jebiga_core:db_execute(
            "UPDATE map_ratings SET rating = ? WHERE account_id = ? AND map_id = ?",
            rating, accountId, mapData.id
        )
        exports.jebiga_core:db_execute(
            "UPDATE maps SET rating_sum = rating_sum - ? + ? WHERE id = ?",
            oldRating, rating, mapData.id
        )
    else
        -- New rating
        exports.jebiga_core:db_execute(
            "INSERT INTO map_ratings (account_id, map_id, rating) VALUES (?, ?, ?)",
            accountId, mapData.id, rating
        )
        exports.jebiga_core:db_execute(
            "UPDATE maps SET rating_sum = rating_sum + ?, rating_count = rating_count + 1 WHERE id = ?",
            rating, mapData.id
        )
    end

    return true
end

function getMapRating(mapName)
    local mapData = getMapFromDatabase(mapName)
    if not mapData or mapData.rating_count == 0 then
        return 0, 0
    end

    local average = mapData.rating_sum / mapData.rating_count
    return average, mapData.rating_count
end

-- ============================================
-- MAP SCANNING
-- ============================================

function scanAllMaps()
    loadedMaps = {}

    local resources = getResources()
    for _, res in ipairs(resources) do
        local resName = getResourceName(res)
        local mapInfo = getMapInfo(res)

        if mapInfo then
            loadedMaps[resName] = {
                name = resName,
                displayName = mapInfo.name or resName,
                author = mapInfo.author or "Unknown",
                gamemode = mapInfo.gamemode or detectGamemode(resName),
                resource = res,
                timesPlayed = 0
            }
        end
    end

    outputDebugString("[Jebiga MapManager] Scanned " .. tableCount(loadedMaps) .. " maps")
    return loadedMaps
end

function getMapInfo(resource)
    if not resource then return nil end

    local meta = xmlLoadFile(":" .. getResourceName(resource) .. "/meta.xml")
    if not meta then return nil end

    local info = {}
    local infoNode = xmlFindChild(meta, "info", 0)

    if infoNode then
        info.name = xmlNodeGetAttribute(infoNode, "name")
        info.author = xmlNodeGetAttribute(infoNode, "author")
        info.type = xmlNodeGetAttribute(infoNode, "type")
        info.gamemode = xmlNodeGetAttribute(infoNode, "gamemodes") or xmlNodeGetAttribute(infoNode, "gamemode")
    end

    -- Check if it's a map (has map file or spawnpoints)
    local isMap = false
    local children = xmlNodeGetChildren(meta)

    for _, child in ipairs(children) do
        local nodeName = xmlNodeGetName(child)
        if nodeName == "map" then
            isMap = true
            break
        end
    end

    xmlUnloadFile(meta)

    if not isMap and info.type ~= "map" then
        return nil
    end

    return info
end

function detectGamemode(mapName)
    local name = mapName:lower()

    local prefixes = {
        dm = {"[dm]", "dm-", "[deathmatch]"},
        race = {"[race]", "race-", "[os]", "[oldschool]"},
        dd = {"[dd]", "dd-", "[derby]"},
        hunter = {"[hunter]", "hunter-"},
        shooter = {"[shooter]", "[fps]", "shooter-"},
        stuntage = {"[stunt]", "stunt-"},
        trials = {"[trials]", "trials-"},
        carball = {"[carball]", "[cb]", "carball-"},
        hotpursuit = {"[hp]", "hp-", "[pursuit]"},
        runarena = {"[run]", "[ra]", "run-"},
        training = {"[training]", "[train]"}
    }

    for gamemode, patterns in pairs(prefixes) do
        for _, pattern in ipairs(patterns) do
            if name:find(pattern, 1, true) then
                return gamemode
            end
        end
    end

    return "unknown"
end

-- ============================================
-- MAP LOADING
-- ============================================

function loadMap(mapName, gamemode)
    local mapData = loadedMaps[mapName]
    if not mapData then
        outputDebugString("[Jebiga MapManager] Map not found: " .. mapName, 2)
        return false
    end

    -- Stop current map
    if currentMap then
        stopMap(currentMap)
    end

    -- Start new map
    local success = startResource(mapData.resource)

    if success then
        currentMap = mapName
        mapData.timesPlayed = mapData.timesPlayed + 1

        -- Save to database
        saveMapToDatabase(mapData)

        -- Add to recent maps
        table.insert(recentMaps, 1, mapName)
        if #recentMaps > config.mapCooldown then
            table.remove(recentMaps)
        end

        -- Notify players
        triggerClientEvent(root, "jebiga:map:loaded", resourceRoot, mapData)

        -- Announce
        local msg = "#2980B9[MAP] #FFFFFF" .. mapData.displayName
        if mapData.author ~= "Unknown" then
            msg = msg .. " #95A5A6by " .. mapData.author
        end
        outputChatBox(msg, root, 255, 255, 255, true)

        -- Auto skip timer
        if config.autoSkipTime > 0 then
            if isTimer(votingTimer) then killTimer(votingTimer) end
            votingTimer = setTimer(function()
                startMapVote()
            end, config.autoSkipTime * 1000, 1)
        end

        outputDebugString("[Jebiga MapManager] Loaded map: " .. mapName)
        return true
    end

    return false
end

function stopMap(mapName)
    local mapData = loadedMaps[mapName]
    if mapData and mapData.resource then
        if getResourceState(mapData.resource) == "running" then
            stopResource(mapData.resource)
        end
    end
    triggerClientEvent(root, "jebiga:map:stopped", resourceRoot, mapName)
end

function nextMap()
    if #mapQueue > 0 then
        local nextMapName = table.remove(mapQueue, 1)
        loadMap(nextMapName)
    else
        startMapVote()
    end
end

-- ============================================
-- MAP VOTING
-- ============================================

function startMapVote(gamemode)
    if votingActive then return end

    votingActive = true
    mapVotes = {}

    -- Get random maps for voting
    local availableMaps = {}
    for name, data in pairs(loadedMaps) do
        local isRecent = false
        for _, recent in ipairs(recentMaps) do
            if recent == name then isRecent = true break end
        end

        if not isRecent then
            if not gamemode or data.gamemode == gamemode then
                table.insert(availableMaps, name)
            end
        end
    end

    -- Shuffle and pick
    local voteMaps = {}
    for i = 1, math.min(config.mapsInVote, #availableMaps) do
        local idx = math.random(#availableMaps)
        table.insert(voteMaps, availableMaps[idx])
        table.remove(availableMaps, idx)
    end

    if #voteMaps == 0 then
        outputChatBox("#E74C3C[MAP] #FFFFFFNo maps available for voting!", root, 255, 255, 255, true)
        votingActive = false
        return
    end

    -- Send to clients
    triggerClientEvent(root, "jebiga:map:voteStart", resourceRoot, voteMaps, config.voteDuration)

    outputChatBox("#2980B9[MAP] #FFFFFFMap vote started! Use F2 or /vote to vote.", root, 255, 255, 255, true)

    -- End voting timer
    setTimer(endMapVote, config.voteDuration * 1000, 1)
end

function endMapVote()
    if not votingActive then return end

    votingActive = false

    -- Count votes
    local voteCounts = {}
    for player, mapName in pairs(mapVotes) do
        voteCounts[mapName] = (voteCounts[mapName] or 0) + 1
    end

    -- Find winner
    local winner = nil
    local maxVotes = 0

    for mapName, votes in pairs(voteCounts) do
        if votes > maxVotes then
            maxVotes = votes
            winner = mapName
        end
    end

    -- If no votes, pick random from vote options
    if not winner then
        -- Get a random map
        local maps = {}
        for name, _ in pairs(loadedMaps) do
            table.insert(maps, name)
        end
        if #maps > 0 then
            winner = maps[math.random(#maps)]
        end
    end

    triggerClientEvent(root, "jebiga:map:voteEnd", resourceRoot, winner, maxVotes)

    if winner then
        outputChatBox("#2980B9[MAP] #FFFFFF" .. winner .. " won with " .. maxVotes .. " votes!", root, 255, 255, 255, true)
        setTimer(function()
            loadMap(winner)
        end, 3000, 1)
    end
end

-- ============================================
-- EVENTS
-- ============================================

addEvent("jebiga:map:vote", true)
addEventHandler("jebiga:map:vote", root, function(mapName)
    if not votingActive then return end
    if not loadedMaps[mapName] then return end

    mapVotes[source] = mapName

    local mapData = loadedMaps[mapName]
    outputChatBox("#2980B9[VOTE] #FFFFFF" .. getPlayerName(source) .. " voted for " .. (mapData.displayName or mapName), root, 255, 255, 255, true)
end)

addEvent("jebiga:map:request", true)
addEventHandler("jebiga:map:request", root, function(gamemode)
    local maps = {}
    for name, data in pairs(loadedMaps) do
        if not gamemode or data.gamemode == gamemode then
            table.insert(maps, {
                name = name,
                displayName = data.displayName,
                author = data.author,
                gamemode = data.gamemode
            })
        end
    end
    triggerClientEvent(source, "jebiga:map:list", resourceRoot, maps)
end)

-- ============================================
-- RTV (Rock The Vote)
-- ============================================

function handleRTV(player)
    if not config.rtv.enabled then
        outputChatBox("#E74C3C[RTV] #FFFFFFRock The Vote is disabled.", player, 255, 255, 255, true)
        return
    end

    local now = getTickCount()
    if now - lastRTV < config.rtv.cooldown * 1000 then
        local remaining = math.ceil((config.rtv.cooldown * 1000 - (now - lastRTV)) / 1000)
        outputChatBox("#E74C3C[RTV] #FFFFFFPlease wait " .. remaining .. " seconds.", player, 255, 255, 255, true)
        return
    end

    local serial = getPlayerSerial(player)

    if rtvVotes[serial] then
        outputChatBox("#E74C3C[RTV] #FFFFFFYou already voted to skip!", player, 255, 255, 255, true)
        return
    end

    rtvVotes[serial] = true

    local playerCount = #getElementsByType("player")
    local voteCount = tableCount(rtvVotes)
    local needed = math.ceil(playerCount * config.rtv.percentage)

    outputChatBox("#2980B9[RTV] #FFFFFF" .. getPlayerName(player) .. " wants to skip the map. (" .. voteCount .. "/" .. needed .. ")", root, 255, 255, 255, true)

    if voteCount >= needed then
        outputChatBox("#2980B9[RTV] #FFFFFFVote passed! Starting map vote...", root, 255, 255, 255, true)
        rtvVotes = {}
        lastRTV = now
        startMapVote()
    end
end

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("rtv", function(player)
    handleRTV(player)
end)

addCommandHandler("skip", function(player)
    if hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#2980B9[MAP] #FFFFFFAdmin skipped the map.", root, 255, 255, 255, true)
        startMapVote()
    else
        outputChatBox("#E74C3C[MAP] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
    end
end)

addCommandHandler("loadmap", function(player, cmd, mapName)
    if not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[MAP] #FFFFFFYou don't have permission!", player, 255, 255, 255, true)
        return
    end

    if not mapName then
        outputChatBox("#E74C3C[MAP] #FFFFFFUsage: /loadmap [mapname]", player, 255, 255, 255, true)
        return
    end

    if loadMap(mapName) then
        outputChatBox("#2980B9[MAP] #FFFFFFLoading " .. mapName .. "...", player, 255, 255, 255, true)
    else
        outputChatBox("#E74C3C[MAP] #FFFFFFMap not found: " .. mapName, player, 255, 255, 255, true)
    end
end)

addCommandHandler("maplist", function(player, cmd, gamemode)
    triggerEvent("jebiga:map:request", player, gamemode)
end)

addCommandHandler("ratemap", function(player, cmd, ratingStr)
    if not currentMap then
        outputChatBox("#E74C3C[MAP] #FFFFFFNo map is currently playing!", player, 255, 255, 255, true)
        return
    end

    local rating = tonumber(ratingStr)
    if not rating or rating < 1 or rating > 5 then
        outputChatBox("#E74C3C[MAP] #FFFFFFUsage: /ratemap [1-5]", player, 255, 255, 255, true)
        return
    end

    if rateMap(player, currentMap, rating) then
        local avg, count = getMapRating(currentMap)
        outputChatBox("#2980B9[MAP] #FFFFFFYou rated this map " .. rating .. "/5. Average: " .. string.format("%.1f", avg) .. " (" .. count .. " votes)", player, 255, 255, 255, true)
    else
        outputChatBox("#E74C3C[MAP] #FFFFFFCouldn't rate map. Make sure you're logged in!", player, 255, 255, 255, true)
    end
end)

addCommandHandler("mapinfo", function(player, cmd)
    if not currentMap then
        outputChatBox("#E74C3C[MAP] #FFFFFFNo map is currently playing!", player, 255, 255, 255, true)
        return
    end

    local mapData = loadedMaps[currentMap]
    local dbMap = getMapFromDatabase(currentMap)
    local avg, count = getMapRating(currentMap)

    outputChatBox("#2980B9═══════════════════════════", player, 255, 255, 255, true)
    outputChatBox("#2980B9       MAP INFORMATION       ", player, 255, 255, 255, true)
    outputChatBox("#2980B9═══════════════════════════", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF Name: #95A5A6" .. (mapData and mapData.displayName or currentMap), player, 255, 255, 255, true)
    outputChatBox("#FFFFFF Author: #95A5A6" .. (mapData and mapData.author or "Unknown"), player, 255, 255, 255, true)
    outputChatBox("#FFFFFF Gamemode: #95A5A6" .. (mapData and mapData.gamemode or "unknown"), player, 255, 255, 255, true)
    if dbMap then
        outputChatBox("#FFFFFF Times Played: #95A5A6" .. dbMap.plays, player, 255, 255, 255, true)
    end
    if count > 0 then
        outputChatBox("#FFFFFF Rating: #F1C40F" .. string.format("%.1f", avg) .. "/5 #95A5A6(" .. count .. " votes)", player, 255, 255, 255, true)
    end
end)

-- ============================================
-- UTILITY
-- ============================================

function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ============================================
-- EXPORTS
-- ============================================

function getCurrentMap()
    return currentMap, loadedMaps[currentMap]
end

function getMapList(gamemode)
    local maps = {}
    for name, data in pairs(loadedMaps) do
        if not gamemode or data.gamemode == gamemode then
            table.insert(maps, data)
        end
    end
    return maps
end

function queueMap(mapName)
    if loadedMaps[mapName] then
        table.insert(mapQueue, mapName)
        return true
    end
    return false
end

-- ============================================
-- INITIALIZATION
-- ============================================

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        scanAllMaps()
    end, 2000, 1)
end)

-- Reset RTV on map change
addEventHandler("onMapStarting", root, function()
    rtvVotes = {}
end)

-- Clean up on player quit
addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    rtvVotes[serial] = nil
    mapVotes[source] = nil
end)
