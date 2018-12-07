local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:NewModule("Bags", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");
local Search = LibStub("LibItemSearch-1.2");
local LIP = LibStub("ItemPrice-1.1");

--Cache global variables
--Lua functions
local _G = _G
local type, ipairs, pairs, unpack, select, assert, pcall = type, ipairs, pairs, unpack, select, assert, pcall
local tinsert, tremove, twipe, tmaxn = table.insert, table.remove, table.wipe, table.maxn
local floor, abs, mod = math.floor, math.abs, math.fmod
local format, len, match, sub, gsub = string.format, string.len, string.match, string.sub, string.gsub
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
local GetContainerNumSlots = GetContainerNumSlots
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetMoney = GetMoney
local GetNumBankSlots = GetNumBankSlots
local GetKeyRingSize = GetKeyRingSize
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local IsBagOpen, IsOptionFrameOpen = IsBagOpen, IsOptionFrameOpen
local IsShiftKeyDown, IsControlKeyDown = IsShiftKeyDown, IsControlKeyDown
local PickupContainerItem = PickupContainerItem
local PlaySound = PlaySound
local PutItemInBag = PutItemInBag
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonDesaturated = SetItemButtonDesaturated
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor
local ToggleFrame = ToggleFrame
local UseContainerItem = UseContainerItem
local BANK_CONTAINER = BANK_CONTAINER
local CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y = CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y
local CONTAINER_SCALE = CONTAINER_SCALE
local CONTAINER_SPACING, VISIBLE_CONTAINER_SPACING = CONTAINER_SPACING, VISIBLE_CONTAINER_SPACING
local CONTAINER_WIDTH = CONTAINER_WIDTH
local KEYRING_CONTAINER = KEYRING_CONTAINER
local MAX_CONTAINER_ITEMS = MAX_CONTAINER_ITEMS
local NUM_BAG_FRAMES = NUM_BAG_FRAMES
local NUM_BANKGENERIC_SLOTS = NUM_BANKGENERIC_SLOTS
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES
local BINDING_NAME_TOGGLEKEYRING = BINDING_NAME_TOGGLEKEYRING
local SEARCH = SEARCH

local TooltipModule, SkinModule
local SEARCH_STRING = ""

function B:GetContainerFrame(arg)
	if type(arg) == "boolean" and (arg == true) then
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
		if self.ttText2desc then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(self.ttText2, self.ttText2desc, 1, 1, 1)
		else
			GameTooltip:AddLine(self.ttText2)
		end
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
	return (SEARCH_STRING ~= "" and SEARCH_STRING ~= SEARCH)
end

function B:UpdateSearch()
	if this.Instructions then this.Instructions:SetShown(this:GetText() == "") end

	local MIN_REPEAT_CHARACTERS = 3
	local searchString = this:GetText()
	local prevSearchString = SEARCH_STRING
	if len(searchString) > MIN_REPEAT_CHARACTERS then
		local repeatChar = true
		for i = 1, MIN_REPEAT_CHARACTERS, 1 do
			if sub(searchString,(0 - i), (0 - i)) ~= sub(searchString,(-1 - i),(-1 - i)) then
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

	B:RefreshSearch()
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
				button:SetAlpha(0.5)
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

function B:UpdateBagTypes(isBank)
	local f = self:GetContainerFrame(isBank)
	for _, bagID in ipairs(f.BagIDs) do
		if f.Bags[bagID] then
			f.Bags[bagID].type = GetItemFamily(GetInventoryItemLink("player", ContainerIDToInventoryID(bagID)), true)
		end
	end
end

function B:UpdateAllBagSlots()
	if E.private.bags.enable ~= true then return end

	for _, bagFrame in pairs(self.BagFrames) do
		if bagFrame.UpdateAllSlots then
			bagFrame:UpdateAllSlots()
		end
	end
end

function B:UpdateSlot(bagID, slotID)
	if (self.Bags[bagID] and self.Bags[bagID].numSlots ~= GetContainerNumSlots(bagID)) or not self.Bags[bagID] or not self.Bags[bagID][slotID] then return end

	local slot = self.Bags[bagID][slotID]
	local bagType = self.Bags[bagID].type
	local texture, count, locked, _, readable = GetContainerItemInfo(bagID, slotID)
	local clink = GetContainerItemLink(bagID, slotID)
	local itemPrice = LIP:GetSellValue(clink)

	slot.name, slot.rarity = nil, nil

	slot:Show()
	slot.QuestIcon:Hide()
	slot.JunkIcon:Hide()
	slot.itemLevel:SetText("")

	if B.ProfessionColors[bagType] then
		slot:SetBackdropBorderColor(unpack(B.ProfessionColors[bagType]))
		slot.ignoreBorderColors = true
	elseif clink then
		local iLink, iLvl, iType, itemEquipLoc
		slot.name, iLink, slot.rarity, iLvl, _, iType, _, _, itemEquipLoc = GetItemInfo(match(clink, "item:(%d+)"))

		local r, g, b

		if slot.rarity then
			r, g, b = GetItemQualityColor(slot.rarity)
		end

		--Item Level
		if iLvl and B.db.itemLevel and (itemEquipLoc ~= nil and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_AMMO" and itemEquipLoc ~= "INVTYPE_BAG" and itemEquipLoc ~= "INVTYPE_QUIVER" and itemEquipLoc ~= "INVTYPE_TABARD") and (slot.rarity and slot.rarity > 1) then
			if iLvl >= E.db.bags.itemLevelThreshold then
				slot.itemLevel:SetText(iLvl)
				if B.db.itemLevelCustomColorEnable then
					slot.itemLevel:SetTextColor(B.db.itemLevelCustomColor.r, B.db.itemLevelCustomColor.g, B.db.itemLevelCustomColor.b)
				else
					slot.itemLevel:SetTextColor(r, g, b)
				end
			end
		end

		if slot.JunkIcon then
			if (slot.rarity and slot.rarity == 0) and (itemPrice and itemPrice > 0) and (iType and iType ~= "Quest") and E.db.bags.junkIcon then
				slot.JunkIcon:Show()
			end
		end

		-- color slot according to item quality
		if (iType and iType == "Quest") and not GetInvalidQuestItemInfo(iLink) then
			if GetQuestItemStarterInfo(iLink) then
				slot.QuestIcon:Show()
				slot:SetBackdropBorderColor(unpack(B.QuestColors.questStarter))
			else
				slot:SetBackdropBorderColor(unpack(B.QuestColors.questItem))
			end
			slot.ignoreBorderColors = true
		elseif slot.rarity and slot.rarity > 1 then
			slot:SetBackdropBorderColor(r, g, b)
			slot.ignoreBorderColors = true
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
			slot.ignoreBorderColors = true
		end
	else
		slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
		slot.ignoreBorderColors = true
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

	slot.readable = readable

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
			self:GetParent():GetParent():UpdateSlot(bagID, slotID)
		end
	end
end

function B:RefreshSearch()
	B:SetSearch(SEARCH_STRING)
end

function B:SortingFadeBags(bagFrame)
	if not (bagFrame and bagFrame.BagIDs) then return end

	for _, bagID in ipairs(bagFrame.BagIDs) do
		for slotID = 1, GetContainerNumSlots(bagID) do
			local button = bagFrame.Bags[bagID][slotID]
			SetItemButtonDesaturated(button, 1)
			button:SetAlpha(0.5)
		end
	end
end

function B:UpdateCooldowns()
	for _, bagID in ipairs(self.BagIDs) do
		if bagID ~= BANK_CONTAINER then
			for slotID = 1, GetContainerNumSlots(bagID) do
				local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
				CooldownFrame_SetTimer(self.Bags[bagID][slotID].cooldown, start, duration, enable)
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

	-- Refresh search in case we moved items around
	if (not self.registerUpdate) and B:IsSearching() then
		B:RefreshSearch()
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
	local numBags = 0
	local numBagSlots = 0
	local bagSpacing = self.db.split.bagSpacing
	local countColor = E.db.bags.countFontColor
	E:Width(f.holderFrame, holderWidth)

	local isSplit = self.db.split[isBank and "bank" or "player"]

	f.totalSlots = 0
	local lastButton
	local lastRowButton
	local lastContainerButton
	local numContainerSlots = GetNumBankSlots()
	local newBag
	for i, bagID in ipairs(f.BagIDs) do
		if isSplit then
			newBag = (bagID ~= -1 or bagID ~= 0) and self.db.split["bag"..bagID] or false
		end

		--Bag Containers
		if (not isBank and bagID <= 3) or (isBank and bagID ~= -1 and numContainerSlots >= 1 and not (i - 1 > numContainerSlots)) then
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
				f.Bags[bagID] = CreateFrame("Frame", f:GetName().."Bag"..bagID, f.holderFrame)
				f.Bags[bagID]:SetID(bagID)
				f.Bags[bagID].UpdateBagSlots = B.UpdateBagSlots
				f.Bags[bagID].UpdateSlot = UpdateSlot
			end

			f.Bags[bagID].numSlots = numSlots
			f.Bags[bagID].type = GetItemFamily(GetInventoryItemLink("player", ContainerIDToInventoryID(bagID)), true)

			--Hide unused slots
			for y = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID][y] then
					f.Bags[bagID][y]:Hide()
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
					E:Point(f.Bags[bagID][slotID].Count, "BOTTOMRIGHT", 0, 3)
					E:FontTemplate(f.Bags[bagID][slotID].Count, E.LSM:Fetch("font", E.db.bags.countFont), E.db.bags.countFontSize, E.db.bags.countFontOutline)
					f.Bags[bagID][slotID].Count:SetTextColor(countColor.r, countColor.g, countColor.b)

					if not f.Bags[bagID][slotID].QuestIcon then
						local QuestIcon = f.Bags[bagID][slotID]:CreateTexture(nil, "OVERLAY")
						QuestIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\bagQuestIcon")
						QuestIcon:SetTexCoord(0, 1, 0, 1)
						E:SetInside(QuestIcon)
						QuestIcon:Hide()
						f.Bags[bagID][slotID].QuestIcon = QuestIcon
					end

					if not f.Bags[bagID][slotID].JunkIcon then
						local JunkIcon = f.Bags[bagID][slotID]:CreateTexture(nil, "OVERLAY")
						JunkIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\bagJunkIcon")
						E:Point(JunkIcon, "TOPLEFT", 1, 0)
						JunkIcon:Hide()
						f.Bags[bagID][slotID].JunkIcon = JunkIcon
					end

					f.Bags[bagID][slotID].iconTexture = _G[f.Bags[bagID][slotID]:GetName().."IconTexture"]
					E:SetInside(f.Bags[bagID][slotID].iconTexture, f.Bags[bagID][slotID])
					f.Bags[bagID][slotID].iconTexture:SetTexCoord(unpack(E.TexCoords))

					if bagID ~= BANK_CONTAINER then
						f.Bags[bagID][slotID].cooldown = _G[f.Bags[bagID][slotID]:GetName().."Cooldown"]
						f.Bags[bagID][slotID].cooldown.CooldownOverride = "bags"
						f.Bags[bagID][slotID].cooldown:SetModelScale(buttonSize / (37 / 0.75))
						E:RegisterCooldown(f.Bags[bagID][slotID].cooldown)
						f.Bags[bagID][slotID].bagID = bagID
						f.Bags[bagID][slotID].slotID = slotID
					end

					f.Bags[bagID][slotID].itemLevel = f.Bags[bagID][slotID]:CreateFontString(nil, "OVERLAY")
					E:Point(f.Bags[bagID][slotID].itemLevel, "BOTTOMRIGHT", 0, 3)
					E:FontTemplate(f.Bags[bagID][slotID].itemLevel, E.LSM:Fetch("font", E.db.bags.itemLevelFont), E.db.bags.itemLevelFontSize, E.db.bags.itemLevelFontOutline)
				end

				f.Bags[bagID][slotID]:SetID(slotID)
				E:Size(f.Bags[bagID][slotID], buttonSize)

				if f.Bags[bagID][slotID].JunkIcon then
					E:Size(f.Bags[bagID][slotID].JunkIcon, buttonSize/2)
				end

				f:UpdateSlot(bagID, slotID)

				if f.Bags[bagID][slotID]:GetPoint() then
					f.Bags[bagID][slotID]:ClearAllPoints()
				end

				local anchorPoint, relativePoint
				if lastButton then
					anchorPoint, relativePoint = (self.db.reverseSlots and "BOTTOM" or "TOP"), (self.db.reverseSlots and "TOP" or "BOTTOM")
					if isSplit and newBag and slotID == 1 then
						E:Point(f.Bags[bagID][slotID], anchorPoint, lastRowButton, relativePoint, 0, self.db.reverseSlots and (buttonSpacing + bagSpacing) or -(buttonSpacing + bagSpacing))
						lastRowButton = f.Bags[bagID][slotID]
						numContainerRows = numContainerRows + 1
						numBags = numBags + 1
						numBagSlots = 0
					elseif isSplit and mod(numBagSlots, numContainerColumns) == 0 then
						E:Point(f.Bags[bagID][slotID], anchorPoint, lastRowButton, relativePoint, 0, self.db.reverseSlots and buttonSpacing or -buttonSpacing)
						lastRowButton = f.Bags[bagID][slotID]
						numContainerRows = numContainerRows + 1
					elseif (not isSplit) and mod((f.totalSlots - 1) , numContainerColumns) == 0 then
						E:Point(f.Bags[bagID][slotID], anchorPoint, lastRowButton, relativePoint, 0, self.db.reverseSlots and buttonSpacing or -buttonSpacing)
						lastRowButton = f.Bags[bagID][slotID]
						numContainerRows = numContainerRows + 1
					else
						anchorPoint, relativePoint = (self.db.reverseSlots and "RIGHT" or "LEFT"), (self.db.reverseSlots and "LEFT" or "RIGHT")
						E:Point(f.Bags[bagID][slotID], anchorPoint, lastButton, relativePoint, self.db.reverseSlots and -buttonSpacing or buttonSpacing, 0)
					end
				else
					anchorPoint = self.db.reverseSlots and "BOTTOMRIGHT" or "TOPLEFT"
					E:Point(f.Bags[bagID][slotID], anchorPoint, f.holderFrame, anchorPoint)
					lastRowButton = f.Bags[bagID][slotID]
					numContainerRows = numContainerRows + 1
				end

				lastButton = f.Bags[bagID][slotID]
				numBagSlots = numBagSlots + 1
			end
		else
			--Hide unused slots
			for y = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID] and f.Bags[bagID][y] then
					f.Bags[bagID][y]:Hide()
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
				f.keyFrame.slots[i].cooldown:SetModelScale(buttonSize / (37 / 0.75))
				E:RegisterCooldown(f.keyFrame.slots[i].cooldown)

				if not f.keyFrame.slots[i].QuestIcon then
					local QuestIcon = f.keyFrame.slots[i]:CreateTexture(nil, "OVERLAY")
					QuestIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\bagQuestIcon")
					QuestIcon:SetTexCoord(0, 1, 0, 1)
					E:SetInside(QuestIcon)
					QuestIcon:Hide()
					f.keyFrame.slots[i].QuestIcon = QuestIcon
				end

				f.keyFrame.slots[i].iconTexture = _G[f.keyFrame.slots[i]:GetName().."IconTexture"]
				E:SetInside(f.keyFrame.slots[i].iconTexture, f.keyFrame.slots[i])
				f.keyFrame.slots[i].iconTexture:SetTexCoord(unpack(E.TexCoords))
			end

			f.keyFrame.slots[i]:ClearAllPoints()
			E:Size(f.keyFrame.slots[i], buttonSize)
			if f.keyFrame.slots[i - 1] then
				if mod(totalSlots - 1, numKeyColumns) == 0 then
					E:Point(f.keyFrame.slots[i], "TOP", lastRowButton, "BOTTOM", 0, -buttonSpacing)
					lastRowButton = f.keyFrame.slots[i]
					numKeyRows = numKeyRows + 1
				else
					E:Point(f.keyFrame.slots[i], "RIGHT", f.keyFrame.slots[i - 1], "LEFT", -buttonSpacing, 0)
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

	E:Size(f, containerWidth, (((buttonSize + buttonSpacing) * numContainerRows) - buttonSpacing) + (isSplit and (numBags * bagSpacing) or 0 ) + f.topOffset + f.bottomOffset) -- 8 is the cussion of the f.holderFrame
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
		local _, r, g, b
		local iLink, iType

		slot.name, iLink, slot.rarity, _, _, iType = GetItemInfo(match(clink, "item:(%d+)"))

		if slot.rarity then
			r, g, b = GetItemQualityColor(slot.rarity)
		end

		if iType and iType == "Quest" then
			if GetQuestItemStarterInfo(iLink) then
				slot.QuestIcon:Show()
				slot:SetBackdropBorderColor(unpack(B.QuestColors.questStarter))
			else
				slot:SetBackdropBorderColor(unpack(B.QuestColors.questItem))
			end
			slot.ignoreBorderColors = true
		elseif slot.rarity and slot.rarity > 1 then
			slot:SetBackdropBorderColor(r, g, b)
			slot.ignoreBorderColors = true
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
			slot.ignoreBorderColors = true
		end
	else
		slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
		slot.ignoreBorderColors = true
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
	SetItemButtonDesaturated(slot, locked)
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

		this:UpdateBagSlots(bag, slot)

		--Refresh search in case we moved items around
		if B:IsSearching() then
			B:RefreshSearch()
		end
	elseif event == "BAG_UPDATE_COOLDOWN" then
		if not this:IsShown() then return end
		this:UpdateCooldowns()
	elseif event == "PLAYERBANKSLOTS_CHANGED" then
		this:UpdateBagSlots(-1)
	end
