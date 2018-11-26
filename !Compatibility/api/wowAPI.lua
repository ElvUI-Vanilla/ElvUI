--Cache global variables
local _G = _G
local date = date
local error = error
local pairs = pairs
local select = select
local tonumber = tonumber
local type = type
local unpack = unpack
local find, format, gmatch, gsub, len, lower, match, upper, sub = string.find, string.format, string.gmatch, string.gsub, string.len, string.lower, string.match, string.upper, string.sub
local getn = table.getn
--WoW API
local debugstack = debugstack
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots
local GetInventoryItemTexture = GetInventoryItemTexture
local GetItemInfo = GetItemInfo
local GetQuestGreenRange = GetQuestGreenRange
local GetRealZoneText = GetRealZoneText
local IsInInstance = IsInInstance
--local UnitBuff = UnitBuff
--local UnitDebuff = UnitDebuff
local UnitLevel = UnitLevel
--WoW Variables
local DUNGEON_DIFFICULTY1 = DUNGEON_DIFFICULTY1
local DURABILITY_TEMPLATE = gsub(DURABILITY_TEMPLATE, "%%d / %%d", "(%%d+) / (%%d+)")
local NUM_BAG_FRAMES = NUM_BAG_FRAMES
local TIMEMANAGER_AM = gsub(TIME_TWELVEHOURAM, "^.-(%w+)$", "%1")
local TIMEMANAGER_PM = gsub(TIME_TWELVEHOURPM, "^.-(%w+)$", "%1")
--Libs
local LBC = LibStub("LibBabble-Class-3.0"):GetLookupTable()
local LBZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local IFDB = LibStub("ItemFamilyDB")

CLASS_SORT_ORDER = {
	"WARRIOR",
	"PALADIN",
	"PRIEST",
	"SHAMAN",
	"DRUID",
	"ROGUE",
	"MAGE",
	"WARLOCK",
	"HUNTER"
}
MAX_CLASSES = getn(CLASS_SORT_ORDER)

LOCALIZED_CLASS_NAMES_MALE = {}
LOCALIZED_CLASS_NAMES_FEMALE = {}

CLASS_ICON_TCOORDS = {
	["WARRIOR"] = {0, 0.25, 0, 0.25},
	["MAGE"] = {0.25, 0.49609375, 0, 0.25},
	["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"] = {0, 0.25, 0.25, 0.5},
	["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"] = {0, 0.25, 0.5, 0.75}
}

