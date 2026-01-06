--[[
    Weevil Multi-Gamemode - Training Client
]]

local GAMEMODE = "training"

addEventHandler("onClientRender", root, function()
    local gamemode = exports.weevil_core:getCurrentGamemode()
    if gamemode ~= GAMEMODE then return end

    local screenW, screenH = guiGetScreenSize()

    dxDrawText(
        "TRAINING MODE",
        screenW / 2 - 100, 20,
        screenW / 2 + 100, 50,
        tocolor(150, 150, 150, 255),
        1.3, "default-bold", "center", "center"
    )

    dxDrawText(
        "/vehicle [id] | /repair | /flip | /invincible",
        screenW / 2 - 180, 55,
        screenW / 2 + 180, 75,
        tocolor(120, 120, 120, 255),
        0.8, "default", "center", "center"
    )
end)
