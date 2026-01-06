--[[
    Jebiga Multi-Gamemode - Arena Manager
    Handles arena-specific logic, vehicles, pickups, etc.
]]

local arenaVehicles = {}
local arenaObjects = {}
local arenaPickups = {}
local arenaBlips = {}

-- Create arena for gamemode
function createArena(gamemode, mapData)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return false end

    -- Clear existing arena elements
    clearArena(gamemode)

    arenaVehicles[gamemode] = {}
    arenaObjects[gamemode] = {}
    arenaPickups[gamemode] = {}
    arenaBlips[gamemode] = {}

    -- Create spawn vehicles
    if mapData.spawnpoints then
        for _, spawn in ipairs(mapData.spawnpoints) do
            local vehicle = createVehicle(
                spawn.vehicle or 411,
                spawn.x, spawn.y, spawn.z,
                spawn.rx or 0, spawn.ry or 0, spawn.rz or 0
            )

            if vehicle then
                setElementDimension(vehicle, cfg.dimension)
                setVehicleDamageProof(vehicle, true) -- Protect until round starts

                if spawn.color1 and spawn.color2 then
                    setVehicleColor(vehicle, spawn.color1, spawn.color2)
                end

                table.insert(arenaVehicles[gamemode], vehicle)
            end
        end
    end

    -- Create objects
    if mapData.objects then
        for _, obj in ipairs(mapData.objects) do
            local object = createObject(
                obj.model,
                obj.x, obj.y, obj.z,
                obj.rx or 0, obj.ry or 0, obj.rz or 0
            )

            if object then
                setElementDimension(object, cfg.dimension)
                setElementDoubleSided(object, true)

                if obj.scale then
                    setObjectScale(object, obj.scale)
                end

                table.insert(arenaObjects[gamemode], object)
            end
        end
    end

    -- Create pickups (for DM/Shooter)
    if mapData.pickups then
        for _, pickup in ipairs(mapData.pickups) do
            local pickupElement = createPickup(
                pickup.x, pickup.y, pickup.z,
                pickup.type or 2,
                pickup.id or 0
            )

            if pickupElement then
                setElementDimension(pickupElement, cfg.dimension)
                table.insert(arenaPickups[gamemode], pickupElement)
            end
        end
    end

    -- Create checkpoints for racing gamemodes
    if mapData.checkpoints then
        for i, cp in ipairs(mapData.checkpoints) do
            -- Store checkpoint data for client-side rendering
            if not arenaCheckpoints then arenaCheckpoints = {} end
            if not arenaCheckpoints[gamemode] then arenaCheckpoints[gamemode] = {} end

            table.insert(arenaCheckpoints[gamemode], {
                x = cp.x,
                y = cp.y,
                z = cp.z,
                size = cp.size or 4,
                type = cp.type or "checkpoint",
                nextX = cp.nextX,
                nextY = cp.nextY,
                nextZ = cp.nextZ
            })
        end
    end

    return true
end

-- Clear arena elements
function clearArena(gamemode)
    -- Destroy vehicles
    if arenaVehicles[gamemode] then
        for _, vehicle in ipairs(arenaVehicles[gamemode]) do
            if isElement(vehicle) then
                destroyElement(vehicle)
            end
        end
        arenaVehicles[gamemode] = {}
    end

    -- Destroy objects
    if arenaObjects[gamemode] then
        for _, object in ipairs(arenaObjects[gamemode]) do
            if isElement(object) then
                destroyElement(object)
            end
        end
        arenaObjects[gamemode] = {}
    end

    -- Destroy pickups
    if arenaPickups[gamemode] then
        for _, pickup in ipairs(arenaPickups[gamemode]) do
            if isElement(pickup) then
                destroyElement(pickup)
            end
        end
        arenaPickups[gamemode] = {}
    end

    -- Destroy blips
    if arenaBlips[gamemode] then
        for _, blip in ipairs(arenaBlips[gamemode]) do
            if isElement(blip) then
                destroyElement(blip)
            end
        end
        arenaBlips[gamemode] = {}
    end

    -- Clear checkpoints
    if arenaCheckpoints and arenaCheckpoints[gamemode] then
        arenaCheckpoints[gamemode] = {}
    end
