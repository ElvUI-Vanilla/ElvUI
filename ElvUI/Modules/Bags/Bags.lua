local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:NewModule("Bags", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");
local Search = LibStub("LibItemSearch-1.2");
local LIP = LibStub("ItemPrice-1.1", true);

--Cache global variables
--Lua functions
local _G = _G
local type, ipairs, pairs, unpack, select, assert, pcall = type, ipairs, pairs, unpack, select, assert, pcall
local tinsert = table.insert
local floor, ceil = math.floor, math.ceil
local len, gsub, sub, find, match = string.len, string.gsub, string.sub, string.find, string.match
--WoW API / Variables
local BankFrameItemButton_OnUpdate = BankFrameItemButton_OnUpdate
local BankFrameItemButton_UpdateLock = BankFrameItemButton_UpdateLock
local CloseBag, CloseBackpack, CloseBankFrame = CloseBag, CloseBackpack, CloseBankFrame
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local CreateFrame = CreateFrame
local DeleteCursorItem = DeleteCursorItem
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetKeyRingSize = GetKeyRingSize
local GetMoney = GetMoney
local GetNumBankSlots = GetNumBankSlots
local IsBagOpen, IsOptionFrameOpen = IsBagOpen, IsOptionFrameOpen
local IsControlKeyDown = IsControlKeyDown
local PickupContainerItem = PickupContainerItem
local PickupMerchantItem = PickupMerchantItem
local PlaySound = PlaySound
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonDesaturated = SetItemButtonDesaturated
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor
local ToggleFrame = ToggleFrame
local UseContainerItem = UseContainerItem

local BANK_CONTAINER = BANK_CONTAINER
local KEYRING_CONTAINER = KEYRING_CONTAINER
local MAX_CONTAINER_ITEMS = MAX_CONTAINER_ITEMS
local NUM_BAG_FRAMES = NUM_BAG_FRAMES
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES
local SEARCH = SEARCH

local SEARCH_STRING = ""

B.ProfessionColors = {
	["0x0008"] = {224/255, 187/255, 74/255}, -- Leatherworking
	["0x0010"] = {74/255, 77/255, 224/255}, -- Inscription
	["0x0020"] = {18/255, 181/255, 32/255}, -- Herbs
	["0x0040"] = {160/255, 3/255, 168/255}, -- Enchanting
	["0x0080"] = {232/255, 118/255, 46/255}, -- Engineering
	["0x0400"] = {105/255, 79/255, 7/255}, -- Mining
	["0x010000"] = {222/255, 13/255, 65/255} -- Cooking
}

function B:GetContainerFrame(arg)
	if type(arg) == "boolean" and arg == true then
		return self.BankFrame
	elseif type(arg) == "number" then
		if self.BankFrame then
			for _, bagID in ipairs(self.BankFrame.BagIDs) do
				if bagID == arg then
					return self.BankFrame
				end
			end
		end
	end

	return self.BagFrame
end

function B:Tooltip_Show()
	GameTooltip:SetOwner(this)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(this.ttText)

	if this.ttText2 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(this.ttText2, this.ttText2desc, 1, 1, 1)
	end

	GameTooltip:Show()
end

function B:Tooltip_Hide()
	GameTooltip:Hide()
end

function B:DisableBlizzard()
	BankFrame:UnregisterAllEvents()

	for i = 1, NUM_CONTAINER_FRAMES do
		E:Kill(_G["ContainerFrame"..i])
	end
end

function B:SearchReset()
	SEARCH_STRING = ""
end

function B:IsSearching()
	if SEARCH_STRING ~= "" and SEARCH_STRING ~= SEARCH then
		return true
	end
	return false
end

function B:UpdateSearch()
	if this.Instructions then this.Instructions:SetShown(this:GetText() == "") end
	local MIN_REPEAT_CHARACTERS = 3
	local searchString = this:GetText()
	local prevSearchString = SEARCH_STRING
	if len(searchString) > MIN_REPEAT_CHARACTERS then
		local repeatChar = true
		for i = 1, MIN_REPEAT_CHARACTERS, 1 do
			if sub(searchString,(0-i), (0-i)) ~= sub(searchString,(-1-i),(-1-i)) then
				repeatChar = false
				break
			end
		end
		if repeatChar then
			B.ResetAndClear(this)
			return
		end
	end

	--Keep active search term when switching between bank and reagent bank
	if searchString == SEARCH and prevSearchString ~= "" then
		searchString = prevSearchString
	elseif searchString == SEARCH then
		searchString = ""
	end

	SEARCH_STRING = searchString

	B:SetSearch(SEARCH_STRING)
end

function B:OpenEditbox()
	self.BagFrame.detail:Hide()
	self.BagFrame.editBox:Show()
	self.BagFrame.editBox:SetText(SEARCH)
	self.BagFrame.editBox:HighlightText()
end

function B:ResetAndClear()
	local editbox = this.editBox or this
	if editbox then editbox:SetText(SEARCH) end

	editbox:ClearFocus()
	B:SearchReset()
end

function B:SetSearch(query)
	local empty = len(gsub(query, " ", "")) == 0
	for _, bagFrame in pairs(self.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local link = GetContainerItemLink(bagID, slotID)
				local button = bagFrame.Bags[bagID][slotID]
				local success, result = pcall(Search.Matches, Search, link, query)
				if empty or (success and result) then
					SetItemButtonDesaturated(button)
					button:SetAlpha(1)
				else
					SetItemButtonDesaturated(button, 1)
					button:SetAlpha(0.5)
				end
			end
		end
	end

	if ElvUIKeyFrameItem1 then
		local numKey = GetKeyRingSize()
		for slotID = 1, numKey do
			local link = GetContainerItemLink(KEYRING_CONTAINER, slotID)
			local button = _G["ElvUIKeyFrameItem"..slotID]
			local success, result = pcall(Search.Matches, Search, link, query)
			if empty or (success and result) then
				SetItemButtonDesaturated(button)
				button:SetAlpha(1)
			else
				SetItemButtonDesaturated(button, 1)
				button:SetAlpha(0.4)
			end
		end
	end
end

function B:UpdateItemLevelDisplay()
	if E.private.bags.enable ~= true then return end
	for _, bagFrame in pairs(self.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local slot = bagFrame.Bags[bagID][slotID]
				if slot and slot.itemLevel then
					E:FontTemplate(slot.itemLevel, E.LSM:Fetch("font", E.db.bags.itemLevelFont), E.db.bags.itemLevelFontSize, E.db.bags.itemLevelFontOutline)
				end
			end
		end

		if bagFrame.UpdateAllSlots then
			bagFrame:UpdateAllSlots()
		end
	end
end

function B:UpdateCountDisplay()
	if E.private.bags.enable ~= true then return end
	local color = E.db.bags.countFontColor

	for _, bagFrame in pairs(self.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local slot = bagFrame.Bags[bagID][slotID]
				if slot and slot.Count then
					E:FontTemplate(slot.Count, E.LSM:Fetch("font", E.db.bags.countFont), E.db.bags.countFontSize, E.db.bags.countFontOutline)
					slot.Count:SetTextColor(color.r, color.g, color.b)
				end
			end
		end
		if bagFrame.UpdateAllSlots then
			bagFrame:UpdateAllSlots()
		end
	end
end

function B:UpdateSlot(bagID, slotID)
	if (self.Bags[bagID] and self.Bags[bagID].numSlots ~= GetContainerNumSlots(bagID)) or not self.Bags[bagID] or not self.Bags[bagID][slotID] then return end

	local slot = self.Bags[bagID][slotID]
	local bagType = self.Bags[bagID].type
	local texture, count, locked = GetContainerItemInfo(bagID, slotID)
	local clink = GetContainerItemLink(bagID, slotID)

	slot.name, slot.rarity = nil, nil

	slot:Show()
	slot.itemLevel:SetText("")

	if B.ProfessionColors[bagType] then
		slot:SetBackdropBorderColor(unpack(B.ProfessionColors[bagType]))
	elseif clink then
		local iLvl, itemEquipLoc
		slot.name, _, slot.rarity, iLvl, _, _, _, itemEquipLoc = GetItemInfo(match(clink, "item:(%d+)"))

		local r, g, b

		if slot.rarity then
			r, g, b = GetItemQualityColor(slot.rarity)
		end

		--Item Level
		if iLvl and B.db.itemLevel and (itemEquipLoc ~= nil and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_AMMO" and itemEquipLoc ~= "INVTYPE_BAG" and itemEquipLoc ~= "INVTYPE_QUIVER" and itemEquipLoc ~= "INVTYPE_TABARD") and (slot.rarity and slot.rarity > 1) then
			if iLvl >= E.db.bags.itemLevelThreshold then
				slot.itemLevel:SetText(iLvl)
				slot.itemLevel:SetTextColor(r, g, b)
			end
		end

		-- color slot according to item quality
		if slot.rarity then
			slot:SetBackdropBorderColor(r, g, b)
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	else
		slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end

	if texture then
		if bagID ~= BANK_CONTAINER then
			local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
			CooldownFrame_SetTimer(slot.cooldown, start, duration, enable)
			if duration > 0 and enable == 0 then
				SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4)
			else
				SetItemButtonTextureVertexColor(slot, 1, 1, 1)
			end
		end
		slot.hasItem = 1
	else
		if bagID ~= BANK_CONTAINER then
			slot.cooldown:Hide()
		end
		slot.hasItem = nil
	end

	SetItemButtonTexture(slot, texture)
	SetItemButtonCount(slot, count)
	SetItemButtonDesaturated(slot, locked)

	if GameTooltip:IsOwned(slot) and not slot.hasItem then
		B:Tooltip_Hide()
	end
end

function B:UpdateBagSlots(bagID)
	for slotID = 1, GetContainerNumSlots(bagID) do
		if self.UpdateSlot then
			self:UpdateSlot(bagID, slotID)
		else
			self:GetParent():UpdateSlot(bagID, slotID)
		end
	end
end

function B:UpdateCooldowns()
	for _, bagID in ipairs(self.BagIDs) do
		if bagID ~= BANK_CONTAINER then
			for slotID = 1, GetContainerNumSlots(bagID) do
				local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
				CooldownFrame_SetTimer(self.Bags[bagID][slotID].cooldown, start, duration, enable)
				if duration > 0 and enable == 0 then
					SetItemButtonTextureVertexColor(self.Bags[bagID][slotID], 0.4, 0.4, 0.4)
				else
					SetItemButtonTextureVertexColor(self.Bags[bagID][slotID], 1, 1, 1)
				end
			end
		end
	end
end

function B:UpdateAllSlots()
	for _, bagID in ipairs(self.BagIDs) do
		if self.Bags[bagID] then
			self.Bags[bagID]:UpdateBagSlots(bagID)
		end
	end
end

function B:SetSlotAlphaForBag(f)
	for _, bagID in ipairs(f.BagIDs) do
		if f.Bags[bagID] then
			local numSlots = GetContainerNumSlots(bagID)
			for slotID = 1, numSlots do
				if f.Bags[bagID][slotID] then
					if bagID == self.id then
						f.Bags[bagID][slotID]:SetAlpha(1)
					else
						f.Bags[bagID][slotID]:SetAlpha(0.1)
					end
				end
			end
		end
	end
end

function B:ResetSlotAlphaForBags(f)
	for _, bagID in ipairs(f.BagIDs) do
		if f.Bags[bagID] then
			local numSlots = GetContainerNumSlots(bagID)
			for slotID = 1, numSlots do
				if f.Bags[bagID][slotID] then
					f.Bags[bagID][slotID]:SetAlpha(1)
				end
			end
		end
	end
end

function B:Layout(isBank)
	if E.private.bags.enable ~= true then return end
	local f = self:GetContainerFrame(isBank)

	if not f then return end
	local buttonSize = isBank and self.db.bankSize or self.db.bagSize
	local buttonSpacing = E.PixelMode and 2 or 4
	local containerWidth = ((isBank and self.db.bankWidth) or self.db.bagWidth)
	local numContainerColumns = floor(containerWidth / (buttonSize + buttonSpacing))
	local holderWidth = ((buttonSize + buttonSpacing) * numContainerColumns) - buttonSpacing
	local numContainerRows = 0
	local countColor = E.db.bags.countFontColor
	E:Width(f.holderFrame, holderWidth)

	f.totalSlots = 0
	local lastButton
	local lastRowButton
	local lastContainerButton
	local numContainerSlots = GetNumBankSlots()
	for i, bagID in ipairs(f.BagIDs) do
		--Bag Containers
		if (not isBank and bagID <= 3 ) or (isBank and bagID ~= -1 and numContainerSlots >= 1 and not (i - 1 > numContainerSlots)) then
			if not f.ContainerHolder[i] then
				if isBank then
					f.ContainerHolder[i] = CreateFrame("CheckButton", "ElvUIBankBag"..bagID - 4, f.ContainerHolder, "BankItemButtonBagTemplate")
					f.ContainerHolder[i]:SetScript("OnClick", function()
						local inventoryID = this:GetInventorySlot()
						PutItemInBag(inventoryID) --Put bag on empty slot, or drop item in this bag
					end)
				else
					f.ContainerHolder[i] = CreateFrame("CheckButton", "ElvUIMainBag"..bagID.."Slot", f.ContainerHolder, "BagSlotButtonTemplate")
					f.ContainerHolder[i]:SetScript("OnClick", function()
						local id = this:GetID()
						PutItemInBag(id) --Put bag on empty slot, or drop item in this bag
					end)
				end

				E:CreateBackdrop(f.ContainerHolder[i], "Default", true)
				f.ContainerHolder[i].backdrop:SetAllPoints()
				E:StyleButton(f.ContainerHolder[i])
				f.ContainerHolder[i]:SetNormalTexture("")
				f.ContainerHolder[i]:SetCheckedTexture("")
				f.ContainerHolder[i]:SetPushedTexture("")
				f.ContainerHolder[i].id = isBank and bagID or bagID + 1
				HookScript(f.ContainerHolder[i], "OnEnter", function() B.SetSlotAlphaForBag(this, f) end)
				HookScript(f.ContainerHolder[i], "OnLeave", function() B.ResetSlotAlphaForBags(this, f) end)

				if isBank then
					f.ContainerHolder[i]:SetID(bagID)
					if not f.ContainerHolder[i].tooltipText then
						f.ContainerHolder[i].tooltipText = ""
					end
				end

				f.ContainerHolder[i].iconTexture = _G[f.ContainerHolder[i]:GetName().."IconTexture"]
				E:SetInside(f.ContainerHolder[i].iconTexture)
				f.ContainerHolder[i].iconTexture:SetTexCoord(unpack(E.TexCoords))
			end

			E:Size(f.ContainerHolder, ((buttonSize + buttonSpacing) * (isBank and i - 1 or i)) + buttonSpacing, buttonSize + (buttonSpacing * 2))

			if isBank then
				-- BankFrameItemButton_OnUpdate()
				-- BankFrameItemButton_UpdateLock()
			end

			E:Size(f.ContainerHolder[i], buttonSize)
			f.ContainerHolder[i]:ClearAllPoints()
			if (isBank and i == 2) or (not isBank and i == 1) then
				E:Point(f.ContainerHolder[i], "BOTTOMLEFT", f.ContainerHolder, "BOTTOMLEFT", buttonSpacing, buttonSpacing)
			else
				E:Point(f.ContainerHolder[i], "LEFT", lastContainerButton, "RIGHT", buttonSpacing, 0)
			end

			lastContainerButton = f.ContainerHolder[i]
		end

		--Bag Slots
		local numSlots = GetContainerNumSlots(bagID)
		if numSlots > 0 then
			if not f.Bags[bagID] then
				f.Bags[bagID] = CreateFrame("Frame", f:GetName().."Bag"..bagID, f)
				f.Bags[bagID]:SetID(bagID)
				f.Bags[bagID].UpdateBagSlots = B.UpdateBagSlots
				-- f.Bags[bagID].UpdateSlot = UpdateSlot
			end

			f.Bags[bagID].numSlots = numSlots

			local link = GetInventoryItemLink("player", ContainerIDToInventoryID(bagID))
			if link then
				local _, _, id = strfind(link, "item:(%d+)")
				f.Bags[bagID].type = select(6, GetItemInfo(id))
			end

			--Hide unused slots
			for i = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID][i] then
					f.Bags[bagID][i]:Hide()
				end
			end

			for slotID = 1, numSlots do
				f.totalSlots = f.totalSlots + 1
				if not f.Bags[bagID][slotID] then
					f.Bags[bagID][slotID] = CreateFrame("CheckButton", f.Bags[bagID]:GetName().."Slot"..slotID, f.Bags[bagID], bagID == -1 and "BankItemButtonGenericTemplate" or "ContainerFrameItemButtonTemplate")
					E:StyleButton(f.Bags[bagID][slotID])
					E:SetTemplate(f.Bags[bagID][slotID], "Default", true)
					f.Bags[bagID][slotID]:SetNormalTexture("")
					f.Bags[bagID][slotID]:SetCheckedTexture("")

					f.Bags[bagID][slotID].Count = _G[f.Bags[bagID][slotID]:GetName().."Count"]
					f.Bags[bagID][slotID].Count:ClearAllPoints()
					E:Point(f.Bags[bagID][slotID].Count, "BOTTOMRIGHT", 0, 2)
					E:FontTemplate(f.Bags[bagID][slotID].Count, E.LSM:Fetch("font", E.db.bags.countFont), E.db.bags.countFontSize, E.db.bags.countFontOutline)
					f.Bags[bagID][slotID].Count:SetTextColor(countColor.r, countColor.g, countColor.b)

					f.Bags[bagID][slotID].iconTexture = _G[f.Bags[bagID][slotID]:GetName().."IconTexture"]
					E:SetInside(f.Bags[bagID][slotID].iconTexture, f.Bags[bagID][slotID])
					f.Bags[bagID][slotID].iconTexture:SetTexCoord(unpack(E.TexCoords))

					if bagID ~= BANK_CONTAINER then
						f.Bags[bagID][slotID].cooldown = _G[f.Bags[bagID][slotID]:GetName().."Cooldown"]
						f.Bags[bagID][slotID].cooldown:SetModelScale(buttonSize / 48)
						E:RegisterCooldown(f.Bags[bagID][slotID].cooldown)
						f.Bags[bagID][slotID].bagID = bagID
						f.Bags[bagID][slotID].slotID = slotID
					end

					f.Bags[bagID][slotID].itemLevel = f.Bags[bagID][slotID]:CreateFontString(nil, "OVERLAY")
					E:Point(f.Bags[bagID][slotID].itemLevel, "BOTTOMRIGHT", 0, 2)
					E:FontTemplate(f.Bags[bagID][slotID].itemLevel, E.LSM:Fetch("font", E.db.bags.itemLevelFont), E.db.bags.itemLevelFontSize, E.db.bags.itemLevelFontOutline)
				end

				f.Bags[bagID][slotID]:SetID(slotID)
				E:Size(f.Bags[bagID][slotID], buttonSize)

				f:UpdateSlot(bagID, slotID)

				if f.Bags[bagID][slotID]:GetPoint() then
					f.Bags[bagID][slotID]:ClearAllPoints()
				end

				if lastButton then
					if mod(f.totalSlots - 1, numContainerColumns) == 0 then
						E:Point(f.Bags[bagID][slotID], "TOP", lastRowButton, "BOTTOM", 0, -buttonSpacing)
						lastRowButton = f.Bags[bagID][slotID]
						numContainerRows = numContainerRows + 1
					else
						E:Point(f.Bags[bagID][slotID], "LEFT", lastButton, "RIGHT", buttonSpacing, 0)
					end
				else
					E:Point(f.Bags[bagID][slotID], "TOPLEFT", f.holderFrame, "TOPLEFT")
					lastRowButton = f.Bags[bagID][slotID]
					numContainerRows = numContainerRows + 1
				end

				lastButton = f.Bags[bagID][slotID]
			end
		else
			for i = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID] and f.Bags[bagID][i] then
					f.Bags[bagID][i]:Hide()
				end
			end

			if f.Bags[bagID] then
				f.Bags[bagID].numSlots = numSlots
			end

			if self.isBank then
				if self.ContainerHolder[i] then
					BankFrameItemButton_OnUpdate()
					BankFrameItemButton_UpdateLock()
				end
			end
		end
	end

	local numKey = GetKeyRingSize()
	local numKeyColumns = 6
	if not isBank then
		local totalSlots = 0
		local lastRowButton
		local numKeyRows = 1
		for i = 1, numKey do
			totalSlots = totalSlots + 1

			if not f.keyFrame.slots[i] then
				f.keyFrame.slots[i] = CreateFrame("CheckButton", "ElvUIKeyFrameItem"..i, f.keyFrame, "ContainerFrameItemButtonTemplate")
				E:StyleButton(f.keyFrame.slots[i], nil, nil, true)
				E:SetTemplate(f.keyFrame.slots[i], "Default", true)
				f.keyFrame.slots[i]:SetNormalTexture("")
				f.keyFrame.slots[i]:SetID(i)

				f.keyFrame.slots[i].cooldown = _G[f.keyFrame.slots[i]:GetName().."Cooldown"]
				f.keyFrame.slots[i].cooldown:SetModelScale(buttonSize / 48)
				E:RegisterCooldown(f.keyFrame.slots[i].cooldown)

				f.keyFrame.slots[i].iconTexture = _G[f.keyFrame.slots[i]:GetName().."IconTexture"]
				E:SetInside(f.keyFrame.slots[i].iconTexture, f.keyFrame.slots[i])
				f.keyFrame.slots[i].iconTexture:SetTexCoord(unpack(E.TexCoords))
			end

			f.keyFrame.slots[i]:ClearAllPoints()
			E:Size(f.keyFrame.slots[i], buttonSize)
			if f.keyFrame.slots[i-1] then
				if mod(totalSlots - 1, numKeyColumns) == 0 then
					E:Point(f.keyFrame.slots[i], "TOP", lastRowButton, "BOTTOM", 0, -buttonSpacing)
					lastRowButton = f.keyFrame.slots[i]
					numKeyRows = numKeyRows + 1
				else
					E:Point(f.keyFrame.slots[i], "RIGHT", f.keyFrame.slots[i-1], "LEFT", -buttonSpacing, 0)
				end
			else
				E:Point(f.keyFrame.slots[i], "TOPRIGHT", f.keyFrame, "TOPRIGHT", -buttonSpacing, -buttonSpacing)
				lastRowButton = f.keyFrame.slots[i]
			end

			self:UpdateKeySlot(i)
		end

		if numKey < numKeyColumns then
			numKeyColumns = numKey
		end
		E:Size(f.keyFrame, ((buttonSize + buttonSpacing) * numKeyColumns) + buttonSpacing, ((buttonSize + buttonSpacing) * numKeyRows) + buttonSpacing)
	end

	E:Size(f, containerWidth, (((buttonSize + buttonSpacing) * numContainerRows) - buttonSpacing) + f.topOffset + f.bottomOffset)
end

function B:UpdateKeySlot(slotID)
	assert(slotID)
	local bagID = KEYRING_CONTAINER
	local texture, count, locked = GetContainerItemInfo(bagID, slotID)
	local clink = GetContainerItemLink(bagID, slotID)
	local slot = _G["ElvUIKeyFrameItem"..slotID]
	if not slot then return end

	slot.name, slot.rarity = nil, nil
	slot:Show()

	if clink then
		local _
		slot.name, _, slot.rarity = GetItemInfo(match(clink, "item:(%d+)"))

		local r, g, b

		if slot.rarity then
			r, g, b = GetItemQualityColor(slot.rarity)
		end

		if slot.rarity and slot.rarity > 1 then
			slot:SetBackdropBorderColor(r, g, b)
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	else
		slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end

	if texture then
		local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
		CooldownFrame_SetTimer(slot.cooldown, start, duration, enable)
		if duration > 0 and enable == 0 then
			SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4)
		else
			SetItemButtonTextureVertexColor(slot, 1, 1, 1)
		end
	else
		slot.cooldown:Hide()
	end

	SetItemButtonTexture(slot, texture)
	SetItemButtonCount(slot, count)
	SetItemButtonDesaturated(slot, locked, 0.5, 0.5, 0.5)
end

function B:UpdateAll()
	if self.BagFrame then
		self:Layout()
	end

	if self.BankFrame then
		self:Layout(true)
	end
end

function B:OnEvent()
	if event == "ITEM_LOCK_CHANGED" or event == "ITEM_UNLOCKED" then
		local bag, slot = arg1, arg2
		if bag == KEYRING_CONTAINER then
			B:UpdateKeySlot(slot)
		else
			this:UpdateSlot(bag, slot)
		end
	elseif event == "BAG_UPDATE" then
		local bag = arg1
		if bag == KEYRING_CONTAINER then
			if not _G["ElvUIKeyFrameItem"..GetKeyRingSize()] then
				B:Layout(false)
			end
			for slotID = 1, GetKeyRingSize() do
				B:UpdateKeySlot(slotID)
			end
		end

		for _, bagID in ipairs(this.BagIDs) do
			local numSlots = GetContainerNumSlots(bagID)
			if (not this.Bags[bagID] and numSlots ~= 0) or (this.Bags[bagID] and numSlots ~= this.Bags[bagID].numSlots) then
				B:Layout(this.isBank)
				return
			end
		end

		this:UpdateBagSlots(arg1, arg2)
		if B:IsSearching() then
			B:SetSearch(SEARCH_STRING)
		end
	elseif event == "BAG_UPDATE_COOLDOWN" then
		if not this:IsShown() then return end
		this:UpdateCooldowns()
	elseif event == "PLAYERBANKSLOTS_CHANGED" then
		this:UpdateAllSlots()
	end
end

function B:UpdateGoldText()
	self.BagFrame.goldText:SetText(E:FormatMoney(GetMoney(), E.db["bags"].moneyFormat))
end

function B:GetGraysValue()
	local c = 0

	for b = 0, NUM_BAG_FRAMES do
		for s = 1, GetContainerNumSlots(b) do
			local l = GetContainerItemLink(b, s)
			if l and find(l,"ff9d9d9d") then
				local p = LIP:GetSellValue(l) * select(2, GetContainerItemInfo(b, s))
				if select(3, GetItemInfo(match(l, "item:(%d+)"))) == 0 and p > 0 then
					c = c + p
				end
			end
		end
	end

	return c
end

function B:VendorGrays(delete, _, getValue)
	if (not MerchantFrame or not MerchantFrame:IsShown()) and not delete and not getValue then
		E:Print(L["You must be at a vendor."])
		return
	end

	local c = 0

	for b = 0, NUM_BAG_FRAMES do
		for s = 1, GetContainerNumSlots(b) do
			local l = GetContainerItemLink(b, s)
			if l and find(l,"ff9d9d9d") then
				local p = LIP:GetSellValue(l) * select(2, GetContainerItemInfo(b, s))
				if delete then
					if not getValue then
						PickupContainerItem(b, s)
						DeleteCursorItem()
					end
					c = c + p
				else
					if not getValue then
						UseContainerItem(b, s)
						PickupMerchantItem()
					end
					c = c + p
				end
			end
		end
	end

	if getValue then
		return c
	end

	if c > 0 and not delete then
		local g, s, c = floor(c / 10000) or 0, floor(mod(c, 10000) / 100) or 0, mod(c, 100)
		E:Print(L["Vendored gray items for:"].." |cffffffff"..g..L.goldabbrev.." |cffffffff"..s..L.silverabbrev.." |cffffffff"..c..L.copperabbrev..".")
	end
end

function B:VendorGrayCheck()
	local value = B:GetGraysValue()
	if value == 0 then
		E:Print(L["No gray items to delete."])
	elseif not MerchantFrame or not MerchantFrame:IsShown() then
		E.PopupDialogs["DELETE_GRAYS"].Money = value
		E:StaticPopup_Show("DELETE_GRAYS")
	else
		B:VendorGrays()
	end
end

function B:ContructContainerFrame(name, isBank)
	local f = CreateFrame("Button", name, E.UIParent)
	E:SetTemplate(f, "Transparent")
	f:SetFrameStrata("DIALOG")
	f.UpdateSlot = B.UpdateSlot
	f.UpdateAllSlots = B.UpdateAllSlots
	f.UpdateBagSlots = B.UpdateBagSlots
	f.UpdateCooldowns = B.UpdateCooldowns
	f:RegisterEvent("ITEM_LOCK_CHANGED")
	f:RegisterEvent("ITEM_UNLOCKED")
	f:RegisterEvent("BAG_UPDATE_COOLDOWN")
	f:RegisterEvent("BAG_UPDATE")
	f:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

	f:SetScript("OnEvent", B.OnEvent)
	f:Hide()

	f.isBank = isBank

	f.bottomOffset = isBank and 8 or 28
	f.topOffset = isBank and 45 or 50
	f.BagIDs = isBank and {-1, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4}
	f.Bags = {}

	local mover = (isBank and ElvUIBankMover or ElvUIBagMover)
	if mover then
		E:Point(f, mover.POINT, mover)
		f.mover = mover
	end

	f:SetMovable(true)
	f:RegisterForDrag("LeftButton", "RightButton")
	f:RegisterForClicks("AnyUp")
	f:SetScript("OnDragStart", function() if IsShiftKeyDown() then this:StartMoving() end end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	f:SetScript("OnClick", function() if IsControlKeyDown() then B.PostBagMove(this.mover) end end)
	f:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Hold Shift + Drag:"], L["Temporary Move"], 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Hold Control + Right Click:"], L["Reset Position"], 1, 1, 1)

		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)

	f.closeButton = CreateFrame("Button", name.."CloseButton", f, "UIPanelCloseButton")
	E:Point(f.closeButton, "TOPRIGHT", -4, -4)

	E:GetModule("Skins"):HandleCloseButton(f.closeButton)

	f.holderFrame = CreateFrame("Frame", nil, f)
	E:Point(f.holderFrame, "TOP", f, "TOP", 0, -f.topOffset)
	E:Point(f.holderFrame, "BOTTOM", f, "BOTTOM", 0, 8)

	f.ContainerHolder = CreateFrame("Button", name.."ContainerHolder", f)
	E:Point(f.ContainerHolder, "BOTTOMLEFT", f, "TOPLEFT", 0, 1)
	E:SetTemplate(f.ContainerHolder, "Transparent")
	f.ContainerHolder:Hide()

	if isBank then
		f.bagText = f:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(f.bagText)
		E:Point(f.bagText, "BOTTOMRIGHT", f.holderFrame, "TOPRIGHT", -2, 4)
		f.bagText:SetJustifyH("RIGHT")
		f.bagText:SetText(L["Bank"])

		f.sortButton = CreateFrame("Button", name.."SortButton", f)
		E:Size(f.sortButton, 16 + E.Border)
		E:SetTemplate(f.sortButton)
		E:Point(f.sortButton, "RIGHT", f.bagText, "LEFT", -5, E.Border * 2)
		f.sortButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetNormalTexture())
		f.sortButton:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetPushedTexture())
		f.sortButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetDisabledTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetDisabledTexture())
		f.sortButton:GetDisabledTexture():SetDesaturated(true)
		E:StyleButton(f.sortButton, nil, true)
		f.sortButton.ttText = L["Sort Bags"]
		f.sortButton:SetScript("OnEnter", self.Tooltip_Show)
		f.sortButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.sortButton:SetScript("OnClick", function() B:CommandDecorator(B.SortBags, "bank")() end)
		if E.db.bags.disableBankSort then
			f.sortButton:Disable()
		end

		f.bagsButton = CreateFrame("Button", name.."BagsButton", f.holderFrame)
		E:Size(f.bagsButton, 16 + E.Border)
		E:SetTemplate(f.bagsButton)
		E:Point(f.bagsButton, "RIGHT", f.sortButton, "LEFT", -5, 0)
		f.bagsButton:SetNormalTexture("Interface\\Buttons\\Button-Backpack-Up")
		f.bagsButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.bagsButton:GetNormalTexture())
		f.bagsButton:SetPushedTexture("Interface\\Buttons\\Button-Backpack-Up")
		f.bagsButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.bagsButton:GetPushedTexture())
		E:StyleButton(f.bagsButton, nil, true)
		f.bagsButton.ttText = L["Toggle Bags"]
		f.bagsButton:SetScript("OnEnter", self.Tooltip_Show)
		f.bagsButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.bagsButton:SetScript("OnClick", function()
			local numSlots = GetNumBankSlots()
			PlaySound("igMainMenuOption")
			if numSlots >= 1 then
				ToggleFrame(f.ContainerHolder)
			else
				E:StaticPopup_Show("NO_BANK_BAGS")
			end
		end)

		f.purchaseBagButton = CreateFrame("Button", nil, f.holderFrame)
		E:Size(f.purchaseBagButton, 16 + E.Border)
		E:SetTemplate(f.purchaseBagButton)
		E:Point(f.purchaseBagButton, "RIGHT", f.bagsButton, "LEFT", -5, 0)
		f.purchaseBagButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Coin_01")
		f.purchaseBagButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.purchaseBagButton:GetNormalTexture())
		f.purchaseBagButton:SetPushedTexture("Interface\\ICONS\\INV_Misc_Coin_01")
		f.purchaseBagButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.purchaseBagButton:GetPushedTexture())
		E:StyleButton(f.purchaseBagButton, nil, true)
		f.purchaseBagButton.ttText = L["Purchase Bags"]
		f.purchaseBagButton:SetScript("OnEnter", self.Tooltip_Show)
		f.purchaseBagButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.purchaseBagButton:SetScript("OnClick", function()
			local _, full = GetNumBankSlots()
			if full then
				E:StaticPopup_Show("CANNOT_BUY_BANK_SLOT")
			else
				E:StaticPopup_Show("BUY_BANK_SLOT")
			end
		end)

		f:SetScript("OnHide", function()
			CloseBankFrame()

			if E.db.bags.clearSearchOnClose then
				B.ResetAndClear(f.editBox)
			end
		end)

		f.editBox = CreateFrame("EditBox", name.."EditBox", f)
		f.editBox:SetFrameLevel(f.editBox:GetFrameLevel() + 2)
		E:CreateBackdrop(f.editBox, "Default")
		E:Point(f.editBox.backdrop, "TOPLEFT", f.editBox, "TOPLEFT", -20, 2)
		E:Height(f.editBox, 15)
		E:Point(f.editBox, "BOTTOMLEFT", f.holderFrame, "TOPLEFT", (E.Border * 2) + 18, E.Border * 2 + 2)
		E:Point(f.editBox, "RIGHT", f.purchaseBagButton, "LEFT", -5, 0)
		f.editBox:SetAutoFocus(false)
		f.editBox:SetScript("OnEscapePressed", self.ResetAndClear)
		f.editBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
		f.editBox:SetScript("OnEditFocusGained", function() this:HighlightText() end)
		f.editBox:SetScript("OnTextChanged", self.UpdateSearch)
		f.editBox:SetScript("OnChar", self.UpdateSearch)
		f.editBox:SetText(SEARCH)
		E:FontTemplate(f.editBox)

		f.editBox.searchIcon = f.editBox:CreateTexture(nil, "OVERLAY")
		f.editBox.searchIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\UI-Searchbox-Icon")
		E:Point(f.editBox.searchIcon, "LEFT", f.editBox.backdrop, "LEFT", E.Border + 1, -1)
		E:Size(f.editBox.searchIcon, 15)
	else
		f.keyFrame = CreateFrame("Frame", name.."KeyFrame", f)
		E:Point(f.keyFrame, "TOPRIGHT", f, "TOPLEFT", -(E.PixelMode and 1 or 3), 0)
		E:SetTemplate(f.keyFrame, "Transparent")
		f.keyFrame:SetID(KEYRING_CONTAINER)
		f.keyFrame.slots = {}
		f.keyFrame:Hide()

		f.goldText = f:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(f.goldText)
		E:Point(f.goldText, "BOTTOMRIGHT", f.holderFrame, "TOPRIGHT", -2, 4)
		f.goldText:SetJustifyH("RIGHT")

		f.sortButton = CreateFrame("Button", name.."SortButton", f)
		E:Size(f.sortButton, 16 + E.Border)
		E:SetTemplate(f.sortButton)
		E:Point(f.sortButton, "RIGHT", f.goldText, "LEFT", -5, E.Border * 2)
		f.sortButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetNormalTexture())
		f.sortButton:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetPushedTexture())
		f.sortButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_RatCage")
		f.sortButton:GetDisabledTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetDisabledTexture())
		f.sortButton:GetDisabledTexture():SetDesaturated(true)
		E:StyleButton(f.sortButton, nil, true)
		f.sortButton.ttText = L["Sort Bags"]
		f.sortButton:SetScript("OnEnter", self.Tooltip_Show)
		f.sortButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.sortButton:SetScript("OnClick", function() B:CommandDecorator(B.SortBags, "bags")() end)
		if E.db.bags.disableBagSort then
			f.sortButton:Disable()
		end

		f.keyButton = CreateFrame("Button", name.."KeyButton", f)
		E:Size(f.keyButton, 16 + E.Border)
		E:SetTemplate(f.keyButton)
		E:Point(f.keyButton, "RIGHT", f.sortButton, "LEFT", -5, 0)
		f.keyButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Key_14")
		f.keyButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.keyButton:GetNormalTexture())
		f.keyButton:SetPushedTexture("Interface\\ICONS\\INV_Misc_Key_14")
		f.keyButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.keyButton:GetPushedTexture())
		E:StyleButton(f.keyButton, nil, true)
		f.keyButton.ttText = L["Toggle Key"]
		f.keyButton:SetScript("OnEnter", self.Tooltip_Show)
		f.keyButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.keyButton:SetScript("OnClick", function() ToggleFrame(f.keyFrame) end)

		f.bagsButton = CreateFrame("Button", name.."BagsButton", f)
		E:Size(f.bagsButton, 16 + E.Border)
		E:SetTemplate(f.bagsButton)
		E:Point(f.bagsButton, "RIGHT", f.keyButton, "LEFT", -5, 0)
		f.bagsButton:SetNormalTexture("Interface\\Buttons\\Button-Backpack-Up")
		f.bagsButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.bagsButton:GetNormalTexture())
		f.bagsButton:SetPushedTexture("Interface\\Buttons\\Button-Backpack-Up")
		f.bagsButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.bagsButton:GetPushedTexture())
		E:StyleButton(f.bagsButton, nil, true)
		f.bagsButton.ttText = L["Toggle Bags"]
		f.bagsButton:SetScript("OnEnter", self.Tooltip_Show)
		f.bagsButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.bagsButton:SetScript("OnClick", function() ToggleFrame(f.ContainerHolder) end)

		f.vendorGraysButton = CreateFrame("Button", nil, f.holderFrame)
		E:Size(f.vendorGraysButton, 16 + E.Border)
		E:SetTemplate(f.vendorGraysButton)
		E:Point(f.vendorGraysButton, "RIGHT", f.bagsButton, "LEFT", -5, 0)
		f.vendorGraysButton:SetNormalTexture("Interface\\ICONS\\INV_Misc_Coin_01")
		f.vendorGraysButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.vendorGraysButton:GetNormalTexture())
		f.vendorGraysButton:SetPushedTexture("Interface\\ICONS\\INV_Misc_Coin_01")
		f.vendorGraysButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.vendorGraysButton:GetPushedTexture())
		E:StyleButton(f.vendorGraysButton, nil, true)
		f.vendorGraysButton.ttText = L["Vendor Grays"]
		f.vendorGraysButton:SetScript("OnEnter", self.Tooltip_Show)
		f.vendorGraysButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.vendorGraysButton:SetScript("OnClick", B.VendorGrayCheck)

		f.editBox = CreateFrame("EditBox", name.."EditBox", f)
		f.editBox:SetFrameLevel(f.editBox:GetFrameLevel() + 2)
		E:CreateBackdrop(f.editBox, "Default")
		E:Point(f.editBox.backdrop, "TOPLEFT", f.editBox, "TOPLEFT", -20, 2)
		E:Height(f.editBox, 15)
		E:Point(f.editBox, "BOTTOMLEFT", f.holderFrame, "TOPLEFT", (E.Border * 2) + 18, E.Border * 2 + 2)
		E:Point(f.editBox, "RIGHT", f.vendorGraysButton, "LEFT", -5, 0)
		f.editBox:SetAutoFocus(false)
		f.editBox:SetScript("OnEscapePressed", self.ResetAndClear)
		f.editBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
		f.editBox:SetScript("OnEditFocusGained", function() this:HighlightText() end)
		f.editBox:SetScript("OnTextChanged", self.UpdateSearch)
		f.editBox:SetScript("OnChar", self.UpdateSearch)
		f.editBox:SetText(SEARCH)
		E:FontTemplate(f.editBox)

		f.editBox.searchIcon = f.editBox:CreateTexture(nil, "OVERLAY")
		f.editBox.searchIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\UI-Searchbox-Icon")
		E:Point(f.editBox.searchIcon, "LEFT", f.editBox.backdrop, "LEFT", E.Border + 1, -1)
		E:Size(f.editBox.searchIcon, 15)

		f:SetScript("OnHide", function()
			CloseBackpack()
			for i = 1, NUM_BAG_FRAMES do
				CloseBag(i)
			end

			if ElvUIBags and ElvUIBags.buttons then
				for _, bagButton in pairs(ElvUIBags.buttons) do
					bagButton:SetChecked(false)
				end
			end
			if E.db.bags.clearSearchOnClose then
				B.ResetAndClear(f.editBox)
			end
		end)
	end

	f:SetScript("OnShow", function()
		this:UpdateCooldowns()
	end)

	tinsert(UISpecialFrames, f:GetName()) --Keep an eye on this for taints..
	tinsert(self.BagFrames, f)
	return f
