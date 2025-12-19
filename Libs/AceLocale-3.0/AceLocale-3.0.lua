--- **AceLocale-3.0** manages localization in addons.
-- @class file
-- @name AceLocale-3.0.lua
-- @release $Id: AceLocale-3.0.lua 1035 2011-07-09 03:20:13Z kaelten $
local MAJOR, MINOR = "AceLocale-3.0", 6

local AceLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceLocale then return end

AceLocale.apps = AceLocale.apps or {}
AceLocale.appnames = AceLocale.appnames or {}

local function addstr(self, key, val)
	if rawget(self, key) then return end
	rawset(self, key, val == true and key or val)
end

local function addtable(self, source)
	for k, v in pairs(source) do
		addstr(self, k, v)
	end
end

local mt = {
	__index = function(t, k)
		rawset(t, k, k)
		return k
	end,
	__newindex = addstr,
}

function AceLocale:NewLocale(app, locale, default)
	if not locale then return end
	
	local obj = self.apps[app] and self.apps[app][locale] or {}
	if not self.apps[app] then
		self.apps[app] = {}
	end
	self.apps[app][locale] = obj
	
	if default then
		self.appnames[app] = obj
	end
	
	if GetLocale() == locale then
		self.appnames[app] = obj
	end
	
	setmetatable(obj, mt)
	return obj
end

function AceLocale:GetLocale(app, locale)
	if not locale then
		return self.appnames[app]
	else
		return self.apps[app] and self.apps[app][locale]
	end
end
