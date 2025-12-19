-- Automation Module for Weevil
-- Handles automatic quest acceptance, repairs, selling junk, and other automation features

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local Automation = Weevil:NewModule("Automation", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
Automation.defaults = {
	autoAcceptQuests = true,
	autoTurnInQuests = true,
	autoRepair = true,
	useGuildRepair = true,
	autoSellJunk = true,
	autoAcceptRes = true,
	autoSkipCutscenes = true,
	autoAcceptSummon = false,
	autoReleaseInBGs = false,
}

function Automation:OnInitialize()
	self.db = Weevil.db:RegisterNamespace("Automation", {
		profile = self.defaults
	})
end

function Automation:OnEnable()
	-- Register events for automation features
	if self.db.profile.autoAcceptQuests or self.db.profile.autoTurnInQuests then
		self:RegisterEvent("QUEST_DETAIL")
		self:RegisterEvent("QUEST_PROGRESS")
		self:RegisterEvent("QUEST_COMPLETE")
	end
	
	if self.db.profile.autoRepair or self.db.profile.autoSellJunk then
		self:RegisterEvent("MERCHANT_SHOW")
	end
	
	if self.db.profile.autoAcceptRes then
		self:RegisterEvent("RESURRECT_REQUEST")
	end
	
	if self.db.profile.autoSkipCutscenes then
		self:RegisterEvent("CINEMATIC_START")
		self:RegisterEvent("PLAY_MOVIE")
	end
	
	if self.db.profile.autoAcceptSummon then
		self:RegisterEvent("CONFIRM_SUMMON")
	end
	
	if self.db.profile.autoReleaseInBGs then
		self:RegisterEvent("PLAYER_DEAD")
	end
	
	Weevil:Print(L["Automation"] .. " " .. "module enabled")
end

function Automation:OnDisable()
	self:UnregisterAllEvents()
end

-- Auto Accept Quests
function Automation:QUEST_DETAIL()
	if self.db.profile.autoAcceptQuests then
		AcceptQuest()
	end
end

-- Auto Turn-in Quests (Progress)
function Automation:QUEST_PROGRESS()
	if self.db.profile.autoTurnInQuests and IsQuestCompletable() then
		CompleteQuest()
	end
end

-- Auto Turn-in Quests (Complete)
function Automation:QUEST_COMPLETE()
	if self.db.profile.autoTurnInQuests then
		-- If there's only one reward or no choice, auto-complete
		local numQuestRewards = GetNumQuestChoices()
		if numQuestRewards <= 1 then
			GetQuestReward(1)
		end
	end
end

-- Auto Repair and Sell Junk at Merchants
function Automation:MERCHANT_SHOW()
	-- Auto repair
	if self.db.profile.autoRepair and CanMerchantRepair() then
		local repairCost, canRepair = GetRepairAllCost()
		if canRepair and repairCost > 0 then
			local useGuildBank = self.db.profile.useGuildRepair and CanGuildBankRepair()
			RepairAllItems(useGuildBank)
			
			if useGuildBank then
				Weevil:Printf("Repaired all items using guild funds: %s", GetCoinTextureString(repairCost))
			else
				Weevil:Printf("Repaired all items: %s", GetCoinTextureString(repairCost))
			end
		end
	end
	
	-- Auto sell junk
	if self.db.profile.autoSellJunk then
		local totalValue = 0
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) or C_Container.GetContainerNumSlots(bag) do
				local itemLink = GetContainerItemLink(bag, slot) or C_Container.GetContainerItemLink(bag, slot)
				if itemLink then
					local _, _, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink)
					if quality == 0 and vendorPrice and vendorPrice > 0 then -- Gray quality
						local itemInfo = GetContainerItemInfo(bag, slot) or C_Container.GetContainerItemInfo(bag, slot)
						local count = itemInfo and (itemInfo.stackCount or itemInfo.count) or 1
						totalValue = totalValue + (vendorPrice * count)
						
						-- Use modern or classic API based on availability
						if C_Container and C_Container.UseContainerItem then
							C_Container.UseContainerItem(bag, slot)
						else
							UseContainerItem(bag, slot)
						end
					end
				end
			end
		end
		
		if totalValue > 0 then
			Weevil:Printf("Sold junk items: %s", GetCoinTextureString(totalValue))
		end
	end
end

-- Auto Accept Resurrection
function Automation:RESURRECT_REQUEST()
	if self.db.profile.autoAcceptRes then
		AcceptResurrect()
	end
end

-- Auto Skip Cutscenes
function Automation:CINEMATIC_START()
	if self.db.profile.autoSkipCutscenes then
		CinematicFrame_CancelCinematic()
	end
end

function Automation:PLAY_MOVIE()
	if self.db.profile.autoSkipCutscenes then
		if MovieFrame:IsShown() then
			MovieFrame:StopMovie()
		end
		GameMovieFinished()
	end
end

-- Auto Accept Summon
function Automation:CONFIRM_SUMMON()
	if self.db.profile.autoAcceptSummon then
		ConfirmSummon()
	end
end

-- Auto Release in Battlegrounds
function Automation:PLAYER_DEAD()
	if self.db.profile.autoReleaseInBGs then
		local inInstance, instanceType = IsInInstance()
		if inInstance and instanceType == "pvp" then
			RepopMe()
		end
	end
end
