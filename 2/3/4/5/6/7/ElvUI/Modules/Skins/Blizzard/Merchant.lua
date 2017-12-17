local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local select = select
local unpack = unpack
local match, split = string.match, string.split
--WoW API / Variables
local GetBuybackItemInfo = GetBuybackItemInfo
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetMerchantItemLink = GetMerchantItemLink
local GetItemLinkByName = GetItemLinkByName
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.merchant ~= true then return end

	E:StripTextures(MerchantFrame, true)
	E:CreateBackdrop(MerchantFrame, "Transparent")
	MerchantFrame.backdrop:SetPoint("TOPLEFT", 10, -11)
	MerchantFrame.backdrop:SetPoint("BOTTOMRIGHT", -28, 60)

	S:HandleCloseButton(MerchantFrameCloseButton, MerchantFrame.backdrop)

	for i = 1, 12 do
		local item = _G["MerchantItem"..i]
		local itemButton = _G["MerchantItem"..i.."ItemButton"]
		local iconTexture = _G["MerchantItem"..i.."ItemButtonIconTexture"]
		local altCurrencyTex1 = _G["MerchantItem"..i.."AltCurrencyFrameItem1Texture"]
		local altCurrencyTex2 = _G["MerchantItem"..i.."AltCurrencyFrameItem2Texture"]

		E:StripTextures(item, true)
		E:CreateBackdrop(item, "Default")

		E:StripTextures(itemButton)
		E:StyleButton(itemButton)
		E:SetTemplate(itemButton, "Default", true)
		itemButton:SetPoint("TOPLEFT", item, "TOPLEFT", 4, -4)

		iconTexture:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(iconTexture)

		_G["MerchantItem"..i.."MoneyFrame"]:ClearAllPoints()
		_G["MerchantItem"..i.."MoneyFrame"]:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 3, 0)
	end

	S:HandleNextPrevButton(MerchantNextPageButton)
	S:HandleNextPrevButton(MerchantPrevPageButton)

	E:StyleButton(MerchantRepairItemButton)
	E:SetTemplate(MerchantRepairItemButton, "Default", true)
	for i = 1, MerchantRepairItemButton:GetNumRegions() do
		local region = select(i, MerchantRepairItemButton:GetRegions())
		if region:GetObjectType() == "Texture" then
			region:SetTexCoord(0.04, 0.24, 0.06, 0.5)
			E:SetInside(region)
		end
	end

	E:StyleButton(MerchantRepairAllButton)
	E:SetTemplate(MerchantRepairAllButton, "Default", true)
	MerchantRepairAllIcon:SetTexCoord(0.34, 0.1, 0.34, 0.535, 0.535, 0.1, 0.535, 0.535)
	E:SetInside(MerchantRepairAllIcon)

	E:StripTextures(MerchantBuyBackItem, true)
	E:CreateBackdrop(MerchantBuyBackItem, "Transparent")
	MerchantBuyBackItem.backdrop:SetPoint("TOPLEFT", -6, 6)
	MerchantBuyBackItem.backdrop:SetPoint("BOTTOMRIGHT", 6, -6)

	E:StripTextures(MerchantBuyBackItemItemButton)
	E:StyleButton(MerchantBuyBackItemItemButton)
	E:SetTemplate(MerchantBuyBackItemItemButton, "Default", true)
	MerchantBuyBackItemItemButtonIconTexture:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(MerchantBuyBackItemItemButtonIconTexture)

	for i = 1, 2 do
		S:HandleTab(_G["MerchantFrameTab"..i])
	end

	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
		local numMerchantItems = GetMerchantNumItems()
		for i = 1, MERCHANT_ITEMS_PER_PAGE do
			local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)
			local itemButton = _G["MerchantItem"..i.."ItemButton"]
			local itemName = _G["MerchantItem"..i.."Name"]

			if index <= numMerchantItems then
				local itemLink = GetMerchantItemLink(index)
				if itemLink then
					local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
					if quality then
						itemName:SetTextColor(GetItemQualityColor(quality))
						itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
					else
						itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					end
				else
					itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end

			local buybackName = GetBuybackItemInfo(GetNumBuybackItems())
			if buybackName then
				local itemLink = GetItemLinkByName(buybackName)
				if itemLink then
					local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
					if quality then
						MerchantBuyBackItemName:SetTextColor(GetItemQualityColor(quality))
						MerchantBuyBackItemItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
					else
						MerchantBuyBackItemItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					end
				else
					MerchantBuyBackItemItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end
		end
	end)

	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
		local numBuybackItems = GetNumBuybackItems()
		for i = 1, BUYBACK_ITEMS_PER_PAGE do
			local itemButton = _G["MerchantItem"..i.."ItemButton"]
			local itemName = _G["MerchantItem"..i.."Name"]

			if i <= numBuybackItems then
				local buybackName = GetBuybackItemInfo(i)
				if buybackName then
					local itemLink = GetItemLinkByName(buybackName)
					if itemLink then
						local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
						if quality then
							itemName:SetTextColor(GetItemQualityColor(quality))
							itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
						else
							itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
						end
					else
						itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					end
				end
			end
		end
	end)
end

S:AddCallback("Merchant", LoadSkin)