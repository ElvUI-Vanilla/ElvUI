local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:GetModule("Misc");

--Cache global variables
--Lua functions
local max = math.max
local tinsert = table.insert
local unpack, pairs = unpack, pairs
--WoW API / Variables
local CloseLoot = CloseLoot
local CursorOnUpdate = CursorOnUpdate
local CursorUpdate = CursorUpdate
local GetCVar = GetCVar
local GetCursorPosition = GetCursorPosition
local GetLootSlotInfo = GetLootSlotInfo
local GetLootSlotLink = GetLootSlotLink
local GetNumLootItems = GetNumLootItems
local GiveMasterLoot = GiveMasterLoot
local IsFishingLoot = IsFishingLoot
local LootSlot = LootSlot
local LootSlotIsCoin = LootSlotIsCoin
local LootSlotIsItem = LootSlotIsItem
local ResetCursor = ResetCursor
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitName = UnitName
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local LOOT = LOOT

-- Credit Haste
local lootFrame, lootFrameHolder
local iconSize = 30

local sq, ss, sn
local OnEnter = function()
	local slot = this:GetID()
	if(LootSlotIsItem(slot)) then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetLootItem(slot)
		CursorUpdate(this)
	end

	this.drop:Show()
	this.drop:SetVertexColor(1, 1, 0)
end

local OnLeave = function()
	if this.quality and (this.quality > 1) then
		local color = ITEM_QUALITY_COLORS[this.quality]
		this.drop:SetVertexColor(color.r, color.g, color.b)
	else
		this.drop:Hide()
	end

	GameTooltip:Hide()
	ResetCursor()
end

local OnClick = function()
	LootFrame.selectedQuality = this.quality
	LootFrame.selectedItemName = this.name:GetText()
	LootFrame.selectedSlot = this:GetID()
	LootFrame.selectedLootButton = this:GetName()

	StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
	ss = this:GetID()
	sq = this.quality
	sn = this.name:GetText()
	--LootSlot(ss)
end

local OnShow = function()
	if(GameTooltip:IsOwned(this)) then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetLootItem(this:GetID())
		CursorOnUpdate(this)
	end
end

local function anchorSlots(self)
	local shownSlots = 0
	for i = 1, getn(self.slots) do
		local frame = self.slots[i]
		if(frame:IsShown()) then
			shownSlots = shownSlots + 1

			frame:SetPoint("TOP", lootFrame, 4, (-8 + iconSize) - (shownSlots * iconSize))
		end
	end

	self:SetHeight(max(shownSlots * iconSize + 16, 20))
end

local function createSlot(id)
	local frame = CreateFrame("LootButton", "ElvLootSlot"..id, lootFrame)
	frame:SetPoint("LEFT", 8, 0)
	frame:SetPoint("RIGHT", -8, 0)
	frame:SetHeight(iconSize - 2)
	frame:SetID(id)

	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnClick", OnClick)
	frame:SetScript("OnShow", OnShow)

	local iconFrame = CreateFrame("Frame", nil, frame)
	iconFrame:SetWidth(iconSize - 2)
	iconFrame:SetHeight(iconSize - 2)
	iconFrame:SetPoint("RIGHT", frame)
	E:SetTemplate(iconFrame, "Default")
	frame.iconFrame = iconFrame
	E["frames"][iconFrame] = nil

	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(icon)
	frame.icon = icon

	local count = iconFrame:CreateFontString(nil, "OVERLAY")
	count:SetJustifyH("RIGHT")
	count:SetPoint("BOTTOMRIGHT", iconFrame, -2, 2)
	E:FontTemplate(count, nil, nil, "OUTLINE")
	count:SetText(1)
	frame.count = count

	local name = frame:CreateFontString(nil, "OVERLAY")
	name:SetJustifyH("LEFT")
	name:SetPoint("LEFT", frame)
	name:SetPoint("RIGHT", icon, "LEFT")
	name:SetNonSpaceWrap(true)
	E:FontTemplate(name, nil, nil, "OUTLINE")
	frame.name = name

	local drop = frame:CreateTexture(nil, "ARTWORK")
	drop:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	drop:SetPoint("LEFT", icon, "RIGHT", 0, 0)
	drop:SetPoint("RIGHT", frame)
	drop:SetAllPoints(frame)
	drop:SetAlpha(.3)
	frame.drop = drop

	lootFrame.slots[id] = frame
	return frame
end

function M:LOOT_SLOT_CLEARED()
	if not lootFrame:IsShown() then return end

	lootFrame.slots[arg1]:Hide()
	anchorSlots(lootFrame)
end

function M:LOOT_CLOSED()
	StaticPopup_Hide("LOOT_BIND")
	lootFrame:Hide()

	for _, v in pairs(lootFrame.slots) do
		v:Hide()
	end
end

function M:OPEN_MASTER_LOOT_LIST()
	ToggleDropDownMenu(1, nil, GroupLootDropDown, lootFrame.slots[ss], 0, 0)
end

function M:UPDATE_MASTER_LOOT_LIST()
	UIDropDownMenu_Refresh(GroupLootDropDown)
end

