local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local unpack = unpack
local format, join = string.format, string.join
local getn, tinsert, sort, wipe = table.getn, table.insert, table.sort, table.wipe
--WoW API / Variables
local GetGuildInfo = GetGuildInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetMouseFocus = GetMouseFocus
local GetNumGuildMembers = GetNumGuildMembers
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GetRealZoneText = GetRealZoneText
local GuildRoster = GuildRoster
local InviteByName = InviteByName
local IsInGuild = IsInGuild
local IsShiftKeyDown = IsShiftKeyDown
local SetItemRef = SetItemRef
local ToggleFriendsFrame = ToggleFriendsFrame

local GUILD = GUILD
local GUILD_MOTD = GUILD_MOTD
local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

local L_EasyMenu = L_EasyMenu

local tthead, ttsubh, ttoff = {r=0.4, g=0.78, b=1}, {r=0.75, g=0.9, b=1}, {r=.3,g=1,b=.3}
local activezone, inactivezone = {r=0.3, g=1.0, b=0.3}, {r=0.65, g=0.65, b=0.65}
local groupedTable = { "|cffaaaaaa*|r", "" }
local displayString = ""
local noGuildString = ""
local guildInfoString = "%s"
local guildInfoString2 = join("", GUILD, ": %d/%d")
local guildMotDString = "%s |cffaaaaaa- |cffffffff%s"
local levelNameString = "|cff%02x%02x%02x%d|r |cff%02x%02x%02x%s|r %s"
local levelNameStatusString = "|cff%02x%02x%02x%d|r %s"
local nameRankString = "%s |cff999999-|cffffffff %s"
local moreMembersOnlineString = join("", "+ %d ", GUILD_ONLINE_LABEL, "...")
local noteString = join("", "|cff999999   ", LABEL_NOTE, ":|r %s")
local officerNoteString = join("", "|cff999999   ", GUILD_RANK1_DESC, ":|r %s")
local guildTable, guildMotD = {}, ""
local lastPanel

local function sortByRank(a, b)
	if a and b then
		return a[9] < b[9]
	end
end

local function sortByName(a, b)
	if a and b then
		return a[1] < b[1]
	end
end

local function SortGuildTable(shift)
	if shift then
		sort(guildTable, sortByRank)
	else
		sort(guildTable, sortByName)
	end
end

local function BuildGuildTable()
	wipe(guildTable)
	local name, rank, rankIndex, level, class, zone, note, officernote, online

	local totalMembers = GetNumGuildMembers()
	for i = 1, totalMembers do
		name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(i)
		if not name then return end

		if online then
			for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do if class == v then class = k end end
			for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do if class == v then class = k end end
			tinsert(guildTable, {name, rank, level, zone, note, officernote, online, class, rankIndex})
		end
	end
end

local function UpdateGuildMessage()
	guildMotD = GetGuildRosterMOTD()
end

local eventHandlers = {
	-- when we enter the world and guildframe is not available then
	-- load guild frame, update guild message
	["PLAYER_ENTERING_WORLD"] = function()
		GuildRoster()
	end,
	-- Guild Roster updated, so rebuild the guild table
	["GUILD_ROSTER_UPDATE"] = function(self)
		BuildGuildTable()
		UpdateGuildMessage()

		if GetMouseFocus() == self then
			self:GetScript("OnEnter")(self, nil, true)
		end
	end,
	["PLAYER_GUILD_UPDATE"] = GuildRoster,
	-- our guild message of the day changed
	["GUILD_MOTD"] = function(self)
		guildMotD = arg1
	end,
	["ELVUI_FORCE_RUN"] = E.noop,
	["ELVUI_COLOR_UPDATE"] = E.noop,

	["PLAYER_LOGIN"] = GuildRoster, -- Temporarily
}

local function OnEvent(self, event)
	lastPanel = self

	if IsInGuild() then
		eventHandlers[event](self, event)

		self.text:SetText(format(displayString, getn(guildTable)))
	else
		self.text:SetText(noGuildString)
	end
end

local menuFrame = CreateFrame("Frame", "GuildDatatTextRightClickMenu", E.UIParent, "L_UIDropDownMenuTemplate")
local menuList = {
	{text = OPTIONS_MENU, isTitle = true, notCheckable = true},
	{text = PARTY_INVITE, hasArrow = true, notCheckable = true},
	{text = CHAT_MSG_WHISPER_INFORM, hasArrow = true, notCheckable = true}
}

