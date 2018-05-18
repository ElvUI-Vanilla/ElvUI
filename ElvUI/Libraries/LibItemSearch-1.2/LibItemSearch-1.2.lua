--[[
	ItemSearch
		An item text search engine of some sort
--]]

local Search = LibStub("CustomSearch-1.0");
local Unfit = LibStub("Unfit-1.0");
local Lib = LibStub:NewLibrary("LibItemSearch-1.2", 11);
if Lib then
	Lib.Filters = {}
else
	return
end

local tonumber = tonumber
local find, strmatch, lower = string.find, string.match, string.lower

--[[ User API ]]--

function Lib:Matches(link, search)
	return Search(link, search, self.Filters)
end

function Lib:Tooltip(link, search)
	return link and strmatch(self.Filters.tip, link, nil, search)
end

function Lib:TooltipPhrase(link, search)
	return link and strmatch(self.Filters.tipPhrases, link, nil, search)
end

--[[ Basics ]]--

Lib.Filters.name = {
  	tags = {"n", "name"},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	match = function(self, item, _, search)
		local name = strmatch(item, "%[(.-)%]")
		return Search:Find(search, name)
	end
}

Lib.Filters.type = {
	tags = {"t", "type", "s", "slot"},

	canSearch = function(self, operator, search)
		return not operator and search
	end,

	match = function(self, item, _, search)
		local type, subType, _, equipSlot = select(6, GetItemInfo(item))
		return Search:Find(search, type, subType, _G[equipSlot])
	end
}

Lib.Filters.level = {
	tags = {"l", "level", "lvl", "ilvl"},

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	match = function(self, link, operator, num)
		local _, _, _, lvl = GetItemInfo(link)
		if lvl then
			return Search:Compare(operator, lvl, num)
		end
	end
}

Lib.Filters.requiredlevel = {
	tags = {"r", "req", "rl", "reql", "reqlvl"},

	canSearch = function(self, _, search)
		return tonumber(search)
	end,

	match = function(self, link, operator, num)
		local _, _, _, _, lvl = GetItemInfo(link)
		if lvl then
			return Search:Compare(operator, lvl, num)
		end
	end
}

--[[ Quality ]]--

local qualities = {}
for i = 0, getn(ITEM_QUALITY_COLORS) do
	qualities[i] = lower(_G["ITEM_QUALITY"..i.."_DESC"])
end

Lib.Filters.quality = {
	tags = {"q", "quality"},

	canSearch = function(self, _, search)
		for i, name in pairs(qualities) do
			if find(namesearch) then
				return i
			end
		end
	end,

	match = function(self, link, operator, num)
		local _, _, quality = GetItemInfo(link)
		return Search:Compare(operator, quality, num)
	end
}

--[[ Usable ]]--

Lib.Filters.usable = {
	tags = {},

	canSearch = function(self, operator, search)
		return not operator and search == "usable"
	end,

	match = function(self, link)
		if(not Unfit:IsItemUnusable(link)) then
			local _, _, _, _, lvl = GetItemInfo(link)
			return lvl and (lvl ~= 0 and lvl <= UnitLevel("player"))
		end
	end
}

--[[ Tooltip Searches ]]--

local scanner = LibItemSearchTooltipScanner or CreateFrame("GameTooltip", "LibItemSearchTooltipScanner", UIParent, "GameTooltipTemplate")

Lib.Filters.tip = {
	tags = {"tt", "tip", "tooltip"},

	onlyTags = true,

	canSearch = function(self, _, search)
		return search
	end,

	match = function(self, link, _, search)
		if find(link, "item:") then
			scanner:SetOwner(UIParent, "ANCHOR_NONE")
			scanner:SetHyperlink(link)

			for i = 1, scanner:NumLines() do
				if Search:Find(search, _G[scanner:GetName().."TextLeft"..i]:GetText()) then
					return true
				end
			end
		end
	end
}

local escapes = {
	["|c%x%x%x%x%x%x%x%x"] = "",
	["|r"] = ""
}

local function CleanString(str)
	for k, v in pairs(escapes) do
		str = string.gsub(str, k, v)
	end
	return str
end

Lib.Filters.tipPhrases = {
	canSearch = function(self, _, search)
		return self.keywords[search]
	end,

	match = function(self, link, _, search)
		local id = strmatch(link, "item:(%d+)")
		if not id then
			return
		end

		local cached = self.cache[search][id]
		if cached ~= nil then
			return cached
		end

		scanner:SetOwner(UIParent, "ANCHOR_NONE")
		scanner:SetHyperlink(link)

		local matches = false
		for i = 1, scanner:NumLines() do
			local text = _G["LibItemSearchTooltipScannerTextLeft"..i]:GetText()
			text = CleanString(text)
			if search == text then
				matches = true
				break
			end
		end

		self.cache[search][id] = matches
		return matches
	end,

	cache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end}),

	keywords = {
		[lower(ITEM_SOULBOUND)] = ITEM_BIND_ON_PICKUP,
		["bound"] = ITEM_BIND_ON_PICKUP,
		["bop"] = ITEM_BIND_ON_PICKUP,
		["boe"] = ITEM_BIND_ON_EQUIP,
		["bou"] = ITEM_BIND_ON_USE
	}
}