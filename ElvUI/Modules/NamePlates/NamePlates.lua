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
--local UnitClass = UnitClass
local UnitExists = UnitExists
--local SetCVar = SetCVar
local WorldFrame = WorldFrame
local WorldGetNumChildren, WorldGetChildren = WorldFrame.GetNumChildren, WorldFrame.GetChildren

local numChildren = 0
local BORDER = "Interface\\Tooltips\\Nameplate-Border"
local FSPAT = "^%s*$"
local queryList = {}

local RaidIconCoordinate = {
	[0] = {[0] = "STAR", [0.25] = "MOON"},
	[0.25] = {[0] = "CIRCLE", [0.25] = "SQUARE"},
	[0.5] = {[0] = "DIAMOND", [0.25] = "CROSS"},
	[0.75] = {[0] = "TRIANGLE", [0.25] = "SKULL"}
}

mod.CreatedPlates = {}
mod.VisiblePlates = {}

function mod:GetPlateFrameLevel(frame)
	local plateLevel
	if frame.plateID then
		plateLevel = frame.plateID*mod.levelStep
	end
	return plateLevel
end

function mod:SetPlateFrameLevel(frame, level, isTarget)
	if frame and level then
		if isTarget then
			level = 890 --10 higher than the max calculated level of 880
		elseif frame.FrameLevelChanged then
			--calculate Style Filter FrameLevelChanged leveling
			--level method: (10*(40*2)) max 800 + max 80 (40*2) = max 880
			--highest possible should be level 880 and we add 1 to all so 881
			local leveledCount = mod.CollectedFrameLevelCount or 1
			level = (frame.FrameLevelChanged*(40*mod.levelStep)) + (leveledCount*mod.levelStep)
		end

		frame:SetFrameLevel(level+1)
		frame.HealthBar:SetFrameLevel(level+1)
		frame.Glow:SetFrameLevel(frame:GetFrameLevel()-1)
		frame.Buffs:SetFrameLevel(level+1)
		frame.Debuffs:SetFrameLevel(level+1)
	end
end

