local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local pairs = pairs
local tinsert, sort, wipe, next = table.insert, table.sort, wipe, next
local format, find, join, gsub = string.format, string.find, string.join, string.gsub
--WoW API / Variables
local SendChatMessage = SendChatMessage
local InviteByName = InviteByName
local SetItemRef = SetItemRef
local GetFriendInfo = GetFriendInfo
local GetNumFriends = GetNumFriends
local GetQuestDifficultyColor = GetQuestDifficultyColor
local ToggleFriendsFrame = ToggleFriendsFrame

local CHAT_MSG_AFK = CHAT_MSG_AFK
local CHAT_MSG_DND = CHAT_MSG_DND
local FRIENDS = FRIENDS
local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

local L_EasyMenu = L_EasyMenu

local function GetNumberFriends()
	local numFriends = GetNumFriends()
	local onlineFriends = 0
	local _, online

	for i = 1, numFriends do
		_, _, _, _, online = GetFriendInfo(i)

		if online then
			onlineFriends = onlineFriends + 1
		end
	end

	return numFriends, onlineFriends
end

local menuFrame = CreateFrame("Frame", "FriendDatatextRightClickMenu", E.UIParent, "L_UIDropDownMenuTemplate")
local menuList = {
	{text = OPTIONS_MENU, isTitle = true, notCheckable = true},
	{text = PARTY_INVITE, hasArrow = true, notCheckable = true},
	{text = CHAT_MSG_WHISPER_INFORM, hasArrow = true, notCheckable = true},
	{text = PLAYER_STATUS, hasArrow = true, notCheckable = true,
		menuList = {
--			{text = "|cff2BC226"..AVAILABLE.."|r", notCheckable = true, func = function() end}, -- TODO
			{text = "|cffE7E716"..CHAT_MSG_AFK.."|r", notCheckable = true, func = function() SendChatMessage("", "AFK") end},
			{text = "|cffFF0000"..CHAT_MSG_DND.."|r", notCheckable = true, func = function() SendChatMessage("", "DND") end}
		}
	}
}

local function inviteClick(playerName)
	menuFrame:Hide()
	InviteByName(playerName)
end

local function whisperClick(playerName)
	menuFrame:Hide()
	SetItemRef("player:"..playerName, format("|Hplayer:%1$s|h[%1$s]|h", playerName), "LeftButton")
end

local lastPanel
local levelNameString = "|cff%02x%02x%02x%d|r |cff%02x%02x%02x%s|r"
local levelNameClassString = "|cff%02x%02x%02x%d|r %s"
local totalOnlineString = join("", GUILD_ONLINE_LABEL, ": %s/%s")
local tthead = {r = 0.4, g = 0.78, b = 1}
local activezone, inactivezone = {r = 0.3, g = 1.0, b = 0.3}, {r = 0.65, g = 0.65, b = 0.65}
local displayString = ""
local groupedTable = {"|cffaaaaaa*|r", ""}
local friendTable = {}
local friendOnline, friendOffline = gsub(ERR_FRIEND_ONLINE_SS, "\124Hplayer:%%s\124h%[%%s%]\124h", ""), gsub(ERR_FRIEND_OFFLINE_S, "%%s", "")
local dataValid = false

local function SortAlphabeticName(a, b)
	if a[1] and b[1] then
		return a[1] < b[1]
	end
end

local function BuildFriendTable(total)
	wipe(friendTable)
	local name, level, class, area, online
	for i = 1, total do
		name, level, class, area, online = GetFriendInfo(i)

		if online then
			for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do if class == v then class = k end end
			for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do if class == v then class = k end end
			friendTable[i] = {name, level, class, area, online}
		end
	end
	if next(friendTable) then
		sort(friendTable, SortAlphabeticName)
	end
end

local function OnEvent(self, event)
	local _, onlineFriends = GetNumberFriends()

	if event == "CHAT_MSG_SYSTEM" then
		if not (find(arg1, friendOnline) or find(arg1, friendOffline)) then return end
	end

	dataValid = false

	self.text:SetText(format(displayString, FRIENDS, onlineFriends))

	lastPanel = self
end

local function OnClick()
	DT.tooltip:Hide()

	if arg1 == "RightButton" then
		local classc, levelc

		menuList[2].menuList = {}
		menuList[3].menuList = {}

		for _, info in friendTable do
			if info[5] then
				classc, levelc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[3]], GetQuestDifficultyColor(info[2])
				classc = classc or GetQuestDifficultyColor(info[2])

				tinsert(menuList[2].menuList, {text = format(levelNameString, levelc.r*255,levelc.g*255,levelc.b*255, info[2],classc.r*255,classc.g*255,classc.b*255, info[1]), arg1 = info[1], notCheckable = true, func = inviteClick})
				tinsert(menuList[3].menuList, {text = format(levelNameString, levelc.r*255,levelc.g*255,levelc.b*255, info[2],classc.r*255,classc.g*255,classc.b*255, info[1]), arg1 = info[1], notCheckable = true, func = whisperClick})
			end
		end
		L_EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
	else
		ToggleFriendsFrame(1)
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	local numberOfFriends, onlineFriends = GetNumberFriends()
	if onlineFriends == 0 then return end

	if not dataValid then
		if numberOfFriends > 0 then BuildFriendTable(numberOfFriends) end
		dataValid = true
	end

	local zonec, classc, levelc
	DT.tooltip:AddDoubleLine(FRIENDS_LIST, format(totalOnlineString, onlineFriends, numberOfFriends), tthead.r, tthead.g, tthead.b, tthead.r, tthead.g, tthead.b)
	if onlineFriends > 0 then
		for _, info in friendTable do
			if info[5] then
				if GetRealZoneText() == info[4] then zonec = activezone else zonec = inactivezone end

				classc, levelc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[3]], GetQuestDifficultyColor(info[2])
				classc = classc or GetQuestDifficultyColor(info[2])

				DT.tooltip:AddDoubleLine(format(levelNameClassString, levelc.r*255,levelc.g*255,levelc.b*255, info[2], info[1]), info[4], classc.r,classc.g,classc.b, zonec.r,zonec.g,zonec.b)
			end
		end
	end

	DT.tooltip:Show()
end

local function ValueColorUpdate(hex)
	displayString = join("", "%s: ", hex, "%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true

DT:RegisterDatatext("Friends", {"PLAYER_LOGIN", "FRIENDLIST_UPDATE", "CHAT_MSG_SYSTEM"}, OnEvent, nil, OnClick, OnEnter, nil, FRIENDS)