RAID_CLASS_COLORS = {
	["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
	["WARLOCK"] = { r = 0.53, g = 0.53, b = 0.93, colorStr = "ff8788ee" },
	["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
	["MAGE"] = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff3fc7eb" },
	["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
	["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
	["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
}

QuestDifficultyColors = {
	["impossible"] = {r = 1.00, g = 0.10, b = 0.10},
	["verydifficult"] = {r = 1.00, g = 0.50, b = 0.25},
	["difficult"] = {r = 1.00, g = 1.00, b = 0.00},
	["standard"] = {r = 0.25, g = 0.75, b = 0.25},
	["trivial"] = {r = 0.50, g = 0.50, b = 0.50},
	["header"] = {r = 0.70, g = 0.70, b = 0.70}
}

function HookScript(frame, scriptName, handler)
	if not (type(frame) == "table" and frame.GetScript and type(scriptName) == "string" and type(handler) == "function") then
		error("Usage: HookScript(frame, \"type\", function)", 2)
	end

	local original_scipt = frame:GetScript(scriptName)
	if original_scipt then
		frame:SetScript(scriptName, function()
			original_scipt(this)
			handler(this)
		end)
	else
		frame:SetScript(scriptName, handler)
	end
end

function hooksecurefunc(a1, a2, a3)
	local isMethod = type(a1) == "table" and type(a2) == "string" and type(a1[a2]) == "function" and type(a3) == "function"
	if not (isMethod or (type(a1) == "string" and type(_G[a1]) == "function" and type(a2) == "function")) then
		error("Usage: hooksecurefunc([table,] \"functionName\", hookfunc)", 2)
	end

	if not isMethod then
		a1, a2, a3 = _G, a1, a2
	end

	local original_func = a1[a2]

	a1[a2] = function(...)
		local original_return = {original_func(unpack(arg))}
		a3(unpack(arg))

		return unpack(original_return)
	end
end

local secureFunctions = {
	["CameraOrSelectOrMoveStop"] = true,
	["MoveBackwardStop"] = true,
	["MoveForwardStop"] = true,
	["PitchDownStop"] = true,
	["PitchUpStop"] = true,
	["StrafeLeftStart"] = true,
	["StrafeRightStart"] = true,
	["ToggleMouseMove"] = true,
	["TurnLeftStart"] = true,
	["TurnOrActionStop"] = true,
	["TurnRightStart"] = true,
	["CameraOrSelectOrMoveStart"] = true,
	["Jump"] = true,
	["MoveBackwardStart"] = true,
	["MoveForwardStart"] = true,
	["PitchDownStart"] = true,
	["PitchUpStart"] = true,
	["StrafeLeftStop"] = true,
	["StrafeRightStop"] = true,
	["ToggleRun"] = true,
	["TurnLeftStop"] = true,
	["TurnOrActionStart"] = true,
	["TurnRightStop"] = true
}
local secureScripts = {}
function issecurevariable(a1, a2)
--	local isMethod = type(a1) == "table" and type(a2) == "string" and type(a1[a2]) == "function"
--	if not (isMethod or (type(a1) == "string" and type(_G[a1]) == "function") then
--		error("Usage: issecurevariable([table,] \"variable\")", 2)
--	end
--
--	local isSecure
--	if isMethod then
--		isSecure = secureScripts[a2] and 1
--	else
--		isSecure = secureFunctions[a1] and 1
--	end
--
--	return isSecure

	if type(a1) == "table" then return end

	if type(a1) ~= "string" then
		error("Usage: issecurevariable([table,] \"variable\")", 2)
	end

	return secureFunctions[a1] and 1
end

function issecure()
	return
end

function securecall(f, ...)
	if arg.n > 0 then
		_G[f](unpack(arg))
	else
		_G[f]()
	end
end

function tContains(table, item)
	local index = 1

	while table[index] do
		if item == table[index] then
			return 1
		end
		index = index + 1
	end

	return
end

function UnitAura(unit, i, filter)
	if not ((type(unit) == "string" or type(unit) == "number") and (type(i) == "string" or type(i) == "number")) then
		error("Usage: UnitAura(\"unit\", index [, filter])", 2)
	end

	if not filter or match(filter, "(HELPFUL)") then
		local texture, count = UnitBuff(unit, i, filter)
		return texture, count
	else
		local texture, count, dType = UnitDebuff(unit, i, filter)
		return texture, count, dType
	end
end

function difftime(time2, time1)
	if type(time2) ~= "number" then
		error(format("bad argument #1 to 'difftime' (number expected, got %s)", time2 and type(time2) or "no value"), 2)
	elseif time1 and type(time1) ~= "number" then
		error(format("bad argument #2 to 'difftime' (number expected, got %s)", time1 and type(time1) or "no value"), 2)
	end

	return time1 and time2 - time1 or time2
end

function BetterDate(formatString, timeVal)
	local dateTable = date("*t", timeVal)
	local amString = (dateTable.hour >= 12) and "PM" or "AM"

	--First, we'll replace %p with the appropriate AM or PM.
	formatString = gsub(formatString, "^%%p", amString)	--Replaces %p at the beginning of the string with the am/pm token
	formatString = gsub(formatString, "([^%%])%%p", "%1"..amString) -- Replaces %p anywhere else in the string, but doesn't replace %%p (since the first % escapes the second)

	return date(formatString, timeVal)
end

function GetQuestDifficultyColor(level)
	local levelDiff = level - UnitLevel("player")
	if levelDiff >= 5 then
		return QuestDifficultyColors["impossible"]
	elseif levelDiff >= 3 then
		return QuestDifficultyColors["verydifficult"]
	elseif levelDiff >= -2 then
		return QuestDifficultyColors["difficult"]
	elseif -levelDiff <= GetQuestGreenRange() then
		return QuestDifficultyColors["standard"]
	else
		return QuestDifficultyColors["trivial"]
	end
end

function FillLocalizedClassList(tab, female)
	if type(tab) ~= "table" then
		error("Usage: FillLocalizedClassList(classTable[, isFemale])", 2)
	end

	for _, engClass in ipairs(CLASS_SORT_ORDER) do
		if female then
			tab[engClass] = LBC[engClass]
		else
			tab[engClass] = LBC[gsub(lower(engClass), "^%l", upper)]
		end
	end

	return true
end

FillLocalizedClassList(LOCALIZED_CLASS_NAMES_MALE)
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_FEMALE, true)

local zoneInfo = {
	-- Battlegrounds
	[LBZ["Warsong Gulch"]] = {mapID = 443, maxPlayers = 10},
	[LBZ["Arathi Basin"]] = {mapID = 461, maxPlayers = 15},
	[LBZ["Alterac Valley"]] = {mapID = 401, maxPlayers = 40},

	-- Raids
	[LBZ["Zul'Gurub"]] = {mapID = 309, maxPlayers = 20},
	[LBZ["Onyxia's Lair"]] = {mapID = 249, maxPlayers = 40},
	[LBZ["Molten Core"]] = {mapID = 409, maxPlayers = 40},
	[LBZ["Ruins of Ahn'Qiraj"]] = {mapID = 509, maxPlayers = 20},
	[LBZ["Temple of Ahn'Qiraj"]] = {mapID = 531, maxPlayers = 40},
	[LBZ["Blackwing Lair"]] = {mapID = 469, maxPlayers = 40},
	[LBZ["Naxxramas"]] = {mapID = 533, maxPlayers = 40},
}

local mapByID = {}
for mapName in pairs(zoneInfo) do
	mapByID[zoneInfo[mapName].mapID] = mapName
end

local function GetMaxPlayersByType(instanceType, zoneName)
	if instanceType == "none" then
		return 40
	elseif instanceType == "party" then
		return 5
	elseif zoneName ~= "" and zoneInfo[zoneName] then
		if instanceType == "pvp" then
			return zoneInfo[zoneName].maxPlayers
		elseif instanceType == "raid" then
			return zoneInfo[zoneName].maxPlayers
		end
	else
		return 0
	end
end

function GetInstanceInfo()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return end

	local name = GetRealZoneText()

	local difficulty = 1
	local maxPlayers = GetMaxPlayersByType(instanceType, name)
	local difficultyName = format("%d %s", maxPlayers, DUNGEON_DIFFICULTY1)

	return name, instanceType, difficulty, difficultyName, maxPlayers
end

function GetCurrentMapAreaID()
	if not IsInInstance() then return end
	local zoneName = GetRealZoneText()

	return zoneInfo[zoneName] and zoneInfo[zoneName].mapID or 0
end

function GetMapNameByID(id)
	if not (type(id) == "string" or type(id) == "number") then
		error(format("Bad argument #1 to \"GetMapNameByID\" (number expected, got %s)", id and type(id) or "no value"), 2)
	end

	return mapByID[tonumber(id)]
end

local arrow
function GetPlayerFacing()
	if not arrow then
		local obj = Minimap
		for i = 1, obj:GetNumChildren() do
			local child = select(i, obj:GetChildren())
			if child and child.GetModel and child:GetModel() == "Interface\\Minimap\\MinimapArrow" then
				arrow = child
				break
			end
		end
	end

	return arrow and arrow:GetFacing()
end

function ToggleFrame(frame)
	if frame:IsShown() then
		HideUIPanel(frame)
	else
		ShowUIPanel(frame)
	end
end

local function OnOrientationChanged(self, orientation)
	self.texturePointer.verticalOrientation = orientation == "VERTICAL"

	if self.texturePointer.verticalOrientation then
		self.texturePointer:SetPoint("BOTTOMLEFT", self)
	else
		self.texturePointer:SetPoint("LEFT", self)
	end
end

local function OnSizeChanged()
	local width, height = this:GetWidth(), this:GetHeight()

	this.texturePointer.width = width
	this.texturePointer.height = height
	this.texturePointer:SetWidth(width)
	this.texturePointer:SetHeight(height)
end

local function OnValueChanged()
	local _, max = this:GetMinMaxValues()

	if this.texturePointer.verticalOrientation then
		this.texturePointer:SetHeight(this.texturePointer.height * (arg1 / max))
	else
		this.texturePointer:SetWidth(this.texturePointer.width * (arg1 / max))
	end
end

function CreateStatusBarTexturePointer(statusbar)
	if type(statusbar) ~= "table" then
		error(format("Bad argument #1 to \"CreateStatusBarTexturePointer\" (table expected, got %s)", statusbar and type(statusbar) or "no value"), 2)
	elseif not (statusbar.GetObjectType and statusbar:GetObjectType() == "StatusBar") then
		error("Bad argument #1 to \"CreateStatusBarTexturePointer\" (statusbar object expected)", 2)
	end

	local f = statusbar:CreateTexture()
	f.width = statusbar:GetWidth()
	f.height = statusbar:GetHeight()
	f.vertical = statusbar:GetOrientation() == "VERTICAL"
	f:SetWidth(f.width)
	f:SetHeight(f.height)

	if f.verticalOrientation then
		f:SetPoint("BOTTOMLEFT", statusbar)
	else
		f:SetPoint("LEFT", statusbar)
	end

	statusbar.texturePointer = f

	statusbar:SetScript("OnSizeChanged", OnSizeChanged)
	statusbar:SetScript("OnValueChanged", OnValueChanged)

	hooksecurefunc(statusbar, "SetOrientation", OnOrientationChanged)

	return f
end

local function removeScript(self, script)
	local func = self:GetScript(script)

	if func then
		self:SetScript(script, nil)
	end

	return func
end

local nbsp = string.char(255)
function EditBoxGetCursorPosition(self)
	if self == WowLuaFrameEditBox or self == WowLuaFrameCommandEditBox then return 0 end

	if self:GetText() == "" then return 0 end

	local occ = removeScript(self, "OnCursorChanged")
	local otc = removeScript(self, "OnTextChanged")
	local ots = removeScript(self, "OnTextSet")

	local charsChanged, numeric

	local maxChars = self:GetMaxLetters()
	if maxChars == self:GetNumLetters() then
		self:SetMaxLetters(maxChars + 1)
		charsChanged = true
	end
	if self:IsNumeric() then
		self:SetNumeric(false)
		numeric = true
	end

	self:Insert(nbsp)

	local pos = find(self:GetText(), nbsp)
	if not pos then
		pos = len(self:GetText())
		print(format("CursorPosition position for `%s` not found!", self.GetName and self:GetName() or tostring(self)))
	else
		self:HighlightText(pos - 1, pos)
		self:Insert("")
	end

	if charsChanged then
		self:SetMaxLetters(maxChars)
	end
	if numeric then
		self:SetNumeric(true)
	end

	if occ then self:SetScript("OnCursorChanged", occ) end
	if otc then self:SetScript("OnTextChanged", otc) end
	if ots then self:SetScript("OnTextSet", ots) end

	return pos - 1
end

function EditBoxSetCursorPosition(self, pos)
	if self == WowLuaFrameEditBox or self == WowLuaFrameCommandEditBox then return end

	if self:GetText() == "" then return end

	local occ = removeScript(self, "OnCursorChanged")
	local otc = removeScript(self, "OnTextChanged")
	local ots = removeScript(self, "OnTextSet")

	local text = self:GetText()
	local size = len(text)

	if pos < 0 then
		pos = 0
	elseif pos > size then
		pos = size
	end

	if pos == 0 then
		local charsChanged, numeric

		local maxChars = self:GetMaxLetters()
		if maxChars == self:GetNumLetters() then
			self:SetMaxLetters(maxChars + 1)
			charsChanged = true
		end
		if self:IsNumeric() then
			self:SetNumeric(false)
			numeric = true
		end

		text = sub(text, 0, 1)
		self:HighlightText(0, 1)
		self:Insert(nbsp)
		self:Insert(text)
		self:HighlightText(0, 1)
		self:Insert("")

		if charsChanged then
			self:SetMaxLetters(maxChars)
		end
		if numeric then
			self:SetNumeric(true)
		end
	else
		text = sub(text, pos, pos)
		self:HighlightText(pos - 1, pos)
		self:Insert(text)
	end

	if occ then self:SetScript("OnCursorChanged", occ) end
	if otc then self:SetScript("OnTextChanged", otc) end
	if ots then self:SetScript("OnTextSet", ots) end
end

local threatColors = {
	[0] = {0.69, 0.69, 0.69},
	[1] = {1, 1, 0.47},
	[2] = {1, 0.6, 0},
	[3] = {1, 0, 0}
}

function GetThreatStatusColor(statusIndex)
	if not (type(statusIndex) == "number" and statusIndex >= 0 and statusIndex < 4) then
		statusIndex = 0
	end

	return threatColors[statusIndex][1], threatColors[statusIndex][2], threatColors[statusIndex][3]
end

function GetThreatStatus(currentThreat, maxThreat)
	if type(currentThreat) ~= "number" or type(maxThreat) ~= "number" then
		error("Usage: GetThreatStatus(currentThreat, maxThreat)", 2)
	end

	if not maxThreat or maxThreat == 0 then
		maxThreat = 1
	end

	local threatPercent = currentThreat / maxThreat * 100

	if threatPercent >= 100 then
		return 3, threatPercent
	elseif threatPercent < 100 and threatPercent >= 80 then
		return 2, threatPercent
	elseif threatPercent < 80 and threatPercent >= 50 then
		return 1, threatPercent
	else
		return 0, threatPercent
	end
end

local LAST_ITEM_ID = 24283
local itemInfoDB = {}

function GetItemInfoByName(itemName)
	if type(itemName) ~= "string" then
		error("Usage: GetItemInfoByName(itemName)", 2)
	end

	if find(itemName, " of ") then
		-- random enchantments
		itemName = gsub(itemName, " of Spirit", "")
		itemName = gsub(itemName, " of Intellect", "")
		itemName = gsub(itemName, " of Strength", "")
		itemName = gsub(itemName, " of Stamina", "")
		itemName = gsub(itemName, " of Agility", "")
		itemName = gsub(itemName, " of Defense", "")
		itemName = gsub(itemName, " of Nimbleness", "")
		itemName = gsub(itemName, " of Power", "")
		itemName = gsub(itemName, " of Speed", "")
		itemName = gsub(itemName, " of Frozen Wrath", "")
		itemName = gsub(itemName, " of Arcane Wrath", "")
		itemName = gsub(itemName, " of Fiery Wrath", "")
		itemName = gsub(itemName, " of Nature's Wrath", "")
		itemName = gsub(itemName, " of Shadow Wrath", "")
		itemName = gsub(itemName, " of Holy Wrath", "")
		itemName = gsub(itemName, " of Healing", "")
		itemName = gsub(itemName, " of Magic", "")
		itemName = gsub(itemName, " of Concentration", "")
		itemName = gsub(itemName, " of Regeneration", "")
		itemName = gsub(itemName, " of Fire Resistance", "")
		itemName = gsub(itemName, " of Nature Resistance", "")
		itemName = gsub(itemName, " of Arcane Resistance", "")
		itemName = gsub(itemName, " of Frost Resistance", "")
		itemName = gsub(itemName, " of Shadow Resistance", "")
		itemName = gsub(itemName, " of the Tiger", "")
		itemName = gsub(itemName, " of the Bear", "")
		itemName = gsub(itemName, " of the Gorilla", "")
		itemName = gsub(itemName, " of the Boar", "")
		itemName = gsub(itemName, " of the Monkey", "")
		itemName = gsub(itemName, " of the Falcon", "")
		itemName = gsub(itemName, " of the Wolf", "")
		itemName = gsub(itemName, " of the Eagle", "")
		itemName = gsub(itemName, " of the Whale", "")
		itemName = gsub(itemName, " of the Owl", "")
		itemName = gsub(itemName, " of Blocking", "")
		itemName = gsub(itemName, " of Eluding", "")
		itemName = gsub(itemName, " of the Invoker", "")
	end

	if not itemInfoDB[itemName] then
		local name
		for itemID = 1, LAST_ITEM_ID do
			name = GetItemInfo(itemID)

			if name ~= nil and name ~= "" then
				itemInfoDB[name] = itemID

				if name == itemName then
					break
				end
			end
		end
	end

	if not itemInfoDB[itemName] then return end

	return GetItemInfo(itemInfoDB[itemName])
end

function GetItemFamily(item, isBag)
	if not item or (type(item) ~= "number" and type(item) ~= "string") then return end

	if type(item) == "string" then
		local _, _, itemID = find(item, "(%d+):")
		if not itemID then return end
		item = tonumber(itemID)
	end

	if item > LAST_ITEM_ID then return end

	return (isBag and IFDB.BagFamily[item] or IFDB.ItemFamily[item]) or 0
end

function GetItemCount(itemName)
	if type(itemName) ~= "string" then return 0 end

	local count = 0

	for bag = NUM_BAG_FRAMES, 0, -1 do
		for slot = 1, GetContainerNumSlots(bag) do
			local _, itemCount = GetContainerItemInfo(bag, slot)

			if itemCount then
				local itemLink = GetContainerItemLink(bag, slot)
				local _, _, itemID = find(itemLink, "(%d+):")
				local queryName = GetItemInfo(itemID)

				if queryName and queryName == itemName then
					count = count + itemCount
				end
			end
		end
	end

	return count
end

local scanTooltip
function GetInventoryItemDurability(slot)
	if not GetInventoryItemTexture("player", slot) then return end

	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "Compatibility_ScanTooltip", nil, "ShoppingTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end

	scanTooltip:ClearLines()
	scanTooltip:SetInventoryItem("player", slot)

	for i = 4, scanTooltip:NumLines() do
		local text = _G["Compatibility_ScanTooltipTextLeft"..i]:GetText()
		for current, maximum in gmatch(text, DURABILITY_TEMPLATE) do
			return tonumber(current), tonumber(maximum)
		end
	end
end