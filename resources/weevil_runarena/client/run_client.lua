--[[
    Weevil Multi-Gamemode - Run Arena Client
]]

local GAMEMODE = "runarena"
local checkpoint = 0
local kills = 0
local deaths = 0

addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    dxDrawText(
        "RUN ARENA",
        screenW / 2 - 80, 20,
        screenW / 2 + 80, 50,
        tocolor(255, 150, 150, 255),
        1.3, "default-bold", "center", "center"
    )

    dxDrawText(
        "K: " .. kills .. " | D: " .. deaths,
        screenW / 2 - 60, 55,
        screenW / 2 + 60, 75,
        tocolor(200, 200, 200, 255),
        0.9, "default", "center", "center"
    )
end)

addEvent(Events.Arena.ROUND_START, true)
addEventHandler(Events.Arena.ROUND_START, root, function(data)
    if data.gamemode ~= GAMEMODE then return end
    checkpoint = 0
    kills = 0
    deaths = 0
end)

addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    checkpoint = 0
    kills = 0
    deaths = 0
end)