end

function B:UpdateGoldText()
	self.BagFrame.goldText:SetText(E:FormatMoney(GetMoney(), E.db.bags.moneyFormat))
end

function B:FormatMoney(amount)
	local str, coppername, silvername, goldname = "", "|cffeda55fc|r", "|cffc7c7cfs|r", "|cffffd700g|r"

	local value = abs(amount)
	local gold = floor(value / 10000)
	local silver = floor(mod(value / 100, 100))
	local copper = floor(mod(value, 100))

	if gold > 0 then
		str = format("%d%s%s", gold, goldname, (silver > 0 or copper > 0) and " " or "")
	end
	if silver > 0 then
		str = format("%s%d%s%s", str, silver, silvername, copper > 0 and " " or "")
	end
	if copper > 0 or value == 0 then
		str = format("%s%d%s", str, copper, coppername)
	end

	return str
end

function B:GetGraysValue()
	local value, itemLink, rarity, itype, itemPrice, stackCount, stackPrice, _ = 0

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				_, _, rarity, _, _, itype = GetItemInfo(match(itemLink, "item:(%d+)"))
				itemPrice = LIP:GetSellValue(itemLink)

				if itemPrice then
					stackCount = select(2, GetContainerItemInfo(bag, slot)) or 1
					stackPrice = itemPrice * stackCount
					if (rarity and rarity == 0) and (itype and itype ~= "Quest") and (stackPrice and stackPrice > 0) then
						value = value + stackPrice
					end
				end
			end
		end
	end

	return value
