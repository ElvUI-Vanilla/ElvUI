local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local pairs = pairs
local find, match, split = string.find, string.match, string.split
--WoW API / Variables
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect then return end

	E:StripTextures(InspectFrame, true)
	E:CreateBackdrop(InspectFrame, "Transparent")
	E:Point(InspectFrame.backdrop, "TOPLEFT", 10, -12)
	E:Point(InspectFrame.backdrop, "BOTTOMRIGHT", -31, 75)

	S:HandleCloseButton(InspectFrameCloseButton)

	for i = 1, 2 do
		S:HandleTab(_G["InspectFrameTab"..i])
	end

	E:StripTextures(InspectPaperDollFrame)

	local slots = {
		"HeadSlot",
		"NeckSlot",
		"ShoulderSlot",
		"BackSlot",
		"ChestSlot",
		"ShirtSlot",
		"TabardSlot",
		"WristSlot",
		"HandsSlot",
		"WaistSlot",
		"LegsSlot",
		"FeetSlot",
		"Finger0Slot",
		"Finger1Slot",
		"Trinket0Slot",
		"Trinket1Slot",
		"MainHandSlot",
		"SecondaryHandSlot",
		"RangedSlot"
	}

	for _, slot in pairs(slots) do
		local icon = _G["Inspect"..slot.."IconTexture"]
		local slot = _G["Inspect"..slot]

		E:StripTextures(slot)
		E:StyleButton(slot, false)
		E:SetTemplate(slot, "Default", true)

		icon:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(icon)
	end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
		if button.hasItem then
			local itemLink = GetInventoryItemLink(InspectFrame.unit, button:GetID())
			if itemLink then
				local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
				if not quality then
					E:Delay(0.1, function()
						if InspectFrame.unit then
							InspectPaperDollItemSlotButton_Update(button)
						end
					end)
					return
				elseif quality then
					button:SetBackdropBorderColor(GetItemQualityColor(quality))
					return
				end
			end
		end
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end)

	S:HandleRotateButton(InspectModelRotateLeftButton)
	E:Point(InspectModelRotateLeftButton, "TOPLEFT", 3, -3)

	S:HandleRotateButton(InspectModelRotateRightButton)
	E:Point(InspectModelRotateRightButton, "TOPLEFT", InspectModelRotateLeftButton, "TOPRIGHT", 3, 0)

	E:StripTextures(InspectHonorFrame)

	InspectHonorFrameProgressBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(InspectHonorFrameProgressBar)
end

S:AddCallbackForAddon("Blizzard_InspectUI", "Inspect", LoadSkin)