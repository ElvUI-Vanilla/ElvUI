local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local find, match, split = string.find, string.match, string.split
--WoW API / Variables
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetCraftReagentInfo = GetCraftReagentInfo
local GetCraftItemLink = GetCraftItemLink
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or not E.private.skins.blizzard.craft ~= true then return end

	E:StripTextures(CraftFrame, true)
	E:CreateBackdrop(CraftFrame, "Transparent")
	E:Point(CraftFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(CraftFrame.backdrop, "BOTTOMRIGHT", -32, 74)

	E:StripTextures(CraftRankFrameBorder)
	E:Size(CraftRankFrame, 322, 16)
	CraftRankFrame:ClearAllPoints()
	E:Point(CraftRankFrame, "TOP", -10, -45)
	E:CreateBackdrop(CraftRankFrame)
	CraftRankFrame:SetStatusBarTexture(E["media"].normTex)
	CraftRankFrame:SetStatusBarColor(0.13, 0.35, 0.80)
	E:RegisterStatusBar(CraftRankFrame)

	E:StripTextures(CraftExpandButtonFrame)
	E:StripTextures(CraftDetailScrollChildFrame)

	E:StripTextures(CraftListScrollFrame)
	S:HandleScrollBar(CraftListScrollFrameScrollBar)

	E:StripTextures(CraftDetailScrollFrame)
	S:HandleScrollBar(CraftDetailScrollFrameScrollBar)

	E:StripTextures(CraftIcon)

	S:HandleButton(CraftCreateButton)
	S:HandleButton(CraftCancelButton)

	S:HandleCloseButton(CraftFrameCloseButton)

	for i = 1, MAX_CRAFT_REAGENTS do
		local reagent = _G["CraftReagent"..i]
		local icon = _G["CraftReagent"..i.."IconTexture"]
		local count = _G["CraftReagent"..i.."Count"]
		local nameFrame = _G["CraftReagent"..i.."NameFrame"]

		icon:SetTexCoord(unpack(E.TexCoords))
		icon:SetDrawLayer("OVERLAY")

		icon.backdrop = CreateFrame("Frame", nil, reagent)
		icon.backdrop:SetFrameLevel(reagent:GetFrameLevel() - 1)
		E:SetTemplate(icon.backdrop, "Default")
		E:SetOutside(icon.backdrop, icon)

		icon:SetParent(icon.backdrop)
		count:SetParent(icon.backdrop)
		count:SetDrawLayer("OVERLAY")

		E:Kill(nameFrame)
	end

	hooksecurefunc("CraftFrame_SetSelection", function(id)
		E:SetTemplate(CraftIcon, "Default", true)
		E:StyleButton(CraftIcon, nil, true)
		if CraftIcon:GetNormalTexture() then
			CraftIcon:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			E:SetInside(CraftIcon:GetNormalTexture())
		end

		CraftIcon:SetWidth(40)
		CraftIcon:SetHeight(40)
		CraftIcon:SetPoint("TOPLEFT", 4, -3)

		CraftRequirements:SetTextColor(1, 0.80, 0.10)

		local skillLink = GetCraftItemLink(id)
		if skillLink then
			local _, _, quality = GetItemInfo(match(skillLink, "enchant:(%d+)"))
			if quality then
				CraftIcon:SetBackdropBorderColor(GetItemQualityColor(quality))
				CraftName:SetTextColor(GetItemQualityColor(quality))
			else
				CraftIcon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				CraftName:SetTextColor(1, 1, 1)
			end
		end

		local numReagents = GetCraftNumReagents(id)
		for i = 1, numReagents, 1 do
			local icon = _G["CraftReagent"..i.."IconTexture"]
			local name = _G["CraftReagent"..i.."Name"]

			local _, _, reagentCount, playerReagentCount = GetCraftReagentInfo(id, i)
			local reagentLink = GetCraftReagentItemLink(id, i)
			if reagentLink then
				local _, _, quality = GetItemInfo(match(reagentLink, "item:(%d+)"))
				if quality then
					icon.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
					if playerReagentCount < reagentCount then
						name:SetTextColor(0.5, 0.5, 0.5)
					else
						name:SetTextColor(GetItemQualityColor(quality))
					end
				else
					icon.backdrop:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end
		end
	end)

	for i = 1, CRAFTS_DISPLAYED do
		local craftButton = _G["Craft"..i]
		craftButton:SetNormalTexture("")
		craftButton.SetNormalTexture = E.noop

		_G["Craft"..i.."Highlight"]:SetTexture("")
		_G["Craft"..i.."Highlight"].SetTexture = E.noop

		craftButton.Text = craftButton:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(craftButton.Text, nil, 22)
		craftButton.Text:SetPoint("LEFT", 3, 0)
		craftButton.Text:SetText("+")

		hooksecurefunc(craftButton, "SetNormalTexture", function(self, texture)
			if find(texture, "MinusButton") then
				self.Text:SetText("-")
			elseif find(texture, "PlusButton") then
				self.Text:SetText("+")
			else
				self.Text:SetText("")
			end
		end)
	end

	CraftCollapseAllButton:SetNormalTexture("")
	CraftCollapseAllButton.SetNormalTexture = E.noop
	CraftCollapseAllButton:SetHighlightTexture("")
	CraftCollapseAllButton.SetHighlightTexture = E.noop
	CraftCollapseAllButton:SetDisabledTexture("")
	CraftCollapseAllButton.SetDisabledTexture = E.noop

	CraftCollapseAllButton.Text = CraftCollapseAllButton:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(CraftCollapseAllButton.Text, nil, 22)
	CraftCollapseAllButton.Text:SetPoint("LEFT", 3, 0)
	CraftCollapseAllButton.Text:SetText("+")

	hooksecurefunc(CraftCollapseAllButton, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self.Text:SetText("-")
		else
			self.Text:SetText("+")
		end
	end)
end

S:AddCallbackForAddon("Blizzard_CraftUI", "Craft", LoadSkin)