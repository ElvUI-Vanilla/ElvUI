local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local pairs = pairs
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.auctionhouse ~= true then return end

	E:StripTextures(AuctionFrame, true)
	E:CreateBackdrop(AuctionFrame, "Transparent")
	E:Point(AuctionFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(AuctionFrame.backdrop, "BOTTOMRIGHT", 0, 4)

	E:StripTextures(BrowseFilterScrollFrame)
	E:StripTextures(BrowseScrollFrame)
	E:StripTextures(AuctionsScrollFrame)
	E:StripTextures(BidScrollFrame)

	S:HandleDropDownBox(BrowseDropDown)

	S:HandleScrollBar(BrowseFilterScrollFrameScrollBar)
	S:HandleScrollBar(BrowseScrollFrameScrollBar)
	S:HandleScrollBar(AuctionsScrollFrameScrollBar)

	S:HandleCloseButton(AuctionFrameCloseButton)

	-- DressUpFrame
	E:StripTextures(AuctionDressUpFrame)
	E:CreateBackdrop(AuctionDressUpFrame, "Default")

	SetAuctionDressUpBackground()
	AuctionDressUpBackgroundTop:SetDesaturated(true)
	AuctionDressUpBackgroundBot:SetDesaturated(true)

	E:SetOutside(AuctionDressUpFrame.backdrop, AuctionDressUpBackgroundTop, nil, nil, AuctionDressUpBackgroundBot)

	S:HandleRotateButton(AuctionDressUpModelRotateLeftButton)
	E:Point(AuctionDressUpModelRotateLeftButton, "TOPLEFT", AuctionDressUpFrame, 8, -17)
	S:HandleRotateButton(AuctionDressUpModelRotateRightButton)
	E:Point(AuctionDressUpModelRotateRightButton, "TOPLEFT", AuctionDressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(AuctionDressUpFrameResetButton)
	S:HandleCloseButton(AuctionDressUpFrameCloseButton, AuctionDressUpFrame.backdrop)

	local buttons = {
		"BrowseBidButton",
		"BidBidButton",
		"BrowseBuyoutButton",
		"BidBuyoutButton",
		"BrowseCloseButton",
		"BidCloseButton",
		"BrowseSearchButton",
		"AuctionsCloseButton",
		"AuctionsCancelAuctionButton",
		"AuctionsCreateAuctionButton",
	}

	for _, button in pairs(buttons) do
		S:HandleButton(_G[button])
	end

	--Fix Button Positions
	E:Point(AuctionsCloseButton, "BOTTOMRIGHT", AuctionFrameAuctions, "BOTTOMRIGHT", 66, 14)
	E:Point(AuctionsCancelAuctionButton, "RIGHT", AuctionsCloseButton, "LEFT", -4, 0)
	E:Point(BidBuyoutButton, "RIGHT", BidCloseButton, "LEFT", -4, 0)
	E:Point(BidBidButton, "RIGHT", BidBuyoutButton, "LEFT", -4, 0)
	E:Point(BrowseBuyoutButton, "RIGHT", BrowseCloseButton, "LEFT", -4, 0)
	E:Point(BrowseBidButton, "RIGHT", BrowseBuyoutButton, "LEFT", -4, 0)
	E:Point(AuctionsCreateAuctionButton, "BOTTOMLEFT", 18, 44)

	BrowseSearchButton:ClearAllPoints()
	E:Point(BrowseSearchButton, "TOPRIGHT", AuctionFrameBrowse, "TOPRIGHT", 25, -30)

	S:HandleNextPrevButton(BrowseNextPageButton)
	BrowseNextPageButton:ClearAllPoints()
	E:Point(BrowseNextPageButton, "BOTTOMLEFT", BrowseSearchButton, "BOTTOMRIGHT", 10, -27)

	S:HandleNextPrevButton(BrowsePrevPageButton)
	BrowsePrevPageButton:ClearAllPoints()
	E:Point(BrowsePrevPageButton, "BOTTOMRIGHT", BrowseSearchButton, "BOTTOMLEFT", -10, -27)

	E:StripTextures(AuctionsItemButton)
	E:SetTemplate(AuctionsItemButton, "Default", true)
	E:StyleButton(AuctionsItemButton, false, true)

	HookScript(AuctionsItemButton, "OnEvent", function()
		this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		if event == "NEW_AUCTION_UPDATE" and this:GetNormalTexture() then
			this:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			E:SetInside(this:GetNormalTexture())
		end

		local itemName = GetAuctionSellItemInfo()
		if itemName then
			local _, itemString = GetItemInfoByName(itemName)
			local _, _, quality = GetItemInfo(itemString, "item:(%d+)")
			if quality then
				AuctionsItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
				AuctionsItemButtonName:SetTextColor(GetItemQualityColor(quality))
			else
				AuctionsItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
		end
	end)

	local sorttabs = {
		"BrowseQualitySort",
		"BrowseLevelSort",
		"BrowseDurationSort",
		"BrowseHighBidderSort",
		"BrowseCurrentBidSort",
		"BidQualitySort",
		"BidLevelSort",
		"BidDurationSort",
		"BidBuyoutSort",
		"BidStatusSort",
		"BidBidSort",
		"AuctionsQualitySort",
		"AuctionsDurationSort",
		"AuctionsHighBidderSort",
		"AuctionsBidSort",
	}

	for _, sorttab in pairs(sorttabs) do
		E:Kill(_G[sorttab.."Left"])
		E:Kill(_G[sorttab.."Middle"])
		E:Kill(_G[sorttab.."Right"])
		E:StyleButton(_G[sorttab])
	end

	for i = 1, 3 do
		S:HandleTab(_G["AuctionFrameTab"..i])
	end

	AuctionFrameTab1:ClearAllPoints()
	E:Point(AuctionFrameTab1, "BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 25, -26)
	AuctionFrameTab1.SetPoint = E.noop

	for i = 1, NUM_FILTERS_TO_DISPLAY do
		local tab = _G["AuctionFilterButton"..i]

		E:StripTextures(tab)
		E:StyleButton(tab)
	end

	local editboxs = {
		"BrowseName",
		"BrowseMinLevel",
		"BrowseMaxLevel",
		"BrowseBidPriceGold",
		"BrowseBidPriceSilver",
		"BrowseBidPriceCopper",
		"BidBidPriceGold",
		"BidBidPriceSilver",
		"BidBidPriceCopper",
		"StartPriceGold",
		"StartPriceSilver",
		"StartPriceCopper",
		"BuyoutPriceGold",
		"BuyoutPriceSilver",
		"BuyoutPriceCopper"
	}

	for _, editbox in pairs(editboxs) do
		S:HandleEditBox(_G[editbox])
		_G[editbox]:SetTextInsets(1, 1, -1, 1)
	end

	E:Point(BrowseBidPrice, "BOTTOM", -15, 18)
	E:Point(BrowseBidText, "BOTTOMRIGHT", AuctionFrameBrowse, "BOTTOM", -116, 21)

	E:Width(BrowseMinLevel, 32)

	E:Point(BrowseLevelHyphen, "LEFT", BrowseMinLevel, "RIGHT", -7, 1)

	E:Point(BrowseMaxLevel, "LEFT", BrowseMinLevel, "RIGHT", 8, 0)
	E:Width(BrowseMaxLevel, 32)
	E:Point(BrowseLevelText, "BOTTOMLEFT", AuctionFrameBrowse, "TOPLEFT", 195, -48)

	E:Width(BrowseName, 164)
	E:Point(BrowseName, "TOPLEFT", AuctionFrameBrowse, "TOPLEFT", 20, -54)
	E:Point(BrowseNameText, "TOPLEFT", BrowseName, "TOPLEFT", 0, 16)

	S:HandleCheckBox(IsUsableCheckButton)
	IsUsableCheckButton:ClearAllPoints()
	E:Point(IsUsableCheckButton, "RIGHT", BrowseIsUsableText, "LEFT", 2, 0)
	E:Point(BrowseIsUsableText, "TOPLEFT", 440, -40)

	S:HandleCheckBox(ShowOnPlayerCheckButton)
	ShowOnPlayerCheckButton:ClearAllPoints()
	E:Point(ShowOnPlayerCheckButton, "RIGHT", BrowseShowOnCharacterText, "LEFT", 2, 0)

	E:Point(BrowseShowOnCharacterText, "TOPLEFT", 440, -60)

	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local button = _G["BrowseButton"..i]
		local icon = _G["BrowseButton"..i.."Item"]
		local name = _G["BrowseButton"..i.."Name"]
		local texture = _G["BrowseButton"..i.."ItemIconTexture"]

		if texture then
			texture:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(texture)
		end

		if icon then
			E:StyleButton(icon)
			icon:GetNormalTexture():SetTexture("")
			E:SetTemplate(icon, "Default")

			hooksecurefunc(name, "SetVertexColor", function(_, r, g, b)
				if r and g and b then
					icon:SetBackdropBorderColor(r, g, b)
				end
			end)
			hooksecurefunc(name, "Hide", function(_, r, g, b)
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end)
		end

		E:StripTextures(button)
		E:StyleButton(button, false, true)
		_G["BrowseButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		E:Point(button:GetHighlightTexture(), "TOPLEFT", icon, "TOPRIGHT", 2, 0)
		E:Point(button:GetHighlightTexture(), "BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		-- button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local button = _G["AuctionsButton"..i]
		local icon = _G["AuctionsButton"..i.."Item"]
		local name = _G["AuctionsButton"..i.."Name"]
		local texture = _G["AuctionsButton"..i.."ItemIconTexture"]

		if texture then
			texture:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(texture)
		end

		if icon then
			E:StyleButton(icon)
			icon:GetNormalTexture():SetTexture("")
			E:SetTemplate(icon, "Default")

			hooksecurefunc(name, "SetVertexColor", function(_, r, g, b)
				if r and g and b then
					icon:SetBackdropBorderColor(r, g, b)
				end
			end)
			hooksecurefunc(name, "Hide", function(_, r, g, b)
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end)
		end

		E:StripTextures(button)
		E:StyleButton(button, false, true)
		_G["AuctionsButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		E:Point(button:GetHighlightTexture(), "TOPLEFT", icon, "TOPRIGHT", 2, 0)
		E:Point(button:GetHighlightTexture(), "BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		-- button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	for i = 1, NUM_BIDS_TO_DISPLAY do
		local button = _G["BidButton"..i]
		local icon = _G["BidButton"..i.."Item"]
		local name = _G["BidButton"..i.."Name"]
		local texture = _G["BidButton"..i.."ItemIconTexture"]

		if texture then
			texture:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(texture)
		end

		if icon then
			E:StyleButton(icon)
			icon:GetNormalTexture():SetTexture("")
			E:SetTemplate(icon, "Default")

			hooksecurefunc(name, "SetVertexColor", function(_, r, g, b)
				if r and g and b then
					icon:SetBackdropBorderColor(r, g, b)
				end
			end)
			hooksecurefunc(name, "Hide", function(_, r, g, b)
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end)
		end

		E:StripTextures(button)
		E:StyleButton(button, false, true)
		_G["BidButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		E:Point(button:GetHighlightTexture(), "TOPLEFT", icon, "TOPRIGHT", 2, 0)
		E:Point(button:GetHighlightTexture(), "BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		-- button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	--Custom Backdrops
	AuctionFrameBrowse.bg1 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	E:SetTemplate(AuctionFrameBrowse.bg1, "Default")
	E:Point(AuctionFrameBrowse.bg1, "TOPLEFT", 20, -103)
	E:Point(AuctionFrameBrowse.bg1, "BOTTOMRIGHT", -575, 40)
	BrowseNoResultsText:SetParent(AuctionFrameBrowse.bg1)
	BrowseSearchCountText:SetParent(AuctionFrameBrowse.bg1)
	AuctionFrameBrowse.bg1:SetFrameLevel(AuctionFrameBrowse.bg1:GetFrameLevel() - 1)

	AuctionFrameBrowse.bg2 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	E:SetTemplate(AuctionFrameBrowse.bg2, "Default")
	E:Point(AuctionFrameBrowse.bg2, "TOPLEFT", AuctionFrameBrowse.bg1, "TOPRIGHT", 4, 0)
	E:Point(AuctionFrameBrowse.bg2, "BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -8, 40)
	AuctionFrameBrowse.bg2:SetFrameLevel(AuctionFrameBrowse.bg2:GetFrameLevel() - 1)

	AuctionFrameBid.bg = CreateFrame("Frame", nil, AuctionFrameBid)
	E:SetTemplate(AuctionFrameBid.bg, "Default")
	E:Point(AuctionFrameBid.bg, "TOPLEFT", 20, -72)
	E:Point(AuctionFrameBid.bg, "BOTTOMRIGHT", 66, 40)
	AuctionFrameBid.bg:SetFrameLevel(AuctionFrameBid.bg:GetFrameLevel() - 1)

	AuctionFrameAuctions.bg1 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	E:SetTemplate(AuctionFrameAuctions.bg1, "Default")
	E:Point(AuctionFrameAuctions.bg1, "TOPLEFT", 15, -72)
	E:Point(AuctionFrameAuctions.bg1, "BOTTOMRIGHT", -545, 40)
	AuctionFrameAuctions.bg1:SetFrameLevel(AuctionFrameAuctions.bg1:GetFrameLevel() - 1)

	AuctionFrameAuctions.bg2 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	E:SetTemplate(AuctionFrameAuctions.bg2, "Default")
	E:Point(AuctionFrameAuctions.bg2, "TOPLEFT", AuctionFrameAuctions.bg1, "TOPRIGHT", 3, 0)
	E:Point(AuctionFrameAuctions.bg2, "BOTTOMRIGHT", AuctionFrame, -8, 40)
	AuctionFrameAuctions.bg2:SetFrameLevel(AuctionFrameAuctions.bg2:GetFrameLevel() - 1)
end

S:AddCallbackForAddon("Blizzard_AuctionUI", "AuctionHouse", LoadSkin)