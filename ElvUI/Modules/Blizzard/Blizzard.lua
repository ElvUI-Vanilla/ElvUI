local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:NewModule("Blizzard", "AceEvent-3.0", "AceHook-3.0");

E.Blizzard = B

function B:Initialize()
	self:AlertMovers()
	self:EnhanceColorPicker()
	self:PositionCaptureBar()
	self:PositionDurabilityFrame()
	self:PositionGMFrames()
	self:MoveWatchFrame()
end

local function InitializeCallback()
	FCF_SelectDockFrame(DEFAULT_CHAT_FRAME)

	B:Initialize()
end

E:RegisterModule(B:GetName(), InitializeCallback)