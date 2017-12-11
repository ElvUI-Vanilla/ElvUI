local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local find = string.find
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.trainer ~= true then return end

	E:CreateBackdrop(ClassTrainerFrame, "Transparent")
	ClassTrainerFrame.backdrop:SetPoint("TOPLEFT", 10, -11)
	ClassTrainerFrame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)

	E:StripTextures(ClassTrainerFrame, true)

	E:StripTextures(ClassTrainerExpandButtonFrame)

	S:HandleDropDownBox(ClassTrainerFrameFilterDropDown)
	ClassTrainerFrameFilterDropDown:SetPoint("TOPRIGHT", -40, -64)

	E:StripTextures(ClassTrainerListScrollFrame)
	S:HandleScrollBar(ClassTrainerListScrollFrameScrollBar)

	E:StripTextures(ClassTrainerDetailScrollFrame)
	S:HandleScrollBar(ClassTrainerDetailScrollFrameScrollBar)

	E:StripTextures(ClassTrainerSkillIcon)

	S:HandleButton(ClassTrainerTrainButton)
	S:HandleButton(ClassTrainerCancelButton)

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
		local skillButton = _G["ClassTrainerSkill" .. i]
		skillButton:SetNormalTexture("")
		skillButton.SetNormalTexture = E.noop

		_G["ClassTrainerSkill" .. i .. "Highlight"]:SetTexture("")
		_G["ClassTrainerSkill" .. i .. "Highlight"].SetTexture = E.noop

		skillButton.Text = skillButton:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(skillButton.Text, nil, 22)
		skillButton.Text:SetPoint("LEFT", 3, 0)
		skillButton.Text:SetText("+")

		hooksecurefunc(skillButton, "SetNormalTexture", function(self, texture)
			if texture == "Interface\\Buttons\\UI-MinusButton-Up" then
				self.Text:SetText("-")
			elseif texture == "Interface\\Buttons\\UI-PlusButton-Up" then
				self.Text:SetText("+")
			else
				self.Text:SetText("")
			end
		end)
	end

	ClassTrainerCollapseAllButton:SetNormalTexture("")
	ClassTrainerCollapseAllButton.SetNormalTexture = E.noop
	ClassTrainerCollapseAllButton:SetHighlightTexture("")
	ClassTrainerCollapseAllButton.SetHighlightTexture = E.noop
	ClassTrainerCollapseAllButton:SetDisabledTexture("")
	ClassTrainerCollapseAllButton.SetDisabledTexture = E.noop

	ClassTrainerCollapseAllButton.Text = ClassTrainerCollapseAllButton:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(ClassTrainerCollapseAllButton.Text, nil, 22)
	ClassTrainerCollapseAllButton.Text:SetPoint("LEFT", 3, 0)
	ClassTrainerCollapseAllButton.Text:SetText("+")

	hooksecurefunc(ClassTrainerCollapseAllButton, "SetNormalTexture", function(self, texture)
		if texture == "Interface\\Buttons\\UI-MinusButton-Up" then
			self.Text:SetText("-")
		else
			self.Text:SetText("+")
		end
	end)
end

S:AddCallbackForAddon("Blizzard_TrainerUI", "Trainer", LoadSkin)