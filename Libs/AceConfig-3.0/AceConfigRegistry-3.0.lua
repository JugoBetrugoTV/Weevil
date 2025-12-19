--- **AceConfigRegistry-3.0** manages option tables.
-- @class file
-- @name AceConfigRegistry-3.0.lua
-- @release $Id: AceConfigRegistry-3.0.lua 1202 2019-05-15 23:11:22Z nevcairiel $
local REGISTRY_MAJOR, REGISTRY_MINOR = "AceConfigRegistry-3.0", 18
local AceConfigRegistry = LibStub:NewLibrary(REGISTRY_MAJOR, REGISTRY_MINOR)

if not AceConfigRegistry then return end

AceConfigRegistry.tables = AceConfigRegistry.tables or {}

function AceConfigRegistry:RegisterOptionsTable(appName, optionTable)
	if type(appName) ~= "string" then
		error("Usage: RegisterOptionsTable(appName, optionTable): 'appName' - string expected.", 2)
	end
	if type(optionTable) ~= "table" and type(optionTable) ~= "function" then
		error("Usage: RegisterOptionsTable(appName, optionTable): 'optionTable' - table or function expected.", 2)
	end
	
	self.tables[appName] = optionTable
	return appName
end

function AceConfigRegistry:GetOptionsTable(appName)
	if not self.tables[appName] then
		return nil, ("Unknown options table %q"):format(tostring(appName))
	end
	
	local tbl = self.tables[appName]
	if type(tbl) == "function" then
		tbl = tbl()
	end
	
	return tbl
end

function AceConfigRegistry:ValidateOptionsTable(options, name)
	-- Basic validation stub
	return true
end

function AceConfigRegistry:NotifyChange(appName)
	-- Notification stub for option changes
end
