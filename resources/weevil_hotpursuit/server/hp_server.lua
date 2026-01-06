--[[
    Weevil Multi-Gamemode - Hot Pursuit
    Racers vs Police - Racers try to reach finish, Police try to catch them
]]

local GAMEMODE = "hotpursuit"
local hpData = {
    players = {},
    racers = {},
    police = {},
    state = "waiting"
}

local POLICE_VEHICLE = 596 -- Police Car
local RACER_VEHICLES = { 411, 451, 541, 506 }

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil HP] Hot Pursuit gamemode initialized")
end)

addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source

    -- Assign role (30% police, 70% racers)
    local role = math.random() < 0.3 and "police" or "racer"

    hpData.players[player] = {
        role = role,
        catches = 0,
        caught = false,
        finished = false
    }

    table.insert(hpData[role == "police" and "police" or "racers"], player)

    local roleColor = role == "police" and "#4444FF" or "#FF4444"
    outputChatBox("#8844FF[Hot Pursuit] #FFFFFFYou are a " .. roleColor .. role:upper() .. "#FFFFFF!", player, 255, 255, 255, true)

    triggerClientEvent(player, "weevil:hp:setRole", player, role)
end)

addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local data = hpData.players[source]
    if data then
        local list = data.role == "police" and hpData.police or hpData.racers
        for i, p in ipairs(list) do
            if p == source then
                table.remove(list, i)
                break
            end
        end
    end

    hpData.players[source] = nil
end)

-- Police catches racer
addEvent("weevil:hp:catch", true)
addEventHandler("weevil:hp:catch", root, function(racerElement)
    local police = client
    if not hpData.players[police] or hpData.players[police].role ~= "police" then return end

    local racer = racerElement
    if not hpData.players[racer] or hpData.players[racer].role ~= "racer" then return end
    if hpData.players[racer].caught then return end

    hpData.players[racer].caught = true
    hpData.players[police].catches = hpData.players[police].catches + 1

    exports.weevil_core:addPlayerPoints(police, 8, GAMEMODE)
    exports.weevil_core:addPlayerMoney(police, 25, "HP Catch")

    for p, _ in pairs(hpData.players) do
        outputChatBox("#8844FF[HP] #4444FF" .. getPlayerName(police) .. " #FFFFFFcaught #FF4444" .. getPlayerName(racer) .. "#FFFFFF!", p, 255, 255, 255, true)
    end

    -- Check if all racers caught
    checkRoundEnd()
end)

-- Racer finishes
addEvent("weevil:hp:finish", true)
addEventHandler("weevil:hp:finish", root, function()
    local racer = client
    if not hpData.players[racer] or hpData.players[racer].role ~= "racer" then return end
    if hpData.players[racer].caught or hpData.players[racer].finished then return end

    hpData.players[racer].finished = true

    exports.weevil_core:addPlayerPoints(racer, 15, GAMEMODE)
    exports.weevil_core:addPlayerMoney(racer, 40, "HP Escape")

    for p, _ in pairs(hpData.players) do
        outputChatBox("#8844FF[HP] #FF4444" .. getPlayerName(racer) .. " #FFFFFFescaped!", p, 255, 255, 255, true)
    end

    checkRoundEnd()
end)

function checkRoundEnd()
    local activeRacers = 0
    for _, racer in ipairs(hpData.racers) do
        local data = hpData.players[racer]
        if data and not data.caught and not data.finished then
            activeRacers = activeRacers + 1
        end
    end

    if activeRacers == 0 then
        triggerEvent("weevil:roundEnded", root, GAMEMODE, nil)
    end
end

addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    hpData.state = "playing"

    for player, data in pairs(hpData.players) do
        data.catches = 0
        data.caught = false
        data.finished = false
        spawnHPPlayer(player)
    end
end)

function spawnHPPlayer(player)
    local data = hpData.players[player]
    if not data then return end

    local vehicleId = data.role == "police" and POLICE_VEHICLE or RACER_VEHICLES[math.random(#RACER_VEHICLES)]
    local spawn = { x = math.random(-20, 20), y = math.random(-20, 20), z = 10 }

    local vehicle = createVehicle(vehicleId, spawn.x, spawn.y, spawn.z)
    setElementDimension(vehicle, Config.Gamemodes.hotpursuit.dimension)

    spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
    setElementDimension(player, Config.Gamemodes.hotpursuit.dimension)
    warpPedIntoVehicle(player, vehicle)
end
