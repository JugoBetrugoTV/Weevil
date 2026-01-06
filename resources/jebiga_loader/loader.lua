--[[
    Jebiga Multi-Gamemode - Resource Loader
    Start this resource to load all Jebiga MGM resources in the correct order

    Usage: Start "jebiga_loader" in the resource manager
]]

local VERSION = "2.6.2"

-- Resources in correct load order (dependencies first)
local loadOrder = {
    -- PHASE 1: Core (MUST start first - database, config, events)
    { name = "jebiga_core", delay = 500, required = true },

    -- PHASE 2: Account System (needs core for database)
    { name = "jebiga_accounts", delay = 500, required = true },

    -- PHASE 3: Map Systems
    { name = "jebiga_maploader", delay = 300 },
    { name = "jebiga_mapmanager", delay = 300 },

    -- PHASE 4: Lobby (needs core config)
    { name = "jebiga_lobby", delay = 500 },

    -- PHASE 5: UI & Support Systems
    { name = "jebiga_scoreboard", delay = 200 },
    { name = "jebiga_toptimes", delay = 200 },
    { name = "jebiga_userpanel", delay = 200 },
    { name = "jebiga_achievements", delay = 200 },
    { name = "jebiga_garage", delay = 200 },
    { name = "jebiga_admin", delay = 200 },

    -- PHASE 6: Features
    { name = "jebiga_neons", delay = 100 },
    { name = "jebiga_tuning", delay = 100 },
    { name = "jebiga_music", delay = 100 },
    { name = "jebiga_clans", delay = 100 },
    { name = "jebiga_chat", delay = 100 },
    { name = "jebiga_killmessages", delay = 100 },
    { name = "jebiga_nametags", delay = 100 },
    { name = "jebiga_racehud", delay = 100 },
    { name = "jebiga_vip", delay = 100 },
    { name = "jebiga_pm", delay = 100 },
    { name = "jebiga_settings", delay = 100 },
    { name = "jebiga_antispam", delay = 100 },

    -- PHASE 7: Gamemodes
    { name = "jebiga_dm", delay = 100 },
    { name = "jebiga_race", delay = 100 },
    { name = "jebiga_dd", delay = 100 },
    { name = "jebiga_hunter", delay = 100 },
    { name = "jebiga_shooter", delay = 100 },
    { name = "jebiga_stuntage", delay = 100 },
    { name = "jebiga_trials", delay = 100 },
    { name = "jebiga_carball", delay = 100 },
    { name = "jebiga_hotpursuit", delay = 100 },
    { name = "jebiga_runarena", delay = 100 },
    { name = "jebiga_training", delay = 100 }
}

local startedResources = {}
local failedResources = {}
local currentIndex = 0
local totalTime = 0

-- Print styled banner
local function printBanner()
    outputServerLog("")
    outputServerLog("========================================================")
    outputServerLog("     _  ____  ____  _  ____    _      __  __  ___  __  __ ")
    outputServerLog("    | || ___|| __ )| |/ ___|  / \\    |  \\/  |/ _ \\|  \\/  |")
    outputServerLog("    | || |_  |  _ \\| | |  _  / _ \\   | |\\/| | | | | |\\/| |")
    outputServerLog(" _  | ||  _| | |_) | | |_| |/ ___ \\  | |  | | |_| | |  | |")
    outputServerLog("(_)_| ||____||____/|_|\\____/_/   \\_\\ |_|  |_|\\___/|_|  |_|")
    outputServerLog("                                                          ")
    outputServerLog("              MULTI-GAMEMODE SERVER v" .. VERSION)
    outputServerLog("           The Ultimate MTA:SA Gaming Experience")
    outputServerLog("========================================================")
    outputServerLog("")
end

