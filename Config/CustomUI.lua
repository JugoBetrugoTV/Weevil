-- Custom UI Panel for Weevil
-- Beautiful, modern options interface

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

local CustomUI = {}
Weevil.CustomUI = CustomUI

-- Color scheme
local COLORS = {
	primary = {0.2, 0.4, 0.8, 1},
	secondary = {0.15, 0.15, 0.2, 0.95},
	accent = {0.3, 0.6, 1, 1},
	success = {0.2, 0.8, 0.2, 1},
	danger = {0.8, 0.2, 0.2, 1},
	text = {1, 1, 1, 1},
	textDim = {0.7, 0.7, 0.7, 1},
	border = {0.3, 0.3, 0.3, 1},
}

function CustomUI:CreateMainFrame()
	if self.mainFrame then
		self.mainFrame:Show()
		return self.mainFrame
	end
	
	-- Main frame
	local frame = CreateFrame("Frame", "WeevilCustomUI", UIParent, "ButtonFrameTemplate")
	frame:SetSize(850, 600)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(100)
	
	-- Title bar with gradient
	frame.TitleBg = frame:CreateTexture(nil, "BACKGROUND")
	frame.TitleBg:SetPoint("TOPLEFT", 6, -6)
	frame.TitleBg:SetPoint("TOPRIGHT", -6, -6)
	frame.TitleBg:SetHeight(40)
	frame.TitleBg:SetGradient("VERTICAL", 
		CreateColor(COLORS.primary[1], COLORS.primary[2], COLORS.primary[3], COLORS.primary[4]),
		CreateColor(COLORS.secondary[1], COLORS.secondary[2], COLORS.secondary[3], COLORS.secondary[4]))
	
	-- Title text
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", frame.TitleBg, "TOPLEFT", 15, -10)
	frame.title:SetText("|cff3399ffWeevil|r - Quality of Life Enhancement Suite")
	frame.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	
	-- Version text
	frame.version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.version:SetPoint("TOPRIGHT", frame.TitleBg, "TOPRIGHT", -15, -10)
	frame.version:SetText("|cff888888v" .. Weevil.version .. "|r")
	frame.version:SetFont("Fonts\\FRIZQT__.TTF", 11)
	
	-- Close button (enhanced)
	frame.CloseButton:SetPoint("TOPRIGHT", -3, -3)
	frame.CloseButton:SetSize(32, 32)
	frame.CloseButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	frame.CloseButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	frame.CloseButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
	
	-- Content background
	frame.ContentBg = frame:CreateTexture(nil, "BACKGROUND")
	frame.ContentBg:SetPoint("TOPLEFT", frame.TitleBg, "BOTTOMLEFT", 0, -5)
	frame.ContentBg:SetPoint("BOTTOMRIGHT", -6, 6)
	frame.ContentBg:SetColorTexture(COLORS.secondary[1], COLORS.secondary[2], COLORS.secondary[3], COLORS.secondary[4])
	
	-- Create category buttons on the left
	frame.categoryButtons = {}
	frame.contentPanels = {}
	
	self:CreateCategoryButtons(frame)
	self:CreateContentPanels(frame)
	
	self.mainFrame = frame
	frame:Hide()
	
	return frame
end

