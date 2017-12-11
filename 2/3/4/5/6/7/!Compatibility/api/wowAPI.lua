--Cache global variables
local _G = getfenv()
local assert = assert
local error = error
local type = type
local unpack = unpack
local date = date
local gsub = string.gsub

function hooksecurefunc(arg1, arg2, arg3)
	if type(arg1) == "string" then
		arg1, arg2, arg3 = _G, arg1, arg2
	end

	local orig = arg1[arg2]
	if type(orig) ~= "function" then
		error("The function "..arg2.." does not exist", 2)
	end

	arg1[arg2] = function(...)
		local tmp = {orig(unpack(arg))}
		arg3(unpack(arg))
		return unpack(tmp)
	end
end

local function noop() end
function HookScript(frame, method, func)
	assert(frame, "HookScript: frame argument missing")

	local orig = frame:GetScript(method) or noop
	frame:SetScript(method, function(...)
		local tmp = {orig(unpack(arg))}
		func(unpack(arg))
		return unpack(tmp)
	end)
end

function BetterDate(formatString, timeVal)
	local dateTable = date("*t", timeVal)
	local amString = (dateTable.hour >= 12) and "PM" or "AM"

	--First, we'll replace %p with the appropriate AM or PM.
	formatString = gsub(formatString, "^%%p", amString)	--Replaces %p at the beginning of the string with the am/pm token
	formatString = gsub(formatString, "([^%%])%%p", "%1"..amString) -- Replaces %p anywhere else in the string, but doesn't replace %%p (since the first % escapes the second)

	return date(formatString, timeVal)
end

RAID_CLASS_COLORS = {
	["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
	["WARLOCK"] = {r = 0.58, g = 0.51, b = 0.79},
	["PRIEST"] = {r = 1.0, g = 1.0, b = 1.0},
	["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
	["MAGE"] = {r = 0.41, g = 0.8, b = 0.94},
	["ROGUE"] = {r = 1.0, g = 0.96, b = 0.41},
	["DRUID"] = {r = 1.0, g = 0.49, b = 0.04},
	["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
};

QuestDifficultyColors = {
	["impossible"]		= {r = 1.00, g = 0.10, b = 0.10};
	["verydifficult"]	= {r = 1.00, g = 0.50, b = 0.25};
	["difficult"]		= {r = 1.00, g = 1.00, b = 0.00};
	["standard"]		= {r = 0.25, g = 0.75, b = 0.25};
	["trivial"]			= {r = 0.50, g = 0.50, b = 0.50};
	["header"]			= {r = 0.70, g = 0.70, b = 0.70};
};

function GetQuestDifficultyColor(level)
	local levelDiff = level - UnitLevel("player")
	local color
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

function EasyMenu(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
	if displayMode == "MENU" then
		menuFrame.displayMode = displayMode
	end
	UIDropDownMenu_Initialize(menuFrame, EasyMenu_Initialize, displayMode)
	ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList)
end

function EasyMenu_Initialize()
	print(level, info)
	for index = 1, getn(menuList) do
		local value = menuList[index]
		if value.text then
			value.index = index;
			UIDropDownMenu_AddButton(value, level)
		end
	end
end