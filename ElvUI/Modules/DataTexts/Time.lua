local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local time = time
local format, join = string.format, string.join
--WoW API / Variables
local GetGameTime = GetGameTime
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local SecondsToTime = SecondsToTime
local TIMEMANAGER_TOOLTIP_REALMTIME = "Realm time:"

local timeDisplayFormat = ""
local dateDisplayFormat = ""
local europeDisplayFormat_nocolor = join("", "%02d", ":|r%02d")
local lockoutInfoFormatNoEnc = "%s%s |cffaaaaaa(%s)"
local difficultyInfo = {"N", "N", "H", "H"}
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8}

local function OnLeave()
	DT.tooltip:Hide()
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	local name, _, reset, difficultyId, locked, extended, isRaid, maxPlayers
	local oneraid, lockoutColor
	for i = 1, GetNumSavedInstances() do
		name, _, reset, difficultyId, locked, extended, _, isRaid, maxPlayers = GetSavedInstanceInfo(i)
		if isRaid and (locked or extended) and name then
			if not oneraid then
				DT.tooltip:AddLine(L["Saved Raid(s)"])
				DT.tooltip:AddLine(" ")
				oneraid = true
			end
			if extended then
				lockoutColor = lockoutColorExtended
			else
				lockoutColor = lockoutColorNormal
			end

			DT.tooltip:AddDoubleLine(format(lockoutInfoFormatNoEnc, maxPlayers, difficultyInfo[difficultyId], name), SecondsToTime(reset, false, nil, 3), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
		end
	end

	DT.tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, format(europeDisplayFormat_nocolor, GetGameTime()), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)

	DT.tooltip:Show()
end

local lastPanel
local int = 5
local function OnUpdate(self, t)
	int = int - t

	if int > 0 then return end

	self.text:SetText(gsub(gsub(BetterDate(E.db.datatexts.timeFormat.." "..E.db.datatexts.dateFormat, time()), ":", timeDisplayFormat), "%s", dateDisplayFormat))

	lastPanel = self
	int = 1
end

local function ValueColorUpdate(hex)
	timeDisplayFormat = join("", hex, ":|r")
	dateDisplayFormat = join("", hex, " ")

	if lastPanel ~= nil then
		OnUpdate(lastPanel, 20000)
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true

DT:RegisterDatatext("Time", nil, nil, OnUpdate, nil, OnEnter, OnLeave)