local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local find, match = string.find, string.match
--WoW API / Variables
local CreateFrame = CreateFrame
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetTradeSkillItemLink = GetTradeSkillItemLink
local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo
local GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.tradeskill ~= true then return end

	TRADE_SKILLS_DISPLAYED = 25

	UIPanelWindows["TradeSkillFrame"] = {area = "doublewide", pushable = 0, whileDead = 1}

	E:StripTextures(TradeSkillFrame, true)
	E:CreateBackdrop(TradeSkillFrame, "Transparent")
	TradeSkillFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	TradeSkillFrame.backdrop:SetPoint("BOTTOMRIGHT", -34, 0)
	E:Size(TradeSkillFrame, 720, 508)

	TradeSkillFrame.bg1 = CreateFrame("Frame", nil, TradeSkillFrame)
	E:SetTemplate(TradeSkillFrame.bg1, "Transparent")
	TradeSkillFrame.bg1:SetPoint("TOPLEFT", 14, -92)
	TradeSkillFrame.bg1:SetPoint("BOTTOMRIGHT", -367, 4)
	TradeSkillFrame.bg1:SetFrameLevel(TradeSkillFrame.bg1:GetFrameLevel() - 1)

	TradeSkillFrame.bg2 = CreateFrame("Frame", nil, TradeSkillFrame)
	E:SetTemplate(TradeSkillFrame.bg2, "Transparent")
	TradeSkillFrame.bg2:SetPoint("TOPLEFT", TradeSkillFrame.bg1, "TOPRIGHT", 3, 0)
	TradeSkillFrame.bg2:SetPoint("BOTTOMRIGHT", TradeSkillFrame, "BOTTOMRIGHT", -38, 4)
	TradeSkillFrame.bg2:SetFrameLevel(TradeSkillFrame.bg2:GetFrameLevel() - 1)

	E:StripTextures(TradeSkillRankFrameBorder)

	E:StripTextures(TradeSkillRankFrame)
	E:CreateBackdrop(TradeSkillRankFrame)
	E:Size(TradeSkillRankFrame, 420, 18)
	TradeSkillRankFrame:ClearAllPoints()
	TradeSkillRankFrame:SetPoint("TOP", -10, -38)
	TradeSkillRankFrame:SetStatusBarTexture(E["media"].normTex)
	E:RegisterStatusBar(TradeSkillRankFrame)

	TradeSkillRankFrameSkillName:Hide()
	TradeSkillRankFrameSkillRank:ClearAllPoints()
	TradeSkillRankFrameSkillRank:SetParent(TradeSkillRankFrame)
	TradeSkillRankFrameSkillRank:SetPoint("CENTER", TradeSkillRankFrame, "CENTER", 58, 0)

	E:StripTextures(TradeSkillListScrollFrame)
	E:Size(TradeSkillListScrollFrame, 310, 405)
	TradeSkillListScrollFrame:ClearAllPoints()
	TradeSkillListScrollFrame:SetPoint("TOPLEFT", 17, -95)

	E:StripTextures(TradeSkillDetailScrollFrame)
	E:Size(TradeSkillDetailScrollFrame, 300, 381)
	TradeSkillDetailScrollFrame:ClearAllPoints()
	TradeSkillDetailScrollFrame:SetPoint("TOPRIGHT", TradeSkillFrame, -60, -95)
	TradeSkillDetailScrollFrame.scrollBarHideable = nil

	E:StripTextures(TradeSkillDetailScrollChildFrame)
	E:Size(TradeSkillDetailScrollChildFrame, 300, 150)

	S:HandleScrollBar(TradeSkillListScrollFrameScrollBar)
	S:HandleScrollBar(TradeSkillDetailScrollFrameScrollBar)
	TradeSkillDetailScrollFrameScrollBar:SetPoint("TOPLEFT", TradeSkillDetailScrollFrame, "TOPRIGHT", 3, -16)

	S:HandleDropDownBox(TradeSkillInvSlotDropDown, 160)
	TradeSkillInvSlotDropDown:ClearAllPoints()
	TradeSkillInvSlotDropDown:SetPoint("RIGHT", TradeSkillRankFrame, "RIGHT", 9, -30)

	S:HandleDropDownBox(TradeSkillSubClassDropDown, 160)
	TradeSkillSubClassDropDown:SetPoint("RIGHT", TradeSkillInvSlotDropDown, "LEFT", 10, 0)

	TradeSkillCancelButton:ClearAllPoints()
	TradeSkillCancelButton:SetPoint("TOPRIGHT", TradeSkillDetailScrollFrame, "BOTTOMRIGHT", 19, -3)
	S:HandleButton(TradeSkillCancelButton)

	TradeSkillCreateButton:ClearAllPoints()
	TradeSkillCreateButton:SetPoint("TOPRIGHT", TradeSkillCancelButton, "TOPLEFT", -3, 0)
	S:HandleButton(TradeSkillCreateButton)

	TradeSkillCreateAllButton:ClearAllPoints()
	TradeSkillCreateAllButton:SetPoint("TOPLEFT", TradeSkillDetailScrollFrame, "BOTTOMLEFT", 0, -3)
	S:HandleButton(TradeSkillCreateAllButton)

	S:HandleNextPrevButton(TradeSkillDecrementButton)

	S:HandleEditBox(TradeSkillInputBox)
	E:Size(TradeSkillInputBox, 40, 16)
	TradeSkillInputBox:SetPoint("LEFT", TradeSkillDecrementButton, "RIGHT", 6, 0)

	S:HandleNextPrevButton(TradeSkillIncrementButton)

	E:StripTextures(TradeSkillSkillIcon)
	E:SetTemplate(TradeSkillSkillIcon, "Default")
	E:StyleButton(TradeSkillSkillIcon, nil, true)
	E:Size(TradeSkillSkillIcon, 47)
	TradeSkillSkillIcon:SetPoint("TOPLEFT", 1, -3)

	TradeSkillSkillName:SetPoint("TOPLEFT", 55, -3)

	TradeSkillRequirementLabel:SetTextColor(1, 0.80, 0.10)

	S:HandleCloseButton(TradeSkillFrameCloseButton)

	E:StripTextures(TradeSkillExpandButtonFrame)

	TradeSkillCollapseAllButton:SetPoint("LEFT", TradeSkillExpandTabLeft, "RIGHT", -8, 5)
	TradeSkillCollapseAllButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
	TradeSkillCollapseAllButton.SetNormalTexture = E.noop
	TradeSkillCollapseAllButton:GetNormalTexture():SetPoint("LEFT", 3, 2)
	E:Size(TradeSkillCollapseAllButton:GetNormalTexture(), 15)

	TradeSkillCollapseAllButton:SetHighlightTexture("")
	TradeSkillCollapseAllButton.SetHighlightTexture = E.noop

	TradeSkillCollapseAllButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
	TradeSkillCollapseAllButton.SetDisabledTexture = E.noop
	TradeSkillCollapseAllButton:GetDisabledTexture():SetPoint("LEFT", 3, 2)
	E:Size(TradeSkillCollapseAllButton:GetDisabledTexture(), 15)
	TradeSkillCollapseAllButton:GetDisabledTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
	TradeSkillCollapseAllButton:GetDisabledTexture():SetDesaturated(true)

	hooksecurefunc(TradeSkillCollapseAllButton, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self:GetNormalTexture():SetTexCoord(0.545, 0.975, 0.085, 0.925)
		else
			self:GetNormalTexture():SetTexCoord(0.045, 0.475, 0.085, 0.925)
		end
	end)

	for i = 9, 25 do
		CreateFrame("Button", "TradeSkillSkill"..i, TradeSkillFrame, "TradeSkillSkillButtonTemplate"):SetPoint("TOPLEFT", _G["TradeSkillSkill"..i - 1], "BOTTOMLEFT")
	end

	for i = 1, TRADE_SKILLS_DISPLAYED do
		local button = _G["TradeSkillSkill"..i]
		local highlight = _G["TradeSkillSkill"..i.."Highlight"]

		button:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		button.SetNormalTexture = E.noop
		E:Size(button:GetNormalTexture(), 14)
		button:GetNormalTexture():SetPoint("LEFT", 2, 1)

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

	for i = 1, MAX_TRADE_SKILL_REAGENTS do
		local reagent = _G["TradeSkillReagent"..i]
		local icon = _G["TradeSkillReagent"..i.."IconTexture"]
		local count = _G["TradeSkillReagent"..i.."Count"]
		local name = _G["TradeSkillReagent"..i.."Name"]
		local nameFrame = _G["TradeSkillReagent"..i.."NameFrame"]

		E:SetTemplate(reagent, "Default")
		E:StyleButton(reagent, nil, true)
		E:Size(reagent, 143, 40)

		icon.backdrop = CreateFrame("Frame", nil, reagent)
		E:SetTemplate(icon.backdrop, "Default")
		icon.backdrop:SetPoint("TOPLEFT", icon, -1, 1)
		icon.backdrop:SetPoint("BOTTOMRIGHT", icon, 1, -1)

		icon:SetTexCoord(unpack(E.TexCoords))
		icon:SetDrawLayer("OVERLAY")
		E:Size(icon, E.PixelMode and 38 or 32)
		icon:SetPoint("TOPLEFT", E.PixelMode and 1 or 4, -(E.PixelMode and 1 or 4))
		icon:SetParent(icon.backdrop)

		count:SetParent(icon.backdrop)
		count:SetDrawLayer("OVERLAY")

		name:SetPoint("LEFT", nameFrame, "LEFT", 20, 0)

		E:Kill(nameFrame)
	end

	TradeSkillReagentLabel:ClearAllPoints()
	TradeSkillReagentLabel:SetPoint("TOPLEFT", TradeSkillSkillIcon, "BOTTOMLEFT", 5, -10)

	TradeSkillReagent1:SetPoint("TOPLEFT", TradeSkillReagentLabel, "BOTTOMLEFT", -3, -3)
	TradeSkillReagent2:SetPoint("LEFT", TradeSkillReagent1, "RIGHT", 3, 0)
	TradeSkillReagent4:SetPoint("LEFT", TradeSkillReagent3, "RIGHT", 3, 0)
	TradeSkillReagent6:SetPoint("LEFT", TradeSkillReagent5, "RIGHT", 3, 0)
	TradeSkillReagent8:SetPoint("LEFT", TradeSkillReagent7, "RIGHT", 3, 0)

	hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
		TradeSkillRankFrame:SetStatusBarColor(0.13, 0.28, 0.85)

		if TradeSkillSkillIcon:GetNormalTexture() then
			TradeSkillReagentLabel:SetAlpha(1)
			TradeSkillSkillIcon:SetAlpha(1)
			TradeSkillSkillIcon:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			E:SetInside(TradeSkillSkillIcon:GetNormalTexture())
		else
			TradeSkillReagentLabel:SetAlpha(0)
			TradeSkillSkillIcon:SetAlpha(0)
		end

		local skillLink = GetTradeSkillItemLink(id)
		if skillLink then
			local _, _, quality = GetItemInfo(match(skillLink, "item:(%d+)"))
			if quality then
				TradeSkillSkillIcon:SetBackdropBorderColor(GetItemQualityColor(quality))
				TradeSkillSkillName:SetTextColor(GetItemQualityColor(quality))
			else
				TradeSkillSkillIcon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				TradeSkillSkillName:SetTextColor(1, 1, 1)
			end
		end

		local numReagents = GetTradeSkillNumReagents(id)
		for i = 1, numReagents, 1 do
			local _, _, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i)
			local reagentLink = GetTradeSkillReagentItemLink(id, i)
			local reagent = _G["TradeSkillReagent"..i]
			local icon = _G["TradeSkillReagent"..i.."IconTexture"]
			local name = _G["TradeSkillReagent"..i.."Name"]

			if reagentLink then
				local _, _, quality = GetItemInfo(match(reagentLink, "item:(%d+)"))
				if quality then
					icon.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
					reagent:SetBackdropBorderColor(GetItemQualityColor(quality))
					if playerReagentCount < reagentCount then
						name:SetTextColor(0.5, 0.5, 0.5)
					else
						name:SetTextColor(GetItemQualityColor(quality))
					end
				else
					reagent:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					icon.backdrop:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end
		end
	end)
end

S:AddCallbackForAddon("Blizzard_TradeSkillUI", "TradeSkill", LoadSkin)