-- Automation Module for Weevil
-- Handles automatic quest acceptance, repairs, selling junk, and many more automation features

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local Automation = Weevil:NewModule("Automation", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
Automation.defaults = {
	-- Quest automation
	autoAcceptQuests = true,
	autoTurnInQuests = true,
	autoGossip = true,
	
	-- Merchant automation
	autoRepair = true,
	useGuildRepair = true,
	autoSellJunk = true,
	autoSellGrey = true,
	
	-- Loot automation
	fasterLooting = true,
	autoLootFaster = true,
	autoGreed = false,
	autoGreedBlue = false,
	
	-- Social automation
	autoAcceptRes = true,
	autoAcceptSummon = false,
	autoInvite = false,
	autoInviteKeyword = "inv",
	autoDeclineDuels = true,
	autoDeclineParty = false,
	
	-- Combat automation
	autoReleaseInBGs = false,
	autoSkinning = false,
	
	-- UI automation
	autoSkipCutscenes = true,
	hideZoneText = false,
	hideBossEmotes = false,
	hideErrorMessages = false,
	autoConfirmLootRoll = false,
	autoConfirmBind = false,
	autoConfirmDisenchant = false,
	
	-- Miscellaneous
	fastWaypoints = true,
	autoAcceptPartySync = false,
	dismountInWater = true,
	autoEquipCompare = true,
}

function Automation:OnInitialize()
	-- Database will be setup by parent addon first
end

function Automation:OnEnable()
	-- Now setup the database namespace
	if not self.db then
		self.db = Weevil.db:RegisterNamespace("Automation", {
			profile = self.defaults
		})
	end
	
	-- Register events for quest automation
	if self.db.profile.autoAcceptQuests or self.db.profile.autoTurnInQuests or self.db.profile.autoGossip then
		self:RegisterEvent("QUEST_DETAIL")
		self:RegisterEvent("QUEST_PROGRESS")
		self:RegisterEvent("QUEST_COMPLETE")
		self:RegisterEvent("GOSSIP_SHOW")
		self:RegisterEvent("QUEST_GREETING")
	end
	
	-- Register events for merchant automation
	if self.db.profile.autoRepair or self.db.profile.autoSellJunk or self.db.profile.autoSellGrey then
		self:RegisterEvent("MERCHANT_SHOW")
	end
	
	-- Register events for social automation
	if self.db.profile.autoAcceptRes then
		self:RegisterEvent("RESURRECT_REQUEST")
	end
	
	if self.db.profile.autoInvite then
		self:RegisterEvent("CHAT_MSG_WHISPER")
		self:RegisterEvent("CHAT_MSG_BN_WHISPER")
	end
	
	if self.db.profile.autoDeclineDuels then
		self:RegisterEvent("DUEL_REQUESTED")
	end
	
	if self.db.profile.autoDeclineParty then
		self:RegisterEvent("PARTY_INVITE_REQUEST")
	end
	
	-- Register events for cutscenes
	if self.db.profile.autoSkipCutscenes then
		self:RegisterEvent("CINEMATIC_START")
		self:RegisterEvent("PLAY_MOVIE")
	end
	
	-- Register events for summons
	if self.db.profile.autoAcceptSummon then
		self:RegisterEvent("CONFIRM_SUMMON")
	end
	
	-- Register events for battlegrounds
	if self.db.profile.autoReleaseInBGs then
		self:RegisterEvent("PLAYER_DEAD")
	end
	
	-- Register events for loot
	if self.db.profile.autoGreed or self.db.profile.autoGreedBlue then
		self:RegisterEvent("START_LOOT_ROLL")
	end
	
	-- Register events for UI automation
	if self.db.profile.hideZoneText then
		ZoneTextFrame:Hide()
		ZoneTextFrame:SetScript("OnShow", function(self) self:Hide() end)
	end
	
	if self.db.profile.hideBossEmotes then
		RaidBossEmoteFrame:UnregisterAllEvents()
	end
	
	-- Faster looting
	if self.db.profile.fasterLooting then
		SetCVar("autoLootDelay", "0")
	end
	
	-- Auto equipment comparison
	if self.db.profile.autoEquipCompare then
		SetCVar("alwaysCompareItems", "1")
	end
	
	-- Dismount in water
	if self.db.profile.dismountInWater then
		SetCVar("autoUnshift", "1")
	end
	
	-- Static popup automation
	if self.db.profile.autoConfirmBind or self.db.profile.autoConfirmDisenchant or self.db.profile.autoConfirmLootRoll then
		self:HookStaticPopups()
	end
	
	Weevil:Print(L["Automation"] .. " module enabled with " .. self:CountEnabledFeatures() .. " features active")
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

-- Helper: Count enabled features
function Automation:CountEnabledFeatures()
	local count = 0
	for key, value in pairs(self.db.profile) do
		if type(value) == "boolean" and value == true then
			count = count + 1
		end
	end
	return count
end

-- Auto Gossip (skip NPC chat)
function Automation:GOSSIP_SHOW()
	if self.db.profile.autoGossip then
		if GetNumGossipOptions() == 1 then
			SelectGossipOption(1)
		elseif GetNumGossipAvailableQuests() > 0 then
			-- Auto-select first available quest
			SelectGossipAvailableQuest(1)
		elseif GetNumGossipActiveQuests() > 0 then
			-- Auto-select first active quest
			SelectGossipActiveQuest(1)
		end
	end
end

function Automation:QUEST_GREETING()
	if self.db.profile.autoGossip then
		if GetNumAvailableQuests() > 0 then
			SelectAvailableQuest(1)
		elseif GetNumActiveQuests() > 0 then
			SelectActiveQuest(1)
		end
	end
end

-- Auto Invite
function Automation:CHAT_MSG_WHISPER(event, text, sender)
	if self.db.profile.autoInvite and text then
		local keyword = self.db.profile.autoInviteKeyword:lower()
		if text:lower():find(keyword) then
			-- Check if sender is in guild or friends
			if C_FriendList.IsFriend(sender) or IsInGuild() then
				InviteUnit(sender)
				Weevil:Printf("Auto-invited %s", sender)
			end
		end
	end
end

function Automation:CHAT_MSG_BN_WHISPER(event, text, sender)
	-- Battle.net whisper auto invite
	if self.db.profile.autoInvite and text then
		local keyword = self.db.profile.autoInviteKeyword:lower()
		if text:lower():find(keyword) then
			-- BNet invite handling would go here
		end
	end
end

-- Auto Decline Duels
function Automation:DUEL_REQUESTED(event, sender)
	if self.db.profile.autoDeclineDuels then
		CancelDuel()
	end
end

-- Auto Decline Party Invites
function Automation:PARTY_INVITE_REQUEST(event, sender)
	if self.db.profile.autoDeclineParty then
		DeclineGroup()
	end
end

-- Auto Greed on loot rolls
function Automation:START_LOOT_ROLL(event, rollID)
	if not self.db.profile.autoGreed and not self.db.profile.autoGreedBlue then return end
	
	local _, _, _, quality = GetLootRollItemInfo(rollID)
	
	-- Quality: 0=Poor, 1=Common, 2=Uncommon(green), 3=Rare(blue), 4=Epic(purple)
	if quality == 2 and self.db.profile.autoGreed then
		-- Green items
		RollOnLoot(rollID, 2) -- 2 = Greed
	elseif quality == 3 and self.db.profile.autoGreedBlue then
		-- Blue items
		RollOnLoot(rollID, 2) -- 2 = Greed
	end
end

-- Hook static popups for auto-confirmation
function Automation:HookStaticPopups()
	-- Auto-confirm bind on equip
	if self.db.profile.autoConfirmBind then
		hooksecurefunc(StaticPopupDialogs, "EQUIP_BIND", function()
			if StaticPopup_Visible("EQUIP_BIND") then
				StaticPopup1Button1:Click()
			end
		end)
	end
	
	-- Auto-confirm disenchant
	if self.db.profile.autoConfirmDisenchant then
		hooksecurefunc(StaticPopupDialogs, "LOOT_BIND", function()
			if StaticPopup_Visible("LOOT_BIND") then
				StaticPopup1Button1:Click()
			end
		end)
	end
end
