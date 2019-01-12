local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local time = time
local format, gsub, join = string.format, string.gsub, string.join
--WoW API / Variables
local GetGameTime = GetGameTime
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local IsAddOnLoaded = IsAddOnLoaded
local SecondsToTime = SecondsToTime

local europeDisplayFormat = join("", "%02d", ":|r%02d")
local instanceFormat = "%s |cffaaaaaa(%s)"
local timeDisplayFormat = ""
local dateDisplayFormat = ""
local enteredFrame = false

local lastPanel

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

	enteredFrame = false
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	if not enteredFrame then
		RequestRaidInfo()

		enteredFrame = true
	end

	local oneraid
	local name, id, reset
	for i = 1, GetNumSavedInstances() do
		name, id, reset = GetSavedInstanceInfo(i)
		if name then
			if not oneraid then
				DT.tooltip:AddLine(L["Saved Instance(s)"])

				oneraid = true
			end

			DT.tooltip:AddDoubleLine(format(instanceFormat, name, id), SecondsToTime(reset, true), 1, 1, 1, 0.8, 0.8, 0.8)
		end

		if DT.tooltip:NumLines() > 0 then
			DT.tooltip:AddLine(" ")
		end
	end

	DT.tooltip:AddDoubleLine(L["Realm Time:"], format(europeDisplayFormat, GetGameTime()), 1, 1, 1, 0.8, 0.8, 0.8)

	DT.tooltip:Show()
end

local function OnEvent(self, event)
	if event == "UPDATE_INSTANCE_INFO" and enteredFrame then
		OnEnter(self)
	end
end

local int = 5
local function OnUpdate(self, t)
	int = int - t

	if int > 0 then return end

	if enteredFrame then
		OnEnter(self)
	end

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
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext("Time", {"UPDATE_INSTANCE_INFO"}, OnEvent, OnUpdate, OnClick, OnEnter, OnLeave)