function M:LOOT_OPENED(_, autoLoot)
	lootFrame:Show()

	if(not lootFrame:IsShown()) then
		CloseLoot(autoLoot == 0)
	end

	local items = GetNumLootItems()

	if(IsFishingLoot()) then
		lootFrame.title:SetText(L["Fishy Loot"])
	elseif(not UnitIsFriend("player", "target") and UnitIsDead("target")) then
		lootFrame.title:SetText(UnitName("target"))
	else
		lootFrame.title:SetText(LOOT)
	end

	-- Blizzard uses strings here
	if E.private.general.lootUnderMouse then
		local x, y = GetCursorPosition()
		x = x / lootFrame:GetEffectiveScale()
		y = y / lootFrame:GetEffectiveScale()

		lootFrame:ClearAllPoints()
		lootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 40, y + 20)
		lootFrame:GetCenter()
		lootFrame:Raise()
	else
		lootFrame:ClearAllPoints()
		lootFrame:SetPoint("TOPLEFT", lootFrameHolder, "TOPLEFT")
	end

	local m, w, t = 0, 0, lootFrame.title:GetStringWidth()
	if(items > 0) then
		for i = 1, items do
			local slot = lootFrame.slots[i] or createSlot(i)
			local texture, item, quantity, quality = GetLootSlotInfo(i)
			local color = ITEM_QUALITY_COLORS[quality]

			if(LootSlotIsCoin(i)) then
				item = item:gsub("\n", ", ")
			end

			if quantity and (quantity > 1) then
				slot.count:SetText(quantity)
				slot.count:Show()
			else
				slot.count:Hide()
			end

			if quality and (quality > 1) then
				slot.drop:SetVertexColor(color.r, color.g, color.b)
				slot.drop:Show()
			else
				slot.drop:Hide()
			end

			slot.quality = quality
			slot.name:SetText(item)
			if color then
				slot.name:SetTextColor(color.r, color.g, color.b)
			end
			slot.icon:SetTexture(texture)

			if quality then
				m = max(m, quality)
			end
			w = max(w, slot.name:GetStringWidth())

			slot:SetID(i)
			slot:SetSlot(i)

			slot:Enable()
			slot:Show()
		end
	else
		local slot = lootFrame.slots[1] or createSlot(1)
		local color = ITEM_QUALITY_COLORS[0]

		slot.name:SetText(L["Empty Slot"])
		if color then
			slot.name:SetTextColor(color.r, color.g, color.b)
		end
		slot.icon:SetTexture[[Interface\Icons\INV_Misc_Herb_AncientLichen]]

		items = 1
		w = max(w, slot.name:GetStringWidth())

		slot.count:Hide()
		slot.drop:Hide()
		slot:Disable()
		slot:Show()
	end
	anchorSlots(lootFrame)

	w = w + 60
	t = t + 5

	local color = ITEM_QUALITY_COLORS[m]
	lootFrame:SetBackdropBorderColor(color.r, color.g, color.b, .8)
	lootFrame:SetWidth(max(w, t))
end

function M:LoadLoot()
	if not E.private.general.loot then return end

	lootFrameHolder = CreateFrame("Frame", "ElvLootFrameHolder", E.UIParent)
	lootFrameHolder:SetPoint("TOPLEFT", 36, -195)
	lootFrameHolder:SetWidth(150)
	lootFrameHolder:SetHeight(22)

	lootFrame = CreateFrame("Button", "ElvLootFrame", lootFrameHolder)
	lootFrame:SetClampedToScreen(true)
	lootFrame:SetPoint("TOPLEFT", 0, 0)
	lootFrame:SetWidth(256)
	lootFrame:SetHeight(64)
	E:SetTemplate(lootFrame, "Transparent")
	lootFrame:SetFrameStrata("FULLSCREEN")
	lootFrame:SetToplevel(true)
	lootFrame.title = lootFrame:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(lootFrame.title, nil, nil, "OUTLINE")
	lootFrame.title:SetPoint("BOTTOMLEFT", lootFrame, "TOPLEFT", 0, 1)
	lootFrame.slots = {}
	lootFrame:SetScript("OnHide", function()
		StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
		CloseLoot()
	end)
	E["frames"][lootFrame] = nil

	self:RegisterEvent("LOOT_OPENED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("LOOT_CLOSED")
	self:RegisterEvent("OPEN_MASTER_LOOT_LIST")
	self:RegisterEvent("UPDATE_MASTER_LOOT_LIST")

	E:CreateMover(lootFrameHolder, "LootFrameMover", L["Loot Frame"])

	-- Fuzz
	LootFrame:UnregisterAllEvents()
	ElvLootFrame:Hide() -- May need another fix. Frame shows without.
	tinsert(UISpecialFrames, "ElvLootFrame")

	function _G.GroupLootDropDown_GiveLoot()
		if(sq >= MASTER_LOOT_THREHOLD) then
			local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION", ITEM_QUALITY_COLORS[sq].hex..sn..FONT_COLOR_CODE_CLOSE, this:GetText())
			if (dialog) then
				dialog.data = this.value
			end
		else
			GiveMasterLoot(ss, this.value)
		end
		CloseDropDownMenus()
	end

	E.PopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function(data)
		GiveMasterLoot(ss, data)
	end
	StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].preferredIndex = 3
end