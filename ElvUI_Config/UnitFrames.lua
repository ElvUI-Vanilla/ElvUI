local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

local ns = oUF
local ElvUF = ns.oUF

--Cache global variables
--Lua functions
local _G = _G
local find, format = string.find, string.format
local gsub, match, split = string.gsub, string.match, string.split
local concat, getn, insert, remove, wipe = table.concat, table.getn, table.insert, table.remove, table.wipe
local ipairs, pairs, select = ipairs, pairs, select
--WoW API / Variables
local GetScreenWidth = GetScreenWidth
local IsAddOnLoaded = IsAddOnLoaded

local COLOR, DELETE, FILTERS, FONT_SIZE = COLOR, DELETE, FILTERS, FONT_SIZE
local CLASS, GROUP, HEALTH, MANA, NAME, PLAYER = CLASS, GROUP, HEALTH, MANA, NAME, PLAYER
local ENERGY, FOCUS, RAGE = ENERGY, FOCUS, RAGE
local FACTION_STANDING_LABEL4 = FACTION_STANDING_LABEL4
local GENERAL, HIDE, NONE = GENERAL, HIDE, NONE

local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local ALT_KEY, CTRL_KEY, SHIFT_KEY = "ALT_KEY", "CTRL_KEY", "SHIFT_KEY"
------------------------------

local ACD = LibStub("AceConfigDialog-3.0")
local fillValues = {
	["fill"] = L["Filled"],
	["spaced"] = L["Spaced"],
	["inset"] = L["Inset"]
};

local positionValues = {
	TOPLEFT = "TOPLEFT",
	LEFT = "LEFT",
	BOTTOMLEFT = "BOTTOMLEFT",
	RIGHT = "RIGHT",
	TOPRIGHT = "TOPRIGHT",
	BOTTOMRIGHT = "BOTTOMRIGHT",
	CENTER = "CENTER",
	TOP = "TOP",
	BOTTOM = "BOTTOM",
};

local threatValues = {
	["GLOW"] = L["Glow"],
	["BORDERS"] = L["Borders"],
	["HEALTHBORDER"] = L["Health Border"],
	["INFOPANELBORDER"] = L["InfoPanel Border"],
	["ICONTOPLEFT"] = L["Icon: TOPLEFT"],
	["ICONTOPRIGHT"] = L["Icon: TOPRIGHT"],
	["ICONBOTTOMLEFT"] = L["Icon: BOTTOMLEFT"],
	["ICONBOTTOMRIGHT"] = L["Icon: BOTTOMRIGHT"],
	["ICONLEFT"] = L["Icon: LEFT"],
	["ICONRIGHT"] = L["Icon: RIGHT"],
	["ICONTOP"] = L["Icon: TOP"],
	["ICONBOTTOM"] = L["Icon: BOTTOM"],
	["NONE"] = "NONE"
}

local petAnchors = {
	TOPLEFT = "TOPLEFT",
	LEFT = "LEFT",
	BOTTOMLEFT = "BOTTOMLEFT",
	RIGHT = "RIGHT",
	TOPRIGHT = "TOPRIGHT",
	BOTTOMRIGHT = "BOTTOMRIGHT",
	TOP = "TOP",
	BOTTOM = "BOTTOM",
};

local auraBarsSortValues = {
	["TIME_REMAINING"] = L["Time Remaining"],
	["TIME_REMAINING_REVERSE"] = L["Time Remaining Reverse"],
	["TIME_DURATION"] = L["Duration"],
	["TIME_DURATION_REVERSE"] = L["Duration Reverse"],
	["NAME"] = "NAME",
	["NONE"] = "NONE",
}

local auraSortValues = {
	["TIME_REMAINING"] = L["Time Remaining"],
	["DURATION"] = L["Duration"],
	["NAME"] = NAME,
	["INDEX"] = L["Index"],
	["PLAYER"] = PLAYER,
}

local auraSortMethodValues = {
	["ASCENDING"] = L["Ascending"],
	["DESCENDING"] = L["Descending"]
}

local CUSTOMTEXT_CONFIGS = {}

local carryFilterFrom, carryFilterTo
local function filterValue(value)
	return gsub(value,"([%(%)%.%%%+%-%*%?%[%^%$])","%%%1")
end

local function filterMatch(s,v)
	local m1, m2, m3, m4 = "^"..v.."$", "^"..v..",", ","..v.."$", ","..v..","
	return (match(s, m1) and m1) or (match(s, m2) and m2) or (match(s, m3) and m3) or (match(s, m4) and v..",")
end

local function filterPriority(auraType, groupName, value, remove, movehere, friendState)
	if not auraType or not value then return end
	local filter = E.db.unitframe.units[groupName] and E.db.unitframe.units[groupName][auraType] and E.db.unitframe.units[groupName][auraType].priority
	if not filter then return end
	local found = filterMatch(filter, filterValue(value))
	if found and movehere then
		local tbl, sv, sm = {split(",", filter)}
		for i in ipairs(tbl) do
			if tbl[i] == value then sv = i elseif tbl[i] == movehere then sm = i end
			if sv and sm then break end
		end
		remove(tbl, sm);insert(tbl, sv, movehere);
		E.db.unitframe.units[groupName][auraType].priority = concat(tbl,",")
	elseif found and friendState then
		local realValue = match(value, "^Friendly:([^,]*)") or match(value, "^Enemy:([^,]*)") or value
		local friend = filterMatch(filter, filterValue("Friendly:"..realValue))
		local enemy = filterMatch(filter, filterValue("Enemy:"..realValue))
		local default = filterMatch(filter, filterValue(realValue))

		local state =
			(friend and (not enemy) and format("%s%s","Enemy:",realValue))					--[x] friend [ ] enemy: > enemy
		or	((not enemy and not friend) and format("%s%s","Friendly:",realValue))			--[ ] friend [ ] enemy: > friendly
		or	(enemy and (not friend) and default and format("%s%s","Friendly:",realValue))	--[ ] friend [x] enemy: (default exists) > friendly
		or	(enemy and (not friend) and match(value, "^Enemy:") and realValue)				--[ ] friend [x] enemy: (no default) > realvalue
		or	(friend and enemy and realValue)												--[x] friend [x] enemy: > default

		if state then
			local stateFound = filterMatch(filter, filterValue(state))
			if not stateFound then
				local tbl, sv, sm = {split(",", filter)}
				for i in ipairs(tbl) do
					if tbl[i] == value then sv = i;break end
				end
				insert(tbl, sv, state);remove(tbl, sv+1)
				E.db.unitframe.units[groupName][auraType].priority = concat(tbl,",")
			end
		end
	elseif found and remove then
		E.db.unitframe.units[groupName][auraType].priority = gsub(filter, found, "")
	elseif not found and not remove then
		E.db.unitframe.units[groupName][auraType].priority = (filter == "" and value) or (filter..","..value)
	end
end

-----------------------------------------------------------------------
-- OPTIONS TABLES
-----------------------------------------------------------------------
local function GetOptionsTable_AuraBars(friendlyOnly, updateFunc, groupName)
	local config = {
		order = 1100,
		type = "group",
		name = L["Aura Bars"],
		get = function(info) return E.db.unitframe.units[groupName]["aurabar"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["aurabar"][ info[getn(info)] ] = value; updateFunc(UF, groupName) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Aura Bars"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
			},
			configureButton1 = {
				order = 3,
				name = L["Coloring"],
				desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
				type = "execute",
				func = function() ACD:SelectGroup("ElvUI", "unitframe", "generalOptionsGroup", "allColorsGroup", "auraBars") end,
			},
			configureButton2 = {
				order = 4,
				name = L["Coloring (Specific)"],
				type = "execute",
				func = function() E:SetToFilterConfig("AuraBar Colors") end,
			},
			anchorPoint = {
				type = "select",
				order = 5,
				name = L["Anchor Point"],
				desc = L["What point to anchor to the frame you set to attach to."],
				values = {
					["ABOVE"] = L["Above"],
					["BELOW"] = L["Below"],
				},
			},
			attachTo = {
				type = "select",
				order = 6,
				name = L["Attach To"],
				desc = L["The object you want to attach to."],
				values = {
					["FRAME"] = L["Frame"],
					["DEBUFFS"] = L["Debuffs"],
					["BUFFS"] = L["Buffs"],
				},
			},
			height = {
				type = "range",
				order = 7,
				name = L["Height"],
				min = 6, max = 40, step = 1,
			},
			maxBars = {
				type = "range",
				order = 8,
				name = L["Max Bars"],
				min = 1, max = 40, step = 1,
			},
			sort = {
				type = "select",
				order = 9,
				name = L["Sort Method"],
				values = auraBarsSortValues,
			},
			filters = {
				name = FILTERS,
				guiInline = true,
				type = "group",
				order = 500,
				args = {},
			},
			friendlyAuraType = {
				type = "select",
				order = 16,
				name = L["Friendly Aura Type"],
				desc = L["Set the type of auras to show when a unit is friendly."],
				values = {
					["HARMFUL"] = L["Debuffs"],
					["HELPFUL"] = L["Buffs"],
				},
			},
			enemyAuraType = {
				type = "select",
				order = 17,
				name = L["Enemy Aura Type"],
				desc = L["Set the type of auras to show when a unit is a foe."],
				values = {
					["HARMFUL"] = L["Debuffs"],
					["HELPFUL"] = L["Buffs"],
				},
			},
			uniformThreshold = {
				order = 18,
				type = "range",
				name = L["Uniform Threshold"],
				desc = L["Seconds remaining on the aura duration before the bar starts moving. Set to 0 to disable."],
				min = 0, max = 3600, step = 1,
			},
			yOffset = {
				order = 19,
				type = "range",
				name = L["yOffset"],
				min = -1000, max = 1000, step = 1,
			},
		},
	}

	if groupName == "target" then
		config.args.attachTo.values["PLAYER_AURABARS"] = L["Player Frame Aura Bars"]
	end

	config.args.filters.args.minDuration = {
		order = 16,
		type = "range",
		name = L["Minimum Duration"],
		desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
		min = 0, max = 10800, step = 1,
	}
	config.args.filters.args.maxDuration = {
		order = 17,
		type = "range",
		name = L["Maximum Duration"],
		desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
		min = 0, max = 10800, step = 1,
	}
	config.args.filters.args.jumpToFilter = {
		order = 18,
		name = L["Filters Page"],
		desc = L["Shortcut to 'Filters' section of the config."],
		type = "execute",
		func = function() ACD:SelectGroup("ElvUI", "filters") end,
	}
	config.args.filters.args.specialPriority = {
		order = 19,
		name = L["Add Special Filter"],
		desc = L["These filters don't use a list of spells like the regular filters. Instead they use the WoW API and some code logic to determine if an aura should be allowed or blocked."],
		type = "select",
		values = function()
			local filters = {}
			local list = E.global.unitframe["specialFilters"]
			if not list then return end
			for filter in pairs(list) do
				filters[filter] = filter
			end
			return filters
		end,
		set = function(info, value)
			filterPriority("aurabar", groupName, value)
			updateFunc(UF, groupName)
		end
	}
	config.args.filters.args.priority = {
		order = 20,
		name = L["Add Regular Filter"],
		desc = L["These filters use a list of spells to determine if an aura should be allowed or blocked. The content of these filters can be modified in the 'Filters' section of the config."],
		type = "select",
		values = function()
			local filters = {}
			local list = E.global.unitframe["aurafilters"]
			if not list then return end
			for filter in pairs(list) do
				filters[filter] = filter
			end
			return filters
		end,
		set = function(info, value)
			filterPriority("aurabar", groupName, value)
			updateFunc(UF, groupName)
		end
	}
	config.args.filters.args.resetPriority = {
		order = 21,
		name = L["Reset Priority"],
		desc = L["Reset filter priority to the default state."],
		type = "execute",
		func = function()
			E.db.unitframe.units[groupName].aurabar.priority = P.unitframe.units[groupName].aurabar.priority
			updateFunc(UF, groupName)
		end,
	}
	-- config.args.filters.args.filterPriority = {
	-- 	order = 22,
	-- 	dragdrop = true,
	-- 	type = "multiselect",
	-- 	name = L["Filter Priority"],
	-- 	dragOnLeave = function() end, --keep this here
	-- 	dragOnEnter = function(info, value)
	-- 		carryFilterTo = info.obj.value
	-- 	end,
	-- 	dragOnMouseDown = function(info, value)
	-- 		carryFilterFrom, carryFilterTo = info.obj.value, nil
	-- 	end,
	-- 	dragOnMouseUp = function(info, value)
	-- 		filterPriority("aurabar", groupName, carryFilterTo, nil, carryFilterFrom) --add it in the new spot
	-- 		carryFilterFrom, carryFilterTo = nil, nil
	-- 	end,
	-- 	dragOnClick = function(info, value)
	-- 		filterPriority("aurabar", groupName, carryFilterFrom, true)
	-- 	end,
	-- 	stateSwitchGetText = function(button, text, value)
	-- 		local friend, enemy = match(text, "^Friendly:([^,]*)"), match(text, "^Enemy:([^,]*)")
	-- 		return (friend and format("|cFF33FF33%s|r %s", L["Friend"], friend)) or (enemy and format("|cFFFF3333%s|r %s", L["Enemy"], enemy))
	-- 	end,
	-- 	stateSwitchOnClick = function(info, value)
	-- 		filterPriority("aurabar", groupName, carryFilterFrom, nil, nil, true)
	-- 	end,
	-- 	values = function()
	-- 		local str = E.db.unitframe.units[groupName].aurabar.priority
	-- 		if str == "" then return nil end
	-- 		return {split(",", str)}
	-- 	end,
	-- 	get = function(info, value)
	-- 		local str = E.db.unitframe.units[groupName].aurabar.priority
	-- 		if str == "" then return nil end
	-- 		local tbl = {split(",", str)}
	-- 		return tbl[value]
	-- 	end,
	-- 	set = function(info, value)
	-- 		E.db.unitframe.units[groupName].aurabar[ info[getn(info)] ] = nil -- this was being set when drag and drop was first added, setting it to nil to clear tester profiles of this variable
	-- 		updateFunc(UF, groupName)
	-- 	end
	-- }
	-- config.args.filters.args.spacer1 = {
	-- 	order = 23,
	-- 	type = "description",
	-- 	name = L["Use drag and drop to rearrange filter priority or right click to remove a filter."].."\n"..L["Use Shift+LeftClick to toggle between friendly or enemy or normal state. Normal state will allow the filter to be checked on all units. Friendly state is for friendly units only and enemy state is for enemy units."],
	-- }

	return config