function CustomUI:CreateCategoryButtons(parent)
	local categories = {
		{name = "Automation", icon = "Interface\\Icons\\INV_Misc_EngGizmos_17", color = {0.3, 0.8, 0.3}},
		{name = "Info Bar", icon = "Interface\\Icons\\INV_Misc_Note_06", color = {0.3, 0.6, 1}},
		{name = "UI Tweaks", icon = "Interface\\Icons\\INV_Misc_Gear_01", color = {0.8, 0.6, 0.2}},
		{name = "Profiles", icon = "Interface\\Icons\\INV_Misc_Book_09", color = {0.8, 0.3, 0.8}},
	}
	
	local yOffset = -50
	for i, cat in ipairs(categories) do
		local btn = CreateFrame("Button", nil, parent)
		btn:SetSize(180, 45)
		btn:SetPoint("TOPLEFT", 15, yOffset)
		
		-- Button background
		btn.bg = btn:CreateTexture(nil, "BACKGROUND")
		btn.bg:SetAllPoints()
		btn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.8)
		
		-- Highlight
		btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
		btn.highlight:SetAllPoints()
		btn.highlight:SetColorTexture(cat.color[1], cat.color[2], cat.color[3], 0.3)
		btn.highlight:SetBlendMode("ADD")
		
		-- Left accent bar
		btn.accent = btn:CreateTexture(nil, "ARTWORK")
		btn.accent:SetPoint("TOPLEFT")
		btn.accent:SetPoint("BOTTOMLEFT")
		btn.accent:SetWidth(4)
		btn.accent:SetColorTexture(cat.color[1], cat.color[2], cat.color[3], 1)
		
		-- Icon
		btn.icon = btn:CreateTexture(nil, "ARTWORK")
		btn.icon:SetSize(32, 32)
		btn.icon:SetPoint("LEFT", 12, 0)
		btn.icon:SetTexture(cat.icon)
		
		-- Text
		btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 10, 0)
		btn.text:SetText(cat.name)
		btn.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		
		-- Click handler
		btn:SetScript("OnClick", function()
			self:SelectCategory(i)
		end)
		
		btn.categoryIndex = i
		parent.categoryButtons[i] = btn
		
		yOffset = yOffset - 50
	end
	
	-- Select first category by default
	self:SelectCategory(1)
end

function CustomUI:SelectCategory(index)
	if not self.mainFrame then return end
	
	-- Update button states
	for i, btn in ipairs(self.mainFrame.categoryButtons) do
		if i == index then
			btn.bg:SetColorTexture(0.2, 0.3, 0.4, 0.9)
			btn.accent:Show()
		else
			btn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.8)
			btn.accent:SetAlpha(0.3)
		end
	end
	
	-- Show corresponding panel
	for i, panel in ipairs(self.mainFrame.contentPanels) do
		if i == index then
			panel:Show()
		else
			panel:Hide()
		end
	end
	
	self.currentCategory = index
end

function CustomUI:CreateContentPanels(parent)
	-- Panel container
	local container = CreateFrame("Frame", nil, parent)
	container:SetPoint("TOPLEFT", 210, -50)
	container:SetPoint("BOTTOMRIGHT", -15, 40)
	
	-- Automation Panel
	local automationPanel = self:CreateAutomationPanel(container)
	table.insert(parent.contentPanels, automationPanel)
	
	-- InfoBar Panel
	local infoBarPanel = self:CreateInfoBarPanel(container)
	table.insert(parent.contentPanels, infoBarPanel)
	
	-- UI Panel
	local uiPanel = self:CreateUIPanel(container)
	table.insert(parent.contentPanels, uiPanel)
	
	-- Profiles Panel
	local profilesPanel = self:CreateProfilesPanel(container)
	table.insert(parent.contentPanels, profilesPanel)
end

