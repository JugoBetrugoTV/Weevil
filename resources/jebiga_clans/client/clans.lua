--[[
    Jebiga Multi-Gamemode - Clan System
    Inspired by Vultaic MGM
    Features: Create clans, manage members, clan chat, clan tags
]]

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 1080

-- Clan GUI state
local clanPanelOpen = false
local panelAlpha = 0
local currentTab = 1
local scrollOffset = 0

-- Clan data (synced from server)
local myClan = nil
local clanMembers = {}
local clanInvites = {}
local allClans = {}

-- Tabs
local tabs = {
    { name = "My Clan", icon = "🏠" },
    { name = "Members", icon = "👥" },
    { name = "Invites", icon = "📩" },
    { name = "Browse", icon = "🔍" },
    { name = "Create", icon = "➕" }
}

-- Create clan form
local createForm = {
    name = "",
    tag = "",
    color = {41, 128, 185},
    activeField = nil
}

-- ============================================
-- CLAN GUI
-- ============================================

function openClanPanel()
    clanPanelOpen = true
    showCursor(true)
    requestClanData()
end

function closeClanPanel()
    clanPanelOpen = false
    showCursor(false)
end

function requestClanData()
    triggerServerEvent("jebiga:clans:getData", localPlayer)
end

function renderClanPanel()
    if not clanPanelOpen then
        if panelAlpha > 0 then panelAlpha = panelAlpha - 20 end
        if panelAlpha <= 0 then return end
    else
        if panelAlpha < 255 then panelAlpha = panelAlpha + 20 end
    end

    local panelW = 650 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Main background
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(15, 17, 23, panelAlpha * 0.97))

    -- Header
    dxDrawRectangle(panelX, panelY, panelW, 60 * scale, tocolor(25, 28, 35, panelAlpha))
    dxDrawRectangle(panelX, panelY + 57 * scale, panelW, 3, tocolor(46, 204, 113, panelAlpha))
    dxDrawText("⚔️ CLAN SYSTEM", panelX, panelY, panelX + panelW, panelY + 60 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.4 * scale, "default-bold", "center", "center")

    -- Tabs
    local tabW = panelW / #tabs
    local tabY = panelY + 65 * scale
    local tabH = 40 * scale

    for i, tab in ipairs(tabs) do
        local tabX = panelX + (i - 1) * tabW
        local isSelected = currentTab == i

        local bgColor = isSelected and tocolor(46, 204, 113, panelAlpha * 0.3) or tocolor(25, 28, 35, panelAlpha * 0.5)
        dxDrawRectangle(tabX, tabY, tabW, tabH, bgColor)

        if isSelected then
            dxDrawRectangle(tabX, tabY + tabH - 3, tabW, 3, tocolor(46, 204, 113, panelAlpha))
        end

        dxDrawText(tab.icon .. " " .. tab.name, tabX, tabY, tabX + tabW, tabY + tabH,
            tocolor(255, 255, 255, panelAlpha * (isSelected and 1 or 0.7)), 0.85 * scale, "default-bold", "center", "center")
    end

    -- Content area
    local contentX = panelX + 15 * scale
    local contentY = tabY + tabH + 15 * scale
    local contentW = panelW - 30 * scale
    local contentH = panelH - 150 * scale

    -- Render current tab content
    if currentTab == 1 then
        renderMyClan(contentX, contentY, contentW, contentH)
    elseif currentTab == 2 then
        renderMembers(contentX, contentY, contentW, contentH)
    elseif currentTab == 3 then
        renderInvites(contentX, contentY, contentW, contentH)
    elseif currentTab == 4 then
        renderBrowse(contentX, contentY, contentW, contentH)
    elseif currentTab == 5 then
        renderCreate(contentX, contentY, contentW, contentH)
    end

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    dxDrawRectangle(closeX, closeY, 25 * scale, 25 * scale, tocolor(231, 76, 60, panelAlpha * 0.8))
    dxDrawText("X", closeX, closeY, closeX + 25 * scale, closeY + 25 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")
end

function renderMyClan(x, y, w, h)
    if not myClan then
        -- No clan
        dxDrawRectangle(x, y, w, h, tocolor(25, 28, 35, panelAlpha * 0.5))
        dxDrawText("You are not in a clan!", x, y, x + w, y + h * 0.4,
            tocolor(150, 150, 150, panelAlpha), 1.2 * scale, "default-bold", "center", "center")
        dxDrawText("Join an existing clan or create your own.", x, y + h * 0.35, x + w, y + h * 0.5,
            tocolor(100, 100, 100, panelAlpha), 0.9 * scale, "default", "center", "center")

        -- Quick action buttons
        local btnW = 150 * scale
        local btnH = 40 * scale
        local btnY = y + h * 0.6

        dxDrawRectangle(x + w/2 - btnW - 20, btnY, btnW, btnH, tocolor(41, 128, 185, panelAlpha * 0.8))
        dxDrawText("Browse Clans", x + w/2 - btnW - 20, btnY, x + w/2 - 20, btnY + btnH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "center", "center")

        dxDrawRectangle(x + w/2 + 20, btnY, btnW, btnH, tocolor(46, 204, 113, panelAlpha * 0.8))
        dxDrawText("Create Clan", x + w/2 + 20, btnY, x + w/2 + btnW + 20, btnY + btnH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "center", "center")
        return
    end

    -- Clan info card
    dxDrawRectangle(x, y, w, 100 * scale, tocolor(25, 28, 35, panelAlpha * 0.8))

    -- Clan tag and name
    local clanColor = myClan.color or {46, 204, 113}
    dxDrawText("[" .. (myClan.tag or "???") .. "]", x + 15, y + 10, x + w - 15, y + 40 * scale,
        tocolor(clanColor[1], clanColor[2], clanColor[3], panelAlpha), 1.5 * scale, "default-bold", "left", "center")

    dxDrawText(myClan.name or "Unknown Clan", x + 15, y + 40, x + w - 15, y + 70 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.2 * scale, "default-bold", "left", "center")

    -- Stats
    local statsY = y + 75 * scale
    dxDrawText("Members: " .. (myClan.memberCount or 0) .. " | Rank: " .. (myClan.myRank or "Member"),
        x + 15, statsY, x + w - 15, statsY + 20 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.85 * scale, "default", "left", "center")

    -- Actions
    local actionsY = y + 115 * scale
    dxDrawText("ACTIONS", x, actionsY, x + w, actionsY + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    local btnH = 35 * scale
    local btnY = actionsY + 30 * scale

    -- Leave clan button
    dxDrawRectangle(x, btnY, 150 * scale, btnH, tocolor(231, 76, 60, panelAlpha * 0.7))
    dxDrawText("Leave Clan", x, btnY, x + 150 * scale, btnY + btnH,
        tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "center", "center")

    -- Clan chat hint
    local chatY = btnY + btnH + 20 * scale
    dxDrawText("Use /cc [message] to chat with your clan", x, chatY, x + w, chatY + 25 * scale,
        tocolor(100, 100, 100, panelAlpha), 0.8 * scale, "default", "left", "center")
end

function renderMembers(x, y, w, h)
    if not myClan then
        dxDrawText("Join a clan to see members!", x, y, x + w, y + h,
            tocolor(150, 150, 150, panelAlpha), 1.0 * scale, "default", "center", "center")
        return
    end

    dxDrawText("CLAN MEMBERS (" .. #clanMembers .. ")", x, y, x + w, y + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    local memberH = 40 * scale
    local startY = y + 35 * scale

    for i, member in ipairs(clanMembers) do
        local my = startY + (i - 1) * (memberH + 5)
        if my + memberH > y + h then break end

        local isOnline = member.online
        dxDrawRectangle(x, my, w, memberH, tocolor(30, 33, 42, panelAlpha * 0.7))

        -- Online indicator
        local statusColor = isOnline and tocolor(46, 204, 113, panelAlpha) or tocolor(150, 150, 150, panelAlpha)
        dxDrawRectangle(x + 10, my + memberH/2 - 5, 10, 10, statusColor)

        -- Name and rank
        dxDrawText(member.name or "Unknown", x + 30, my, x + w * 0.5, my + memberH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        dxDrawText(member.rank or "Member", x + w * 0.5, my, x + w - 80, my + memberH,
            tocolor(155, 89, 182, panelAlpha), 0.8 * scale, "default", "left", "center")

        -- Kick button (if leader)
        if myClan.myRank == "Leader" and member.name ~= getPlayerName(localPlayer) then
            dxDrawRectangle(x + w - 70, my + 5, 60, memberH - 10, tocolor(231, 76, 60, panelAlpha * 0.6))
            dxDrawText("Kick", x + w - 70, my + 5, x + w - 10, my + memberH - 5,
                tocolor(255, 255, 255, panelAlpha), 0.75 * scale, "default-bold", "center", "center")
        end
    end
end

function renderInvites(x, y, w, h)
    dxDrawText("CLAN INVITES", x, y, x + w, y + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    if #clanInvites == 0 then
        dxDrawText("No pending invites", x, y + 40 * scale, x + w, y + h,
            tocolor(100, 100, 100, panelAlpha), 0.9 * scale, "default", "center", "top")
        return
    end

    local inviteH = 50 * scale
    local startY = y + 35 * scale

    for i, invite in ipairs(clanInvites) do
        local iy = startY + (i - 1) * (inviteH + 5)
        if iy + inviteH > y + h then break end

        dxDrawRectangle(x, iy, w, inviteH, tocolor(30, 33, 42, panelAlpha * 0.7))

        -- Clan name
        dxDrawText("[" .. (invite.tag or "?") .. "] " .. (invite.name or "Unknown"),
            x + 15, iy, x + w * 0.5, iy + inviteH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        -- Accept/Decline buttons
        local btnW = 70 * scale
        dxDrawRectangle(x + w - btnW * 2 - 20, iy + 10, btnW, inviteH - 20, tocolor(46, 204, 113, panelAlpha * 0.7))
        dxDrawText("Accept", x + w - btnW * 2 - 20, iy + 10, x + w - btnW - 20, iy + inviteH - 10,
            tocolor(255, 255, 255, panelAlpha), 0.8 * scale, "default-bold", "center", "center")

        dxDrawRectangle(x + w - btnW - 10, iy + 10, btnW, inviteH - 20, tocolor(231, 76, 60, panelAlpha * 0.7))
        dxDrawText("Decline", x + w - btnW - 10, iy + 10, x + w - 10, iy + inviteH - 10,
            tocolor(255, 255, 255, panelAlpha), 0.8 * scale, "default-bold", "center", "center")
    end
end

function renderBrowse(x, y, w, h)
    dxDrawText("BROWSE CLANS", x, y, x + w, y + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    if #allClans == 0 then
        dxDrawText("No clans found", x, y + 40 * scale, x + w, y + h,
            tocolor(100, 100, 100, panelAlpha), 0.9 * scale, "default", "center", "top")
        return
    end

    local clanH = 50 * scale
    local startY = y + 35 * scale

    for i, clan in ipairs(allClans) do
        local cy = startY + (i - 1) * (clanH + 5)
        if cy + clanH > y + h then break end

        dxDrawRectangle(x, cy, w, clanH, tocolor(30, 33, 42, panelAlpha * 0.7))

        -- Clan info
        local clanColor = clan.color or {46, 204, 113}
        dxDrawText("[" .. (clan.tag or "?") .. "]", x + 15, cy, x + 80, cy + clanH,
            tocolor(clanColor[1], clanColor[2], clanColor[3], panelAlpha), 1.0 * scale, "default-bold", "left", "center")

        dxDrawText(clan.name or "Unknown", x + 85, cy, x + w * 0.5, cy + clanH,
            tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

        dxDrawText(clan.memberCount .. " members", x + w * 0.5, cy, x + w - 100, cy + clanH,
            tocolor(150, 150, 150, panelAlpha), 0.8 * scale, "default", "left", "center")

        -- Request join button
        if not myClan then
            dxDrawRectangle(x + w - 90, cy + 10, 80, clanH - 20, tocolor(41, 128, 185, panelAlpha * 0.7))
            dxDrawText("Join", x + w - 90, cy + 10, x + w - 10, cy + clanH - 10,
                tocolor(255, 255, 255, panelAlpha), 0.85 * scale, "default-bold", "center", "center")
        end
    end
end

function renderCreate(x, y, w, h)
    if myClan then
        dxDrawText("You are already in a clan!", x, y, x + w, y + h,
            tocolor(150, 150, 150, panelAlpha), 1.0 * scale, "default", "center", "center")
        return
    end

    dxDrawText("CREATE NEW CLAN", x, y, x + w, y + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.9 * scale, "default-bold", "left", "center")

    local fieldY = y + 40 * scale
    local fieldH = 40 * scale
    local fieldW = w * 0.7

    -- Clan Name field
    dxDrawText("Clan Name:", x, fieldY, x + 100, fieldY + fieldH,
        tocolor(200, 200, 200, panelAlpha), 0.85 * scale, "default", "left", "center")

    local nameBg = createForm.activeField == "name" and tocolor(40, 45, 60, panelAlpha) or tocolor(30, 33, 42, panelAlpha)
    dxDrawRectangle(x + 110, fieldY + 5, fieldW, fieldH - 10, nameBg)
    dxDrawText(createForm.name .. (createForm.activeField == "name" and "|" or ""),
        x + 120, fieldY + 5, x + 110 + fieldW - 10, fieldY + fieldH - 5,
        tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default", "left", "center")

    -- Clan Tag field
    fieldY = fieldY + fieldH + 15
    dxDrawText("Clan Tag:", x, fieldY, x + 100, fieldY + fieldH,
        tocolor(200, 200, 200, panelAlpha), 0.85 * scale, "default", "left", "center")

    local tagBg = createForm.activeField == "tag" and tocolor(40, 45, 60, panelAlpha) or tocolor(30, 33, 42, panelAlpha)
    dxDrawRectangle(x + 110, fieldY + 5, 100 * scale, fieldH - 10, tagBg)
    dxDrawText(createForm.tag .. (createForm.activeField == "tag" and "|" or ""),
        x + 120, fieldY + 5, x + 200, fieldY + fieldH - 5,
        tocolor(255, 255, 255, panelAlpha), 0.9 * scale, "default", "left", "center")

    dxDrawText("(Max 4 chars)", x + 220, fieldY, x + w, fieldY + fieldH,
        tocolor(100, 100, 100, panelAlpha), 0.75 * scale, "default", "left", "center")

    -- Preview
    fieldY = fieldY + fieldH + 30
    dxDrawText("Preview:", x, fieldY, x + w, fieldY + 25 * scale,
        tocolor(150, 150, 150, panelAlpha), 0.85 * scale, "default", "left", "center")

    dxDrawRectangle(x, fieldY + 30, w, 50 * scale, tocolor(25, 28, 35, panelAlpha * 0.8))
    local previewText = "[" .. (createForm.tag ~= "" and createForm.tag or "TAG") .. "] " .. (createForm.name ~= "" and createForm.name or "Clan Name")
    dxDrawText(previewText, x + 15, fieldY + 30, x + w - 15, fieldY + 80,
        tocolor(createForm.color[1], createForm.color[2], createForm.color[3], panelAlpha), 1.1 * scale, "default-bold", "left", "center")

    -- Create button
    local btnY = fieldY + 100 * scale
    dxDrawRectangle(x + w/2 - 100, btnY, 200, 45 * scale, tocolor(46, 204, 113, panelAlpha * 0.8))
    dxDrawText("CREATE CLAN", x + w/2 - 100, btnY, x + w/2 + 100, btnY + 45 * scale,
        tocolor(255, 255, 255, panelAlpha), 1.0 * scale, "default-bold", "center", "center")

    -- Cost info
    dxDrawText("Cost: $10,000", x, btnY + 55 * scale, x + w, btnY + 75 * scale,
        tocolor(241, 196, 15, panelAlpha), 0.85 * scale, "default", "center", "center")
end

-- ============================================
-- INPUT HANDLING
-- ============================================

function handleClanClick(button, state, absX, absY)
    if not clanPanelOpen or button ~= "left" or state ~= "down" then return end

    local panelW = 650 * scale
    local panelH = 500 * scale
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Close button
    local closeX = panelX + panelW - 35 * scale
    local closeY = panelY + 10 * scale
    if absX >= closeX and absX <= closeX + 25 * scale and absY >= closeY and absY <= closeY + 25 * scale then
        closeClanPanel()
        return
    end

    -- Tab clicks
    local tabW = panelW / #tabs
    local tabY = panelY + 65 * scale
    local tabH = 40 * scale

    for i = 1, #tabs do
        local tabX = panelX + (i - 1) * tabW
        if absX >= tabX and absX <= tabX + tabW and absY >= tabY and absY <= tabY + tabH then
            currentTab = i
            scrollOffset = 0
            playSoundFrontEnd(37)
            return
        end
    end

    -- Content area
    local contentX = panelX + 15 * scale
    local contentY = tabY + tabH + 15 * scale
    local contentW = panelW - 30 * scale
    local contentH = panelH - 150 * scale

    -- Tab-specific clicks
    if currentTab == 5 then -- Create tab
        handleCreateClicks(absX, absY, contentX, contentY, contentW)
    elseif currentTab == 1 and not myClan then -- My Clan (no clan) buttons
        handleNoClanClicks(absX, absY, contentX, contentY, contentW, contentH)
    end
end

function handleCreateClicks(absX, absY, x, y, w)
    local fieldY = y + 40 * scale
    local fieldH = 40 * scale
    local fieldW = w * 0.7

    -- Name field click
    if absX >= x + 110 and absX <= x + 110 + fieldW and absY >= fieldY + 5 and absY <= fieldY + fieldH - 5 then
        createForm.activeField = "name"
        return
    end

    -- Tag field click
    fieldY = fieldY + fieldH + 15
    if absX >= x + 110 and absX <= x + 210 and absY >= fieldY + 5 and absY <= fieldY + fieldH - 5 then
        createForm.activeField = "tag"
        return
    end

    -- Create button click
    local btnY = fieldY + fieldH + 130 * scale
    if absX >= x + w/2 - 100 and absX <= x + w/2 + 100 and absY >= btnY and absY <= btnY + 45 * scale then
        createClan()
        return
    end

    createForm.activeField = nil
end

function handleNoClanClicks(absX, absY, x, y, w, h)
    local btnW = 150 * scale
    local btnH = 40 * scale
    local btnY = y + h * 0.6

    -- Browse button
    if absX >= x + w/2 - btnW - 20 and absX <= x + w/2 - 20 and absY >= btnY and absY <= btnY + btnH then
        currentTab = 4
        playSoundFrontEnd(37)
        return
    end

    -- Create button
    if absX >= x + w/2 + 20 and absX <= x + w/2 + btnW + 20 and absY >= btnY and absY <= btnY + btnH then
        currentTab = 5
        playSoundFrontEnd(37)
        return
    end
end

function handleClanKey(button, press)
    if not clanPanelOpen then return end
    if not press then return end

    if button == "escape" then
        if createForm.activeField then
            createForm.activeField = nil
        else
            closeClanPanel()
        end
        return
    end

    -- Text input for create form
    if createForm.activeField then
        if button == "backspace" then
            if createForm.activeField == "name" then
                createForm.name = createForm.name:sub(1, -2)
            elseif createForm.activeField == "tag" then
                createForm.tag = createForm.tag:sub(1, -2)
            end
        end
    end
end

function handleClanChar(char)
    if not clanPanelOpen or not createForm.activeField then return end

    if createForm.activeField == "name" and #createForm.name < 20 then
        createForm.name = createForm.name .. char
    elseif createForm.activeField == "tag" and #createForm.tag < 4 then
        createForm.tag = createForm.tag:upper() .. char:upper()
    end
end

-- ============================================
-- CLAN ACTIONS
-- ============================================

function createClan()
    if createForm.name == "" or createForm.tag == "" then
        exports.jebiga_core:showNotification("Please fill in all fields!", "error")
        return
    end

    if #createForm.tag > 4 then
        exports.jebiga_core:showNotification("Tag must be 4 characters or less!", "error")
        return
    end

    triggerServerEvent("jebiga:clans:create", localPlayer, createForm.name, createForm.tag)
    playSoundFrontEnd(40)
end

function leaveClan()
    triggerServerEvent("jebiga:clans:leave", localPlayer)
end

function joinClan(clanId)
    triggerServerEvent("jebiga:clans:requestJoin", localPlayer, clanId)
end

-- ============================================
-- EVENTS
-- ============================================

addEventHandler("onClientRender", root, renderClanPanel)
addEventHandler("onClientClick", root, handleClanClick)
addEventHandler("onClientKey", root, handleClanKey)
addEventHandler("onClientCharacter", root, handleClanChar)

-- Data sync from server
addEvent("jebiga:clans:syncData", true)
addEventHandler("jebiga:clans:syncData", root, function(clan, members, invites, clans)
    myClan = clan
    clanMembers = members or {}
    clanInvites = invites or {}
    allClans = clans or {}
end)

addEvent("jebiga:clans:result", true)
addEventHandler("jebiga:clans:result", root, function(success, message)
    if success then
        exports.jebiga_core:showNotification(message, "success")
        requestClanData()
        createForm.name = ""
        createForm.tag = ""
    else
        exports.jebiga_core:showNotification(message, "error")
    end
end)

-- Clan chat
addEvent("jebiga:clans:chat", true)
addEventHandler("jebiga:clans:chat", root, function(sender, message)
    outputChatBox("#2ECC71[CLAN] #FFFFFF" .. sender .. ": " .. message, 255, 255, 255, true)
end)

-- ============================================
-- COMMANDS
-- ============================================

addCommandHandler("clan", function()
    if clanPanelOpen then
        closeClanPanel()
    else
        openClanPanel()
    end
end)

addCommandHandler("clans", function()
    if clanPanelOpen then
        closeClanPanel()
    else
        openClanPanel()
    end
end)

-- Clan chat command
addCommandHandler("cc", function(cmd, ...)
    local message = table.concat({...}, " ")
    if message == "" then
        outputChatBox("#E74C3C[CLAN] #FFFFFFUsage: /cc [message]", 255, 255, 255, true)
        return
    end
    triggerServerEvent("jebiga:clans:sendChat", localPlayer, message)
end)

bindKey("F9", "down", function()
    if clanPanelOpen then
        closeClanPanel()
    else
        openClanPanel()
    end
end)
