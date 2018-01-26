local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local CH = E:NewModule("Chat", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0");
local CC = E:GetModule("ClassCache");
local LSM = LibStub("LibSharedMedia-3.0");

--Cache global variables
--Lua functions
local _G = _G
local time, difftime = time, difftime
local pairs, unpack, select, tostring, next, tonumber, type, assert = pairs, unpack, select, tostring, next, tonumber, type, assert
local tinsert, tremove, tsort, twipe, tconcat = table.insert, table.remove, table.sort, table.wipe, table.concat
local strmatch = strmatch
local gsub, find, match, gmatch, format, split = string.gsub, string.find, string.match, string.gmatch, string.format, string.split
local strlower, strsub, strlen, strupper = strlower, strsub, strlen, strupper
--WoW API / Variables
local BetterDate = BetterDate
local ChatEdit_SetLastTellTarget = ChatEdit_SetLastTellTarget
local ChatFrameEditBox = ChatFrameEditBox
local ChatFrame_ConfigEventHandler = ChatFrame_ConfigEventHandler
local ChatFrame_SendTell = ChatFrame_SendTell
local ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler
local CreateFrame = CreateFrame
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FloatingChatFrame_OnEvent = FloatingChatFrame_OnEvent
local GetChannelName = GetChannelName
local GetDefaultLanguage = GetDefaultLanguage
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetMouseFocus = GetMouseFocus
local GetNumRaidMembers = GetNumRaidMembers
local GetTime = GetTime
local IsInInstance = IsInInstance
local IsMouseButtonDown = IsMouseButtonDown
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local ShowUIPanel, HideUIPanel = ShowUIPanel, HideUIPanel
local StaticPopup_Visible = StaticPopup_Visible
local ToggleFrame = ToggleFrame
local UnitName = UnitName
local hooksecurefunc = hooksecurefunc

local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

local GlobalStrings = {
	["AFK"] = CHAT_MSG_AFK,
	["CHAT_FILTERED"] = CHAT_FILTERED,
	["CHAT_IGNORED"] = CHAT_IGNORED,
	["CHAT_RESTRICTED"] = CHAT_RESTRICTED,
	["CHAT_TELL_ALERT_TIME"] = CHAT_TELL_ALERT_TIME,
	["DND"] = CHAT_MSG_DND,
	["CHAT_MSG_RAID_WARNING"] = CHAT_MSG_RAID_WARNING
}

local CreatedFrames = 0
local lines = {}
local msgList, msgCount, msgTime = {}, {}, {}
local chatFilters = {}

local PLAYER_REALM = gsub(E.myrealm,"[%s%-]","")
local PLAYER_NAME = E.myname.."-"..PLAYER_REALM

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS

local DEFAULT_STRINGS = {
	BATTLEGROUND = L["BG"],
	GUILD = L["G"],
	PARTY = L["P"],
	RAID = L["R"],
	OFFICER = L["O"],
	BATTLEGROUND_LEADER = L["BGL"],
	RAID_LEADER = L["RL"],
}

local hyperlinkTypes = {
	["item"] = true,
	["spell"] = true,
	["unit"] = true,
	["quest"] = true,
	["enchant"] = true,
	["instancelock"] = true,
	["talent"] = true,
}

CH.Keywords = {}

local numScrollMessages
local function ChatFrame_OnMouseScroll(frame, delta)
	numScrollMessages = CH.db.numScrollMessages or 3
	if CH.db.scrollDirection == "TOP" then
		if delta < 0 then
			if IsShiftKeyDown() then
				frame:ScrollToBottom()
			elseif IsAltKeyDown() then
				frame:ScrollDown()
			else
				for i = 1, numScrollMessages do
					frame:ScrollDown()
				end
			end
		elseif delta > 0 then
			if IsShiftKeyDown() then
				frame:ScrollToTop()
			elseif IsAltKeyDown() then
				frame:ScrollUp()
			else
				for i = 1, numScrollMessages do
					frame:ScrollUp()
				end
			end

			if CH.db.scrollDownInterval ~= 0 then
				if frame.ScrollTimer then
					CH:CancelTimer(frame.ScrollTimer, true)
				end

				frame.ScrollTimer = CH:ScheduleTimer("ScrollToBottom", CH.db.scrollDownInterval, frame)
			end
		end
	else
		if delta < 0 then
			if IsShiftKeyDown() then
				frame:ScrollToBottom()
			else
				for i = 1, numScrollMessages do
					frame:ScrollDown()
				end
			end
		elseif delta > 0 then
			if IsShiftKeyDown() then
				frame:ScrollToTop()
			else
				for i = 1, numScrollMessages do
					frame:ScrollUp()
				end
			end

			if CH.db.scrollDownInterval ~= 0 then
				if frame.ScrollTimer then
					CH:CancelTimer(frame.ScrollTimer, true)
				end

				-- frame.ScrollTimer = CH:ScheduleTimer("ScrollToBottom", CH.db.scrollDownInterval, frame)
			end
		end
	end
end

local function ChatFrame_AddMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		-- Only allow a filter to be added once
		for index, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				return
			end
		end
	else
		chatFilters[event] = {}
	end

	tinsert(chatFilters[event], filter)
end

local function ChatFrame_RemoveMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		for index, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				tremove(chatFilters[event], index)
			end
		end

		if getn(chatFilters[event]) == 0 then
			chatFilters[event] = nil
		end
	end
end

local function ChatFrame_GetMessageEventFilters(event)
	assert(event)

	return chatFilters[event]
end

function CH:GetGroupDistribution()
	local inInstance, kind = IsInInstance()
	if inInstance and kind == "pvp" then
		return "/bg "
	end
	if GetNumRaidMembers() > 0 then
		return "/ra "
	end
	if GetNumPartyMembers() > 0 then
		return "/p "
	end
	return "/s "
end

function CH:StyleChat(frame)
	local name = frame:GetName()
	E:FontTemplate(_G[name.."TabText"], LSM:Fetch("font", self.db.tabFont), self.db.tabFontSize, self.db.tabFontOutline)

	if frame.styled then return end

	frame:SetFrameLevel(4)

	local id = frame:GetID()

	local tab = _G[name.."Tab"]
	tab.isDocked = frame.isDocked

	for i = 1, getn(CHAT_FRAME_TEXTURES) do
		E:Kill(_G[name..CHAT_FRAME_TEXTURES[i]])
	end

	E:Kill(_G[name.."UpButton"])
	E:Kill(_G[name.."DownButton"])
	E:Kill(_G[name.."BottomButton"])
	E:Kill(_G[name.."TabDockRegion"])
	E:Kill(_G[name.."TabLeft"])
	E:Kill(_G[name.."TabMiddle"])
	E:Kill(_G[name.."TabRight"])
	_G[name.."Tab"]:GetHighlightTexture():SetTexture(nil)

	if frame.isDocked or frame:IsVisible() then
		tab:Show()
	end

	hooksecurefunc(tab, "SetAlpha", function(t, alpha)
		if alpha ~= 1 and (not t.isDocked or SELECTED_CHAT_FRAME:GetID() == t:GetID()) then
			UIFrameFadeRemoveFrame(t)
			t:SetAlpha(1)
		elseif alpha < 0.6 then
			UIFrameFadeRemoveFrame(t)
			t:SetAlpha(0.6)
		end
	end)

	tab.text = _G[name.."TabText"]
	tab.text:SetTextColor(unpack(E["media"].rgbvaluecolor))
	hooksecurefunc(tab.text, "SetTextColor", function(self, r, g, b)
		local rR, gG, bB = unpack(E["media"].rgbvaluecolor)
		if r ~= rR or g ~= gG or b ~= bB then
			self:SetTextColor(rR, gG, bB)
		end
	end)

	if id ~= 2 then
		tab.text:SetPoint("LEFT", _G[name.."TabLeft"], "RIGHT", 0, -4)
	end

	tab.flash = _G[name.."TabFlash"]
	tab.flash:ClearAllPoints()
	tab.flash:SetPoint("TOPLEFT", _G[name.."TabLeft"], "TOPLEFT", -3, id == 2 and -3 or -2)
	tab.flash:SetPoint("BOTTOMRIGHT", _G[name.."TabRight"], "BOTTOMRIGHT", 3, id == 2 and -7 or -6)

	--frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)

	--copy chat button
	frame.button = CreateFrame("Button", format("CopyChatButton%d", id), frame)
	frame.button:EnableMouse(true)
	frame.button:SetAlpha(0.35)
	frame.button:SetWidth(20)
	frame.button:SetHeight(22)
	frame.button:SetPoint("TOPRIGHT", 0, 0)
	frame.button:SetFrameLevel(frame:GetFrameLevel() + 5)

	frame.button.tex = frame.button:CreateTexture(nil, "OVERLAY")
	E:SetInside(frame.button.tex)
	frame.button.tex:SetTexture([[Interface\AddOns\ElvUI\media\textures\copy.tga]])

	frame.button:SetScript("OnMouseUp", function()
		if arg1 == "LeftButton" then
			CH:CopyChat(frame)
		elseif arg1 == "RightButton" and id ~= 2 then
			ToggleFrame(ChatMenu)
		end
	end)

	frame.button:SetScript("OnEnter", function() this:SetAlpha(1) end)
	frame.button:SetScript("OnLeave", function()
		if _G[this:GetParent():GetName().."TabText"]:IsShown() then
			this:SetAlpha(0.35)
		else
			this:SetAlpha(0)
		end
	end)

	CreatedFrames = id
	frame.styled = true