function CustomUI:CreateAutomationPanel(parent)
	local panel = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	panel:SetAllPoints()
	
	local content = CreateFrame("Frame", nil, panel)
	content:SetSize(600, 1200)
	panel:SetScrollChild(content)
	
	-- Title
	local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("|cff66ff66Automation Features|r")
	title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
	
	local yOffset = -50
	local automation = Weevil:GetModule("Automation")
	
	-- Quest Section
	yOffset = self:CreateSection(content, yOffset, "Quest Automation", {
		{key = "autoAcceptQuests", label = "Auto Accept Quests", desc = "Automatically accept quests from NPCs"},
		{key = "autoTurnInQuests", label = "Auto Turn-in Quests", desc = "Automatically complete quests"},
		{key = "autoGossip", label = "Auto Gossip", desc = "Skip NPC dialogue automatically"},
	}, automation.db.profile)
	
	-- Merchant Section
	yOffset = self:CreateSection(content, yOffset, "Merchant Automation", {
		{key = "autoRepair", label = "Auto Repair", desc = "Repair gear at vendors automatically"},
		{key = "useGuildRepair", label = "Use Guild Repair", desc = "Use guild bank for repairs", dependent = "autoRepair"},
		{key = "autoSellJunk", label = "Auto Sell Junk", desc = "Sell gray items automatically"},
		{key = "autoSellGrey", label = "Auto Sell All Grey", desc = "Sell all grey quality items"},
	}, automation.db.profile)
	
	-- Loot Section
	yOffset = self:CreateSection(content, yOffset, "Loot Automation", {
		{key = "fasterLooting", label = "Faster Looting", desc = "Instant loot delay (0ms)"},
		{key = "autoLootFaster", label = "Enhanced Auto Loot", desc = "Faster auto loot speed"},
		{key = "autoGreed", label = "Auto Greed Greens", desc = "Automatically greed on green items"},
		{key = "autoGreedBlue", label = "Auto Greed Blues", desc = "Automatically greed on blue items"},
	}, automation.db.profile)
	
	-- Social Section
	yOffset = self:CreateSection(content, yOffset, "Social Automation", {
		{key = "autoAcceptRes", label = "Auto Accept Resurrect", desc = "Accept resurrections automatically"},
		{key = "autoAcceptSummon", label = "Auto Accept Summon", desc = "Accept warlock summons"},
		{key = "autoInvite", label = "Auto Invite", desc = "Auto invite from whispers"},
		{key = "autoDeclineDuels", label = "Auto Decline Duels", desc = "Automatically decline duel requests"},
		{key = "autoDeclineParty", label = "Auto Decline Party", desc = "Decline party invites"},
	}, automation.db.profile)
	
	-- UI Section
	yOffset = self:CreateSection(content, yOffset, "UI Automation", {
		{key = "autoSkipCutscenes", label = "Skip Cutscenes", desc = "Automatically skip cinematics"},
		{key = "hideZoneText", label = "Hide Zone Text", desc = "Hide zone change announcements"},
		{key = "hideBossEmotes", label = "Hide Boss Emotes", desc = "Hide boss emote frame"},
		{key = "autoConfirmBind", label = "Auto Confirm Bind", desc = "Auto confirm bind on equip"},
		{key = "autoConfirmDisenchant", label = "Auto Confirm Disenchant", desc = "Auto confirm disenchant"},
	}, automation.db.profile)
	
	panel:Hide()
	return panel
end

