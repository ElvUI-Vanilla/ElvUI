local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local match = string.match
--WoW API / Variables
local GetItemQualityColor = GetItemQualityColor
local GetContainerItemLink = GetContainerItemLink
local BANK_CONTAINER = BANK_CONTAINER
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES

function S:ContainerFrame_Update(self)
	local id = self:GetID()
	local name = self:GetName()
	local _, itemButton, itemLink, quality

	for i = 1, self.size, 1 do
		itemButton = _G[name.."Item"..i]

		itemLink = GetContainerItemLink(id, itemButton:GetID())
		if itemLink then
			_, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
			if quality then
				itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
			else
				itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
		else
			itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end
end

function S:BankFrameItemButton_Update(button)
	if not button.isBag then
		local _, _, _, quality = GetContainerItemInfo(BANK_CONTAINER, button:GetID())
		if quality then
			button:SetBackdropBorderColor(GetItemQualityColor(quality))
		else
			button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end
end

local function LoadSkin()
	-- if not E.private.skins.blizzard.enable and E.private.skins.blizzard.bags and not E.private.bags.enable then return end

	-- ContainerFrame
	local containerFrame, containerFrameClose
	for i = 1, NUM_CONTAINER_FRAMES, 1 do
		containerFrame = _G["ContainerFrame"..i]
		containerFrameClose = _G["ContainerFrame"..i.."CloseButton"]

		E:StripTextures(containerFrame, true)
		E:CreateBackdrop(containerFrame, "Transparent")
		containerFrame.backdrop:SetPoint("TOPLEFT", 9, -4)
		containerFrame.backdrop:SetPoint("BOTTOMRIGHT", -4, 2)

		S:HandleCloseButton(containerFrameClose)

		local itemButton, itemButtonIcon
		for k = 1, MAX_CONTAINER_ITEMS, 1 do
			itemButton = _G["ContainerFrame"..i.."Item"..k]
			itemButtonIcon = _G["ContainerFrame"..i.."Item"..k.."IconTexture"]
			itemButtonCooldown = _G["ContainerFrame"..i.."Item"..k.."Cooldown"]

			itemButton:SetNormalTexture("")

			E:SetTemplate(itemButton, "Default", true)
			E:StyleButton(itemButton)

			E:SetInside(itemButtonIcon)
			itemButtonIcon:SetTexCoord(unpack(E.TexCoords))

			if itemButtonCooldown then
				E:RegisterCooldown(itemButtonCooldown)
			end
		end
	end

	S:SecureHook("ContainerFrame_Update")

	-- BankFrame
	E:CreateBackdrop(BankFrame, "Transparent")
	BankFrame.backdrop:SetPoint("TOPLEFT", 10, -11)
	BankFrame.backdrop:SetPoint("BOTTOMRIGHT", -26, 93)

	E:StripTextures(BankFrame, true)

	S:HandleCloseButton(BankCloseButton)

	local button, buttonIcon
	for i = 1, NUM_BANKGENERIC_SLOTS, 1 do
		button = _G["BankFrameItem"..i]
		buttonIcon = _G["BankFrameItem"..i.."IconTexture"]

		button:SetNormalTexture("")

		E:SetTemplate(button, "Default", true)
		E:StyleButton(button)

		E:SetInside(buttonIcon)
		buttonIcon:SetTexCoord(unpack(E.TexCoords))
	end

	BankFrame.itemBackdrop = CreateFrame("Frame", "BankFrameItemBackdrop", BankFrame)
	E:SetTemplate(BankFrame.itemBackdrop, "Default")
	BankFrame.itemBackdrop:SetPoint("TOPLEFT", BankFrameItem1, "TOPLEFT", -6, 6)
	BankFrame.itemBackdrop:SetPoint("BOTTOMRIGHT", BankFrameItem24, "BOTTOMRIGHT", 6, -6)
	BankFrame.itemBackdrop:SetFrameLevel(BankFrame:GetFrameLevel())

	for i = 1, NUM_BANKBAGSLOTS, 1 do
		button = _G["BankFrameBag"..i]
		buttonIcon = _G["BankFrameBag"..i.."IconTexture"]

		button:SetNormalTexture("")

		E:SetTemplate(button, "Default", true)
		E:StyleButton(button)

		E:SetInside(buttonIcon)
		buttonIcon:SetTexCoord(unpack(E.TexCoords))

		E:SetInside(_G["BankFrameBag"..i.."HighlightFrameTexture"])
		_G["BankFrameBag"..i.."HighlightFrameTexture"]:SetTexture(unpack(E["media"].rgbvaluecolor), 0.3)
	end

	BankFrame.bagBackdrop = CreateFrame("Frame", "BankFrameBagBackdrop", BankFrame)
	E:SetTemplate(BankFrame.bagBackdrop, "Default")
	BankFrame.bagBackdrop:SetPoint("TOPLEFT", BankFrameBag1, "TOPLEFT", -6, 6)
	BankFrame.bagBackdrop:SetPoint("BOTTOMRIGHT", BankFrameBag6, "BOTTOMRIGHT", 6, -6)
	BankFrame.bagBackdrop:SetFrameLevel(BankFrame:GetFrameLevel())

	S:HandleButton(BankFramePurchaseButton)

	-- S:SecureHook("BankFrameItemButton_UpdateLock")
end

S:AddCallback("SkinBags", LoadSkin)