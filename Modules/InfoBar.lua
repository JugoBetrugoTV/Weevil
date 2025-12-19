-- InfoBar Module for Weevil
-- Displays system information in a Titan Panel style bar

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local InfoBar = Weevil:NewModule("InfoBar", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
InfoBar.defaults = {
	enabled = true,
	position = "TOP", -- TOP or BOTTOM
	barHeight = 24,
	fontSize = 12,
	bgColor = {r = 0, g = 0, b = 0, a = 0.7},
	borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
	
	-- Performance displays
	showFPS = true,
	showLatency = true,
	showMemory = true,
	
	-- Currency displays
	showGold = true,
	showGoldRealm = false,
	showCurrencies = true,
	
	-- Character displays
	showBags = true,
	showDurability = true,
	showXP = true,
	showReputation = true,
	showSpeed = false,
	showItemLevel = true,
	showTalentSpec = true,
	
	-- Location displays
	showLocation = true,
	showCoordinates = true,
	showZoneLevel = false,
	
	-- Time displays
	showClock = true,
	showGameTime = true,
	showLocalTime = true,
	show24HourTime = true,
	
	-- Social displays
	showFriends = true,
	showGuild = true,
	showMail = true,
	
	-- Instance displays
	showInstanceDifficulty = true,
	showSavedInstances = false,
	
	-- Tracking displays
	showTracking = false,
	showQuestLog = true,
}

function InfoBar:OnInitialize()
	-- Database will be setup by parent addon first
	-- We register our namespace when we actually need it
end

function InfoBar:OnEnable()
	-- Now setup the database namespace
	if not self.db then
		self.db = Weevil.db:RegisterNamespace("InfoBar", {
			profile = self.defaults
		})
	end
	
	-- Create the bar if it doesn't exist
	if not self.bar then
		self:CreateBar()
	end
	
	if self.db.profile.enabled then
		self:ShowBar()
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:StartUpdates()
	end
end

function InfoBar:OnDisable()
	self:HideBar()
	self:UnregisterAllEvents()
	self:StopUpdates()
end

function InfoBar:CreateBar()
	if self.bar then return end
	
	-- Create main bar frame
	local bar = CreateFrame("Frame", "WeevilInfoBar", UIParent)
	bar:SetFrameStrata("MEDIUM")
	bar:SetFrameLevel(10)
	bar:SetHeight(self.db.profile.barHeight or 24)
	bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
	
	-- Background with gradient
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0, 0, 0, 0.7)
	
	-- Top border
	bar.topBorder = bar:CreateTexture(nil, "ARTWORK")
	bar.topBorder:SetHeight(1)
	bar.topBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	bar.topBorder:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
	bar.topBorder:SetColorTexture(0.3, 0.3, 0.3, 1)
	
	-- Bottom border with glow
	bar.bottomBorder = bar:CreateTexture(nil, "ARTWORK")
	bar.bottomBorder:SetHeight(2)
	bar.bottomBorder:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
	bar.bottomBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	bar.bottomBorder:SetColorTexture(0.2, 0.4, 0.8, 0.8)
	
	-- Left section (performance & character info)
	bar.leftText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.leftText:SetPoint("LEFT", bar, "LEFT", 10, 0)
	bar.leftText:SetJustifyH("LEFT")
	bar.leftText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.fontSize or 12, "OUTLINE")
	
	-- Center section (location & time)
	bar.centerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.centerText:SetPoint("CENTER", bar, "CENTER", 0, 0)
	bar.centerText:SetJustifyH("CENTER")
	bar.centerText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.fontSize or 12, "OUTLINE")
	
	-- Right section (social & currencies)
	bar.rightText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.rightText:SetPoint("RIGHT", bar, "RIGHT", -10, 0)
	bar.rightText:SetJustifyH("RIGHT")
	bar.rightText:SetFont("Fonts\\FRIZQT__.TTF", self.db.profile.fontSize or 12, "OUTLINE")
	
	self.bar = bar
	self:UpdateBarAppearance()
	bar:Hide()
end

function InfoBar:UpdateBarAppearance()
	if not self.bar then return end
	
	local c = self.db.profile.bgColor
	self.bar.bg:SetColorTexture(c.r, c.g, c.b, c.a)
	
	-- Update position
	self.bar:ClearAllPoints()
	if self.db.profile.position == "TOP" then
		self.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
		self.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
	else
		self.bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
		self.bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	end
end

function InfoBar:ShowBar()
	if self.bar and self.db.profile.enabled then
		self.bar:Show()
	end
end

function InfoBar:HideBar()
	if self.bar then
		self.bar:Hide()
	end
end

function InfoBar:Toggle()
	self.db.profile.enabled = not self.db.profile.enabled
	if self.db.profile.enabled then
		self:ShowBar()
		self:StartUpdates()
	else
		self:HideBar()
		self:StopUpdates()
	end
