--[[
    Weevil Multi-Gamemode - Lobby Camera
    Cinematic lobby camera system
]]

local cameraEnabled = false
local cameraPositions = {
    -- Los Santos views
    { x = 1468.8, y = -919.3, z = 100.0, lookX = 1550, lookY = -850, lookZ = 50 },
    { x = 2027.1, y = -1393.8, z = 35.0, lookX = 1950, lookY = -1350, lookZ = 25 },
    { x = 1297.5, y = -800.8, z = 95.0, lookX = 1200, lookY = -900, lookZ = 50 },
    { x = 2494.1, y = -1666.8, z = 25.0, lookX = 2450, lookY = -1700, lookZ = 15 },

    -- San Fierro views
    { x = -2027.6, y = 156.1, z = 50.0, lookX = -2100, lookY = 200, lookZ = 30 },
    { x = -2716.6, y = 217.3, z = 15.0, lookX = -2750, lookY = 150, lookZ = 5 },

    -- Las Venturas views
    { x = 2024.8, y = 1007.9, z = 35.0, lookX = 2100, lookY = 1050, lookZ = 25 },
    { x = 2491.9, y = 2397.5, z = 20.0, lookX = 2400, lookY = 2350, lookZ = 15 },

    -- Countryside views
    { x = -315.0, y = 1520.0, z = 100.0, lookX = -400, lookY = 1600, lookZ = 50 },
    { x = 425.0, y = 2525.0, z = 50.0, lookX = 350, lookY = 2600, lookZ = 30 }
}

local currentCameraIndex = 1
local cameraTransitionTime = 10000 -- 10 seconds per position
local cameraFadeTime = 2000 -- 2 seconds fade
local lastCameraChange = 0
local cameraAlpha = 0

-- Camera interpolation
local currentCamPos = { x = 0, y = 0, z = 0 }
local currentLookAt = { x = 0, y = 0, z = 0 }
local targetCamPos = { x = 0, y = 0, z = 0 }
local targetLookAt = { x = 0, y = 0, z = 0 }
local interpolationProgress = 0

-- Enable lobby camera
function enableLobbyCamera()
    if cameraEnabled then return end

    cameraEnabled = true
    lastCameraChange = getTickCount()

    -- Set initial camera position
    local pos = cameraPositions[currentCameraIndex]
    currentCamPos = { x = pos.x, y = pos.y, z = pos.z }
    currentLookAt = { x = pos.lookX, y = pos.lookY, z = pos.lookZ }

    selectNextCameraTarget()

    showChat(false)
    showPlayerHudComponent("radar", false)
end

-- Disable lobby camera
function disableLobbyCamera()
    if not cameraEnabled then return end

    cameraEnabled = false
    setCameraTarget(localPlayer)

    showChat(true)
    showPlayerHudComponent("radar", true)
end