function mod:ResetNameplateFrameLevel(frame)
	local isTarget = frame.isTarget --frame.isTarget is not the same here so keep this.
	local plateLevel = mod:GetPlateFrameLevel(frame)
	if plateLevel then
		if frame.FrameLevelChanged then --keep how many plates we change, this is reset to 1 post-ResetNameplateFrameLevel
			mod.CollectedFrameLevelCount = (mod.CollectedFrameLevelCount and mod.CollectedFrameLevelCount + 1) or 1
		end
		self:SetPlateFrameLevel(frame, plateLevel, isTarget)
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
	if frame.isTarget then
		if not frame.isTargetChanged then
			frame.isTargetChanged = true

			mod:SetPlateFrameLevel(frame, mod:GetPlateFrameLevel(frame), true)

			if self.db.useTargetScale then
				self:SetFrameScale(frame, (frame.ThreatScale or 1) * self.db.targetScale)
			end

			if not frame.isGroupUnit then
				frame.unit = "target"

			--	self:RegisterEvents(frame)
			end

			if self.db.units[frame.UnitType].healthbar.enable ~= true and self.db.alwaysShowTargetHealth then
				frame.Name:ClearAllPoints()
				frame.Level:ClearAllPoints()
				frame.HealthBar.r, frame.HealthBar.g, frame.HealthBar.b = nil, nil, nil
				self:ConfigureElement_HealthBar(frame)
			--	self:ConfigureElement_CastBar(frame)
				self:ConfigureElement_Glow(frame)
				self:ConfigureElement_Highlight(frame)
				self:ConfigureElement_Level(frame)
				self:ConfigureElement_Name(frame)
			--	self:RegisterEvents(frame)
				self:UpdateElement_All(frame, true)
			end

			if self.hasTarget then
				frame:SetAlpha(1)
			end

			-- TEST
			mod:UpdateElement_Highlight(frame)
		--	mod:UpdateElement_CPoints(frame)
			mod:UpdateElement_Filters(frame, "PLAYER_TARGET_CHANGED")
			mod:ForEachPlate("ResetNameplateFrameLevel") --keep this after `UpdateElement_Filters`
		end
	elseif frame.isTargetChanged then
		frame.isTargetChanged = false

		mod:SetPlateFrameLevel(frame, mod:GetPlateFrameLevel(frame))

		if self.db.useTargetScale then
			self:SetFrameScale(frame, (frame.ThreatScale or 1))
		end

		if not frame.isGroupUnit then
			frame.unit = nil
	--		frame:UnregisterAllEvents()
		end

		if self.db.units[frame.UnitType].healthbar.enable ~= true then
			self:UpdateAllFrame(frame)
		end

		if not frame.AlphaChanged then
			if self.hasTarget then
				frame:SetAlpha(self.db.nonTargetTransparency)
			else
				frame:SetAlpha(1)
			end
		end

		-- TEST
	--	mod:UpdateElement_CPoints(frame)
		mod:UpdateElement_Filters(frame, "PLAYER_TARGET_CHANGED")
		mod:ForEachPlate("ResetNameplateFrameLevel") --keep this after `UpdateElement_Filters`
	elseif frame.oldHighlight:IsShown() then
		if not frame.isMouseover then
			frame.isMouseover = true

			if not frame.isGroupUnit then
				frame.unit = "mouseover"

	--			mod:UpdateElement_AurasByGUID(frame.guid)
				mod:UpdateElement_Highlight(frame)
			end
		end
	--	mod:UpdateElement_Cast(frame, nil, frame.unit)
	elseif frame.isMouseover then
		frame.isMouseover = nil

		if not frame.isGroupUnit then
			frame.unit = nil
		--	frame.CastBar:Hide()
		end
		mod:UpdateElement_Highlight(frame)
	else
		if not frame.AlphaChanged then
			if self.hasTarget then
				frame:SetAlpha(self.db.nonTargetTransparency)
			else
				frame:SetAlpha(1)
			end
		end
	end

	self:UpdateElement_Glow(frame)
	self:UpdateElement_HealthColor(frame)
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
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E["media"].bordercolor))

		point.borderbottom = parent:CreateTexture()
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E["media"].bordercolor))

		point.borderleft = parent:CreateTexture()
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E["media"].bordercolor))

		point.borderright = parent:CreateTexture()
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E["media"].bordercolor))
	else
		point.bordertop = parent:CreateTexture(nil, "OVERLAY")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult*2)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult*2)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.bordertop.backdrop = parent:CreateTexture()
		point.bordertop.backdrop:SetPoint("TOPLEFT", point.bordertop, "TOPLEFT", noscalemult, noscalemult)
		point.bordertop.backdrop:SetPoint("TOPRIGHT", point.bordertop, "TOPRIGHT", -noscalemult, noscalemult)
		point.bordertop.backdrop:SetHeight(noscalemult * 3)
		point.bordertop.backdrop:SetTexture(0, 0, 0)

		point.borderbottom = parent:CreateTexture(nil, "OVERLAY")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult*2)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult*2)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom.backdrop = parent:CreateTexture()
		point.borderbottom.backdrop:SetPoint("BOTTOMLEFT", point.borderbottom, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetPoint("BOTTOMRIGHT", point.borderbottom, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetHeight(noscalemult * 3)
		point.borderbottom.backdrop:SetTexture(0, 0, 0)

		point.borderleft = parent:CreateTexture(nil, "OVERLAY")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderleft.backdrop = parent:CreateTexture()
		point.borderleft.backdrop:SetPoint("TOPLEFT", point.borderleft, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft.backdrop:SetPoint("BOTTOMLEFT", point.borderleft, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderleft.backdrop:SetWidth(noscalemult * 3)
		point.borderleft.backdrop:SetTexture(0, 0, 0)

		point.borderright = parent:CreateTexture(nil, "OVERLAY")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))

		point.borderright.backdrop = parent:CreateTexture()
		point.borderright.backdrop:SetPoint("TOPRIGHT", point.borderright, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright.backdrop:SetPoint("BOTTOMRIGHT", point.borderright, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderright.backdrop:SetWidth(noscalemult * 3)
		point.borderright.backdrop:SetTexture(0, 0, 0)
	end
end

function mod:RoundColors(r, g, b)
	return floor(r*100+.5) / 100, floor(g*100+.5) / 100, floor(b*100+.5) / 100
end

function mod:UnitClass(name, type)
	if type == "FRIENDLY_NPC" then return end

	if E.private.general.classCache then
		return CC:GetClassByName(name)
	end
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

function mod:OnShow(self, isUpdate)
	self = self or this
	if mod.db.motionType == "OVERLAP" then
		self:SetWidth(0.01)
		self:SetHeight(0.01)
	end

	if not isUpdate then
		self.UnitFrame.moveUp:Play()
	end

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

	mod:ConfigureElement_Level(self.UnitFrame)
	mod:ConfigureElement_Name(self.UnitFrame)
	mod:ConfigureElement_Highlight(self.UnitFrame)

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
	self = self or this
	mod.VisiblePlates[self.UnitFrame] = nil

	self.UnitFrame.unit = nil
	--self.UnitFrame.isGroupUnit = nil

	mod:HideAuraIcons(self.UnitFrame.Buffs)
	mod:HideAuraIcons(self.UnitFrame.Debuffs)
	mod:ClearStyledPlate(self.UnitFrame)
	self.UnitFrame:UnregisterAllEvents()
	self.UnitFrame.Glow.r, self.UnitFrame.Glow.g, self.UnitFrame.Glow.b = nil, nil, nil
	self.UnitFrame.Glow:Hide()
	self.UnitFrame.Glow2:Hide()
	self.UnitFrame.TopArrow:Hide()
	self.UnitFrame.LeftArrow:Hide()
	self.UnitFrame.RightArrow:Hide()
	self.UnitFrame.HealthBar.r, self.UnitFrame.HealthBar.g, self.UnitFrame.HealthBar.b = nil, nil, nil
	self.UnitFrame.HealthBar:Hide()
	self.UnitFrame.HealthBar.currentScale = nil
	self.UnitFrame.Level:ClearAllPoints()
	self.UnitFrame.Level:SetText("")
	self.UnitFrame.Name.r, self.UnitFrame.Name.g, self.UnitFrame.Name.b = nil, nil, nil
	self.UnitFrame.Name:ClearAllPoints()
	self.UnitFrame.Name:SetText("")
	self.UnitFrame.Name.NameOnlyGlow:Hide()
	self.UnitFrame.Highlight:Hide()
	self.UnitFrame.CPoints:Hide()
	self.UnitFrame:Hide()
	self.UnitFrame.isTarget = nil
	self.UnitFrame.isTargetChanged = false
	self.UnitFrame.isMouseover = nil
	self.UnitFrame.UnitName = nil
	self.UnitFrame.UnitType = nil
	self.UnitFrame.UnitClass = nil
	self.UnitFrame.UnitReaction = nil
	self.UnitFrame.TopLevelFrame = nil
	self.UnitFrame.TopOffset = nil
	self.UnitFrame.ThreatScale = nil
	self.UnitFrame.ActionScale = nil
	self.UnitFrame.ThreatReaction = nil
	self.UnitFrame.RaidIconType = nil
end

function mod:UpdateAllFrame(frame)
	mod:OnHide(frame:GetParent())
	mod:OnShow(frame:GetParent(), true)
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

function mod:ForEachVisiblePlate(functionToRun, ...)
	for frame in pairs(self.VisiblePlates) do
		self[functionToRun](self, frame, unpack(arg))
	end
end

function mod:UpdateElement_All(frame, noTargetFrame, filterIgnore)
	local healthShown = (frame.UnitType and self.db.units[frame.UnitType].healthbar.enable) or (frame.isTarget and self.db.alwaysShowTargetHealth)

	if healthShown then
		mod:UpdateElement_Health(frame)
		mod:UpdateElement_HealthColor(frame)
		mod:UpdateElement_Cast(frame, nil, frame.unit)
		mod:UpdateElement_Auras(frame)
	end
	mod:UpdateElement_RaidIcon(frame)
	mod:UpdateElement_Name(frame)
	mod:UpdateElement_Level(frame)
	mod:UpdateElement_Highlight(frame)

	if healthShown then
		mod:UpdateElement_Glow(frame)
	else
		-- make sure we hide the arrows and/or glow after disabling the healthbar
		if frame.TopArrow and frame.TopArrow:IsShown() then frame.TopArrow:Hide() end
		if frame.LeftArrow and frame.LeftArrow:IsShown() then frame.LeftArrow:Hide() end
		if frame.RightArrow and frame.RightArrow:IsShown() then frame.RightArrow:Hide() end
		if frame.Glow2 and frame.Glow2:IsShown() then frame.Glow2:Hide() end
		if frame.Glow and frame.Glow:IsShown() then frame.Glow:Hide() end
	end

	if not noTargetFrame then
		mod:SetTargetFrame(frame)
	end

	if not filterIgnore then
		mod:UpdateElement_Filters(frame, "UpdateElement_All")
	end
end

function mod:AnimatedHide()
	local num = 0
	for frame in pairs(mod.VisiblePlates) do
		frame.moveDown:Play()
		num = num + 1
	end
	if num < 1 then
		
	end
end

local plateID = 0
function mod:OnCreated(frame)
	plateID = plateID + 1
	local HealthBar = frame:GetChildren()
	local Border, Highlight, Name, Level, BossIcon, RaidIcon = frame:GetRegions()
	frame.UnitFrame = CreateFrame("Button", format("ElvUI_NamePlate%d", plateID), frame)
	frame.UnitFrame:SetPoint("CENTER", 0, 0)
	frame.UnitFrame.plateID = plateID

	frame.UnitFrame:SetScript("OnEvent", self.OnEvent)
	frame.UnitFrame:SetScript("OnClick", function()
		frame:Click()
	end)

	frame.UnitFrame.moveUp = CreateAnimationGroup(frame.UnitFrame)
	local moveUp = frame.UnitFrame.moveUp:CreateAnimation("Move")
	moveUp:SetDuration(0)
	moveUp:SetOffset(0, -35)
	moveUp = frame.UnitFrame.moveUp:CreateAnimation("Move")
	moveUp:SetDuration(0.3)
	moveUp:SetOffset(0, 35)
	moveUp:SetSmoothing("Out")
	moveUp:SetOrder(2)

	frame.UnitFrame.moveDown = CreateAnimationGroup(frame.UnitFrame)
	local moveDown = frame.UnitFrame.moveDown:CreateAnimation("Move")
	moveDown:SetDuration(0.1)
	moveDown:SetOffset(0, -35)
	moveDown:SetSmoothing("In")
	moveDown:SetScript("OnFinished", function(self)
		self:Reset()
	end)

	frame.UnitFrame.HealthBar = self:ConstructElement_HealthBar(frame.UnitFrame)
	frame.UnitFrame.Level = self:ConstructElement_Level(frame.UnitFrame)
	frame.UnitFrame.Name = self:ConstructElement_Name(frame.UnitFrame)
	frame.UnitFrame.CastBar = self:ConstructElement_CastBar(frame.UnitFrame)
	frame.UnitFrame.Glow = self:ConstructElement_Glow(frame.UnitFrame)
	frame.UnitFrame.Buffs = self:ConstructElement_Auras(frame.UnitFrame, "LEFT")
	frame.UnitFrame.Debuffs = self:ConstructElement_Auras(frame.UnitFrame, "RIGHT")
	frame.UnitFrame.HealerIcon = self:ConstructElement_HealerIcon(frame.UnitFrame)
	frame.UnitFrame.CPoints = self:ConstructElement_CPoints(frame.UnitFrame)
	frame.UnitFrame.Highlight = self:ConstructElement_Highlight(frame.UnitFrame)

	self:QueueObject(HealthBar)
	self:QueueObject(Level)
	self:QueueObject(Name)
	self:QueueObject(Border)
	self:QueueObject(Highlight)
	BossIcon:SetAlpha(0)

	frame.UnitFrame.oldHealthBar = HealthBar
	frame.UnitFrame.oldName = Name
	frame.UnitFrame.oldHighlight = Highlight
	frame.UnitFrame.oldLevel = Level

	RaidIcon:SetParent(frame.UnitFrame)
	frame.UnitFrame.RaidIcon = RaidIcon

	frame.UnitFrame.BossIcon = BossIcon

	self:OnShow(frame)

	frame:SetScript("OnShow", self.OnShow)
	frame:SetScript("OnHide", self.OnHide)

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
		object:SetWidth(0.001)
	elseif objectType == "StatusBar" then
		object:SetStatusBarTexture("")
	end
	object:Hide()
end

function mod:OnUpdate()
	local count = WorldGetNumChildren(WorldFrame)
	if count ~= numChildren then
		local frame, region
		for i = numChildren + 1, count do
			frame = select(i, WorldGetChildren(WorldFrame))
			region = frame:GetRegions()
			if not mod.CreatedPlates[frame] and region and region:GetObjectType() == "Texture" and region:GetTexture() == BORDER then
				mod:OnCreated(frame)
			end
			numChildren = count
		end
	end

	for frame in pairs(mod.VisiblePlates) do
		if mod.hasTarget then 
			frame.alpha = frame:GetParent():GetAlpha()
		else
			frame.alpha = 1
		end

		frame:GetParent():SetAlpha(1)

		frame.isTarget = mod.hasTarget and frame.alpha == 1
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
	local SearchFor = split("-", sourceName)
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
end

function mod:PLAYER_TARGET_CHANGED()
	self.hasTarget = UnitExists("target") == 1
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

	self.hasTarget = false

	--Add metatable to all our StyleFilters so they can grab default values if missing
	for _, filterTable in pairs(E.global.nameplates.filters) do
		self:StyleFilterInitializeFilter(filterTable);
	end

	self:StyleFilterConfigureEvents()

	self.levelStep = 2

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

	self:ScheduleRepeatingTimer("ForEachVisiblePlate", 0.1, "SetTargetFrame")

	E.NamePlates = self
end

local function InitializeCallback()
	mod:Initialize()
end

E:RegisterModule(mod:GetName(), InitializeCallback)