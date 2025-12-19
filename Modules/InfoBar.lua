-- InfoBar Module for Weevil
-- Displays system information in a Titan Panel style bar

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local InfoBar = Weevil:NewModule("InfoBar", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
InfoBar.defaults = {
	enabled = true,
	position = "TOP", -- TOP or BOTTOM
	bgColor = {r = 0, g = 0, b = 0, a = 0.6},
	showFPS = true,
	showLatency = true,
	showGold = true,
	showBags = true,
	showDurability = true,
	showLocation = true,
	showClock = true,
	showMemory = true,
}

function InfoBar:OnInitialize()
	self.db = Weevil.db:RegisterNamespace("InfoBar", {
		profile = self.defaults
	})
	
	self:CreateBar()
end

function InfoBar:OnEnable()
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
	bar:SetFrameStrata("LOW")
	bar:SetFrameLevel(0)
	bar:SetHeight(20)
	bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
	
	-- Background
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0, 0, 0, 0.6)
	
	-- Text container
	bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.text:SetPoint("LEFT", bar, "LEFT", 10, 0)
	bar.text:SetJustifyH("LEFT")
	
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
	
	local info = {}
	
	-- FPS
	if self.db.profile.showFPS then
		local fps = GetFramerate()
		table.insert(info, string.format("|cff00ff00FPS:|r %.0f", fps))
	end
	
	-- Latency
	if self.db.profile.showLatency then
		local _, _, home, world = GetNetStats()
		table.insert(info, string.format("|cff00ff00Latency:|r %d/%d ms", home, world))
	end
	
	-- Gold
	if self.db.profile.showGold then
		local gold = GetMoney()
		table.insert(info, string.format("|cff00ff00Gold:|r %s", GetCoinTextureString(gold)))
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
		table.insert(info, string.format("|cff00ff00Bags:|r %d/%d", free, total))
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
			table.insert(info, string.format("|cff00ff00Dur:|r |cff%s%.0f%%|r", color, percent))
		end
	end
	
	-- Location
	if self.db.profile.showLocation then
		local zone = GetZoneText()
		local subzone = GetSubZoneText()
		local map = C_Map.GetBestMapForUnit("player")
		if map then
			local pos = C_Map.GetPlayerMapPosition(map, "player")
			if pos then
				local x, y = pos:GetXY()
				table.insert(info, string.format("|cff00ff00Loc:|r %s (%.1f, %.1f)", subzone ~= "" and subzone or zone, x * 100, y * 100))
			else
				table.insert(info, string.format("|cff00ff00Loc:|r %s", subzone ~= "" and subzone or zone))
			end
		else
			table.insert(info, string.format("|cff00ff00Loc:|r %s", subzone ~= "" and subzone or zone))
		end
	end
	
	-- Clock
	if self.db.profile.showClock then
		local hour, minute = GetGameTime()
		local localTime = date("%H:%M")
		table.insert(info, string.format("|cff00ff00Time:|r %02d:%02d (S) | %s (L)", hour, minute, localTime))
	end
	
	-- Memory
	if self.db.profile.showMemory then
		UpdateAddOnMemoryUsage()
		local mem = GetAddOnMemoryUsage("Weevil")
		table.insert(info, string.format("|cff00ff00Mem:|r %.2f MB", mem / 1024))
	end
	
	self.bar.text:SetText(table.concat(info, "  |cff666666||r  "))
end
