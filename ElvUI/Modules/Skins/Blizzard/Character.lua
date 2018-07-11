local E, L, V, P, G = unpack(ElvUI) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local pairs = pairs
local find, getn = string.find, table.getn
--WoW API / Variables
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventoryItemQuality = GetInventoryItemQuality
local GetNumFactions = GetNumFactions
local FauxScrollFrame_GetOffset = FauxScrollFrame_GetOffset
local NUM_FACTIONS_DISPLAYED = NUM_FACTIONS_DISPLAYED
local CHARACTERFRAME_SUBFRAMES = CHARACTERFRAME_SUBFRAMES

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.character ~= true then return end

	-- Character Frame
	E:StripTextures(CharacterFrame, true)

	E:CreateBackdrop(CharacterFrame, "Transparent")
	E:Point(CharacterFrame.backdrop, "TOPLEFT", 11, -12)
	E:Point(CharacterFrame.backdrop, "BOTTOMRIGHT", -32, 76)

	S:HandleCloseButton(CharacterFrameCloseButton)

	for i = 1, getn(CHARACTERFRAME_SUBFRAMES) do
		local tab = _G["CharacterFrameTab"..i]
		S:HandleTab(tab)
	end

	E:StripTextures(PaperDollFrame)

	S:HandleRotateButton(CharacterModelFrameRotateLeftButton)
	E:Point(CharacterModelFrameRotateLeftButton, "TOPLEFT", 3, -3)
	S:HandleRotateButton(CharacterModelFrameRotateRightButton)
	E:Point(CharacterModelFrameRotateRightButton, "TOPLEFT", CharacterModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	E:StripTextures(CharacterAttributesFrame)

	local function HandleResistanceFrame(frameName)
		for i = 1, 5 do
			local frame = _G[frameName..i]
			E:Size(frame, 24)

			local icon, text = _G[frameName..i]:GetRegions()
			E:SetInside(icon)
			icon:SetDrawLayer("ARTWORK")
			text:SetDrawLayer("OVERLAY")

			E:SetTemplate(frame, "Default")

			if i ~= 1 then
				frame:ClearAllPoints()
				E:Point(frame, "TOP", _G[frameName..i - 1], "BOTTOM", 0, -(E.Border + E.Spacing))
			end
		end
	end

	HandleResistanceFrame("MagicResFrame")

	MagicResFrame1:GetRegions():SetTexCoord(0.21875, 0.8125, 0.25, 0.32421875)		--Arcane
	MagicResFrame2:GetRegions():SetTexCoord(0.21875, 0.8125, 0.0234375, 0.09765625)	--Fire
	MagicResFrame3:GetRegions():SetTexCoord(0.21875, 0.8125, 0.13671875, 0.2109375)	--Nature
	MagicResFrame4:GetRegions():SetTexCoord(0.21875, 0.8125, 0.36328125, 0.4375)	--Frost
	MagicResFrame5:GetRegions():SetTexCoord(0.21875, 0.8125, 0.4765625, 0.55078125)	--Shadow

	local slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
		"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
		"MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot"
	}

	for _, slot in pairs(slots) do
		local icon = _G["Character"..slot.."IconTexture"]
		local cooldown = _G["Character"..slot.."Cooldown"]

		slot = _G["Character"..slot]
		E:StripTextures(slot)
		E:StyleButton(slot, false)
		E:SetTemplate(slot, "Default", true, true)

		icon:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(icon)

		slot:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 2)

		if cooldown then
			E:RegisterCooldown(cooldown)
		end
	end

	hooksecurefunc("PaperDollItemSlotButton_Update", function(cooldownOnly)
		if cooldownOnly then return end

		local textureName = GetInventoryItemTexture("player", this:GetID())
		if textureName then
			local rarity = GetInventoryItemQuality("player", this:GetID())
			this:SetBackdropBorderColor(GetItemQualityColor(rarity))
		else
			this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)

	-- PetPaperDollFrame
	E:StripTextures(PetPaperDollFrame)

	S:HandleButton(PetPaperDollCloseButton)

	S:HandleRotateButton(PetModelFrameRotateLeftButton)
	PetModelFrameRotateLeftButton:ClearAllPoints()
	E:Point(PetModelFrameRotateLeftButton, "TOPLEFT", 3, -3)
	S:HandleRotateButton(PetModelFrameRotateRightButton)
	PetModelFrameRotateRightButton:ClearAllPoints()
	E:Point(PetModelFrameRotateRightButton, "TOPLEFT", PetModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	E:StripTextures(PetAttributesFrame)

	E:CreateBackdrop(PetResistanceFrame, "Default")
	E:SetOutside(PetResistanceFrame.backdrop, PetMagicResFrame1, nil, nil, PetMagicResFrame5)

	for i = 1, 5 do
		local frame = _G["PetMagicResFrame"..i]
		E:Size(frame, 24)
	end

	PetMagicResFrame1:GetRegions():SetTexCoord(0.21875, 0.78125, 0.25, 0.3203125)
	PetMagicResFrame2:GetRegions():SetTexCoord(0.21875, 0.78125, 0.0234375, 0.09375)
	PetMagicResFrame3:GetRegions():SetTexCoord(0.21875, 0.78125, 0.13671875, 0.20703125)
	PetMagicResFrame4:GetRegions():SetTexCoord(0.21875, 0.78125, 0.36328125, 0.43359375)
	PetMagicResFrame5:GetRegions():SetTexCoord(0.21875, 0.78125, 0.4765625, 0.546875)

	E:StripTextures(PetPaperDollFrameExpBar)
	PetPaperDollFrameExpBar:SetStatusBarTexture(E["media"].normTex)
	E:RegisterStatusBar(PetPaperDollFrameExpBar)
	E:CreateBackdrop(PetPaperDollFrameExpBar, "Default")

	local function updHappiness()
		local happiness = GetPetHappiness()
		local _, isHunterPet = HasPetUI()
		if not happiness or not isHunterPet then return end

		local texture = this:GetRegions()
		if happiness == 1 then
			texture:SetTexCoord(0.41, 0.53, 0.06, 0.30)
		elseif happiness == 2 then
			texture:SetTexCoord(0.22, 0.345, 0.06, 0.30)
		elseif happiness == 3 then
			texture:SetTexCoord(0.04, 0.15, 0.06, 0.30)
		end
	end

	E:Point(PetPaperDollPetInfo, "TOPLEFT", PetModelFrameRotateLeftButton, "BOTTOMLEFT", 9, -3)
	PetPaperDollPetInfo:GetRegions():SetTexCoord(0.04, 0.15, 0.06, 0.30)
	PetPaperDollPetInfo:SetFrameLevel(PetModelFrame:GetFrameLevel() + 2)
	E:CreateBackdrop(PetPaperDollPetInfo, "Default")
	E:Size(PetPaperDollPetInfo, 24)

	PetPaperDollPetInfo:RegisterEvent("UNIT_HAPPINESS")
	PetPaperDollPetInfo:SetScript("OnEvent", updHappiness)
	PetPaperDollPetInfo:SetScript("OnShow", updHappiness)

	-- Reputation Frame
	E:StripTextures(ReputationFrame)

	for i = 1, NUM_FACTIONS_DISPLAYED do
		local factionBar = _G["ReputationBar"..i]
		local factionHeader = _G["ReputationHeader"..i]
		local factionName = _G["ReputationBar"..i.."FactionName"]
		local factionWar = _G["ReputationBar"..i.."AtWarCheck"]

		E:StripTextures(factionBar)
		E:CreateBackdrop(factionBar, "Default")
		factionBar:SetStatusBarTexture(E.media.normTex)
		E:Size(factionBar, 108, 13)
		E:RegisterStatusBar(factionBar)

		if i == 1 then
			E:Point(factionBar, "TOPLEFT", 190, -86)
		end

		E:Width(factionName, 140)
		factionName:SetPoint("LEFT", factionBar, "LEFT", -150, 0)
		factionName.SetWidth = E.noop

		factionHeader:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		factionHeader.SetNormalTexture = E.noop
		E:Size(factionHeader:GetNormalTexture(), 14)
		factionHeader:SetHighlightTexture(nil)
		factionHeader:SetPoint("TOPLEFT", factionBar, "TOPLEFT", -175, 0)

		E:StripTextures(factionWar)
		E:Point(factionWar, "LEFT", factionBar, "RIGHT", 0, 0)

		factionWar.Icon = factionWar:CreateTexture(nil, "OVERLAY")
		E:Point(factionWar.Icon, "LEFT", 6, -8)
		E:Size(factionWar.Icon, 32)
		factionWar.Icon:SetTexture("Interface\\Buttons\\UI-CheckBox-SwordCheck")
	end

	hooksecurefunc("ReputationFrame_Update", function()
		local numFactions = GetNumFactions()
		local factionIndex, factionHeader
		local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)

		for i = 1, NUM_FACTIONS_DISPLAYED, 1 do
			factionHeader = _G["ReputationHeader"..i]
			factionIndex = factionOffset + i
			if factionIndex <= numFactions then
				if factionHeader.isCollapsed then
					factionHeader:GetNormalTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
				else
					factionHeader:GetNormalTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
				end
			end
		end
	end)

	E:StripTextures(ReputationListScrollFrame)
	S:HandleScrollBar(ReputationListScrollFrameScrollBar)

	E:StripTextures(ReputationDetailFrame)
	E:SetTemplate(ReputationDetailFrame, "Transparent")
	E:Point(ReputationDetailFrame, "TOPLEFT", ReputationFrame, "TOPRIGHT", -31, -12)

	S:HandleCloseButton(ReputationDetailCloseButton)
	E:Point(ReputationDetailCloseButton, "TOPRIGHT", 2, 2)

	S:HandleCheckBox(ReputationDetailAtWarCheckBox)
	S:HandleCheckBox(ReputationDetailInactiveCheckBox)
	S:HandleCheckBox(ReputationDetailMainScreenCheckBox)

	-- Skill Frame
	E:StripTextures(SkillFrame)

	SkillFrameExpandButtonFrame:DisableDrawLayer("BACKGROUND")

	SkillFrameCollapseAllButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
	SkillFrameCollapseAllButton.SetNormalTexture = E.noop
	E:Size(SkillFrameCollapseAllButton:GetNormalTexture(), 15)
	SkillFrameCollapseAllButton:SetPoint("LEFT", SkillFrameExpandTabLeft, "RIGHT", -40, -3)

	SkillFrameCollapseAllButton:SetHighlightTexture(nil)

	hooksecurefunc(SkillFrameCollapseAllButton, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self:GetNormalTexture():SetTexCoord(0.545, 0.975, 0.085, 0.925)
		else
			self:GetNormalTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
		end
	end)

	S:HandleButton(SkillFrameCancelButton)

	for i = 1, SKILLS_TO_DISPLAY do
		local bar = _G["SkillRankFrame"..i]
		local label = _G["SkillTypeLabel"..i]
		local border = _G["SkillRankFrame"..i.."Border"]
		local background = _G["SkillRankFrame"..i.."Background"]

		E:CreateBackdrop(bar, "Default")
		bar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(bar)

		E:StripTextures(border)
		background:SetTexture(nil)

		label:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		label.SetNormalTexture = E.noop
		E:Size(label:GetNormalTexture(), 14)
		label:SetHighlightTexture(nil)

		hooksecurefunc(label, "SetNormalTexture", function(self, texture)
			if find(texture, "MinusButton") then
				self:GetNormalTexture():SetTexCoord(0.545, 0.975, 0.085, 0.925)
			else
				self:GetNormalTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
			end
		end)
	end

	E:StripTextures(SkillListScrollFrame)
	S:HandleScrollBar(SkillListScrollFrameScrollBar)

	E:StripTextures(SkillDetailScrollFrame)
	S:HandleScrollBar(SkillDetailScrollFrameScrollBar)

	E:StripTextures(SkillDetailStatusBar)
	SkillDetailStatusBar:SetParent(SkillDetailScrollFrame)
	E:CreateBackdrop(SkillDetailStatusBar, "Default")
	SkillDetailStatusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(SkillDetailStatusBar)

	S:HandleNextPrevButton(SkillDetailStatusBarUnlearnButton)
	S:SquareButton_SetIcon(SkillDetailStatusBarUnlearnButton, "DELETE")
	E:Size(SkillDetailStatusBarUnlearnButton, 24)
	SkillDetailStatusBarUnlearnButton:SetPoint("LEFT", SkillDetailStatusBarBorder, "RIGHT", 5, 0)
	SkillDetailStatusBarUnlearnButton:SetHitRectInsets(0, 0, 0, 0)

	-- Honor Frame
	hooksecurefunc("HonorFrame_Update", function()
		E:StripTextures(HonorFrame)

		HonorFrameProgressBar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(HonorFrameProgressBar)
	end)
end

S:AddCallback("Character", LoadSkin)