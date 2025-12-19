--[[
LibDataBroker-1.1 by Tekkub
LibDataBroker is a small WoW addon library designed to provide a modus
of operation for addons to populate minimap buttons and more.
]]

local MAJOR, MINOR = "LibDataBroker-1.1", 4
assert(LibStub, MAJOR.." requires LibStub")
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, callbacks = lib.attributestorage, lib.namestorage, lib.callbacks

local function CreateObjectData(dataobj, name)
	namestorage[dataobj] = name
	attributestorage[name] = {}
	
	for i,v in pairs(dataobj) do
		attributestorage[name][i] = v
	end
end

-- Object creation and management
local function New(name, dataobj)
	if not name or not dataobj then return end
	if attributestorage[name] then return end
	
	CreateObjectData(dataobj, name)
	
	callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj)
	return dataobj
end

-- API
function lib:NewDataObject(name, dataobj)
	if attributestorage[name] then return end
	
	dataobj = dataobj or {}
	CreateObjectData(dataobj, name)
	
	callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj)
	return dataobj
end

function lib:DataObjectIterator()
	return pairs(attributestorage)
end

function lib:GetDataObjectByName(name)
	return attributestorage[name]
end

function lib:GetNameByDataObject(dataobj)
	return namestorage[dataobj]
end

local function __index(self, key)
	local name = namestorage[self]
	if not name then return end
	return attributestorage[name][key]
end

local function __newindex(self, key, value)
	local name = namestorage[self]
	if not name then return end
	
	local oldvalue = attributestorage[name][key]
	if oldvalue ~= value then
		attributestorage[name][key] = value
		callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value, self)
	end
end

-- Make existing data objects use our metatable
for name, dataobj in pairs(attributestorage) do
	setmetatable(dataobj, {__index = __index, __newindex = __newindex})
end
