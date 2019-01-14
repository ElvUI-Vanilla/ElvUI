local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

local select, tonumber = select, tonumber
local match = string.match

local CreateFrame = CreateFrame
local GetNumRaidMembers = GetNumRaidMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local IsPartyLeader = IsPartyLeader
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid

local function CheckLeader(unit)
	if unit == "player" then
		return IsPartyLeader()
	elseif unit ~= "player" and (UnitInParty(unit) or UnitInRaid(unit)) then
		local gtype, index = match(unit, "(%D+)(%d+)")
		index = tonumber(index)
		if gtype == "party" and GetNumRaidMembers() == 0 then
			return GetPartyLeaderIndex() == index
		elseif gtype == "raid" and GetNumRaidMembers() > 0 then
			return select(2, GetRaidRosterInfo(index)) == 2
		end
	end
end

local function UpdateOverride(self)
	local element = self.LeaderIndicator

	if element.PreUpdate then
		element:PreUpdate()
	end

	local isLeader = CheckLeader(self.unit)

	if isLeader then
		element:Show()
	else
		element:Hide()
	end

	if element.PostUpdate then
		return element:PostUpdate(isLeader)
	end
end

function UF:Construct_RaidRoleFrames(frame)
	local anchor = CreateFrame("Frame", nil, frame.RaisedElementParent)
	frame.LeaderIndicator = anchor:CreateTexture(nil, "OVERLAY")
	frame.AssistantIndicator = anchor:CreateTexture(nil, "OVERLAY")
	frame.MasterLooterIndicator = anchor:CreateTexture(nil, "OVERLAY")

	E:Size(anchor, 24, 12)
	E:Size(frame.LeaderIndicator, 12)
	E:Size(frame.AssistantIndicator, 12)
	E:Size(frame.MasterLooterIndicator, 11)

	frame.LeaderIndicator.Override = UpdateOverride

	frame.LeaderIndicator.PostUpdate = UF.RaidRoleUpdate
	frame.AssistantIndicator.PostUpdate = UF.RaidRoleUpdate
	frame.MasterLooterIndicator.PostUpdate = UF.RaidRoleUpdate

	return anchor
end

function UF:Configure_RaidRoleIcons(frame)
	local raidRoleFrameAnchor = frame.RaidRoleFramesAnchor
	if not raidRoleFrameAnchor then return end

	if frame.db.raidRoleIcons.enable then
		raidRoleFrameAnchor:Show()
		if not frame:IsElementEnabled("LeaderIndicator") then
			frame:EnableElement("LeaderIndicator")
			frame:EnableElement("MasterLooterIndicator")
			frame:EnableElement("AssistantIndicator")
		end

		raidRoleFrameAnchor:ClearAllPoints()
		if frame.db.raidRoleIcons.position == "TOPLEFT" then
			E:Point(raidRoleFrameAnchor, "LEFT", frame, "TOPLEFT", 2, 0)
		else
			E:Point(raidRoleFrameAnchor, "RIGHT", frame, "TOPRIGHT", -2, 0)
		end
	elseif frame:IsElementEnabled("LeaderIndicator") then
		raidRoleFrameAnchor:Hide()
		frame:DisableElement("LeaderIndicator")
		frame:DisableElement("MasterLooterIndicator")
		frame:DisableElement("AssistantIndicator")
	end
end

function UF:RaidRoleUpdate()
	local anchor = self:GetParent()
	local frame = anchor:GetParent():GetParent()
	local leader = frame.LeaderIndicator
	local assistant = frame.AssistantIndicator
	local masterLooter = frame.MasterLooterIndicator

	if not leader or not masterLooter or not assistant then return end

	local db = frame.db
	local isLeader = leader:IsShown()
	local isMasterLooter = masterLooter:IsShown()
	local isAssist = assistant:IsShown()

	leader:ClearAllPoints()
	assistant:ClearAllPoints()
	masterLooter:ClearAllPoints()

	if db and db.raidRoleIcons then
		if isLeader and db.raidRoleIcons.position == "TOPLEFT" then
			E:Point(leader, "LEFT", anchor, "LEFT")
			E:Point(masterLooter, "RIGHT", anchor, "RIGHT")
		elseif isLeader and db.raidRoleIcons.position == "TOPRIGHT" then
			E:Point(leader, "RIGHT", anchor, "RIGHT")
			E:Point(masterLooter, "LEFT", anchor, "LEFT")
		elseif isAssist and db.raidRoleIcons.position == "TOPLEFT" then
			E:Point(assistant, "LEFT", anchor, "LEFT")
			E:Point(masterLooter, "RIGHT", anchor, "RIGHT")
		elseif isAssist and db.raidRoleIcons.position == "TOPRIGHT" then
			E:Point(assistant, "RIGHT", anchor, "RIGHT")
			E:Point(masterLooter, "LEFT", anchor, "LEFT")
		elseif isMasterLooter and db.raidRoleIcons.position == "TOPLEFT" then
			E:Point(masterLooter, "LEFT", anchor, "LEFT")
		else
			E:Point(masterLooter, "RIGHT", anchor, "RIGHT")
		end
	end
end