end

local function GetOptionsTable_Auras(friendlyUnitOnly, auraType, isGroupFrame, updateFunc, groupName, numUnits)
	local config = {
		order = auraType == "buffs" and 600 or 700,
		type = "group",
		name = auraType == "buffs" and L["Buffs"] or L["Debuffs"],
		get = function(info) return E.db.unitframe.units[groupName][auraType][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName][auraType][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				type = "header",
				order = 1,
				name = auraType == "buffs" and L["Buffs"] or L["Debuffs"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
			},
			perrow = {
				type = "range",
				order = 3,
				name = L["Per Row"],
				min = 1, max = 20, step = 1,
			},
			numrows = {
				type = "range",
				order = 4,
				name = L["Num Rows"],
				min = 1, max = 10, step = 1,
			},
			sizeOverride = {
				type = "range",
				order = 5,
				name = L["Size Override"],
				desc = L["If not set to 0 then override the size of the aura icon to this."],
				min = 0, max = 60, step = 1,
			},
			xOffset = {
				order = 6,
				type = "range",
				name = L["xOffset"],
				min = -1000, max = 1000, step = 1,
			},
			yOffset = {
				order = 7,
				type = "range",
				name = L["yOffset"],
				min = -1000, max = 1000, step = 1,
			},
			anchorPoint = {
				type = "select",
				order = 8,
				name = L["Anchor Point"],
				desc = L["What point to anchor to the frame you set to attach to."],
				values = positionValues,
			},
			fontSize = {
				order = 9,
				name = FONT_SIZE,
				type = "range",
				min = 6, max = 212, step = 1,
			},
			clickThrough = {
				order = 15,
				name = L["Click Through"],
				desc = L["Ignore mouse events."],
				type = "toggle",
			},
			sortMethod = {
				order = 16,
				name = L["Sort By"],
				desc = L["Method to sort by."],
				type = "select",
				values = auraSortValues,
			},
			sortDirection = {
				order = 16,
				name = L["Sort Direction"],
				desc = L["Ascending or Descending order."],
				type = "select",
				values = auraSortMethodValues,
			},
			filters = {
				name = FILTERS,
				guiInline = true,
				type = "group",
				order = 500,
				args = {},
			},
		},
	}

	if auraType == "buffs" then
		config.args.attachTo = {
			type = "select",
			order = 7,
			name = L["Attach To"],
			desc = L["What to attach the buff anchor frame to."],
			values = {
				["FRAME"] = L["Frame"],
				["DEBUFFS"] = L["Debuffs"],
				["HEALTH"] = HEALTH,
				["POWER"] = L["Power"],
			},
		}
	else
		config.args.attachTo = {
			type = "select",
			order = 7,
			name = L["Attach To"],
			desc = L["What to attach the debuff anchor frame to."],
			values = {
				["FRAME"] = L["Frame"],
				["BUFFS"] = L["Buffs"],
				["HEALTH"] = HEALTH,
				["POWER"] = L["Power"],
			},
		}
	end

	if isGroupFrame then
		config.args.countFontSize = {
			order = 10,
			name = L["Count Font Size"],
			type = "range",
			min = 6, max = 212, step = 1,
		}
	end

	config.args.filters.args.minDuration = {
		order = 16,
		type = "range",
		name = L["Minimum Duration"],
		desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
		min = 0, max = 10800, step = 1,
	}
	config.args.filters.args.maxDuration = {
		order = 17,
		type = "range",
		name = L["Maximum Duration"],
		desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
		min = 0, max = 10800, step = 1,
	}
	config.args.filters.args.jumpToFilter = {
		order = 18,
		name = L["Filters Page"],
		desc = L["Shortcut to 'Filters' section of the config."],
		type = "execute",
		func = function() ACD:SelectGroup("ElvUI", "filters") end,
	}
	config.args.filters.args.specialPriority = {
		order = 19,
		name = L["Add Special Filter"],
		desc = L["These filters don't use a list of spells like the regular filters. Instead they use the WoW API and some code logic to determine if an aura should be allowed or blocked."],
		type = "select",
		values = function()
			local filters = {}
			local list = E.global.unitframe["specialFilters"]
			if not list then return end
			for filter in pairs(list) do
				filters[filter] = filter
			end
			return filters
		end,
		set = function(info, value)
			filterPriority(auraType, groupName, value)
			updateFunc(UF, groupName, numUnits)
		end
	}
	config.args.filters.args.priority = {
		order = 20,
		name = L["Add Regular Filter"],
		desc = L["These filters use a list of spells to determine if an aura should be allowed or blocked. The content of these filters can be modified in the 'Filters' section of the config."],
		type = "select",
		values = function()
			local filters = {}
			local list = E.global.unitframe["aurafilters"]
			if not list then return end
			for filter in pairs(list) do
				filters[filter] = filter
			end
			return filters
		end,
		set = function(info, value)
			filterPriority(auraType, groupName, value)
			updateFunc(UF, groupName, numUnits)
		end
	}
	config.args.filters.args.resetPriority = {
		order = 21,
		name = L["Reset Priority"],
		desc = L["Reset filter priority to the default state."],
		type = "execute",
		func = function()
			E.db.unitframe.units[groupName][auraType].priority = P.unitframe.units[groupName][auraType].priority
			updateFunc(UF, groupName, numUnits)
		end,
	}
	-- config.args.filters.args.filterPriority = {
	-- 	order = 22,
	-- 	dragdrop = true,
	-- 	type = "multiselect",
	-- 	name = L["Filter Priority"],
	-- 	dragOnLeave = function() end, --keep this here
	-- 	dragOnEnter = function(info, value)
	-- 		carryFilterTo = info.obj.value
	-- 	end,
	-- 	dragOnMouseDown = function(info, value)
	-- 		carryFilterFrom, carryFilterTo = info.obj.value, nil
	-- 	end,
	-- 	dragOnMouseUp = function(info, value)
	-- 		filterPriority(auraType, groupName, carryFilterTo, nil, carryFilterFrom) --add it in the new spot
	-- 		carryFilterFrom, carryFilterTo = nil, nil
	-- 	end,
	-- 	dragOnClick = function(info, value)
	-- 		filterPriority(auraType, groupName, carryFilterFrom, true)
	-- 	end,
	-- 	stateSwitchGetText = function(button, text, value)
	-- 		local friend, enemy = match(text, "^Friendly:([^,]*)"), match(text, "^Enemy:([^,]*)")
	-- 		return (friend and format("|cFF33FF33%s|r %s", L["Friend"], friend)) or (enemy and format("|cFFFF3333%s|r %s", L["Enemy"], enemy))
	-- 	end,
	-- 	stateSwitchOnClick = function(info, value)
	-- 		filterPriority(auraType, groupName, carryFilterFrom, nil, nil, true)
	-- 	end,
	-- 	values = function()
	-- 		local str = E.db.unitframe.units[groupName][auraType].priority
	-- 		if str == "" then return nil end
	-- 		return {split(",", str)}
	-- 	end,
	-- 	get = function(info, value)
	-- 		local str = E.db.unitframe.units[groupName][auraType].priority
	-- 		if str == "" then return nil end
	-- 		local tbl = {split(",", str)}
	-- 		return tbl[value]
	-- 	end,
	-- 	set = function(info, value)
	-- 		E.db.unitframe.units[groupName][auraType][ info[getn(info)] ] = nil -- this was being set when drag and drop was first added, setting it to nil to clear tester profiles of this variable
	-- 		updateFunc(UF, groupName, numUnits)
	-- 	end
	-- }
	-- config.args.filters.args.spacer1 = {
	-- 	order = 23,
	-- 	type = "description",
	-- 	name = L["Use drag and drop to rearrange filter priority or right click to remove a filter."].."\n"..L["Use Shift+LeftClick to toggle between friendly or enemy or normal state. Normal state will allow the filter to be checked on all units. Friendly state is for friendly units only and enemy state is for enemy units."],
	-- }

	return config
end

