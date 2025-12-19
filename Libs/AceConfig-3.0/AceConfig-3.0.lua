--- **AceConfig-3.0** provides a framework for configuration options.
-- @class file
-- @name AceConfig-3.0.lua
-- @release $Id: AceConfig-3.0.lua 1239 2019-08-01 10:25:50Z nevcairiel $
local ACECONFIG_MAJOR, ACECONFIG_MINOR = "AceConfig-3.0", 3
local AceConfig = LibStub:NewLibrary(ACECONFIG_MAJOR, ACECONFIG_MINOR)

if not AceConfig then return end

AceConfig.optionTables = AceConfig.optionTables or {}

function AceConfig:RegisterOptionsTable(appName, options, slashcmd)
	if type(appName) ~= "string" then
		error("Usage: RegisterOptionsTable(appName, options[, slashcmd]): 'appName' - string expected.", 2)
	end
	if type(options) ~= "table" and type(options) ~= "function" then
		error("Usage: RegisterOptionsTable(appName, options[, slashcmd]): 'options' - table or function expected.", 2)
	end
	
	self.optionTables[appName] = options
	
	if slashcmd then
		if type(slashcmd) == "table" then
			for i, cmd in ipairs(slashcmd) do
				_G["SLASH_" .. appName .. i] = "/" .. cmd
			end
		else
			_G["SLASH_" .. appName .. "1"] = "/" .. slashcmd
		end
		SlashCmdList[appName] = function()
			local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
			if AceConfigDialog then
				AceConfigDialog:Open(appName)
			end
		end
	end
	
	return appName
end

function AceConfig:GetOptionsTable(appName)
	local tbl = self.optionTables[appName]
	if type(tbl) == "function" then
		tbl = tbl()
	end
	return tbl
end