end

function CH:UpdateSettings()
	ChatFrameEditBox:SetAltArrowKeyMode(CH.db.useAltKey)
end

local function colorizeLine(text, r, g, b)
	local hexCode = E:RGBToHex(r, g, b)
	local hexReplacement = format("|r%s", hexCode)

	text = gsub(text, "|r", hexReplacement)
	text = format("%s%s|r", hexCode, text)

	return text
end

function CH:GetLines(...)
	local index = 1
	wipe(lines)
	for i = getn(arg), 1, -1 do
		local region = arg[i]
		if region:GetObjectType() == "FontString" then
			local line = tostring(region:GetText())
			local r, g, b = region:GetTextColor()

			line = colorizeLine(line, r, g, b)

			lines[index] = line
			index = index + 1
		end
	end
	return index - 1
end

function CH:CopyChat(frame)
	if not CopyChatFrame:IsShown() then
		local _, fontSize = GetChatWindowInfo(frame:GetID())
		if fontSize < 10 then fontSize = 12 end
		FCF_SetChatWindowFontSize(frame, 0.01)
		CopyChatFrame:Show()
		local lineCt = self:GetLines(frame:GetRegions())
		local text = tconcat(lines, " \n", 1, lineCt)
		FCF_SetChatWindowFontSize(frame, fontSize)
		CopyChatFrameEditBox:SetText(text)
	else
		CopyChatFrame:Hide()
	end
end

function CH:OnEnter()
	_G[this:GetName().."Text"]:Show()
end

function CH:OnLeave()
	_G[this:GetName().."Text"]:Hide()
end

function CH:SetupChatTabs(frame, hook)
	if hook and (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnEnter) then
		self:HookScript(frame, "OnEnter")
		self:HookScript(frame, "OnLeave")
	elseif not hook and self.hooks and self.hooks[frame] and self.hooks[frame].OnEnter then
		self:Unhook(frame, "OnEnter")
		self:Unhook(frame, "OnLeave")
	end

	if not hook then
		_G[frame:GetName().."Text"]:Show()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(0.35)
		end
	elseif GetMouseFocus() ~= frame then
		_G[frame:GetName().."Text"]:Hide()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(1)
		end
	end
end

function CH:UpdateAnchors()
	local frame = _G["ChatFrameEditBox"]
	if not E.db.datatexts.leftChatPanel and self.db.panelBackdrop == "HIDEBOTH" or self.db.panelBackdrop == "RIGHT" then
		frame:ClearAllPoints()
		if E.db.chat.editBoxPosition == "BELOW_CHAT" then
			frame:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT")
			frame:SetPoint("BOTTOMRIGHT", ChatFrame1, "BOTTOMRIGHT", 0, -LeftChatTab:GetHeight())
		else
			frame:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT")
			frame:SetPoint("TOPRIGHT", ChatFrame1, "TOPRIGHT", 0, LeftChatTab:GetHeight())
		end
	else
		if E.db.datatexts.leftChatPanel and E.db.chat.editBoxPosition == "BELOW_CHAT" then
			frame:SetAllPoints(LeftChatDataPanel)
		else
			frame:SetAllPoints(LeftChatTab)
		end
	end

	CH:PositionChat(true)
end

local function FindRightChatID()
	local rightChatID

	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G["ChatFrame"..i]
		local id = chat:GetID()

		if E:FramesOverlap(chat, RightChatPanel) and not E:FramesOverlap(chat, LeftChatPanel) then
			rightChatID = id
			break
		end
	end

	return rightChatID
end

function CH:UpdateChatTabs()
	local fadeUndockedTabs = E.db["chat"].fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db["chat"].fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local chat = _G[format("ChatFrame%d", i)]
		local tab = _G[format("ChatFrame%sTab", i)]
		local id = chat:GetID()
		local isDocked = chat.isDocked

		if chat:IsShown() and (id == self.RightChatWindowID) then
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end
end

