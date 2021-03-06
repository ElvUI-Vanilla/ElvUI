--By Elv, for E.
local ns = oUF
local oUF = ns.oUF

local pairs = pairs

local UIFrameFadeIn, UIFrameFadeOut = UIFrameFadeIn, UIFrameFadeOut
local UnitAffectingCombat = UnitAffectingCombat
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitExists = UnitExists

local frames, allFrames = {}, {}
local showStatus

local CheckForReset = function()
	for frame in pairs(allFrames) do
		if frame.fadeInfo and frame.fadeInfo.reset then
			frame:SetAlpha(1)
			frame.fadeInfo.reset = nil
		end
	end
end

local FadeFramesInOut = function(fade, unit)
	for frame, unit in pairs(frames) do
		if not UnitExists(unit) then return end
		if fade then
			if frame:GetAlpha() ~= 1 or (frame.fadeInfo and frame.fadeInfo.endAlpha == 0) then
				UIFrameFadeIn(frame, 0.15)
			end
		else
			if frame:GetAlpha() ~= 0 then
				UIFrameFadeOut(frame, 0.15)
				frame.fadeInfo.finishedFunc = CheckForReset
			else
				showStatus = false
				return
			end
		end
	end

	if unit == "player" then
		showStatus = fade
	end
end

local Update = function(self, arg1, arg2)
	if arg1 == "UNIT_HEALTH" and self and self.unit ~= arg2 then return end
	if type(arg1) == "boolean" and not frames[self] then
		return
	end

	if not frames[self] then
		UIFrameFadeIn(self, 0.15)
		self.fadeInfo.reset = true
		return
	end

	local combat = UnitAffectingCombat("player")
	local cur, max = UnitHealth("player"), UnitHealthMax("player")
	local target = UnitExists("target")

	if cur ~= max and showStatus ~= true then
		FadeFramesInOut(true, frames[self])
	elseif target and showStatus ~= true then
		FadeFramesInOut(true, frames[self])
	elseif arg1 == true and showStatus ~= true then
		FadeFramesInOut(true, frames[self])
	else
		if combat and showStatus ~= true then
			FadeFramesInOut(true, frames[self])
		elseif not target and not combat and (cur == max) then
			FadeFramesInOut(false, frames[self])
		end
	end
end

local Enable = function(self, unit)
	if self.CombatFade then
		frames[self] = self.unit
		allFrames[self] = self.unit

		if unit == "player" then
			showStatus = false
		end

		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Update)
		self:RegisterEvent("PLAYER_REGEN_DISABLED", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:RegisterEvent("UNIT_HEALTH", Update)
		self:RegisterEvent("UNIT_SPELLCAST_START", Update)
		self:RegisterEvent("UNIT_SPELLCAST_STOP", Update)
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", Update)
		self:RegisterEvent("UNIT_MODEL_CHANGED", Update)

		if not self.CombatFadeHooked then
			HookScript(self, "OnEnter", function() Update(self, true) end)
			HookScript(self, "OnLeave", function() Update(self, false) end)
			self.CombatFadeHooked = true
		end
		return true
	end
end

local Disable = function(self)
	if(self.CombatFade) then
		frames[self] = nil
		Update(self)

		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Update)
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("UNIT_HEALTH", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_START", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_STOP", Update)
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE", Update)
		self:UnregisterEvent("UNIT_MODEL_CHANGED", Update)
	end
end

oUF:AddElement("CombatFade", Update, Enable, Disable)