end

function B:ToggleBags(id)
	--Closes a bag when inserting a new container..
	if id and GetContainerNumSlots(id) == 0 then return end

	if self.BagFrame:IsShown() then
		self:CloseBags()
	else
		self:OpenBags()
	end
end

function B:ToggleBackpack()
	if IsOptionFrameOpen() then
		return
	end

	if IsBagOpen(0) then
		self:OpenBags()
	else
		self:CloseBags()
	end
end

function B:OpenAllBags()
	if IsOptionFrameOpen() then
		return
	end

	if self.BagFrame:IsShown() then
		self:CloseBags()
	else
		self:OpenBags()
	end
end

function B:ToggleSortButtonState(isBank)
	local button, disable
	if isBank and self.BankFrame then
		button = self.BankFrame.sortButton
		disable = E.db.bags.disableBankSort
	elseif not isBank and self.BagFrame then
		button = self.BagFrame.sortButton
		disable = E.db.bags.disableBagSort
	end

	if button and disable then
		button:Disable()
	elseif button and not disable then
		button:Enable()
	end
end

function B:OpenBags()
	self.BagFrame:Show()
	self.BagFrame:UpdateAllSlots()
	E:GetModule("Tooltip"):GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:CloseBags()
	self.BagFrame:Hide()

	if self.BankFrame then
		self.BankFrame:Hide()
	end

	E:GetModule("Tooltip"):GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:OpenBank()
	if not self.BankFrame then
		self.BankFrame = self:ContructContainerFrame("ElvUI_BankContainerFrame", true)
	end

	self:Layout(true)
	self.BankFrame:Show()
	self.BankFrame:UpdateAllSlots()
	self:OpenBags()
