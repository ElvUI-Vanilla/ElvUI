local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local max = math.max
local format, join, sub = string.format, string.join, string.sub
--WoW API / Variables
local UnitAttackPower = UnitAttackPower
local UnitRangedAttackPower = UnitRangedAttackPower
local ATTACK_POWER_COLON = ATTACK_POWER_COLON
local ATTACK_POWER_MAGIC_NUMBER = ATTACK_POWER_MAGIC_NUMBER
local MELEE_ATTACK_POWER = MELEE_ATTACK_POWER
local MELEE_ATTACK_POWER_TOOLTIP = MELEE_ATTACK_POWER_TOOLTIP
local RANGED_ATTACK_POWER = RANGED_ATTACK_POWER
local RANGED_ATTACK_POWER_TOOLTIP = RANGED_ATTACK_POWER_TOOLTIP
local ATTACK_POWER_TOOLTIP = ATTACK_POWER_TOOLTIP

local ATTACK_POWER = sub(ATTACK_POWER_COLON, 1, -2)

local base, posBuff, negBuff, effective, Rbase, RposBuff, RnegBuff, Reffective, pwr
local displayNumberString = ""
local lastPanel

local function OnEvent(self)
	if(E.myclass == "HUNTER") then
		Rbase, RposBuff, RnegBuff = UnitRangedAttackPower("player")
		Reffective = Rbase + RposBuff + RnegBuff
		pwr = Reffective
	else
		base, posBuff, negBuff = UnitAttackPower("player")
		effective = base + posBuff + negBuff
		pwr = effective
	end

	self.text:SetText(format(displayNumberString, ATTACK_POWER, pwr))
	lastPanel = self
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	if(E.myclass == "HUNTER") then
		DT.tooltip:AddDoubleLine(RANGED_ATTACK_POWER, pwr, 1, 1, 1)

		local line = format(RANGED_ATTACK_POWER_TOOLTIP, max((pwr), 0) / ATTACK_POWER_MAGIC_NUMBER)

		DT.tooltip:AddLine(line, nil, nil, nil, true)
	else
		DT.tooltip:AddDoubleLine(MELEE_ATTACK_POWER, pwr, 1, 1, 1)
		DT.tooltip:AddLine(format(MELEE_ATTACK_POWER_TOOLTIP, max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER), nil, nil, nil, true)
	end

	DT.tooltip:Show()
end

local function ValueColorUpdate(hex)
	displayNumberString = join("", "%s: ", hex, "%d|r")

	if(lastPanel ~= nil) then
		OnEvent(lastPanel)
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true

DT:RegisterDatatext("Attack Power", {"UNIT_ATTACK_POWER", "UNIT_RANGED_ATTACK_POWER"}, OnEvent, nil, nil, OnEnter, nil, ATTACK_POWER_TOOLTIP)