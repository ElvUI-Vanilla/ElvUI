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
		captureBar = _G["WorldStateCaptureBar"..i]

		if captureBar and captureBar:IsShown() then
			captureBar:ClearAllPoints()
			E:Point(captureBar, "TOP", pvpHolder, "BOTTOM", 0, -75)
		end
	end

	for i = 1, NUM_ALWAYS_UP_UI_FRAMES do
		local frame = _G["AlwaysUpFrame"..i]
		local text = _G["AlwaysUpFrame"..i.."Text"]
		local icon = _G["AlwaysUpFrame"..i.."Icon"]
		local dynamic = _G["AlwaysUpFrame"..i.."DynamicIconButton"]

		if frame then
			if i == 1 then
				frame:ClearAllPoints()
				E:Point(frame, "CENTER", pvpHolder, "CENTER", 0, 5)
			end

			text:ClearAllPoints()
			E:Point(text, "CENTER", frame, "CENTER", 0, 0)

			icon:ClearAllPoints()
			E:Point(icon, "CENTER", text, "LEFT", -10, -9)

			dynamic:ClearAllPoints()
			E:Point(dynamic, "LEFT", text, "RIGHT", 5, 0)
		end
	end
end

function B:PositionCaptureBar()
	self:SecureHook("WorldStateAlwaysUpFrame_Update")

	E:Size(pvpHolder, 30, 70)
	E:Point(pvpHolder, "TOP", E.UIParent, "TOP", 0, -4)

	E:CreateMover(pvpHolder, "PvPMover", L["PvP"], nil, nil, nil, "ALL")
end