end

-- Get arena vehicles
function getArenaVehicles(gamemode)
    return arenaVehicles[gamemode] or {}
end

-- Get arena objects
function getArenaObjects(gamemode)
    return arenaObjects[gamemode] or {}
end

-- Get arena checkpoints
function getArenaCheckpoints(gamemode)
    return arenaCheckpoints and arenaCheckpoints[gamemode] or {}
end

-- Enable vehicle damage (when round starts)
function enableArenaDamage(gamemode)
    if arenaVehicles[gamemode] then
        for _, vehicle in ipairs(arenaVehicles[gamemode]) do
            if isElement(vehicle) then
                setVehicleDamageProof(vehicle, false)
            end
        end
    end
end

-- Disable vehicle damage (between rounds)
function disableArenaDamage(gamemode)
    if arenaVehicles[gamemode] then
        for _, vehicle in ipairs(arenaVehicles[gamemode]) do
            if isElement(vehicle) then
                setVehicleDamageProof(vehicle, true)
            end
        end
    end
end

-- Reset arena vehicles
function resetArenaVehicles(gamemode)
    if arenaVehicles[gamemode] then
        for _, vehicle in ipairs(arenaVehicles[gamemode]) do
            if isElement(vehicle) then
                fixVehicle(vehicle)
                setElementHealth(vehicle, 1000)
            end
        end
    end
end

-- Create Carball arena elements
function createCarballArena(gamemode, mapData)
    local cfg = Config.Gamemodes[gamemode]
    if not cfg then return false end

    -- Create the ball (using a sphere object)
    local ballX = mapData.ballSpawn and mapData.ballSpawn.x or 0
    local ballY = mapData.ballSpawn and mapData.ballSpawn.y or 0
    local ballZ = mapData.ballSpawn and mapData.ballSpawn.z or 5

    local ball = createObject(1598, ballX, ballY, ballZ) -- Football/Soccer ball
    if ball then
        setElementDimension(ball, cfg.dimension)
        setObjectScale(ball, 3)
        setElementData(ball, "carball:ball", true)

        if not arenaObjects[gamemode] then arenaObjects[gamemode] = {} end
        table.insert(arenaObjects[gamemode], ball)
    end

    -- Create goals (markers)
    if mapData.goals then
        for i, goal in ipairs(mapData.goals) do
            local marker = createMarker(
                goal.x, goal.y, goal.z,
                "cylinder",
                goal.size or 10,
                goal.r or 255, goal.g or 0, goal.b or 0, 100
            )

            if marker then
                setElementDimension(marker, cfg.dimension)
                setElementData(marker, "carball:goal", i)
            end
        end
    end

    return true
end

-- Handle vehicle explosion
addEventHandler("onVehicleExplode", root, function()
    local vehicle = source
    local dimension = getElementDimension(vehicle)

    -- Find which gamemode this vehicle belongs to
    for gamemode, cfg in pairs(Config.Gamemodes) do
        if cfg.dimension == dimension then
            -- Check if it's an arena vehicle
            if arenaVehicles[gamemode] then
                for _, v in ipairs(arenaVehicles[gamemode]) do
                    if v == vehicle then
                        -- Get the player in this vehicle
                        local occupant = getVehicleOccupant(vehicle)
                        if occupant then
                            -- Handle elimination
                            addPlayerElimination(occupant, gamemode, getElementData(vehicle, "lastDamager"))
                        end
                        break
                    end
                end
            end
            break
        end
    end
end)

-- Handle vehicle damage (track last damager)
addEventHandler("onVehicleDamage", root, function(loss)
    local vehicle = source
    local attacker = getElementData(vehicle, "currentAttacker")

    if attacker and isElement(attacker) then
        setElementData(vehicle, "lastDamager", attacker)
    end
end)

