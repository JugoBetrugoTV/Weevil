--- **AceConfigCmd-3.0** provides slash command support for AceConfig.
-- @class file
-- @name AceConfigCmd-3.0.lua
-- @release $Id: AceConfigCmd-3.0.lua 1202 2019-05-15 23:11:22Z nevcairiel $
local CMD_MAJOR, CMD_MINOR = "AceConfigCmd-3.0", 14
local AceConfigCmd = LibStub:NewLibrary(CMD_MAJOR, CMD_MINOR)

if not AceConfigCmd then return end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConsole = LibStub("AceConsole-3.0", true)

function AceConfigCmd:CreateParser(appName)
	local function parser(msg)
		local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
		if AceConfigDialog then
			AceConfigDialog:Open(appName)
		end
	end
	return parser
end

function AceConfigCmd:RegisterSlashCommand(appName, ...)
	local parser = self:CreateParser(appName)
	
	for i = 1, select("#", ...) do
		local cmd = select(i, ...)
		if cmd then
			_G["SLASH_" .. appName .. i] = "/" .. cmd
		end
	end
	
	SlashCmdList[appName] = parser
end
