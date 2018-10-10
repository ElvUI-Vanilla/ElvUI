local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:NewModule("Misc", "AceEvent-3.0", "AceTimer-3.0");
E.Misc = M

--Cache global variables
--Lua functions
local format, gsub = string.format, string.gsub
--WoW API / Variables
local CanMerchantRepair = CanMerchantRepair
local GetFriendInfo = GetFriendInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumFriends = GetNumFriends
local GetNumGuildMembers = GetNumGuildMembers
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetPartyMember = GetPartyMember
local GetRepairAllCost = GetRepairAllCost
local GuildRoster = GuildRoster
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local IsShiftKeyDown = IsShiftKeyDown
local RepairAllItems = RepairAllItems
local UninviteByName = UninviteByName
local UnitInRaid = UnitInRaid
local UnitName = UnitName
local UIErrorsFrame = UIErrorsFrame
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS

local interruptMsg = INTERRUPTED.." %s's \124cff71d5ff\124Hspell:%d\124h[%s]\124h\124r!"

function M:ErrorFrameToggle(event)
	if not E.db.general.hideErrorFrame then return end
	if event == "PLAYER_REGEN_DISABLED" then
		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

function M:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, _, sourceName, _, _, destName, _, _, _, _, spellID, spellName)
	if E.db.general.interruptAnnounce == "NONE" then return end
	if not event == "SPELL_INTERRUPT" and sourceName == UnitName("player") then return end

	local party = GetNumPartyMembers()

	if E.db.general.interruptAnnounce == "SAY" then
		if party > 0 then
			SendChatMessage(format(interruptMsg, destName, spellID, spellName), "SAY")
		end
	elseif E.db.general.interruptAnnounce == "EMOTE" then
		if party > 0 then
			SendChatMessage(format(interruptMsg, destName, spellID, spellName), "EMOTE")
		end
	else
		local raid = GetNumRaidMembers()
		local _, instanceType = IsInInstance()
		local battleground = instanceType == "pvp"

		if E.db.general.interruptAnnounce == "PARTY" then
			if party > 0 then
				SendChatMessage(format(interruptMsg, destName, spellID, spellName), battleground and "BATTLEGROUND" or "PARTY")
			end
		elseif E.db.general.interruptAnnounce == "RAID" then
			if raid > 0 then
				SendChatMessage(format(interruptMsg, destName, spellID, spellName), battleground and "BATTLEGROUND" or "RAID")
			elseif party > 0 then
				SendChatMessage(format(interruptMsg, destName, spellID, spellName), battleground and "BATTLEGROUND" or "PARTY")
			end
		elseif E.db.general.interruptAnnounce == "RAID_ONLY" then
			if raid > 0 then
				SendChatMessage(format(interruptMsg, destName, spellID, spellName), battleground and "BATTLEGROUND" or "RAID")
			end
		end
	end
end

function M:MERCHANT_SHOW()
	if E.db.bags.vendorGrays.enable then
		E:GetModule("Bags"):VendorGrays(nil, true)
	end

	local autoRepair = E.db.general.autoRepair
	if IsShiftKeyDown() or autoRepair == "NONE" or not CanMerchantRepair() then return end

	local cost, possible = GetRepairAllCost()
	local money = GetMoney()

	if possible then
		if cost > 0 and money >= cost then
			RepairAllItems(autoRepair == "PLAYER")
			E:Print(L["Your items have been repaired for: "]..E:FormatMoney(cost, "BLIZZARD"))
		else
			E:Print(L["You don't have enough money to repair."])
		end
	end
end

function M:DisbandRaidGroup()
	if UnitInRaid("player") then
		for i = 1, GetNumRaidMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if online and name ~= E.myname then
				UninviteByName(name)
			end
		end
	else
		for i = MAX_PARTY_MEMBERS, 1, -1 do
			if GetPartyMember(i) then
				UninviteByName(UnitName("party"..i))
			end
		end
	end
	LeaveParty()
end

function M:PVPMessageEnhancement()
	if not E.db.general.enhancedPvpMessages then return end
	local _, instanceType = IsInInstance()
	if instanceType == "pvp" then
		RaidNotice_AddMessage(RaidBossEmoteFrame, arg1, ChatTypeInfo["RAID_BOSS_EMOTE"])
	--	RaidNotice_AddMessage(RaidBossEmoteFrame, arg1, ChatTypeInfo["RAID_BOSS_EMOTE"])
	end
end

local hideStatic = false
function M:AutoInvite(event)
	if not E.db.general.autoAcceptInvite then return end

	if event == "PARTY_INVITE_REQUEST" then
		if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then return end
		hideStatic = true

		-- Update Guild and Friendlist
		local numFriends = GetNumFriends()
		if numFriends > 0 then ShowFriends() end
		if IsInGuild() then GuildRoster() end
		local inGroup = false

		for friendIndex = 1, numFriends do
			local friendName = gsub(GetFriendInfo(friendIndex), "-.*", "")
			if friendName == arg1 then
				AcceptGroup()
				inGroup = true
				break
			end
		end

		if not inGroup then
			for guildIndex = 1, GetNumGuildMembers(true) do
				local guildMemberName = gsub(GetGuildRosterInfo(guildIndex), "-.*", "")
				if guildMemberName == arg1 then
					AcceptGroup()
					inGroup = true
					break
				end
			end
		end

	elseif event == "PARTY_MEMBERS_CHANGED" and hideStatic == true then
		StaticPopup_Hide("PARTY_INVITE")
		hideStatic = false
	end
end

function M:ForceCVars()
	if E.private.general.loot then
		if E.private.general.lootUnderMouse then
			E:DisableMover("LootFrameMover")
		else
			E:EnableMover("LootFrameMover")
		end
	end
end

function M:Initialize()
	--DB conversion
	if E.db.general.vendorGrays then E.db.bags.vendorGrays.enable = E.db.general.vendorGrays end

	self:LoadRaidMarker()
	self:LoadLoot()
	self:LoadLootRoll()
	self:LoadChatBubbles()
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ErrorFrameToggle")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "ErrorFrameToggle")
	-- self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "PVPMessageEnhancement")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "PVPMessageEnhancement")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL", "PVPMessageEnhancement")
	self:RegisterEvent("PARTY_INVITE_REQUEST", "AutoInvite")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "AutoInvite")
	self:RegisterEvent("CVAR_UPDATE", "ForceCVars")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ForceCVars")
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterModule(M:GetName(), InitializeCallback)