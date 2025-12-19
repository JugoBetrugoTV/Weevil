--- **AceDB-3.0** provides a framework for saved variables management.
-- @class file
-- @name AceDB-3.0.lua
-- @release $Id: AceDB-3.0.lua 1221 2019-07-03 20:23:03Z nevcairiel $

local ACEDB_MAJOR, ACEDB_MINOR = "AceDB-3.0", 27
local AceDB, oldminor = LibStub:NewLibrary(ACEDB_MAJOR, ACEDB_MINOR)

if not AceDB then return end

AceDB.db_registry = AceDB.db_registry or {}
AceDB.frame = AceDB.frame or CreateFrame("Frame")

local CallbackHandler
local CallbackDummy = { Fire = function() end }

local function initdb(parent, name, defaults, defaultProfile, olddb)
	local sv = getglobal(name)
	
	if not sv then
		sv = {}
		setglobal(name, sv)
	end
	
	local db = {}
	db.sv = sv
	db.keys = {}
	db.parent = parent
	
	if not sv.profileKeys then sv.profileKeys = {} end
	if not sv.profiles then sv.profiles = {} end
	
	local char = UnitName("player") .. " - " .. GetRealmName()
	db.keys.profile = sv.profileKeys[char] or defaultProfile or "Default"
	
	if not sv.profiles[db.keys.profile] then
		sv.profiles[db.keys.profile] = {}
	end
	
	db.profile = sv.profiles[db.keys.profile]
	
	if not sv.global then sv.global = {} end
	db.global = sv.global
	
	if not sv.char then sv.char = {} end
	if not sv.char[char] then sv.char[char] = {} end
	db.char = sv.char[char]
	
	local mt = {
		__index = function(t, k)
			if defaults and defaults[k] ~= nil then
				return defaults[k]
			end
		end
	}
	
	setmetatable(db.profile, mt)
	setmetatable(db.global, mt)
	setmetatable(db.char, mt)
	
	return db
end

function AceDB:New(name, defaults, defaultProfile)
	if type(name) ~= "string" then
		error("Usage: AceDB:New(name, defaults, defaultProfile): 'name' - string expected.", 2)
	end
	
	local db = initdb(self, name, defaults, defaultProfile)
	
	-- Add reset functions
	function db:ResetProfile()
		local profile = self.keys.profile
		self.sv.profiles[profile] = {}
		self.profile = self.sv.profiles[profile]
	end
	
	function db:ResetDB()
		for k,v in pairs(self.sv) do
			self.sv[k] = nil
		end
		initdb(self.parent, name, defaults, defaultProfile, self)
	end
	
	function db:SetProfile(name)
		local char = UnitName("player") .. " - " .. GetRealmName()
		self.sv.profileKeys[char] = name
		self.keys.profile = name
		
		if not self.sv.profiles[name] then
			self.sv.profiles[name] = {}
		end
		self.profile = self.sv.profiles[name]
	end
	
	function db:GetCurrentProfile()
		return self.keys.profile
	end
	
	function db:GetProfiles(tbl)
		tbl = tbl or {}
		for profileKey in pairs(self.sv.profiles) do
			tbl[profileKey] = profileKey
		end
		return tbl
	end
	
	function db:DeleteProfile(name)
		if self.keys.profile == name then
			return false
		end
		self.sv.profiles[name] = nil
		return true
	end
	
	function db:CopyProfile(name)
		if name == self.keys.profile then
			return false
		end
		if not self.sv.profiles[name] then
			return false
		end
		
		for k,v in pairs(self.sv.profiles[name]) do
			if type(v) == "table" then
				self.profile[k] = {}
				for k2,v2 in pairs(v) do
					self.profile[k][k2] = v2
				end
			else
				self.profile[k] = v
			end
		end
		return true
	end
	
	return db
end

function AceDB:OnEmbedDisable(target)
	if AceDB.db_registry[target] then
		AceDB:ReleaseDBNamespace(target, AceDB.db_registry[target])
	end
end

local function copyDefaults(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if not rawget(dest, k) then rawset(dest, k, {}) end
			if type(dest[k]) == "table" then
				copyDefaults(dest[k], v)
			end
		else
			if rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end
end

AceDB.embeds = AceDB.embeds or {}

local mixins = {
	"RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks",
	"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages",
	"SendMessage",
}

function AceDB:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(AceDB.embeds) do
	AceDB:Embed(target)
end
