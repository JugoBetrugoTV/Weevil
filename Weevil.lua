-- Weevil Main File
-- A Quality of Life addon combining automation and info display features

local ADDON_NAME = "Weevil"
local Weevil = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Version info
Weevil.version = GetAddOnMetadata(ADDON_NAME, "Version")
Weevil.author = GetAddOnMetadata(ADDON_NAME, "Author")

-- Default settings
local defaults = {
	profile = {
		minimap = {
			hide = false,
			minimapPos = 225,
		},
	},
}

function Weevil:OnInitialize()
	-- Setup database
	self.db = LibStub("AceDB-3.0"):New("WeevilDB", defaults, true)
	
	-- Setup options
	self:SetupOptions()
	
	-- Register slash commands
	self:RegisterChatCommand("weevil", "SlashCommand")
	self:RegisterChatCommand("wv", "SlashCommand")
	
	-- Print welcome message
	self:Print(string.format("v%s loaded. Type /weevil or /wv for options.", self.version))
end

function Weevil:OnEnable()
	-- Setup LibDataBroker launcher
	self:SetupLDB()
	
	-- Setup minimap icon
	self:SetupMinimapIcon()
end

function Weevil:OnDisable()
	-- Cleanup if needed
end

-- Slash command handler
function Weevil:SlashCommand(input)
	input = input:trim():lower()
	
	if input == "" or input == "options" or input == "config" then
		-- Open custom UI
		self.CustomUI:Show()
	elseif input == "infobar" or input == "bar" then
		-- Toggle InfoBar
		local infobar = self:GetModule("InfoBar")
		if infobar then
			infobar:Toggle()
			if infobar.db.profile.enabled then
				self:Print(L["Info Bar"] .. " enabled")
			else
				self:Print(L["Info Bar"] .. " disabled")
			end
		end
	elseif input == "help" then
		self:Print("Available commands:")
		self:Print("  /weevil or /wv - Open options")
		self:Print("  /weevil infobar - Toggle info bar")
		self:Print("  /weevil help - Show this help")
	else
		self:Print("Unknown command. Type /weevil help for available commands.")
	end
end

-- Setup LibDataBroker launcher
function Weevil:SetupLDB()
	local LDB = LibStub("LibDataBroker-1.1", true)
	if not LDB then return end
	
	local dataObj = LDB:NewDataObject("Weevil", {
		type = "launcher",
		text = "Weevil",
		icon = "Interface\\Icons\\INV_Misc_Dice_01",
		OnClick = function(clickedframe, button)
			if button == "LeftButton" then
				Weevil.CustomUI:Show()
			elseif button == "RightButton" then
				local infobar = Weevil:GetModule("InfoBar")
				if infobar then
					infobar:Toggle()
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("Weevil")
			tooltip:AddLine(" ")
			tooltip:AddLine("|cff00ff00Left-Click:|r Open Options", 1, 1, 1)
			tooltip:AddLine("|cff00ff00Right-Click:|r Toggle Info Bar", 1, 1, 1)
			tooltip:AddLine(" ")
			tooltip:AddLine("|cff888888Version: " .. Weevil.version .. "|r", 1, 1, 1)
		end,
	})
	
	self.LDBObj = dataObj
end

-- Setup minimap icon
function Weevil:SetupMinimapIcon()
	local icon = LibStub("LibDBIcon-1.0", true)
	if not icon or not self.LDBObj then return end
	
	icon:Register("Weevil", self.LDBObj, self.db.profile.minimap)
	
	-- Make sure icon is visible if not hidden
	if not self.db.profile.minimap.hide then
		icon:Show("Weevil")
	end
end

-- Helper function to get module safely
function Weevil:GetModuleSafe(name)
	local success, module = pcall(function() return self:GetModule(name) end)
	if success then
		return module
	end
	return nil
end
