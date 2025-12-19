--- **AceGUI-3.0** provides base widget functionality.
-- @class file
-- @name AceGUI-3.0.lua
-- @release $Id: AceGUI-3.0.lua 1238 2019-07-11 03:49:15Z nevcairiel $
local ACEGUI_MAJOR, ACEGUI_MINOR = "AceGUI-3.0", 41
local AceGUI, oldminor = LibStub:NewLibrary(ACEGUI_MAJOR, ACEGUI_MINOR)

if not AceGUI then return end

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.WidgetBase = AceGUI.WidgetBase or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}

-- Basic widget creation and management
function AceGUI:RegisterWidgetType(Name, Constructor, Version)
	assert(type(Constructor) == "function")
	assert(type(Version) == "number")
	
	local oldVersion = self.WidgetVersions[Name]
	if oldVersion and oldVersion >= Version then return end
	
	self.WidgetVersions[Name] = Version
	self.WidgetRegistry[Name] = Constructor
end

function AceGUI:Create(Type)
	if not self.WidgetRegistry[Type] then
		error("Attempt to create unknown widget type: " .. Type)
	end
	
	local widget = self.WidgetRegistry[Type]()
	return widget
end

-- Widget base
AceGUI.WidgetBase = {
	SetCallback = function(self, name, func)
		self.callbacks = self.callbacks or {}
		self.callbacks[name] = func
	end,
	
	Fire = function(self, name, ...)
		if self.callbacks and self.callbacks[name] then
			self.callbacks[name](self, name, ...)
		end
	end,
	
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self.width = width
	end,
	
	SetHeight = function(self, height)
		self.frame:SetHeight(height)
		self.height = height
	end,
	
	SetDisabled = function(self, disabled)
		self.disabled = disabled
	end,
	
	IsDisabled = function(self)
		return self.disabled
	end,
	
	IsVisible = function(self)
		return self.frame:IsVisible()
	end,
	
	Release = function(self)
		self.frame:Hide()
		self.frame:ClearAllPoints()
	end,
}
