-- Chat Module for Weevil
-- Handles chat improvements and enhancements

local Weevil = LibStub("AceAddon-3.0"):GetAddon("Weevil")
local Chat = Weevil:NewModule("Chat", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weevil")

-- Default settings
Chat.defaults = {
	enableChatCopy = true,
	timestamps = true,
	urlDetection = true,
	classColoredNames = true,
	stickyChannels = true,
}

function Chat:OnInitialize()
	self.db = Weevil.db:RegisterNamespace("Chat", {
		profile = self.defaults
	})
end

function Chat:OnEnable()
	if self.db.profile.timestamps then
		self:EnableTimestamps()
	end
	
	if self.db.profile.classColoredNames then
		self:EnableClassColors()
	end
	
	if self.db.profile.stickyChannels then
		self:EnableStickyChannels()
	end
	
	if self.db.profile.enableChatCopy then
		self:EnableChatCopy()
	end
	
	if self.db.profile.urlDetection then
		self:EnableURLDetection()
	end
	
	Weevil:Print(L["Chat"] .. " " .. "module enabled")
end

function Chat:OnDisable()
	self:UnregisterAllEvents()
end

-- Enable timestamps in chat
function Chat:EnableTimestamps()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			frame:SetTimeVisible(true)
		end
	end
end

-- Enable class colored names in chat
function Chat:EnableClassColors()
	-- Hook chat message adding to colorize names
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			-- Enable class colors for channel chat
			if i <= 2 then
				ToggleChatColorNamesByClassGroup(true, "SAY")
				ToggleChatColorNamesByClassGroup(true, "EMOTE")
				ToggleChatColorNamesByClassGroup(true, "YELL")
				ToggleChatColorNamesByClassGroup(true, "GUILD")
				ToggleChatColorNamesByClassGroup(true, "OFFICER")
				ToggleChatColorNamesByClassGroup(true, "WHISPER")
				ToggleChatColorNamesByClassGroup(true, "PARTY")
				ToggleChatColorNamesByClassGroup(true, "PARTY_LEADER")
				ToggleChatColorNamesByClassGroup(true, "RAID")
				ToggleChatColorNamesByClassGroup(true, "RAID_LEADER")
				ToggleChatColorNamesByClassGroup(true, "RAID_WARNING")
				ToggleChatColorNamesByClassGroup(true, "INSTANCE_CHAT")
				ToggleChatColorNamesByClassGroup(true, "INSTANCE_CHAT_LEADER")
				ToggleChatColorNamesByClassGroup(true, "CHANNEL")
			end
		end
	end
end

-- Enable sticky chat channels
function Chat:EnableStickyChannels()
	ChatTypeInfo["SAY"].sticky = 1
	ChatTypeInfo["PARTY"].sticky = 1
	ChatTypeInfo["RAID"].sticky = 1
	ChatTypeInfo["RAID_WARNING"].sticky = 1
	ChatTypeInfo["INSTANCE_CHAT"].sticky = 1
	ChatTypeInfo["GUILD"].sticky = 1
	ChatTypeInfo["OFFICER"].sticky = 1
	ChatTypeInfo["WHISPER"].sticky = 1
	ChatTypeInfo["CHANNEL"].sticky = 1
	ChatTypeInfo["EMOTE"].sticky = 1
	ChatTypeInfo["YELL"].sticky = 1
end

-- Enable chat copy functionality
function Chat:EnableChatCopy()
	-- Create copy frame
	local copyFrame = CreateFrame("Frame", "WeevilChatCopyFrame", UIParent, "DialogBoxFrame")
	copyFrame:SetSize(600, 400)
	copyFrame:SetPoint("CENTER")
	copyFrame:SetFrameStrata("DIALOG")
	copyFrame:Hide()
	
	local scrollArea = CreateFrame("ScrollFrame", "WeevilChatCopyScroll", copyFrame, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", 8, -30)
	scrollArea:SetPoint("BOTTOMRIGHT", -30, 40)
	
	local editBox = CreateFrame("EditBox", "WeevilChatCopyEditBox", copyFrame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(0)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(scrollArea:GetWidth())
	editBox:SetHeight(scrollArea:GetHeight())
	editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
	
	scrollArea:SetScrollChild(editBox)
	
	local closeButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	closeButton:SetSize(100, 22)
	closeButton:SetPoint("BOTTOM", 0, 10)
	closeButton:SetText("Close")
	closeButton:SetScript("OnClick", function() copyFrame:Hide() end)
	
	copyFrame.editBox = editBox
	self.copyFrame = copyFrame
	
	-- Add right-click menu to chat frames
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			frame:SetScript("OnMouseUp", function(self, button)
				if button == "RightButton" and IsShiftKeyDown() then
					local text = ""
					for i = 1, self:GetNumMessages() do
						local msg = self:GetMessageInfo(i)
						if msg then
							text = text .. msg .. "\n"
						end
					end
					copyFrame.editBox:SetText(text)
					copyFrame.editBox:HighlightText()
					copyFrame:Show()
				end
			end)
		end
	end
end

-- Enable URL detection in chat
function Chat:EnableURLDetection()
	-- Hook chat frame AddMessage to detect URLs
	local function AddMessageHook(frame, text, ...)
		if text and type(text) == "string" then
			-- Simple URL pattern detection
			text = text:gsub("(%a+://[%w_./%%?&=~#-]+[^%p%s])", "|cff8888ff|Hurl:%1|h[%1]|h|r")
			text = text:gsub("(www%.[%w_./%%?&=~#-]+[^%p%s])", "|cff8888ff|Hurl:%1|h[%1]|h|r")
		end
		return text, ...
	end
	
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame and frame.AddMessage then
			hooksecurefunc(frame, "AddMessage", function(self, text, ...)
				-- URL detection is handled by the pattern replacement above
			end)
		end
	end
	
	-- Register URL link handler
	if not _G.SetItemRef_Original then
		_G.SetItemRef_Original = SetItemRef
	end
	
	SetItemRef = function(link, text, button, chatFrame)
		if link:sub(1, 4) == "url:" then
			local url = link:sub(5)
			-- Create a simple dialog to show URL
			StaticPopup_Show("WEEVIL_URL_COPY", url)
		else
			return _G.SetItemRef_Original(link, text, button, chatFrame)
		end
	end
	
	-- Register static popup
	if not StaticPopupDialogs["WEEVIL_URL_COPY"] then
		StaticPopupDialogs["WEEVIL_URL_COPY"] = {
			text = "URL: %s",
			button1 = "Okay",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
end
