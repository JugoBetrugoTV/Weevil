--- **AceConfigDialog-3.0** provides a dialog for configuration.
-- @class file
-- @name AceConfigDialog-3.0.lua
-- @release $Id: AceConfigDialog-3.0.lua 1239 2019-08-01 10:25:50Z nevcairiel $
local DIALOG_MAJOR, DIALOG_MINOR = "AceConfigDialog-3.0", 78
local AceConfigDialog = LibStub:NewLibrary(DIALOG_MAJOR, DIALOG_MINOR)

if not AceConfigDialog then return end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceGUI = LibStub("AceGUI-3.0")

AceConfigDialog.OpenFrames = AceConfigDialog.OpenFrames or {}
AceConfigDialog.Status = AceConfigDialog.Status or {}

function AceConfigDialog:Open(appName, container, ...)
	local optionTable = AceConfigRegistry:GetOptionsTable(appName)
	if not optionTable then
		error(("Cannot find options table for %q"):format(appName), 2)
	end
	
	-- Create or reuse interface options panel
	if not self.OpenFrames[appName] then
		local f = CreateFrame("Frame", appName .. "OptionsPanel", InterfaceOptionsFramePanelContainer)
		f.name = optionTable.name or appName
		f:Hide()
		f:SetAllPoints()
		
		local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText(f.name)
		
		InterfaceOptions_AddCategory(f)
		
		self.OpenFrames[appName] = f
	end
	
	-- Show interface options
	InterfaceOptionsFrame_OpenToCategory(self.OpenFrames[appName])
	InterfaceOptionsFrame_OpenToCategory(self.OpenFrames[appName]) -- Call twice to ensure it opens
	
	return self.OpenFrames[appName]
end

function AceConfigDialog:Close(appName)
	if self.OpenFrames[appName] then
		self.OpenFrames[appName]:Hide()
	end
end

function AceConfigDialog:AddToBlizOptions(appName, name, parent, ...)
	local optionTable = AceConfigRegistry:GetOptionsTable(appName)
	if not optionTable then
		error(("Cannot find options table for %q"):format(appName), 2)
	end
	
	local frame = CreateFrame("Frame", appName .. "BlizOptionsPanel", InterfaceOptionsFramePanelContainer)
	frame.name = name or appName
	frame.parent = parent
	frame:Hide()
	frame:SetAllPoints()
	
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(frame.name)
	
	InterfaceOptions_AddCategory(frame)
	
	return frame
end

function AceConfigDialog:SetDefaultSize(appName, width, height)
	self.Status[appName] = self.Status[appName] or {}
	self.Status[appName].width = width
	self.Status[appName].height = height
end
