--[[
    Jebiga Multi-Gamemode - Carball
    Client-side Carball gamemode
]]

local GAMEMODE = "carball"
local team = nil
local score = { red = 0, blue = 0 }
local roundTimeRemaining = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[Jebiga Carball] Carball client initialized")
end)

-- Render Carball HUD
addEventHandler("onClientRender", root, function()
    local gamemode = exports.jebiga_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    -- Score display
    dxDrawRectangle(screenW / 2 - 100, 10, 200, 50, tocolor(0, 0, 0, 180))

    -- Red score
    dxDrawText(
        tostring(score.red),
        screenW / 2 - 90, 15,
        screenW / 2 - 20, 55,
        tocolor(255, 100, 100, 255),
        2.0, "default-bold", "center", "center"
    )

    -- VS
    dxDrawText(
        "-",
        screenW / 2 - 20, 15,
        screenW / 2 + 20, 55,
        tocolor(255, 255, 255, 255),
        2.0, "default-bold", "center", "center"
    )

    -- Blue score
    dxDrawText(
        tostring(score.blue),
        screenW / 2 + 20, 15,
        screenW / 2 + 90, 55,
        tocolor(100, 100, 255, 255),
        2.0, "default-bold", "center", "center"
    )

    -- Team indicator
    if team then
        local teamColor = team == "red" and tocolor(255, 100, 100, 255) or tocolor(100, 100, 255, 255)
        dxDrawText(
            "Team: " .. team:upper(),
            screenW / 2 - 50, 65,
            screenW / 2 + 50, 85,
            teamColor,
            0.9, "default-bold", "center", "center"
        )
    end
end)

-- Update score from server
addEvent("weevil:carball:updateScore", true)
addEventHandler("weevil:carball:updateScore", root, function(newScore)
    score = newScore or { red = 0, blue = 0 }
end)

-- Set team
addEvent("weevil:carball:setTeam", true)
addEventHandler("weevil:carball:setTeam", root, function(newTeam)
    team = newTeam
end)

-- Reset on new round
addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    score = { red = 0, blue = 0 }
end)

-- Cleanup
addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    team = nil
    score = { red = 0, blue = 0 }
end)
