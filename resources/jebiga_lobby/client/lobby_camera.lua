--[[
    Jebiga Multi-Gamemode - Lobby Camera Helper
    Minimal - main lobby panel is handled by lobby_gui.lua
]]

-- Handle login event - show lobby panel
addEvent("jebiga:playerLoggedIn", true)
addEventHandler("jebiga:playerLoggedIn", root, function()
    if showLobbyGUI then
        showLobbyGUI()
    end
end)

-- Handle gamemode join - hide lobby
addEvent("weevil:lobby:playerJoin", true)
addEventHandler("weevil:lobby:playerJoin", root, function()
    if hideLobbyGUI then
        hideLobbyGUI()
    end
end)

-- Handle return to lobby
addEvent("weevil:lobby:playerLeave", true)
addEventHandler("weevil:lobby:playerLeave", root, function()
    if showLobbyGUI then
        showLobbyGUI()
    end
end)

-- Auto-show lobby on resource start if not in gamemode
addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        local currentGM = getElementData(localPlayer, "jebiga:currentGamemode")
        if not currentGM and showLobbyGUI then
            showLobbyGUI()
        end
    end, 2500, 1)
end)
