local E, L, DF = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:GetModule("Blizzard");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

function B:PositionDurabilityFrame()
	DurabilityFrame:SetFrameStrata("HIGH")

	local function SetPosition(self, _, parent)
		if parent == "MinimapCluster" or parent == _G["MinimapCluster"] then
			self:ClearAllPoints()
			self:SetPoint("RIGHT", Minimap, "RIGHT")
			self:SetScale(0.6)
		end
	end

	hooksecurefunc(DurabilityFrame, "SetPoint", SetPosition)
end