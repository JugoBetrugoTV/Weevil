--- **AceEvent-3.0** provides event registration and secure dispatching.
-- @class file
-- @name AceEvent-3.0.lua
-- @release $Id: AceEvent-3.0.lua 1202 2019-05-15 23:11:22Z nevcairiel $
local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end

AceEvent.frame = AceEvent.frame or CreateFrame("Frame", "AceEvent30Frame")
AceEvent.embeds = AceEvent.embeds or {}

local CallbackHandler = LibStub("CallbackHandler-1.0")

AceEvent.events = AceEvent.events or CallbackHandler:New(AceEvent,
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")

function AceEvent.events:OnUsed(target, eventname)
	AceEvent.frame:RegisterEvent(eventname)
end

function AceEvent.events:OnUnused(target, eventname)
	AceEvent.frame:UnregisterEvent(eventname)
end

AceEvent.frame:SetScript("OnEvent", function(this, event, ...)
	AceEvent.events:Fire(event, ...)
end)

--- embedding and embed handling
local mixins = {
	"RegisterEvent", "UnregisterEvent", 
	"UnregisterAllEvents"
}

function AceEvent:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

function AceEvent:OnEmbedDisable(target)
	target:UnregisterAllEvents()
end

for addon in pairs(AceEvent.embeds) do
	AceEvent:Embed(addon)
end
