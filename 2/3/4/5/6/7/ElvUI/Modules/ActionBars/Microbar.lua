local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars");

--Cache global variables
--Lua functions
local _G = getfenv()
local getn = table.getn
local mod = math.mod
--WoW API / Variables
local CreateFrame = CreateFrame

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"WorldMapMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton"
}

local function Button_OnEnter()
	if AB.db.microbar.mouseover then
		UIFrameFadeIn(ElvUI_MicroBar, .2, ElvUI_MicroBar:GetAlpha(), AB.db.microbar.alpha)
	end
end

local function Button_OnLeave()
	if AB.db.microbar.mouseover then
		UIFrameFadeOut(ElvUI_MicroBar, .2, ElvUI_MicroBar:GetAlpha(), 0)
	end
end

function AB:HandleMicroButton(button)
	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()

	--button:SetParent(ElvUI_MicroBar)

	E:Kill(button:GetHighlightTexture())
	HookScript(button, "OnEnter", Button_OnEnter)
	HookScript(button, "OnLeave", Button_OnLeave)

	local f = CreateFrame("Frame", nil, button)
	f:SetFrameLevel(1)
	f:SetFrameStrata("BACKGROUND")
	f:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 0)
	f:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -28)
	E:SetTemplate(f, "Default", true)
	button.backdrop = f

	pushed:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	E:SetInside(pushed, f)

	normal:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	E:SetInside(normal, f)

	if disabled then
		disabled:SetTexCoord(0.17, 0.87, 0.5, 0.908)
		E:SetInside(disabled, f)
	end
end

function AB:UpdateMicroButtonsParent()
	if CharacterMicroButton:GetParent() == ElvUI_MicroBar then return end

	for i = 1, getn(MICRO_BUTTONS) do
	--	_G[MICRO_BUTTONS[i]]:SetParent(ElvUI_MicroBar)
	end

	AB:UpdateMicroPositionDimensions()
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return; end

	local numRows = 1
	for i = 1, getn(MICRO_BUTTONS) do
		local button = _G[MICRO_BUTTONS[i]]
		local prevButton = _G[MICRO_BUTTONS[i-1]] or ElvUI_MicroBar
		local lastColumnButton = _G[MICRO_BUTTONS[i-self.db.microbar.buttonsPerRow]]

		button:ClearAllPoints()

		if prevButton == ElvUI_MicroBar then
			button:SetPoint("TOPLEFT", prevButton, "TOPLEFT", -2 + E.Border, 28 - E.Border)
		elseif mod((i - 1), self.db.microbar.buttonsPerRow) == 0 then
			button:SetPoint("TOP", lastColumnButton, "BOTTOM", 0, 28 - self.db.microbar.yOffset)
			numRows = numRows + 1
		else
			button:SetPoint("LEFT", prevButton, "RIGHT", - 4 + self.db.microbar.xOffset, 0)
		end
	end

	if AB.db.microbar.mouseover then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = ((_G["CharacterMicroButton"]:GetWidth() - 4) * self.db.microbar.buttonsPerRow) + (self.db.microbar.xOffset * (self.db.microbar.buttonsPerRow - 1)) + E.Border * 2
	AB.MicroHeight = ((_G["CharacterMicroButton"]:GetHeight() - 28) * numRows) + (self.db.microbar.yOffset * (numRows - 1)) + E.Border * 2
	ElvUI_MicroBar:SetWidth(AB.MicroWidth)
	ElvUI_MicroBar:SetHeight(AB.MicroHeight)

	if self.db.microbar.enabled then
		ElvUI_MicroBar:Show()
		if ElvUI_MicroBar.mover then
			E:EnableMover(ElvUI_MicroBar.mover:GetName())
		end
	else
		ElvUI_MicroBar:Hide()
		if ElvUI_MicroBar.mover then
			E:DisableMover(ElvUI_MicroBar.mover:GetName())
		end
	end
end

function AB:SetupMicroBar()
	local microBar = CreateFrame("Frame", "ElvUI_MicroBar", E.UIParent)
	microBar:SetPoint("TOPLEFT", E.UIParent, "TOPLEFT", 4, -48)
	for i = 1, getn(MICRO_BUTTONS) do
		self:HandleMicroButton(_G[MICRO_BUTTONS[i]])
	end

	E:SetInside(MicroButtonPortrait, CharacterMicroButton.backdrop)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateMicroButtonsParent")

	self:UpdateMicroPositionDimensions()
	E:CreateMover(microBar, "MicrobarMover", L["Micro Bar"], nil, nil, nil, "ALL,ACTIONBARS")
end