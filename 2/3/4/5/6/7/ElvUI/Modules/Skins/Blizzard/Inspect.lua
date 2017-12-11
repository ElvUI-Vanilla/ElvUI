local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local pairs = pairs
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect then return end

	E:StripTextures(InspectFrame, true)
	E:CreateBackdrop(InspectFrame, "Transparent")
	InspectFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	InspectFrame.backdrop:SetPoint("BOTTOMRIGHT", -31, 75)

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
		if(button.hasItem) then
			local itemID = GetInventoryItemLink(InspectFrame.unit, button:GetID())
			if(itemID) then
				local _, _, quality = GetItemInfo(itemID)
				if(not quality) then
					E:Delay(0.1, function()
						if(InspectFrame.unit) then
							InspectPaperDollItemSlotButton_Update(button)
						end
					end)
					return
				elseif(quality and quality > 1) then
					button:SetBackdropBorderColor(GetItemQualityColor(quality))
					return
				end
			end
		end
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end)

	S:HandleRotateButton(InspectModelRotateLeftButton)
	InspectModelRotateLeftButton:SetPoint("TOPLEFT", 3, -3)

	S:HandleRotateButton(InspectModelRotateRightButton)
	InspectModelRotateRightButton:SetPoint("TOPLEFT", InspectModelRotateLeftButton, "TOPRIGHT", 3, 0)

	E:StripTextures(InspectHonorFrame)
end

S:AddCallbackForAddon("Blizzard_InspectUI", "Inspect", LoadSkin)