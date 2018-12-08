local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

--WoW API / Variables
local CreateFrame = CreateFrame

local ns = oUF
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_RaidRoleFrames(frame)
	local anchor = CreateFrame("Frame", nil, frame.RaisedElementParent)
	frame.LeaderIndicator = anchor:CreateTexture(nil, "OVERLAY")
	frame.AssistantIndicator = anchor:CreateTexture(nil, "OVERLAY")
	frame.MasterLooterIndicator = anchor:CreateTexture(nil, "OVERLAY")

	anchor:SetWidth(24)
	anchor:SetHeight(12)
	frame.LeaderIndicator:SetWidth(12)
	frame.LeaderIndicator:SetHeight(12)
	frame.AssistantIndicator:SetWidth(12)
	frame.AssistantIndicator:SetHeight(12)
	frame.MasterLooterIndicator:SetWidth(11)
	frame.MasterLooterIndicator:SetHeight(11)

	frame.LeaderIndicator.PostUpdate = UF.RaidRoleUpdate
	frame.AssistantIndicator.PostUpdate = UF.RaidRoleUpdate
	frame.MasterLooterIndicator.PostUpdate = UF.RaidRoleUpdate

	return anchor
end

function UF:Configure_RaidRoleIcons(frame)
	local raidRoleFrameAnchor = frame.RaidRoleFramesAnchor

	if frame.db.raidRoleIcons.enable then
		raidRoleFrameAnchor:Show()
		if not frame:IsElementEnabled("LeaderIndicator") then
			frame:EnableElement("LeaderIndicator")
			frame:EnableElement("MasterLooterIndicator")
			frame:EnableElement("AssistantIndicator")
		end

		raidRoleFrameAnchor:ClearAllPoints()
		if frame.db.raidRoleIcons.position == "TOPLEFT" then
			raidRoleFrameAnchor:SetPoint("LEFT", frame.Health, "TOPLEFT", 2, 0)
		else
			raidRoleFrameAnchor:SetPoint("RIGHT", frame, "TOPRIGHT", -2, 0)
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

	if not leader or not masterLooter or not assistant then return; end

	local db = frame.db
	local isLeader = leader:IsShown()
	local isMasterLooter = masterLooter:IsShown()
	local isAssist = assistant:IsShown()

	leader:ClearAllPoints()
	assistant:ClearAllPoints()
	masterLooter:ClearAllPoints()

	if db and db.raidRoleIcons then
		if isLeader and db.raidRoleIcons.position == "TOPLEFT" then
			leader:SetPoint("LEFT", anchor, "LEFT")
			masterLooter:SetPoint("RIGHT", anchor, "RIGHT")
		elseif isLeader and db.raidRoleIcons.position == "TOPRIGHT" then
			leader:SetPoint("RIGHT", anchor, "RIGHT")
			masterLooter:SetPoint("LEFT", anchor, "LEFT")
		elseif isAssist and db.raidRoleIcons.position == "TOPLEFT" then
			assistant:SetPoint("LEFT", anchor, "LEFT")
			masterLooter:SetPoint("RIGHT", anchor, "RIGHT")
		elseif isAssist and db.raidRoleIcons.position == "TOPRIGHT" then
			assistant:SetPoint("RIGHT", anchor, "RIGHT")
			masterLooter:SetPoint("LEFT", anchor, "LEFT")
		elseif isMasterLooter and db.raidRoleIcons.position == "TOPLEFT" then
			masterLooter:SetPoint("LEFT", anchor, "LEFT")
		else
			masterLooter:SetPoint("RIGHT", anchor, "RIGHT")
		end
	end
end