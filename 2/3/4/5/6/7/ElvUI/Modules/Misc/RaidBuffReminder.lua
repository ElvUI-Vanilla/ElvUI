local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local RB = E:NewModule("ReminderBuffs", "AceEvent-3.0");
local LSM = LibStub("LibSharedMedia-3.0");

--Cache global variables
--Lua functions
local ipairs = ipairs
--WoW API / Variables
local GetPlayerBuff = GetPlayerBuff
local GetPlayerBuffName = GetPlayerBuffName
local GetPlayerBuffTexture = GetPlayerBuffTexture
local GetPlayerBuffTimeLeft = GetPlayerBuffTimeLeft
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitBuff = UnitBuff

local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY

E.ReminderBuffs = RB

RB.Spell1Buffs = {
	-- 17638, -- Flask of Chromatic Resistance
	-- 17637, -- Flask of Supreme Power
	-- 17635, -- Flask of the Titans
	-- 17636, -- Flask of Distilled Wisdom

	-- 11450, -- Elixir of Greater Defense
	-- 3171,  -- Elixir of Wisdom
	-- 3230,  -- Elixir of Fortitude
	-- 11467, -- Elixir of Greater Agility
	-- 11406, -- Elixir of Demonslaying
}

RB.Spell2Buffs = {
	-- 43706, -- +23 Spellcrit (Skullfish Soup Buff)
	-- 33257, -- +30 Stamina
	-- 33256, -- +20 Strength
	-- 33259, -- +40 AP
	-- 33261, -- +20 Agility
	-- 33263, -- +23 Spelldmg
	-- 33265, -- +8 MP5
	-- 33268, -- +44 Addheal
	-- 35272, -- +20 Stamina
	-- 33254, -- +20 Stamina
	-- 43764, -- +20 Meleehit
	-- 45619, -- +8 Spellresist
}

RB.Spell3Buffs = {
	-- 21850, -- Gift of the Wild
	-- 16878, -- Mark of the Wild
}

RB.Spell4Buffs = {
	-- 25898, -- Greater Blessing of Kings
	-- 20217, -- Blessing of Kings
}

RB.CasterSpell5Buffs = {
	-- 23028, -- Arcane Brilliance
	-- 16876, -- Arcane Intellect
}

RB.MeleeSpell5Buffs = {
	-- 21564, -- Prayer of Fortitude
	-- 23948, -- Power Word: Fortitude
	-- 22440, -- Commanding Shout
}

RB.CasterSpell6Buffs = {
	-- 25918, -- Greater Blessing of Wisdom
	-- 25290, -- Blessing of Wisdom
	-- 10494, -- Mana Spring
}

RB.MeleeSpell6Buffs = {
	-- 25291, -- Greater Blessing of Might
	-- 27140, -- Blessing of Might
	-- 25289, -- Battle Shout
}

function RB:CheckFilterForActiveBuff(filter)
	local spellName, buffIndex, untilCancelled

	for _, spellID in ipairs(filter) do
		spellName = GetSpellName(spellID, BOOKTYPE_SPELL)

		if spellName then
			for i = 1, BUFF_MAX_DISPLAY do
				buffIndex, untilCancelled = GetPlayerBuff(i)

				if buffIndex ~= 0 then
					if spellName == GetPlayerBuffName(buffIndex) then
						return true, buffIndex, GetPlayerBuffTexture(buffIndex), untilCancelled, GetPlayerBuffTimeLeft(buffIndex), GetPlayerBuffName(buffIndex), spellID
					end
				end
			end
		end
	end

	return false
end

function RB:GetDurationForBuffName(buffName)
	local _, name, duration
	for i = 1, BUFF_MAX_DISPLAY do
		name, _, _, _, duration = UnitBuff("player", i)
		if name == buffName and duration then
			return duration
		end
	end
	return nil
end

