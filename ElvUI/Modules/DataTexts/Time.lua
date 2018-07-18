local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local next, unpack = next, unpack
local time = time
local format, gsub, join = string.format, string.gsub, string.join
local abs = math.abs
local getn, tinsert = table.getn, table.insert
--WoW API / Variables
local GetGameTime = GetGameTime
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local IsAddOnLoaded = IsAddOnLoaded
local SecondsToTime = SecondsToTime

local timeDisplayFormat = ""
local dateDisplayFormat = ""
local europeDisplayFormat_nocolor = join("", "%02d", ":|r%02d")
local lockoutInfoFormat = "|cffaaaaaa(%s)"
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8}

local function OnClick()
	if IsAddOnLoaded("TimeManager") then -- https://github.com/gashole/TimeManager
		if arg1 == "RightButton" then
			TimeManagerClockButton_OnClick()
		else
			GameTimeFrame_OnClick()
		end
	end
end

local function OnLeave()
	DT.tooltip:Hide()
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	RequestRaidInfo()

	local lockedInstances = {raids = {}}
	local _, name, reset

	for i = 1, GetNumSavedInstances() do
		name, _, reset = GetSavedInstanceInfo(i)
		if name then
			tinsert(lockedInstances["raids"], {name, reset})
		end
	end

	if next(lockedInstances["raids"]) then
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddLine(L["Saved Raid(s)"])

		for i = 1, getn(lockedInstances["raids"]) do
			name, reset = unpack(lockedInstances["raids"][i])
			lockoutColor = extended and lockoutColorExtended or lockoutColorNormal
			DT.tooltip:AddDoubleLine(format(lockoutInfoFormat, name), SecondsToTime(abs(reset), 1, 1, false), 1, 1, 1, lockoutColor.r, lockoutColor.g, lockoutColor.b)
		end

		DT.tooltip:Show()
		DT.tooltip:AddLine(" ")
	end

	DT.tooltip:AddDoubleLine(L["Realm time:"], format(europeDisplayFormat_nocolor, GetGameTime()), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)
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

DT:RegisterDatatext("Time", nil, nil, OnUpdate, OnClick, OnEnter, OnLeave)