local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local collectgarbage = collectgarbage
local sort, wipe = table.sort, wipe
local floor = math.floor
local format = string.format
local gcinfo = gcinfo
--WoW API / Variables
local GetNetStats = GetNetStats
local GetFramerate = GetFramerate

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

local function formatMem(memory)
	local mult = 10 ^ 1
	if(memory > 999) then
		local mem = ((memory / 1024) * mult) / mult
		return format(megaByteString, mem)
	else
		local mem = (memory * mult) / mult
		return format(kiloByteString, mem)
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

local function OnClick(_, btn)
	if btn == "RightButton" then
		collectgarbage()
	elseif btn == "LeftButton" then
		ToggleGameMenuFrame()
	end
end

local function OnEnter(self)
	enteredFrame = true
	DT:SetupTooltip(self)

	local totalMemory = gcinfo()
	local _, _, latency = GetNetStats()
	DT.tooltip:AddDoubleLine(L["Home Latency:"], format(homeLatencyString, latency), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	DT.tooltip:AddDoubleLine(L["Total Memory:"], formatMem(totalMemory), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)

	DT.tooltip:Show()
end

local function OnLeave()
	enteredFrame = false
	DT.tooltip:Hide()
end

local function OnUpdate(self, t)
	int = int - t

	if int < 0 then
		local framerate = floor(GetFramerate())
		local _, _, latency = GetNetStats()

		self.text:SetText(format("FPS: %s%d|r MS: %s%d|r",
			statusColors[framerate >= 30 and 1 or (framerate >= 20 and framerate < 30) and 2 or (framerate >= 10 and framerate < 20) and 3 or 4],
			framerate,
			statusColors[latency < 150 and 1 or (latency >= 150 and latency < 300) and 2 or (latency >= 300 and latency < 500) and 3 or 4],
			latency))
		int = 1
		if enteredFrame then
			OnEnter(this)
		end
	end
end

DT:RegisterDatatext("System", nil, nil, OnUpdate, OnClick, OnEnter, OnLeave, L["System"])