function RB:Button_OnUpdate(elapsed)
	local timeLeft = GetPlayerBuffTimeLeft(self.index)

	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	if timeLeft <= 0 then
		self.timer:SetText("")
		self:SetScript("OnUpdate", nil)
		return
	end

	local timerValue, formatID
	timerValue, formatID, self.nextUpdate = E:GetTimeInfo(timeLeft, 4)
	self.timer:SetFormattedText(("%s%s|r"):format(E.TimeColors[formatID], E.TimeFormats[formatID][1]), timerValue)
end

function RB:Update()
	for i = 1, 6 do
		local button = self.frame[i]
		local hasBuff, index, texture, untilCancelled, timeLeft, buffName, spellID = self:CheckFilterForActiveBuff(self["Spell"..i.."Buffs"])

		if hasBuff then
			button.index = index
			button.t:SetTexture(texture)

			if (untilCancelled == 1 or not timeLeft) or not E.db.general.reminder.durations then
				button.t:SetAlpha(E.db.general.reminder.reverse and 1 or 0.3)
				button:SetScript("OnUpdate", nil)
				button.timer:SetText(nil)
				CooldownFrame_SetTimer(button.cd, 0, 0, 0)
			else
				button.nextUpdate = 0
				button.t:SetAlpha(1)

				local duration = self:GetDurationForBuffName(buffName) or ElvCharacterDB.ReminderDuration[spellID]
				if duration then
					CooldownFrame_SetTimer(button.cd, GetTime() - (duration - timeLeft), duration, 1)
					ElvCharacterDB.ReminderDuration[spellID] = duration
				else
					CooldownFrame_SetTimer(button.cd, 0, 0, 0)
				end
				button:SetScript("OnUpdate", self.Button_OnUpdate)
			end
		else
			button.index = nil
			CooldownFrame_SetTimer(button.cd, 0, 0, 0)
			button.t:SetAlpha(E.db.general.reminder.reverse and 0.3 or 1)
			button:SetScript("OnUpdate", nil)
			button.timer:SetText(nil)
			button.t:SetTexture(self.DefaultIcons[i])
		end
	end
end

function RB:CreateButton()
	local button = CreateFrame("Button", nil, ElvUI_ReminderBuffs)
	E:SetTemplate(button, "Default")

	button.t = button:CreateTexture(nil, "OVERLAY")
	button.t:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(button.t)
	button.t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	button.timer = button:CreateFontString(nil, "OVERLAY")
	button.timer:SetPoint("CENTER", 0, 0)

	button.cd = CreateFrame("Button", nil, button, "CooldownFrameTemplate")
	E:SetInside(button.cd)
	button.cd.noOCC = true
	button.cd.noCooldownCount = true

	return button
end

function RB:UpdateSettings(isCallback)
	local font = LSM:Fetch("font", E.db.general.reminder.font)

	local frame = self.frame
	frame:SetWidth(E.RBRWidth)

	self:UpdateDefaultIcons()

	for i = 1, 6 do
		local button = self.frame[i]
		button:SetWidth(E.RBRWidth)
		button:SetHeight(E.RBRWidth)

		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint("TOP", ElvUI_ReminderBuffs, "TOP", 0, 0)
		elseif i == 6 then
			button:SetPoint("BOTTOM", ElvUI_ReminderBuffs, "BOTTOM", 0, 0)
		else
			button:SetPoint("TOP", frame[i - 1], "BOTTOM", 0, E.Border - E.Spacing*3)
		end

		if E.db.general.reminder.durations then
			button.cd:SetAlpha(1)
		else
			button.cd:SetAlpha(0)
		end

		E:FontTemplate(button.timer, font, E.db.general.reminder.fontSize, E.db.general.reminder.fontOutline)
		-- button.cd:SetReverse(E.db.general.reminder.reverse)
		-- if E.db.general.reminder.reverse then
		-- 	button.timer:SetParent(button)
		-- else
		-- 	button.timer:SetParent(button.cd)
		-- end
	end

	if not isCallback then
		if E.db.general.reminder.enable then
			RB:Enable()
		else
			RB:Disable()
		end
	else
		self:Update()
	end
