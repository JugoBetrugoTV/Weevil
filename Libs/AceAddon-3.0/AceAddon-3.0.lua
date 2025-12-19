--- **AceAddon-3.0** provides a framework for addon creation and management.
-- @class file
-- @name AceAddon-3.0
-- @release $Id: AceAddon-3.0.lua 1238 2019-07-11 03:49:15Z nevcairiel $
local MAJOR, MINOR = "AceAddon-3.0", 13
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end

AceAddon.frame = AceAddon.frame or CreateFrame("Frame", "AceAddon30Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end })

local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local fmt, tostring = string.format, tostring
local select, pairs, next, type, unpack = select, pairs, next, type, unpack
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget

xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

-- Embed handling
local mixins = {
	"NewAddon", "GetAddon", "GetName", "SetDefaultModuleState",
	"SetDefaultModuleLibraries", "SetDefaultModulePrototype",
	"SetEnabledState", "IsEnabled",
	"EnableAddon", "DisableAddon",
	"GetModule", "NewModule", "IterateModules", "GetNumModules",
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents",
	"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages",
	"SendMessage"
}

function AceAddon:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

-- AceAddon:NewAddon( name, [lib, lib, lib, ...] )
function AceAddon:NewAddon(objname, ...)
	if type(objname) ~= "string" then error("Usage: NewAddon(name, [lib, ...]): 'name' - string expected.", 2) end
	if self.addons[objname] then error("Usage: NewAddon(name, [lib, ...]): 'name' - Addon '"..objname.."' already exists.", 2) end
	
	local addon = setmetatable({modules = {}, orderedModules = {}, name = objname, enabledState = true}, {__index = AceAddon})
	addon.frame = CreateFrame("Frame")
	
	self.addons[objname] = addon
	self:EmbedLibraries(addon, ...)
	
	safecall(self.InitializeAddon, self, addon, objname)
	
	tinsert(self.initializequeue, addon)
	
	return addon
end

function AceAddon:GetAddon(name)
	return self.addons[name]
end

function AceAddon:EmbedLibraries(addon, ...)
	local libs = {...}
	for i = 1, #libs do
		local lib = LibStub(libs[i], true)
		if lib then
			lib:Embed(addon)
		end
	end
end

function AceAddon:InitializeAddon(addon, objname)
	addon.name = objname
	addon.modules = {}
	addon.orderedModules = {}
end

function AceAddon:EnableAddon(addon)
	addon:SetEnabledState(true)
	if type(addon.OnEnable) == "function" then
		safecall(addon.OnEnable, addon)
	end
	
	for i = 1, #addon.orderedModules do
		local module = addon.orderedModules[i]
		if module:IsEnabled() and type(module.OnEnable) == "function" then
			safecall(module.OnEnable, module)
		end
	end
end

function AceAddon:DisableAddon(addon)
	if type(addon.OnDisable) == "function" then
		safecall(addon.OnDisable, addon)
	end
	addon:SetEnabledState(false)
end

local function Enable(self)
	return AceAddon:EnableAddon(self)
end

local function Disable(self)
	return AceAddon:DisableAddon(self)
end

function AceAddon:SetEnabledState(state)
	self.enabledState = state
end

function AceAddon:IsEnabled()
	return self.enabledState
end

function AceAddon:GetName()
	return self.name
end

function AceAddon:NewModule(name, ...)
	if type(name) ~= "string" then error("Usage: NewModule(name, [lib, ...]): 'name' - string expected.", 2) end
	if self.modules[name] then error("Usage: NewModule(name, [lib, ...]): 'name' - Module '"..name.."' already exists.", 2) end
	
	local module = setmetatable({name = name, enabledState = true}, {__index = self})
	self.modules[name] = module
	tinsert(self.orderedModules, module)
	
	AceAddon:EmbedLibraries(module, ...)
	
	safecall(self.InitializeModule, self, module, name)
	
	return module
end

function AceAddon:GetModule(name)
	return self.modules[name]
end

function AceAddon:IterateModules()
	return pairs(self.modules)
end

function AceAddon:InitializeModule(module, name)
	module.name = name
end

-- Event frame
AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
AceAddon.frame:SetScript("OnEvent", function(this, event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		for i = 1, #AceAddon.initializequeue do
			local addon = AceAddon.initializequeue[i]
			if type(addon.OnInitialize) == "function" then
				safecall(addon.OnInitialize, addon)
			end
		end
	elseif event == "PLAYER_LOGIN" then
		for i = 1, #AceAddon.initializequeue do
			local addon = AceAddon.initializequeue[i]
			tinsert(AceAddon.enablequeue, addon)
		end
		for i = 1, #AceAddon.enablequeue do
			AceAddon:EnableAddon(AceAddon.enablequeue[i])
		end
	end
end)

for addon in pairs(AceAddon.embeds) do
	AceAddon:Embed(addon)
end
