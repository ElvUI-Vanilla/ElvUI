local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local getn = table.getn
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.macro ~= true then return end

	local MacroFrame = _G["MacroFrame"]
	E:StripTextures(MacroFrame)
	E:CreateBackdrop(MacroFrame, "Transparent")
	E:Point(MacroFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(MacroFrame.backdrop, "BOTTOMRIGHT", -32, 71)

	MacroFrame.bg = CreateFrame("Frame", nil, MacroFrame)
	E:SetTemplate(MacroFrame.bg, "Transparent", true)
	E:Point(MacroFrame.bg, "TOPLEFT", MacroButton1, -10, 10)
	E:Point(MacroFrame.bg, "BOTTOMRIGHT", MacroButton18, 10, -10)

	E:StripTextures(MacroFrameTextBackground)
	E:CreateBackdrop(MacroFrameTextBackground, "Default")
	E:Point(MacroFrameTextBackground.backdrop, "TOPLEFT", 6, -3)
	E:Point(MacroFrameTextBackground.backdrop, "BOTTOMRIGHT", -2, 3)

	local Buttons = {
		"MacroFrameTab1",
		"MacroFrameTab2",
		"MacroDeleteButton",
		"MacroNewButton",
		"MacroExitButton",
		"MacroEditButton",
		"MacroPopupOkayButton",
		"MacroPopupCancelButton"
	}

	for i = 1, getn(Buttons) do
		E:StripTextures(_G[Buttons[i]])
		S:HandleButton(_G[Buttons[i]])
	end

	for i = 1, 2 do
		local tab = _G["MacroFrameTab"..i]

		E:Height(tab, 22)
	end

	E:Point(MacroFrameTab1, "TOPLEFT", MacroFrame, "TOPLEFT", 85, -39)
	E:Point(MacroFrameTab2, "LEFT", MacroFrameTab1, "RIGHT", 4, 0)

	S:HandleCloseButton(MacroFrameCloseButton)

	S:HandleScrollBar(MacroFrameScrollFrameScrollBar)
	S:HandleScrollBar(MacroPopupScrollFrameScrollBar)

	MacroEditButton:ClearAllPoints()
	E:Point(MacroEditButton, "BOTTOMLEFT", MacroFrameSelectedMacroButton, "BOTTOMRIGHT", 10, 0)

	E:Point(MacroFrameSelectedMacroName, "TOPLEFT", MacroFrameSelectedMacroBackground, "TOPRIGHT", -4, -10)

	E:StripTextures(MacroFrameSelectedMacroButton)
	E:SetTemplate(MacroFrameSelectedMacroButton, "Transparent")
	E:StyleButton(MacroFrameSelectedMacroButton, true)
	MacroFrameSelectedMacroButton:GetNormalTexture():SetTexture(nil)

	MacroFrameSelectedMacroButtonIcon:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(MacroFrameSelectedMacroButtonIcon)

	MacroFrameCharLimitText:ClearAllPoints()
	E:Point(MacroFrameCharLimitText, "BOTTOM", MacroFrameTextBackground, 0, -9)

	for i = 1, MAX_MACROS do
		local Button = _G["MacroButton"..i]
		local ButtonIcon = _G["MacroButton"..i.."Icon"]

		if Button then
			E:StripTextures(Button)
			E:SetTemplate(Button, "Default", true)
			E:StyleButton(Button, nil, true)
		end

		if ButtonIcon then
			ButtonIcon:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(ButtonIcon)
		end
	end

	S:HandleIconSelectionFrame(MacroPopupFrame, NUM_MACRO_ICONS_SHOWN, "MacroPopupButton", "MacroPopup")

	E:CreateBackdrop(MacroPopupScrollFrame, "Transparent")
	E:Point(MacroPopupScrollFrame.backdrop, "TOPLEFT", 51, 2)
	E:Point(MacroPopupScrollFrame.backdrop, "BOTTOMRIGHT", 0, 4)

	E:Point(MacroPopupFrame, "TOPLEFT", MacroFrame, "TOPRIGHT", -41, 1)
end

S:AddCallbackForAddon("Blizzard_MacroUI", "Macro", LoadSkin)