function CH:PositionChat(override)
	if ((not override and self.initialMove) or (not override)) then return end
	if not RightChatPanel or not LeftChatPanel then return end
	RightChatPanel:SetWidth(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth)
	RightChatPanel:SetHeight(E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	LeftChatPanel:SetWidth(E.db.chat.panelWidth)
	LeftChatPanel:SetHeight(E.db.chat.panelHeight)

	self.RightChatWindowID = FindRightChatID()

	if not self.db.lockPositions or E.private.chat.enable ~= true then return end

	local chat, tab, id, isDocked
	local fadeUndockedTabs = E.db["chat"].fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db["chat"].fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local BASE_OFFSET = 57 + E.Spacing*3

		chat = _G[format("ChatFrame%d", i)]
		id = chat:GetID()
		tab = _G[format("ChatFrame%sTab", i)]
		isDocked = chat.isDocked
		tab.isDocked = chat.isDocked
		tab.owner = chat

		if chat:IsShown() and id == self.RightChatWindowID then
			chat:ClearAllPoints()

			if E.db.datatexts.rightChatPanel then
				chat:SetPoint("BOTTOMLEFT", RightChatDataPanel, "TOPLEFT", 1, 3)
			else
				BASE_OFFSET = BASE_OFFSET - 24
				chat:SetPoint("BOTTOMLEFT", RightChatDataPanel, "BOTTOMLEFT", 1, 1)
			end
			if id ~= 2 then
				chat:SetWidth((E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth) - 11)
				chat:SetHeight((E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight) - BASE_OFFSET)
			else
				chat:SetWidth(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET))
				chat:SetHeight(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET))
			end

			tab:SetParent(RightChatPanel)
			chat:SetParent(RightChatPanel)

			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			tab:SetParent(UIParent)
			chat:SetParent(UIParent)
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if id ~= 2 then
				chat:ClearAllPoints()
				if E.db.datatexts.leftChatPanel then
					chat:SetPoint("BOTTOMLEFT", LeftChatToggleButton, "TOPLEFT", 1, 3)
				else
					BASE_OFFSET = BASE_OFFSET - 24
					chat:SetPoint("BOTTOMLEFT", LeftChatToggleButton, "BOTTOMLEFT", 1, 1)
				end

				chat:SetWidth(E.db.chat.panelWidth - 11)
				chat:SetHeight((E.db.chat.panelHeight - BASE_OFFSET))
			end
			chat:SetParent(LeftChatPanel)
			if i > 2 then
				tab:SetParent(LeftChatPanel)
			else
				tab:SetParent(LeftChatPanel)
			end
			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end

			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end

	self.initialMove = true
end

local function UpdateChatTabColor(_, r, g, b)
	for i = 1, CreatedFrames do
		_G["ChatFrame"..i.."TabText"]:SetTextColor(r, g, b)
	end
end
E["valueColorUpdateFuncs"][UpdateChatTabColor] = true

function CH:ScrollToBottom(frame)
	frame:ScrollToBottom()

	self:CancelTimer(frame.ScrollTimer, true)
end

function CH:PrintURL(url)
	return "|cFFFFFFFF[|Hurl:"..url.."|h"..url.."|h]|r "
end

