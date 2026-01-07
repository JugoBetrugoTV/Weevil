--[[
    Jebiga Multi-Gamemode - Core Map Loader
    Parses .map files and creates all game elements
    Handles checkpoints, spawnpoints, objects, vehicles
]]

-- Current map state
local currentMapResource = nil
local currentMapName = nil
local mapElements = {}
local mapSettings = {}
local spawnPoints = {}
local checkpoints = {}
local finishLine = nil

-- Player checkpoint tracking
local playerCheckpoints = {}
local playerLaps = {}
local playerStartTimes = {}
local playerFinished = {}

-- ============================================
-- MAP LOADING
-- ============================================

function loadMapResource(mapResourceName, dimension)
    dimension = dimension or 0

    -- Stop current map first
    if currentMapResource then
        unloadCurrentMap()
    end

    -- Find the resource
    local mapRes = getResourceFromName(mapResourceName)
    if not mapRes then
        outputDebugString("[MapLoader] Resource not found: " .. mapResourceName, 2)
        return false
    end

    -- MTA 1.6 FIX: Force restart the resource to ensure scripts (like music.lua) run fresh
    -- This is critical for maps with their own client scripts
    if getResourceState(mapRes) == "running" then
        stopResource(mapRes)
    end

    local started = startResource(mapRes)
    if not started then
        outputDebugString("[MapLoader] Failed to start resource: " .. mapResourceName, 2)
        return false
    end

    currentMapResource = mapRes
    currentMapName = mapResourceName

    -- Parse the map file
    local success = parseMapFile(mapRes, dimension)

    if success then
        -- Detect music files in the map resource (for maps without their own music.lua)
        local musicFile = detectMapMusicFile(mapRes)
        if musicFile then
            mapSettings.musicFile = musicFile
            mapSettings.musicResource = mapResourceName
            outputDebugString("[MapLoader] Detected music file: " .. musicFile)
        end

        outputDebugString("[MapLoader] Loaded map: " .. mapResourceName .. " (" .. #spawnPoints .. " spawns, " .. #checkpoints .. " checkpoints)")

        -- Notify clients
        local mapData = {
            name = currentMapName,
            checkpoints = checkpoints,
            spawnCount = #spawnPoints,
            settings = mapSettings
        }
        triggerClientEvent(root, "jebiga:maploader:mapLoaded", resourceRoot, mapData)

        -- Trigger event for other resources
        triggerEvent("jebiga:maploader:onMapLoaded", resourceRoot, mapResourceName, mapSettings)

        return true
    end

    return false
end

-- ============================================
-- MUSIC FILE DETECTION (MTA 1.6)
-- ============================================

-- Detect music files in map resource
function detectMapMusicFile(mapRes)
    local resName = getResourceName(mapRes)
    local meta = xmlLoadFile(":" .. resName .. "/meta.xml")

    if not meta then return nil end

    local musicFile = nil
    local hasOwnMusicScript = false
    local children = xmlNodeGetChildren(meta)

    for _, child in ipairs(children) do
        local nodeName = xmlNodeGetName(child)

        -- Check for script nodes that handle music
        if nodeName == "script" then
            local src = xmlNodeGetAttribute(child, "src")
            local scriptType = xmlNodeGetAttribute(child, "type")
            if src and scriptType == "client" then
                local lower = src:lower()
                if lower:find("music") or lower:find("sound") or lower:find("audio") then
                    -- Map has its own music script - let it handle music
                    hasOwnMusicScript = true
                    outputDebugString("[MapLoader] Map has own music script: " .. src)
                end
            end
        end

        -- Check for file nodes with music extensions
        if nodeName == "file" then
            local src = xmlNodeGetAttribute(child, "src")
            if src then
                local lower = src:lower()
                if lower:find("%.mp3$") or lower:find("%.ogg$") or lower:find("%.wav$") then
                    -- Found a music file
                    musicFile = src
                end
            end
        end
    end

    xmlUnloadFile(meta)

    -- If map has its own music script, don't override with our system
    if hasOwnMusicScript then
        return nil
    end

    -- Return music file path for maps that don't have their own music script
    if musicFile then
        return ":" .. resName .. "/" .. musicFile
    end

    return nil
end

function parseMapFile(mapRes, dimension)
    local resName = getResourceName(mapRes)
    local mapFilePath = ":" .. resName .. "/" .. resName .. ".map"

    -- Try common map file names
    local mapFileNames = {
        resName .. ".map",
        "map.map",
        resName:gsub("%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1") .. ".map"
    }

    local mapXML = nil
    for _, fileName in ipairs(mapFileNames) do
        mapXML = xmlLoadFile(":" .. resName .. "/" .. fileName)
        if mapXML then break end
    end

    -- Also try to find any .map file
    if not mapXML then
        local meta = xmlLoadFile(":" .. resName .. "/meta.xml")
        if meta then
            local children = xmlNodeGetChildren(meta)
            for _, child in ipairs(children) do
                if xmlNodeGetName(child) == "map" then
                    local src = xmlNodeGetAttribute(child, "src")
                    if src then
                        mapXML = xmlLoadFile(":" .. resName .. "/" .. src)
                        if mapXML then break end
                    end
                end
            end
            xmlUnloadFile(meta)
        end
    end

    if not mapXML then
        outputDebugString("[MapLoader] No .map file found in: " .. resName, 2)
        return false
    end

    -- Reset map data
    mapElements = {}
    spawnPoints = {}
    checkpoints = {}
    finishLine = nil
    mapSettings = {
        laps = 1,
        respawn = "timelimit",
        respawnTime = 5000,
        duration = 600000,
        ghostmode = false
    }

    -- Parse all nodes
    local children = xmlNodeGetChildren(mapXML)
    for _, node in ipairs(children) do
        local nodeName = xmlNodeGetName(node)

        if nodeName == "spawnpoint" then
            parseSpawnpoint(node, dimension)
        elseif nodeName == "checkpoint" then
            parseCheckpoint(node, dimension)
        elseif nodeName == "object" then
            parseObject(node, dimension)
        elseif nodeName == "vehicle" then
            parseVehicle(node, dimension)
        elseif nodeName == "marker" then
            parseMarker(node, dimension)
        elseif nodeName == "pickup" then
            parsePickup(node, dimension)
        elseif nodeName == "settings" or nodeName == "meta" then
            parseSettings(node)
        elseif nodeName == "racepickup" then
            parseRacePickup(node, dimension)
        end
    end

    xmlUnloadFile(mapXML)

    -- Sort checkpoints by order
    table.sort(checkpoints, function(a, b) return (a.order or 0) < (b.order or 0) end)

    -- Mark last checkpoint as finish if not already set
    if #checkpoints > 0 and not finishLine then
        checkpoints[#checkpoints].isFinish = true
        finishLine = checkpoints[#checkpoints]
    end

    return true
end

-- ============================================
-- ELEMENT PARSERS
-- ============================================

function parseSpawnpoint(node, dimension)
    local spawn = {
        x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0,
        y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0,
        z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0,
        rotX = tonumber(xmlNodeGetAttribute(node, "rotX")) or 0,
        rotY = tonumber(xmlNodeGetAttribute(node, "rotY")) or 0,
        rotZ = tonumber(xmlNodeGetAttribute(node, "rotZ")) or tonumber(xmlNodeGetAttribute(node, "rot")) or 0,
        vehicle = tonumber(xmlNodeGetAttribute(node, "vehicle")) or tonumber(xmlNodeGetAttribute(node, "model")) or 411,
        skin = tonumber(xmlNodeGetAttribute(node, "skin")) or 0
    }

    table.insert(spawnPoints, spawn)
end

function parseCheckpoint(node, dimension)
    local cp = {
        x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0,
        y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0,
        z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0,
        size = tonumber(xmlNodeGetAttribute(node, "size")) or 10,
        order = tonumber(xmlNodeGetAttribute(node, "order")) or tonumber(xmlNodeGetAttribute(node, "id")) or #checkpoints + 1,
        type = xmlNodeGetAttribute(node, "type") or "checkpoint",
        vehicle = tonumber(xmlNodeGetAttribute(node, "vehicle")),
        color = xmlNodeGetAttribute(node, "color"),
        isFinish = xmlNodeGetAttribute(node, "type") == "finish" or xmlNodeGetAttribute(node, "finish") == "true"
    }

    -- Parse next checkpoint reference
    local nextAttr = xmlNodeGetAttribute(node, "nextid") or xmlNodeGetAttribute(node, "next")
    if nextAttr then
        cp.nextCheckpoint = tonumber(nextAttr)
    end

    -- Create the checkpoint marker
    local markerType = cp.isFinish and "cylinder" or "checkpoint"
    local r, g, b, a = 255, 0, 0, 100

    if cp.color then
        local colors = split(cp.color, ",")
        if #colors >= 3 then
            r, g, b = tonumber(colors[1]) or 255, tonumber(colors[2]) or 0, tonumber(colors[3]) or 0
            a = tonumber(colors[4]) or 100
        end
    elseif cp.isFinish then
        r, g, b = 255, 255, 0
    end

    local marker = createMarker(cp.x, cp.y, cp.z, markerType, cp.size, r, g, b, a)
    if marker then
        setElementDimension(marker, dimension)
        setElementData(marker, "jebiga:checkpointIndex", cp.order)
        setElementData(marker, "jebiga:isFinish", cp.isFinish)
        table.insert(mapElements, marker)
        cp.marker = marker

        -- Initially hide all checkpoints except first
        if cp.order > 1 then
            setElementAlpha(marker, 0)
            setElementCollisionsEnabled(marker, false)
        end
    end

    -- Create corona effect for visibility
    local corona = createMarker(cp.x, cp.y, cp.z + cp.size, "corona", 2, r, g, b, 100)
    if corona then
        setElementDimension(corona, dimension)
        table.insert(mapElements, corona)

        if cp.order > 1 then
            setElementAlpha(corona, 0)
        end
    end

    table.insert(checkpoints, cp)

    if cp.isFinish then
        finishLine = cp
    end
end

function parseObject(node, dimension)
    local model = tonumber(xmlNodeGetAttribute(node, "model")) or tonumber(xmlNodeGetAttribute(node, "id")) or 1337
    local x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0
    local y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0
    local z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0
    local rx = tonumber(xmlNodeGetAttribute(node, "rotX")) or 0
    local ry = tonumber(xmlNodeGetAttribute(node, "rotY")) or 0
    local rz = tonumber(xmlNodeGetAttribute(node, "rotZ")) or 0

    local obj = createObject(model, x, y, z, rx, ry, rz)
    if obj then
        setElementDimension(obj, dimension)

        -- Check for doublesided
        local doubleSided = xmlNodeGetAttribute(node, "doublesided")
        if doubleSided == "true" then
            setElementDoubleSided(obj, true)
        end

        -- Check for alpha
        local alpha = tonumber(xmlNodeGetAttribute(node, "alpha"))
        if alpha then
            setElementAlpha(obj, alpha)
        end

        -- Check for scale
        local scale = tonumber(xmlNodeGetAttribute(node, "scale"))
        if scale then
            setObjectScale(obj, scale)
        end

        -- Check for collision
        local collision = xmlNodeGetAttribute(node, "collisions")
        if collision == "false" then
            setElementCollisionsEnabled(obj, false)
        end

        -- Check for interior
        local interior = tonumber(xmlNodeGetAttribute(node, "interior"))
        if interior then
            setElementInterior(obj, interior)
        end

        table.insert(mapElements, obj)
    end
end

function parseVehicle(node, dimension)
    local model = tonumber(xmlNodeGetAttribute(node, "model")) or 411
    local x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0
    local y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0
    local z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0
    local rx = tonumber(xmlNodeGetAttribute(node, "rotX")) or 0
    local ry = tonumber(xmlNodeGetAttribute(node, "rotY")) or 0
    local rz = tonumber(xmlNodeGetAttribute(node, "rotZ")) or 0

    local veh = createVehicle(model, x, y, z, rx, ry, rz)
    if veh then
        setElementDimension(veh, dimension)

        -- Check for color
        local color1 = tonumber(xmlNodeGetAttribute(node, "color1"))
        local color2 = tonumber(xmlNodeGetAttribute(node, "color2"))
        if color1 then
            setVehicleColor(veh, color1, color2 or color1, color1, color1)
        end

        -- Check for paintjob
        local paintjob = tonumber(xmlNodeGetAttribute(node, "paintjob"))
        if paintjob then
            setVehiclePaintjob(veh, paintjob)
        end

        table.insert(mapElements, veh)
    end
end

function parseMarker(node, dimension)
    local x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0
    local y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0
    local z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0
    local markerType = xmlNodeGetAttribute(node, "type") or "cylinder"
    local size = tonumber(xmlNodeGetAttribute(node, "size")) or 2
    local r = tonumber(xmlNodeGetAttribute(node, "r")) or 255
    local g = tonumber(xmlNodeGetAttribute(node, "g")) or 0
    local b = tonumber(xmlNodeGetAttribute(node, "b")) or 0
    local a = tonumber(xmlNodeGetAttribute(node, "a")) or 200

    local marker = createMarker(x, y, z, markerType, size, r, g, b, a)
    if marker then
        setElementDimension(marker, dimension)
        table.insert(mapElements, marker)
    end
end

function parsePickup(node, dimension)
    local x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0
    local y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0
    local z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0
    local pickupType = tonumber(xmlNodeGetAttribute(node, "type")) or 2
    local amount = tonumber(xmlNodeGetAttribute(node, "amount")) or 100
    local respawn = tonumber(xmlNodeGetAttribute(node, "respawn")) or 30000

    local pickup = createPickup(x, y, z, pickupType, amount, respawn)
    if pickup then
        setElementDimension(pickup, dimension)
        table.insert(mapElements, pickup)
    end
end

function parseRacePickup(node, dimension)
    local x = tonumber(xmlNodeGetAttribute(node, "posX")) or tonumber(xmlNodeGetAttribute(node, "x")) or 0
    local y = tonumber(xmlNodeGetAttribute(node, "posY")) or tonumber(xmlNodeGetAttribute(node, "y")) or 0
    local z = tonumber(xmlNodeGetAttribute(node, "posZ")) or tonumber(xmlNodeGetAttribute(node, "z")) or 0
    local pickupType = xmlNodeGetAttribute(node, "type") or "nitro"
    local respawn = tonumber(xmlNodeGetAttribute(node, "respawn")) or 30000
    local targetVehicle = tonumber(xmlNodeGetAttribute(node, "vehicle")) or tonumber(xmlNodeGetAttribute(node, "model"))

    -- Create marker for race pickup
    local r, g, b = 0, 255, 255
    if pickupType == "nitro" then
        r, g, b = 0, 255, 0
    elseif pickupType == "repair" then
        r, g, b = 255, 255, 0
    elseif pickupType == "vehiclechange" then
        r, g, b = 255, 0, 255
    end

    local marker = createMarker(x, y, z, "corona", 3, r, g, b, 200)
    if marker then
        setElementDimension(marker, dimension)
        setElementData(marker, "jebiga:racePickupType", pickupType)
        setElementData(marker, "jebiga:respawnTime", respawn)
        if targetVehicle then
            setElementData(marker, "jebiga:targetVehicle", targetVehicle)
        end
        table.insert(mapElements, marker)
    end
end

function parseSettings(node)
    local children = xmlNodeGetChildren(node)
    for _, child in ipairs(children) do
        local name = xmlNodeGetAttribute(child, "name")
        local value = xmlNodeGetAttribute(child, "value")

        if name and value then
            if name == "time" then
                mapSettings.duration = tonumber(value) or 600000
            elseif name == "respawn" then
                mapSettings.respawn = value
            elseif name == "respawntime" then
                mapSettings.respawnTime = tonumber(value) or 5000
            elseif name == "ghostmode" then
                mapSettings.ghostmode = value == "true"
            elseif name == "laps" then
                mapSettings.laps = tonumber(value) or 1
            -- Music settings support
            elseif name == "music" or name == "snd" or name == "sound" then
                mapSettings.music = value
            elseif name == "musicurl" or name == "soundtrack" then
                mapSettings.musicUrl = value
            elseif name == "musicvolume" or name == "sndvolume" then
                mapSettings.musicVolume = tonumber(value) or 0.5
            end
        end
    end
end

-- ============================================
-- MAP UNLOADING
-- ============================================

function unloadCurrentMap()
    -- Destroy all map elements
    for _, element in ipairs(mapElements) do
        if isElement(element) then
            destroyElement(element)
        end
    end

    -- Stop the resource
    if currentMapResource and getResourceState(currentMapResource) == "running" then
        stopResource(currentMapResource)
    end

    -- Reset state
    mapElements = {}
    spawnPoints = {}
    checkpoints = {}
    finishLine = nil
    currentMapResource = nil
    currentMapName = nil

    -- Reset player tracking
    playerCheckpoints = {}
    playerLaps = {}
    playerStartTimes = {}
    playerFinished = {}

    -- Notify clients
    triggerClientEvent(root, "jebiga:maploader:mapUnloaded", resourceRoot)
    triggerEvent("jebiga:maploader:onMapUnloaded", resourceRoot)

    outputDebugString("[MapLoader] Map unloaded")
end

-- ============================================
-- CHECKPOINT HANDLING
-- ============================================

function initPlayerCheckpoints(player)
    playerCheckpoints[player] = 1
    playerLaps[player] = 1
    playerStartTimes[player] = getTickCount()
    playerFinished[player] = false

    -- Show first checkpoint
    updatePlayerCheckpoint(player, 1)
end

function updatePlayerCheckpoint(player, index)
    if not checkpoints[index] then return end

    -- Send to client for HUD
    triggerClientEvent(player, "jebiga:maploader:updateCheckpoint", resourceRoot, {
        current = index,
        total = #checkpoints,
        lap = playerLaps[player],
        totalLaps = mapSettings.laps,
        checkpoint = checkpoints[index]
    })
end

-- Handle checkpoint hit
addEventHandler("onMarkerHit", root, function(hitElement, matchingDimension)
    if not matchingDimension then return end
    if getElementType(hitElement) ~= "player" then
        -- Check if in vehicle
        local vehicle = getPedOccupiedVehicle(hitElement)
        if not vehicle then return end
        hitElement = getVehicleOccupant(vehicle)
        if not hitElement then return end
    end

    local cpIndex = getElementData(source, "jebiga:checkpointIndex")
    if not cpIndex then return end

    local player = hitElement
    local currentCP = playerCheckpoints[player] or 1

    -- Check if this is the expected checkpoint
    if cpIndex ~= currentCP then return end

    local isFinish = getElementData(source, "jebiga:isFinish")
    local cp = checkpoints[cpIndex]

    -- Play sound
    triggerClientEvent(player, "jebiga:maploader:checkpointHit", resourceRoot, cpIndex, isFinish)

    if isFinish then
        -- Check lap
        if playerLaps[player] >= mapSettings.laps then
            -- Player finished!
            handlePlayerFinish(player)
        else
            -- Next lap
            playerLaps[player] = playerLaps[player] + 1
            playerCheckpoints[player] = 1

            outputChatBox("#2980B9[RACE] #FFFFFFLap " .. playerLaps[player] .. "/" .. mapSettings.laps, player, 255, 255, 255, true)

            updatePlayerCheckpoint(player, 1)

            -- Reset checkpoint visibility for new lap
            for i, checkpoint in ipairs(checkpoints) do
                if checkpoint.marker then
                    if i == 1 then
                        setElementAlpha(checkpoint.marker, 200)
                        setElementCollisionsEnabled(checkpoint.marker, true)
                    else
                        setElementAlpha(checkpoint.marker, 0)
                        setElementCollisionsEnabled(checkpoint.marker, false)
                    end
                end
            end
        end
    else
        -- Next checkpoint
        playerCheckpoints[player] = cpIndex + 1

        -- Hide current, show next
        if cp.marker then
            setElementAlpha(cp.marker, 50)
            setElementCollisionsEnabled(cp.marker, false)
        end

        local nextCP = checkpoints[cpIndex + 1]
        if nextCP and nextCP.marker then
            setElementAlpha(nextCP.marker, 200)
            setElementCollisionsEnabled(nextCP.marker, true)
        end

        updatePlayerCheckpoint(player, cpIndex + 1)
    end
end)

function handlePlayerFinish(player)
    if playerFinished[player] then return end

    playerFinished[player] = true

    local finishTime = getTickCount() - (playerStartTimes[player] or getTickCount())

    -- Format time
    local mins = math.floor(finishTime / 60000)
    local secs = math.floor((finishTime % 60000) / 1000)
    local ms = finishTime % 1000
    local timeStr = string.format("%02d:%02d.%03d", mins, secs, ms)

    -- Count position
    local position = 1
    for p, finished in pairs(playerFinished) do
        if finished and p ~= player then
            position = position + 1
        end
    end

    outputChatBox("#00FF00[RACE] #FFFFFF" .. getPlayerName(player) .. " finished #" .. position .. " in " .. timeStr, root, 255, 255, 255, true)

    -- Trigger finish event
    triggerEvent("jebiga:maploader:playerFinished", player, position, finishTime)
    triggerClientEvent(player, "jebiga:maploader:finished", resourceRoot, position, finishTime)

    -- Award points
    if exports.jebiga_core then
        local points = math.max(10, 100 - (position - 1) * 10)
        local money = math.max(25, 250 - (position - 1) * 25)
        pcall(function()
            exports.jebiga_core:addPlayerPoints(player, points)
            exports.jebiga_core:addPlayerMoney(player, money)
        end)
    end
end

-- ============================================
-- RACE PICKUP HANDLING
-- ============================================

addEventHandler("onMarkerHit", root, function(hitElement, matchingDimension)
    if not matchingDimension then return end

    local pickupType = getElementData(source, "jebiga:racePickupType")
    if not pickupType then return end

    local player = hitElement
    if getElementType(hitElement) ~= "player" then
        local vehicle = getPedOccupiedVehicle(hitElement)
        if not vehicle then return end
        player = getVehicleOccupant(vehicle)
    end

    if not player then return end

    local vehicle = getPedOccupiedVehicle(player)

    if pickupType == "nitro" and vehicle then
        addVehicleUpgrade(vehicle, 1010) -- Nitro
        triggerClientEvent(player, "jebiga:maploader:pickupCollected", resourceRoot, "nitro")
    elseif pickupType == "repair" and vehicle then
        fixVehicle(vehicle)
        setElementHealth(vehicle, 1000)
        triggerClientEvent(player, "jebiga:maploader:pickupCollected", resourceRoot, "repair")
    elseif pickupType == "vehiclechange" then
        -- Get target vehicle model from marker data
        local targetVehicle = getElementData(source, "jebiga:targetVehicle")
        if targetVehicle and vehicle then
            local x, y, z = getElementPosition(vehicle)
            local rx, ry, rz = getElementRotation(vehicle)
            local vx, vy, vz = getElementVelocity(vehicle)

            -- Destroy old vehicle
            destroyElement(vehicle)

            -- Create new vehicle
            local newVehicle = createVehicle(targetVehicle, x, y, z, rx, ry, rz)
            if newVehicle then
                warpPedIntoVehicle(player, newVehicle)
                setElementVelocity(newVehicle, vx, vy, vz)
                setElementDimension(newVehicle, getElementDimension(player))
                table.insert(mapElements, newVehicle)
                setElementData(player, "jebiga:spawnVehicle", newVehicle)
                triggerClientEvent(player, "jebiga:maploader:pickupCollected", resourceRoot, "vehiclechange")
            end
        end
    end

    -- Temporarily hide pickup
    local respawnTime = getElementData(source, "jebiga:respawnTime") or 30000
    local marker = source
    setElementAlpha(marker, 0)
    setElementCollisionsEnabled(marker, false)

    setTimer(function()
        if isElement(marker) then
            setElementAlpha(marker, 200)
            setElementCollisionsEnabled(marker, true)
        end
    end, respawnTime, 1)
end)

-- ============================================
-- SPAWNING
-- ============================================

function spawnPlayerAtMap(player, spawnIndex)
    if #spawnPoints == 0 then
        outputDebugString("[MapLoader] No spawn points available", 2)
        return false
    end

    spawnIndex = spawnIndex or ((#getElementsByType("player") % #spawnPoints) + 1)
    local spawn = spawnPoints[spawnIndex] or spawnPoints[1]

    if spawn.vehicle and spawn.vehicle > 0 then
        -- Spawn in vehicle
        spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2, spawn.rotZ, spawn.skin or 0)
        local vehicle = createVehicle(spawn.vehicle, spawn.x, spawn.y, spawn.z, spawn.rotX, spawn.rotY, spawn.rotZ)
        if vehicle then
            warpPedIntoVehicle(player, vehicle)
            setElementFrozen(vehicle, true) -- Freeze until race starts
            table.insert(mapElements, vehicle)
            setElementData(player, "jebiga:spawnVehicle", vehicle)
        end
    else
        -- Spawn on foot
        spawnPlayer(player, spawn.x, spawn.y, spawn.z, spawn.rotZ, spawn.skin or 0)
    end

    -- Initialize checkpoints
    initPlayerCheckpoints(player)

    fadeCamera(player, true, 1)
    setCameraTarget(player, player)

    return true
end

function unfreezeAllPlayers()
    for _, player in ipairs(getElementsByType("player")) do
        local vehicle = getElementData(player, "jebiga:spawnVehicle")
        if vehicle and isElement(vehicle) then
            setElementFrozen(vehicle, false)
        end
        setElementFrozen(player, false)
    end
end

-- ============================================
-- UTILITY
-- ============================================

function split(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- ============================================
-- EVENTS
-- ============================================

addEvent("jebiga:maploader:loadMap", true)
addEventHandler("jebiga:maploader:loadMap", root, function(mapName, dimension)
    loadMapResource(mapName, dimension)
end)

addEvent("jebiga:maploader:unloadMap", true)
addEventHandler("jebiga:maploader:unloadMap", root, function()
    unloadCurrentMap()
end)

addEvent("jebiga:maploader:spawnPlayer", true)
addEventHandler("jebiga:maploader:spawnPlayer", root, function(spawnIndex)
    spawnPlayerAtMap(client, spawnIndex)
end)

addEvent("jebiga:maploader:startRace", true)
addEventHandler("jebiga:maploader:startRace", root, function()
    unfreezeAllPlayers()

    -- Reset start times
    for player, _ in pairs(playerStartTimes) do
        playerStartTimes[player] = getTickCount()
    end

    triggerClientEvent(root, "jebiga:maploader:raceStarted", resourceRoot)
end)

-- Clean up on player quit
addEventHandler("onPlayerQuit", root, function()
    playerCheckpoints[source] = nil
    playerLaps[source] = nil
    playerStartTimes[source] = nil
    playerFinished[source] = nil

    local vehicle = getElementData(source, "jebiga:spawnVehicle")
    if vehicle and isElement(vehicle) then
        destroyElement(vehicle)
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

function getCurrentMapName()
    return currentMapName
end

function getSpawnPoints()
    return spawnPoints
end

function getCheckpoints()
    return checkpoints
end

function getMapSettings()
    return mapSettings
end

function getPlayerCheckpointProgress(player)
    return {
        checkpoint = playerCheckpoints[player] or 1,
        total = #checkpoints,
        lap = playerLaps[player] or 1,
        totalLaps = mapSettings.laps
    }
end

-- Make exports available
_G.loadMapResource = loadMapResource
_G.unloadCurrentMap = unloadCurrentMap
_G.spawnPlayerAtMap = spawnPlayerAtMap
_G.unfreezeAllPlayers = unfreezeAllPlayers
_G.getCurrentMapName = getCurrentMapName
_G.getSpawnPoints = getSpawnPoints
_G.getCheckpoints = getCheckpoints
_G.getMapSettings = getMapSettings
_G.getPlayerCheckpointProgress = getPlayerCheckpointProgress
