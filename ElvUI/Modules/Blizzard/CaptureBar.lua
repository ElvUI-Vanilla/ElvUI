local E, L, DF = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:GetModule("Blizzard");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local pvpHolder = CreateFrame("Frame", "PvPHolder", E.UIParent)

function B:WorldStateAlwaysUpFrame_Update()
	local captureBar
	for i = 1, NUM_EXTENDED_UI_FRAMES do
		captureBar = _G["WorldStateCaptureBar" .. i]
		if captureBar and captureBar:IsShown() then
			captureBar:ClearAllPoints()
			captureBar:SetPoint("TOP", WorldStateAlwaysUpFrame, "BOTTOM", 0, -80)
		end
	end

	WorldStateAlwaysUpFrame:ClearAllPoints()
	WorldStateAlwaysUpFrame:SetPoint("CENTER", pvpHolder, "CENTER", 0, 10)

	if AlwaysUpFrame1 then
		AlwaysUpFrame1:ClearAllPoints()
		AlwaysUpFrame1:SetPoint("CENTER", WorldStateAlwaysUpFrame, "CENTER", 0, 0)
	end

	if AlwaysUpFrame2 then
		AlwaysUpFrame2:SetPoint("TOP", AlwaysUpFrame1, "BOTTOM", 0, -5)
	end

	local offset = 0

	for i = 1, NUM_ALWAYS_UP_UI_FRAMES do
		local frameText = _G["AlwaysUpFrame"..i.."Text"]
		local frameIcon = _G["AlwaysUpFrame"..i.."Icon"]
		local frameIcon2 = _G["AlwaysUpFrame"..i.."DynamicIconButton"]

		frameText:ClearAllPoints()
		frameText:SetPoint("CENTER", WorldStateAlwaysUpFrame, "CENTER", 0, offset)
		frameText:SetJustifyH("CENTER")

		frameIcon:ClearAllPoints()
		frameIcon:SetPoint("CENTER", frameText, "LEFT", -7, -9)
		frameIcon:SetWidth(38)
		frameIcon:SetHeight(38)

		frameIcon2:ClearAllPoints()
		frameIcon2:SetPoint("LEFT", frameText, "RIGHT", 5, 0)
		frameIcon2:SetWidth(38)
		frameIcon2:SetHeight(38)

		offset = offset - 25
	end
end

function B:PositionCaptureBar()
	self:SecureHook("WorldStateAlwaysUpFrame_Update")

	pvpHolder:SetWidth(30)
	pvpHolder:SetHeight(70)
	pvpHolder:SetPoint("TOP", E.UIParent, "TOP", 0, -4)

	E:CreateMover(pvpHolder, "PvPMover", L["PvP"], nil, nil, nil, "ALL")
end