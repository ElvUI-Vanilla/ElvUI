local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

local ns = oUF
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

--WoW API / Variables
local CreateFrame = CreateFrame

function UF:Construct_RaidpetFrames()
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetWidth(UF.db.units.raidpet.width)
	self:SetHeight(UF.db.units.raidpet.height)

	self.RaisedElementParent = CreateFrame("Frame", nil, self)
	self.RaisedElementParent.TextureParent = CreateFrame("Frame", nil, self.RaisedElementParent)
	self.RaisedElementParent:SetFrameLevel(self:GetFrameLevel() + 100)

	self.Health = UF:Construct_HealthBar(self, true, true, "RIGHT")
	self.Name = UF:Construct_NameText(self)
	self.Portrait3D = UF:Construct_Portrait(self, "model")
	self.Portrait2D = UF:Construct_Portrait(self, "texture")
	self.Buffs = UF:Construct_Buffs(self)
	self.Debuffs = UF:Construct_Debuffs(self)
	self.AuraWatch = UF:Construct_AuraWatch(self)
	self.RaidDebuffs = UF:Construct_RaidDebuffs(self)
	self.DebuffHighlight = UF:Construct_DebuffHighlight(self)
	self.MouseGlow = UF:Construct_MouseGlow(self)
	self.TargetGlow = UF:Construct_TargetGlow(self)
	self.RaidTargetIndicator = UF:Construct_RaidIcon(self)
	self.Range = UF:Construct_Range(self)
	self.customTexts = {}

	UF:Update_StatusBars()
	UF:Update_FontStrings()

	self.unitframeType = "raidpet"

	UF:Update_RaidpetFrames(self, UF.db.units.raidpet)

	return self
end

function UF:RaidPetsSmartVisibility()
	if not self then self = this end
	if not self.db or (self.db and not self.db.enable) then return end

	local numMembers = GetNumRaidMembers()
	if numMembers > 1 then
		self:Show()
	else
		self:Hide()
	end
end

function UF:Update_RaidpetHeader(header, db)
	header.db = db

	if not header.positioned then
		header:ClearAllPoints()
		E:Point(header, "BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 574)

		E:CreateMover(header, header:GetName().."Mover", L["Raid Pet Frames"], nil, nil, nil, "ALL,RAID10,RAID25,RAID40")

		header:RegisterEvent("PLAYER_LOGIN")
		header:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		header:RegisterEvent("PARTY_MEMBERS_CHANGED")
		header:RegisterEvent("RAID_ROSTER_UPDATE")
		header:SetScript("OnEvent", UF.RaidPetsSmartVisibility)
		header.positioned = true
	end

	UF.RaidPetsSmartVisibility(header)
end

function UF:Update_RaidpetFrames(frame, db)
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
		frame.SHADOW_SPACING = 3

		frame.ORIENTATION = db.orientation --allow this value to change when unitframes position changes on screen?

		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.height

		frame.USE_POWERBAR = false
		frame.POWERBAR_DETACHED = false
		frame.USE_INSET_POWERBAR = false
		frame.USE_MINI_POWERBAR = false
		frame.USE_POWERBAR_OFFSET = false
		frame.POWERBAR_OFFSET = 0
		frame.POWERBAR_HEIGHT = 0
		frame.POWERBAR_WIDTH = 0

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width

		frame.CLASSBAR_YOFFSET = 0
		frame.BOTTOM_OFFSET = 0

		frame.VARIABLES_SET = true
	end

	UF:Configure_HealthBar(frame)

	UF:UpdateNameSettings(frame)

	UF:Configure_Portrait(frame)

	UF:EnableDisable_Auras(frame)
	UF:Configure_Auras(frame, "Buffs")
	UF:Configure_Auras(frame, "Debuffs")

	UF:Configure_RaidDebuffs(frame)

	UF:Configure_RaidIcon(frame)

	UF:Configure_DebuffHighlight(frame)

	UF:Configure_Range(frame)

	UF:UpdateAuraWatch(frame, true) --2nd argument is the petOverride

	UF:Configure_CustomTexts(frame)

	frame:UpdateAllElements("ElvUI_UpdateAllElements")
end

UF.headerstoload.raidpet = true