local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local find = string.find
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.trainer ~= true then return end

	E:CreateBackdrop(ClassTrainerFrame, "Transparent")
	E:Point(ClassTrainerFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(ClassTrainerFrame.backdrop, "BOTTOMRIGHT", -32, 74)

	E:StripTextures(ClassTrainerFrame, true)

	E:StripTextures(ClassTrainerExpandButtonFrame)

	S:HandleDropDownBox(ClassTrainerFrameFilterDropDown)
	E:Point(ClassTrainerFrameFilterDropDown, "TOPRIGHT", -40, -64)

	E:StripTextures(ClassTrainerListScrollFrame)
	S:HandleScrollBar(ClassTrainerListScrollFrameScrollBar)

	E:StripTextures(ClassTrainerDetailScrollFrame)
	S:HandleScrollBar(ClassTrainerDetailScrollFrameScrollBar)

	E:StripTextures(ClassTrainerSkillIcon)

	E:Kill(ClassTrainerCancelButton)

	S:HandleButton(ClassTrainerTrainButton)
	E:Point(ClassTrainerTrainButton, "BOTTOMRIGHT", -38, 80)

	S:HandleCloseButton(ClassTrainerFrameCloseButton)

	hooksecurefunc("ClassTrainer_SetSelection", function()
		local skillIcon = ClassTrainerSkillIcon:GetNormalTexture()
		if skillIcon then
			E:SetInside(skillIcon)
			skillIcon:SetTexCoord(unpack(E.TexCoords))

			E:SetTemplate(ClassTrainerSkillIcon, "Default")
		end
	end)

	for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
		local button = _G["ClassTrainerSkill"..i]
		local highlight = _G["ClassTrainerSkill"..i.."Highlight"]

		button:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		button.SetNormalTexture = E.noop
		E:Size(button:GetNormalTexture(), 14)

		highlight:SetTexture("")
		highlight.SetTexture = E.noop

		hooksecurefunc(button, "SetNormalTexture", function(self, texture)
			if find(texture, "MinusButton") then
				self:GetNormalTexture():SetTexCoord(0.545, 0.975, 0.085, 0.925)
			elseif find(texture, "PlusButton") then
				self:GetNormalTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
			else
				self:GetNormalTexture():SetTexCoord(0, 0, 0, 0)
			end
		end)
	end

	ClassTrainerCollapseAllButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
	ClassTrainerCollapseAllButton.SetNormalTexture = E.noop
	ClassTrainerCollapseAllButton:GetNormalTexture():SetPoint("LEFT", 3, 2)
	E:Size(ClassTrainerCollapseAllButton:GetNormalTexture(), 15)

	ClassTrainerCollapseAllButton:SetHighlightTexture("")
	ClassTrainerCollapseAllButton.SetHighlightTexture = E.noop

	ClassTrainerCollapseAllButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
	ClassTrainerCollapseAllButton.SetDisabledTexture = E.noop
	ClassTrainerCollapseAllButton:GetDisabledTexture():SetPoint("LEFT", 3, 2)
	E:Size(ClassTrainerCollapseAllButton:GetDisabledTexture(), 15)
	ClassTrainerCollapseAllButton:GetDisabledTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
	ClassTrainerCollapseAllButton:GetDisabledTexture():SetDesaturated(true)

	hooksecurefunc(ClassTrainerCollapseAllButton, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self:GetNormalTexture():SetTexCoord(0.545, 0.975, 0.085, 0.925)
		else
			self:GetNormalTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
		end
	end)
end

S:AddCallbackForAddon("Blizzard_TrainerUI", "Trainer", LoadSkin)