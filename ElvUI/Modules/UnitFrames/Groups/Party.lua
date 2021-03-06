local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

local ns = oUF
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

--Cache global variables
--Lua functions
local _G = _G

--WoW API / Variables
local CreateFrame = CreateFrame
local GetNumRaidMembers = GetNumRaidMembers
local UnitInRaid = UnitInRaid

function UF:Construct_PartyFrames()
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.RaisedElementParent = CreateFrame("Frame", nil, self)
	self.RaisedElementParent.TextureParent = CreateFrame("Frame", nil, self.RaisedElementParent)
	self.RaisedElementParent:SetFrameLevel(self:GetFrameLevel() + 100)
	self.BORDER = E.Border
	self.SPACING = E.Spacing
	self.SHADOW_SPACING = 3
	if self.isChild then
		self.Health = UF:Construct_HealthBar(self, true)

		self.MouseGlow = UF:Construct_MouseGlow(self)
		self.TargetGlow = UF:Construct_TargetGlow(self)
		self.Name = UF:Construct_NameText(self)
		self.RaidTargetIndicator = UF:Construct_RaidIcon(self)

		self.originalParent = self:GetParent()

		local childDB = UF.db.units.party.petsGroup
		self.childType = "pet"
		if self == _G[self.originalParent:GetName().."Target"] then
			childDB = UF.db.units.party.targetsGroup
			self.childType = "target"
		end

		self.unitframeType = "party"..self.childType

		self:SetWidth(childDB.width)
		self:SetHeight(childDB.height)
	else
		self:SetWidth(UF.db.units.party.width)
		self:SetHeight(UF.db.units.party.height)

		self.Health = UF:Construct_HealthBar(self, true, true, "RIGHT")

		self.Power = UF:Construct_PowerBar(self, true, true, "LEFT")
		self.Power.frequentUpdates = false

		self.Portrait3D = UF:Construct_Portrait(self, "model")
		self.Portrait2D = UF:Construct_Portrait(self, "texture")
		self.InfoPanel = UF:Construct_InfoPanel(self)
		self.Name = UF:Construct_NameText(self)
		self.Buffs = UF:Construct_Buffs(self)
		self.Debuffs = UF:Construct_Debuffs(self)
		self.AuraWatch = UF:Construct_AuraWatch(self)
		self.RaidDebuffs = UF:Construct_RaidDebuffs(self)
		self.DebuffHighlight = UF:Construct_DebuffHighlight(self)
		self.RaidRoleFramesAnchor = UF:Construct_RaidRoleFrames(self)
		self.MouseGlow = UF:Construct_MouseGlow(self)
		self.TargetGlow = UF:Construct_TargetGlow(self)
		self.RaidTargetIndicator = UF:Construct_RaidIcon(self)
		self.GPS = UF:Construct_GPS(self)
		self.Castbar = UF:Construct_Castbar(self)
		self.customTexts = {}
		self.unitframeType = "party"
	end

	self.Range = UF:Construct_Range(self)

	UF:Update_StatusBars()
	UF:Update_FontStrings()

	UF:Update_PartyFrames(self, UF.db.units.party)

	return self
end