function CustomUI:CreateInfoBarPanel(parent)
	local panel = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	panel:SetAllPoints()
	
	local content = CreateFrame("Frame", nil, panel)
	content:SetSize(600, 1400)
	panel:SetScrollChild(content)
	
	local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("|cff66ccffInfo Bar Configuration|r")
	title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
	
	local yOffset = -50
	local infobar = Weevil:GetModule("InfoBar")
	
	-- General Settings
	yOffset = self:CreateSection(content, yOffset, "General Settings", {
		{key = "enabled", label = "Enable Info Bar", desc = "Show the information bar"},
	}, infobar.db.profile)
	
	-- Performance Displays
	yOffset = self:CreateSection(content, yOffset, "Performance Displays", {
		{key = "showFPS", label = "Show FPS", desc = "Display frames per second"},
		{key = "showLatency", label = "Show Latency", desc = "Display ping/latency"},
		{key = "showMemory", label = "Show Memory", desc = "Display addon memory usage"},
	}, infobar.db.profile)
	
	-- Character Displays
	yOffset = self:CreateSection(content, yOffset, "Character Displays", {
		{key = "showBags", label = "Show Bag Space", desc = "Display free bag slots"},
		{key = "showDurability", label = "Show Durability", desc = "Display equipment durability"},
		{key = "showXP", label = "Show XP Bar", desc = "Display experience progress"},
		{key = "showReputation", label = "Show Reputation", desc = "Display watched faction rep"},
		{key = "showItemLevel", label = "Show Item Level", desc = "Display average item level"},
		{key = "showTalentSpec", label = "Show Talent Spec", desc = "Display current specialization"},
		{key = "showSpeed", label = "Show Speed", desc = "Display movement speed"},
	}, infobar.db.profile)
	
	-- Currency Displays
	yOffset = self:CreateSection(content, yOffset, "Currency Displays", {
		{key = "showGold", label = "Show Gold", desc = "Display current gold"},
		{key = "showGoldRealm", label = "Show Realm Gold", desc = "Display all characters gold"},
		{key = "showCurrencies", label = "Show Currencies", desc = "Display tracked currencies"},
	}, infobar.db.profile)
	
	-- Location Displays
	yOffset = self:CreateSection(content, yOffset, "Location Displays", {
		{key = "showLocation", label = "Show Location", desc = "Display current zone"},
		{key = "showCoordinates", label = "Show Coordinates", desc = "Display player coordinates"},
		{key = "showZoneLevel", label = "Show Zone Level", desc = "Display zone level range"},
	}, infobar.db.profile)
	
	-- Time Displays
	yOffset = self:CreateSection(content, yOffset, "Time Displays", {
		{key = "showClock", label = "Show Clock", desc = "Display time"},
		{key = "showGameTime", label = "Show Game Time", desc = "Display server time"},
		{key = "showLocalTime", label = "Show Local Time", desc = "Display local time"},
		{key = "show24HourTime", label = "24 Hour Format", desc = "Use 24-hour time format"},
	}, infobar.db.profile)
	
	-- Social Displays
	yOffset = self:CreateSection(content, yOffset, "Social Displays", {
		{key = "showFriends", label = "Show Friends", desc = "Display online friends"},
		{key = "showGuild", label = "Show Guild", desc = "Display online guild members"},
		{key = "showMail", label = "Show Mail", desc = "Display mail indicator"},
	}, infobar.db.profile)
	
	-- Instance Displays
	yOffset = self:CreateSection(content, yOffset, "Instance Displays", {
		{key = "showInstanceDifficulty", label = "Show Instance Difficulty", desc = "Display dungeon/raid difficulty"},
		{key = "showSavedInstances", label = "Show Saved Instances", desc = "Display lockout information"},
		{key = "showQuestLog", label = "Show Quest Log", desc = "Display quest count"},
	}, infobar.db.profile)
	
	panel:Hide()
	return panel
end

function CustomUI:CreateUIPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("|cffffaa66UI Tweaks & Enhancements|r")
	title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
	
	local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
	desc:SetPoint("RIGHT", -20, 0)
	desc:SetText("Customize your World of Warcraft interface with these quality of life improvements.")
	desc:SetJustifyH("LEFT")
	desc:SetTextColor(0.7, 0.7, 0.7, 1)
	
	panel:Hide()
	return panel
end

function CustomUI:CreateProfilesPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	
	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("|cffff88ffProfile Management|r")
	title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
	
	local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
	desc:SetPoint("RIGHT", -20, 0)
	desc:SetText("Manage your addon profiles. Create, delete, and switch between different configurations for your characters.")
	desc:SetJustifyH("LEFT")
	desc:SetTextColor(0.7, 0.7, 0.7, 1)
	
	panel:Hide()
	return panel
end

function CustomUI:CreateSection(parent, yOffset, sectionName, options, db)
	-- Section header
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 10, yOffset)
	header:SetText("|cff88aaff" .. sectionName .. "|r")
	header:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	
	yOffset = yOffset - 30
	
	-- Create checkboxes for each option
	for _, opt in ipairs(options) do
		local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
		check:SetPoint("TOPLEFT", 20, yOffset)
		check:SetSize(24, 24)
		check:SetChecked(db[opt.key])
		
		check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
		check.text:SetText(opt.label)
		check.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
		
		check:SetScript("OnClick", function(self)
			db[opt.key] = self:GetChecked()
		end)
		
		-- Tooltip
		check:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(opt.label, 1, 1, 1)
			GameTooltip:AddLine(opt.desc, 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		end)
		check:SetScript("OnLeave", function() GameTooltip:Hide() end)
		
		yOffset = yOffset - 30
	end
	
	yOffset = yOffset - 20 -- Extra space after section
	return yOffset
end

function CustomUI:Show()
	local frame = self:CreateMainFrame()
	frame:Show()
end

function CustomUI:Hide()
	if self.mainFrame then
		self.mainFrame:Hide()
	end
end
