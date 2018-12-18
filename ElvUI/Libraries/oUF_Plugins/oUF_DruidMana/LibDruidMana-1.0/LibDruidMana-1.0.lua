--[[
Name: LibDruidMana-1.0
Revision: $Rev: 29 $
Author: Cameron Kenneth Knight (ckknight@gmail.com)
Inspired By: SmartyCat by Darravis
Website: http://www.wowace.com/
Description: A library to provide data on mana for druids in bear or cat form.
License: LGPL v2.1
]]

if(select(2, UnitClass("player")) ~= "DRUID") then return end

local MAJOR_VERSION = "LibDruidMana-1.0"
local MINOR_VERSION = 90001 + tonumber(strmatch("$Revision: 29 $", "%d+"))

local floor = math.floor

local GetManaRegen = GetManaRegen
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellName = GetSpellName
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellTexture = GetSpellTexture
local GetTime = GetTime
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local UnitPowerType = UnitPowerType
local UnitStat = UnitStat

local lib, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end
local oldLib
if oldMinor then
	oldLib = {}
	for k, v in pairs(lib) do
		oldLib[k] = v
		lib[k] = nil
	end
end

local regenMana, maxMana, currMana, currInt, fiveSecondRule
currMana, maxMana = 0, 0
local bearID, bearName, catName

-- frame for events and OnUpdate
local frame
if oldLib and oldLib.frame then
	frame = oldLib.frame
	frame:UnregisterAllEvents()
	frame:SetScript("OnEvent", nil)
	frame:SetScript("OnUpdate", nil)
	for k in pairs(frame) do
		if k ~= 0 then
			frame[k] = nil
		end
	end
else
	frame = CreateFrame("Frame", MAJOR_VERSION .. "_Frame")
end
lib.frame = frame

-- tooltip for scanning the mana cost for shapeshifting.
local tt
if oldLib and oldLib.tt then
	tt = oldLib.tt
else
	tt = CreateFrame("GameTooltip", MAJOR_VERSION .. "_Tooltip")
end
lib.tt = tt
if not tt.left then
	tt.left = {}
	tt.right = {}
end
for i = table.getn(tt.left) + 1, 30 do
	local left, right = tt:CreateFontString(), tt:CreateFontString()
	tt.left[i] = left
	tt.right[i] = right
	left:SetFontObject(GameFontNormal)
	right:SetFontObject(GameFontNormal)
	tt:AddFontStrings(left, right)
end
tt:SetOwner(UIParent, "ANCHOR_NONE")

-- set of functions to call when mana is updated
local registry = oldLib and oldLib.registry or {}
lib.registry = registry

local function GetManaRegen()
	local _, spirit = UnitStat("player", 5)
	local currMana, maxMana = UnitMana("player"), UnitManaMax("player")
	local regen, castingRegen

	regen = (ceil(spirit / 5) + 15)
	castingRegen = min(currMana + regen, maxMana)

	local j = 1
	local icon
	while UnitBuff("player",j) do
		icon = UnitBuff("player",j)
		if icon and icon == "Interface\\Icons\\Spell_Nature_Lightning" then
			regen = ((ceil(UnitStat("player", 5) / 5) + 15) * 5)
		end
		j = j + 1
	end

	return regen, castingRegen
end

local function getShapeshiftCost()
	if not bearID then return 0 end

	tt:ClearLines()
	tt:SetSpell(bearID, "spell")

	if not tt:IsOwned(UIParent) then
		tt:SetOwner(UIParent, "ANCHOR_NONE")
	end

	local line = tt.left[2]:GetText()
	if line then
		line = tonumber(strmatch(line, "(%d+)"))
	end

	return line or 0
end

local IsLoggedIn
frame:SetScript("OnEvent", function(...)
	if event == "PLAYER_LOGIN" then
		IsLoggedIn = true
	end

	this[event](this, unpack(arg))
end)

local SetMax_time = nil
local UpdateMana_time = nil
local killFSR_time = nil

frame:SetScript("OnUpdate", function()
	local currentTime = GetTime()
	if SetMax_time and SetMax_time <= currentTime then
		SetMax_time = nil
		this:SetMax()
	end
	if UpdateMana_time and UpdateMana_time <= currentTime then
		UpdateMana_time = UpdateMana_time + 2
		this:UpdateMana()
	end
	if killFSR_time and killFSR_time <= currentTime then
		killFSR_time = nil
		fiveSecondRule = false
	end
end)

function frame:PLAYER_LOGIN()
	self.PLAYER_LOGIN = nil

	self:LEARNED_SPELL_IN_TAB()

	self:RegisterEvent("UNIT_DISPLAYPOWER")

	if UnitPowerType("player") == 0 then
		self:UNIT_DISPLAYPOWER("player")
	end
end

function frame:UNIT_DISPLAYPOWER()
	if arg1 ~= "player" or UnitPowerType("player") ~= 0 then return end

	self:UnregisterEvent("UNIT_DISPLAYPOWER")
	self.UNIT_DISPLAYPOWER = nil

	maxMana = UnitManaMax("player")
	currMana = UnitMana("player")
	local _
	_, currInt = UnitStat("player", 4)

	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_MAXMANA")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("COMBAT_TEXT_UPDATE")

	self:Update()
end

function frame:PLAYER_ENTERING_WORLD()
	if UnitPowerType("player") ~= 0 then
		SetMax_time = GetTime() + 7
	end