function CH.FindURL(msg, ...)
	if not msg then return end

	local event = select(11, unpack(arg))
	if event and event == "CHAT_MSG_WHISPER" and CH.db.whisperSound ~= "None" and not CH.SoundPlayed then
		PlaySoundFile(LSM:Fetch("sound", CH.db.whisperSound), "Master")
		CH.SoundPlayed = true
		-- CH.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
	end

	if not CH.db.url then
		msg = CH:CheckKeyword(msg)
		return false, msg, unpack(arg)
	end

	msg = gsub(gsub(msg, "(%S)(|c.-|H.-|h.-|h|r)", '%1 %2'), "(|c.-|H.-|h.-|h|r)(%S)", "%1 %2")
	-- http://example.com
	local newMsg, found = gsub(msg, "(%a+)://(%S+)%s?", CH:PrintURL("%1://%2"))
	if found > 0 then return false, CH:CheckKeyword(newMsg), unpack(arg) end
	-- www.example.com
	newMsg, found = gsub(msg, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", CH:PrintURL("www.%1.%2"))
	if found > 0 then return false, CH:CheckKeyword(newMsg), unpack(arg) end
	-- example@example.com
	newMsg, found = gsub(msg, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", CH:PrintURL("%1@%2%3%4"))
	if found > 0 then return false, CH:CheckKeyword(newMsg), unpack(arg) end
	-- IP address with port 1.1.1.1:1
	newMsg, found = gsub(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)(:%d+)%s?", CH:PrintURL("%1.%2.%3.%4%5"))
	if found > 0 then return false, CH:CheckKeyword(newMsg), unpack(arg) end
	-- IP address 1.1.1.1
	newMsg, found = gsub(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", CH:PrintURL("%1.%2.%3.%4"))
	if found > 0 then return false, CH:CheckKeyword(newMsg), unpack(arg) end

	msg = CH:CheckKeyword(msg)

	return false, msg, unpack(arg)
end

local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(data, ...)
	if strsub(data, 1, 3) == "url" then
		local currentLink = strsub(data, 5)
		if not ChatFrameEditBox:IsShown() then
			ChatFrameEditBox:Show()
			ChatEdit_UpdateHeader(ChatFrameEditBox)
		end
		ChatFrameEditBox:Insert(currentLink)
		ChatFrameEditBox:HighlightText()
	else
		SetHyperlink(self, data, unpack(arg))
	end
end

local function WIM_URLLink(link)
	if strsub(link, 1, 3) == "url" then
		local currentLink = strsub(link, 5)
		if not ChatFrameEditBox:IsShown() then
			ChatFrameEditBox:Show()
			ChatEdit_UpdateHeader(ChatFrameEditBox)
		end
		ChatFrameEditBox:Insert(currentLink)
		ChatFrameEditBox:HighlightText()
		return
	end
end

local hyperLinkEntered
function CH:OnHyperlinkEnter()
	local linkToken = match(arg1, "([^:]+)")
	if hyperlinkTypes[linkToken] then
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(arg1)
		hyperLinkEntered = this
		GameTooltip:Show()
	end
end

function CH:OnHyperlinkLeave()
	local linkToken = match(arg1, "([^:]+)")
	if hyperlinkTypes[linkToken] then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = nil
	end
end

function CH:OnMessageScrollChanged()
	if hyperLinkEntered == this then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = false
	end
end

function CH:EnableHyperlink()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnHyperlinkEnter) then
			self:HookScript(frame, "OnHyperlinkEnter")
			self:HookScript(frame, "OnHyperlinkLeave")
			self:HookScript(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableHyperlink()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if self.hooks and self.hooks[frame] and self.hooks[frame].OnHyperlinkEnter then
			self:Unhook(frame, "OnHyperlinkEnter")
			self:Unhook(frame, "OnHyperlinkLeave")
			self:Unhook(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableChatThrottle()
	twipe(msgList) twipe(msgCount) twipe(msgTime)
end

function CH.ShortChannel()
	return format("|Hchannel:%s|h[%s]|h", arg8, DEFAULT_STRINGS[strupper(arg8)] or gsub(arg8, "channel:", ""))
end

function CH:ConcatenateTimeStamp(msg)
	if CH.db.timeStampFormat and CH.db.timeStampFormat ~= "NONE" then
		local timeStamp = BetterDate(CH.db.timeStampFormat, CH.timeOverride or time())
		timeStamp = gsub(timeStamp, " ", "")
		timeStamp = gsub(timeStamp, "AM", " AM")
		timeStamp = gsub(timeStamp, "PM", " PM")
		if CH.db.useCustomTimeColor then
			local color = CH.db.customTimeColor
			local hexColor = E:RGBToHex(color.r, color.g, color.b)
			msg = format("%s[%s]|r %s", hexColor, timeStamp, msg)
		else
			msg = format("[%s] %s", timeStamp, msg)
		end
		CH.timeOverride = nil
	end

	return msg
end

function GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
	if not E.private.general.classCache then return arg2 end

	if arg2 and arg2 ~= "" then
		local name, realm = strsplit("-", arg2)
		local englishClass = CC:GetClassByName(name, realm)

		if englishClass then
			local classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[englishClass] or RAID_CLASS_COLORS[englishClass]
			if not classColorTable then
				return arg2
			end

			return format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255)..arg2.."\124r"
		end
	end

	return arg2
end

function CH:ChatFrame_MessageEventHandler(event, ...)
	if event == "UPDATE_CHAT_WINDOWS" then
		local name, fontSize, r, g, b, a, shown, locked = GetChatWindowInfo(self:GetID())
		if fontSize > 0 then
			local fontFile, unused, fontFlags = self:GetFont()
			self:SetFont(fontFile, fontSize, fontFlags)
		end
		if shown then
			self:Show()
		end
		-- Do more stuff!!!
		ChatFrame_RegisterForMessages(GetChatWindowMessages(self:GetID()))
		ChatFrame_RegisterForChannels(GetChatWindowChannels(self:GetID()))
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		self.defaultLanguage = GetDefaultLanguage()
		return
	end
	if event == "TIME_PLAYED_MSG" then
		ChatFrame_DisplayTimePlayed(arg1, arg2)
		return
	end
	if event == "PLAYER_LEVEL_UP" then
		-- Level up
		local info = ChatTypeInfo["SYSTEM"]

		local string = format(TEXT(LEVEL_UP), arg1)
		self:AddMessage(string, info.r, info.g, info.b, info.id)

		if arg3 > 0 then
			string = format(TEXT(LEVEL_UP_HEALTH_MANA), arg2, arg3)
		else
			string = format(TEXT(LEVEL_UP_HEALTH), arg2)
		end
		self:AddMessage(string, info.r, info.g, info.b, info.id)

		if arg4 > 0 then
			string = format(GetText("LEVEL_UP_CHAR_POINTS", nil, arg4), arg4)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end

		if arg5 > 0 then
			string = format(TEXT(LEVEL_UP_STAT), TEXT(SPELL_STAT0_NAME), arg5)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		if arg6 > 0 then
			string = format(TEXT(LEVEL_UP_STAT), TEXT(SPELL_STAT1_NAME), arg6)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		if arg7 > 0 then
			string = format(TEXT(LEVEL_UP_STAT), TEXT(SPELL_STAT2_NAME), arg7)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		if arg8 > 0 then
			string = format(TEXT(LEVEL_UP_STAT), TEXT(SPELL_STAT3_NAME), arg8)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		if arg9 > 0 then
			string = format(TEXT(LEVEL_UP_STAT), TEXT(SPELL_STAT4_NAME), arg9)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		return
	end
	if event == "CHARACTER_POINTS_CHANGED" then
		local info = ChatTypeInfo["SYSTEM"]
		if arg2 > 0 then
			local cp1, cp2 = UnitCharacterPoints("player")
			if cp2 then
				local string = format(GetText("LEVEL_UP_SKILL_POINTS", nil, cp2), cp2)
				self:AddMessage(string, info.r, info.g, info.b, info.id)
			end
		end
		return
	end
	if event == "GUILD_MOTD" then
		if arg1 and (strlen(arg1) > 0) then
			local info = ChatTypeInfo["GUILD"]
			local string = format(TEXT(GUILD_MOTD_TEMPLATE), arg1)
			self:AddMessage(string, info.r, info.g, info.b, info.id)
		end
		return
	end
	if event == "EXECUTE_CHAT_LINE" then
		self.editBox:SetText(arg1)
		ChatEdit_SendText(self.editBox)
		ChatEdit_OnEscapePressed(self.editBox)
		return
	end
	if event == "UPDATE_CHAT_COLOR" then
		local info = ChatTypeInfo[strupper(arg1)]
		if info then
			info.r = arg2
			info.g = arg3
			info.b = arg4
			self:UpdateColorByID(info.id, info.r, info.g, info.b)

			if strupper(arg1) == "WHISPER" then
				info = ChatTypeInfo["REPLY"]
				if info then
					info.r = arg2
					info.g = arg3
					info.b = arg4
					self:UpdateColorByID(info.id, info.r, info.g, info.b)
				end
			end
		end
		return
	end
	if strsub(event, 1, 8) == "CHAT_MSG" then
		local type = strsub(event, 10)
		local info = ChatTypeInfo[type]
		local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = unpack(arg)

		local filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10 = false
		if chatFilters[event] then
			for _, filterFunc in next, chatFilters[event] do
				filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10 = filterFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, event)
				arg1 = newarg1 or arg1
				if filter then
					return true
				elseif newarg1 and newarg2 then
					arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10
				end
			end
		end

		local coloredName = GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)

		local channelLength = arg4 and strlen(arg4)
		if (strsub(type, 1, 7) == "CHANNEL") and (type ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (type ~= "CHANNEL_NOTICE_USER")) then
			if arg1 == "WRONG_PASSWORD" then
				local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""]
				if staticPopup and staticPopup.data == arg9 then
					-- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
					return
				end
			end

			local found = 0
			for index, value in pairs(self.channelList) do
				if channelLength > strlen(value) then
					-- arg9 is the channel name without the number in front...
					if ((arg7 > 0) and (self.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) then
						found = 1
						info = ChatTypeInfo["CHANNEL"..arg8]
						if (type == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") then
							self.channelList[index] = nil
							self.zoneChannelList[index] = nil
						end
						break
					end
				end
			end
			if found == 0 or not info then
				return true
			end
		end

		if type == "SYSTEM" or type == "TEXT_EMOTE" or type == "SKILL" or type == "LOOT" or type == "MONEY" or
			type == "OPENING" or type == "TRADESKILLS" or type == "PET_INFO" then
			self:AddMessage(CH:ConcatenateTimeStamp(arg1), info.r, info.g, info.b, info.id)
		elseif strsub(type,1,7) == "COMBAT_" then
			self:AddMessage(CH:ConcatenateTimeStamp(arg1), info.r, info.g, info.b, info.id)
		elseif strsub(type,1,6) == "SPELL_" then
			self:AddMessage(CH:ConcatenateTimeStamp(arg1), info.r, info.g, info.b, info.id)
		elseif strsub(type,1,10) == "BG_SYSTEM_" then
			self:AddMessage(CH:ConcatenateTimeStamp(arg1), info.r, info.g, info.b, info.id)
		elseif type == "IGNORED" then
			self:AddMessage(format(CH:ConcatenateTimeStamp(GlobalStrings.CHAT_IGNORED), arg2), info.r, info.g, info.b, info.id)
		elseif type == "FILTERED" then
			self:AddMessage(format(CH:ConcatenateTimeStamp(GlobalStrings.CHAT_FILTERED), arg2), info.r, info.g, info.b, info.id)
		elseif type == "RESTRICTED" then
			self:AddMessage(CH:ConcatenateTimeStamp(GlobalStrings.CHAT_RESTRICTED), info.r, info.g, info.b, info.id)
		elseif type == "CHANNEL_LIST" then
			if channelLength > 0 then
				self:AddMessage(format(CH:ConcatenateTimeStamp(_G["CHAT_"..type.."_GET"]..arg1), arg4), info.r, info.g, info.b, info.id)
			else
				self:AddMessage(CH:ConcatenateTimeStamp(arg1), info.r, info.g, info.b, info.id)
			end
		elseif type == "CHANNEL_NOTICE_USER" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			globalstring = CH:ConcatenateTimeStamp(globalstring)

			if strlen(arg5) > 0 then
				-- TWO users in this notice (E.G. x kicked y)
				self:AddMessage(format(globalstring, arg4, arg2, arg5), info.r, info.g, info.b, info.id)
			else
				self:AddMessage(format(globalstring, arg4, arg2), info.r, info.g, info.b, info.id)
			end
		elseif type == "CHANNEL_NOTICE" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			if arg10 > 0 then
				arg4 = arg4.." "..arg10
			end
			self:AddMessage(format(CH:ConcatenateTimeStamp(globalstring), arg4), info.r, info.g, info.b, info.id)
		else
			local body
			local _, fontHeight = GetChatWindowInfo(self:GetID())

			if fontHeight == 0 then
				--fontHeight will be 0 if it's still at the default (14)
				fontHeight = 14
			end

			-- Add AFK/DND flags
			local pflag
			if arg6 ~= "" then
				if arg6 == "DND" or arg6 == "AFK" then
					pflag = (pflag or "").._G["CHAT_FLAG_"..arg6]
				else
					pflag = _G["CHAT_FLAG_"..arg6]
				end
			else
				if pflag == true then
					pflag = ""
				end
			end

			pflag = pflag or ""

			local showLink = 1
			if strsub(type, 1, 7) == "MONSTER" or strsub(type, 1, 9) == "RAID_BOSS" then
				showLink = nil
			else
				arg1 = gsub(arg1, "%%", "%%%%")
			end

			local showLink = 1
			if strsub(type, 1, 7) == "MONSTER" or type == "RAID_BOSS_EMOTE" then
				showLink = nil
			else
				arg1 = gsub(arg1, "%%", "%%%%")
			end

			if (strlen(arg3) > 0) and (arg3 ~= "Universal") and (arg3 ~= GetDefaultLanguage()) then
				local languageHeader = "["..arg3.."] "
				if showLink and (strlen(arg2) > 0) then
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag.."|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h")
				else
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag..arg2)
				end
			else
				if showLink and (strlen(arg2) > 0) and (type ~= "EMOTE") then
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h")
				elseif showLink and (strlen(arg2) > 0) and (type == "EMOTE") then
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2.."|h".."["..coloredName.."]".."|h")
				else
					arg1 = gsub(arg1, "%%s %%s", "%%s")
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag..arg2)

					-- Add raid boss emote message
					if type == "RAID_BOSS_EMOTE" then
						RaidBossEmoteFrame:AddMessage(body, info.r, info.g, info.b, 1.0)
						PlaySound("RaidBossEmoteWarning")
					end
				end
			end

			-- Add Channel
			arg4 = gsub(arg4, "%s%-%s.*", "")
			if channelLength > 0 then
				body = "|Hchannel:channel:"..arg8.."|h["..arg4.."]|h "..body
			end

			if CH.db.shortChannels then
				body = gsub(body, "|Hchannel:(.-)|h%[(.-)%]|h", CH.ShortChannel)
				body = gsub(body, "CHANNEL:", "")
				body = gsub(body, "^(.-|h) "..L["whispers"], "%1")
				body = gsub(body, "^(.-|h) "..L["says"], "%1")
				body = gsub(body, "^(.-|h) "..L["yells"], "%1")
				body = gsub(body, "<"..GlobalStrings.AFK..">", "[|cffFF0000"..L["AFK"].."|r] ")
				body = gsub(body, "<"..GlobalStrings.DND..">", "[|cffE7E716"..L["DND"].."|r] ")
				body = gsub(body, "^%["..GlobalStrings.CHAT_MSG_RAID_WARNING.."%]", "["..L["RW"].."]")
			end
			self:AddMessage(CH:ConcatenateTimeStamp(body), info.r, info.g, info.b, info.id)
		end

		if type == "WHISPER" then
			ChatEdit_SetLastTellTarget(self.editBox, arg2)
			if self.tellTimer and (GetTime() > self.tellTimer) then
				PlaySound("TellMessage")
			end
			self.tellTimer = GetTime() + GlobalStrings.CHAT_TELL_ALERT_TIME
			FCF_FlashTab()
		end

		return true
	end
