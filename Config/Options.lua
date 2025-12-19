-- Options Configuration for Weevil
-- Creates the AceConfig options table

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

function Weevil:SetupOptions()
	local options = {
		type = "group",
		name = "Weevil",
		args = {
			general = {
				name = "General",
				type = "group",
				order = 1,
				args = {
					description = {
						name = L["Quality of Life addon combining automation and info display features"],
						type = "description",
						order = 1,
					},
					spacer1 = {
						name = "",
						type = "description",
						order = 2,
					},
					version = {
						name = "Version: " .. GetAddOnMetadata("Weevil", "Version"),
						type = "description",
						order = 3,
					},
				},
			},
			automation = {
				name = L["Automation"],
				type = "group",
				order = 2,
				args = {
					header = {
						name = L["Automation Settings"],
						type = "header",
						order = 0,
					},
					autoAcceptQuests = {
						name = L["Auto Accept Quests"],
						desc = L["Automatically accept quests from NPCs"],
						type = "toggle",
						order = 1,
						get = function() return Weevil:GetModule("Automation").db.profile.autoAcceptQuests end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoAcceptQuests = value 
						end,
					},
					autoTurnInQuests = {
						name = L["Auto Turn-in Quests"],
						desc = L["Automatically complete quests"],
						type = "toggle",
						order = 2,
						get = function() return Weevil:GetModule("Automation").db.profile.autoTurnInQuests end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoTurnInQuests = value 
						end,
					},
					autoRepair = {
						name = L["Auto Repair"],
						desc = L["Automatically repair gear at vendors"],
						type = "toggle",
						order = 3,
						get = function() return Weevil:GetModule("Automation").db.profile.autoRepair end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoRepair = value 
						end,
					},
					useGuildRepair = {
						name = L["Use Guild Repair"],
						desc = L["Use guild bank funds for repairs when available"],
						type = "toggle",
						order = 4,
						disabled = function() return not Weevil:GetModule("Automation").db.profile.autoRepair end,
						get = function() return Weevil:GetModule("Automation").db.profile.useGuildRepair end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.useGuildRepair = value 
						end,
					},
					autoSellJunk = {
						name = L["Auto Sell Junk"],
						desc = L["Automatically sell gray items to vendors"],
						type = "toggle",
						order = 5,
						get = function() return Weevil:GetModule("Automation").db.profile.autoSellJunk end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoSellJunk = value 
						end,
					},
					autoAcceptRes = {
						name = L["Auto Accept Resurrect"],
						desc = L["Accept resurrection requests automatically"],
						type = "toggle",
						order = 6,
						get = function() return Weevil:GetModule("Automation").db.profile.autoAcceptRes end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoAcceptRes = value 
						end,
					},
					autoSkipCutscenes = {
						name = L["Auto Skip Cutscenes"],
						desc = L["Skip cinematics and cutscenes automatically"],
						type = "toggle",
						order = 7,
						get = function() return Weevil:GetModule("Automation").db.profile.autoSkipCutscenes end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoSkipCutscenes = value 
						end,
					},
					autoAcceptSummon = {
						name = L["Auto Accept Summon"],
						desc = L["Accept warlock summons automatically"],
						type = "toggle",
						order = 8,
						get = function() return Weevil:GetModule("Automation").db.profile.autoAcceptSummon end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoAcceptSummon = value 
						end,
					},
					autoReleaseInBGs = {
						name = L["Auto Release in BGs"],
						desc = L["Auto release spirit in battlegrounds"],
						type = "toggle",
						order = 9,
						get = function() return Weevil:GetModule("Automation").db.profile.autoReleaseInBGs end,
						set = function(_, value) 
							Weevil:GetModule("Automation").db.profile.autoReleaseInBGs = value 
						end,
					},
				},
			},
			infobar = {
				name = L["Info Bar"],
				type = "group",
				order = 3,
				args = {
					header = {
						name = L["Info Bar Settings"],
						type = "header",
						order = 0,
					},
					enabled = {
						name = L["Enable Info Bar"],
						desc = L["Show the information bar"],
						type = "toggle",
						order = 1,
						get = function() return Weevil:GetModule("InfoBar").db.profile.enabled end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.enabled = value
							if value then
								Weevil:GetModule("InfoBar"):ShowBar()
								Weevil:GetModule("InfoBar"):StartUpdates()
							else
								Weevil:GetModule("InfoBar"):HideBar()
								Weevil:GetModule("InfoBar"):StopUpdates()
							end
						end,
					},
					position = {
						name = L["Position"],
						desc = L["Choose where to display the info bar"],
						type = "select",
						order = 2,
						values = {
							TOP = L["Top"],
							BOTTOM = L["Bottom"],
						},
						get = function() return Weevil:GetModule("InfoBar").db.profile.position end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.position = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					barScale = {
						name = L["Bar Scale"],
						desc = L["Set the scale of the info bar"],
						type = "range",
						order = 3,
						min = 0.8,
						max = 1.5,
						step = 0.05,
						get = function() return Weevil:GetModule("InfoBar").db.profile.barScale end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.barScale = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					barHeight = {
						name = L["Bar Height"],
						desc = L["Set the height of the info bar"],
						type = "range",
						order = 4,
						min = 18,
						max = 32,
						step = 1,
						get = function() return Weevil:GetModule("InfoBar").db.profile.barHeight end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.barHeight = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					fontSize = {
						name = L["Font Size"],
						desc = L["Set the font size for the info bar"],
						type = "range",
						order = 5,
						min = 9,
						max = 16,
						step = 1,
						get = function() return Weevil:GetModule("InfoBar").db.profile.fontSize end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.fontSize = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					offsetFromEdge = {
						name = L["Offset From Edge"],
						desc = L["Set distance from screen edge"],
						type = "range",
						order = 6,
						min = 0,
						max = 50,
						step = 1,
						get = function() return Weevil:GetModule("InfoBar").db.profile.offsetFromEdge end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.offsetFromEdge = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					bgAlpha = {
						name = L["Background Alpha"],
						desc = L["Set the transparency of the info bar background"],
						type = "range",
						order = 7,
						min = 0,
						max = 1,
						step = 0.05,
						get = function() return Weevil:GetModule("InfoBar").db.profile.bgColor.a end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.bgColor.a = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					useClassColor = {
						name = L["Use Class Color"],
						desc = L["Use your class color for the accent"],
						type = "toggle",
						order = 8,
						get = function() return Weevil:GetModule("InfoBar").db.profile.useClassColor end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.useClassColor = value
							Weevil:GetModule("InfoBar"):UpdateBarAppearance()
						end,
					},
					autoHideInCombat = {
						name = L["Auto Hide In Combat"],
						desc = L["Hide the bar when entering combat"],
						type = "toggle",
						order = 9,
						get = function() return Weevil:GetModule("InfoBar").db.profile.autoHideInCombat end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.autoHideInCombat = value
						end,
					},
					spacer1 = {
						name = "",
						type = "description",
						order = 10,
					},
					performanceHeader = {
						name = L["Performance Displays"],
						type = "header",
						order = 11,
					},
					showFPS = {
						name = L["Show FPS"],
						desc = L["Display frames per second"],
						type = "toggle",
						order = 12,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showFPS end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showFPS = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showLatency = {
						name = L["Show Latency"],
						desc = L["Display home and world latency"],
						type = "toggle",
						order = 13,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showLatency end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showLatency = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showMemory = {
						name = L["Show Memory"],
						desc = L["Display addon memory usage"],
						type = "toggle",
						order = 14,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showMemory end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showMemory = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					spacer2 = {
						name = "",
						type = "description",
						order = 20,
					},
					characterHeader = {
						name = L["Character Displays"],
						type = "header",
						order = 21,
					},
					showBags = {
						name = L["Show Bag Space"],
						desc = L["Display free bag slots"],
						type = "toggle",
						order = 22,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showBags end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showBags = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showDurability = {
						name = L["Show Durability"],
						desc = L["Display average item durability"],
						type = "toggle",
						order = 23,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showDurability end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showDurability = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showItemLevel = {
						name = L["Show Item Level"],
						desc = L["Display average item level"],
						type = "toggle",
						order = 24,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showItemLevel end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showItemLevel = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showTalentSpec = {
						name = L["Show Talent Spec"],
						desc = L["Display current specialization"],
						type = "toggle",
						order = 25,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showTalentSpec end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showTalentSpec = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showXP = {
						name = L["Show XP"],
						desc = L["Display experience progress"],
						type = "toggle",
						order = 26,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showXP end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showXP = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showReputation = {
						name = L["Show Reputation"],
						desc = L["Display watched faction reputation"],
						type = "toggle",
						order = 27,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showReputation end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showReputation = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					spacer3 = {
						name = "",
						type = "description",
						order = 30,
					},
					locationHeader = {
						name = L["Location & Time Displays"],
						type = "header",
						order = 31,
					},
					showLocation = {
						name = L["Show Location"],
						desc = L["Display current zone and coordinates"],
						type = "toggle",
						order = 32,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showLocation end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showLocation = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showCoordinates = {
						name = L["Show Coordinates"],
						desc = L["Display player coordinates"],
						type = "toggle",
						order = 33,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showCoordinates end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showCoordinates = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showClock = {
						name = L["Show Clock"],
						desc = L["Display server and local time"],
						type = "toggle",
						order = 34,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showClock end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showClock = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					show24HourTime = {
						name = L["24 Hour Format"],
						desc = L["Use 24-hour time format"],
						type = "toggle",
						order = 35,
						get = function() return Weevil:GetModule("InfoBar").db.profile.show24HourTime end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.show24HourTime = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					spacer4 = {
						name = "",
						type = "description",
						order = 40,
					},
					socialHeader = {
						name = L["Social & Currency Displays"],
						type = "header",
						order = 41,
					},
					showGold = {
						name = L["Show Gold"],
						desc = L["Display current gold"],
						type = "toggle",
						order = 42,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showGold end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showGold = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showFriends = {
						name = L["Show Friends"],
						desc = L["Display online friends count"],
						type = "toggle",
						order = 43,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showFriends end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showFriends = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showGuild = {
						name = L["Show Guild"],
						desc = L["Display online guild members"],
						type = "toggle",
						order = 44,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showGuild end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showGuild = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
					showQuestLog = {
						name = L["Show Quest Log"],
						desc = L["Display quest count"],
						type = "toggle",
						order = 45,
						get = function() return Weevil:GetModule("InfoBar").db.profile.showQuestLog end,
						set = function(_, value) 
							Weevil:GetModule("InfoBar").db.profile.showQuestLog = value
							Weevil:GetModule("InfoBar"):UpdateDisplay()
						end,
					},
				},
			},
			chat = {
				name = L["Chat"],
				type = "group",
				order = 4,
				args = {
					header = {
						name = L["Chat Settings"],
						type = "header",
						order = 0,
					},
					enableChatCopy = {
						name = L["Enable Chat Copy"],
						desc = L["Allow copying of chat text"],
						type = "toggle",
						order = 1,
						get = function() return Weevil:GetModule("Chat").db.profile.enableChatCopy end,
						set = function(_, value) 
							Weevil:GetModule("Chat").db.profile.enableChatCopy = value
						end,
					},
					timestamps = {
						name = L["Chat Timestamps"],
						desc = L["Show timestamps in chat"],
						type = "toggle",
						order = 2,
						get = function() return Weevil:GetModule("Chat").db.profile.timestamps end,
						set = function(_, value) 
							Weevil:GetModule("Chat").db.profile.timestamps = value
							if value then
								Weevil:GetModule("Chat"):EnableTimestamps()
							end
						end,
					},
					urlDetection = {
						name = L["URL Detection"],
						desc = L["Detect and copy URLs from chat"],
						type = "toggle",
						order = 3,
						get = function() return Weevil:GetModule("Chat").db.profile.urlDetection end,
						set = function(_, value) 
							Weevil:GetModule("Chat").db.profile.urlDetection = value
						end,
					},
					classColoredNames = {
						name = L["Class Colored Names"],
						desc = L["Color player names by class in chat"],
						type = "toggle",
						order = 4,
						get = function() return Weevil:GetModule("Chat").db.profile.classColoredNames end,
						set = function(_, value) 
							Weevil:GetModule("Chat").db.profile.classColoredNames = value
							if value then
								Weevil:GetModule("Chat"):EnableClassColors()
							end
						end,
					},
					stickyChannels = {
						name = L["Sticky Channels"],
						desc = L["Remember the last chat channel used"],
						type = "toggle",
						order = 5,
						get = function() return Weevil:GetModule("Chat").db.profile.stickyChannels end,
						set = function(_, value) 
							Weevil:GetModule("Chat").db.profile.stickyChannels = value
							if value then
								Weevil:GetModule("Chat"):EnableStickyChannels()
							end
						end,
					},
				},
			},
			ui = {
				name = L["UI"],
				type = "group",
				order = 5,
				args = {
					header = {
						name = L["UI Settings"],
						type = "header",
						order = 0,
					},
					hideErrorFrame = {
						name = L["Hide Error Frame"],
						desc = L["Hide the red error text"],
						type = "toggle",
						order = 1,
						get = function() return Weevil:GetModule("UI").db.profile.hideErrorFrame end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.hideErrorFrame = value
							if value then
								Weevil:GetModule("UI"):HideErrorFrame()
							end
						end,
					},
					fasterAutoLoot = {
						name = L["Faster Auto Loot"],
						desc = L["Instant auto looting"],
						type = "toggle",
						order = 2,
						get = function() return Weevil:GetModule("UI").db.profile.fasterAutoLoot end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.fasterAutoLoot = value
							if value then
								Weevil:GetModule("UI"):EnableFasterAutoLoot()
							end
						end,
					},
					screenshotAchievements = {
						name = L["Screenshot Achievements"],
						desc = L["Automatically screenshot when earning achievements"],
						type = "toggle",
						order = 3,
						get = function() return Weevil:GetModule("UI").db.profile.screenshotAchievements end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.screenshotAchievements = value
						end,
					},
					enhancedTooltips = {
						name = L["Enhanced Tooltips"],
						desc = L["Show item level and spell IDs in tooltips"],
						type = "toggle",
						order = 4,
						get = function() return Weevil:GetModule("UI").db.profile.enhancedTooltips end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.enhancedTooltips = value
						end,
					},
					confirmLootRoll = {
						name = L["Confirm Loot Roll"],
						desc = L["Require confirmation for passing on loot"],
						type = "toggle",
						order = 5,
						get = function() return Weevil:GetModule("UI").db.profile.confirmLootRoll end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.confirmLootRoll = value
						end,
					},
					hideTalkingHead = {
						name = L["Hide Talking Head"],
						desc = L["Hide the talking head frame"],
						type = "toggle",
						order = 6,
						get = function() return Weevil:GetModule("UI").db.profile.hideTalkingHead end,
						set = function(_, value) 
							Weevil:GetModule("UI").db.profile.hideTalkingHead = value
							if value then
								Weevil:GetModule("UI"):HideTalkingHead()
							end
						end,
					},
				},
			},
			profiles = {
				name = L["Profiles"],
				type = "group",
				order = 10,
				args = {},
			},
		},
	}
	
	-- Register options with AceConfig
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local AceDBOptions = LibStub("AceDBOptions-3.0")
	
	AceConfig:RegisterOptionsTable("Weevil", options)
	AceConfigDialog:AddToBlizOptions("Weevil", "Weevil")
	
	-- Add profiles
	options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
	AceConfigDialog:AddToBlizOptions("Weevil-Profiles", L["Profiles"], "Weevil")
end
