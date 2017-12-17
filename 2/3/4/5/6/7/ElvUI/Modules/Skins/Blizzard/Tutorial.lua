local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables
local MAX_TUTORIAL_ALERTS = MAX_TUTORIAL_ALERTS

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.tutorial ~= true then return end

	for i = 1, MAX_TUTORIAL_ALERTS do
		local button = _G["TutorialFrameAlertButton"..i]
		local icon = button:GetNormalTexture()

		button:SetWidth(35)
		button:SetHeight(45)
		E:SetTemplate(button, "Default", true)
		E:StyleButton(button, nil, true)

		E:SetInside(icon)
		icon:SetTexCoord(0.09, 0.40, 0.11, 0.56)
	end

	E:SetTemplate(TutorialFrame, "Transparent")

	S:HandleCheckBox(TutorialFrameCheckButton)

	S:HandleButton(TutorialFrameOkayButton)
end

S:AddCallback("Tutorial", LoadSkin)