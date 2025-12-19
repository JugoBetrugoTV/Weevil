--[[
LibQTip-1.0 by Torhal, Ackis, Kaelten, Tekkub
Provides multi-column tooltips.
]]

local QTIP_MAJOR, QTIP_MINOR = "LibQTip-1.0", 90
local LibQTip = LibStub:NewLibrary(QTIP_MAJOR, QTIP_MINOR)

if not LibQTip then return end

LibQTip.tooltips = LibQTip.tooltips or {}

local function releaseTooltip(tooltip)
	tooltip:Hide()
	tooltip:ClearAllPoints()
	tooltip:SetParent(UIParent)
end

function LibQTip:Acquire(key, colCount, ...)
	if self.tooltips[key] then
		releaseTooltip(self.tooltips[key])
	end
	
	local tooltip = CreateFrame("GameTooltip", "LibQTip-1.0Tooltip" .. key, UIParent, "GameTooltipTemplate")
	tooltip:SetFrameStrata("TOOLTIP")
	tooltip.key = key
	
	self.tooltips[key] = tooltip
	
	return tooltip
end

function LibQTip:Release(tooltip)
	if type(tooltip) == "string" then
		tooltip = self.tooltips[tooltip]
	end
	
	if tooltip then
		releaseTooltip(tooltip)
		if tooltip.key then
			self.tooltips[tooltip.key] = nil
		end
	end
end

function LibQTip:IsAcquired(key)
	return self.tooltips[key] and true or false
end
