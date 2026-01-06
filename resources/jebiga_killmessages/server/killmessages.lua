--[[
    Jebiga Multi-Gamemode - Kill Messages Server
    Broadcasts kills to all players
]]

-- Track kill streaks
local killStreaks = {}
local lastKillTime = {}

-- ============================================
-- KILL DETECTION
-- ============================================

addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart)
    local victim = source
    local victimName = getPlayerName(victim)
    local victimTeam = getPlayerTeam(victim) and getTeamName(getPlayerTeam(victim)) or nil

    local killerName = nil
    local killerTeam = nil

    if killer and killer ~= victim and getElementType(killer) == "player" then
        killerName = getPlayerName(killer)
        killerTeam = getPlayerTeam(killer) and getTeamName(getPlayerTeam(killer)) or nil

        -- Track killer streak
        local serial = getPlayerSerial(killer)
        local now = getTickCount()

        if not killStreaks[serial] then
            killStreaks[serial] = 0
        end

        if not lastKillTime[serial] or now - lastKillTime[serial] < 10000 then
            killStreaks[serial] = killStreaks[serial] + 1
        else
            killStreaks[serial] = 1
        end
        lastKillTime[serial] = now

        -- Announce streaks
        local streak = killStreaks[serial]
        if streak == 3 then
            outputChatBox("#F1C40F[STREAK] #FFFFFF" .. killerName .. " is on a TRIPLE KILL!", root, 255, 255, 255, true)
        elseif streak == 5 then
            outputChatBox("#E67E22[STREAK] #FFFFFF" .. killerName .. " is on a KILLING SPREE!", root, 255, 255, 255, true)
        elseif streak == 10 then
            outputChatBox("#E74C3C[STREAK] #FFFFFF" .. killerName .. " is UNSTOPPABLE!", root, 255, 255, 255, true)
        elseif streak == 15 then
            outputChatBox("#9B59B6[STREAK] #FFFFFF" .. killerName .. " is GODLIKE!", root, 255, 255, 255, true)
        end

        -- Check headshot
        if bodypart == 9 then
            triggerClientEvent(killer, "jebiga:kill:headshot", resourceRoot, victimName)

            -- Bonus points for headshot
            local core = getResourceFromName("jebiga_core")
            if core and getResourceState(core) == "running" then
                exports.jebiga_core:addPlayerPoints(killer, 5)
            end
        end
    end

    -- Reset victim's streak
    local victimSerial = getPlayerSerial(victim)
    if killStreaks[victimSerial] and killStreaks[victimSerial] >= 5 then
        if killerName then
            outputChatBox("#2980B9[STREAK] #FFFFFF" .. killerName .. " ended " .. victimName .. "'s " .. killStreaks[victimSerial] .. " kill streak!", root, 255, 255, 255, true)
        end
    end
    killStreaks[victimSerial] = 0

    -- Broadcast kill
    triggerClientEvent(root, "jebiga:kill:add", resourceRoot, killerName, victimName, weapon, killerTeam, victimTeam)
end)

-- Vehicle kills
addEventHandler("onPlayerVehicleDamage", root, function(attacker, weapon, loss, x, y, z, tire)
    -- Track vehicle damage for potential kill credit
end)

-- ============================================
-- CLEANUP
-- ============================================

addEventHandler("onPlayerQuit", root, function()
    local serial = getPlayerSerial(source)
    killStreaks[serial] = nil
    lastKillTime[serial] = nil
end)

-- ============================================
-- EXPORTS
-- ============================================

function getKillStreak(player)
    local serial = getPlayerSerial(player)
    return killStreaks[serial] or 0
end

function resetKillStreak(player)
    local serial = getPlayerSerial(player)
    killStreaks[serial] = 0
end
