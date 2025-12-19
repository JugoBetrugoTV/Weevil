-- UI Module for Weevil
-- Handles UI tweaks and improvements

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local UI = Weevil:NewModule("UI", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
UI.defaults = {
	hideErrorFrame = false,
	fasterAutoLoot = true,
	screenshotAchievements = true,
	enhancedTooltips = true,
	confirmLootRoll = false,
	hideTalkingHead = false,
}

function UI:OnInitialize()
	self.db = Weevil.db:RegisterNamespace("UI", {
		profile = self.defaults
	})
end

function UI:OnEnable()
	if self.db.profile.hideErrorFrame then
		self:HideErrorFrame()
	end
	
	if self.db.profile.fasterAutoLoot then
		self:EnableFasterAutoLoot()
	end
	
	if self.db.profile.screenshotAchievements then
		self:EnableAchievementScreenshots()
	end
	
	if self.db.profile.enhancedTooltips then
		self:EnableEnhancedTooltips()
	end
	
	if self.db.profile.confirmLootRoll then
		self:EnableConfirmLootRoll()
	end
	
	if self.db.profile.hideTalkingHead then
		self:HideTalkingHead()
	end
	
	Weevil:Print(L["UI"] .. " " .. "module enabled")
end

function UI:OnDisable()
	self:UnregisterAllEvents()
end

-- Hide error frame (red error text)
function UI:HideErrorFrame()
	UIErrorsFrame:Hide()
	UIErrorsFrame:SetScript("OnShow", function(self)
		self:Hide()
	end)
end

-- Enable faster auto loot
function UI:EnableFasterAutoLoot()
	-- Reduce loot delay to 0
	SetCVar("autoLootDelay", "0")
end

-- Screenshot on achievements
function UI:EnableAchievementScreenshots()
	self:RegisterEvent("ACHIEVEMENT_EARNED")
end

function UI:ACHIEVEMENT_EARNED(event, achievementID)
	C_Timer.After(1, function()
		Screenshot()
		Weevil:Printf("Screenshot taken for achievement: %s", select(2, GetAchievementInfo(achievementID)))
	end)
end

-- Enhanced tooltips
function UI:EnableEnhancedTooltips()
	-- Hook tooltip to add item level and spell IDs
	GameTooltip:HookScript("OnTooltipSetItem", function(self)
		local _, itemLink = self:GetItem()
		if itemLink then
			local itemLevel = GetDetailedItemLevelInfo(itemLink)
			if itemLevel and itemLevel > 0 then
				self:AddLine("|cff00ff00Item Level: " .. itemLevel .. "|r")
			end
			
			-- Add item ID
			local itemID = itemLink:match("item:(%d+)")
			if itemID then
				self:AddLine("|cff888888Item ID: " .. itemID .. "|r")
			end
		end
		self:Show()
	end)
	
	-- Add spell IDs to spell tooltips
	local function AddSpellID(self)
		local id = select(2, self:GetSpell())
		if id then
			self:AddLine("|cff888888Spell ID: " .. id .. "|r")
			self:Show()
		end
	end
	
	GameTooltip:HookScript("OnTooltipSetSpell", AddSpellID)
	
	-- Also hook item tooltips in bags
	if ItemRefTooltip then
		ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
			local _, itemLink = self:GetItem()
			if itemLink then
				local itemLevel = GetDetailedItemLevelInfo(itemLink)
				if itemLevel and itemLevel > 0 then
					self:AddLine("|cff00ff00Item Level: " .. itemLevel .. "|r")
				end
				
				local itemID = itemLink:match("item:(%d+)")
				if itemID then
					self:AddLine("|cff888888Item ID: " .. itemID .. "|r")
				end
			end
			self:Show()
		end)
	end
end

-- Confirm loot roll
function UI:EnableConfirmLootRoll()
	-- Hook the group loot container to require confirmation for passing
	hooksecurefunc("GroupLootContainer_OnEvent", function(self, event, ...)
		if event == "START_LOOT_ROLL" then
			local rollID = ...
			if rollID then
				-- Override pass button
				for i = 1, self:GetNumChildren() do
					local child = select(i, self:GetChildren())
					if child and child.rollID == rollID then
						local passButton = child.PassButton
						if passButton then
							passButton:SetScript("OnClick", function(btn)
								StaticPopup_Show("WEEVIL_CONFIRM_PASS", nil, nil, rollID)
							end)
						end
						break
					end
				end
			end
		end
	end)
	
	-- Register static popup for confirmation
	if not StaticPopupDialogs["WEEVIL_CONFIRM_PASS"] then
		StaticPopupDialogs["WEEVIL_CONFIRM_PASS"] = {
			text = "Are you sure you want to pass on this loot?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function(self, rollID)
				RollOnLoot(rollID, 0) -- 0 = pass
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
end

-- Hide talking head frame
function UI:HideTalkingHead()
	if TalkingHeadFrame then
		TalkingHeadFrame:Hide()
		TalkingHeadFrame:SetScript("OnShow", function(self)
			self:Hide()
		end)
		
		-- Also hide via the API
		if C_TalkingHead then
			hooksecurefunc(C_TalkingHead, "ShowTalkingHead", function()
				TalkingHeadFrame:Hide()
			end)
		end
	end
end