-- Handle player wasted
addEventHandler("onPlayerWasted", root, function(totalAmmo, killer, killerWeapon, bodypart)
    local player = source
    local gamemode = getCurrentGamemode(player)

    if gamemode then
        -- Handle based on gamemode type
        if gamemode == "shooter" or gamemode == "runarena" then
            -- Respawn after delay
            setTimer(function()
                if isElement(player) and getCurrentGamemode(player) == gamemode then
                    local arena = Jebiga.arenas[gamemode]
                    if arena and arena.state == "playing" then
                        local spawn = getMapSpawnPoints(gamemode)[math.random(1, 5)]
                        spawnPlayerInArena(player, gamemode, spawn)
                    end
                end
            end, Config.Arena.respawnTime * 1000, 1)

            -- Award killer
            if killer and isElement(killer) and killer ~= player then
                addPlayerKill(killer, gamemode)
            end

            addPlayerDeath(player, gamemode)

        elseif gamemode == "dm" then
            -- In DM, death usually means elimination for that lap/section
            -- But can respawn depending on map settings
            setTimer(function()
                if isElement(player) and getCurrentGamemode(player) == gamemode then
                    local arena = Jebiga.arenas[gamemode]
                    if arena and arena.state == "playing" then
                        local spawn = getMapSpawnPoints(gamemode)[math.random(1, 5)]
                        spawnPlayerInArena(player, gamemode, spawn)
                    end
                end
            end, Config.Arena.respawnTime * 1000, 1)

        elseif gamemode == "hunter" then
            -- Full elimination in Hunter
            addPlayerElimination(player, gamemode, killer)
        end
    end
end)

-- Handle pickup collection
addEventHandler("onPlayerPickUpRacePickup", root, function(pickupType)
    local player = source
    local gamemode = getCurrentGamemode(player)

    if not gamemode then return end

    if pickupType == "vehiclechange" then
        -- Vehicle change pickup
        triggerEvent("weevil:vehicleChanged", player, gamemode)
    elseif pickupType == "nitro" then
        -- Nitro pickup
        local vehicle = getPedOccupiedVehicle(player)
        if vehicle then
            addVehicleUpgrade(vehicle, 1010) -- Nitro x10
        end
    elseif pickupType == "repair" then
        -- Repair pickup
        local vehicle = getPedOccupiedVehicle(player)
        if vehicle then
            fixVehicle(vehicle)
        end
    end
end)

-- Custom events
addEvent("weevil:vehicleChanged", false)

-- Spectator mode
function setPlayerSpectating(player, target)
    if not isElement(player) then return false end

    if target then
        setCameraTarget(player, target)
        setElementData(player, "spectating", target)
    else
        setCameraTarget(player, player)
        removeElementData(player, "spectating")
    end

    return true
end

-- Handle spectate request
addEvent(Events.Arena.REQUEST_SPECTATE, true)
addEventHandler(Events.Arena.REQUEST_SPECTATE, root, function(targetPlayer)
    local player = client
    local gamemode = getCurrentGamemode(player)

    if not gamemode then return end

    local arena = Jebiga.arenas[gamemode]
    if not arena then return end

    -- Can only spectate if dead/eliminated
    if not getElementData(player, "eliminated") then return end

    if targetPlayer and isElement(targetPlayer) then
        setPlayerSpectating(player, targetPlayer)
    else
        -- Find next alive player to spectate
        for _, p in ipairs(arena.players) do
            if isElement(p) and p ~= player and not getElementData(p, "eliminated") then
                setPlayerSpectating(player, p)
                break
            end
        end
    end
end)

-- Cleanup on resource stop
addEventHandler("onResourceStop", resourceRoot, function()
    for gamemode, _ in pairs(Config.Gamemodes) do
        clearArena(gamemode)
    end
end)