-- Start next resource in queue
local function startNextResource()
    currentIndex = currentIndex + 1

    if currentIndex > #loadOrder then
        -- All done!
        outputServerLog("")
        outputServerLog("========================================================")
        outputServerLog("[Jebiga] Loading complete!")
        outputServerLog("[Jebiga] Started: " .. #startedResources .. " resources")
        if #failedResources > 0 then
            outputServerLog("[Jebiga] Failed: " .. #failedResources .. " resources")
            for _, name in ipairs(failedResources) do
                outputServerLog("[Jebiga]   - " .. name)
            end
        end
        outputServerLog("[Jebiga] Total load time: " .. math.floor(totalTime / 1000) .. " seconds")
        outputServerLog("========================================================")
        outputServerLog("")
        outputServerLog("[Jebiga] Server is ready! Press F1 in-game to open gamemode selection.")
        outputServerLog("")
        return
    end

    local entry = loadOrder[currentIndex]
    local resourceName = entry.name
    local delay = entry.delay or 200
    local required = entry.required or false

    local resource = getResourceFromName(resourceName)

    if resource then
        local state = getResourceState(resource)

        if state == "running" then
            outputServerLog("[Jebiga] [" .. currentIndex .. "/" .. #loadOrder .. "] " .. resourceName .. " (already running)")
            table.insert(startedResources, resourceName)
            totalTime = totalTime + 50
            setTimer(startNextResource, 50, 1)
        else
            local success = startResource(resource)

            if success then
                outputServerLog("[Jebiga] [" .. currentIndex .. "/" .. #loadOrder .. "] Started: " .. resourceName)
                table.insert(startedResources, resourceName)
            else
                outputServerLog("[Jebiga] [" .. currentIndex .. "/" .. #loadOrder .. "] FAILED: " .. resourceName)
                table.insert(failedResources, resourceName)

                if required then
                    outputServerLog("[Jebiga] ERROR: Required resource failed to start! Aborting.")
                    return
                end
            end

            totalTime = totalTime + delay
            setTimer(startNextResource, delay, 1)
        end
    else
        outputServerLog("[Jebiga] [" .. currentIndex .. "/" .. #loadOrder .. "] Not found: " .. resourceName)
        table.insert(failedResources, resourceName)

        if required then
            outputServerLog("[Jebiga] ERROR: Required resource not found! Aborting.")
            return
        end

        setTimer(startNextResource, 50, 1)
    end
end

-- Resource start handler
addEventHandler("onResourceStart", resourceRoot, function()
    printBanner()
    outputServerLog("[Jebiga] Starting resource loader...")
    outputServerLog("[Jebiga] Loading " .. #loadOrder .. " resources...")
    outputServerLog("")

    -- Small delay before starting to ensure console is ready
    setTimer(startNextResource, 500, 1)
end)

-- Resource stop handler - stop all Jebiga resources
addEventHandler("onResourceStop", resourceRoot, function()
    outputServerLog("")
    outputServerLog("[Jebiga] Stopping all Jebiga resources...")

    -- Stop in reverse order
    for i = #startedResources, 1, -1 do
        local resourceName = startedResources[i]
        local resource = getResourceFromName(resourceName)

        if resource and getResourceState(resource) == "running" then
            stopResource(resource)
            outputServerLog("[Jebiga] Stopped: " .. resourceName)
        end
    end

    outputServerLog("[Jebiga] All resources stopped.")
    outputServerLog("")
end)

-- Admin command to reload all resources
addCommandHandler("jreload", function(player)
    if player then
        -- Check if player is admin (if player_manager is available)
        local isAdmin = false
        local coreRes = getResourceFromName("jebiga_core")
        if coreRes and getResourceState(coreRes) == "running" then
            local success, result = pcall(function()
                return exports.jebiga_core:isPlayerAdmin(player, 3)
            end)
            isAdmin = success and result
        else
            -- Fallback: check if player has admin rights
            isAdmin = hasObjectPermissionTo(player, "command.start")
        end

        if not isAdmin then
            outputChatBox("#E74C3C[JEBIGA] #FFFFFFYou don't have permission to use this command.", player, 255, 255, 255, true)
            return
        end

        outputChatBox("#2980B9[JEBIGA] #FFFFFFReloading all resources...", player, 255, 255, 255, true)
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

    -- Reset state
    startedResources = {}
    failedResources = {}
    currentIndex = 0
    totalTime = 0

    -- Restart after delay
    setTimer(function()
        printBanner()
        outputServerLog("[Jebiga] Restarting resources...")
        outputServerLog("")
        startNextResource()
    end, 2000, 1)
end)

-- Status command
addCommandHandler("jstatus", function(player)
    if not player then return end

    local running = 0
    local total = #loadOrder

    for _, entry in ipairs(loadOrder) do
        local res = getResourceFromName(entry.name)
        if res and getResourceState(res) == "running" then
            running = running + 1
        end
    end

    outputChatBox(" ", player)
    outputChatBox("#2980B9========================================", player, 255, 255, 255, true)
    outputChatBox("#2980B9  JEBIGA MULTI-GAMEMODE STATUS", player, 255, 255, 255, true)
    outputChatBox("#2980B9========================================", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF  Version:   #2ECC71" .. VERSION, player, 255, 255, 255, true)
    outputChatBox("#FFFFFF  Resources: #2ECC71" .. running .. "/" .. total .. " running", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF  Players:   #2ECC71" .. #getElementsByType("player"), player, 255, 255, 255, true)

    if #failedResources > 0 then
        outputChatBox("#E74C3C  Failed:    " .. #failedResources .. " resources", player, 255, 255, 255, true)
    end

    outputChatBox("#2980B9========================================", player, 255, 255, 255, true)
    outputChatBox(" ", player)
end)

-- Help command
addCommandHandler("jhelp", function(player)
    if not player then return end

    outputChatBox(" ", player)
    outputChatBox("#2980B9[JEBIGA] #FFFFFFCommands:", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /lobby #FFFFFF- Return to lobby", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /jstatus #FFFFFF- Server status", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  /jhelp #FFFFFF- This help", player, 255, 255, 255, true)
    outputChatBox(" ", player)
    outputChatBox("#2980B9[JEBIGA] #FFFFFFKeybinds:", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  F1 #FFFFFF- Gamemode Selection", player, 255, 255, 255, true)
    outputChatBox("#95A5A6  TAB #FFFFFF- Scoreboard", player, 255, 255, 255, true)
    outputChatBox(" ", player)
end)