end

function B:VendorGrays(delete)
	if B.SellFrame:IsShown() then return end
	if (not MerchantFrame or not MerchantFrame:IsShown()) and not delete then
		E:Print(L["You must be at a vendor."])
		return
	end

	local itemLink, rarity, itype, itemPrice, _
	for bag = 0, NUM_BAG_FRAMES, 1 do
		for slot = 1, GetContainerNumSlots(bag), 1 do
			itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				_, _, rarity, _, _, itype = GetItemInfo(match(itemLink, "item:(%d+)"))
				itemPrice = LIP:GetSellValue(itemLink) or 0

				if (rarity and rarity == 0) and (itype and itype ~= "Quest") and (itemPrice and itemPrice > 0) then
					tinsert(B.SellFrame.Info.itemList, {bag, slot, itemPrice, itemLink})
				end
			end
		end
	end

	if not B.SellFrame.Info.itemList then return end
	if tmaxn(B.SellFrame.Info.itemList) < 1 then return end

	--Resetting stuff
	B.SellFrame.Info.delete = delete or false
	B.SellFrame.Info.ProgressTimer = 0
	B.SellFrame.Info.SellInterval = E.db.bags.vendorGrays.interval
	B.SellFrame.Info.ProgressMax = tmaxn(B.SellFrame.Info.itemList)
	B.SellFrame.Info.goldGained = 0
	B.SellFrame.Info.itemsSold = 0

	B.SellFrame.statusbar:SetValue(0)
	B.SellFrame.statusbar:SetMinMaxValues(0, B.SellFrame.Info.ProgressMax)
	B.SellFrame.statusbar.ValueText:SetText("0 / "..B.SellFrame.Info.ProgressMax)

	--Time to sell
	B.SellFrame:Show()
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
	if not SkinModule then SkinModule = E:GetModule("Skins") end

	local strata = E.db.bags.strata or "MEDIUM"

	local f = CreateFrame("Button", name, E.UIParent)
	E:SetTemplate(f, "Transparent")
	f:SetFrameStrata(strata)
	f.UpdateSlot = B.UpdateSlot
	f.UpdateAllSlots = B.UpdateAllSlots
	f.UpdateBagSlots = B.UpdateBagSlots
	f.UpdateCooldowns = B.UpdateCooldowns
	f:RegisterEvent("BAG_UPDATE") -- Has to be on both frames
	f:RegisterEvent("BAG_UPDATE_COOLDOWN") -- Has to be on both frames
	f.events = isBank and {"PLAYERBANKSLOTS_CHANGED"} or {"ITEM_LOCK_CHANGED", "ITEM_UNLOCKED"}

	for _, event in pairs(f.events) do
		f:RegisterEvent(event)
	end

	f:SetScript("OnEvent", B.OnEvent)
	f:Hide()

	f.isBank = isBank
	f.bottomOffset = 8
	f.topOffset = isBank and 45 or 50
	f.BagIDs = isBank and {-1, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4}
	f.Bags = {}

	local mover = (isBank and ElvUIBankMover) or ElvUIBagMover
	if mover then
		E:Point(f, mover.POINT, mover)
		f.mover = mover
	end

	--Allow dragging the frame around
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton", "RightButton")
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	f:SetScript("OnDragStart", function() if IsShiftKeyDown() then this:StartMoving() end end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	f:SetScript("OnClick", function() if IsControlKeyDown() then B.PostBagMove(this.mover) end end)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Hold Shift + Drag:"], L["Temporary Move"], 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Hold Control + Right Click:"], L["Reset Position"], 1, 1, 1)
		GameTooltip:Show()
	end)

	f.closeButton = CreateFrame("Button", name.."CloseButton", f, "UIPanelCloseButton")
	E:Point(f.closeButton, "TOPRIGHT", 2, 2)

	SkinModule:HandleCloseButton(f.closeButton)

	f.holderFrame = CreateFrame("Frame", nil, f)
	E:Point(f.holderFrame, "TOP", f, "TOP", 0, -f.topOffset)
	E:Point(f.holderFrame, "BOTTOM", f, "BOTTOM", 0, 8)

	f.ContainerHolder = CreateFrame("Button", name.."ContainerHolder", f)
	E:Point(f.ContainerHolder, "BOTTOMLEFT", f, "TOPLEFT", 0, 1)
	E:SetTemplate(f.ContainerHolder, "Transparent")
	f.ContainerHolder:Hide()

	if isBank then
		--Bag Text
		f.bagText = f:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(f.bagText)
		E:Point(f.bagText, "BOTTOMRIGHT", f.holderFrame, "TOPRIGHT", -2, 4)
		f.bagText:SetJustifyH("RIGHT")
		f.bagText:SetText(L["Bank"])

		--Sort Button
		f.sortButton = CreateFrame("Button", name.."SortButton", f)
		E:Size(f.sortButton, 16 + E.Border)
		E:SetTemplate(f.sortButton)
		E:Point(f.sortButton, "RIGHT", f.bagText, "LEFT", -5, E.Border * 2)
		f.sortButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetNormalTexture())
		f.sortButton:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetPushedTexture())
		f.sortButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetDisabledTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetDisabledTexture())
		f.sortButton:GetDisabledTexture():SetDesaturated(true)
		E:StyleButton(f.sortButton, nil, true)
		f.sortButton.ttText = L["Sort Bags"]
		f.sortButton:SetScript("OnEnter", self.Tooltip_Show)
		f.sortButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.sortButton:SetScript("OnClick", function()
			f:UnregisterAllEvents() --Unregister to prevent unnecessary updates
			if not f.registerUpdate then
				B:SortingFadeBags(f)
			end
			f.registerUpdate = true --Set variable that indicates this bag should be updated when sorting is done
			B:CommandDecorator(B.SortBags, "bank")()
		end)
		if E.db.bags.disableBankSort then
			f.sortButton:Disable()
		end

		--Toggle Bags Button
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

		--Purchase Bags Button
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

		--Search
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
		--Keyring Frame
		f.keyFrame = CreateFrame("Frame", name.."KeyFrame", f)
		E:Point(f.keyFrame, "TOPRIGHT", f, "TOPLEFT", -(E.PixelMode and 1 or 3), 0)
		E:SetTemplate(f.keyFrame, "Transparent")
		f.keyFrame:SetID(KEYRING_CONTAINER)
		f.keyFrame.slots = {}
		f.keyFrame:Hide()

		--Gold Text
		f.goldText = f:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(f.goldText)
		E:Point(f.goldText, "BOTTOMRIGHT", f.holderFrame, "TOPRIGHT", -10, 4)
		f.goldText:SetJustifyH("RIGHT")

		--Sort Button
		f.sortButton = CreateFrame("Button", name.."SortButton", f)
		E:Size(f.sortButton, 16 + E.Border)
		E:SetTemplate(f.sortButton)
		E:Point(f.sortButton, "RIGHT", f.goldText, "LEFT", -5, E.Border * 2)
		f.sortButton:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetNormalTexture())
		f.sortButton:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetPushedTexture())
		f.sortButton:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\INV_Pet_Broom")
		f.sortButton:GetDisabledTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(f.sortButton:GetDisabledTexture())
		f.sortButton:GetDisabledTexture():SetDesaturated(true)
		E:StyleButton(f.sortButton, nil, true)
		f.sortButton.ttText = L["Sort Bags"]
		f.sortButton:SetScript("OnEnter", self.Tooltip_Show)
		f.sortButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.sortButton:SetScript("OnClick", function()
			f:UnregisterAllEvents() --Unregister to prevent unnecessary updates
			if not f.registerUpdate then
				B:SortingFadeBags(f)
			end
			f.registerUpdate = true --Set variable that indicates this bag should be updated when sorting is done
			B:CommandDecorator(B.SortBags, "bags")()
		end)
		if E.db.bags.disableBagSort then
			f.sortButton:Disable()
		end

		--Keyring Button
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
		f.keyButton.ttText = BINDING_NAME_TOGGLEKEYRING
		f.keyButton:SetScript("OnEnter", self.Tooltip_Show)
		f.keyButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.keyButton:SetScript("OnClick", function() ToggleFrame(f.keyFrame) end)

		--Bags Button
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

		--Vendor Grays
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
		f.vendorGraysButton.ttText = L["Vendor / Delete Grays"]
		f.vendorGraysButton:SetScript("OnEnter", self.Tooltip_Show)
		f.vendorGraysButton:SetScript("OnLeave", self.Tooltip_Hide)
		f.vendorGraysButton:SetScript("OnClick", B.VendorGrayCheck)

		--Search
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
	if id and (GetContainerNumSlots(id) == 0) then return end --Closes a bag when inserting a new container..

	if self.BagFrame:IsShown() then
		self:CloseBags()
	else
		self:OpenBags()
	end
