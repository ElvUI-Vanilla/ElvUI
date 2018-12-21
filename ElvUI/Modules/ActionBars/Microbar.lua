local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars");

--Cache global variables
--Lua functions
local _G = _G
local gsub, match = string.gsub, string.match
--WoW API / Variables
local CreateFrame = CreateFrame
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut

local microBar = CreateFrame("Frame", "ElvUI_MicroBar", E.UIParent)
microBar:SetFrameStrata("BACKGROUND")

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

local function onEnter()
	if AB.db.microbar.mouseover then
		UIFrameFadeIn(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), AB.db.microbar.alpha)
	end
end

local function onLeave()
	if AB.db.microbar.mouseover then
		UIFrameFadeOut(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), 0)
	end
end

function AB:HandleMicroButton(button)
	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()

	local f = CreateFrame("Frame", nil, button)
	f:SetFrameLevel(button:GetFrameLevel() - 2)
	E:SetTemplate(f, "Default", true)
	E:SetOutside(f, button)
	button.backdrop = f

	button:SetParent(ElvUI_MicroBar)
	E:Kill(button:GetHighlightTexture())
	HookScript(button, "OnEnter", onEnter)
	HookScript(button, "OnLeave", onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)
	button:Show()

	pushed:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	E:SetInside(pushed, f)

	normal:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	E:SetInside(normal, f)

	if disabled then
		disabled:SetTexCoord(0.17, 0.87, 0.5, 0.908)
		E:SetInside(disabled, f)
	end
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return end

	local numRows = 1
	local prevButton = ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)

	for i = 1, getn(MICRO_BUTTONS) do
		local button = _G[MICRO_BUTTONS[i]]
		local lastColumnButton = i - self.db.microbar.buttonsPerRow
		lastColumnButton = _G[MICRO_BUTTONS[lastColumnButton]]

		E:Size(button, self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4)
		button:ClearAllPoints()

		if prevButton == ElvUI_MicroBar then
			E:Point(button, "TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
		elseif mod((i - 1), self.db.microbar.buttonsPerRow) == 0 then
			E:Point(button, "TOP", lastColumnButton, "BOTTOM", 0, -spacing)
			numRows = numRows + 1
		else
			E:Point(button, "LEFT", prevButton, "RIGHT", spacing, 0)
		end

		prevButton = button
	end

	if AB.db.microbar.mouseover and not MouseIsOver(ElvUI_MicroBar) then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = (((_G["CharacterMicroButton"]:GetWidth() + spacing) * self.db.microbar.buttonsPerRow) - spacing) + (offset * 2)
	AB.MicroHeight = (((_G["CharacterMicroButton"]:GetHeight() + spacing) * numRows) - spacing) + (offset * 2)
	E:Size(ElvUI_MicroBar, AB.MicroWidth, AB.MicroHeight)

	-- local visibility = self.db.microbar.visibility
	-- if visibility and match(visibility, "[\n\r]") then
	-- 	visibility = gsub(visibility, "[\n\r]", "")
	-- end


	if ElvUI_MicroBar.mover then
		if self.db.microbar.enabled then
			ElvUI_MicroBar:Show()
			E:EnableMover(ElvUI_MicroBar.mover:GetName())
		else
			ElvUI_MicroBar:Hide()
			E:DisableMover(ElvUI_MicroBar.mover:GetName())
		end
	end
end

function AB:SetupMicroBar()
	E:Point(ElvUI_MicroBar, "TOPLEFT", E.UIParent, "TOPLEFT", 4, -48)
	ElvUI_MicroBar:EnableMouse(true)
	ElvUI_MicroBar:SetScript("OnEnter", onEnter)
	ElvUI_MicroBar:SetScript("OnLeave", onLeave)

	for i = 1, getn(MICRO_BUTTONS) do
		self:HandleMicroButton(_G[MICRO_BUTTONS[i]])
	end

	E:SetInside(MicroButtonPortrait, CharacterMicroButton.backdrop)

	self:UpdateMicroPositionDimensions()

	E:Kill(MainMenuBarPerformanceBarFrame)

	E:CreateMover(ElvUI_MicroBar, 'MicrobarMover', L["Micro Bar"], nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,microbar")
end