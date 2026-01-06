--[[
    Weevil Multi-Gamemode - Carball
    Server-side - Football/Soccer with cars
]]

local GAMEMODE = "carball"
local carballData = {
    players = {},
    teams = { red = {}, blue = {} },
    score = { red = 0, blue = 0 },
    ball = nil,
    state = "waiting",
    roundTime = 300 -- 5 minutes
}

local ARENA_CENTER = { x = 0, y = 0, z = 5 }
local GOAL_RED = { x = -50, y = 0, z = 5 }
local GOAL_BLUE = { x = 50, y = 0, z = 5 }
local GOAL_WIDTH = 20
local GOAL_HEIGHT = 10

addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[Weevil Carball] Carball gamemode initialized")
end)

-- Player joins Carball
addEventHandler("weevil:playerJoinedArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local player = source

    -- Assign to team with fewer players
    local team = #carballData.teams.red <= #carballData.teams.blue and "red" or "blue"

    carballData.players[player] = {
        team = team,
        goals = 0,
        assists = 0,
        vehicle = nil
    }

    table.insert(carballData.teams[team], player)

    local teamColor = team == "red" and "#FF4444" or "#4444FF"
    outputChatBox("#88FF88[Carball] #FFFFFFWelcome to Carball! You are on the " .. teamColor .. team:upper() .. " #FFFFFFteam.", player, 255, 255, 255, true)
end)

-- Player leaves Carball
addEventHandler("weevil:playerLeftArena", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    local data = carballData.players[source]
    if data then
        -- Remove from team
        for i, p in ipairs(carballData.teams[data.team]) do
            if p == source then
                table.remove(carballData.teams[data.team], i)
                break
            end
        end

        if data.vehicle and isElement(data.vehicle) then
            destroyElement(data.vehicle)
        end
    end

    carballData.players[source] = nil
end)

-- Create ball
function createBall()
    if carballData.ball and isElement(carballData.ball) then
        destroyElement(carballData.ball)
    end

    carballData.ball = createObject(1598, ARENA_CENTER.x, ARENA_CENTER.y, ARENA_CENTER.z + 2)
    setElementDimension(carballData.ball, Config.Gamemodes.carball.dimension)
    setObjectScale(carballData.ball, 3)
    setElementData(carballData.ball, "carball:ball", true)
end

-- Reset ball to center
function resetBall()
    if carballData.ball and isElement(carballData.ball) then
        setElementPosition(carballData.ball, ARENA_CENTER.x, ARENA_CENTER.y, ARENA_CENTER.z + 5)
        setElementVelocity(carballData.ball, 0, 0, 0)
    end
end

-- Spawn player
function spawnCarballPlayer(player)
    local data = carballData.players[player]
    if not data then return end

    local spawn
    if data.team == "red" then
        spawn = { x = GOAL_RED.x + 20, y = math.random(-10, 10), z = 5 }
    else
        spawn = { x = GOAL_BLUE.x - 20, y = math.random(-10, 10), z = 5 }
    end

    -- Create vehicle
    local vehicle = createVehicle(415, spawn.x, spawn.y, spawn.z) -- Cheetah
    setElementDimension(vehicle, Config.Gamemodes.carball.dimension)

    -- Team colors
    if data.team == "red" then
        setVehicleColor(vehicle, 255, 0, 0, 255, 0, 0)
    else
        setVehicleColor(vehicle, 0, 0, 255, 0, 0, 255)
    end

    spawnPlayer(player, spawn.x, spawn.y, spawn.z + 2)
    setElementDimension(player, Config.Gamemodes.carball.dimension)
    warpPedIntoVehicle(player, vehicle)

    data.vehicle = vehicle
end

-- Handle goal
addEvent("weevil:carball:goal", true)
addEventHandler("weevil:carball:goal", root, function(team, scorer)
    if carballData.state ~= "playing" then return end

    carballData.score[team] = carballData.score[team] + 1

    if scorer and carballData.players[scorer] then
        carballData.players[scorer].goals = carballData.players[scorer].goals + 1
        exports.weevil_core:addPlayerPoints(scorer, 10, GAMEMODE)
        exports.weevil_core:addPlayerMoney(scorer, 20, "Carball goal")
    end

    local teamColor = team == "red" and "#FF4444" or "#4444FF"
    local scorerName = scorer and getPlayerName(scorer) or "Unknown"

    for p, _ in pairs(carballData.players) do
        outputChatBox("#88FF88[Carball] " .. teamColor .. "GOAL! #FFFFFF" .. scorerName .. " scores! " ..
            "#FF4444Red " .. carballData.score.red .. " #FFFFFF- #4444FFBlue " .. carballData.score.blue, p, 255, 255, 255, true)
    end

    -- Reset positions
    setTimer(function()
        resetBall()
        for player, _ in pairs(carballData.players) do
            if isElement(player) then
                spawnCarballPlayer(player)
            end
        end
    end, 3000, 1)
end)

-- Round started
addEventHandler("weevil:roundStarted", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    carballData.state = "playing"
    carballData.score = { red = 0, blue = 0 }

    createBall()

    for player, data in pairs(carballData.players) do
        data.goals = 0
        data.assists = 0
        spawnCarballPlayer(player)
    end

    -- Round timer
    setTimer(function()
        if carballData.state == "playing" then
            endCarballRound()
        end
    end, carballData.roundTime * 1000, 1)
end)

-- End round
function endCarballRound()
    carballData.state = "ending"

    local winningTeam
    if carballData.score.red > carballData.score.blue then
        winningTeam = "red"
    elseif carballData.score.blue > carballData.score.red then
        winningTeam = "blue"
    else
        winningTeam = "draw"
    end

    local teamColor = winningTeam == "red" and "#FF4444" or (winningTeam == "blue" and "#4444FF" or "#FFFF44")
    local resultText = winningTeam == "draw" and "DRAW!" or (winningTeam:upper() .. " TEAM WINS!")

    for p, _ in pairs(carballData.players) do
        outputChatBox("#88FF88[Carball] " .. teamColor .. resultText .. " #FFFFFFScore: " ..
            carballData.score.red .. " - " .. carballData.score.blue, p, 255, 255, 255, true)
    end

    -- Award winning team
    if winningTeam ~= "draw" then
        for _, player in ipairs(carballData.teams[winningTeam]) do
            if isElement(player) then
                exports.weevil_core:addPlayerWin(player, GAMEMODE)
            end
        end
    end

    triggerEvent("weevil:roundEnded", root, GAMEMODE, nil)
end

addEventHandler("weevil:roundEnded", root, function(gamemode)
    if gamemode ~= GAMEMODE then return end

    carballData.state = "waiting"

    if carballData.ball and isElement(carballData.ball) then
        destroyElement(carballData.ball)
    end

    for player, data in pairs(carballData.players) do
        if data.vehicle and isElement(data.vehicle) then
            destroyElement(data.vehicle)
            data.vehicle = nil
        end
    end
end)