end

function CH:ChatFrame_OnEvent(event, ...)
	if CH.ChatFrame_MessageEventHandler(self, event, unpack(arg)) then
		return
	end
end

function CH:FloatingChatFrame_OnEvent(self, event, ...)
	CH.ChatFrame_OnEvent(self, event, unpack(arg))
	FloatingChatFrame_OnEvent(self, event, 1)
end

local function OnTextChanged(self)
	local text = self:GetText()

		local MIN_REPEAT_CHARACTERS = E.db.chat.numAllowedCombatRepeat
		if strlen(text) > MIN_REPEAT_CHARACTERS then
		local repeatChar = true
		for i = 1, MIN_REPEAT_CHARACTERS, 1 do
			if strsub(text,(0-i), (0-i)) ~= strsub(text, (-1-i), (-1-i)) then
				repeatChar = false
				break
			end
		end
			if repeatChar then
				self:Hide()
				return
			end
		end

	if strlen(text) < 5 then
		if strsub(text, 1, 4) == "/tt " then
			local unitname, realm = UnitName("target")
			if unitname and realm then
				unitname = unitname .. "-" .. gsub(realm, " ", "")
			end
			ChatFrame_SendTell((unitname or L["Invalid Target"]), ChatFrame1)
		end

		if strsub(text, 1, 4) == "/gr " then
			self:SetText(CH:GetGroupDistribution() .. strsub(text, 5))
			ChatEdit_ParseText(self, 0)
		end
	end

	local new, found = gsub(text, "|Kf(%S+)|k(%S+)%s(%S+)|k", "%2 %3")
	if found > 0 then
		new = gsub(new, "|", "")
		self:SetText(new)
	end
