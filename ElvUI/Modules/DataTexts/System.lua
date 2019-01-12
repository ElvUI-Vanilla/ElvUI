local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local select, collectgarbage = select, collectgarbage
local sort, wipe = table.sort, wipe
local floor = math.floor
local format = string.format
local gcinfo = gcinfo
--WoW API / Variables
local GetAddOnInfo = GetAddOnInfo
local GetCVar = GetCVar
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local GetNumAddOns = GetNumAddOns
local IsAddOnLoaded = IsAddOnLoaded
local IsShiftKeyDown = IsShiftKeyDown

local int, int2 = 6, 5
local statusColors = {
	"|cff0CD809",
	"|cffE8DA0F",
	"|cffFF9000",
	"|cffD80909"
}

local enteredFrame = false
local homeLatencyString = "%d ms"
local kiloByteString = "%d kb"
local megaByteString = "%.2f mb"
local totalMemory = 0

local function formatMem(memory)
	local mult = 10 ^ 1
	if memory > 999 then
		local mem = ((memory / 1024) * mult) / mult
		return format(megaByteString, mem)
	else
		local mem = (memory * mult) / mult
		return format(kiloByteString, mem)
	end
end

local function sortByMemoryOrCPU(a, b)
	if a and b then
		return (a[3] == b[3] and a[2] < b[2]) or a[3] > b[3]
	end
end

local memoryTable = {}
local function RebuildAddonList()
	local addOnCount = GetNumAddOns()
	if addOnCount == getn(memoryTable) then return end

	wipe(memoryTable)
	for i = 1, addOnCount do
		memoryTable[i] = {i, select(2, GetAddOnInfo(i)), 0}
	end
end

local function ToggleGameMenuFrame()
	if GameMenuFrame:IsShown() then
		PlaySound("igMainMenuQuit")
		HideUIPanel(GameMenuFrame)
	else
		PlaySound("igMainMenuOpen")
		ShowUIPanel(GameMenuFrame)
	end
end

local function OnClick()
	if arg1 == "RightButton" then
		collectgarbage()
	elseif arg1 == "LeftButton" then
		ToggleGameMenuFrame()
	end
end

local function OnEnter(self)
	enteredFrame = true
	DT:SetupTooltip(self)

	totalMemory = gcinfo()
	DT.tooltip:AddDoubleLine(L["Home Latency:"], format(homeLatencyString, select(3, GetNetStats())), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	DT.tooltip:AddDoubleLine(L["Total Memory:"], formatMem(totalMemory), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)

	local ele
		DT.tooltip:AddLine(" ")
		for i = 1, getn(memoryTable) do
			ele = memoryTable[i]
			if ele and IsAddOnLoaded(ele[1]) then
				DT.tooltip:AddLine(ele[2])
			end
		end

	DT.tooltip:Show()
end

local function OnLeave()
	enteredFrame = false
	DT.tooltip:Hide()
end

local function OnUpdate(self, t)
	int = int - t
	int2 = int2 - t

	if int < 0 then
		RebuildAddonList()
		int = 10
	end
	if int2 < 0 then
		local framerate = floor(GetFramerate())
		local latency = select(3, GetNetStats())

		self.text:SetText(format("FPS: %s%d|r MS: %s%d|r",
			statusColors[framerate >= 30 and 1 or (framerate >= 20 and framerate < 30) and 2 or (framerate >= 10 and framerate < 20) and 3 or 4],
			framerate,
			statusColors[latency < 150 and 1 or (latency >= 150 and latency < 300) and 2 or (latency >= 300 and latency < 500) and 3 or 4],
			latency))
		int2 = 1
		if enteredFrame then
			OnEnter(this)
		end
	end
end

DT:RegisterDatatext("System", nil, nil, OnUpdate, OnClick, OnEnter, OnLeave, L["System"])