end

function B:ToggleBackpack()
	if IsOptionFrameOpen() then return end

	if IsBagOpen(0) then
		self:OpenBags()
	else
		self:CloseBags()
	end
end

function B:OpenAllBags()
	if IsOptionFrameOpen() then return end

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
	PlaySound("igBackPackOpen")

	if not TooltipModule then TooltipModule = E:GetModule("Tooltip") end
	TooltipModule:GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:CloseBags()
	self.BagFrame:Hide()
	PlaySound("igBackPackClose")

	if self.BankFrame then
		self.BankFrame:Hide()
	end

	if not TooltipModule then TooltipModule = E:GetModule("Tooltip") end
	TooltipModule:GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:OpenBank()
	if not self.BankFrame then
		self.BankFrame = self:ContructContainerFrame("ElvUI_BankContainerFrame", true)
	end

	--Call :Layout first so all elements are created before we update
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

local playerEnteringWorldFunc = function() B:UpdateBagTypes() B:Layout() end
function B:PLAYER_ENTERING_WORLD()
	self:UpdateGoldText()

	E:Delay(2, playerEnteringWorldFunc) -- Update bag types for bagslot coloring
end

function B:updateContainerFrameAnchors()
	local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
	local screenWidth = GetScreenWidth()
	local containerScale = 1
	local leftLimit = 0

	if BankFrame:IsShown() then
		leftLimit = BankFrame:GetRight() - 25
	end

	while containerScale > CONTAINER_SCALE do
		screenHeight = GetScreenHeight() / containerScale
		-- Adjust the start anchor for bags depending on the multibars
		xOffset = CONTAINER_OFFSET_X / containerScale
		yOffset = CONTAINER_OFFSET_Y / containerScale
		-- freeScreenHeight determines when to start a new column of bags
		freeScreenHeight = screenHeight - yOffset
		leftMostPoint = screenWidth - xOffset
		column = 1

		local frameHeight
		for _, frameName in ipairs(ContainerFrame1.bags) do
			frameHeight = _G[frameName]:GetHeight()

			if freeScreenHeight < frameHeight then
				-- Start a new column
				column = column + 1
				leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
				freeScreenHeight = screenHeight - yOffset
			end

			freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
		end

		if leftMostPoint < leftLimit then
			containerScale = containerScale - 0.01
		else
			break
		end
	end

	if containerScale < CONTAINER_SCALE then
		containerScale = CONTAINER_SCALE
	end

	screenHeight = GetScreenHeight() / containerScale
	-- Adjust the start anchor for bags depending on the multibars
	xOffset = CONTAINER_OFFSET_X / containerScale
	yOffset = CONTAINER_OFFSET_Y / containerScale
	-- freeScreenHeight determines when to start a new column of bags
	freeScreenHeight = screenHeight - yOffset
	column = 0

	local bagsPerColumn = 0
	for index, frameName in ipairs(ContainerFrame1.bags) do
		frame = _G[frameName]
		frame:SetScale(1)

		if index == 1 then
			-- First bag
			E:Point(frame, "BOTTOMRIGHT", ElvUIBagMover, "BOTTOMRIGHT", E.Spacing, -E.Border)
			bagsPerColumn = bagsPerColumn + 1
		elseif freeScreenHeight < frame:GetHeight() then
			-- Start a new column
			column = column + 1
			freeScreenHeight = screenHeight - yOffset
			if column > 1 then
				E:Point(frame, "BOTTOMRIGHT", ContainerFrame1.bags[(index - bagsPerColumn) - 1], "BOTTOMLEFT", -CONTAINER_SPACING, 0)
			else
				E:Point(frame, "BOTTOMRIGHT", ContainerFrame1.bags[index - bagsPerColumn], "BOTTOMLEFT", -CONTAINER_SPACING, 0)
			end
			bagsPerColumn = 0
		else
			-- Anchor to the previous bag
			E:Point(frame, "BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING)
			bagsPerColumn = bagsPerColumn + 1
		end

		freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
	end
end

function B:PostBagMove()
	if not E.private.bags.enable then return end

	-- self refers to the mover (bag or bank)
	local x, y = self:GetCenter()
	local screenHeight = E.UIParent:GetTop()
	local screenWidth = E.UIParent:GetRight()

	if y > (screenHeight / 2) then
		self:SetText(self.textGrowDown)
		self.POINT = ((x > (screenWidth / 2)) and "TOPRIGHT" or "TOPLEFT")
	else
		self:SetText(self.textGrowUp)
		self.POINT = ((x > (screenWidth / 2)) and "BOTTOMRIGHT" or "BOTTOMLEFT")
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

function B:MERCHANT_CLOSED()
	B.SellFrame:Hide()

	twipe(B.SellFrame.Info.itemList)
	B.SellFrame.Info.delete = false
	B.SellFrame.Info.ProgressTimer = 0
	B.SellFrame.Info.SellInterval = E.db.bags.vendorGrays.interval
	B.SellFrame.Info.ProgressMax = 0
	B.SellFrame.Info.goldGained = 0
	B.SellFrame.Info.itemsSold = 0
end

function B:ProgressQuickVendor()
	local item = B.SellFrame.Info.itemList[1]
	if not item then return nil, true end --No more to sell
	local bag, slot, itemPrice, itemLink = unpack(item)

	local stackPrice
	local stackCount = select(2, GetContainerItemInfo(bag, slot)) or 1
	if B.SellFrame.Info.delete then
		PickupContainerItem(bag, slot)
		DeleteCursorItem()
	else
		stackPrice = (itemPrice or 0) * stackCount
		if E.db.bags.vendorGrays.details and itemLink then
			E:Print(format("%s|cFF00DDDDx%d|r %s", itemLink, stackCount, B:FormatMoney(stackPrice)))
		end
		UseContainerItem(bag, slot)
	end

	tremove(B.SellFrame.Info.itemList, 1)

	return stackPrice
end

function B:VendorGreys_OnUpdate()
	B.SellFrame.Info.ProgressTimer = B.SellFrame.Info.ProgressTimer - arg1
	if B.SellFrame.Info.ProgressTimer > 0 then return end
	B.SellFrame.Info.ProgressTimer = B.SellFrame.Info.SellInterval

	local goldGained, lastItem = B:ProgressQuickVendor()
	if goldGained then
		B.SellFrame.Info.goldGained = B.SellFrame.Info.goldGained + goldGained
		B.SellFrame.Info.itemsSold = B.SellFrame.Info.itemsSold + 1
		B.SellFrame.statusbar:SetValue(B.SellFrame.Info.itemsSold)
		local timeLeft = (B.SellFrame.Info.ProgressMax - B.SellFrame.Info.itemsSold)*B.SellFrame.Info.SellInterval
		B.SellFrame.statusbar.ValueText:SetText(B.SellFrame.Info.itemsSold.." / "..B.SellFrame.Info.ProgressMax.." ( "..timeLeft.."s )")
	elseif lastItem then
		B.SellFrame:Hide()
		if B.SellFrame.Info.goldGained > 0 then
			E:Print(format(L["Vendored gray items for: %s"], B:FormatMoney(B.SellFrame.Info.goldGained)))
		end
	end
end

function B:CreateSellFrame()
	B.SellFrame = CreateFrame("Frame", "ElvUIVendorGraysFrame", E.UIParent)
	E:Size(B.SellFrame, 200,40)
	E:Point(B.SellFrame, "CENTER", E.UIParent)
	E:CreateBackdrop(B.SellFrame, "Transparent")
	B.SellFrame:SetAlpha(E.db.bags.vendorGrays.progressBar and 1 or 0)

	B.SellFrame.title = B.SellFrame:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(B.SellFrame.title, nil, 12, "OUTLINE")
	E:Point(B.SellFrame.title, "TOP", B.SellFrame, "TOP", 0, -2)
	B.SellFrame.title:SetText(L["Vendoring Grays"])

	B.SellFrame.statusbar = CreateFrame("StatusBar", "ElvUIVendorGraysFrameStatusbar", B.SellFrame)
	E:Size(B.SellFrame.statusbar, 180, 16)
	E:Point(B.SellFrame.statusbar, "BOTTOM", B.SellFrame, "BOTTOM", 0, 4)
	B.SellFrame.statusbar:SetStatusBarTexture(E.media.normTex)
	B.SellFrame.statusbar:SetStatusBarColor(1, 0, 0)
	E:CreateBackdrop(B.SellFrame.statusbar, "Transparent")

	B.SellFrame.statusbar.ValueText = B.SellFrame.statusbar:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(B.SellFrame.statusbar.ValueText, nil, 12, "OUTLINE")
	E:Point(B.SellFrame.statusbar.ValueText, "CENTER", B.SellFrame.statusbar)
	B.SellFrame.statusbar.ValueText:SetText("0 / 0 ( 0s )")

	B.SellFrame.Info = {
		delete = false,
		ProgressTimer = 0,
		SellInterval = E.db.bags.vendorGrays.interval,
		ProgressMax = 0,
		goldGained = 0,
		itemsSold = 0,
		itemList = {}
	}

	B.SellFrame:SetScript("OnUpdate", B.VendorGreys_OnUpdate)

	B.SellFrame:Hide()
end

function B:UpdateSellFrameSettings()
	if not B.SellFrame or not B.SellFrame.Info then return end

	B.SellFrame.Info.SellInterval = E.db.bags.vendorGrays.interval
	B.SellFrame:SetAlpha(E.db.bags.vendorGrays.progressBar and 1 or 0)
end

B.BagIndice = {
	quiver = 1,
	ammoPouch = 2,
	soulBag = 4,
	herbs = 8,
	enchanting = 16,
}

B.QuestKeys = {
	questStarter = "questStarter",
	questItem = "questItem"
}

function B:UpdateBagColors(table, indice, r, g, b)
	self[table][B.BagIndice[indice]] = {r, g, b}
end

function B:UpdateQuestColors(table, indice, r, g, b)
	self[table][B.QuestKeys[indice]] = {r, g, b}
end

function B:Initialize()
	self:LoadBagBar()

	--Bag Mover (We want it created even if Bags module is disabled, so we can use it for default bags too)
	local BagFrameHolder = CreateFrame("Frame", nil, E.UIParent)
	E:Width(BagFrameHolder, 200)
	E:Height(BagFrameHolder, 22)
	BagFrameHolder:SetFrameLevel(BagFrameHolder:GetFrameLevel() + 400)

	--Creating vendor grays frame
	B:CreateSellFrame()

	self:RegisterEvent("MERCHANT_CLOSED")

	if not E.private.bags.enable then
		--Set a different default anchor
		E:Point(BagFrameHolder, "BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", -(E.Border*2), 22 + E.Border*4 - E.Spacing*2)
		E:CreateMover(BagFrameHolder, "ElvUIBagMover", L["Bag Mover"], nil, nil, B.PostBagMove, nil, nil, "bags,general")

		self:SecureHook("updateContainerFrameAnchors")

		return
	end

	E.bags = self
	self.db = E.db.bags
	self.BagFrames = {}

	self.ProfessionColors = {
		[1] = {self.db.colors.profession.quiver.r, self.db.colors.profession.quiver.g, self.db.colors.profession.quiver.b},
		[2] = {self.db.colors.profession.ammoPouch.r, self.db.colors.profession.ammoPouch.g, self.db.colors.profession.ammoPouch.b},
		[4] = {self.db.colors.profession.soulBag.r, self.db.colors.profession.soulBag.g, self.db.colors.profession.soulBag.b},
		[8] = {self.db.colors.profession.herbs.r, self.db.colors.profession.herbs.g, self.db.colors.profession.herbs.b},
		[16] = {self.db.colors.profession.enchanting.r, self.db.colors.profession.enchanting.g, self.db.colors.profession.enchanting.b},
	}

	self.QuestColors = {
		["questStarter"] = {self.db.colors.items.questStarter.r, self.db.colors.items.questStarter.g, self.db.colors.items.questStarter.b},
		["questItem"] = {self.db.colors.items.questItem.r, self.db.colors.items.questItem.g, self.db.colors.items.questItem.b}
	}

	--Bag Mover: Set default anchor point and create mover
	E:Point(BagFrameHolder, "BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", 0, 22 + E.Border*4 - E.Spacing*2)
	E:CreateMover(BagFrameHolder, "ElvUIBagMover", L["Bag Mover (Grow Up)"], nil, nil, B.PostBagMove, nil, nil, "bags,general")

	--Bank Mover
	local BankFrameHolder = CreateFrame("Frame", nil, E.UIParent)
	E:Width(BankFrameHolder, 200)
	E:Height(BankFrameHolder, 22)
	E:Point(BankFrameHolder, "BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", 0, 22 + E.Border*4 - E.Spacing*2)
	BankFrameHolder:SetFrameLevel(BankFrameHolder:GetFrameLevel() + 400)
	E:CreateMover(BankFrameHolder, "ElvUIBankMover", L["Bank Mover (Grow Up)"], nil, nil, B.PostBagMove, nil, nil, "bags,general")

	--Set some variables on movers
	ElvUIBagMover.textGrowUp = L["Bag Mover (Grow Up)"]
	ElvUIBagMover.textGrowDown = L["Bag Mover (Grow Down)"]
	ElvUIBagMover.POINT = "BOTTOM"
	ElvUIBankMover.textGrowUp = L["Bank Mover (Grow Up)"]
	ElvUIBankMover.textGrowDown = L["Bank Mover (Grow Down)"]
	ElvUIBankMover.POINT = "BOTTOM"

	--Create Bag Frame
	self.BagFrame = self:ContructContainerFrame("ElvUI_ContainerFrame")

	--Hook onto Blizzard Functions
	self:RawHook("ToggleBag", "ToggleBags", true)
	self:RawHook("OpenBackpack", "OpenBags", true)
	self:RawHook("CloseAllBags", "CloseBags", true)
	self:RawHook("CloseBackpack", "CloseBags", true)
	self:RawHook("OpenAllBags", "OpenAllBags", true)

	self:Layout()

	E.Bags = self

	self:DisableBlizzard()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_MONEY", "UpdateGoldText")
	self:RegisterEvent("PLAYER_TRADE_MONEY", "UpdateGoldText")
	self:RegisterEvent("TRADE_MONEY_CHANGED", "UpdateGoldText")
	self:RegisterEvent("BANKFRAME_OPENED", "OpenBank")
	self:RegisterEvent("BANKFRAME_CLOSED", "CloseBank")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
end

local function InitializeCallback()
	B:Initialize()
end

E:RegisterModule(B:GetName(), InitializeCallback)