end

function B:PLAYERBANKBAGSLOTS_CHANGED()
	self:Layout(true)
end

function B:CloseBank()
	if not self.BankFrame then return end -- WHY???, WHO KNOWS!
	self.BankFrame:Hide()
end

function B:PostBagMove()
	if not E.private.bags.enable then return end

	local x, y = self:GetCenter()
	local screenHeight = UIParent:GetTop()
	local screenWidth = UIParent:GetRight()

	if not x then return end

	if y > (screenHeight / 2) then
		self:SetText(self.textGrowDown)
		self.POINT = ((x > (screenWidth/2)) and "TOPRIGHT" or "TOPLEFT")
	else
		self:SetText(self.textGrowUp)
		self.POINT = ((x > (screenWidth/2)) and "BOTTOMRIGHT" or "BOTTOMLEFT")
	end

	local bagFrame
	if self.name == "ElvUIBankMover" then
		bagFrame = B.BankFrame
	else
		bagFrame = B.BagFrame
	end

	if bagFrame then
		bagFrame:ClearAllPoints()
		E:Point(bagFrame, self.POINT, self)
	end
end

function B:Initialize()
	self:LoadBagBar()

	local BagFrameHolder = CreateFrame("Frame", nil, E.UIParent)
	E:Size(BagFrameHolder, 200, 22)
	BagFrameHolder:SetFrameLevel(BagFrameHolder:GetFrameLevel() + 400)

	if not E.private.bags.enable then
		E:Point(BagFrameHolder, "BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", -(E.Border*2), 22 + E.Border*4 - E.Spacing*2)
		E:CreateMover(BagFrameHolder, "ElvUIBagMover", L["Bag Mover"], nil, nil, B.PostBagMove)

		self:SecureHook("UpdateContainerFrameAnchors")
		return
	end

	E.bags = self
	self.db = E.db.bags
	self.BagFrames = {}

	E:Point(BagFrameHolder, "BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", 0, 22 + E.Border*4 - E.Spacing*2)
	E:CreateMover(BagFrameHolder, "ElvUIBagMover", L["Bag Mover (Grow Up)"], nil, nil, B.PostBagMove)

	local BankFrameHolder = CreateFrame("Frame", nil, E.UIParent)
	E:Size(BankFrameHolder, 200, 22)
	E:Point(BankFrameHolder, "BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", 0, 22 + E.Border*4 - E.Spacing*2)
	BankFrameHolder:SetFrameLevel(BankFrameHolder:GetFrameLevel() + 400)
	E:CreateMover(BankFrameHolder, "ElvUIBankMover", L["Bank Mover (Grow Up)"], nil, nil, B.PostBagMove)

	ElvUIBagMover.textGrowUp = L["Bag Mover (Grow Up)"]
	ElvUIBagMover.textGrowDown = L["Bag Mover (Grow Down)"]
	ElvUIBagMover.POINT = "BOTTOMRIGHT"
	ElvUIBankMover.textGrowUp = L["Bank Mover (Grow Up)"]
	ElvUIBankMover.textGrowDown = L["Bank Mover (Grow Down)"]
	ElvUIBankMover.POINT = "BOTTOMLEFT"

	self.BagFrame = self:ContructContainerFrame("ElvUI_ContainerFrame")

	--Hook onto Blizzard Functions
	self:RawHook("ToggleBag", "ToggleBags")
	self:RawHook("OpenBackpack", "OpenBags")
	self:RawHook("CloseAllBags", "CloseBags")
	self:RawHook("CloseBackpack", "CloseBags")
	self:RawHook("ToggleBackpack", "ToggleBags")
	self:RawHook("OpenAllBags", "OpenAllBags", true)

	self:Layout()

	E.Bags = self

	self:DisableBlizzard()
	self:RegisterEvent("PLAYER_MONEY", "UpdateGoldText")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateGoldText")
	self:RegisterEvent("PLAYER_TRADE_MONEY", "UpdateGoldText")
	self:RegisterEvent("TRADE_MONEY_CHANGED", "UpdateGoldText")
	self:RegisterEvent("BANKFRAME_OPENED", "OpenBank")
	self:RegisterEvent("BANKFRAME_CLOSED", "CloseBank")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

	StackSplitFrame:SetFrameStrata("DIALOG")
end

local function InitializeCallback()
	B:Initialize()
end

E:RegisterModule(B:GetName(), InitializeCallback)