end

function CH:SetupChat()
	if E.private.chat.enable ~= true then return end

	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		local id = frame:GetID()
		local _, fontSize = GetChatWindowInfo(id)
		self:StyleChat(frame)

		frame:SetFont(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)
		if self.db.fontOutline ~= "NONE" then
			frame:SetShadowColor(0, 0, 0, 0.2)
		else
			frame:SetShadowColor(0, 0, 0, 1)
		end
		frame:SetTimeVisible(100)
		frame:SetShadowOffset((E.mult or 1), -(E.mult or 1))
		frame:SetFading(self.db.fade)

		if not frame.scriptsSet then
			frame:SetScript("OnMouseWheel", function() ChatFrame_OnMouseScroll(this, arg1) end)
			frame:EnableMouseWheel(true)

			if id ~= 2 then
				frame:SetScript("OnEvent", function() CH:FloatingChatFrame_OnEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) end)
			end
			frame.scriptsSet = true
		end
	end

	local editbox = _G["ChatFrameEditBox"]
	if not editbox.isSkinned then
		local a, b, c = select(6, editbox:GetRegions()) E:Kill(a) E:Kill(b) E:Kill(c)
		E:SetTemplate(editbox, "Default", true)
		editbox:SetAltArrowKeyMode(CH.db.useAltKey)
		editbox:SetAllPoints(LeftChatDataPanel)
		self:SecureHook(editbox, "AddHistoryLine", "ChatEdit_AddHistory")
		HookScript(editbox, "OnTextChanged", function() OnTextChanged(this) end)

		editbox.historyLines = ElvCharacterDB.ChatEditHistory
		editbox.historyIndex = 0
		editbox:Hide()

		HookScript(editbox, "OnEditFocusGained", function() this:Show() if not LeftChatPanel:IsShown() then LeftChatPanel.editboxforced = true LeftChatToggleButton:GetScript("OnEnter")(LeftChatToggleButton) end end)
		HookScript(editbox, "OnEditFocusLost", function() if LeftChatPanel.editboxforced then LeftChatPanel.editboxforced = nil if LeftChatPanel:IsShown() then LeftChatToggleButton:GetScript("OnLeave")(LeftChatToggleButton) end end this.historyIndex = 0 this:Hide() end)

		for _, text in pairs(ElvCharacterDB.ChatEditHistory) do
			editbox:AddHistoryLine(text)
		end
		editbox.isSkinned = true
	end

	if self.db.hyperlinkHover then
		self:EnableHyperlink()
	end

	DEFAULT_CHAT_FRAME:SetParent(LeftChatPanel)
	self:ScheduleRepeatingTimer("PositionChat", 1)
	-- self:PositionChat(true)
end

local function PrepareMessage(author, message)
	if not author then return message end
	return format("%s%s", strupper(author), message)
end

function CH:ChatThrottleHandler(_, ...)
	local arg1, arg2 = unpack(arg)

	if arg2 and arg2 ~= "" then
		local message = PrepareMessage(arg2, arg1)
		if msgList[message] == nil then
			msgList[message] = true
			msgCount[message] = 1
			msgTime[message] = time()
		else
			msgCount[message] = msgCount[message] + 1
		end
	end
end

function CH.CHAT_MSG_CHANNEL(message, author, ...)
	if not (message and author) then return end

	local blockFlag = false
	local msg = PrepareMessage(author, message)

	if msg == nil then return CH.FindURL(message, author, unpack(arg)) end

	-- ignore player messages
	if author and author == UnitName("player") then return CH.FindURL(message, author, unpack(arg)) end
	if msgList[msg] and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(message, author, unpack(arg))
	end
end

function CH.CHAT_MSG_YELL(message, author, ...)
	if not (message and author) then return end

	local blockFlag = false
	local msg = PrepareMessage(author, message)

	if msg == nil then return CH.FindURL(message, author, unpack(arg)) end

	-- ignore player messages
	if author and author == UnitName("player") then return CH.FindURL(message, author, unpack(arg)) end
	if msgList[msg] and msgCount[msg] > 1 and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(message, author, unpack(arg))
	end
end

function CH.CHAT_MSG_SAY(message, author, ...)
	if not (message and author) then return end

	return CH.FindURL(message, author, unpack(arg))
end

function CH:ThrottleSound()
	self.SoundPlayed = nil
end

