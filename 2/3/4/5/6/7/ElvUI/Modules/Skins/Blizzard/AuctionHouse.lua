local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.auctionhouse ~= true then return end

	E:StripTextures(AuctionFrame, true)
	E:CreateBackdrop(AuctionFrame, "Transparent")
	AuctionFrame.backdrop:SetPoint("TOPLEFT", 10, -11)
	AuctionFrame.backdrop:SetPoint("BOTTOMRIGHT", 0, 4)

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
	AuctionDressUpModelRotateLeftButton:SetPoint("TOPLEFT", AuctionDressUpFrame, 8, -17)
	S:HandleRotateButton(AuctionDressUpModelRotateRightButton)
	AuctionDressUpModelRotateRightButton:SetPoint("TOPLEFT", AuctionDressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

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
	AuctionsCloseButton:SetPoint("BOTTOMRIGHT", AuctionFrameAuctions, "BOTTOMRIGHT", 66, 14)
	AuctionsCancelAuctionButton:SetPoint("RIGHT", AuctionsCloseButton, "LEFT", -4, 0)
	BidBuyoutButton:SetPoint("RIGHT", BidCloseButton, "LEFT", -4, 0)
	BidBidButton:SetPoint("RIGHT", BidBuyoutButton, "LEFT", -4, 0)
	BrowseBuyoutButton:SetPoint("RIGHT", BrowseCloseButton, "LEFT", -4, 0)
	BrowseBidButton:SetPoint("RIGHT", BrowseBuyoutButton, "LEFT", -4, 0)
	AuctionsCreateAuctionButton:SetPoint("BOTTOMLEFT", 18, 44)

	BrowseSearchButton:ClearAllPoints()
	BrowseSearchButton:SetPoint("TOPRIGHT", AuctionFrameBrowse, "TOPRIGHT", 25, -30)

	S:HandleNextPrevButton(BrowseNextPageButton)
	BrowseNextPageButton:ClearAllPoints()
	BrowseNextPageButton:SetPoint("BOTTOMLEFT", BrowseSearchButton, "BOTTOMRIGHT", 10, -27)

	S:HandleNextPrevButton(BrowsePrevPageButton)
	BrowsePrevPageButton:ClearAllPoints()
	BrowsePrevPageButton:SetPoint("BOTTOMRIGHT", BrowseSearchButton, "BOTTOMLEFT", -10, -27)

	E:StripTextures(AuctionsItemButton)
	E:SetTemplate(AuctionsItemButton, "Default", true)
	E:StyleButton(AuctionsItemButton)

	HookScript(AuctionsItemButton, "OnEvent", function()
		this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		if arg1 == "NEW_AUCTION_UPDATE" and this:GetNormalTexture() then
			this:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
			E:SetInside(this:GetNormalTexture())
		end
		local _, _, _, quality = GetAuctionSellItemInfo()
		if quality and quality > 1 then
			AuctionsItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
			AuctionsItemButtonName:SetTextColor(quality)
		else
			E:SetTemplate(AuctionsItemButton, "Default", true)
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
	AuctionFrameTab1:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 25, -26)
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

	BrowseBidPrice:SetPoint("BOTTOM", -15, 18)
	BrowseBidText:SetPoint("BOTTOMRIGHT", AuctionFrameBrowse, "BOTTOM", -116, 21)

	BrowseMaxLevel:SetPoint("LEFT", BrowseMinLevel, "RIGHT", 8, 0)
	BrowseLevelText:SetPoint("BOTTOMLEFT", AuctionFrameBrowse, "TOPLEFT", 195, -48)

	BrowseName:SetWidth(164)
	BrowseName:SetPoint("TOPLEFT", AuctionFrameBrowse, "TOPLEFT", 20, -54)
	BrowseNameText:SetPoint("TOPLEFT", BrowseName, "TOPLEFT", 0, 16)

	S:HandleCheckBox(IsUsableCheckButton)
	IsUsableCheckButton:ClearAllPoints()
	IsUsableCheckButton:SetPoint("RIGHT", BrowseIsUsableText, "LEFT", 2, 0)
	BrowseIsUsableText:SetPoint("TOPLEFT", 440, -40)

	S:HandleCheckBox(ShowOnPlayerCheckButton)
	ShowOnPlayerCheckButton:ClearAllPoints()
	ShowOnPlayerCheckButton:SetPoint("RIGHT", BrowseShowOnCharacterText, "LEFT", 2, 0)

	BrowseShowOnCharacterText:SetPoint("TOPLEFT", 440, -60)

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
				if(r == 1 and g == 1 and b == 1) then
					icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				else
					icon:SetBackdropBorderColor(r, g, b)
				end
			end)
			hooksecurefunc(name, "Hide", function(_, r, g, b)
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end)
		end

		E:StripTextures(button)
		E:StyleButton(button)
		_G["BrowseButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		button:GetHighlightTexture():SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
		button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local button = _G["AuctionsButton"..i]
		local icon = _G["AuctionsButton"..i.."Item"]
		local name = _G["AuctionsButton"..i.."Name"]

		_G["AuctionsButton"..i.."ItemIconTexture"]:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(_G["AuctionsButton"..i.."ItemIconTexture"])

		E:StyleButton(icon)
		icon:GetNormalTexture():SetTexture("")
		E:SetTemplate(icon, "Default")

		hooksecurefunc(name, "SetVertexColor", function(_, r, g, b)
			if(r == 1 and g == 1 and b == 1) then
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			else
				icon:SetBackdropBorderColor(r, g, b)
			end
		end)
		hooksecurefunc(name, "Hide", function(_, r, g, b)
			icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end)

		E:StripTextures(button)
		E:StyleButton(button)
		_G["AuctionsButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		button:GetHighlightTexture():SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
		button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	for i = 1, NUM_BIDS_TO_DISPLAY do
		local button = _G["BidButton"..i]
		local icon = _G["BidButton"..i.."Item"]
		local name = _G["BidButton"..i.."Name"]

		_G["BidButton"..i.."ItemIconTexture"]:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(_G["BidButton"..i.."ItemIconTexture"])

		E:StyleButton(icon)
		icon:GetNormalTexture():SetTexture("")
		E:SetTemplate(icon, "Default")

		E:CreateBackdrop(icon, "Default")
		icon.backdrop:SetAllPoints()

		hooksecurefunc(name, "SetVertexColor", function(_, r, g, b)
			if(r == 1 and g == 1 and b == 1) then
				icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			else
				icon:SetBackdropBorderColor(r, g, b)
			end
		end)
		hooksecurefunc(name, "Hide", function(_, r, g, b)
			icon:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end)

		E:StripTextures(button)
		E:StyleButton(button)
		_G["BidButton"..i.."Highlight"] = button:GetHighlightTexture()
		button:GetHighlightTexture():ClearAllPoints()
		button:GetHighlightTexture():SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
		button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 5)
		button:GetPushedTexture():SetAllPoints(button:GetHighlightTexture())
	end

	--Custom Backdrops
	AuctionFrameBrowse.bg1 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	E:SetTemplate(AuctionFrameBrowse.bg1, "Default")
	AuctionFrameBrowse.bg1:SetPoint("TOPLEFT", 20, -103)
	AuctionFrameBrowse.bg1:SetPoint("BOTTOMRIGHT", -575, 40)
	BrowseNoResultsText:SetParent(AuctionFrameBrowse.bg1)
	BrowseSearchCountText:SetParent(AuctionFrameBrowse.bg1)
	AuctionFrameBrowse.bg1:SetFrameLevel(AuctionFrameBrowse.bg1:GetFrameLevel() - 1)

	AuctionFrameBrowse.bg2 = CreateFrame("Frame", nil, AuctionFrameBrowse)
	E:SetTemplate(AuctionFrameBrowse.bg2, "Default")
	AuctionFrameBrowse.bg2:SetPoint("TOPLEFT", AuctionFrameBrowse.bg1, "TOPRIGHT", 4, 0)
	AuctionFrameBrowse.bg2:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -8, 40)
	AuctionFrameBrowse.bg2:SetFrameLevel(AuctionFrameBrowse.bg2:GetFrameLevel() - 1)

	AuctionFrameBid.bg = CreateFrame("Frame", nil, AuctionFrameBid)
	E:SetTemplate(AuctionFrameBid.bg, "Default")
	AuctionFrameBid.bg:SetPoint("TOPLEFT", 20, -72)
	AuctionFrameBid.bg:SetPoint("BOTTOMRIGHT", 66, 40)
	AuctionFrameBid.bg:SetFrameLevel(AuctionFrameBid.bg:GetFrameLevel() - 1)

	AuctionFrameAuctions.bg1 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	E:SetTemplate(AuctionFrameAuctions.bg1, "Default")
	AuctionFrameAuctions.bg1:SetPoint("TOPLEFT", 15, -72)
	AuctionFrameAuctions.bg1:SetPoint("BOTTOMRIGHT", -545, 40)
	AuctionFrameAuctions.bg1:SetFrameLevel(AuctionFrameAuctions.bg1:GetFrameLevel() - 3)

	AuctionFrameAuctions.bg2 = CreateFrame("Frame", nil, AuctionFrameAuctions)
	E:SetTemplate(AuctionFrameAuctions.bg2, "Default")
	AuctionFrameAuctions.bg2:SetPoint("TOPLEFT", AuctionFrameAuctions.bg1, "TOPRIGHT", 3, 0)
	AuctionFrameAuctions.bg2:SetPoint("BOTTOMRIGHT", AuctionFrame, -8, 40)
	AuctionFrameAuctions.bg2:SetFrameLevel(AuctionFrameAuctions.bg2:GetFrameLevel() - 3)
end

S:AddCallbackForAddon("Blizzard_AuctionUI", "AuctionHouse", LoadSkin)