local function inviteClick(playerName)
	menuFrame:Hide()
	InviteByName(playerName)
end

local function whisperClick(playerName)
	menuFrame:Hide()
	SetItemRef("player:"..playerName, format("|Hplayer:%1$s|h[%1$s]|h", playerName), "LeftButton")
end

local function OnClick()
	if arg1 == "RightButton" and IsInGuild() then
		DT.tooltip:Hide()

		local classc, levelc, info

		menuList[2].menuList = {}
		menuList[3].menuList = {}

		for i = 1, getn(guildTable) do
			info = guildTable[i]
			if info[7] and info[1] ~= E.myname then
				classc, levelc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[8]], GetQuestDifficultyColor(info[3])

				tinsert(menuList[2].menuList, {text = format(levelNameString, levelc.r*255,levelc.g*255,levelc.b*255, info[3], classc.r*255,classc.g*255,classc.b*255, info[1], ""), arg1 = info[1],notCheckable=true, func = inviteClick})
				tinsert(menuList[3].menuList, {text = format(levelNameString, levelc.r*255,levelc.g*255,levelc.b*255, info[3], classc.r*255,classc.g*255,classc.b*255, info[1], ""), arg1 = info[1],notCheckable=true, func = whisperClick})
			end
		end

		L_EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
	else
		ToggleFriendsFrame(3)
	end
end

local function OnEnter(self, _, noUpdate)
	if not IsInGuild() then return end

	DT:SetupTooltip(self)

	local online, total = 0, GetNumGuildMembers(true)
	for i = 0, total do local _, _, _, _, _, _, _, _, connected = GetGuildRosterInfo(i) if connected then online = online + 1 end end
	if not guildTable[1] then BuildGuildTable() end

	SortGuildTable(IsShiftKeyDown())

	local guildName, guildRank = GetGuildInfo("player")

	if guildName and guildRank then
		DT.tooltip:AddDoubleLine(format(guildInfoString, guildName), format(guildInfoString2, online, total),tthead.r,tthead.g,tthead.b,tthead.r,tthead.g,tthead.b)
		DT.tooltip:AddLine(guildRank, unpack(tthead))
	end

	if guildMotD ~= "" then
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddLine(format(guildMotDString, GUILD_MOTD, guildMotD), ttsubh.r, ttsubh.g, ttsubh.b, 1)
	end

	local zonec, classc, levelc, info
	local shown = 0

	DT.tooltip:AddLine(" ")
	for i = 1, getn(guildTable) do
		-- if more then 30 guild members are online, we don't Show any more, but inform user there are more
		if 30 - shown <= 1 then
			if online - 30 > 1 then DT.tooltip:AddLine(format(moreMembersOnlineString, online - 30), ttsubh.r, ttsubh.g, ttsubh.b) end
			break
		end

		info = guildTable[i]
		if GetRealZoneText() == info[4] then zonec = activezone else zonec = inactivezone end
		classc, levelc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[8]], GetQuestDifficultyColor(info[3])

		if IsShiftKeyDown() then
			DT.tooltip:AddDoubleLine(format(nameRankString, info[1], info[2]), info[4], classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
			if info[5] ~= "" then DT.tooltip:AddLine(format(noteString, info[5]), ttsubh.r, ttsubh.g, ttsubh.b, 1) end
			if info[6] ~= "" then DT.tooltip:AddLine(format(officerNoteString, info[6]), ttoff.r, ttoff.g, ttoff.b, 1) end
		else
			DT.tooltip:AddDoubleLine(format(levelNameStatusString, levelc.r*255, levelc.g*255, levelc.b*255, info[3], info[1], " " .. info[8]), info[4], classc.r,classc.g,classc.b, zonec.r,zonec.g,zonec.b)
		end
		shown = shown + 1
	end

	DT.tooltip:Show()

	if not noUpdate then
		GuildRoster()
	end
end

local function ValueColorUpdate(hex)
	displayString = join("", GUILD, ": ", hex, "%d|r")
	noGuildString = join("", hex, L["No Guild"])

	if lastPanel ~= nil then
		OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Guild", {"PLAYER_ENTERING_WORLD", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD"}, OnEvent, nil, OnClick, OnEnter, nil, GUILD)