local protectLinks = {}
function CH:CheckKeyword(message)
	for itemLink in gmatch(message, "|%x+|Hitem:.-|h.-|h|r") do
		protectLinks[itemLink] = gsub(itemLink, "%s","|s")
		for keyword, _ in pairs(CH.Keywords) do
			if itemLink == keyword then
				if self.db.keywordSound ~= "None" and not self.SoundPlayed then
					PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
					self.SoundPlayed = true
					-- self.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
				end
			end
		end
	end

	for itemLink, tempLink in pairs(protectLinks) do
		message = gsub(message, gsub(itemLink, "([%(%)%.%%%+%-%*%?%[%^%$])","%%%1"), tempLink)
	end

	local classColorTable, tempWord, rebuiltString, lowerCaseWord, wordMatch, classMatch
	local isFirstWord = true
	for word in gmatch(message, "%s-[^%s]+%s*") do
		tempWord = gsub(word, "[%s%p]", "")
		lowerCaseWord = strlower(tempWord)
		for keyword, _ in pairs(CH.Keywords) do
			if lowerCaseWord == strlower(keyword) then
				word = gsub(word, tempWord, format("%s%s|r", E.media.hexvaluecolor, tempWord))
				if self.db.keywordSound ~= "None" and not self.SoundPlayed then
					PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
					self.SoundPlayed = true
					-- self.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
				end
			end
		end

		if self.db.classColorMentionsChat and E.private.general.classCache then
			tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$","%1%2")

			classMatch = CC:GetCacheTable()[E.myrealm][tempWord]
			wordMatch = classMatch and lowerCaseWord

			if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
				classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classMatch] or RAID_CLASS_COLORS[classMatch]
				word = gsub(word, gsub(tempWord, "%-","%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
			end
		end

		if isFirstWord then
			rebuiltString = word
			isFirstWord = false
		else
			rebuiltString = format("%s%s", rebuiltString, word)
		end
	end

	for itemLink, tempLink in pairs(protectLinks) do
		rebuiltString = gsub(rebuiltString, gsub(tempLink, "([%(%)%.%%%+%-%*%?%[%^%$])","%%%1"), itemLink)
		protectLinks[itemLink] = nil
	end

	return rebuiltString
end

function CH:AddLines(lines, ...)
	for i = getn(arg), 1, -1 do
		local x = select(i, unpack(arg))
		if	x:GetObjectType() == "FontString" and not x:GetName() then
			tinsert(lines, x:GetText())
		end
	end
end

function CH:ChatEdit_UpdateHeader()
	local type = this.chatType
	if type == "CHANNEL" then
		local id = GetChannelName(this.channelTarget)
		if id == 0 then
			this:SetBackdropBorderColor(unpack(E.media.bordercolor))
		else
			this:SetBackdropBorderColor(ChatTypeInfo[type..id].r, ChatTypeInfo[type..id].g, ChatTypeInfo[type..id].b)
		end
	elseif type then
		this:SetBackdropBorderColor(ChatTypeInfo[type].r, ChatTypeInfo[type].g, ChatTypeInfo[type].b)
	end
end

function CH:ChatEdit_OnEnterPressed()
	local type = this.chatType
	if ChatTypeInfo[type].sticky == 1 then
		if not self.db.sticky then type = "SAY" end
		this.chatType = type
	end
end

function CH:SetItemRef(link, text, button)
	if strsub(link, 1, 7) == "channel" then
		if IsModifiedClick("CHATLINK") then
			ToggleFriendsFrame(4)
		elseif button == "LeftButton" then
			local chanLink = sub(link, 9)
			local chatType, chatTarget = strsplit(":", chanLink)

			if strupper(chatType) == "CHANNEL" then
				if GetChannelName(tonumber(chatTarget)) ~= 0 then
					ChatFrame_OpenChat("/"..chatTarget, this)
				end
			else
				ChatFrame_OpenChat("/"..chatType, this)
			end
--[[	-- TODO
		elseif button == "RightButton" then
			local chanLink = sub(link, 9)
			local chatType, chatTarget = strsplit(":", chanLink)

			if not strupper(chatType) == "CHANNEL" and GetChannelName(tonumber(chatTarget)) == 0 then
				ChatChannelDropDown_Show(this, strupper(chatType), chatTarget, Chat_GetColoredChatName(strupper(chatType), chatTarget))
			end
]]
		end

		return
	end

	return self.hooks.SetItemRef(link, text, button)
end

function CH:SetChatFont(chatFrame, fontSize)
	if not chatFrame then
		chatFrame = FCF_GetCurrentChatFrame()
	end
	if not fontSize then
		fontSize = this.value
	end
	chatFrame:SetFont(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)

	if self.db.fontOutline ~= "NONE" then
		chatFrame:SetShadowColor(0, 0, 0, 0.2)
	else
		chatFrame:SetShadowColor(0, 0, 0, 1)
	end
	chatFrame:SetShadowOffset((E.mult or 1), -(E.mult or 1))
end

function CH:ChatEdit_AddHistory(_, line)
	if find(line, "/rl") then return end

	if strlen(line) > 0 then
		for _, text in pairs(ElvCharacterDB.ChatEditHistory) do
			if text == line then
				return
			end
		end

		tinsert(ElvCharacterDB.ChatEditHistory, getn(ElvCharacterDB.ChatEditHistory) + 1, line)
		if getn(ElvCharacterDB.ChatEditHistory) > 20 then
			tremove(ElvCharacterDB.ChatEditHistory, 1)
		end
	end
end

function CH:UpdateChatKeywords()
	twipe(CH.Keywords)
	local keywords = self.db.keywords
	keywords = gsub(keywords,",%s",",")

	for i = 1, getn({split(",", keywords)}) do
		local stringValue = select(i, split(",", keywords))
		if stringValue ~= "" then
			CH.Keywords[stringValue] = true
		end
	end
end

function CH:UpdateFading()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if frame then
			frame:SetFading(self.db.fade)
		end
	end
end

function CH:DisplayChatHistory()
	local data, chat, d = ElvCharacterDB.ChatHistoryLog
	if not (data and next(data)) then return end

	CH.SoundPlayed = true
	for i = 1, NUM_CHAT_WINDOWS do
		chat = _G["ChatFrame"..i]
		for i = 1, getn(data) do
			d = data[i]
			if type(d) == "table" then
				CH.timeOverride = d[51]
				for _, messageType in pairs(chat.messageTypeList) do
					if gsub(strsub(d[50],10),"_INFORM","") == messageType then
						CH.ChatFrame_MessageEventHandler(chat,d[50],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11])
					end
				end
			end
		end
	end
	CH.SoundPlayed = nil
end

tremove(ChatTypeGroup["GUILD"], 2)
function CH:DelayGuildMOTD()
	local delay, delayFrame, chat = 0, CreateFrame("Frame")
	tinsert(ChatTypeGroup["GUILD"], 2, "GUILD_MOTD")
	delayFrame:SetScript("OnUpdate", function()
		delay = delay + arg1
		if delay < 7 then return end
		local msg = GetGuildRosterMOTD()
		for i = 1, NUM_CHAT_WINDOWS do
			chat = _G["ChatFrame"..i]
			if i == 1 then -- TEMPORARY UNTIL FURTHER FIX
			--if chat and chat:IsEventRegistered("CHAT_MSG_GUILD") then
				if msg and strlen(msg) > 0 then
					local info = ChatTypeInfo["GUILD"]
					local string = format(GUILD_MOTD_TEMPLATE, msg)
					chat:AddMessage(string, info.r, info.g, info.b, info.id)
				end
				chat:RegisterEvent("GUILD_MOTD")
			--end
			end
		end
		this:SetScript("OnUpdate", nil)
	end)
end

function CH:SaveChatHistory(event, ...)
	if not self.db.chatHistory then return end
	local data = ElvCharacterDB.ChatHistoryLog

	if self.db.throttleInterval ~= 0 and (event == "CHAT_MESSAGE_SAY" or event == "CHAT_MESSAGE_YELL" or event == "CHAT_MSG_CHANNEL") then
		self:ChatThrottleHandler(event, unpack(arg))

		local message, author = unpack(arg)
		local msg = PrepareMessage(author, message)
		if author and author ~= PLAYER_NAME and msgList[msg] then
			if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
				return
			end
		end
	end

	local temp = {}
	for i = 1, getn(arg) do
		temp[i] = select(i, unpack(arg)) or false
	end

	if getn(temp) > 0 then
		temp[50] = event
		temp[51] = time()

		tinsert(data, temp)
		while getn(data) >= 128 do
			tremove(data, 1)
		end
	end
	temp = nil -- Destory!
end

function CH:ChatFrame_AddMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		-- Only allow a filter to be added once
		for _, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				return
			end
		end
	else
		chatFilters[event] = {}
	end

	tinsert(chatFilters[event], filter)
end

function CH:ChatFrame_RemoveMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		for index, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				tremove(chatFilters[event], index)
			end
		end

		if getn(chatFilters[event]) == 0 then
			chatFilters[event] = nil
		end
	end
end

function CH:FCF_SetWindowAlpha(frame, alpha)
	frame.oldAlpha = alpha or 1
end

local FindURL_Events = {
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_AFK",
	"CHAT_MSG_DND",
}


function CH:Initialize()
	if ElvCharacterDB.ChatHistory then
  		ElvCharacterDB.ChatHistory = nil --Depreciated
  	end
	if ElvCharacterDB.ChatLog then
		ElvCharacterDB.ChatLog = nil --Depreciated
	end

	self.db = E.db.chat

	self:DelayGuildMOTD() --Keep this before `is Chat Enabled` check
	if E.private.chat.enable ~= true then return end

	if not ElvCharacterDB.ChatEditHistory then
		ElvCharacterDB.ChatEditHistory = {}
	end

	if not ElvCharacterDB.ChatHistoryLog or not self.db.chatHistory then
		ElvCharacterDB.ChatHistoryLog = {}
	end

	self:UpdateChatKeywords()

	self:UpdateFading()
	E.Chat = self
	self:SecureHook("ChatEdit_UpdateHeader")
	self:SecureHook("ChatEdit_OnEnterPressed")
	self:RawHook("SetItemRef", true)

	E:Kill(ChatFrameMenuButton)

	if WIM then
		WIM.RegisterWidgetTrigger("chat_display", "whisper,chat,w2w,demo", "OnHyperlinkClick", function(self) CH.clickedframe = self end)
		WIM.RegisterItemRefHandler("url", WIM_URLLink)
	end

	self:SecureHook("FCF_SetChatWindowFontSize", "SetChatFont")
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "SetupChat")
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "SetupChat")

	self:SetupChat()
	self:UpdateAnchors()
	if not E.db.chat.lockPositions then
		CH:UpdateChatTabs() --It was not done in PositionChat, so do it now
	end

	--First get all pre-existing filters and copy them to our version of chatFilters using ChatFrame_GetMessageEventFilters
	for name, _ in pairs(ChatTypeGroup) do
		for i = 1, getn(ChatTypeGroup[name]) do
			local filterFuncTable = ChatFrame_GetMessageEventFilters(ChatTypeGroup[name][i])
			if filterFuncTable then
				chatFilters[ChatTypeGroup[name][i]] = {}

				for j = 1, getn(filterFuncTable) do
					local filterFunc = filterFuncTable[j]
					tinsert(chatFilters[ChatTypeGroup[name][i]], filterFunc)
				end
			end
		end
	end

	--CHAT_MSG_CHANNEL isn't located inside ChatTypeGroup
	local filterFuncTable = ChatFrame_GetMessageEventFilters("CHAT_MSG_CHANNEL")
	if filterFuncTable then
		chatFilters["CHAT_MSG_CHANNEL"] = {}

		for j = 1, getn(filterFuncTable) do
			local filterFunc = filterFuncTable[j]
			tinsert(chatFilters["CHAT_MSG_CHANNEL"], filterFunc)
		end
	end

	--Now hook onto Blizzards functions for other addons
	hooksecurefunc(self, "ChatFrame_AddMessageEventFilter", ChatFrame_AddMessageEventFilter)
	hooksecurefunc(self, "ChatFrame_RemoveMessageEventFilter", ChatFrame_RemoveMessageEventFilter)

	self:SecureHook("FCF_SetWindowAlpha")

	ChatTypeInfo["SAY"].sticky = 1
	ChatTypeInfo["EMOTE"].sticky = 1
	ChatTypeInfo["YELL"].sticky = 1
	ChatTypeInfo["WHISPER"].sticky = 1
	ChatTypeInfo["PARTY"].sticky = 1
	ChatTypeInfo["RAID"].sticky = 1
	ChatTypeInfo["RAID_WARNING"].sticky = 1
	ChatTypeInfo["BATTLEGROUND"].sticky = 1
	ChatTypeInfo["GUILD"].sticky = 1
	ChatTypeInfo["OFFICER"].sticky = 1
	ChatTypeInfo["CHANNEL"].sticky = 1

	if self.db.chatHistory then
		self:DisplayChatHistory()
	end

	for _, event in pairs(FindURL_Events) do
		ChatFrame_AddMessageEventFilter(event, CH[event] or CH.FindURL)
		local nType = strsub(event, 10)
		if nType ~= "AFK" and nType ~= "DND" then
			self:RegisterEvent(event, "SaveChatHistory")
		end
	end

	local S = E:GetModule("Skins")

	local frame = CreateFrame("Frame", "CopyChatFrame", E.UIParent)
	tinsert(UISpecialFrames, "CopyChatFrame")
	E:SetTemplate(frame, "Transparent")
	frame:SetWidth(700)
	frame:SetHeight(200)
	frame:SetPoint("BOTTOM", E.UIParent, "BOTTOM", 0, 3)
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetResizable(true)
	frame:SetMinResize(350, 100)
	frame:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" and not this.isMoving then
			this:StartMoving()
			this.isMoving = true
		elseif arg1 == "RightButton" and not this.isSizing then
			this:StartSizing()
			this.isSizing = true
		end
	end)
	frame:SetScript("OnMouseUp", function()
		if arg1 == "LeftButton" and this.isMoving then
			this:StopMovingOrSizing()
			this.isMoving = false
		elseif arg1 == "RightButton" and this.isSizing then
			this:StopMovingOrSizing()
			this.isSizing = false
		end
	end)
	frame:SetScript("OnHide", function()
		if this.isMoving or this.isSizing then
			this:StopMovingOrSizing()
			this.isMoving = false
			this.isSizing = false
		end
	end)
	frame:SetFrameStrata("DIALOG")

	local scrollArea = CreateFrame("ScrollFrame", "CopyChatScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
	scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
	S:HandleScrollBar(CopyChatScrollFrameScrollBar)
	scrollArea:SetScript("OnSizeChanged", function()
		CopyChatFrameEditBox:SetWidth(this:GetWidth())
		CopyChatFrameEditBox:SetHeight(this:GetHeight())
	end)
	HookScript(scrollArea, "OnVerticalScroll", function()
		CopyChatFrameEditBox:SetHitRectInsets(0, 0, arg1, (CopyChatFrameEditBox:GetHeight() - arg1 - this:GetHeight()))
	end)

	local editBox = CreateFrame("EditBox", "CopyChatFrameEditBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(GameFontNormal)
	editBox:SetWidth(scrollArea:GetWidth())
	editBox:SetHeight(200)
	editBox:SetScript("OnEscapePressed", function() CopyChatFrame:Hide() end)
	scrollArea:SetScrollChild(editBox)
	CopyChatFrameEditBox:SetScript("OnTextChanged", function()
		local scrollBar = CopyChatScrollFrameScrollBar
		local _, max = scrollBar:GetMinMaxValues()
		for i = 1, max do
			scrollBar:SetValue(scrollBar:GetValue() + (scrollBar:GetHeight() / 2))
		end
	end)

	local close = CreateFrame("Button", "CopyChatFrameCloseButton", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:EnableMouse(true)
	S:HandleCloseButton(close)
end

local function InitializeCallback()
	CH:Initialize()
end

E:RegisterModule(CH:GetName(), InitializeCallback)