end

function frame:PLAYER_LEAVING_WORLD()
	SetMax_time = nil
	UpdateMana_time = nil
	killFSR_time = nil
end

function frame:UNIT_MANA()
	if arg1 ~= "player" then return end

	if UnitPowerType("player") == 0 then
		currMana = UnitMana("player")
		maxMana = UnitManaMax("player")
		self:Update()
	else
		if regenMana and not UpdateMana_time then
			-- Update mana every 2 seconds
			UpdateMana_time = GetTime() + 2
			self:UpdateMana()
		end
		-- if mana hasn't been updated for 7 seconds, set current mana to the max mana
		SetMax_time = GetTime() + 7
	end
end

function frame:UNIT_MAXMANA()
	if arg1 ~= "player" then return end

	local _, int = UnitStat("player", 4)
	if UnitPowerType("player") == 0 then
		maxMana = UnitManaMax("player")
		currMana = UnitMana("player")
		currInt = int
	elseif currInt ~= int then
		-- int buff maybe
		maxMana = maxMana + ((int - currInt) * 15)
		currInt = int
		if currMana > maxMana then
			currMana = maxMana
		end
	end

	self:Update()
end
frame.UNIT_INVENTORY_CHANGED = frame.UNIT_MAXMANA

function frame:PLAYER_AURAS_CHANGED()
	-- possibly losing the bear/cat buff
	if UnitPowerType("player") == 0 then
		regenMana = false
		SetMax_time = nil
		UpdateMana_time = nil
		killFSR_time = nil
		currMana = UnitMana("player")
		maxMana = UnitManaMax("player")
	end

	self:Update()
end

function frame:COMBAT_TEXT_UPDATE()
	if arg1 ~= "AURA_START" then return end

	-- if the spell is cast for either bear or cat, deduct the cost.
	-- we can't rely on UNIT_DISPLAYPOWER since you could switch from bear -> bear, never calling that, so we check the spellcast.
	if (bearName and arg2 == bearName) or (catName and arg2 == catName) then
		regenMana = true
		fiveSecondRule = true
		killFSR_time = GetTime() + 5
		currMana = currMana - getShapeshiftCost()
	end
end

function frame:LEARNED_SPELL_IN_TAB()
	for i = 1, GetNumSpellTabs() do
		local _, texture, offset, numSpells = GetSpellTabInfo(i)
		-- the spell tab that shows the bear is the feral tree, gonna check for bear form and cat form, gleam important info
		if strfind(texture, "Ability_Racial_BearForm") then
			for j = offset + 1, offset + numSpells do
				if strfind(GetSpellTexture(j, "spell"), "Ability_Racial_BearForm") then
					bearID = j
					bearName = GetSpellName(j, "spell")
				elseif strfind(GetSpellTexture(j, "spell"), "Ability_Druid_CatForm") then
					catName = GetSpellName(j, "spell")
				end
			end
			break
		end
	end
end

function frame:UpdateMana()
	local regen, castingRegen = GetManaRegen()
	print(regen, castingRegen, fiveSecondRule)
	if fiveSecondRule then
		currMana = currMana + floor(castingRegen * 2 + 0.5)
	else
		currMana = currMana + floor(regen * 2 + 0.5)
	end

	if currMana >= maxMana then
		currMana = maxMana

		-- we're at max mana, no need for any more checking
		SetMax_time = nil
		UpdateMana_time = nil
		killFSR_time = nil
	end

	self:Update()
end

function frame:SetMax()
	currMana = maxMana

	-- we're at max mana, no need for any more checking
	SetMax_time = nil
	UpdateMana_time = nil
	killFSR_time = nil

	self:Update()
end
local i = 0
local lastMaxMana, lastCurrMana = 0, 0
function frame:Update()
	if lastMaxMana == maxMana and lastCurrMana == currMana then return end

	lastMaxMana = maxMana
	lastCurrMana = currMana

	-- trigger event
	for func in pairs(registry) do
		local success, ret = pcall(func, currMana, maxMana)
		if not success then
			geterrorhandler()(ret)
		end
	end
end

if IsLoggedIn then
	frame:PLAYER_LOGIN()
else
	frame:RegisterEvent("PLAYER_LOGIN")
end

function lib:GetCurrentMana()
	return currMana
end

function lib:GetMaximumMana()
	return maxMana
end

function lib:AddListener(tab, method)
	local func
	if type(tab) == "table" then
		if type(method) ~= "string" then
			error(format("Bad argument #3 to `AddListener'. Expected %q, got %q.", "string", type(method)), 2)
		elseif type(tab[method]) ~= "function" then
			error(format("Bad argument #3 to `AddListener'. Expected method, got %q.", type(tab[method])), 2)
		end
		func = function(...)
			return tab[method](tab, unpack(arg))
		end
	elseif type(tab) == "function" then
		func = tab
		if method and type(method) ~= "string" then
			method = true
		end
	else
		error(format("Bad argument #2 to `AddListener'. Expected %q or %q, got %q.", "table", "function", type(tab)), 2)
	end

	registry[func] = method
end

function lib:RemoveListener(method)
	if type(method) ~= "string" then
		error(format("Bad argument #2 to `RemoveListener'. Expected %q, got %q.", "string", type(method)), 2)
	end

	for func, methodName in pairs(registry) do
		if methodName == method then
			registry[func] = nil
			break
		end
	end
end