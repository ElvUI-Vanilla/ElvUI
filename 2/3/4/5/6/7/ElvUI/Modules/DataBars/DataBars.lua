local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local mod = E:NewModule("DataBars", "AceEvent-3.0");
E.DataBars = mod

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables
local UIFrameFadeOut = UIFrameFadeOut

function mod:OnLeave()
	if (this == ElvUI_ExperienceBar and mod.db.experience.mouseover) or (this == ElvUI_ReputationBar and mod.db.reputation.mouseover) then
		UIFrameFadeOut(this, 1, this:GetAlpha(), 0)
	end
	GameTooltip:Hide()
end

function mod:CreateBar(name, onEnter, onClick, ...)
	local bar = CreateFrame("Button", name, E.UIParent)
	bar:SetPoint(unpack(arg))
	bar:SetScript("OnEnter", onEnter)
	bar:SetScript("OnLeave", mod.OnLeave)
	bar:SetScript("OnClick", onClick)
	bar:SetFrameStrata("LOW")
	E:SetTemplate(bar, "Transparent")
	bar:Hide()

	bar.statusBar = CreateFrame("StatusBar", nil, bar)
	E:SetInside(bar.statusBar)
	bar.statusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(bar.statusBar)
	bar.text = bar.statusBar:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(bar.text)
	bar.text:SetPoint("CENTER", 0, 0)

	return bar
end

function mod:UpdateDataBarDimensions()
	self:UpdateExperienceDimensions()
	self:UpdateReputationDimensions()
end

function mod:PLAYER_LEVEL_UP(level, level2)
	print(level, level2)
	local maxLevel = 60
	if (level ~= maxLevel or not self.db.experience.hideAtMaxLevel) and self.db.experience.enable then
		self:UpdateExperience("PLAYER_LEVEL_UP", level)
	else
		self.expBar:Hide()
	end
end

function mod:Initialize()
	self.db = E.db.databars

	self:LoadExperienceBar()
	self:LoadReputationBar()
	self:RegisterEvent("PLAYER_LEVEL_UP")
end

local function InitializeCallback()
	mod:Initialize()
end

E:RegisterModule(mod:GetName(), InitializeCallback)