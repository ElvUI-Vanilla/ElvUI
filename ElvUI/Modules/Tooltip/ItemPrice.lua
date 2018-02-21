local E, L, V, P, G = unpack(ElvUI)
local IP = E:NewModule("Tooltip_ItemPrice", "AceHook-3.0")

local LIP = LibStub:GetLibrary("ItemPrice-1.1")

local match = string.match

local GetActionCount = GetActionCount
local GetAuctionItemInfo = GetAuctionItemInfo
local GetAuctionSellItemInfo = GetAuctionSellItemInfo
local GetContainerItemInfo = GetContainerItemInfo
local GetCraftReagentInfo = GetCraftReagentInfo
local GetInboxItem = GetInboxItem
local GetItemCount = GetItemCount
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootSlotInfo = GetLootSlotInfo
local GetMerchantItemInfo = GetMerchantItemInfo
local GetQuestItemInfo = GetQuestItemInfo
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetSendMailItem = GetSendMailItem
local GetTradePlayerItemInfo = GetTradePlayerItemInfo
local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo
local GetTradeTargetItemInfo = GetTradeTargetItemInfo
local IsConsumableAction = IsConsumableAction

local tooltips = {
	"GameTooltip",
	"ItemRefTooltip"
}

function IP:SetAction(tt, id)
	local item
	for i = 1, tt:NumLines() do
		if i == 1 then
			local tiptext = _G["GameTooltipTextLeft"..i]
			local linetext = tiptext:GetText()

			item = linetext
		end
	end

	if not item then return end

	local count = 1
	if IsConsumableAction(id) then
		local actionCount = GetActionCount(id)
		if actionCount and actionCount == GetItemCount(item) then
			count = actionCount
		end
	end

	self:SetPrice(tt, count, item)
end

function IP:SetAuctionItem(tt, type, index)
	local _, _, count = GetAuctionItemInfo(type, index)
	self:SetPrice(tt, count)
end

function IP:SetAuctionSellItem(tt)
	local _, _, count = GetAuctionSellItemInfo()
 	self:SetPrice(tt, count)
end

function IP:SetBagItem(tt, bag, slot)
	local _, count = GetContainerItemInfo(bag, slot)
	self:SetPrice(tt, count)
end

function IP:SetCraftItem(tt, skill, slot)
	local count = 1
	if slot then
		count = select(3, GetCraftReagentInfo(skill, slot))
	end

	self:SetPrice(tt, count)
end

function IP:SetHyperlink(tt, link, count)
	count = tonumber(count)
	if not count or count < 1 then
		local owner = tt:GetParent()
		count = owner and tonumber(owner.count)
		if not count or count < 1 then
			count = 1
		end
	end

	self:SetPrice(tt, count)
end

function IP:SetInboxItem(tt, index, attachmentIndex)
	local _, _, count = GetInboxItem(index, attachmentIndex)
	self:SetPrice(tt, count)
end

function IP:SetInventoryItem(tt, unit, slot)
	if type(slot) ~= "number" or slot < 0 then return end

	local count = 1
	if slot < 20 or slot > 39 and slot < 68 then
		count = GetInventoryItemCount(unit, slot)
	end

	self:SetPrice(tt, count)
end

function IP:SetLootItem(tt, slot)
	local _, _, count = GetLootSlotInfo(slot)
	self:SetPrice(tt, count)
end

function IP:SetLootRollItem(tt, rollID)
	local _, _, count = GetLootRollItemInfo(rollID)
	self:SetPrice(tt, count)
end

function IP:SetMerchantItem(tt, slot)
	local _, _, _, count = GetMerchantItemInfo(slot)
	self:SetPrice(tt, count)
end

function IP:SetQuestItem(tt, type, slot)
	local _, _, count = GetQuestItemInfo(type, slot)
	self:SetPrice(tt, count)
end

function IP:SetQuestLogItem(tt, type, index)
	local _, _, count = GetQuestLogRewardInfo(index)
	self:SetPrice(tt, count)
end

function IP:SetSendMailItem(tt, index)
	local _, _, count = GetSendMailItem(index)
	self:SetPrice(tt, count)
end

function IP:SetTradePlayerItem(tt, index)
	local _, _, count = GetTradePlayerItemInfo(index)
	self:SetPrice(tt, count)
end

function IP:SetTradeSkillItem(tt, skill, slot)
	local count = 1
	if slot then
		count = select(3, GetTradeSkillReagentInfo(skill, slot))
	end

	self:SetPrice(tt, count)
end

function IP:SetTradeTargetItem(tt, index)
	local _, _, count = GetTradeTargetItemInfo(index)
	self:SetPrice(tt, count)
end

function IP:SetPrice(tt, count)
	if MerchantFrame:IsShown() then return end

	local bag, slot = this:GetParent():GetID(), this:GetID()
	local itemLink = GetContainerItemLink(bag, slot)
	local item, itemID
	if itemLink then
		itemID = match(itemLink, "item:(%d+)")
		item = GetItemInfo(itemID)
	end

	if not item then return end

	local price = LIP:GetSellValue(itemID)

	if price and price > 0 then
		tt:AddDoubleLine(SALE_PRICE_COLON, E:FormatMoney(count and price * count or price, "BLIZZARD", false), nil, nil, nil, 1, 1, 1)
	end

	if tt:IsShown() then tt:Show() end
end

function IP:ApplyHooks(tooltip)
	self:SecureHook(tooltip, "SetAction", "SetAction")
	self:SecureHook(tooltip, "SetAuctionItem", "SetAuctionItem")
	self:SecureHook(tooltip, "SetAuctionSellItem", "SetAuctionSellItem")
	self:SecureHook(tooltip, "SetBagItem", "SetBagItem")
	self:SecureHook(tooltip, "SetCraftItem", "SetCraftItem")
	self:SecureHook(tooltip, "SetHyperlink", "SetHyperlink")
	self:SecureHook(tooltip, "SetInboxItem", "SetInboxItem")
	self:SecureHook(tooltip, "SetInventoryItem", "SetInventoryItem")
	self:SecureHook(tooltip, "SetLootItem", "SetLootItem")
	self:SecureHook(tooltip, "SetLootRollItem", "SetLootRollItem")
	self:SecureHook(tooltip, "SetMerchantItem", "SetMerchantItem")
	self:SecureHook(tooltip, "SetQuestItem", "SetQuestItem")
	self:SecureHook(tooltip, "SetQuestLogItem", "SetQuestLogItem")
	self:SecureHook(tooltip, "SetSendMailItem", "SetSendMailItem")
	self:SecureHook(tooltip, "SetTradePlayerItem", "SetTradePlayerItem")
	self:SecureHook(tooltip, "SetTradeSkillItem", "SetTradeSkillItem")
	self:SecureHook(tooltip, "SetTradeTargetItem", "SetTradeTargetItem")
end

function IP:UpdateSettings()
	if E.db.tooltip.itemPrice then
		for _, tooltip in pairs(tooltips) do
			self:ApplyHooks(_G[tooltip])
		end
	else
		self:UnhookAll()
	end
end

function IP:Initialize()
	self:UpdateSettings()
end

local function InitializeCallback()
	IP:Initialize()
end

E:RegisterModule(IP:GetName(), InitializeCallback)