-- Select next camera target
function selectNextCameraTarget()
    -- Choose random next position (different from current)
    local nextIndex
    repeat
        nextIndex = math.random(1, #cameraPositions)
    until nextIndex ~= currentCameraIndex

    currentCameraIndex = nextIndex
    local pos = cameraPositions[currentCameraIndex]

    targetCamPos = { x = pos.x, y = pos.y, z = pos.z }
    targetLookAt = { x = pos.lookX, y = pos.lookY, z = pos.lookZ }
    interpolationProgress = 0
    lastCameraChange = getTickCount()
end

-- Smooth interpolation
function lerp(a, b, t)
    return a + (b - a) * t
end

-- Ease function for smoother transitions
function easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - math.pow(-2 * t + 2, 2) / 2
    end
end

-- Update camera
function updateLobbyCamera()
    if not cameraEnabled then return end

    local now = getTickCount()
    local elapsed = now - lastCameraChange

    -- Calculate interpolation progress
    interpolationProgress = math.min(1, elapsed / cameraTransitionTime)
    local easedProgress = easeInOutQuad(interpolationProgress)

    -- Interpolate position
    local camX = lerp(currentCamPos.x, targetCamPos.x, easedProgress)
    local camY = lerp(currentCamPos.y, targetCamPos.y, easedProgress)
    local camZ = lerp(currentCamPos.z, targetCamPos.z, easedProgress)

    local lookX = lerp(currentLookAt.x, targetLookAt.x, easedProgress)
    local lookY = lerp(currentLookAt.y, targetLookAt.y, easedProgress)
    local lookZ = lerp(currentLookAt.z, targetLookAt.z, easedProgress)

    -- Add slight movement for cinematic effect
    local time = now / 1000
    camX = camX + math.sin(time * 0.1) * 2
    camY = camY + math.cos(time * 0.15) * 2
    camZ = camZ + math.sin(time * 0.08) * 0.5

    -- Set camera
    setCameraMatrix(camX, camY, camZ, lookX, lookY, lookZ)

    -- Check if transition complete
    if interpolationProgress >= 1 then
        currentCamPos = { x = targetCamPos.x, y = targetCamPos.y, z = targetCamPos.z }
        currentLookAt = { x = targetLookAt.x, y = targetLookAt.y, z = targetLookAt.z }
        selectNextCameraTarget()
    end
end

addEventHandler("onClientPreRender", root, updateLobbyCamera)

-- Render lobby overlay
function renderLobbyOverlay()
    if not cameraEnabled then return end

    local screenW, screenH = guiGetScreenSize()

    -- Gradient overlay at top
    for i = 0, 100 do
        local alpha = math.floor((1 - i / 100) * 150)
        dxDrawRectangle(0, i, screenW, 1, tocolor(0, 0, 0, alpha))
    end

    -- Gradient overlay at bottom
    for i = 0, 150 do
        local alpha = math.floor((i / 150) * 200)
        dxDrawRectangle(0, screenH - 150 + i, screenW, 1, tocolor(0, 0, 0, alpha))
    end

    -- Server name
    dxDrawText(
        "WEEVIL GAMING",
        0, 20,
        screenW, 70,
        tocolor(255, 102, 0, 255),
        2.0, "default-bold", "center", "center"
    )

    -- Tagline
    dxDrawText(
        "Multi-Gamemode Server",
        0, 65,
        screenW, 95,
        tocolor(200, 200, 200, 255),
        1.0, "default", "center", "center"
    )

    -- Instructions
    dxDrawText(
        "Press F2 to select a gamemode",
        0, screenH - 80,
        screenW, screenH - 50,
        tocolor(255, 255, 255, 255),
        1.2, "default-bold", "center", "center"
    )

    -- Online players
    local playerCount = #getElementsByType("player")
    dxDrawText(
        playerCount .. " players online",
        0, screenH - 45,
        screenW, screenH - 20,
        tocolor(150, 150, 150, 255),
        0.9, "default", "center", "center"
    )
end

addEventHandler("onClientRender", root, renderLobbyOverlay)

-- Check if player is in lobby
function checkLobbyState()
    local isInLobby = exports.weevil_core:isPlayerInLobby()

    if isInLobby and not cameraEnabled then
        enableLobbyCamera()
    elseif not isInLobby and cameraEnabled then
        disableLobbyCamera()
    end
end

-- Check lobby state periodically
setTimer(checkLobbyState, 1000, 0)

-- Handle joining/leaving gamemode
addEvent(Events.Lobby.PLAYER_JOIN, true)
addEventHandler(Events.Lobby.PLAYER_JOIN, root, function()
    disableLobbyCamera()
end)

addEvent(Events.Lobby.PLAYER_LEAVE, true)
addEventHandler(Events.Lobby.PLAYER_LEAVE, root, function()
    enableLobbyCamera()
end)

-- Initialize
addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        if exports.weevil_core:isPlayerInLobby() then
            enableLobbyCamera()
        end
    end, 2000, 1)
end)

-- Cleanup
addEventHandler("onClientResourceStop", resourceRoot, function()
    disableLobbyCamera()
end)
