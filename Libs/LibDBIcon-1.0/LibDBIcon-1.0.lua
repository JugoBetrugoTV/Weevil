--[[
LibDBIcon-1.0 by Funkydude
Allows addons to register to recieve a lightweight minimap icon as an alternative to more heavy LDB displays.
]]

local DBICON_MAJOR, DBICON_MINOR = "LibDBIcon-1.0", 45
local LibDBIcon = LibStub:NewLibrary(DBICON_MAJOR, DBICON_MINOR)

if not LibDBIcon then return end

local LibDataBroker = LibStub("LibDataBroker-1.1", true)

LibDBIcon.objects = LibDBIcon.objects or {}
LibDBIcon.callbacks = LibDBIcon.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(LibDBIcon)
local callbacks = LibDBIcon.callbacks

function LibDBIcon:Register(name, dataObject, db)
	if not LibDataBroker then return end
	if self.objects[name] then return end
	
	if not db or not db.hide then
		-- Create minimap button
		local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
		button:SetFrameStrata("MEDIUM")
		button:SetSize(31, 31)
		button:SetFrameLevel(8)
		button:RegisterForClicks("anyUp")
		button:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
		
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT")
		
		local icon = button:CreateTexture(nil, "BACKGROUND")
		icon:SetSize(20, 20)
		icon:SetTexture(dataObject.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
		icon:SetPoint("CENTER", 0, 1)
		button.icon = icon
		
		button:SetScript("OnClick", function(self, btn)
			if dataObject.OnClick then
				dataObject.OnClick(self, btn)
			end
		end)
		
		button:SetScript("OnEnter", function(self)
			if dataObject.OnTooltipShow then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				dataObject.OnTooltipShow(GameTooltip)
				GameTooltip:Show()
			elseif dataObject.OnEnter then
				dataObject.OnEnter(self)
			end
		end)
		
		button:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
			if dataObject.OnLeave then
				dataObject.OnLeave(self)
			end
		end)
		
		-- Position button
		local angle = db and db.minimapPos or 225
		local x = 80 * cos(angle)
		local y = 80 * sin(angle)
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
		
		self.objects[name] = button
		button:Show()
	end
	
	callbacks:Fire("LibDBIcon_IconCreated", name, self.objects[name])
end

function LibDBIcon:Hide(name)
	if not self.objects[name] then return end
	self.objects[name]:Hide()
end

function LibDBIcon:Show(name)
	if not self.objects[name] then return end
	self.objects[name]:Show()
end

function LibDBIcon:GetMinimapButton(name)
	return self.objects[name]
end

function LibDBIcon:IsRegistered(name)
	return self.objects[name] and true or false
end

function LibDBIcon:Refresh(name, db)
	if not self.objects[name] then return end
	
	if db and db.hide then
		self.objects[name]:Hide()
	else
		local angle = db and db.minimapPos or 225
		local x = 80 * cos(angle)
		local y = 80 * sin(angle)
		self.objects[name]:SetPoint("CENTER", Minimap, "CENTER", x, y)
		self.objects[name]:Show()
	end
end
