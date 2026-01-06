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
    "jebiga_mapmanager",
    "jebiga_scoreboard",
    "jebiga_toptimes",
    "jebiga_userpanel",
    "jebiga_achievements",
    "jebiga_garage",
    "jebiga_admin",

    -- Vultaic-inspired features
    "jebiga_neons",
    "jebiga_tuning",
    "jebiga_music",
    "jebiga_clans",

    -- Additional features
    "jebiga_chat",
    "jebiga_killmessages",
    "jebiga_nametags",
    "jebiga_racehud",
    "jebiga_vip",
    "jebiga_pm",
    "jebiga_settings",
    "jebiga_antispam",

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
    outputServerLog("║              Version 2.3.0               ║")
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
    outputChatBox("#2980B9║  #95A5A6Version:   #FFFFFF2.3.0              #2980B9║", player, 255, 255, 255, true)
    outputChatBox("#2980B9╚═══════════════════════════════╝", player, 255, 255, 255, true)
end)

-- Help command
addCommandHandler("jebigahelp", function(player)
    outputChatBox("#2980B9[JEBIGA] #FFFFFFCommands:", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /lobby #FFFFFF- Lobby | #95A5A6/rtv #FFFFFF- Rock the vote", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /neon #FFFFFF- Neons | #95A5A6/tuning #FFFFFF- Tuning | #95A5A6/music #FFFFFF- Music", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /clan #FFFFFF- Clan | #95A5A6/cc <msg> #FFFFFF- Clan chat", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /pm <player> <msg> #FFFFFF- PM | #95A5A6/r <msg> #FFFFFF- Reply", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /vip #FFFFFF- VIP info | #95A5A6/settings #FFFFFF- Settings", player, 255, 255, 255, true)
    outputChatBox("#2980B9[JEBIGA] #FFFFFFKeybinds:", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F1 #FFFFFF- Lobby | #95A5A6F2 #FFFFFF- Vote | #95A5A6F3 #FFFFFF- User panel", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F6 #FFFFFF- Tuning | #95A5A6F7 #FFFFFF- HUD | #95A5A6F8 #FFFFFF- Music | #95A5A6F9 #FFFFFF- Clan", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F10 #FFFFFF- Settings | #95A5A6N #FFFFFF- Neons | #95A5A6TAB #FFFFFF- Scoreboard", player, 255, 255, 255, true)
end)