function UF:Update_PartyHeader(header, db)
	header.db = db

	if not header.positioned then
		header:ClearAllPoints()
		E:Point(header, "BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 195)

		E:CreateMover(header, header:GetName().."Mover", L["Party Frames"], nil, nil, nil, "ALL,PARTY")
		header.positioned = true

		header:RegisterEvent("PLAYER_LOGIN")
		header:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		header:RegisterEvent("PARTY_MEMBERS_CHANGED")
		header:RegisterEvent("RAID_ROSTER_UPDATE")
		header:SetScript("OnEvent", UF.PartySmartVisibility)
		header.positioned = true
	end

	UF.PartySmartVisibility(header)
end

function UF:PartySmartVisibility()
	if not self then self = this end
	if not self.db or (self.db and not self.db.enable) then return end

	local numMembers = GetNumRaidMembers()
	if numMembers < 1 then
		self:Show()
	else
		self:Hide()
	end
end

function UF:Update_PartyFrames(frame, db)
	frame.db = db

	frame.Portrait = frame.Portrait or (db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D)
	frame.colors = ElvUF.colors
	frame:RegisterForClicks(self.db.targetOnMouseDown and "LeftButtonDown" or "LeftButtonUp", self.db.targetOnMouseDown and "RightButtonDown" or "RightButtonUp")

	do
		if self.thinBorders then
			frame.SPACING = 0
			frame.BORDER = E.mult
		else
			frame.BORDER = E.Border
			frame.SPACING = E.Spacing
		end

		frame.ORIENTATION = db.orientation --allow this value to change when unitframes position changes on screen?
		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.infoPanel.enable and (db.height + db.infoPanel.height) or db.height

		frame.USE_POWERBAR = db.power.enable
		frame.POWERBAR_DETACHED = db.power.detachFromFrame
		frame.USE_INSET_POWERBAR = not frame.POWERBAR_DETACHED and db.power.width == "inset" and frame.USE_POWERBAR
		frame.USE_MINI_POWERBAR = (not frame.POWERBAR_DETACHED and db.power.width == "spaced" and frame.USE_POWERBAR)
		frame.USE_POWERBAR_OFFSET = db.power.offset ~= 0 and frame.USE_POWERBAR and not frame.POWERBAR_DETACHED
		frame.POWERBAR_OFFSET = frame.USE_POWERBAR_OFFSET and db.power.offset or 0

		frame.POWERBAR_HEIGHT = not frame.USE_POWERBAR and 0 or db.power.height
		frame.POWERBAR_WIDTH = frame.USE_MINI_POWERBAR and (frame.UNIT_WIDTH - (frame.BORDER*2))/2 or (frame.POWERBAR_DETACHED and db.power.detachedWidth or (frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2)))

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width
		frame.CLASSBAR_YOFFSET = 0

		frame.USE_INFO_PANEL = not frame.USE_MINI_POWERBAR and not frame.USE_POWERBAR_OFFSET and db.infoPanel.enable
		frame.INFO_PANEL_HEIGHT = frame.USE_INFO_PANEL and db.infoPanel.height or 0

		frame.BOTTOM_OFFSET = UF:GetHealthBottomOffset(frame)

		frame.VARIABLES_SET = true
	end

	if frame.isChild then
		frame.USE_PORTAIT = false
		frame.USE_PORTRAIT_OVERLAY = false
		frame.PORTRAIT_WIDTH = 0
		frame.USE_POWERBAR = false
		frame.USE_INSET_POWERBAR = false
		frame.USE_MINI_POWERBAR = false
		frame.USE_POWERBAR_OFFSET = false
		frame.POWERBAR_OFFSET = 0

		frame.POWERBAR_HEIGHT = 0
		frame.POWERBAR_WIDTH = 0

		frame.BOTTOM_OFFSET = 0

		local childDB = db.petsGroup
		if frame.childType == "target" then
			childDB = db.targetsGroup
		end

		if not frame.originalParent.childList then
			frame.originalParent.childList = {}
		end
		frame.originalParent.childList[frame] = true

		if childDB.enable then
			frame:SetParent(frame.originalParent)
			RegisterUnitWatch(frame)
			E:Size(frame, childDB.width, childDB.height)
			frame:ClearAllPoints()
			E:Point(frame, E.InversePoints[childDB.anchorPoint], frame.originalParent, childDB.anchorPoint, childDB.xOffset, childDB.yOffset)
		else
			UnregisterUnitWatch(frame)
			frame:SetParent(E.HiddenFrame)
		end

		UF:Configure_HealthBar(frame)

		UF:Configure_RaidIcon(frame)

		UF:UpdateNameSettings(frame, frame.childType)
	else

		E:Size(frame, frame.UNIT_WIDTH, frame.UNIT_HEIGHT)

		UF:Configure_InfoPanel(frame)
		UF:Configure_HealthBar(frame)

		UF:UpdateNameSettings(frame)

		UF:Configure_Power(frame)

		UF:Configure_Portrait(frame)

		UF:EnableDisable_Auras(frame)
		UF:Configure_Auras(frame, "Buffs")
		UF:Configure_Auras(frame, "Debuffs")

		UF:Configure_RaidDebuffs(frame)

		UF:Configure_Castbar(frame)

		UF:Configure_RaidIcon(frame)

		UF:Configure_DebuffHighlight(frame)

		UF:Configure_GPS(frame)

		UF:Configure_RaidRoleIcons(frame)

		UF:UpdateAuraWatch(frame)

		UF:Configure_CustomTexts(frame)
	end

	UF:Configure_Range(frame)

	frame:UpdateAllElements("ElvUI_UpdateAllElements")
end

UF.headerstoload.party = {nil, "ELVUI_UNITPET, ELVUI_UNITTARGET"}