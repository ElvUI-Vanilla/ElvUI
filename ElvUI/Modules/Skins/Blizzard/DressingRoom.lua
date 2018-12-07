local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
--WoW API / Variables
local SetDressUpBackground = SetDressUpBackground

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.dressingroom ~= true then return end

	local DressUpFrame = _G["DressUpFrame"]
	E:StripTextures(DressUpFrame)
	E:CreateBackdrop(DressUpFrame, "Transparent")
	E:Point(DressUpFrame.backdrop, "TOPLEFT", 10, -12)
	E:Point(DressUpFrame.backdrop, "BOTTOMRIGHT", -33, 73)

	E:Kill(DressUpFramePortrait)

	SetDressUpBackground()
	DressUpBackgroundTopLeft:SetDesaturated(true)
	DressUpBackgroundTopRight:SetDesaturated(true)
	DressUpBackgroundBotLeft:SetDesaturated(true)
	DressUpBackgroundBotRight:SetDesaturated(true)

	E:Point(DressUpFrameDescriptionText, "CENTER", DressUpFrameTitleText, "BOTTOM", -5, -22)

	S:HandleCloseButton(DressUpFrameCloseButton)

	S:HandleRotateButton(DressUpModelRotateLeftButton)
	E:Point(DressUpModelRotateLeftButton, "TOPLEFT", DressUpFrame, 25, -79)
	S:HandleRotateButton(DressUpModelRotateRightButton)
	E:Point(DressUpModelRotateRightButton, "TOPLEFT", DressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(DressUpFrameCancelButton)
	E:Point(DressUpFrameCancelButton, "CENTER", DressUpFrame, "TOPLEFT", 306, -423)
	S:HandleButton(DressUpFrameResetButton)
	E:Point(DressUpFrameResetButton, "RIGHT", DressUpFrameCancelButton, "LEFT", -3, 0)

	E:CreateBackdrop(DressUpModel, "Default")
	DressUpModel.backdrop:SetPoint("TOPLEFT", -2, 1)
	DressUpModel.backdrop:SetPoint("BOTTOMRIGHT", 0, 19)
end

S:AddCallback("DressingRoom", LoadSkin)