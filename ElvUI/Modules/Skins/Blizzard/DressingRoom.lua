local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
--WoW API / Variables
local SetDressUpBackground = SetDressUpBackground

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.dressingroom ~= true then return end

	E:StripTextures(DressUpFrame)
	E:CreateBackdrop(DressUpFrame, "Transparent")
	DressUpFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	DressUpFrame.backdrop:SetPoint("BOTTOMRIGHT", -33, 73)

	E:Kill(DressUpFramePortrait)

	SetDressUpBackground()
	DressUpBackgroundTopLeft:SetDesaturated(true)
	DressUpBackgroundTopRight:SetDesaturated(true)
	DressUpBackgroundBotLeft:SetDesaturated(true)
	DressUpBackgroundBotRight:SetDesaturated(true)

	DressUpFrameDescriptionText:SetPoint("CENTER", DressUpFrameTitleText, "BOTTOM", -5, -22)

	S:HandleCloseButton(DressUpFrameCloseButton)

	S:HandleRotateButton(DressUpModelRotateLeftButton)
	DressUpModelRotateLeftButton:SetPoint("TOPLEFT", DressUpFrame, 25, -79)
	S:HandleRotateButton(DressUpModelRotateRightButton)
	DressUpModelRotateRightButton:SetPoint("TOPLEFT", DressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(DressUpFrameCancelButton)
	DressUpFrameCancelButton:SetPoint("CENTER", DressUpFrame, "TOPLEFT", 306, -423)
	S:HandleButton(DressUpFrameResetButton)
	DressUpFrameResetButton:SetPoint("RIGHT", DressUpFrameCancelButton, "LEFT", -3, 0)

	E:CreateBackdrop(DressUpModel, "Default")
	E:SetOutside(DressUpModel.backdrop, DressUpBackgroundTopLeft, nil, nil, DressUpModel)
end

S:AddCallback("DressingRoom", LoadSkin)