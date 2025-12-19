--- **AceDBOptions-3.0** provides a universal AceConfig options screen for managing AceDB-3.0 profiles.
-- @class file
-- @name AceDBOptions-3.0
-- @release $Id: AceDBOptions-3.0.lua 1202 2019-05-15 23:11:22Z nevcairiel $
local ACEDBO_MAJOR, ACEDBO_MINOR = "AceDBOptions-3.0", 15
local AceDBOptions, oldminor = LibStub:NewLibrary(ACEDBO_MAJOR, ACEDBO_MINOR)

if not AceDBOptions then return end

local AceDB = LibStub("AceDB-3.0")

function AceDBOptions:GetOptionsTable(db, noDefaultProfiles)
	local defaults = db.defaults
	
	local options = {
		type = "group",
		name = "Profiles",
		desc = "Manage saved profiles",
		args = {
			choose = {
				name = "Existing Profiles",
				desc = "Select a profile to use",
				type = "select",
				order = 10,
				get = function() return db:GetCurrentProfile() end,
				set = function(info, value) db:SetProfile(value) end,
				values = function()
					local t = {}
					for k in pairs(db.sv.profiles) do
						t[k] = k
					end
					return t
				end,
			},
			new = {
				name = "New Profile",
				desc = "Create a new profile",
				type = "input",
				order = 20,
				get = false,
				set = function(info, value)
					if value and value ~= "" then
						db:SetProfile(value)
					end
				end,
			},
			choose_desc = {
				name = "You can select a profile to use or create a new one.",
				type = "description",
				order = 5,
			},
			reset = {
				name = "Reset Profile",
				desc = "Reset the current profile to defaults",
				type = "execute",
				order = 40,
				func = function() db:ResetProfile() end,
				confirm = true,
				confirmText = "Are you sure you want to reset the current profile?",
			},
			delete = {
				name = "Delete Profile",
				desc = "Delete an existing profile",
				type = "select",
				order = 50,
				get = false,
				set = function(info, value)
					db:DeleteProfile(value)
				end,
				values = function()
					local t = {}
					for k in pairs(db.sv.profiles) do
						if k ~= db:GetCurrentProfile() then
							t[k] = k
						end
					end
					return t
				end,
				confirm = true,
				confirmText = "Are you sure you want to delete the selected profile?",
			},
			copyfrom = {
				name = "Copy From",
				desc = "Copy settings from another profile",
				type = "select",
				order = 60,
				get = false,
				set = function(info, value)
					db:CopyProfile(value)
				end,
				values = function()
					local t = {}
					for k in pairs(db.sv.profiles) do
						if k ~= db:GetCurrentProfile() then
							t[k] = k
						end
					end
					return t
				end,
			},
		},
	}
	
	return options
end

AceDBOptions.optionTables = AceDBOptions.optionTables or {}

function AceDBOptions:RegisterOptionsTable(appName, db)
	local tbl = self:GetOptionsTable(db)
	self.optionTables[appName] = tbl
	return tbl
end
