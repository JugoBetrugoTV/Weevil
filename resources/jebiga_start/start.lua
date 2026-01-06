--[[
    Jebiga Multi-Gamemode - Startup Script
    This resource starts all Jebiga MGM resources in the correct order
]]

local resources = {
    -- Core systems (start first)
    "jebiga_core",
    "jebiga_accounts",

    -- Support systems
    "jebiga_lobby",
    "jebiga_scoreboard",
    "jebiga_toptimes",
    "jebiga_userpanel",
    "jebiga_achievements",
    "jebiga_garage",
    "jebiga_admin",

    -- Gamemodes
    "jebiga_dm",
    "jebiga_race",
    "jebiga_dd",
    "jebiga_hunter",
    "jebiga_shooter",
    "jebiga_stuntage",
    "jebiga_trials",
    "jebiga_carball",
    "jebiga_hotpursuit",
    "jebiga_runarena",
    "jebiga_training"
}

local startedResources = {}
local currentIndex = 0

function startNextResource()
    currentIndex = currentIndex + 1

    if currentIndex > #resources then
        outputDebugString("[Jebiga] All resources started successfully!")
        outputServerLog("[Jebiga] ==========================================")
        outputServerLog("[Jebiga] Multi-Gamemode server fully loaded!")
        outputServerLog("[Jebiga] Started " .. #startedResources .. " resources")
        outputServerLog("[Jebiga] Press F1 in-game to open gamemode selection")
        outputServerLog("[Jebiga] ==========================================")
        return
    end

    local resourceName = resources[currentIndex]
    local resource = getResourceFromName(resourceName)

    if resource then
        if getResourceState(resource) == "running" then
            outputDebugString("[Jebiga] " .. resourceName .. " already running")
            table.insert(startedResources, resourceName)
            startNextResource()
        else
            local success = startResource(resource)
            if success then
                outputDebugString("[Jebiga] Started: " .. resourceName)
                table.insert(startedResources, resourceName)
            else
                outputDebugString("[Jebiga] Failed to start: " .. resourceName, 2)
            end
            -- Continue to next resource after a short delay
            setTimer(startNextResource, 500, 1)
        end
    else
        outputDebugString("[Jebiga] Resource not found: " .. resourceName, 2)
        setTimer(startNextResource, 100, 1)
    end
end

-- Start loading resources when this resource starts
addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog("")
    outputServerLog("╔══════════════════════════════════════════╗")
    outputServerLog("║                                          ║")
    outputServerLog("║       JEBIGA MULTI-GAMEMODE SERVER       ║")
    outputServerLog("║              Version 2.0.0               ║")
    outputServerLog("║                                          ║")
    outputServerLog("║         The Ultimate MTA Experience      ║")
    outputServerLog("║                                          ║")
    outputServerLog("╚══════════════════════════════════════════╝")
    outputServerLog("")
    outputServerLog("[Jebiga] Starting resources...")
    outputServerLog("")

    setTimer(startNextResource, 1000, 1)
end)

-- Stop all resources when this resource stops
addEventHandler("onResourceStop", resourceRoot, function()
    outputServerLog("[Jebiga] Stopping all Jebiga resources...")

    for i = #startedResources, 1, -1 do
        local resourceName = startedResources[i]
        local resource = getResourceFromName(resourceName)
        if resource and getResourceState(resource) == "running" then
            stopResource(resource)
        end
    end
end)

-- Command to reload all resources
addCommandHandler("jebigareload", function(player)
    if player and not hasObjectPermissionTo(player, "command.start") then
        outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou don't have permission to use this command.", player, 255, 255, 255, true)
        return
    end

    outputServerLog("[Jebiga] Reloading all resources...")

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
        outputChatBox("#2980B9[JEBIGA] #FFFFFFReloading all resources...", player, 255, 255, 255, true)
    end
end)

-- Status command
addCommandHandler("jebigastatus", function(player)
    outputChatBox("#2980B9╔═══════════════════════════════╗", player, 255, 255, 255, true)
    outputChatBox("#2980B9║  #FFFFFFJEBIGA MGM STATUS            #2980B9║", player, 255, 255, 255, true)
    outputChatBox("#2980B9╠═══════════════════════════════╣", player, 255, 255, 255, true)

    local running = 0
    for _, name in ipairs(resources) do
        local res = getResourceFromName(name)
        if res and getResourceState(res) == "running" then
            running = running + 1
        end
    end

    outputChatBox("#2980B9║  #95A5A6Resources: #2ECC71" .. running .. "/" .. #resources .. " running       #2980B9║", player, 255, 255, 255, true)
    outputChatBox("#2980B9║  #95A5A6Version:   #FFFFFF2.0.0              #2980B9║", player, 255, 255, 255, true)
    outputChatBox("#2980B9╚═══════════════════════════════╝", player, 255, 255, 255, true)
end)

-- Help command
addCommandHandler("jebigathelp", function(player)
    outputChatBox("#2980B9[JEBIGA] #FFFFFFAvailable Commands:", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /lobby #FFFFFF- Return to lobby", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /maps <gamemode> #FFFFFF- List maps for gamemode", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /jebigastatus #FFFFFF- Server status", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F1 #FFFFFF- Open gamemode selection", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F3 #FFFFFF- Open user panel", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  TAB #FFFFFF- Show scoreboard", player, 255, 255, 255, true)
end)
