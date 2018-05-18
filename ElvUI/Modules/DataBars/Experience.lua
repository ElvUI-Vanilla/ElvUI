local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local mod = E:GetModule("DataBars");
local LSM = LibStub("LibSharedMedia-3.0");

--Cache global variables
--Lua functions
local _G = _G
local format = format
local min = min
--WoW API / Variables
local GetPetExperience, UnitXP, UnitXPMax = GetPetExperience, UnitXP, UnitXPMax
local UnitLevel = UnitLevel
local GetXPExhaustion = GetXPExhaustion

function mod:GetXP(unit)
	if unit == "pet" then
		return GetPetExperience()
	else
		return UnitXP(unit), UnitXPMax(unit)
	end
end

function mod:UpdateExperience(event)
	if not mod.db.experience.enable then return end

	local bar = self.expBar
	local hideXP = (UnitLevel("player") == 60 and self.db.experience.hideAtMaxLevel)

	if hideXP then
		E:DisableMover(self.expBar.mover:GetName())
		bar:Hide()
	elseif not hideXP then
		E:EnableMover(self.expBar.mover:GetName())
		bar:Show()

		local cur, max = self:GetXP("player")
		if max <= 0 then max = 1 end
		bar.statusBar:SetMinMaxValues(0, max)
		bar.statusBar:SetValue(cur - 1 >= 0 and cur - 1 or 0)
		bar.statusBar:SetValue(cur)

		local rested = GetXPExhaustion()
		local text = ""
		local textFormat = self.db.experience.textFormat

		if rested and rested > 0 then
			bar.rested:SetMinMaxValues(0, max)
			bar.rested:SetValue(min(cur + rested, max))

			if textFormat == "PERCENT" then
				text = format("%d%% R:%d%%", cur / max * 100, rested / max * 100)
			elseif textFormat == "CURMAX" then
				text = format("%s - %s R:%s", E:ShortValue(cur), E:ShortValue(max), E:ShortValue(rested))
			elseif textFormat == "CURPERC" then
				text = format("%s - %d%% R:%s [%d%%]", E:ShortValue(cur), cur / max * 100, E:ShortValue(rested), rested / max * 100)
			elseif textFormat == "CUR" then
				text = format("%s R:%s", E:ShortValue(cur), E:ShortValue(rested))
			elseif textFormat == "REM" then
				text = format("%s R:%s", E:ShortValue(max - cur), E:ShortValue(rested))
			elseif textFormat == "CURREM" then
				text = format("%s - %s R:%s", E:ShortValue(cur), E:ShortValue(max - cur), E:ShortValue(rested))
			elseif textFormat == "CURPERCREM" then
				text = format("%s - %d%% (%s) R:%s", E:ShortValue(cur), cur / max * 100, E:ShortValue(max - cur), E:ShortValue(rested))
			end
		else
			bar.rested:SetMinMaxValues(0, 1)
			bar.rested:SetValue(0)

			if textFormat == "PERCENT" then
				text = format("%d%%", cur / max * 100)
			elseif textFormat == "CURMAX" then
				text = format("%s - %s", E:ShortValue(cur), E:ShortValue(max))
			elseif textFormat == "CURPERC" then
				text = format("%s - %d%%", E:ShortValue(cur), cur / max * 100)
			elseif textFormat == "CUR" then
				text = format("%s", E:ShortValue(cur))
			elseif textFormat == "REM" then
				text = format("%s", E:ShortValue(max - cur))
			elseif textFormat == "CURREM" then
				text = format("%s - %s", E:ShortValue(cur), E:ShortValue(max - cur))
			elseif textFormat == "CURPERCREM" then
				text = format("%s - %d%% (%s)", E:ShortValue(cur), cur / max * 100, E:ShortValue(max - cur))
			end
		end

		bar.text:SetText(text)
	end
end

function mod:ExperienceBar_OnEnter()
	if mod.db.experience.mouseover then
		UIFrameFadeIn(this, 0.4, this:GetAlpha(), 1)
	end
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(this, "ANCHOR_CURSOR", 0, -4)

	local cur, max = mod:GetXP("player")
	local rested = GetXPExhaustion()
	GameTooltip:AddLine(L["Experience"])
	GameTooltip:AddLine(" ")

	GameTooltip:AddDoubleLine(L["XP:"], format(" %d / %d (%d%%)", cur, max, cur/max * 100), 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Remaining:"], format(" %d (%d%% - %d "..L["Bars"]..")", max - cur, (max - cur) / max * 100, 20 * (max - cur) / max), 1, 1, 1)

	if rested then
		GameTooltip:AddDoubleLine(L["Rested:"], format("+%d (%d%%)", rested, rested / max * 100), 1, 1, 1)
	end

	GameTooltip:Show()
end

function mod:ExperienceBar_OnClick()

end

function mod:UpdateExperienceDimensions()
	E:Size(self.expBar, self.db.experience.width, self.db.experience.height)

	E:FontTemplate(self.expBar.text, LSM:Fetch("font", self.db.experience.font), self.db.experience.textSize, self.db.experience.fontOutline)
	self.expBar.rested:SetOrientation(self.db.experience.orientation)

	self.expBar.statusBar:SetOrientation(self.db.experience.orientation)

	if self.db.experience.mouseover then
		self.expBar:SetAlpha(0)
	else
		self.expBar:SetAlpha(1)
	end
end

function mod:EnableDisable_ExperienceBar()
	local maxLevel = 60
	if (UnitLevel("player") ~= maxLevel or not self.db.experience.hideAtMaxLevel) and self.db.experience.enable then
		self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateExperience")
		self:RegisterEvent("DISABLE_XP_GAIN", "UpdateExperience")
		self:RegisterEvent("ENABLE_XP_GAIN", "UpdateExperience")
		self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateExperience")
		self:UnregisterEvent("UPDATE_EXPANSION_LEVEL")
		self:UpdateExperience()
		E:EnableMover(self.expBar.mover:GetName())
	else
		self:UnregisterEvent("PLAYER_XP_UPDATE")
		self:UnregisterEvent("DISABLE_XP_GAIN")
		self:UnregisterEvent("ENABLE_XP_GAIN")
		self:UnregisterEvent("UPDATE_EXHAUSTION")
		self:RegisterEvent("UPDATE_EXPANSION_LEVEL", "EnableDisable_ExperienceBar")
		self.expBar:Hide()
		E:DisableMover(self.expBar.mover:GetName())
	end
end

function mod:LoadExperienceBar()
	self.expBar = self:CreateBar("ElvUI_ExperienceBar", self.ExperienceBar_OnEnter, self.ExperienceBar_OnClick, "LEFT", LeftChatPanel, "RIGHT", -E.Border + E.Spacing*3, 0)
	self.expBar.statusBar:SetStatusBarColor(0, 0.4, 1, .8)
	self.expBar.rested = CreateFrame("StatusBar", nil, self.expBar)
	E:SetInside(self.expBar.rested)
	self.expBar.rested:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(self.expBar.rested)
	self.expBar.rested:SetStatusBarColor(1, 0, 1, 0.2)
	E:Kill(ExhaustionTick)

	self:UpdateExperienceDimensions()

	E:CreateMover(self.expBar, "ExperienceBarMover", L["Experience Bar"])
	self:EnableDisable_ExperienceBar()
end