--[[
    Weevil Multi-Gamemode - Startup Script
    This resource starts all Weevil MGM resources in the correct order
]]

local resources = {
    -- Core systems (start first)
    "weevil_core",
    "weevil_accounts",

    -- Support systems
    "weevil_lobby",
    "weevil_scoreboard",
    "weevil_toptimes",
    "weevil_userpanel",
    "weevil_achievements",
    "weevil_garage",
    "weevil_admin",

    -- Gamemodes
    "weevil_dm",
    "weevil_race",
    "weevil_dd",
    "weevil_hunter",
    "weevil_shooter",
    "weevil_stuntage",
    "weevil_trials",
    "weevil_carball",
    "weevil_hotpursuit",
    "weevil_runarena",
    "weevil_training"
}

local startedResources = {}
local currentIndex = 0

function startNextResource()
    currentIndex = currentIndex + 1

    if currentIndex > #resources then
        outputDebugString("[Weevil] All resources started successfully!")
        outputServerLog("[Weevil] Multi-Gamemode server fully loaded")
        outputServerLog("[Weevil] Started " .. #startedResources .. " resources")
        return
    end

    local resourceName = resources[currentIndex]
    local resource = getResourceFromName(resourceName)

    if resource then
        if getResourceState(resource) == "running" then
            outputDebugString("[Weevil] " .. resourceName .. " already running")
            table.insert(startedResources, resourceName)
            startNextResource()
        else
            local success = startResource(resource)
            if success then
                outputDebugString("[Weevil] Started: " .. resourceName)
                table.insert(startedResources, resourceName)
            else
                outputDebugString("[Weevil] Failed to start: " .. resourceName, 2)
            end
            -- Continue to next resource after a short delay
            setTimer(startNextResource, 500, 1)
        end
    else
        outputDebugString("[Weevil] Resource not found: " .. resourceName, 2)
        setTimer(startNextResource, 100, 1)
    end
end

-- Start loading resources when this resource starts
addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog("==========================================")
    outputServerLog("  WEEVIL MULTI-GAMEMODE SERVER")
    outputServerLog("  Version 1.0.0")
    outputServerLog("  Starting resources...")
    outputServerLog("==========================================")

    setTimer(startNextResource, 1000, 1)
end)

-- Stop all resources when this resource stops
addEventHandler("onResourceStop", resourceRoot, function()
    outputServerLog("[Weevil] Stopping all Weevil resources...")

    for i = #startedResources, 1, -1 do
        local resourceName = startedResources[i]
        local resource = getResourceFromName(resourceName)
        if resource and getResourceState(resource) == "running" then
            stopResource(resource)
        end
    end
end)

-- Command to reload all resources
addCommandHandler("weevilreload", function(player)
    if player and not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    outputServerLog("[Weevil] Reloading all resources...")

    -- Stop all
    for i = #startedResources, 1, -1 do
        local resourceName = startedResources[i]
        local resource = getResourceFromName(resourceName)
        if resource and getResourceState(resource) == "running" then
            stopResource(resource)
        end
    end

    startedResources = {}
    currentIndex = 0

    -- Start again
    setTimer(startNextResource, 2000, 1)

    if player then
        outputChatBox("[Weevil] Reloading all resources...", player, 255, 200, 0)
    end
end)

-- Status command
addCommandHandler("weevilstatus", function(player)
    outputChatBox("=== Weevil MGM Status ===", player, 255, 200, 0)
    outputChatBox("Loaded resources: " .. #startedResources .. "/" .. #resources, player, 255, 255, 255)

    local running = 0
    for _, name in ipairs(resources) do
        local res = getResourceFromName(name)
        if res and getResourceState(res) == "running" then
            running = running + 1
        end
    end

    outputChatBox("Running: " .. running, player, 100, 255, 100)
end)