local function GetOptionsTable_Castbar(updateFunc, groupName, numUnits)
	local config = {
		order = 800,
		type = "group",
		name = L["Castbar"],
		get = function(info) return E.db.unitframe.units[groupName]["castbar"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["castbar"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Castbar"],
			},
			matchsize = {
				order = 2,
				type = "execute",
				name = L["Match Frame Width"],
				func = function() E.db.unitframe.units[groupName]["castbar"]["width"] = E.db.unitframe.units[groupName]["width"]; updateFunc(UF, groupName, numUnits) end,
			},
			forceshow = {
				order = 3,
				name = L["Show"].." / "..HIDE,
				func = function()
					local frameName = E:StringTitle(groupName)
					frameName = "ElvUF_"..frameName
					frameName = gsub(frameName, "t(arget)", "T%1")

					if numUnits then
						for i = 1, numUnits do
							local castbar = _G[frameName..i].Castbar
							if not castbar.oldHide then
								castbar.oldHide = castbar.Hide
								castbar.Hide = castbar.Show
								castbar:Show()
							else
								castbar.Hide = castbar.oldHide
								castbar.oldHide = nil
								castbar:Hide()
							end
						end
					else
						local castbar = _G[frameName].Castbar
						if not castbar.oldHide then
							castbar.oldHide = castbar.Hide
							castbar.Hide = castbar.Show
							castbar:Show()
						else
							castbar.Hide = castbar.oldHide
							castbar.oldHide = nil
							castbar:Hide()
						end
					end
				end,
				type = "execute",
			},
			configureButton = {
				order = 4,
				type = "execute",
				name = L["Coloring"],
				desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
				func = function() ACD:SelectGroup("ElvUI", "unitframe", "generalOptionsGroup", "allColorsGroup", "castBars") end
			},
			enable = {
				order = 5,
				type = "toggle",
				name = L["Enable"]
			},
			width = {
				order = 6,
				type = "range",
				name = L["Width"],
				softMax = 600,
				min = 50, max = GetScreenWidth(), step = 1
			},
			height = {
				order = 7,
				type = "range",
				name = L["Height"],
				min = 10, max = 85, step = 1
			},
			format = {
				order = 8,
				type = "select",
				name = L["Format"],
				values = {
					["CURRENTMAX"] = L["Current / Max"],
					["CURRENT"] = L["Current"],
					["REMAINING"] = L["Remaining"]
				}
			},
			spark = {
				order = 9,
				type = "toggle",
				name = L["Spark"],
				desc = L["Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop."]
			},
			insideInfoPanel = {
				order = 10,
				type = "toggle",
				name = L["Inside Information Panel"],
				desc = L["Display the castbar inside the information panel, the icon will be displayed outside the main unitframe."],
				disabled = function() return not E.db.unitframe.units[groupName].infoPanel or not E.db.unitframe.units[groupName].infoPanel.enable end
			},
			iconSettings = {
				order = 11,
				type = "group",
				name = L["Icon"],
				guiInline = true,
				get = function(info) return E.db.unitframe.units[groupName]["castbar"][ info[getn(info)] ] end,
				set = function(info, value) E.db.unitframe.units[groupName]["castbar"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
				args = {
					icon = {
						order = 1,
						type = "toggle",
						name = L["Enable"]
					},
					iconAttached = {
						order = 2,
						type = "toggle",
						name = L["Icon Inside Castbar"],
						desc = L["Display the castbar icon inside the castbar."]
					},
					iconSize = {
						order = 3,
						type = "range",
						name = L["Icon Size"],
						desc = L["This dictates the size of the icon when it is not attached to the castbar."],
						disabled = function() return E.db.unitframe.units[groupName].castbar.iconAttached end,
						min = 8, max = 150, step = 1
					},
					iconAttachedTo = {
						order = 4,
						type = "select",
						name = L["Attach To"],
						disabled = function() return E.db.unitframe.units[groupName].castbar.iconAttached end,
						values = {
							["Frame"] = L["Frame"],
							["Castbar"] = L["Castbar"]
						}
					},
					iconPosition = {
						type = "select",
						order = 5,
						name = L["Position"],
						values = positionValues,
						disabled = function() return E.db.unitframe.units[groupName].castbar.iconAttached end
					},
					iconXOffset = {
						order = 5,
						type = "range",
						name = L["xOffset"],
						min = -300, max = 300, step = 1,
						disabled = function() return E.db.unitframe.units[groupName].castbar.iconAttached end
					},
					iconYOffset = {
						order = 6,
						type = "range",
						name = L["yOffset"],
						min = -300, max = 300, step = 1,
						disabled = function() return E.db.unitframe.units[groupName].castbar.iconAttached end
					}
				}
			}
		}
	}

	return config
end

local function GetOptionsTable_InformationPanel(updateFunc, groupName, numUnits)

	local config = {
		order = 4000,
		type = "group",
		name = L["Information Panel"],
		get = function(info) return E.db.unitframe.units[groupName]["infoPanel"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["infoPanel"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Information Panel"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
			},
			transparent = {
				type = "toggle",
				order = 3,
				name = L["Transparent"],
			},
			height = {
				type = "range",
				order = 4,
				name = L["Height"],
				min = 4, max = 30, step = 1,
			},
		}
	}

	return config
end

local function GetOptionsTable_Health(isGroupFrame, updateFunc, groupName, numUnits)
	local config = {
		order = 100,
		type = "group",
		name = HEALTH,
		get = function(info) return E.db.unitframe.units[groupName]["health"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["health"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = HEALTH,
			},
			position = {
				type = "select",
				order = 2,
				name = L["Text Position"],
				values = positionValues,
			},
			xOffset = {
				order = 3,
				type = "range",
				name = L["Text xOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 4,
				type = "range",
				name = L["Text yOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			attachTextTo = {
				type = "select",
				order = 5,
				name = L["Attach Text To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
			text_format = {
				order = 100,
				name = L["Text Format"],
				type = "input",
				width = "full",
				desc = L["TEXT_FORMAT_DESC"],
			},
			configureButton = {
				order = 6,
				name = L["Coloring"],
				desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
				type = "execute",
				func = function() ACD:SelectGroup("ElvUI", "unitframe", "generalOptionsGroup", "allColorsGroup", "healthGroup") end,
			},
		},
	}

	if isGroupFrame then
		config.args.frequentUpdates = {
			type = "toggle",
			order = 2,
			name = L["Frequent Updates"],
			desc = L["Rapidly update the health, uses more memory and cpu. Only recommended for healing."],
		}

		config.args.orientation = {
			type = "select",
			order = 3,
			name = L["Statusbar Fill Orientation"],
			desc = L["Direction the health bar moves when gaining/losing health."],
			values = {
				["HORIZONTAL"] = L["Horizontal"],
				["VERTICAL"] = L["Vertical"],
			},
		}
	end

	return config
end

local function CreateCustomTextGroup(unit, objectName)
	if not E.Options.args.unitframe.args[unit] then
		return
	elseif E.Options.args.unitframe.args[unit].args.customText.args[objectName] then
		E.Options.args.unitframe.args[unit].args.customText.args[objectName].hidden = false -- Re-show existing custom texts which belong to current profile and were previously hidden
		insert(CUSTOMTEXT_CONFIGS, E.Options.args.unitframe.args[unit].args.customText.args[objectName]) --Register this custom text config to be hidden again on profile change
		return
	end

	E.Options.args.unitframe.args[unit].args.customText.args[objectName] = {
		order = -1,
		type = "group",
		name = objectName,
		get = function(info) return E.db.unitframe.units[unit].customTexts[objectName][ info[getn(info)] ] end,
		set = function(info, value)
			E.db.unitframe.units[unit].customTexts[objectName][ info[getn(info)] ] = value;

			if unit == "party" or find(unit, "raid") then
				UF:CreateAndUpdateHeaderGroup(unit)
			else
				UF:CreateAndUpdateUF(unit)
			end
		end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = objectName,
			},
			delete = {
				type = "execute",
				order = 2,
				name = DELETE,
				func = function()
					E.Options.args.unitframe.args[unit].args.customText.args[objectName] = nil;
					E.db.unitframe.units[unit].customTexts[objectName] = nil;

					if unit == "party" or find(unit, "raid") then
						for i=1, UF[unit]:GetNumChildren() do
							local child = select(i, UF[unit]:GetChildren())
							if child.Tag then
								child:Tag(child["customTexts"][objectName], "");
								child["customTexts"][objectName]:Hide();
							else
								for x=1, child:GetNumChildren() do
									local c2 = select(x, child:GetChildren())
									if(c2.Tag) then
										c2:Tag(c2["customTexts"][objectName], "");
										c2["customTexts"][objectName]:Hide();
									end
								end
							end
						end
					elseif UF[unit] then
						UF[unit]:Tag(UF[unit]["customTexts"][objectName], "");
						UF[unit]["customTexts"][objectName]:Hide();
					end
				end,
			},
			font = {
				type = "select", dialogControl = "LSM30_Font",
				order = 3,
				name = L["Font"],
				values = AceGUIWidgetLSMlists.font,
			},
			size = {
				order = 4,
				name = FONT_SIZE,
				type = "range",
				min = 4, max = 212, step = 1,
			},
			fontOutline = {
				order = 5,
				name = L["Font Outline"],
				desc = L["Set the font outline."],
				type = "select",
				values = {
					["NONE"] = NONE,
					["OUTLINE"] = "OUTLINE",

					["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
					["THICKOUTLINE"] = "THICKOUTLINE",
				},
			},
			justifyH = {
				order = 6,
				type = "select",
				name = L["JustifyH"],
				desc = L["Sets the font instance's horizontal text alignment style."],
				values = {
					["CENTER"] = L["Center"],
					["LEFT"] = L["Left"],
					["RIGHT"] = L["Right"],
				},
			},
			xOffset = {
				order = 7,
				type = "range",
				name = L["xOffset"],
				min = -400, max = 400, step = 1,
			},
			yOffset = {
				order = 8,
				type = "range",
				name = L["yOffset"],
				min = -400, max = 400, step = 1,
			},
			attachTextTo = {
				type = "select",
				order = 9,
				name = L["Attach Text To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
			text_format = {
				order = 100,
				name = L["Text Format"],
				type = "input",
				width = "full",
				desc = L["TEXT_FORMAT_DESC"],
			},
		},
	}

	insert(CUSTOMTEXT_CONFIGS, E.Options.args.unitframe.args[unit].args.customText.args[objectName]) --Register this custom text config to be hidden on profile change
end

local function GetOptionsTable_CustomText(updateFunc, groupName, numUnits, orderOverride)
	local config = {
		order = 5100,
		type = "group",
		name = L["Custom Texts"],
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Custom Texts"],
			},
			createCustomText = {
				order = 2,
				type = "input",
				name = L["Create Custom Text"],
				width = "full",
				get = function() return "" end,
				set = function(info, textName)
					for object, _ in pairs(E.db.unitframe.units[groupName]) do
						if object:lower() == textName:lower() then
							E:Print(L["The name you have selected is already in use by another element."])
							return
						end
					end

					if not E.db.unitframe.units[groupName].customTexts then
						E.db.unitframe.units[groupName].customTexts = {};
					end

					local frameName = "ElvUF_"..E:StringTitle(groupName)
					if E.db.unitframe.units[groupName].customTexts[textName] or (_G[frameName] and _G[frameName]["customTexts"] and _G[frameName]["customTexts"][textName] or _G[frameName.."Group1UnitButton1"] and _G[frameName.."Group1UnitButton1"]["customTexts"] and _G[frameName.."Group1UnitButton1"][textName]) then
						E:Print(L["The name you have selected is already in use by another element."])
						return;
					end

					E.db.unitframe.units[groupName].customTexts[textName] = {
						["text_format"] = "",
						["size"] = E.db.unitframe.fontSize,
						["font"] = E.db.unitframe.font,
						["xOffset"] = 0,
						["yOffset"] = 0,
						["justifyH"] = "CENTER",
						["fontOutline"] = E.db.unitframe.fontOutline,
						["attachTextTo"] = "Health"
					};

					CreateCustomTextGroup(groupName, textName)
					updateFunc(UF, groupName, numUnits)
				end,
			},
		},
	}

	return config
end

local function GetOptionsTable_Name(updateFunc, groupName, numUnits)
	local config = {
		order = 400,
		type = "group",
		name = NAME,
		get = function(info) return E.db.unitframe.units[groupName]["name"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["name"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = NAME,
			},
			position = {
				type = "select",
				order = 2,
				name = L["Text Position"],
				values = positionValues,
			},
			xOffset = {
				order = 3,
				type = "range",
				name = L["Text xOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 4,
				type = "range",
				name = L["Text yOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			attachTextTo = {
				type = "select",
				order = 5,
				name = L["Attach Text To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
			text_format = {
				order = 100,
				name = L["Text Format"],
				type = "input",
				width = "full",
				desc = L["TEXT_FORMAT_DESC"],
			},
		},
	}

	return config
end

local function GetOptionsTable_Portrait(updateFunc, groupName, numUnits)
	local config = {
		order = 400,
		type = "group",
		name = L["Portrait"],
		get = function(info) return E.db.unitframe.units[groupName]["portrait"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["portrait"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Portrait"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
				desc = L["If you have a lot of 3D Portraits active then it will likely have a big impact on your FPS. Disable some portraits if you experience FPS issues."],
			},
			width = {
				type = "range",
				order = 3,
				name = L["Width"],
				min = 15, max = 150, step = 1,
			},
			overlay = {
				type = "toggle",
				name = L["Overlay"],
				desc = L["Overlay the healthbar"],
				order = 4,
			},
			style = {
				type = "select",
				name = L["Style"],
				desc = L["Select the display method of the portrait."],
				order = 5,
				values = {
					["2D"] = L["2D"],
					["3D"] = L["3D"],
				},
			},
		},
	}

	return config
end

local function GetOptionsTable_Power(hasDetatchOption, updateFunc, groupName, numUnits, hasStrataLevel)
	local config = {
		order = 200,
		type = "group",
		name = L["Power"],
		get = function(info) return E.db.unitframe.units[groupName]["power"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["power"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Power"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
			},
			text_format = {
				order = 100,
				name = L["Text Format"],
				type = "input",
				width = "full",
				desc = L["TEXT_FORMAT_DESC"],
			},
			width = {
				type = "select",
				order = 3,
				name = L["Style"],
				values = fillValues,
				set = function(info, value)
					E.db.unitframe.units[groupName]["power"][ info[getn(info)] ] = value;

					local frameName = E:StringTitle(groupName)
					frameName = "ElvUF_"..frameName
					frameName = string.gsub(frameName, "t(arget)", "T%1")

					if numUnits then
						for i=1, numUnits do
							if _G[frameName..i] then
								local min, max = _G[frameName..i].Power:GetMinMaxValues()
								_G[frameName..i].Power:SetMinMaxValues(min, max + 500)
								_G[frameName..i].Power:SetValue(1)
								_G[frameName..i].Power:SetValue(0)
							end
						end
					else
						if _G[frameName] and _G[frameName].Power then
							local min, max = _G[frameName].Power:GetMinMaxValues()
							_G[frameName].Power:SetMinMaxValues(min, max + 500)
							_G[frameName].Power:SetValue(1)
							_G[frameName].Power:SetValue(0)
						else
							for i=1, _G[frameName]:GetNumChildren() do
								local child = select(i, _G[frameName]:GetChildren())
								if child and child.Power then
									local min, max = child.Power:GetMinMaxValues()
									child.Power:SetMinMaxValues(min, max + 500)
									child.Power:SetValue(1)
									child.Power:SetValue(0)
								end
							end
						end
					end

					updateFunc(UF, groupName, numUnits)
				end,
			},
			height = {
				type = "range",
				name = L["Height"],
				order = 4,
				min = ((E.db.unitframe.thinBorders or E.PixelMode) and 3 or 7), max = 50, step = 1,
			},
			offset = {
				type = "range",
				name = L["Offset"],
				desc = L["Offset of the powerbar to the healthbar, set to 0 to disable."],
				order = 5,
				min = 0, max = 20, step = 1,
			},
			configureButton = {
				order = 6,
				name = L["Coloring"],
				desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
				type = "execute",
				func = function() ACD:SelectGroup("ElvUI", "unitframe", "generalOptionsGroup", "allColorsGroup", "powerGroup") end,
			},
			position = {
				type = "select",
				order = 7,
				name = L["Text Position"],
				values = positionValues,
			},
			xOffset = {
				order = 8,
				type = "range",
				name = L["Text xOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 9,
				type = "range",
				name = L["Text yOffset"],
				desc = L["Offset position for text."],
				min = -300, max = 300, step = 1,
			},
			attachTextTo = {
				type = "select",
				order = 10,
				name = L["Attach Text To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
		},
	}

	if hasDetatchOption then
			config.args.detachFromFrame = {
				type = "toggle",
				order = 11,
				name = L["Detach From Frame"],
			}
			config.args.detachedWidth = {
				type = "range",
				order = 12,
				name = L["Detached Width"],
				disabled = function() return not E.db.unitframe.units[groupName].power.detachFromFrame end,
				min = 15, max = 450, step = 1,
			}
			config.args.parent = {
				type = "select",
				order = 13,
				name = L["Parent"],
				desc = L["Choose UIPARENT to prevent it from hiding with the unitframe."],
				disabled = function() return not E.db.unitframe.units[groupName].power.detachFromFrame end,
				values = {
					["FRAME"] = "FRAME",
					["UIPARENT"] = "UIPARENT",
				},
			}
	end

	if hasStrataLevel then
		config.args.strataAndLevel = {
			order = 101,
			type = "group",
			name = L["Strata and Level"],
			get = function(info) return E.db.unitframe.units[groupName]["power"]["strataAndLevel"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units[groupName]["power"]["strataAndLevel"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
			guiInline = true,
			args = {
				useCustomStrata = {
					order = 1,
					type = "toggle",
					name = L["Use Custom Strata"],
				},
				frameStrata = {
					order = 2,
					type = "select",
					name = L["Frame Strata"],
					values = {
						["BACKGROUND"] = "BACKGROUND",
						["LOW"] = "LOW",
						["MEDIUM"] = "MEDIUM",
						["HIGH"] = "HIGH",
						["DIALOG"] = "DIALOG",
						["TOOLTIP"] = "TOOLTIP",
					},
				},
				spacer = {
					order = 3,
					type = "description",
					name = "",
				},
				useCustomLevel = {
					order = 4,
					type = "toggle",
					name = L["Use Custom Level"],
				},
				frameLevel = {
					order = 5,
					type = "range",
					name = L["Frame Level"],
					min = 2, max = 128, step = 1,
				},
			},
		}
	end

	return config
end

local function GetOptionsTable_RaidIcon(updateFunc, groupName, numUnits)
	local config = {
		order = 5000,
		type = "group",
		name = L["Raid Icon"],
		get = function(info) return E.db.unitframe.units[groupName]["raidicon"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["raidicon"][ info[getn(info)] ] = value; updateFunc(UF, groupName, numUnits) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Raid Icon"],
			},
			enable = {
				type = "toggle",
				order = 2,
				name = L["Enable"],
			},
			attachTo = {
				type = "select",
				order = 3,
				name = L["Position"],
				values = positionValues,
			},
			attachToObject = {
				type = "select",
				order = 4,
				name = L["Attach To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
			size = {
				type = "range",
				name = L["Size"],
				order = 4,
				min = 8, max = 60, step = 1,
			},
			xOffset = {
				order = 5,
				type = "range",
				name = L["xOffset"],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 6,
				type = "range",
				name = L["yOffset"],
				min = -300, max = 300, step = 1,
			},
		},
	}

	return config
end

local function GetOptionsTable_RaidDebuff(updateFunc, groupName)
	local config = {
		order = 800,
		type = "group",
		name = L["RaidDebuff Indicator"],
		get = function(info) return E.db.unitframe.units[groupName]["rdebuffs"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["rdebuffs"][ info[getn(info)] ] = value; updateFunc(UF, groupName) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["RaidDebuff Indicator"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			showDispellableDebuff = {
				order = 3,
				type = "toggle",
				name = L["Show Dispellable Debuffs"],
			},
			onlyMatchSpellID = {
				order = 4,
				type = "toggle",
				name = L["Only Match SpellID"],
				desc = L["When enabled it will only show spells that were added to the filter using a spell ID and not a name."],
			},
			size = {
				order = 4,
				type = "range",
				name = L["Size"],
				min = 8, max = 100, step = 1,
			},
			font = {
				order = 5,
				type = "select", dialogControl = "LSM30_Font",
				name = L["Font"],
				values = AceGUIWidgetLSMlists.font,
			},
			fontSize = {
				order = 6,
				type = "range",
				name = FONT_SIZE,
				min = 7, max = 212, step = 1,
			},
			fontOutline = {
				order = 7,
				type = "select",
				name = L["Font Outline"],
				values = {
					["NONE"] = NONE,
					["OUTLINE"] = "OUTLINE",
					["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
					["THICKOUTLINE"] = "THICKOUTLINE",
				},
			},
			xOffset = {
				order = 8,
				type = "range",
				name = L["xOffset"],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 9,
				type = "range",
				name = L["yOffset"],
				min = -300, max = 300, step = 1,
			},
			configureButton = {
				order = 10,
				type = "execute",
				name = L["Configure Auras"],
				func = function() E:SetToFilterConfig("RaidDebuffs") end,
			},
			duration = {
				order = 11,
				type = "group",
				guiInline = true,
				name = L["Duration Text"],
				get = function(info) return E.db.unitframe.units[groupName]["rdebuffs"]["duration"][ info[getn(info)] ] end,
				set = function(info, value) E.db.unitframe.units[groupName]["rdebuffs"]["duration"][ info[getn(info)] ] = value; updateFunc(UF, groupName) end,
				args = {
					position = {
						order = 1,
						type = "select",
						name = L["Position"],
						values = {
							["TOP"] = "TOP",
							["LEFT"] = "LEFT",
							["RIGHT"] = "RIGHT",
							["BOTTOM"] = "BOTTOM",
							["CENTER"] = "CENTER",
							["TOPLEFT"] = "TOPLEFT",
							["TOPRIGHT"] = "TOPRIGHT",
							["BOTTOMLEFT"] = "BOTTOMLEFT",
							["BOTTOMRIGHT"] = "BOTTOMRIGHT",
						},
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["xOffset"],
						min = -10, max = 10, step = 1,
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["yOffset"],
						min = -10, max = 10, step = 1,
					},
					color = {
						order = 4,
						type = "color",
						name = COLOR,
						hasAlpha = true,
						get = function(info)
							local c = E.db.unitframe.units.raid.rdebuffs.duration.color
							local d = P.unitframe.units.raid.rdebuffs.duration.color
							return c.r, c.g, c.b, c.a, d.r, d.g, d.b, d.a
						end,
						set = function(info, r, g, b, a)
							local c = E.db.unitframe.units.raid.rdebuffs.duration.color
							c.r, c.g, c.b, c.a = r, g, b, a
							UF:CreateAndUpdateHeaderGroup("raid")
						end,
					},
				},
			},
			stack = {
				order = 12,
				type = "group",
				guiInline = true,
				name = L["Stack Counter"],
				get = function(info) return E.db.unitframe.units[groupName]["rdebuffs"]["stack"][ info[getn(info)] ] end,
				set = function(info, value) E.db.unitframe.units[groupName]["rdebuffs"]["stack"][ info[getn(info)] ] = value; updateFunc(UF, groupName) end,
				args = {
					position = {
						order = 1,
						type = "select",
						name = L["Position"],
						values = {
							["TOP"] = "TOP",
							["LEFT"] = "LEFT",
							["RIGHT"] = "RIGHT",
							["BOTTOM"] = "BOTTOM",
							["CENTER"] = "CENTER",
							["TOPLEFT"] = "TOPLEFT",
							["TOPRIGHT"] = "TOPRIGHT",
							["BOTTOMLEFT"] = "BOTTOMLEFT",
							["BOTTOMRIGHT"] = "BOTTOMRIGHT",
						},
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["xOffset"],
						min = -10, max = 10, step = 1,
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["yOffset"],
						min = -10, max = 10, step = 1,
					},
					color = {
						order = 4,
						type = "color",
						name = COLOR,
						hasAlpha = true,
						get = function(info)
							local c = E.db.unitframe.units[groupName].rdebuffs.stack.color
							local d = P.unitframe.units[groupName].rdebuffs.stack.color
							return c.r, c.g, c.b, c.a, d.r, d.g, d.b, d.a
						end,
						set = function(info, r, g, b, a)
							local c = E.db.unitframe.units[groupName].rdebuffs.stack.color
							c.r, c.g, c.b, c.a = r, g, b, a
							updateFunc(UF, groupName)
						end,
					},
				},
			},
		},
	}

	return config
end

local function GetOptionsTable_ReadyCheckIcon(updateFunc, groupName)
	local config = {
		order = 900,
		type = "group",
		name = L["Ready Check Icon"],
		get = function(info) return E.db.unitframe.units[groupName]["readycheckIcon"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["readycheckIcon"][ info[getn(info)] ] = value; updateFunc(UF, groupName) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Ready Check Icon"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			size = {
				order = 3,
				type = "range",
				name = L["Size"],
				min = 8, max = 60, step = 1,
			},
			attachTo = {
				order = 4,
				type = "select",
				name = L["Attach To"],
				values = {
					["Health"] = HEALTH,
					["Power"] = L["Power"],
					["InfoPanel"] = L["Information Panel"],
					["Frame"] = L["Frame"],
				},
			},
			position = {
				order = 5,
				type = "select",
				name = L["Position"],
				values = positionValues,
			},
			xOffset = {
				order = 6,
				type = "range",
				name = L["xOffset"],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 7,
				type = "range",
				name = L["yOffset"],
				min = -300, max = 300, step = 1,
			},
		},
	}

	return config
end

local function GetOptionsTable_GPS(groupName)
	local config = {
		order = 1000,
		type = "group",
		name = L["GPS Arrow"],
		get = function(info) return E.db.unitframe.units[groupName]["GPSArrow"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[groupName]["GPSArrow"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup(groupName) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["GPS Arrow"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			onMouseOver = {
				order = 3,
				type = "toggle",
				name = L["Mouseover"],
				desc = L["Only show when you are mousing over a frame."],
			},
			outOfRange = {
				order = 4,
				type = "toggle",
				name = L["Out of Range"],
				desc = L["Only show when the unit is not in range."],
			},
			size = {
				order = 5,
				type = "range",
				name = L["Size"],
				min = 8, max = 60, step = 1,
			},
			xOffset = {
				order = 6,
				type = "range",
				name = L["xOffset"],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 7,
				type = "range",
				name = L["yOffset"],
				min = -300, max = 300, step = 1,
			}
		}
	}

	return config
end

local function GetOptionsTableForNonGroup_GPS(unit)
	local config = {
		order = 1000,
		type = "group",
		name = L["GPS Arrow"],
		get = function(info) return E.db.unitframe.units[unit]["GPSArrow"][ info[getn(info)] ] end,
		set = function(info, value) E.db.unitframe.units[unit]["GPSArrow"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF(unit) end,
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["GPS Arrow"],
			},
			enable = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			onMouseOver = {
				order = 3,
				type = "toggle",
				name = L["Mouseover"],
				desc = L["Only show when you are mousing over a frame."],
			},
			outOfRange = {
				order = 4,
				type = "toggle",
				name = L["Out of Range"],
				desc = L["Only show when the unit is not in range."],
			},
			size = {
				order = 5,
				type = "range",
				name = L["Size"],
				min = 8, max = 60, step = 1,
			},
			xOffset = {
				order = 6,
				type = "range",
				name = L["xOffset"],
				min = -300, max = 300, step = 1,
			},
			yOffset = {
				order = 7,
				type = "range",
				name = L["yOffset"],
				min = -300, max = 300, step = 1,
			}
		}
	}

	return config
end

E.Options.args.unitframe = {
	type = "group",
	name = L["Unitframes"],
	childGroups = "tree",
	get = function(info) return E.db.unitframe[ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value end,
	args = {
		enable = {
			order = 0,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.unitframe.enable end,
			set = function(info, value) E.private.unitframe.enable = value; E:StaticPopup_Show("PRIVATE_RL") end
		},
		intro = {
			order = 1,
			type = "description",
			name = L["UNITFRAME_DESC"],
		},
		header = {
			order = 2,
			type = "header",
			name = L["Shortcuts"],
		},
		spacer1 = {
			order = 3,
			type = "description",
			name = " ",
		},
		generalOptionsGroup = {
			order = 19,
			type = "group",
			name = GENERAL,
			childGroups = "tab",
			disabled = function() return not E.UnitFrames; end,
			args = {
				generalGroup = {
					order = 1,
					type = "group",
					name = GENERAL,
					args = {
						header = {
							order = 0,
							type = "header",
							name = GENERAL,
						},
						thinBorders = {
							order = 1,
							name = L["Thin Borders"],
							desc = L["Use thin borders on certain unitframe elements."],
							type = "toggle",
							disabled = function() return E.private.general.pixelPerfect end,
							set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; E:StaticPopup_Show("CONFIG_RL") end,
						},
						OORAlpha = {
							order = 2,
							name = L["OOR Alpha"],
							desc = L["The alpha to set units that are out of range to."],
							type = "range",
							min = 0, max = 1, step = 0.01,
						},
						debuffHighlighting = {
							order = 3,
							name = L["Debuff Highlighting"],
							desc = L["Color the unit healthbar if there is a debuff that can be dispelled by you."],
							type = "select",
							values = {
								["NONE"] = NONE,
								["GLOW"] = L["Glow"],
								["FILL"] = L["Fill"]
							},
						},
						targetOnMouseDown = {
							order = 4,
							name = L["Target On Mouse-Down"],
							desc = L["Target units on mouse down rather than mouse up. \n\n|cffFF0000Warning: If you are using the addon 'Clique' you may have to adjust your clique settings when changing this."],
							type = "toggle",
						},
						auraBlacklistModifier = {
							order = 5,
							type = "select",
							name = L["Blacklist Modifier"],
							desc = L["You need to hold this modifier down in order to blacklist an aura by right-clicking the icon. Set to None to disable the blacklist functionality."],
							values = {
								["NONE"] = NONE,
								["SHIFT"] = SHIFT_KEY,
								["ALT"] = ALT_KEY,
								["CTRL"] = CTRL_KEY,
							},
						},
						resetFilters = {
							order = 6,
							name = L["Reset Aura Filters"],
							type = "execute",
							func = function(info, value)
								E:StaticPopup_Show("RESET_UF_AF") --reset unitframe aurafilters
							end,
						},
						barGroup = {
							order = 20,
							type = "group",
							guiInline = true,
							name = L["Bars"],
							args = {
								smoothbars = {
									type = "toggle",
									order = 1,
									name = L["Smooth Bars"],
									desc = L["Bars will transition smoothly."],
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_AllFrames(); end,
								},
								smoothSpeed = {
									type = "range",
									order = 2,
									name = L["Animation Speed"],
									desc = L["Speed in seconds"],
									min = 0.1, max = 3, step = 0.01,
									disabled = function() return not E.db.unitframe.smoothbars; end,
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_AllFrames(); end
								},
								statusbar = {
									type = "select", dialogControl = "LSM30_Statusbar",
									order = 3,
									name = L["StatusBar Texture"],
									desc = L["Main statusbar texture."],
									values = AceGUIWidgetLSMlists.statusbar,
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_StatusBars() end,
								},
							},
						},
						fontGroup = {
							order = 30,
							type = "group",
							guiInline = true,
							name = L["Fonts"],
							args = {
								font = {
									type = "select", dialogControl = "LSM30_Font",
									order = 4,
									name = L["Default Font"],
									desc = L["The font that the unitframes will use."],
									values = AceGUIWidgetLSMlists.font,
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_FontStrings() end,
								},
								fontSize = {
									order = 5,
									name = FONT_SIZE,
									desc = L["Set the font size for unitframes."],
									type = "range",
									min = 4, max = 212, step = 1,
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_FontStrings() end,
								},
								fontOutline = {
									order = 6,
									name = L["Font Outline"],
									desc = L["Set the font outline."],
									type = "select",
									values = {
										["NONE"] = NONE,
										["OUTLINE"] = "OUTLINE",

										["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
										["THICKOUTLINE"] = "THICKOUTLINE",
									},
									set = function(info, value) E.db.unitframe[ info[getn(info)] ] = value; UF:Update_FontStrings() end,
								},
							},
						},
					},
				},
				allColorsGroup = {
					order = 2,
					type = "group",
					childGroups = "tree",
					name = L["Colors"],
					get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
					set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
					args = {
						header = {
							order = 0,
							type = "header",
							name = L["Colors"],
						},
						borderColor = {
							order = 1,
							type = "color",
							name = L["Border Color"],
							get = function(info)
								local t = E.db.unitframe.colors.borderColor
								local d = P.unitframe.colors.borderColor
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.unitframe.colors.borderColor
								t.r, t.g, t.b = r, g, b
								E:UpdateMedia()
								E:UpdateBorderColors()
							end,
						},
						healthGroup = {
							order = 2,
							type = "group",
							name = HEALTH,
							get = function(info)
								local t = E.db.unitframe.colors[ info[getn(info)] ]
								local d = P.unitframe.colors[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.unitframe.colors[ info[getn(info)] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,
							args = {
								healthclass = {
									order = 1,
									type = "toggle",
									name = L["Class Health"],
									desc = L["Color health by classcolor or reaction."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								forcehealthreaction = {
									order = 2,
									type = "toggle",
									name = L["Force Reaction Color"],
									desc = L["Forces reaction color instead of class color on units controlled by players."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
									disabled = function() return not E.db.unitframe.colors.healthclass end,
								},
								colorhealthbyvalue = {
									order = 3,
									type = "toggle",
									name = L["Health By Value"],
									desc = L["Color health by amount remaining."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								customhealthbackdrop = {
									order = 4,
									type = "toggle",
									name = L["Custom Health Backdrop"],
									desc = L["Use the custom health backdrop color instead of a multiple of the main health color."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								classbackdrop = {
									order = 5,
									type = "toggle",
									name = L["Class Backdrop"],
									desc = L["Color the health backdrop by class or reaction."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								transparentHealth = {
									order = 6,
									type = "toggle",
									name = L["Transparent"],
									desc = L["Make textures transparent."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								useDeadBackdrop = {
									order = 7,
									type = "toggle",
									name = L["Use Dead Backdrop"],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								health = {
									order = 10,
									type = "color",
									name = HEALTH,
								},
								health_backdrop = {
									order = 11,
									type = "color",
									name = L["Health Backdrop"],
								},
								tapped = {
									order = 12,
									type = "color",
									name = L["Tapped"],
								},
								disconnected = {
									order = 13,
									type = "color",
									name = L["Disconnected"],
								},
								health_backdrop_dead = {
									order = 14,
									type = "color",
									name = L["Custom Dead Backdrop"],
									desc = L["Use this backdrop color for units that are dead or ghosts."],
								},
							},
						},
						powerGroup = {
							order = 3,
							type = "group",
							name = L["Powers"],
							get = function(info)
								local t = E.db.unitframe.colors.power[ info[getn(info)] ]
								local d = P.unitframe.colors.power[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.unitframe.colors.power[ info[getn(info)] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,
							args = {
								powerclass = {
									order = 0,
									type = "toggle",
									name = L["Class Power"],
									desc = L["Color power by classcolor or reaction."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								transparentPower = {
									order = 1,
									type = "toggle",
									name = L["Transparent"],
									desc = L["Make textures transparent."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								MANA = {
									order = 2,
									name = MANA,
									type = "color",
								},
								RAGE = {
									order = 3,
									name = RAGE,
									type = "color",
								},
								FOCUS = {
									order = 4,
									name = FOCUS,
									type = "color",
								},
								ENERGY = {
									order = 5,
									name = ENERGY,
									type = "color",
								},
							},
						},
						reactionGroup = {
							order = 4,
							type = "group",
							name = L["Reactions"],
							get = function(info)
								local t = E.db.unitframe.colors.reaction[ info[getn(info)] ]
								local d = P.unitframe.colors.reaction[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.unitframe.colors.reaction[ info[getn(info)] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,
							args = {
								BAD = {
									order = 1,
									name = L["Bad"],
									type = "color",
								},
								NEUTRAL = {
									order = 2,
									name = FACTION_STANDING_LABEL4,
									type = "color",
								},
								GOOD = {
									order = 3,
									name = L["Good"],
									type = "color",
								},
							},
						},
						castBars = {
							order = 5,
							type = "group",
							name = L["Castbar"],
							get = function(info)
								local t = E.db.unitframe.colors[ info[getn(info)] ]
								local d = P.unitframe.colors[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.unitframe.colors[ info[getn(info)] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,
							args = {
								castClassColor = {
									order = 0,
									type = "toggle",
									name = L["Class Castbars"],
									desc = L["Color castbars by the class of player units."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								castReactionColor = {
									order = 1,
									type = "toggle",
									name = L["Reaction Castbars"],
									desc = L["Color castbars by the reaction type of non-player units."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								transparentCastbar = {
									order = 2,
									type = "toggle",
									name = L["Transparent"],
									desc = L["Make textures transparent."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								castColor = {
									order = 3,
									name = L["Interruptable"],
									type = "color",
								},
								castNoInterrupt = {
									order = 4,
									name = L["Non-Interruptable"],
									type = "color",
								},
							},
						},
						auraBars = {
							order = 6,
							type = "group",
							name = L["Aura Bars"],
							args = {
								transparentAurabars = {
									order = 0,
									type = "toggle",
									name = L["Transparent"],
									desc = L["Make textures transparent."],
									get = function(info) return E.db.unitframe.colors[ info[getn(info)] ] end,
									set = function(info, value) E.db.unitframe.colors[ info[getn(info)] ] = value; UF:Update_AllFrames() end,
								},
								auraBarByType = {
									order = 1,
									name = L["By Type"],
									desc = L["Color aurabar debuffs by type."],
									type = "toggle",
								},
								auraBarTurtle = {
									order = 2,
									name = L["Color Turtle Buffs"],
									desc = L["Color all buffs that reduce the unit's incoming damage."],
									type = "toggle",
								},
								BUFFS = {
									order = 10,
									name = L["Buffs"],
									type = "color",
									get = function(info)
										local t = E.db.unitframe.colors.auraBarBuff
										local d = P.unitframe.colors.auraBarBuff
										return t.r, t.g, t.b, t.a, d.r, d.g, d.b
									end,
									set = function(info, r, g, b)
										if E:CheckClassColor(r, g, b) then
											local classColor = E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass])
											r = classColor.r
											g = classColor.g
											b = classColor.b
										end

										local t = E.db.unitframe.colors.auraBarBuff
										t.r, t.g, t.b = r, g, b

										UF:Update_AllFrames()
									end,
								},
								DEBUFFS = {
									order = 11,
									name = L["Debuffs"],
									type = "color",
									get = function(info)
										local t = E.db.unitframe.colors.auraBarDebuff
										local d = P.unitframe.colors.auraBarDebuff
										return t.r, t.g, t.b, t.a, d.r, d.g, d.b
									end,
									set = function(info, r, g, b)
										local t = E.db.unitframe.colors.auraBarDebuff
										t.r, t.g, t.b = r, g, b
										UF:Update_AllFrames()
									end,
								},
								auraBarTurtleColor = {
									order = 12,
									name = L["Turtle Color"],
									type = "color",
									get = function(info)
										local t = E.db.unitframe.colors.auraBarTurtleColor
										local d = P.unitframe.colors.auraBarTurtleColor
										return t.r, t.g, t.b, t.a, d.r, d.g, d.b
									end,
									set = function(info, r, g, b)
										local t = E.db.unitframe.colors.auraBarTurtleColor
										t.r, t.g, t.b = r, g, b
										UF:Update_AllFrames()
									end,
								},
							},
						},
						healPrediction = {
							order = 7,
							name = L["Heal Prediction"],
							type = "group",
							get = function(info)
								local t = E.db.unitframe.colors.healPrediction[ info[getn(info)] ]
								local d = P.unitframe.colors.healPrediction[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
							end,
							set = function(info, r, g, b, a)
								local t = E.db.unitframe.colors.healPrediction[ info[getn(info)] ]
								t.r, t.g, t.b, t.a = r, g, b, a
								UF:Update_AllFrames()
							end,
							args = {
								personal = {
									order = 1,
									name = L["Personal"],
									type = "color",
									hasAlpha = true,
								},
								others = {
									order = 2,
									name = L["Others"],
									type = "color",
									hasAlpha = true,
								},
								maxOverflow = {
									order = 3,
									type = "range",
									name = L["Max Overflow"],
									desc = L["Max amount of overflow allowed to extend past the end of the health bar."],
									isPercent = true,
									min = 0, max = 1, step = 0.01,
									get = function(info) return E.db.unitframe.colors.healPrediction.maxOverflow end,
									set = function(info, value) E.db.unitframe.colors.healPrediction.maxOverflow = value; UF:Update_AllFrames() end,
								},
							},
						},
					},
				},
				disabledBlizzardFrames = {
					order = 3,
					type = "group",
					name = L["Disabled Blizzard Frames"],
					get = function(info) return E.private.unitframe.disabledBlizzardFrames[ info[getn(info)] ] end,
					set = function(info, value) E.private["unitframe"].disabledBlizzardFrames[ info[getn(info)] ] = value; E:StaticPopup_Show("PRIVATE_RL") end,
					args = {
						header = {
							order = 0,
							type = "header",
							name = L["Disabled Blizzard Frames"],
						},
						player = {
							order = 1,
							type = "toggle",
							name = L["Player Frame"],
							desc = L["Disables the player and pet unitframes."],
						},
						target = {
							order = 2,
							type = "toggle",
							name = L["Target Frame"],
							desc = L["Disables the target and target of target unitframes."],
						},
						focus = {
							order = 3,
							type = "toggle",
							name = L["Focus Frame"],
							desc = L["Disables the focus and target of focus unitframes."],
						},
						party = {
							order = 6,
							type = "toggle",
							name = L["Party Frames"],
						},
						raid = {
							order = 7,
							type = "toggle",
							name = L["Raid Frames"],
						},
					},
				},
				--[[raidDebuffIndicator = {
					order = 4,
					type = "group",
					name = L["RaidDebuff Indicator"],
					args = {
						header = {
							order = 1,
							type = "header",
							name = L["RaidDebuff Indicator"],
						},
						instanceFilter = {
							order = 2,
							type = "select",
							name = L["Dungeon & Raid Filter"],
							values = function()
								local filters = {}
								local list = E.global.unitframe["aurafilters"]
								if not list then return end
								for filter in pairs(list) do
									filters[filter] = filter
								end

								return filters
							end,
							get = function(info) return E.global.unitframe.raidDebuffIndicator.instanceFilter end,
							set = function(info, value) E.global.unitframe.raidDebuffIndicator.instanceFilter = value; UF:UpdateAllHeaders() end,
						},
						otherFilter = {
							order = 3,
							type = "select",
							name = L["Other Filter"],
							values = function()
								local filters = {}
								local list = E.global.unitframe["aurafilters"]
								if not list then return end
								for filter in pairs(list) do
									filters[filter] = filter
								end

								return filters
							end,
							get = function(info) return E.global.unitframe.raidDebuffIndicator.otherFilter end,
							set = function(info, value) E.global.unitframe.raidDebuffIndicator.otherFilter = value; UF:UpdateAllHeaders() end,
						},
					},
				},--]]
			},
		},
	},
}

--Player
E.Options.args.unitframe.args.player = {
	name = L["Player Frame"],
	type = "group",
	order = 300,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["player"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["player"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("player") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
					set = function(info, value)
						E.db.unitframe.units["player"][ info[getn(info)] ] = value;
						UF:CreateAndUpdateUF("player");
						if value == true and E.db.unitframe.units.player.combatfade then
							ElvUF_Pet:SetParent(ElvUF_Player)
						else
							ElvUF_Pet:SetParent(ElvUF_Parent)
						end
					end,
				},
				copyFrom = {
					type = "select",
					order = 2,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "player"); end,
				},
				resetSettings = {
					type = "execute",
					order = 3,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("player"); E:ResetMovers(L["Player Frame"]) end,
				},
				showAuras = {
					order = 4,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_Player
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("player")
					end,
				},
				width = {
					order = 5,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
					set = function(info, value)
						if E.db.unitframe.units["player"].castbar.width == E.db.unitframe.units["player"][ info[getn(info)] ] then
							E.db.unitframe.units["player"].castbar.width = value;
						end

						E.db.unitframe.units["player"][ info[getn(info)] ] = value;
						UF:CreateAndUpdateUF("player");
					end,
				},
				height = {
					order = 6,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				combatfade = {
					order = 7,
					name = L["Combat Fade"],
					desc = L["Fade the unitframe when out of combat, not casting, no target exists."],
					type = "toggle",
					set = function(info, value)
						E.db.unitframe.units["player"][ info[getn(info)] ] = value;
						UF:CreateAndUpdateUF("player");
						if value == true and E.db.unitframe.units.player.enable then
							ElvUF_Pet:SetParent(ElvUF_Player)
						else
							ElvUF_Pet:SetParent(ElvUF_Parent)
						end
					end,
				},
				healPrediction = {
					order = 8,
					name = L["Heal Prediction"],
					desc = L["Show an incoming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 9,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["player"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["player"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("player") end,
				},
				restIcon = {
					order = 10,
					name = L["Rest Icon"],
					desc = L["Display the rested icon on the unitframe."],
					type = "toggle",
				},
				combatIcon = {
					order = 11,
					name = L["Combat Icon"],
					desc = L["Display the combat icon on the unitframe."],
					type = "toggle",
				},
				threatStyle = {
					type = "select",
					order = 12,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 13,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
						["FLUID_BUFFS_ON_DEBUFFS"] = L["Fluid Position Buffs on Debuffs"],
						["FLUID_DEBUFFS_ON_BUFFS"] = L["Fluid Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 14,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 15,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "player"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "player"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "player"),
		power = GetOptionsTable_Power(true, UF.CreateAndUpdateUF, "player", nil, true),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "player"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "player"),
		buffs = GetOptionsTable_Auras(true, "buffs", false, UF.CreateAndUpdateUF, "player"),
		debuffs = GetOptionsTable_Auras(true, "debuffs", false, UF.CreateAndUpdateUF, "player"),
		castbar = GetOptionsTable_Castbar(UF.CreateAndUpdateUF, "player"),
		aurabar = GetOptionsTable_AuraBars(true, UF.CreateAndUpdateUF, "player"),
		raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateUF, "player"),
		classbar = {
			order = 1000,
			type = "group",
			name = L["Classbar"],
			get = function(info) return E.db.unitframe.units["player"]["classbar"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["player"]["classbar"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("player") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Classbar"],
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
				},
				height = {
					type = "range",
					order = 3,
					name = L["Height"],
					min = ((E.db.unitframe.thinBorders or E.PixelMode) and 3 or 7),
					max = (E.db.unitframe.units["player"]["classbar"].detachFromFrame and 300 or 30),
					step = 1,
				},
				fill = {
					type = "select",
					order = 4,
					name = L["Fill"],
					values = {
						["fill"] = L["Filled"],
						["spaced"] = L["Spaced"],
					},
				},
				autoHide = {
					order = 5,
					type = "toggle",
					name = L["Auto-Hide"],
				},
				detachFromFrame = {
					type = "toggle",
					order = 6,
					name = L["Detach From Frame"],
					set = function(info, value)
						if value == true then
							E.Options.args.unitframe.args.player.args.classbar.args.height.max = 300
						else
							E.Options.args.unitframe.args.player.args.classbar.args.height.max = 30
						end
						E.db.unitframe.units["player"]["classbar"][ info[getn(info)] ] = value;
						UF:CreateAndUpdateUF("player")
					end,
				},
				verticalOrientation = {
					order = 7,
					type = "toggle",
					name = L["Vertical Orientation"],
					disabled = function() return not E.db.unitframe.units["player"]["classbar"].detachFromFrame end,
				},
				detachedWidth = {
					type = "range",
					order = 8,
					name = L["Detached Width"],
					disabled = function() return not E.db.unitframe.units["player"]["classbar"].detachFromFrame end,
					min = ((E.db.unitframe.thinBorders or E.PixelMode) and 3 or 7), max = 800, step = 1,
				},
				parent = {
					type = "select",
					order = 9,
					name = L["Parent"],
					desc = L["Choose UIPARENT to prevent it from hiding with the unitframe."],
					disabled = function() return not E.db.unitframe.units["player"]["classbar"].detachFromFrame end,
					values = {
						["FRAME"] = "FRAME",
						["UIPARENT"] = "UIPARENT",
					},
				},
				strataAndLevel = {
					order = 20,
					type = "group",
					name = L["Strata and Level"],
					get = function(info) return E.db.unitframe.units["player"]["classbar"]["strataAndLevel"][ info[getn(info)] ] end,
					set = function(info, value) E.db.unitframe.units["player"]["classbar"]["strataAndLevel"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("player") end,
					guiInline = true,
					disabled = function() return not E.db.unitframe.units["player"]["classbar"].detachFromFrame end,
					hidden = function() return not E.db.unitframe.units["player"]["classbar"].detachFromFrame end,
					args = {
						useCustomStrata = {
							order = 1,
							type = "toggle",
							name = L["Use Custom Strata"],
						},
						frameStrata = {
							order = 2,
							type = "select",
							name = L["Frame Strata"],
							values = {
								["BACKGROUND"] = "BACKGROUND",
								["LOW"] = "LOW",
								["MEDIUM"] = "MEDIUM",
								["HIGH"] = "HIGH",
								["DIALOG"] = "DIALOG",
								["TOOLTIP"] = "TOOLTIP",
							},
						},
						spacer = {
							order = 3,
							type = "description",
							name = "",
						},
						useCustomLevel = {
							order = 4,
							type = "toggle",
							name = L["Use Custom Level"],
						},
						frameLevel = {
							order = 5,
							type = "range",
							name = L["Frame Level"],
							min = 2, max = 128, step = 1,
						},
					},
				},
			},
		},
		pvpIcon = {
			order = 449,
			type = "group",
			name = L["PvP Icon"],
			get = function(info) return E.db.unitframe.units["player"]["pvpIcon"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["player"]["pvpIcon"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("player") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["PvP Icon"],
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
				},
				scale = {
					order = 3,
					type = "range",
					name = L["Scale"],
					isPercent = true,
					min = 0.1, max = 2, step = 0.01,
				},
				spacer = {
					order = 4,
					type = "description",
					name = " ",
				},
				anchorPoint = {
					order = 5,
					type = "select",
					name = L["Anchor Point"],
					values = positionValues,
				},
				xOffset = {
					order = 6,
					type = "range",
					name = L["X-Offset"],
					min = -100, max = 100, step = 1,
				},
				yOffset = {
					order = 7,
					type = "range",
					name = L["Y-Offset"],
					min = -100, max = 100, step = 1,
				},
			},
		},
		pvpText = {
			order = 450,
			type = "group",
			name = L["PvP Text"],
			get = function(info) return E.db.unitframe.units["player"]["pvp"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["player"]["pvp"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("player") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name =L["PvP Text"],
				},
				position = {
					type = "select",
					order = 2,
					name = L["Position"],
					values = positionValues,
				},
				text_format = {
					order = 100,
					name = L["Text Format"],
					type = "input",
					width = "full",
					desc = L["TEXT_FORMAT_DESC"],
				},
			},
		},
	},
}

--Target
E.Options.args.unitframe.args.target = {
	name = L["Target Frame"],
	type = "group",
	order = 400,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["target"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["target"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("target") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
				},
				copyFrom = {
					type = "select",
					order = 3,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "target"); end,
				},
				resetSettings = {
					type = "execute",
					order = 4,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("target"); E:ResetMovers(L["Target Frame"]) end,
				},
				showAuras = {
					order = 5,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_Target
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("target")
					end,
				},
				width = {
					order = 6,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
					set = function(info, value)
						if E.db.unitframe.units["target"].castbar.width == E.db.unitframe.units["target"][ info[getn(info)] ] then
							E.db.unitframe.units["target"].castbar.width = value;
						end

						E.db.unitframe.units["target"][ info[getn(info)] ] = value;
						UF:CreateAndUpdateUF("target");
					end,
				},
				height = {
					order = 7,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				rangeCheck = {
					order = 8,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				healPrediction = {
					order = 9,
					name = L["Heal Prediction"],
					desc = L["Show an incoming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 10,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["target"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["target"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("target") end,
				},
				middleClickFocus = {
					order = 11,
					name = L["Middle Click - Set Focus"],
					desc = L["Middle clicking the unit frame will cause your focus to match the unit."],
					type = "toggle",
					disabled = function() return IsAddOnLoaded("Clique") end,
				},
				threatStyle = {
					type = "select",
					order = 12,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 13,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
						["FLUID_BUFFS_ON_DEBUFFS"] = L["Fluid Position Buffs on Debuffs"],
						["FLUID_DEBUFFS_ON_BUFFS"] = L["Fluid Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 14,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 15,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "target"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "target"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "target"),
		power = GetOptionsTable_Power(true, UF.CreateAndUpdateUF, "target", nil, true),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "target"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "target"),
		--buffs = GetOptionsTable_Auras(false, "buffs", false, UF.CreateAndUpdateUF, "target"),
		--debuffs = GetOptionsTable_Auras(false, "debuffs", false, UF.CreateAndUpdateUF, "target"),
		--castbar = GetOptionsTable_Castbar(UF.CreateAndUpdateUF, "target"),
		--aurabar = GetOptionsTable_AuraBars(false, UF.CreateAndUpdateUF, "target"),
		raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateUF, "target"),
		GPSArrow = GetOptionsTableForNonGroup_GPS("target"),
		combobar = {
			order = 850,
			type = "group",
			name = L["Combobar"],
			get = function(info) return E.db.unitframe.units["target"]["combobar"][ info[getn(info)] ]; end,
			set = function(info, value) E.db.unitframe.units["target"]["combobar"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("target"); end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Combobar"],
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
				},
				height = {
					order = 3,
					type = "range",
					name = L["Height"],
					min = ((E.db.unitframe.thinBorders or E.PixelMode) and 3 or 7), max = 15, step = 1,
				},
				fill = {
					order = 4,
					type = "select",
					name = L["Fill"],
					values = {
						["fill"] = L["Filled"],
						["spaced"] = L["Spaced"],
					},
				},
				autoHide = {
					order = 5,
					type = "toggle",
					name = L["Auto-Hide"],
				},
				detachFromFrame = {
					order = 6,
					type = "toggle",
					name = L["Detach From Frame"],
				},
				detachedWidth = {
					order = 7,
					type = "range",
					name = L["Detached Width"],
					disabled = function() return not E.db.unitframe.units["target"]["combobar"].detachFromFrame; end,
					min = 15, max = 450, step = 1,
				},
			},
		},
		pvpIcon = {
			order = 449,
			type = "group",
			name = L["PvP Icon"],
			get = function(info) return E.db.unitframe.units["target"]["pvpIcon"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["target"]["pvpIcon"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("target") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["PvP Icon"],
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
				},
				scale = {
					order = 3,
					type = "range",
					name = L["Scale"],
					isPercent = true,
					min = 0.1, max = 2, step = 0.01,
				},
				spacer = {
					order = 4,
					type = "description",
					name = " ",
				},
				anchorPoint = {
					order = 5,
					type = "select",
					name = L["Anchor Point"],
					values = positionValues,
				},
				xOffset = {
					order = 6,
					type = "range",
					name = L["X-Offset"],
					min = -100, max = 100, step = 1,
				},
				yOffset = {
					order = 7,
					type = "range",
					name = L["Y-Offset"],
					min = -100, max = 100, step = 1,
				},
			},
		},
	},
}

--TargetTarget
E.Options.args.unitframe.args.targettarget = {
	name = L["TargetTarget Frame"],
	type = "group",
	order = 500,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["targettarget"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["targettarget"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("targettarget") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
				},
				copyFrom = {
					type = "select",
					order = 3,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "targettarget"); end,
				},
				resetSettings = {
					type = "execute",
					order = 4,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("targettarget"); E:ResetMovers(L["TargetTarget Frame"]) end,
				},
				showAuras = {
					order = 5,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_TargetTarget
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("targettarget")
					end,
				},
				width = {
					order = 6,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
				},
				height = {
					order = 7,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				rangeCheck = {
					order = 8,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 9,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["targettarget"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["targettarget"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("targettarget") end,
				},
				threatStyle = {
					type = "select",
					order = 10,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 11,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 12,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 13,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "targettarget"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "targettarget"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "targettarget"),
		power = GetOptionsTable_Power(nil, UF.CreateAndUpdateUF, "targettarget"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "targettarget"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "targettarget"),
		--buffs = GetOptionsTable_Auras(false, "buffs", false, UF.CreateAndUpdateUF, "targettarget"),
		--debuffs = GetOptionsTable_Auras(false, "debuffs", false, UF.CreateAndUpdateUF, "targettarget"),
		raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateUF, "targettarget"),
	},
}

--TargetTargetTarget
E.Options.args.unitframe.args.targettargettarget = {
	name = L["TargetTargetTarget Frame"],
	type = "group",
	order = 500,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["targettargettarget"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["targettargettarget"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("targettargettarget") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
				},
				copyFrom = {
					type = "select",
					order = 3,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "targettargettarget"); end,
				},
				resetSettings = {
					type = "execute",
					order = 4,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("targettargettarget"); E:ResetMovers(L["TargetTargetTarget Frame"]) end,
				},
				showAuras = {
					order = 5,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_TargetTargetTarget
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("targettargettarget")
					end,
				},
				width = {
					order = 6,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
				},
				height = {
					order = 7,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				rangeCheck = {
					order = 8,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 9,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["targettargettarget"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["targettargettarget"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("targettargettarget") end,
				},
				threatStyle = {
					type = "select",
					order = 10,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 11,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
						["FLUID_BUFFS_ON_DEBUFFS"] = L["Fluid Position Buffs on Debuffs"],
						["FLUID_DEBUFFS_ON_BUFFS"] = L["Fluid Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 12,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 13,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "targettargettarget"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "targettargettarget"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "targettargettarget"),
		power = GetOptionsTable_Power(nil, UF.CreateAndUpdateUF, "targettargettarget"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "targettargettarget"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "targettargettarget"),
		--buffs = GetOptionsTable_Auras(false, "buffs", false, UF.CreateAndUpdateUF, "targettargettarget"),
		--debuffs = GetOptionsTable_Auras(false, "debuffs", false, UF.CreateAndUpdateUF, "targettargettarget"),
		raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateUF, "targettargettarget"),
	},
}

--Pet
E.Options.args.unitframe.args.pet = {
	name = L["Pet Frame"],
	type = "group",
	order = 800,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["pet"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["pet"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("pet") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
				},
				copyFrom = {
					type = "select",
					order = 3,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "pet"); end,
				},
				resetSettings = {
					type = "execute",
					order = 4,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("pet"); E:ResetMovers(L["Pet Frame"]) end,
				},
				showAuras = {
					order = 5,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_Pet
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("pet")
					end,
				},
				width = {
					order = 6,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
				},
				height = {
					order = 7,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				rangeCheck = {
					order = 8,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				healPrediction = {
					order = 9,
					name = L["Heal Prediction"],
					desc = L["Show an incoming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 10,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["pet"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["pet"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("pet") end,
				},
				threatStyle = {
					type = "select",
					order = 11,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 12,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
						["FLUID_BUFFS_ON_DEBUFFS"] = L["Fluid Position Buffs on Debuffs"],
						["FLUID_DEBUFFS_ON_BUFFS"] = L["Fluid Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 13,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 14,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		buffIndicator = {
			order = 600,
			type = "group",
			name = L["Buff Indicator"],
			get = function(info) return E.db.unitframe.units["pet"]["buffIndicator"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["pet"]["buffIndicator"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("pet") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Buff Indicator"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				size = {
					type = "range",
					name = L["Size"],
					desc = L["Size of the indicator icon."],
					order = 3,
					min = 4, max = 50, step = 1,
				},
				fontSize = {
					type = "range",
					name = FONT_SIZE,
					order = 4,
					min = 7, max = 22, step = 1,
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "pet"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "pet"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "pet"),
		power = GetOptionsTable_Power(false, UF.CreateAndUpdateUF, "pet"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "pet"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "pet"),
		--buffs = GetOptionsTable_Auras(true, "buffs", false, UF.CreateAndUpdateUF, "pet"),
		--debuffs = GetOptionsTable_Auras(true, "debuffs", false, UF.CreateAndUpdateUF, "pet"),
		--castbar = GetOptionsTable_Castbar(UF.CreateAndUpdateUF, "pet"),
	},
}

--Pet Target
E.Options.args.unitframe.args.pettarget = {
	name = L["PetTarget Frame"],
	type = "group",
	order = 900,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["pettarget"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["pettarget"][ info[getn(info)] ] = value; UF:CreateAndUpdateUF("pettarget") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		generalGroup = {
			order = 1,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
					width = "full",
				},
				copyFrom = {
					type = "select",
					order = 3,
					name = L["Copy From"],
					desc = L["Select a unit to copy settings from."],
					values = UF["units"],
					set = function(info, value) UF:MergeUnitSettings(value, "pettarget"); end,
				},
				resetSettings = {
					type = "execute",
					order = 4,
					name = L["Restore Defaults"],
					func = function(info, value) UF:ResetUnitSettings("pettarget"); E:ResetMovers(L["PetTarget Frame"]) end,
				},
				showAuras = {
					order = 5,
					type = "execute",
					name = L["Show Auras"],
					func = function()
						local frame = ElvUF_PetTarget
						if frame.forceShowAuras then
							frame.forceShowAuras = nil;
						else
							frame.forceShowAuras = true;
						end

						UF:CreateAndUpdateUF("pettarget")
					end,
				},
				width = {
					order = 6,
					name = L["Width"],
					type = "range",
					min = 50, max = 500, step = 1,
				},
				height = {
					order = 7,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				rangeCheck = {
					order = 8,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				hideonnpc = {
					type = "toggle",
					order = 9,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["pettarget"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["pettarget"]["power"].hideonnpc = value; UF:CreateAndUpdateUF("pettarget") end,
				},
				threatStyle = {
					type = "select",
					order = 10,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				smartAuraPosition = {
					order = 11,
					type = "select",
					name = L["Smart Aura Position"],
					desc = L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."],
					values = {
						["DISABLED"] = DISABLE,
						["BUFFS_ON_DEBUFFS"] = L["Position Buffs on Debuffs"],
						["DEBUFFS_ON_BUFFS"] = L["Position Debuffs on Buffs"],
						["FLUID_BUFFS_ON_DEBUFFS"] = L["Fluid Position Buffs on Debuffs"],
						["FLUID_DEBUFFS_ON_BUFFS"] = L["Fluid Position Debuffs on Buffs"],
					},
				},
				orientation = {
					order = 12,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				colorOverride = {
					order = 13,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
			},
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateUF, "pettarget"),
		health = GetOptionsTable_Health(false, UF.CreateAndUpdateUF, "pettarget"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateUF, "pettarget"),
		power = GetOptionsTable_Power(false, UF.CreateAndUpdateUF, "pettarget"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateUF, "pettarget"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateUF, "pettarget"),
		--buffs = GetOptionsTable_Auras(false, "buffs", false, UF.CreateAndUpdateUF, "pettarget"),
		--debuffs = GetOptionsTable_Auras(false, "debuffs", false, UF.CreateAndUpdateUF, "pettarget"),
	},
}

--Party Frames
E.Options.args.unitframe.args.party = {
	name = L["Party Frames"],
	type = "group",
	order = 1100,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["party"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		configureToggle = {
			order = 1,
			type = "execute",
			name = L["Display Frames"],
			func = function()
				UF:HeaderConfig(ElvUF_Party, ElvUF_Party.forceShow ~= true or nil)
			end,
		},
		resetSettings = {
			type = "execute",
			order = 2,
			name = L["Restore Defaults"],
			func = function(info, value) UF:ResetUnitSettings("party"); E:ResetMovers(L["Party Frames"]) end,
		},
		copyFrom = {
			type = "select",
			order = 3,
			name = L["Copy From"],
			desc = L["Select a unit to copy settings from."],
			values = {
				["raid"] = L["Raid Frames"],
				["raid40"] = L["Raid40 Frames"],
			},
			set = function(info, value) UF:MergeUnitSettings(value, "party", true); end,
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateHeaderGroup, "party", nil, 4),
		generalGroup = {
			order = 5,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
				},
				hideonnpc = {
					type = "toggle",
					order = 3,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["party"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["party"]["power"].hideonnpc = value; UF:CreateAndUpdateHeaderGroup("party"); end,
				},
				rangeCheck = {
					order = 4,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				healPrediction = {
					order = 5,
					name = L["Heal Prediction"],
					desc = L["Show an incoming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals."],
					type = "toggle",
				},
				threatStyle = {
					type = "select",
					order = 6,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				colorOverride = {
					order = 7,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
				orientation = {
					order = 8,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				targetGlow = {
					order = 9,
					type = "toggle",
					name = L["Target Glow"],
				},
				positionsGroup = {
					order = 100,
					name = L["Size and Positions"],
					type = "group",
					guiInline = true,
					set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party", nil, nil, true) end,
					args = {
						width = {
							order = 1,
							name = L["Width"],
							type = "range",
							min = 10, max = 500, step = 1,
							set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
						},
						height = {
							order = 2,
							name = L["Height"],
							type = "range",
							min = 10, max = 500, step = 1,
							set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
						},
						spacer = {
							order = 3,
							name = "",
							type = "description",
							width = "full",
						},
						growthDirection = {
							order = 4,
							name = L["Growth Direction"],
							desc = L["Growth direction from the first unitframe."],
							type = "select",
							values = {
								DOWN_RIGHT = format(L["%s and then %s"], L["Down"], L["Right"]),
								DOWN_LEFT = format(L["%s and then %s"], L["Down"], L["Left"]),
								UP_RIGHT = format(L["%s and then %s"], L["Up"], L["Right"]),
								UP_LEFT = format(L["%s and then %s"], L["Up"], L["Left"]),
								RIGHT_DOWN = format(L["%s and then %s"], L["Right"], L["Down"]),
								RIGHT_UP = format(L["%s and then %s"], L["Right"], L["Up"]),
								LEFT_DOWN = format(L["%s and then %s"], L["Left"], L["Down"]),
								LEFT_UP = format(L["%s and then %s"], L["Left"], L["Up"]),
							},
						},
						numGroups = {
							order = 7,
							type = "range",
							name = L["Number of Groups"],
							min = 1, max = 8, step = 1,
							set = function(info, value)
								E.db.unitframe.units["party"][ info[getn(info)] ] = value;
								UF:CreateAndUpdateHeaderGroup("party")
								if ElvUF_Party.isForced then
									UF:HeaderConfig(ElvUF_Party)
									UF:HeaderConfig(ElvUF_Party, true)
								end
							end,
						},
						groupsPerRowCol = {
							order = 8,
							type = "range",
							name = L["Groups Per Row/Column"],
							min = 1, max = 8, step = 1,
							set = function(info, value)
								E.db.unitframe.units["party"][ info[getn(info)] ] = value;
								UF:CreateAndUpdateHeaderGroup("party")
								if ElvUF_Party.isForced then
									UF:HeaderConfig(ElvUF_Party)
									UF:HeaderConfig(ElvUF_Party, true)
								end
							end,
						},
						horizontalSpacing = {
							order = 9,
							type = "range",
							name = L["Horizontal Spacing"],
							min = -1, max = 50, step = 1,
						},
						verticalSpacing = {
							order = 10,
							type = "range",
							name = L["Vertical Spacing"],
							min = -1, max = 50, step = 1,
						},
					},
				},
				visibilityGroup = {
					order = 200,
					name = L["Visibility"],
					type = "group",
					guiInline = true,
					set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party", nil, nil, true) end,
					args = {
						showPlayer = {
							order = 1,
							type = "toggle",
							name = L["Display Player"],
							desc = L["When true, the header includes the player when not in a raid."],
						},
						visibility = {
							order = 2,
							type = "input",
							name = L["Visibility"],
							desc = L["The following macro must be true in order for the group to be shown, in addition to any filter that may already be set."],
							width = "full",
						},
					},
				},
				sortingGroup = {
					order = 300,
					type = "group",
					guiInline = true,
					name = L["Grouping & Sorting"],
					set = function(info, value) E.db.unitframe.units["party"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party", nil, nil, true) end,
					args = {
						groupBy = {
							order = 1,
							name = L["Group By"],
							desc = L["Set the order that the group will sort."],
							type = "select",
							values = {
								["CLASS"] = CLASS,
								["NAME"] = NAME,
								["MTMA"] = L["Main Tanks / Main Assist"],
								["GROUP"] = GROUP,
							},
						},
						sortDir = {
							order = 2,
							name = L["Sort Direction"],
							desc = L["Defines the sort order of the selected sort method."],
							type = "select",
							values = {
								["ASC"] = L["Ascending"],
								["DESC"] = L["Descending"]
							},
						},
						spacer = {
							order = 3,
							type = "description",
							width = "full",
							name = " "
						},
						raidWideSorting = {
							order = 4,
							name = L["Raid-Wide Sorting"],
							desc = L["Enabling this allows raid-wide sorting however you will not be able to distinguish between groups."],
							type = "toggle",
						},
						invertGroupingOrder = {
							order = 5,
							name = L["Invert Grouping Order"],
							desc = L["Enabling this inverts the grouping order when the raid is not full, this will reverse the direction it starts from."],
							disabled = function() return not E.db.unitframe.units["party"].raidWideSorting end,
							type = "toggle",
						},
						startFromCenter = {
							order = 6,
							name = L["Start Near Center"],
							desc = L["The initial group will start near the center and grow out."],
							disabled = function() return not E.db.unitframe.units["party"].raidWideSorting end,
							type = "toggle",
						},
					},
				},
			},
		},
		buffIndicator = {
			order = 701,
			type = "group",
			name = L["Buff Indicator"],
			get = function(info) return E.db.unitframe.units["party"]["buffIndicator"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["party"]["buffIndicator"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Buff Indicator"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				size = {
					type = "range",
					name = L["Size"],
					desc = L["Size of the indicator icon."],
					order = 3,
					min = 4, max = 50, step = 1,
				},
				fontSize = {
					type = "range",
					name = FONT_SIZE,
					order = 4,
					min = 7, max = 22, step = 1,
				},
				profileSpecific = {
					type = "toggle",
					name = L["Profile Specific"],
					desc = L["Use the profile specific filter 'Buff Indicator (Profile)' instead of the global filter 'Buff Indicator'."],
					order = 5,
				},
				configureButton = {
					type = "execute",
					name = L["Configure Auras"],
					func = function()
						if E.db.unitframe.units["party"]["buffIndicator"].profileSpecific then
							E:SetToFilterConfig("Buff Indicator (Profile)")
						else
							E:SetToFilterConfig("Buff Indicator")
						end
					end,
					order = 6
				},
			},
		},
		roleIcon = {
			order = 702,
			type = "group",
			name = L["Role Icon"],
			get = function(info) return E.db.unitframe.units["party"]["roleIcon"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["party"]["roleIcon"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Role Icon"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				position = {
					type = "select",
					order = 3,
					name = L["Position"],
					values = positionValues,
				},
				attachTo = {
					type = "select",
					order = 4,
					name = L["Attach To"],
					values = {
						["Health"] = HEALTH,
						["Power"] = L["Power"],
						["InfoPanel"] = L["Information Panel"],
						["Frame"] = L["Frame"],
					},
				},
				xOffset = {
					order = 5,
					type = "range",
					name = L["xOffset"],
					min = -300, max = 300, step = 1,
				},
				yOffset = {
					order = 6,
					type = "range",
					name = L["yOffset"],
					min = -300, max = 300, step = 1,
				},
				size = {
					type = "range",
					order = 7,
					name = L["Size"],
					min = 4, max = 100, step = 1,
				},
			},
		},
		raidRoleIcons = {
			order = 703,
			type = "group",
			name = L["RL / ML Icons"],
			get = function(info) return E.db.unitframe.units["party"]["raidRoleIcons"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["party"]["raidRoleIcons"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["RL / ML Icons"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				position = {
					type = "select",
					order = 3,
					name = L["Position"],
					values = {
						["TOPLEFT"] = "TOPLEFT",
						["TOPRIGHT"] = "TOPRIGHT",
					},
				},
			},
		},
		health = GetOptionsTable_Health(true, UF.CreateAndUpdateHeaderGroup, "party"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateHeaderGroup, "party"),
		power = GetOptionsTable_Power(false, UF.CreateAndUpdateHeaderGroup, "party"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateHeaderGroup, "party"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateHeaderGroup, "party"),
		--buffs = GetOptionsTable_Auras(true, "buffs", true, UF.CreateAndUpdateHeaderGroup, "party"),
		--debuffs = GetOptionsTable_Auras(true, "debuffs", true, UF.CreateAndUpdateHeaderGroup, "party"),
		rdebuffs = GetOptionsTable_RaidDebuff(UF.CreateAndUpdateHeaderGroup, "party"),
		petsGroup = {
			order = 850,
			type = "group",
			name = L["Party Pets"],
			get = function(info) return E.db.unitframe.units["party"]["petsGroup"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["party"]["petsGroup"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Party Pets"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				width = {
					order = 3,
					name = L["Width"],
					type = "range",
					min = 10, max = 500, step = 1,
				},
				height = {
					order = 4,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				anchorPoint = {
					type = "select",
					order = 5,
					name = L["Anchor Point"],
					desc = L["What point to anchor to the frame you set to attach to."],
					values = petAnchors,
				},
				xOffset = {
					order = 6,
					type = "range",
					name = L["xOffset"],
					desc = L["An X offset (in pixels) to be used when anchoring new frames."],
					min = -500, max = 500, step = 1,
				},
				yOffset = {
					order = 7,
					type = "range",
					name = L["yOffset"],
					desc = L["An Y offset (in pixels) to be used when anchoring new frames."],
					min = -500, max = 500, step = 1,
				},
				name = {
					order = 8,
					type = "group",
					guiInline = true,
					get = function(info) return E.db.unitframe.units["party"]["petsGroup"]["name"][ info[getn(info)] ] end,
					set = function(info, value) E.db.unitframe.units["party"]["petsGroup"]["name"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
					name = NAME,
					args = {
						position = {
							type = "select",
							order = 1,
							name = L["Text Position"],
							values = positionValues,
						},
						xOffset = {
							order = 2,
							type = "range",
							name = L["Text xOffset"],
							desc = L["Offset position for text."],
							min = -300, max = 300, step = 1,
						},
						yOffset = {
							order = 3,
							type = "range",
							name = L["Text yOffset"],
							desc = L["Offset position for text."],
							min = -300, max = 300, step = 1,
						},
						text_format = {
							order = 100,
							name = L["Text Format"],
							type = "input",
							width = "full",
							desc = L["TEXT_FORMAT_DESC"],
						},
					},
				},
			},
		},
		targetsGroup = {
			order = 900,
			type = "group",
			name = L["Party Targets"],
			get = function(info) return E.db.unitframe.units["party"]["targetsGroup"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["party"]["targetsGroup"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Party Targets"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				width = {
					order = 3,
					name = L["Width"],
					type = "range",
					min = 10, max = 500, step = 1,
				},
				height = {
					order = 4,
					name = L["Height"],
					type = "range",
					min = 10, max = 250, step = 1,
				},
				anchorPoint = {
					type = "select",
					order = 5,
					name = L["Anchor Point"],
					desc = L["What point to anchor to the frame you set to attach to."],
					values = petAnchors,
				},
				xOffset = {
					order = 6,
					type = "range",
					name = L["xOffset"],
					desc = L["An X offset (in pixels) to be used when anchoring new frames."],
					min = -500, max = 500, step = 1,
				},
				yOffset = {
					order = 7,
					type = "range",
					name = L["yOffset"],
					desc = L["An Y offset (in pixels) to be used when anchoring new frames."],
					min = -500, max = 500, step = 1,
				},
				name = {
					order = 8,
					type = "group",
					guiInline = true,
					get = function(info) return E.db.unitframe.units["party"]["targetsGroup"]["name"][ info[getn(info)] ] end,
					set = function(info, value) E.db.unitframe.units["party"]["targetsGroup"]["name"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("party") end,
					name = NAME,
					args = {
						position = {
							type = "select",
							order = 1,
							name = L["Text Position"],
							values = positionValues,
						},
						xOffset = {
							order = 2,
							type = "range",
							name = L["Text xOffset"],
							desc = L["Offset position for text."],
							min = -300, max = 300, step = 1,
						},
						yOffset = {
							order = 3,
							type = "range",
							name = L["Text yOffset"],
							desc = L["Offset position for text."],
							min = -300, max = 300, step = 1,
						},
						text_format = {
							order = 100,
							name = L["Text Format"],
							type = "input",
							width = "full",
							desc = L["TEXT_FORMAT_DESC"],
						},
					},
				},
			},
		},
		raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateHeaderGroup, "party"),
		readycheckIcon = GetOptionsTable_ReadyCheckIcon(UF.CreateAndUpdateHeaderGroup, "party"),
		GPSArrow = GetOptionsTable_GPS("party"),
	},
}

--Raid Frames
E.Options.args.unitframe.args.raid = {
	name = L["Raid Frames"],
	type = "group",
	order = 1100,
	childGroups = "tab",
	get = function(info) return E.db.unitframe.units["raid"][ info[getn(info)] ] end,
	set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
	disabled = function() return not E.UnitFrames; end,
	args = {
		configureToggle = {
			order = 1,
			type = "execute",
			name = L["Display Frames"],
			func = function()
				UF:HeaderConfig(_G["ElvUF_Raid"], _G["ElvUF_Raid"].forceShow ~= true or nil)
			end,
		},
		resetSettings = {
			type = "execute",
			order = 2,
			name = L["Restore Defaults"],
			func = function(info, value) UF:ResetUnitSettings("raid"); E:ResetMovers("Raid Frames") end,
		},
		copyFrom = {
			type = "select",
			order = 3,
			name = L["Copy From"],
			desc = L["Select a unit to copy settings from."],
			values = {
				["party"] = L["Party Frames"],
				["raid40"] = L["Raid40 Frames"],
			},
			set = function(info, value) UF:MergeUnitSettings(value, "raid", true); end,
		},
		customText = GetOptionsTable_CustomText(UF.CreateAndUpdateHeaderGroup, "raid", nil, 4),
		generalGroup = {
			order = 5,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 1,
					type = "header",
					name = GENERAL,
				},
				enable = {
					type = "toggle",
					order = 2,
					name = L["Enable"],
				},
				hideonnpc = {
					type = "toggle",
					order = 3,
					name = L["Text Toggle On NPC"],
					desc = L["Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point."],
					get = function(info) return E.db.unitframe.units["raid"]["power"].hideonnpc end,
					set = function(info, value) E.db.unitframe.units["raid"]["power"].hideonnpc = value; UF:CreateAndUpdateHeaderGroup("raid"); end,
				},
				rangeCheck = {
					order = 4,
					name = L["Range Check"],
					desc = L["Check if you are in range to cast spells on this specific unit."],
					type = "toggle",
				},
				healPrediction = {
					order = 5,
					name = L["Heal Prediction"],
					desc = L["Show an incoming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals."],
					type = "toggle",
				},
				threatStyle = {
					type = "select",
					order = 6,
					name = L["Threat Display Mode"],
					values = threatValues,
				},
				colorOverride = {
					order = 7,
					name = L["Class Color Override"],
					desc = L["Override the default class color setting."],
					type = "select",
					values = {
						["USE_DEFAULT"] = L["Use Default"],
						["FORCE_ON"] = L["Force On"],
						["FORCE_OFF"] = L["Force Off"],
					},
				},
				orientation = {
					order = 8,
					type = "select",
					name = L["Frame Orientation"],
					desc = L["Set the orientation of the UnitFrame."],
					values = {
						--["AUTOMATIC"] = L["Automatic"], not sure if i will use this yet
						["LEFT"] = L["Left"],
						["MIDDLE"] = L["Middle"],
						["RIGHT"] = L["Right"],
					},
				},
				targetGlow = {
					order = 9,
					type = "toggle",
					name = L["Target Glow"],
				},
				positionsGroup = {
					order = 100,
					name = L["Size and Positions"],
					type = "group",
					guiInline = true,
					set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid", nil, nil, true) end,
					args = {
						width = {
							order = 1,
							name = L["Width"],
							type = "range",
							min = 10, max = 500, step = 1,
							set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
						},
						height = {
							order = 2,
							name = L["Height"],
							type = "range",
							min = 10, max = 500, step = 1,
							set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
						},
						spacer = {
							order = 3,
							name = "",
							type = "description",
							width = "full",
						},
						growthDirection = {
							order = 4,
							name = L["Growth Direction"],
							desc = L["Growth direction from the first unitframe."],
							type = "select",
							values = {
								DOWN_RIGHT = format(L["%s and then %s"], L["Down"], L["Right"]),
								DOWN_LEFT = format(L["%s and then %s"], L["Down"], L["Left"]),
								UP_RIGHT = format(L["%s and then %s"], L["Up"], L["Right"]),
								UP_LEFT = format(L["%s and then %s"], L["Up"], L["Left"]),
								RIGHT_DOWN = format(L["%s and then %s"], L["Right"], L["Down"]),
								RIGHT_UP = format(L["%s and then %s"], L["Right"], L["Up"]),
								LEFT_DOWN = format(L["%s and then %s"], L["Left"], L["Down"]),
								LEFT_UP = format(L["%s and then %s"], L["Left"], L["Up"]),
							},
						},
						numGroups = {
							order = 7,
							type = "range",
							name = L["Number of Groups"],
							min = 1, max = 8, step = 1,
							set = function(info, value)
								E.db.unitframe.units["raid"][ info[getn(info)] ] = value;
								UF:CreateAndUpdateHeaderGroup("raid")
								if _G["ElvUF_Raid"].isForced then
									UF:HeaderConfig(_G["ElvUF_Raid"])
									UF:HeaderConfig(_G["ElvUF_Raid"], true)
								end
							end,
						},
						groupsPerRowCol = {
							order = 8,
							type = "range",
							name = L["Groups Per Row/Column"],
							min = 1, max = 8, step = 1,
							set = function(info, value)
								E.db.unitframe.units["raid"][ info[getn(info)] ] = value;
								UF:CreateAndUpdateHeaderGroup("raid")
								if _G["ElvUF_Raid"].isForced then
									UF:HeaderConfig(_G["ElvUF_Raid"])
									UF:HeaderConfig(_G["ElvUF_Raid"], true)
								end
							end,
						},
						horizontalSpacing = {
							order = 9,
							type = "range",
							name = L["Horizontal Spacing"],
							min = -1, max = 50, step = 1,
						},
						verticalSpacing = {
							order = 10,
							type = "range",
							name = L["Vertical Spacing"],
							min = -1, max = 50, step = 1,
						},
					},
				},
				visibilityGroup = {
					order = 200,
					name = L["Visibility"],
					type = "group",
					guiInline = true,
					set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid", nil, nil, true) end,
					args = {
						showPlayer = {
							order = 1,
							type = "toggle",
							name = L["Display Player"],
							desc = L["When true, the header includes the player when not in a raid."],
						},
						visibility = {
							order = 2,
							type = "input",
							name = L["Visibility"],
							desc = L["The following macro must be true in order for the group to be shown, in addition to any filter that may already be set."],
							width = "full",
						},
					},
				},
				sortingGroup = {
					order = 300,
					type = "group",
					guiInline = true,
					name = L["Grouping & Sorting"],
					set = function(info, value) E.db.unitframe.units["raid"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid", nil, nil, true) end,
					args = {
						groupBy = {
							order = 1,
							name = L["Group By"],
							desc = L["Set the order that the group will sort."],
							type = "select",
							values = {
								["CLASS"] = "CLASS",
								["NAME"] = "NAME",
								["MTMA"] = L["Main Tanks / Main Assist"],
								["GROUP"] = "GROUP",
							},
						},
						sortDir = {
							order = 2,
							name = L["Sort Direction"],
							desc = L["Defines the sort order of the selected sort method."],
							type = "select",
							values = {
								["ASC"] = L["Ascending"],
								["DESC"] = L["Descending"]
							},
						},
						spacer = {
							order = 3,
							type = "description",
							width = "full",
							name = " "
						},
						raidWideSorting = {
							order = 4,
							name = L["Raid-Wide Sorting"],
							desc = L["Enabling this allows raid-wide sorting however you will not be able to distinguish between groups."],
							type = "toggle",
						},
						invertGroupingOrder = {
							order = 5,
							name = L["Invert Grouping Order"],
							desc = L["Enabling this inverts the grouping order when the raid is not full, this will reverse the direction it starts from."],
							disabled = function() return not E.db.unitframe.units["raid"].raidWideSorting end,
							type = "toggle",
						},
						startFromCenter = {
							order = 6,
							name = L["Start Near Center"],
							desc = L["The initial group will start near the center and grow out."],
							disabled = function() return not E.db.unitframe.units["raid"].raidWideSorting end,
							type = "toggle",
						},
					},
				},
			},
		},
		health = GetOptionsTable_Health(true, UF.CreateAndUpdateHeaderGroup, "raid"),
		infoPanel = GetOptionsTable_InformationPanel(UF.CreateAndUpdateHeaderGroup, "raid"),
		power = GetOptionsTable_Power(false, UF.CreateAndUpdateHeaderGroup, "raid"),
		name = GetOptionsTable_Name(UF.CreateAndUpdateHeaderGroup, "raid"),
		portrait = GetOptionsTable_Portrait(UF.CreateAndUpdateHeaderGroup, "raid"),
		--buffs = GetOptionsTable_Auras(true, "buffs", true, UF.CreateAndUpdateHeaderGroup, "raid"),
		--debuffs = GetOptionsTable_Auras(true, "debuffs", true, UF.CreateAndUpdateHeaderGroup, "raid"),
		buffIndicator = {
			order = 701,
			type = "group",
			name = L["Buff Indicator"],
			get = function(info) return E.db.unitframe.units["raid"]["buffIndicator"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["raid"]["buffIndicator"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Buff Indicator"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				size = {
					type = "range",
					name = L["Size"],
					desc = L["Size of the indicator icon."],
					order = 3,
					min = 4, max = 50, step = 1,
				},
				fontSize = {
					type = "range",
					name = FONT_SIZE,
					order = 4,
					min = 7, max = 22, step = 1,
				},
				profileSpecific = {
					type = "toggle",
					name = L["Profile Specific"],
					desc = L["Use the profile specific filter 'Buff Indicator (Profile)' instead of the global filter 'Buff Indicator'."],
					order = 5,
				},
				configureButton = {
					type = "execute",
					name = L["Configure Auras"],
					func = function()
						if E.db.unitframe.units["raid"]["buffIndicator"].profileSpecific then
							E:SetToFilterConfig("Buff Indicator (Profile)")
						else
							E:SetToFilterConfig("Buff Indicator")
						end
					end,
					order = 6
				},
			},
		},
		roleIcon = {
			order = 702,
			type = "group",
			name = L["Role Icon"],
			get = function(info) return E.db.unitframe.units["raid"]["roleIcon"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["raid"]["roleIcon"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Role Icon"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				position = {
					type = "select",
					order = 3,
					name = L["Position"],
					values = positionValues,
				},
				attachTo = {
					type = "select",
					order = 4,
					name = L["Attach To"],
					values = {
						["Health"] = HEALTH,
						["Power"] = L["Power"],
						["InfoPanel"] = L["Information Panel"],
						["Frame"] = L["Frame"],
					},
				},
				xOffset = {
					order = 5,
					type = "range",
					name = L["xOffset"],
					min = -300, max = 300, step = 1,
				},
				yOffset = {
					order = 6,
					type = "range",
					name = L["yOffset"],
					min = -300, max = 300, step = 1,
				},
				size = {
					type = "range",
					order = 7,
					name = L["Size"],
					min = 4, max = 100, step = 1,
				},
			},
		},
		raidRoleIcons = {
			order = 703,
			type = "group",
			name = L["RL / ML Icons"],
			get = function(info) return E.db.unitframe.units["raid"]["raidRoleIcons"][ info[getn(info)] ] end,
			set = function(info, value) E.db.unitframe.units["raid"]["raidRoleIcons"][ info[getn(info)] ] = value; UF:CreateAndUpdateHeaderGroup("raid") end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["RL / ML Icons"],
				},
				enable = {
					type = "toggle",
					name = L["Enable"],
					order = 2,
				},
				position = {
					type = "select",
					order = 3,
					name = L["Position"],
					values = {
						["TOPLEFT"] = "TOPLEFT",
						["TOPRIGHT"] = "TOPRIGHT",
					},
				},
			},
		},
		--rdebuffs = GetOptionsTable_RaidDebuff(UF.CreateAndUpdateHeaderGroup, "raid"),
		--raidicon = GetOptionsTable_RaidIcon(UF.CreateAndUpdateHeaderGroup, "raid"),
		readycheckIcon = GetOptionsTable_ReadyCheckIcon(UF.CreateAndUpdateHeaderGroup, "raid"),
		GPSArrow = GetOptionsTable_GPS("raid"),
	},
}

--MORE COLORING STUFF YAY
E.Options.args.unitframe.args.generalOptionsGroup.args.allColorsGroup.args.classResourceGroup = {
	order = -10,
	type = "group",
	name = L["Class Resources"],
	get = function(info)
		local t = E.db.unitframe.colors.classResources[ info[getn(info)] ]
		local d = P.unitframe.colors.classResources[ info[getn(info)] ]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b
	end,
	set = function(info, r, g, b)
		local t = E.db.unitframe.colors.classResources[ info[getn(info)] ]
		t.r, t.g, t.b = r, g, b
		UF:Update_AllFrames()
	end,
	args = {}
}

E.Options.args.unitframe.args.generalOptionsGroup.args.allColorsGroup.args.classResourceGroup.args.bgColor = {
	order = 1,
	type = "color",
	name = L["Backdrop Color"],
	hasAlpha = false,
}

for i = 1, 3 do
	E.Options.args.unitframe.args.generalOptionsGroup.args.allColorsGroup.args.classResourceGroup.args["combo"..i] = {
		order = i + 2,
		type = "color",
		name = L["Combo Point"].." #"..i,
		get = function(info)
			local t = E.db.unitframe.colors.classResources.comboPoints[i]
			local d = P.unitframe.colors.classResources.comboPoints[i]
			return t.r, t.g, t.b, t.a, d.r, d.g, d.b
		end,
		set = function(info, r, g, b)
			local t = E.db.unitframe.colors.classResources.comboPoints[i]
			t.r, t.g, t.b = r, g, b
			UF:Update_AllFrames()
		end,
	}
end


if P.unitframe.colors.classResources[E.myclass] then
	E.Options.args.unitframe.args.generalOptionsGroup.args.allColorsGroup.args.classResourceGroup.args.spacer2 = {
		order = 10,
		name = " ",
		type = "description",
		width = "full",
	}
end

--Custom Texts
function E:RefreshCustomTextsConfigs()
	--Hide any custom texts that don't belong to current profile
	for _, customText in pairs(CUSTOMTEXT_CONFIGS) do
		customText.hidden = true
	end
	wipe(CUSTOMTEXT_CONFIGS)

	for unit, _ in pairs(E.db.unitframe.units) do
		if E.db.unitframe.units[unit].customTexts then
			for objectName, _ in pairs(E.db.unitframe.units[unit].customTexts) do
				CreateCustomTextGroup(unit, objectName)
			end
		end
	end
end
E:RefreshCustomTextsConfigs()
