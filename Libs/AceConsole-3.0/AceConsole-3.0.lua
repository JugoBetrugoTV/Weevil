--- **AceConsole-3.0** provides registration for slash commands.
-- @class file
-- @name AceConsole-3.0.lua
-- @release $Id: AceConsole-3.0.lua 1202 2019-05-15 23:11:22Z nevcairiel $
local MAJOR, MINOR = "AceConsole-3.0", 7
local AceConsole = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConsole then return end

AceConsole.embeds = AceConsole.embeds or {}
AceConsole.commands = AceConsole.commands or {}

local mixins = {
	"RegisterChatCommand", "UnregisterChatCommand",
	"Print", "Printf",
}

function AceConsole:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

function AceConsole:RegisterChatCommand(command, func, persist)
	if type(command) ~= "string" then error("Usage: RegisterChatCommand(command, func): 'command' - string expected.", 2) end
	
	if type(func) == "string" then
		SlashCmdList[command] = function(msg, editBox)
			self[func](self, msg, editBox)
		end
	else
		SlashCmdList[command] = func
	end
	
	_G["SLASH_" .. command .. "1"] = "/" .. command:lower()
	
	self.commands[command] = true
end

function AceConsole:UnregisterChatCommand(command)
	if self.commands[command] then
		SlashCmdList[command] = nil
		_G["SLASH_" .. command .. "1"] = nil
		self.commands[command] = nil
	end
end

function AceConsole:Print(...)
	print("|cff33ff99" .. (self.name or "Addon") .. ":|r", ...)
end

function AceConsole:Printf(fmt, ...)
	self:Print(string.format(fmt, ...))
end

for addon in pairs(AceConsole.embeds) do
	AceConsole:Embed(addon)
end