end

function InfoBar:StartUpdates()
	if self.updateTimer then return end
	
	self.updateTimer = C_Timer.NewTicker(1, function()
		self:UpdateDisplay()
	end)
	self:UpdateDisplay() -- Initial update
end

function InfoBar:StopUpdates()
	if self.updateTimer then
		self.updateTimer:Cancel()
		self.updateTimer = nil
	end
end

function InfoBar:PLAYER_ENTERING_WORLD()
	self:UpdateDisplay()
end

function InfoBar:UpdateDisplay()
	if not self.bar or not self.bar:IsShown() then return end
	
	local leftInfo = {}
	local centerInfo = {}
	local rightInfo = {}
	
	-- LEFT SECTION: Performance & Character
	
	-- FPS
	if self.db.profile.showFPS then
		local fps = GetFramerate()
		local color = fps > 60 and "00ff00" or (fps > 30 and "ffff00" or "ff0000")
		table.insert(leftInfo, string.format("|cff00ccff[FPS]|r |cff%s%.0f|r", color, fps))
	end
	
	-- Latency
	if self.db.profile.showLatency then
		local _, _, home, world = GetNetStats()
		local maxLatency = math.max(home, world)
		local color = maxLatency < 100 and "00ff00" or (maxLatency < 200 and "ffff00" or "ff0000")
		table.insert(leftInfo, string.format("|cff00ccff[Ping]|r |cff%s%d|r|cff888888/|r|cff%s%d|r", 
			color, home, color, world))
	end
	
	-- Memory
	if self.db.profile.showMemory then
		UpdateAddOnMemoryUsage()
		local mem = GetAddOnMemoryUsage("Weevil")
		table.insert(leftInfo, string.format("|cff00ccff[Mem]|r |cffaaaaaa%.1f MB|r", mem / 1024))
	end
	
	-- Bag Space
	if self.db.profile.showBags then
		local free, total = 0, 0
		for i = 0, NUM_BAG_SLOTS do
			local numSlots = GetContainerNumSlots(i) or (C_Container and C_Container.GetContainerNumSlots(i)) or 0
			total = total + numSlots
			local freeSlots = GetContainerNumFreeSlots(i) or (C_Container and C_Container.GetContainerNumFreeSlots(i)) or 0
			free = free + freeSlots
		end
		local percent = total > 0 and (free / total) * 100 or 0
		local color = percent > 30 and "00ff00" or (percent > 10 and "ffff00" or "ff0000")
		table.insert(leftInfo, string.format("|cff00ccff[Bags]|r |cff%s%d|r|cff888888/|r%d", color, free, total))
	end
	
	-- Durability
	if self.db.profile.showDurability then
		local total, current = 0, 0
		for i = 1, 18 do
			local curDur, maxDur = GetInventoryItemDurability(i)
			if curDur and maxDur then
				current = current + curDur
				total = total + maxDur
			end
		end
		if total > 0 then
			local percent = (current / total) * 100
			local color = percent > 50 and "00ff00" or (percent > 25 and "ffff00" or "ff0000")
			table.insert(leftInfo, string.format("|cff00ccff[Dur]|r |cff%s%.0f%%|r", color, percent))
		end
	end
	
	-- Item Level
	if self.db.profile.showItemLevel then
		local total, count = 0, 0
		for i = 1, 18 do
			local itemLink = GetInventoryItemLink("player", i)
			if itemLink then
				local itemLevel = GetDetailedItemLevelInfo(itemLink)
				if itemLevel and itemLevel > 0 then
					total = total + itemLevel
					count = count + 1
				end
			end
		end
		if count > 0 then
			local avgIlvl = total / count
			table.insert(leftInfo, string.format("|cff00ccff[iLvl]|r |cffffaa00%.0f|r", avgIlvl))
		end
	end
	
	-- Talent Spec
	if self.db.profile.showTalentSpec then
		local specID = GetSpecialization()
		if specID then
			local _, specName = GetSpecializationInfo(specID)
			if specName then
				table.insert(leftInfo, string.format("|cff00ccff[Spec]|r |cff88ff88%s|r", specName))
			end
		end
	end
	
	-- XP Bar
	if self.db.profile.showXP and not IsXPUserDisabled() then
		local level = UnitLevel("player")
		if level < GetMaxPlayerLevel() then
			local xp = UnitXP("player")
			local xpMax = UnitXPMax("player")
			local percent = (xp / xpMax) * 100
			local restedXP = GetXPExhaustion() or 0
			local restedPercent = (restedXP / xpMax) * 100
			local color = restedPercent > 0 and "88ff88" or "ffffff"
			table.insert(leftInfo, string.format("|cff00ccff[XP]|r |cff%s%.1f%%|r", color, percent))
		end
	end
	
	-- Reputation
	if self.db.profile.showReputation then
		local name, standing, min, max, value = GetWatchedFactionInfo()
		if name then
			local percent = ((value - min) / (max - min)) * 100
			local standingText = _G["FACTION_STANDING_LABEL"..standing] or ""
			table.insert(leftInfo, string.format("|cff00ccff[Rep]|r |cffaaaaff%s|r |cffffffff%.0f%%|r", 
				standingText:sub(1, 3), percent))
		end
	end
	
	-- CENTER SECTION: Location & Time
	
	-- Location
	if self.db.profile.showLocation then
		local zone = GetZoneText()
		local subzone = GetSubZoneText()
		local displayText = subzone ~= "" and subzone or zone
		
		if self.db.profile.showCoordinates then
			local map = C_Map.GetBestMapForUnit("player")
			if map then
				local pos = C_Map.GetPlayerMapPosition(map, "player")
				if pos then
					local x, y = pos:GetXY()
					displayText = string.format("%s |cff888888(%.1f, %.1f)|r", displayText, x * 100, y * 100)
				end
			end
		end
		
		table.insert(centerInfo, string.format("|cffffaa00%s|r", displayText))
	end
	
	-- Clock
	if self.db.profile.showClock then
		local timeText = {}
		if self.db.profile.showGameTime then
			local hour, minute = GetGameTime()
			table.insert(timeText, string.format("|cff88ff88%02d:%02d|r", hour, minute))
		end
		if self.db.profile.showLocalTime then
			local format = self.db.profile.show24HourTime and "%H:%M" or "%I:%M %p"
			local localTime = date(format)
			table.insert(timeText, string.format("|cffaaaaff%s|r", localTime))
		end
		if #timeText > 0 then
			table.insert(centerInfo, table.concat(timeText, " |cff666666||r "))
		end
	end
	
	-- Quest Log
	if self.db.profile.showQuestLog then
		local numQuests = C_QuestLog.GetNumQuestLogEntries()
		local maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()
		local color = numQuests >= maxQuests and "ff0000" or "ffff88"
		table.insert(centerInfo, string.format("|cff00ccff[Quests]|r |cff%s%d|r|cff888888/|r%d", 
			color, numQuests, maxQuests))
	end
	
	-- RIGHT SECTION: Social & Currency
	
	-- Gold
	if self.db.profile.showGold then
		local gold = GetMoney()
		table.insert(rightInfo, string.format("|cff00ccff[Gold]|r %s", GetCoinTextureString(gold)))
	end
	
	-- Currencies (show main currency types)
	if self.db.profile.showCurrencies then
		-- Show first tracked currency
		local info = C_CurrencyInfo.GetCurrencyListInfo(1)
		if info and info.name and info.quantity then
			table.insert(rightInfo, string.format("|cff00ccff[%s]|r |cffffffff%d|r", 
				info.name:sub(1, 8), info.quantity))
		end
	end
	
	-- Friends Online
	if self.db.profile.showFriends then
		local _, numOnline = C_FriendList.GetNumFriends()
		local numBNetOnline = C_BattleNet.GetFriendNumGameAccounts()
		local totalOnline = numOnline + numBNetOnline
		local color = totalOnline > 0 and "88ff88" or "888888"
		table.insert(rightInfo, string.format("|cff00ccff[Friends]|r |cff%s%d|r", color, totalOnline))
	end
	
	-- Guild
	if self.db.profile.showGuild then
		if IsInGuild() then
			local numTotal, numOnline = GetNumGuildMembers()
			local color = numOnline > 0 and "88ff88" or "888888"
			table.insert(rightInfo, string.format("|cff00ccff[Guild]|r |cff%s%d|r|cff888888/|r%d", 
				color, numOnline, numTotal))
		end
	end
	
	-- Mail
	if self.db.profile.showMail then
		if HasNewMail() then
			table.insert(rightInfo, "|cff00ccff[Mail]|r |cffff8800NEW!|r")
		end
	end
	
	-- Instance Difficulty
	if self.db.profile.showInstanceDifficulty then
		local inInstance, instanceType = IsInInstance()
		if inInstance then
			local difficulty = GetInstanceDifficulty()
			local diffText = difficulty == 1 and "N" or difficulty == 2 and "H" or difficulty == 3 and "M" or "?"
			table.insert(rightInfo, string.format("|cff00ccff[Diff]|r |cffff88ff%s|r", diffText))
		end
	end
	
	-- Speed
	if self.db.profile.showSpeed then
		local speed = GetUnitSpeed("player")
		if speed > 0 then
			table.insert(rightInfo, string.format("|cff00ccff[Speed]|r |cffffffff%.0f%%|r", speed * 100))
		end
	end
	
	-- Update all text sections
	self.bar.leftText:SetText(table.concat(leftInfo, "  "))
	self.bar.centerText:SetText(table.concat(centerInfo, "  |cff444444||r  "))
	self.bar.rightText:SetText(table.concat(rightInfo, "  "))
end
