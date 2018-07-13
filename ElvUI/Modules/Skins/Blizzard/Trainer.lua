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

	UIPanelWindows["ClassTrainerFrame"] = {area = "doublewide", pushable = 0, whileDead = 1}

	E:Size(ClassTrainerFrame, 710, 470)
	E:StripTextures(ClassTrainerFrame, true)
	E:CreateBackdrop(ClassTrainerFrame, "Transparent")
	E:Point(ClassTrainerFrame.backdrop, "TOPLEFT", 15, -11)
	E:Point(ClassTrainerFrame.backdrop, "BOTTOMRIGHT", -34, 74)

	E:StripTextures(ClassTrainerListScrollFrame)
	E:Size(ClassTrainerListScrollFrame, 300)
	ClassTrainerListScrollFrame.SetHeight = E.noop
	ClassTrainerListScrollFrame:ClearAllPoints()
	ClassTrainerListScrollFrame:SetPoint("TOPLEFT", 17, -85)

	E:StripTextures(ClassTrainerDetailScrollFrame)
	E:Size(ClassTrainerDetailScrollFrame, 295, 280)
	ClassTrainerDetailScrollFrame.SetHeight = E.noop
	ClassTrainerDetailScrollFrame:ClearAllPoints()
	ClassTrainerDetailScrollFrame:SetPoint("TOPRIGHT", ClassTrainerFrame, -64, -85)
	ClassTrainerDetailScrollFrame.scrollBarHideable = nil

	ClassTrainerFrame.bg1 = CreateFrame("Frame", nil, ClassTrainerFrame)
	E:SetTemplate(ClassTrainerFrame.bg1, "Transparent")
	ClassTrainerFrame.bg1:SetPoint("TOPLEFT", 18, -77)
	ClassTrainerFrame.bg1:SetPoint("BOTTOMRIGHT", -367, 77)
	ClassTrainerFrame.bg1:SetFrameLevel(ClassTrainerFrame.bg1:GetFrameLevel() - 1)

	ClassTrainerFrame.bg2 = CreateFrame("Frame", nil, ClassTrainerFrame)
	E:SetTemplate(ClassTrainerFrame.bg2, "Transparent")
	ClassTrainerFrame.bg2:SetPoint("TOPLEFT", ClassTrainerFrame.bg1, "TOPRIGHT", 1, 0)
	ClassTrainerFrame.bg2:SetPoint("BOTTOMRIGHT", ClassTrainerFrame, "BOTTOMRIGHT", -38, 77)
	ClassTrainerFrame.bg2:SetFrameLevel(ClassTrainerFrame.bg2:GetFrameLevel() - 1)

	E:StripTextures(ClassTrainerDetailScrollChildFrame)
	E:Size(ClassTrainerDetailScrollFrame, 300, 150)

	E:StripTextures(ClassTrainerExpandButtonFrame)

	S:HandleDropDownBox(ClassTrainerFrameFilterDropDown)
	ClassTrainerFrameFilterDropDown:SetPoint("TOPRIGHT", -55, -40)

	S:HandleScrollBar(ClassTrainerListScrollFrameScrollBar)
	S:HandleScrollBar(ClassTrainerDetailScrollFrameScrollBar)

	ClassTrainerCancelButton:ClearAllPoints()
	ClassTrainerCancelButton:SetPoint("TOPRIGHT", ClassTrainerDetailScrollFrame, "BOTTOMRIGHT", 23, -3)
	S:HandleButton(ClassTrainerCancelButton)

	ClassTrainerTrainButton:ClearAllPoints()
	ClassTrainerTrainButton:SetPoint("TOPRIGHT", ClassTrainerCancelButton, "TOPLEFT", -3, 0)
	S:HandleButton(ClassTrainerTrainButton)

	ClassTrainerMoneyFrame:ClearAllPoints()
	ClassTrainerMoneyFrame:SetPoint("BOTTOMLEFT", ClassTrainerFrame, "BOTTOMRIGHT", -180, 107)

	S:HandleCloseButton(ClassTrainerFrameCloseButton)

	E:StripTextures(ClassTrainerSkillIcon)
	E:SetTemplate(ClassTrainerSkillIcon, "Default")
	E:StyleButton(ClassTrainerSkillIcon, nil, true)
	E:Size(ClassTrainerSkillIcon, 47)
	ClassTrainerSkillIcon:SetPoint("TOPLEFT", 2, -1)

	ClassTrainerSkillName:SetPoint("TOPLEFT", 55, 0)

	hooksecurefunc("ClassTrainer_SetSelection", function()
		local skillIcon = ClassTrainerSkillIcon:GetNormalTexture()
		if skillIcon then
			E:SetInside(skillIcon)
			skillIcon:SetTexCoord(unpack(E.TexCoords))

			E:SetTemplate(ClassTrainerSkillIcon, "Default")
		end
	end)

	CLASS_TRAINER_SKILLS_DISPLAYED = 19

	hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", function()
		CLASS_TRAINER_SKILLS_DISPLAYED = 19
	end)

	hooksecurefunc("ClassTrainer_SetToClassTrainer", function()
		CLASS_TRAINER_SKILLS_DISPLAYED = 19
	end)

	for i = 12, 19 do
		CreateFrame("Button", "ClassTrainerSkill"..i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate"):SetPoint("TOPLEFT", _G["ClassTrainerSkill"..i - 1], "BOTTOMLEFT")
	end

	ClassTrainerSkill1:SetPoint("TOPLEFT", 22, -80)

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

	ClassTrainerCollapseAllButton:SetPoint("LEFT", ClassTrainerExpandTabLeft, "RIGHT", 5, 20)

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