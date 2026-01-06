--[[
    Jebiga Multi-Gamemode - Hot Pursuit Client
]]

local GAMEMODE = "hotpursuit"
local role = nil

addEvent("weevil:hp:setRole", true)
addEventHandler("weevil:hp:setRole", root, function(newRole)
    role = newRole
end)

addEventHandler("onClientRender", root, function()
    local gamemode = exports.jebiga_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    local roleText = role and role:upper() or "UNKNOWN"
    local roleColor = role == "police" and tocolor(100, 100, 255, 255) or tocolor(255, 100, 100, 255)

    dxDrawText(
        roleText,
        screenW / 2 - 80, 20,
        screenW / 2 + 80, 50,
        roleColor,
        1.5, "default-bold", "center", "center"
    )

    local objective = role == "police" and "Catch the racers!" or "Escape to the finish!"
    dxDrawText(
        objective,
        screenW / 2 - 120, 55,
        screenW / 2 + 120, 75,
        tocolor(200, 200, 200, 255),
        0.9, "default", "center", "center"
    )
end)

addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function(gamemode)
    if gamemode ~= GAMEMODE then return end
    role = nil
end)
