local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local mod = E:NewModule("NamePlates", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");
local CC = E:GetModule("ClassCache");

--Cache global variables
--Lua functions
local _G = _G
local pairs, tonumber = pairs, tonumber
local select = select
local gsub, match, split = string.gsub, string.match, string.split
local twipe = table.wipe
--WoW API / Variables
local CreateFrame = CreateFrame
local GetBattlefieldScore = GetBattlefieldScore
local GetNumBattlefieldScores = GetNumBattlefieldScores
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local SetCVar = SetCVar
local WorldFrame = WorldFrame
local WorldGetNumChildren, WorldGetChildren = WorldFrame.GetNumChildren, WorldFrame.GetChildren

local numChildren = 0
local isTarget = false
local BORDER = "Interface\\Tooltips\\Nameplate-Border"
local FSPAT = "^%s*$"
local queryList = {}

local RaidIconCoordinate = {
	[0] = {[0] = "STAR", [0.25] = "MOON"},
	[0.25] = {[0] = "CIRCLE", [0.25] = "SQUARE"},
	[0.5] = {[0] = "DIAMOND", [0.25] = "CROSS"},
	[0.75] = {[0] = "TRIANGLE", [0.25] = "SKULL"}
}

local healClasses = {
	["DRUID"] = true,
	["HUNTER"] = false,
	["MAGE"] = false,
	["PALADIN"] = true,
	["PRIEST"] = true,
	["ROGUE"] = false,
	["SHAMAN"] = true,
	["WARLOCK"] = false,
	["WARRIOR"] = false
}

mod.CreatedPlates = {}
mod.VisiblePlates = {}
mod.Healers = {}

function mod:CheckFilter(frame)
	--[[local db = E.global.nameplates["filter"][frame.UnitName]
	if db and db.enable then
		if db.hide then
			frame:Hide()
			return
		else
			if not frame:IsShown() then
				frame:Show()
			end

			if db.customColor then
				frame.CustomColor = db.color
				frame.HealthBar:SetStatusBarColor(db.color.r, db.color.g, db.color.b)
			else
				frame.CustomColor = nil
			end

			if db.customScale and db.customScale ~= 1 then
				frame.CustomScale = db.customScale
			else
				frame.CustomScale = nil
			end
		end
	elseif not frame:IsShown() then
		frame:Show()
	end]]
	return true
end

function mod:CheckBGHealers()
	local name, class, damageDone, healingDone, _
	for i = 1, GetNumBattlefieldScores() do
		name, _, _, _, _, _, _, _, _, class, damageDone, healingDone = GetBattlefieldScore(i)
		if name and class and healClasses[class] then
			name = match(name, "(.+)%-.+") or name
			if name and healingDone > (damageDone * 2) then
				self.Healers[name] = true
			elseif name and self.Healers[name] then
				self.Healers[name] = nil
			end
		end
	end
end

function mod:SetFrameScale(frame, scale)
	if frame.HealthBar.currentScale ~= scale then
		if frame.HealthBar.scale:IsPlaying() then
			frame.HealthBar.scale:Stop()
		end
		frame.HealthBar.scale.width:SetChange(self.db.units[frame.UnitType].healthbar.width * scale)
		frame.HealthBar.scale.height:SetChange(self.db.units[frame.UnitType].healthbar.height * scale)
		frame.HealthBar.scale:Play()
		frame.HealthBar.currentScale = scale
	end
end

function mod:SetTargetFrame(frame)
	if isTarget then return end

	local targetExists = UnitExists("target") == 1
	if targetExists and frame:GetParent():IsShown() and frame:GetParent():GetAlpha() == 1 then
		if self.db.useTargetScale then
			self:SetFrameScale(frame, (frame.CustomScale and frame.CustomScale * self.db.targetScale) or self.db.targetScale)
		end
		frame.isTarget = true
		frame.unit = "target"
	--	frame.guid = UnitGUID("target")

		if self.db.units[frame.UnitType].healthbar.enable ~= true then
			frame.Name:ClearAllPoints()
			frame.Level:ClearAllPoints()
			frame.HealthBar.r, frame.HealthBar.g, frame.HealthBar.b = nil, nil, nil
			self:ConfigureElement_HealthBar(frame)
			self:ConfigureElement_CastBar(frame)
			self:ConfigureElement_Glow(frame)
			self:ConfigureElement_Level(frame)
			self:ConfigureElement_Name(frame)

			self:UpdateElement_All(frame, true)
		end

		--[[if UnitCastingInfo("target") then
			frame:GetScript("OnEvent")(frame, "UNIT_SPELLCAST_START", "target")
		elseif UnitChannelInfo("target") then
			frame:GetScript("OnEvent")(frame, "UNIT_SPELLCAST_CHANNEL_START", "target")
		end]]

		frame:SetAlpha(1)

		mod:UpdateElement_AurasByUnitID("target")
	elseif frame.isTarget then
		if self.db.useTargetScale then
			self:SetFrameScale(frame, frame.CustomScale or frame.ThreatScale or 1)
		end
		frame.isTarget = nil
		frame.unit = nil
	--	frame.guid = nil
		if self.db.units[frame.UnitType].healthbar.enable ~= true then
			self:UpdateAllFrame(frame)
		end

		if targetExists then
			frame:SetAlpha(self.db.nonTargetTransparency)
		else
			frame:SetAlpha(1)
		end
	else
		if targetExists then
			frame:SetAlpha(self.db.nonTargetTransparency)
		else
			frame:SetAlpha(1)
		end
	end

	mod:UpdateElement_HealthColor(frame)
	mod:UpdateElement_Glow(frame)
	mod:UpdateElement_CPoints(frame)

	return frame.isTarget
end

function mod:GetNumVisiblePlates()
	local i = 0
	for _ in pairs(mod.VisiblePlates) do
		i = i + 1
	end
	return i
end

function mod:StyleFrame(parent, noBackdrop, point)
	point = point or parent
	local noscalemult = E.mult * UIParent:GetScale()

	if point.bordertop then return end

	if not noBackdrop then
		point.backdrop = parent:CreateTexture(nil, "BACKGROUND")
		point.backdrop:SetAllPoints(point)
		point.backdrop:SetTexture(unpack(E["media"].backdropfadecolor))
	end

	if E.PixelMode then
		point.bordertop = parent:CreateTexture()
		E:Point(point.bordertop, "TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		E:Point(point.bordertop, "TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		E:Height(point.bordertop, noscalemult)
		point.bordertop:SetTexture(unpack(E["media"].bordercolor))

		point.borderbottom = parent:CreateTexture()
		E:Point(point.borderbottom, "BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		E:Point(point.borderbottom, "BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		E:Height(point.borderbottom, noscalemult)
		point.borderbottom:SetTexture(unpack(E["media"].bordercolor))

		point.borderleft = parent:CreateTexture()
		E:Point(point.borderleft, "TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		E:Point(point.borderleft, "BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		E:Width(point.borderleft, noscalemult)
		point.borderleft:SetTexture(unpack(E["media"].bordercolor))

		point.borderright = parent:CreateTexture()
		E:Point(point.borderright, "TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		E:Point(point.borderright, "BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		E:Width(point.borderright, noscalemult)
		point.borderright:SetTexture(unpack(E["media"].bordercolor))
	else
		point.bordertop = parent:CreateTexture(nil, "OVERLAY")
		E:Point(point.bordertop, "TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult*2)
		E:Point(point.bordertop, "TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult*2)
		E:Height(point.bordertop, noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.bordertop.backdrop = parent:CreateTexture()
		E:Point(point.bordertop.backdrop, "TOPLEFT", point.bordertop, "TOPLEFT", noscalemult, noscalemult)
		E:Point(point.bordertop.backdrop, "TOPRIGHT", point.bordertop, "TOPRIGHT", -noscalemult, noscalemult)
		E:Height(point.bordertop.backdrop, noscalemult * 3)
		point.bordertop.backdrop:SetTexture(0, 0, 0)

		point.borderbottom = parent:CreateTexture(nil, "OVERLAY")
		E:Point(point.borderbottom, "BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult*2)
		E:Point(point.borderbottom, "BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult*2)
		E:Height(point.borderbottom, noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom.backdrop = parent:CreateTexture()
		E:Point(point.borderbottom.backdrop, "BOTTOMLEFT", point.borderbottom, "BOTTOMLEFT", noscalemult, -noscalemult)
		E:Point(point.borderbottom.backdrop, "BOTTOMRIGHT", point.borderbottom, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		E:Height(point.borderbottom.backdrop, noscalemult * 3)
		point.borderbottom.backdrop:SetTexture(0, 0, 0)

		point.borderleft = parent:CreateTexture(nil, "OVERLAY")
		E:Point(point.borderleft, "TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		E:Point(point.borderleft, "BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
		E:Width(point.borderleft, noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderleft.backdrop = parent:CreateTexture()
		E:Point(point.borderleft.backdrop, "TOPLEFT", point.borderleft, "TOPLEFT", -noscalemult, noscalemult)
		E:Point(point.borderleft.backdrop, "BOTTOMLEFT", point.borderleft, "BOTTOMLEFT", -noscalemult, -noscalemult)
		E:Width(point.borderleft.backdrop, noscalemult * 3)
		point.borderleft.backdrop:SetTexture(0, 0, 0)

		point.borderright = parent:CreateTexture(nil, "OVERLAY")
		E:Point(point.borderright, "TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		E:Point(point.borderright, "BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
		E:Width(point.borderright, noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))

		point.borderright.backdrop = parent:CreateTexture()
		E:Point(point.borderright.backdrop, "TOPRIGHT", point.borderright, "TOPRIGHT", noscalemult, noscalemult)
		E:Point(point.borderright.backdrop, "BOTTOMRIGHT", point.borderright, "BOTTOMRIGHT", noscalemult, -noscalemult)
		E:Width(point.borderright.backdrop, noscalemult * 3)
		point.borderright.backdrop:SetTexture(0, 0, 0)
	end
end

function mod:RoundColors(r, g, b)
	return floor(r*100+.5) / 100, floor(g*100+.5) / 100, floor(b*100+.5) / 100
end

function mod:UnitClass(name, type)
	--[[if E.private.general.classCache then
		if type == "FRIENDLY_PLAYER" then
			local _, class = UnitClass(name)
			if class then
				return class
			else
				local name, realm = split("-", name)
				return CC:GetClassByName(name, realm)
			end
		end
	else
		if type == "FRIENDLY_PLAYER" then
			return select(2, UnitClass(name))
		end
	end--]]
end

function mod:UnitDetailedThreatSituation(frame)
	return false
end

function mod:UnitLevel(frame)
	local level, boss = frame.oldLevel:GetObjectType() == "FontString" and tonumber(frame.oldLevel:GetText()) or false, frame.BossIcon:IsShown()
	if boss or not level then
		return "??", 0.9, 0, 0
	else
		return level, frame.oldLevel:GetTextColor()
	end
end

function mod:GetUnitInfo(frame)
	if UnitExists("target") == 1 and frame:GetParent():IsShown() and frame:GetParent():GetAlpha() == 1 then
		if UnitIsPlayer("target") then
			if UnitIsEnemy("target", "player") then
				return 2, "ENEMY_PLAYER"
			else
				return 5, "FRIENDLY_PLAYER"
			end
		else
			if UnitIsEnemy("target", "player") then
				return 2, "ENEMY_NPC"
			elseif UnitReaction("target", "player") == 4 then
				return 4, "ENEMY_NPC"
			else
				return 5, "FRIENDLY_NPC"
			end
		end
	end

	local r, g, b = mod:RoundColors(frame.oldHealthBar:GetStatusBarColor())
	if r == 1 and g == 0 and b == 0 then
		return 2, "ENEMY_NPC"
	elseif r == 0 and g == 0 and b == 1 then
		return 5, "FRIENDLY_PLAYER"
	elseif r == 0 and g == 1 and b == 0 then
		return 5, "FRIENDLY_NPC"
	elseif r == 1 and g == 1 and b == 0 then
		return 4, "ENEMY_NPC"
	end
end

function mod:OnShow(self)
	isTarget = false

	self:SetWidth(0.01)
	self:SetHeight(0.01)

	mod.VisiblePlates[self.UnitFrame] = true

	self.UnitFrame.UnitName = gsub(self.UnitFrame.oldName:GetText(), FSPAT, "")
	local unitReaction, unitType = mod:GetUnitInfo(self.UnitFrame)
	self.UnitFrame.UnitType = unitType
	self.UnitFrame.UnitClass = mod:UnitClass(self.UnitFrame.oldName:GetText(), unitType)
	self.UnitFrame.UnitReaction = unitReaction

	if not self.UnitFrame.UnitClass then
		queryList[self.UnitFrame.UnitName] = self.UnitFrame
	end

	if unitType == "ENEMY_NPC" and self.UnitFrame.UnitClass then
		unitType = "ENEMY_PLAYER"
		self.UnitFrame.UnitType = unitType
	end

	if not mod:CheckFilter(self.UnitFrame) then return end

	if unitType == "ENEMY_PLAYER" then
		mod:UpdateElement_HealerIcon(self.UnitFrame)
	end

	self.UnitFrame.Level:ClearAllPoints()
	self.UnitFrame.Name:ClearAllPoints()

	mod:ConfigureElement_HealthBar(self.UnitFrame)
	if mod.db.units[unitType].healthbar.enable then
		mod:ConfigureElement_CastBar(self.UnitFrame)
		mod:ConfigureElement_Glow(self.UnitFrame)

		if mod.db.units[unitType].buffs.enable then
			self.UnitFrame.Buffs.db = mod.db.units[unitType].buffs
			mod:UpdateAuraIcons(self.UnitFrame.Buffs)
		end

		if mod.db.units[unitType].debuffs.enable then
			self.UnitFrame.Debuffs.db = mod.db.units[unitType].debuffs
			mod:UpdateAuraIcons(self.UnitFrame.Debuffs)
		end
	end

	if mod.db.units[unitType].healthbar.enable then
		mod:ConfigureElement_Name(self.UnitFrame)
		mod:ConfigureElement_Level(self.UnitFrame)
	else
		mod:ConfigureElement_Level(self.UnitFrame)
		mod:ConfigureElement_Name(self.UnitFrame)
	end

	--[[if(mod.db.units[unitType].castbar.enable) then
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_START")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		self.UnitFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	end]]

	mod:UpdateElement_All(self.UnitFrame)

	self.UnitFrame:Show()
end

function mod:OnHide(self)
	--local self = this
	mod.VisiblePlates[self.UnitFrame] = nil

	self.UnitFrame.unit = nil

	mod:HideAuraIcons(self.UnitFrame.Buffs)
	mod:HideAuraIcons(self.UnitFrame.Debuffs)
	self.UnitFrame.Glow.r, self.UnitFrame.Glow.g, self.UnitFrame.Glow.b = nil, nil, nil
	self.UnitFrame.Glow:Hide()
	self.UnitFrame.HealthBar.r, self.UnitFrame.HealthBar.g, self.UnitFrame.HealthBar.b = nil, nil, nil
	self.UnitFrame.HealthBar:Hide()
	--self.UnitFrame.CastBar:Hide()
	self.UnitFrame.Level:ClearAllPoints()
	self.UnitFrame.Level:SetText("")
	self.UnitFrame.Name:ClearAllPoints()
	self.UnitFrame.Name:SetText("")
	self.UnitFrame.CPoints:Hide()
	self.UnitFrame:Hide()
	self.UnitFrame.isTarget = nil
	self.UnitFrame.displayedUnit = nil
	self.ThreatData = nil
	self.UnitFrame.UnitName = nil
	self.UnitFrame.UnitType = nil
	self.UnitFrame.ThreatScale = nil

	self.UnitFrame.ThreatReaction = nil
	self.UnitFrame.guid = nil
	self.UnitFrame.RaidIconType = nil
	self.UnitFrame.CustomColor = nil
	self.UnitFrame.CustomScale = nil
end

function mod:UpdateAllFrame(frame)
	mod:OnHide(frame:GetParent())
	mod:OnShow(frame:GetParent())
end

function mod:ConfigureAll()
	if E.private.nameplates.enable ~= true then return end

	self:ForEachPlate("UpdateAllFrame")
	self:UpdateCVars()
end

function mod:ForEachPlate(functionToRun, ...)
	for frame in pairs(self.CreatedPlates) do
		if frame and frame.UnitFrame then
			self[functionToRun](self, frame.UnitFrame, unpack(arg))
		end
	end
end

function mod:UpdateElement_All(frame, noTargetFrame)
	if self.db.units[frame.UnitType].healthbar.enable or frame.isTarget then
		self:UpdateElement_Health(frame)
		self:UpdateElement_HealthColor(frame)
		self:UpdateElement_Auras(frame)
	end
	self:UpdateElement_RaidIcon(frame)
	self:UpdateElement_HealerIcon(frame)
	self:UpdateElement_Name(frame)
	self:UpdateElement_Level(frame)

	if not noTargetFrame then
		mod:ScheduleTimer("ForEachPlate", 0.25, 1, "SetTargetFrame")
	end
end

function mod:OnCreated(frame)
	isTarget = false
	local HealthBar, CastBar = frame:GetChildren()
	local Border, Highlight, Name, Level, BossIcon, RaidIcon = frame:GetRegions()

	frame.UnitFrame = CreateFrame("Button", nil, frame)
	E:Size(frame.UnitFrame, 100, 20)
	E:Point(frame.UnitFrame, "CENTER", 0, 0)
	frame.UnitFrame:SetScript("OnEvent", self.OnEvent)
	frame.UnitFrame:SetScript("OnClick", function()
		frame:Click()
	end)

	frame.UnitFrame.HealthBar = self:ConstructElement_HealthBar(frame.UnitFrame)
	frame.UnitFrame.CastBar = self:ConstructElement_CastBar(frame.UnitFrame)
	frame.UnitFrame.Level = self:ConstructElement_Level(frame.UnitFrame)
	frame.UnitFrame.Name = self:ConstructElement_Name(frame.UnitFrame)
	frame.UnitFrame.Glow = self:ConstructElement_Glow(frame.UnitFrame)
	frame.UnitFrame.Buffs = self:ConstructElement_Auras(frame.UnitFrame, "LEFT")
	frame.UnitFrame.Debuffs = self:ConstructElement_Auras(frame.UnitFrame, "RIGHT")
	frame.UnitFrame.HealerIcon = self:ConstructElement_HealerIcon(frame.UnitFrame)
	frame.UnitFrame.CPoints = self:ConstructElement_CPoints(frame.UnitFrame)

	--self:QueueObject(CastBarBorder)
	--self:QueueObject(CastBarIcon)
	self:QueueObject(HealthBar)
	--self:QueueObject(CastBar)
	self:QueueObject(Level)
	self:QueueObject(Name)
	self:QueueObject(Border)
	self:QueueObject(Highlight)
	--CastBar:Kill()
	--CastBarIcon:SetParent(E.HiddenFrame)
	BossIcon:SetAlpha(0)

	frame.UnitFrame.oldHealthBar = HealthBar
	frame.UnitFrame.oldCastBar = CastBar
	--frame.UnitFrame.oldCastBar.Icon = CastBarIcon
	frame.UnitFrame.oldName = Name
	frame.UnitFrame.oldHighlight = Highlight
	frame.UnitFrame.oldLevel = Level

	RaidIcon:SetParent(frame.UnitFrame)
	frame.UnitFrame.RaidIcon = RaidIcon

	frame.UnitFrame.BossIcon = BossIcon

	self:OnShow(frame)

	HookScript(frame, "OnShow", function() self:OnShow(this) end)
	HookScript(frame, "OnHide", function() self:OnHide(this) end)

	HookScript(HealthBar, "OnValueChanged", self.UpdateElement_HealthOnValueChanged)

	self.CreatedPlates[frame] = true
	self.VisiblePlates[frame.UnitFrame] = true
end

function mod:OnEvent(event, unit, ...)
	if not self.unit then return end

	mod:UpdateElement_Cast(self, event, unit, unpack(arg))
end

function mod:QueueObject(object)
	local objectType = object:GetObjectType()
	if objectType == "Texture" then
		object:SetTexture("")
		object:SetTexCoord(0, 0, 0, 0)
	elseif objectType == "FontString" then
		E:Width(object, 0.001)
	elseif objectType == "StatusBar" then
		object:SetStatusBarTexture("")
	end
	object:Hide()
end

function mod:OnUpdate(elapsed)
	local count = WorldGetNumChildren(WorldFrame)
	if count ~= numChildren then
		for i = numChildren + 1, count do
			local frame = select(i, WorldGetChildren(WorldFrame))
			local region = frame:GetRegions()

			if(not mod.CreatedPlates[frame] and region and region:GetObjectType() == "Texture" and region:GetTexture() == BORDER) then
				mod:OnCreated(frame)
			end
		end
		numChildren = count
	end

	local i = 0
	for frame in pairs(mod.VisiblePlates) do
		i = i + 1

		local getTarget = mod:SetTargetFrame(frame)
		if not getTarget then
			frame:GetParent():SetAlpha(1)
		end

		if i == mod:GetNumVisiblePlates() then
			isTarget = true
		end
	end
end

function mod:CheckRaidIcon(frame)
	if frame.RaidIcon:IsShown() then
		local ux, uy = frame.RaidIcon:GetTexCoord()
		frame.RaidIconType = RaidIconCoordinate[ux][uy]
	else
		frame.RaidIconType = nil
	end
end

function mod:SearchNameplateByGUID(guid)
	for frame in pairs(self.VisiblePlates) do
		if frame and frame:IsShown() and frame.guid == guid then
			return frame
		end
	end
end

function mod:SearchNameplateByName(sourceName)
	if not sourceName then return end
	local SearchFor = strsplit("-", sourceName)
	for frame in pairs(self.VisiblePlates) do
		if frame and frame:IsShown() and frame.UnitName == SearchFor and RAID_CLASS_COLORS[frame.UnitClass] then
			return frame
		end
	end
end

function mod:SearchNameplateByIconName(raidIcon)
	for frame in pairs(self.VisiblePlates) do
		self:CheckRaidIcon(frame)
		if frame and frame:IsShown() and frame.RaidIcon:IsShown() and (frame.RaidIconType == raidIcon) then
			return frame
		end
	end
end

function mod:SearchForFrame(guid, raidIcon, name)
	local frame
	if guid then frame = self:SearchNameplateByGUID(guid) end
	if (not frame) and name then frame = self:SearchNameplateByName(name) end
	if (not frame) and raidIcon then frame = self:SearchNameplateByIconName(raidIcon) end

	return frame
end

function mod:UpdateCVars()
	-- SetCVar("showVKeyCastbar", "1")
	-- SetCVar("nameplateAllowOverlap", self.db.motionType == "STACKED" and "0" or "1")
end

local function CopySettings(from, to)
	for setting, value in pairs(from) do
		if type(value) == "table" then
			CopySettings(from[setting], to[setting])
		else
			if to[setting] ~= nil then
				to[setting] = from[setting]
			end
		end
	end
end

function mod:ResetSettings(unit)
	CopySettings(P.nameplates.units[unit], self.db.units[unit])
end

function mod:CopySettings(from, to)
	if from == to then return end

	CopySettings(self.db.units[from], self.db.units[to])
end

function mod:PLAYER_ENTERING_WORLD()
	self:CleanAuraLists()
	twipe(self.Healers)
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == "pvp" and self.db.units.ENEMY_PLAYER.markHealers then
		self.CheckHealerTimer = self:ScheduleRepeatingTimer("CheckBGHealers", 3)
		self:CheckBGHealers()
	else
		if self.CheckHealerTimer then
			self:CancelTimer(self.CheckHealerTimer)
			self.CheckHealerTimer = nil
		end
	end
end

function mod:PLAYER_TARGET_CHANGED()
	isTarget = false
end

function mod:UNIT_AURA(_, unit)
	if unit == "target" then
		self:UpdateElement_AurasByUnitID("target")
	end
end

function mod:PLAYER_COMBO_POINTS()
	self:ForEachPlate("UpdateElement_CPoints")
end

function mod:PLAYER_REGEN_DISABLED()
	if self.db.showFriendlyCombat == "TOGGLE_ON" then
		ShowFriendNameplates();
	elseif self.db.showFriendlyCombat == "TOGGLE_OFF" then
		HideFriendNameplates();
	end

	if self.db.showEnemyCombat == "TOGGLE_ON" then
		ShowNameplates();
	elseif self.db.showEnemyCombat == "TOGGLE_OFF" then
		HideNameplates();
	end
end

function mod:PLAYER_REGEN_ENABLED()
	self:CleanAuraLists()
	if self.db.showFriendlyCombat == "TOGGLE_ON" then
		HideFriendNameplates();
	elseif self.db.showFriendlyCombat == "TOGGLE_OFF" then
		ShowFriendNameplates();
	end

	if self.db.showEnemyCombat == "TOGGLE_ON" then
		HideNameplates();
	elseif self.db.showEnemyCombat == "TOGGLE_OFF" then
		ShowNameplates();
	end
end

function mod:ClassCacheQueryResult(_, name, class)
	if queryList[name] then
		local frame = queryList[name]

		if frame.UnitType then
			if frame.UnitType == "ENEMY_NPC" then
				frame.UnitType = "ENEMY_PLAYER"
			end
			frame.UnitClass = class

			if self.db.units[frame.UnitType].healthbar.enable then
				self:UpdateElement_HealthColor(frame)
			end
			self:UpdateElement_Name(frame)
		end

		queryList[name] = nil
	end
end

function mod:Initialize()
	self.db = E.db["nameplates"]
	if E.private["nameplates"].enable ~= true then return end

	self:UpdateCVars()

	self.Frame = CreateFrame("Frame"):SetScript("OnUpdate", self.OnUpdate)

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	--self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	--self:RegisterEvent("UNIT_AURA")
	--self:RegisterEvent("PLAYER_COMBO_POINTS")

	self:RegisterMessage("ClassCacheQueryResult")

	E.NamePlates = self
end

local function InitializeCallback()
	mod:Initialize()
end

E:RegisterModule(mod:GetName(), InitializeCallback)