--[[
    Jebiga Multi-Gamemode - Server Commands
    Chat and console commands for players and admins
]]

-- Player Commands

-- Help command
addCommandHandler("help", function(player)
    outputChatBox("#FF6600=== Jebiga Gaming Commands ===", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/lobby - Return to lobby", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/join [gamemode] - Join a gamemode", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/leave - Leave current gamemode", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/stats [player] - View player stats", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/profile - Open your profile", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/balance - Check your balance", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/pay [player] [amount] - Send money", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/daily - Claim daily bonus", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/top [money/dm/race/etc] - View leaderboards", player, 255, 255, 255, true)
    outputChatBox("#FFFFFF/pm [player] [message] - Private message", player, 255, 255, 255, true)
end)

-- Lobby command
addCommandHandler("lobby", function(player)
    local gamemode = getCurrentGamemode(player)
    if gamemode then
        removePlayerFromArena(player, gamemode)
    end
    teleportToLobby(player)
    outputChatBox("#00FF00[Jebiga] #FFFFFFYou returned to the lobby.", player, 255, 255, 255, true)
end)

-- Join gamemode command
addCommandHandler("join", function(player, cmd, gamemodeArg)
    if not gamemodeArg then
        outputChatBox("Usage: /join [dm/race/dd/hunter/shooter/stuntage/trials/carball/hp/run/training]", player, 255, 200, 0)
        return
    end

    local gamemode = gamemodeArg:lower()

    -- Handle aliases
    local aliases = {
        ["hp"] = "hotpursuit",
        ["run"] = "runarena",
        ["train"] = "training",
        ["stunt"] = "stuntage"
    }

    if aliases[gamemode] then
        gamemode = aliases[gamemode]
    end

    if not Config.Gamemodes[gamemode] then
        outputChatBox("Invalid gamemode. Available: dm, race, dd, hunter, shooter, stuntage, trials, carball, hp, run, training", player, 255, 0, 0)
        return
    end

    if not Config.Gamemodes[gamemode].enabled then
        outputChatBox("This gamemode is currently disabled.", player, 255, 0, 0)
        return
    end

    addPlayerToArena(player, gamemode)
end)

-- Leave gamemode command
addCommandHandler("leave", function(player)
    local gamemode = getCurrentGamemode(player)
    if not gamemode then
        outputChatBox("You are not in any gamemode.", player, 255, 200, 0)
        return
    end

    removePlayerFromArena(player, gamemode)
    outputChatBox("#00FF00[Jebiga] #FFFFFFYou left " .. Config.Gamemodes[gamemode].name .. ".", player, 255, 255, 255, true)
end)

-- Stats command
addCommandHandler("stats", function(player, cmd, targetName)
    local target = player
    if targetName then
        target = getPlayerFromPartialName(targetName)
        if not target then
            outputChatBox("Player not found.", player, 255, 0, 0)
            return
        end
    end

    local data = getCachedPlayerData(target)
    if not data then
        outputChatBox("Player data not available.", player, 255, 0, 0)
        return
    end

    outputChatBox("#FFFF00=== Stats for " .. getPlayerName(target) .. " ===", player, 255, 255, 255, true)
    outputChatBox("#FFFFFFTotal Points: " .. Utils.formatNumber(data.totalPoints), player, 255, 255, 255, true)
    outputChatBox("#FFFFFFMoney: $" .. Utils.formatNumber(data.money), player, 255, 255, 255, true)
    outputChatBox("#FFFFFFPlaytime: " .. Utils.formatTimeLong(data.playtime * 1000), player, 255, 255, 255, true)
    outputChatBox("#FFFFFFRank: " .. Utils.calculateRank(data.totalPoints).name, player, 255, 255, 255, true)

    -- Show gamemode stats
    if data.stats then
        local totalWins = 0
        local totalKills = 0
        local totalDeaths = 0

        for _, stats in pairs(data.stats) do
            totalWins = totalWins + (stats.wins or 0)
            totalKills = totalKills + (stats.kills or 0)
            totalDeaths = totalDeaths + (stats.deaths or 0)
        end

        outputChatBox("#FFFFFFTotal Wins: " .. totalWins, player, 255, 255, 255, true)
        outputChatBox("#FFFFFFTotal K/D: " .. totalKills .. "/" .. totalDeaths, player, 255, 255, 255, true)
    end
end)

-- Profile command
addCommandHandler("profile", function(player)
    triggerClientEvent(player, Events.UserPanel.OPEN, player)
end)

-- Private message command
addCommandHandler("pm", function(player, cmd, targetName, ...)
    if not targetName then
        outputChatBox("Usage: /pm [player] [message]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    if target == player then
        outputChatBox("You cannot PM yourself.", player, 255, 0, 0)
        return
    end

    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("Usage: /pm [player] [message]", player, 255, 200, 0)
        return
    end

    outputChatBox("#FF00FF[PM to " .. getPlayerName(target) .. "] #FFFFFF" .. message, player, 255, 255, 255, true)
    outputChatBox("#FF00FF[PM from " .. getPlayerName(player) .. "] #FFFFFF" .. message, target, 255, 255, 255, true)

    -- Play sound for recipient
    triggerClientEvent(target, "weevil:playSound", target, "pm")
end)

-- Reply to last PM
local lastPM = {}
addCommandHandler("r", function(player, cmd, ...)
    if not lastPM[player] or not isElement(lastPM[player]) then
        outputChatBox("No one to reply to.", player, 255, 0, 0)
        return
    end

    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("Usage: /r [message]", player, 255, 200, 0)
        return
    end

    local target = lastPM[player]
    outputChatBox("#FF00FF[PM to " .. getPlayerName(target) .. "] #FFFFFF" .. message, player, 255, 255, 255, true)
    outputChatBox("#FF00FF[PM from " .. getPlayerName(player) .. "] #FFFFFF" .. message, target, 255, 255, 255, true)
end)

-- Players command
addCommandHandler("players", function(player)
    local players = getOnlinePlayers()

    outputChatBox("#FFFF00=== Online Players (" .. #players .. ") ===", player, 255, 255, 255, true)

    local lobbyPlayers = {}
    local gamemodePlayers = {}

    for _, p in ipairs(players) do
        if p.gamemode then
            if not gamemodePlayers[p.gamemode] then
                gamemodePlayers[p.gamemode] = {}
            end
            table.insert(gamemodePlayers[p.gamemode], p.name)
        else
            table.insert(lobbyPlayers, p.name)
        end
    end

    if #lobbyPlayers > 0 then
        outputChatBox("#FFFFFFLobby: " .. table.concat(lobbyPlayers, ", "), player, 255, 255, 255, true)
    end

    for gamemode, names in pairs(gamemodePlayers) do
        local cfg = Config.Gamemodes[gamemode]
        local gmName = cfg and cfg.shortName or gamemode
        outputChatBox("#FFFFFF" .. gmName .. ": " .. table.concat(names, ", "), player, 255, 255, 255, true)
    end
end)

-- Admin Commands

-- Kick command
addCommandHandler("kick", function(player, cmd, targetName, ...)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /kick [player] [reason]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local reason = table.concat({...}, " ")
    if reason == "" then reason = "No reason specified" end

    kickPlayer(target, player, reason)
    broadcastMessage("#FF0000[Admin] #FFFFFF" .. getPlayerName(target) .. " was kicked by " .. getPlayerName(player) .. " (" .. reason .. ")")

    -- Log admin action
    logAdminAction(player, "kick", target, reason)
end)

-- Ban command
addCommandHandler("ban", function(player, cmd, targetName, duration, ...)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /ban [player] [duration:hours/perm] [reason]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local reason = table.concat({...}, " ")
    if reason == "" then reason = "No reason specified" end

    local banDuration = nil
    if duration and duration ~= "perm" then
        banDuration = tonumber(duration)
    end

    banPlayer(target, player, reason, banDuration)
    broadcastMessage("#FF0000[Admin] #FFFFFF" .. getPlayerName(target) .. " was banned by " .. getPlayerName(player) .. " (" .. reason .. ")")

    -- Log admin action
    logAdminAction(player, "ban", target, reason .. " (Duration: " .. (banDuration or "permanent") .. ")")
end)

-- Mute command
addCommandHandler("mute", function(player, cmd, targetName, duration)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /mute [player] [duration:minutes]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local muteDuration = tonumber(duration) or 10

    local data = getCachedPlayerData(target)
    if data then
        data.muted = true
        local now = getRealTime().timestamp
        data.muteExpires = now + (muteDuration * 60)

        outputChatBox("#FF0000[Admin] #FFFFFFYou have been muted for " .. muteDuration .. " minutes.", target, 255, 255, 255, true)
        outputChatBox("#00FF00[Admin] #FFFFFFYou muted " .. getPlayerName(target) .. " for " .. muteDuration .. " minutes.", player, 255, 255, 255, true)

        logAdminAction(player, "mute", target, muteDuration .. " minutes")
    end
end)

-- Unmute command
addCommandHandler("unmute", function(player, cmd, targetName)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /unmute [player]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local data = getCachedPlayerData(target)
    if data then
        data.muted = false
        data.muteExpires = nil

        outputChatBox("#00FF00[Admin] #FFFFFFYou have been unmuted.", target, 255, 255, 255, true)
        outputChatBox("#00FF00[Admin] #FFFFFFYou unmuted " .. getPlayerName(target) .. ".", player, 255, 255, 255, true)

        logAdminAction(player, "unmute", target, "")
    end
end)

-- Give money command
addCommandHandler("givemoney", function(player, cmd, targetName, amountStr)
    if not isPlayerAdmin(player, 3) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName or not amountStr then
        outputChatBox("Usage: /givemoney [player] [amount]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        outputChatBox("Invalid amount.", player, 255, 0, 0)
        return
    end

    giveMoney(target, amount, "Admin grant by " .. getPlayerName(player))
    outputChatBox("#00FF00[Admin] #FFFFFFYou gave $" .. Utils.formatNumber(amount) .. " to " .. getPlayerName(target), player, 255, 255, 255, true)

    logAdminAction(player, "givemoney", target, "$" .. amount)
end)

-- Give points command
addCommandHandler("givepoints", function(player, cmd, targetName, amountStr, gamemode)
    if not isPlayerAdmin(player, 3) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName or not amountStr then
        outputChatBox("Usage: /givepoints [player] [amount] [gamemode]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        outputChatBox("Invalid amount.", player, 255, 0, 0)
        return
    end

    givePoints(target, amount, gamemode, "Admin grant")
    outputChatBox("#00FF00[Admin] #FFFFFFYou gave " .. Utils.formatNumber(amount) .. " points to " .. getPlayerName(target), player, 255, 255, 255, true)

    logAdminAction(player, "givepoints", target, amount .. " points" .. (gamemode and (" (" .. gamemode .. ")") or ""))
end)

-- Set admin command
addCommandHandler("setadmin", function(player, cmd, targetName, levelStr)
    if not isPlayerAdmin(player, 4) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName or not levelStr then
        outputChatBox("Usage: /setadmin [player] [level:0-4]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local level = tonumber(levelStr)
    if not level or level < 0 or level > 4 then
        outputChatBox("Level must be between 0 and 4.", player, 255, 0, 0)
        return
    end

    local data = getCachedPlayerData(target)
    if data then
        data.adminLevel = level

        -- Update database (use execute function from database module)
        execute("UPDATE accounts SET admin_level = ? WHERE id = ?", level, data.accountId)

        local levelName = level > 0 and Config.AdminLevels[level].name or "Player"
        outputChatBox("#00FF00[Admin] #FFFFFFYou set " .. getPlayerName(target) .. " to " .. levelName, player, 255, 255, 255, true)
        outputChatBox("#00FF00[Admin] #FFFFFFYour admin level has been set to " .. levelName, target, 255, 255, 255, true)

        logAdminAction(player, "setadmin", target, "Level " .. level)
    end
end)

-- Announce command
addCommandHandler("announce", function(player, cmd, ...)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("Usage: /announce [message]", player, 255, 200, 0)
        return
    end

    broadcastMessage("#FF6600[Announcement] #FFFFFF" .. message)

    -- Trigger client notification
    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, Events.Notification.SHOW, p, {
            type = "info",
            title = "Announcement",
            message = message,
            duration = 10000
        })
    end
end)

-- Teleport command
addCommandHandler("tp", function(player, cmd, targetName)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /tp [player]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local x, y, z = getElementPosition(target)
    local dim = getElementDimension(target)
    local int = getElementInterior(target)

    setElementPosition(player, x + 2, y, z)
    setElementDimension(player, dim)
    setElementInterior(player, int)

    outputChatBox("#00FF00[Admin] #FFFFFFTeleported to " .. getPlayerName(target), player, 255, 255, 255, true)
end)

-- Bring command
addCommandHandler("bring", function(player, cmd, targetName)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Usage: /bring [player]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    local x, y, z = getElementPosition(player)
    local dim = getElementDimension(player)
    local int = getElementInterior(player)

    setElementPosition(target, x + 2, y, z)
    setElementDimension(target, dim)
    setElementInterior(target, int)

    outputChatBox("#00FF00[Admin] #FFFFFFYou brought " .. getPlayerName(target), player, 255, 255, 255, true)
    outputChatBox("#00FF00[Admin] #FFFFFFYou were brought to " .. getPlayerName(player), target, 255, 255, 255, true)
end)

-- Log admin action
function logAdminAction(admin, action, target, details)
    local adminData = getCachedPlayerData(admin)
    local targetData = target and getCachedPlayerData(target)

    execute([[
        INSERT INTO admin_log (admin_id, action, target_id, details)
        VALUES (?, ?, ?, ?)
    ]],
        adminData and adminData.accountId or 0,
        action,
        targetData and targetData.accountId or nil,
        details
    )
end

-- Ban player helper
function banPlayer(player, admin, reason, hours)
    local data = getCachedPlayerData(player)
    if not data then return false end

    local banExpires = nil
    if hours then
        local now = getRealTime().timestamp
        banExpires = now + (hours * 3600)
    end

    execute([[
        UPDATE accounts SET banned = 1, ban_reason = ?, ban_expires = ?
        WHERE id = ?
    ]], reason, banExpires and os.date("%Y-%m-%d %H:%M:%S", banExpires) or nil, data.accountId)

    kickPlayer(player, admin, "Banned: " .. reason)

    return true
end

-- Chat handler (check mute)
addEventHandler("onPlayerChat", root, function(message, messageType)
    local player = source

    local data = getCachedPlayerData(player)
    if data and data.muted then
        local now = getRealTime().timestamp
        if data.muteExpires and data.muteExpires > now then
            cancelEvent()
            local remaining = math.ceil((data.muteExpires - now) / 60)
            outputChatBox("#FF0000[Muted] #FFFFFFYou are muted for " .. remaining .. " more minutes.", player, 255, 255, 255, true)
        else
            data.muted = false
            data.muteExpires = nil
        end
    end
end)