end

function RB:UpdatePosition()
	Minimap:ClearAllPoints()
	ElvConfigToggle:ClearAllPoints()
	ElvUI_ReminderBuffs:ClearAllPoints()

	if E.db.general.reminder.position == "LEFT" then
		Minimap:SetPoint("TOPRIGHT", MMHolder, "TOPRIGHT", -E.Border, -E.Border)
		ElvConfigToggle:SetPoint("TOPRIGHT", LeftMiniPanel, "TOPLEFT", E.Border - E.Spacing*3, 0)
		ElvConfigToggle:SetPoint("BOTTOMRIGHT", LeftMiniPanel, "BOTTOMLEFT", E.Border - E.Spacing*3, 0)
		ElvUI_ReminderBuffs:SetPoint("TOPRIGHT", Minimap.backdrop, "TOPLEFT", E.Border - E.Spacing*3, 0)
		ElvUI_ReminderBuffs:SetPoint("BOTTOMRIGHT", Minimap.backdrop, "BOTTOMLEFT", E.Border - E.Spacing*3, 0)
	else
		Minimap:SetPoint("TOPLEFT", MMHolder, "TOPLEFT", E.Border, -E.Border)
		ElvConfigToggle:SetPoint("TOPLEFT", RightMiniPanel, "TOPRIGHT", -E.Border + E.Spacing*3, 0)
		ElvConfigToggle:SetPoint("BOTTOMLEFT", RightMiniPanel, "BOTTOMRIGHT", -E.Border + E.Spacing*3, 0)
		ElvUI_ReminderBuffs:SetPoint("TOPLEFT", Minimap.backdrop, "TOPRIGHT", -E.Border + E.Spacing*3, 0)
		ElvUI_ReminderBuffs:SetPoint("BOTTOMLEFT", Minimap.backdrop, "BOTTOMRIGHT", -E.Border + E.Spacing*3, 0)
	end
end

function RB:UpdateDefaultIcons()
	self.DefaultIcons = {
		[1] = "Interface\\Icons\\INV_Potion_97",
		[2] = "Interface\\Icons\\Spell_Misc_Food",
		[3] = "Interface\\Icons\\Spell_Nature_Regeneration",
		[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",
		[5] = (E.Role == "Caster" and "Interface\\Icons\\Spell_Holy_MagicalSentry") or "Interface\\Icons\\Spell_Holy_WordFortitude",
		[6] = (E.Role == "Caster" and "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom") or "Interface\\Icons\\Ability_Warrior_BattleShout"
	}

	if E.Role == "Caster" then
		self.Spell5Buffs = self.CasterSpell5Buffs
		self.Spell6Buffs = self.CasterSpell6Buffs
	else
		self.Spell5Buffs = self.MeleeSpell5Buffs
		self.Spell6Buffs = self.MeleeSpell6Buffs
	end
end

function RB:Enable()
	ElvUI_ReminderBuffs:Show()
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "Update")
	E.RegisterCallback(self, "RoleChanged", "UpdateSettings")
	self:Update()
end

function RB:Disable()
	ElvUI_ReminderBuffs:Hide()
	self:UnregisterEvent("PLAYER_AURAS_CHANGED")
	E.UnregisterCallback(self, "RoleChanged", "UpdateSettings")
end

function RB:Initialize()
	if not E.private.general.minimap.enable then return end

	self.db = E.db.general.reminder

	if not ElvCharacterDB.ReminderDuration then
		ElvCharacterDB.ReminderDuration = {}
	end

	local frame = CreateFrame("Frame", "ElvUI_ReminderBuffs", Minimap)
	frame:SetWidth(E.RBRWidth)
	self.frame = frame

	self:UpdatePosition()

	for i = 1, 6 do
		frame[i] = self:CreateButton()
	end

	self:UpdateSettings()
end

local function InitializeCallback()
	RB:Initialize()
end

E:RegisterModule(RB:GetName(), InitializeCallback)