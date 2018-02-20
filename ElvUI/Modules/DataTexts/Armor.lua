local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts");

--Cache global variables
--Lua functions
local format = string.format
local join = string.join
--WoW API / Variables
local UnitArmor = UnitArmor
local UnitLevel = UnitLevel
local ARMOR = ARMOR

local lastPanel
local chanceString = "%.2f%%"
local displayString = ""
local _, effectiveArmor

local function GetArmorReduction(armor, attackerLevel)
	local levelModifier = attackerLevel
	if levelModifier > 59 then
		levelModifier = levelModifier + (4.5 * (levelModifier - 59))
	end
	local temp = 0.1 * armor/(8.5 * levelModifier + 40)
	temp = temp/(1 + temp)

	if temp > 0.75 then return 75 end
	if temp < 0 then return 0 end

	return temp*100
end

local function OnEvent(self)
	_, effectiveArmor = UnitArmor("player")

	self.text:SetText(format(displayString, ARMOR, effectiveArmor))
	lastPanel = self
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	DT.tooltip:AddLine(L["Mitigation By Level: "])
	DT.tooltip:AddLine(" ")

	local playerLevel = UnitLevel("player") + 3
	for i = 1, 4 do
		local armorReduction = GetArmorReduction(effectiveArmor, playerLevel)
		DT.tooltip:AddDoubleLine(playerLevel, format(chanceString, armorReduction), 1, 1, 1)
		playerLevel = playerLevel - 1
	end

	local targetLevel = UnitLevel("target")
	if targetLevel and targetLevel > 0 and (targetLevel > playerLevel + 3 or targetLevel < playerLevel) then
		local armorReduction = GetArmorReduction(effectiveArmor, targetLevel)
		DT.tooltip:AddDoubleLine(targetLevel, format(chanceString, armorReduction), 1, 1, 1)
	end

	DT.tooltip:Show()
end

local function ValueColorUpdate(hex)
	displayString = join("", "%s: ", hex, "%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel)
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true

DT:RegisterDatatext("Armor", {"UNIT_RESISTANCES"}, OnEvent, nil, nil, OnEnter, nil, ARMOR)