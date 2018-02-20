local pairs = pairs
local ipairs = ipairs

local unitExistsWatchers = {}
local unitExistsCache = setmetatable({},{
	__index = function(t, k)
		local v = UnitExists(k) or false
		t[k] = v
		return v
	end
})

local function updateUnitWatch(frame)
	local unit = frame.unit
	local exists = (unit and unitExistsCache[unit])
	if exists then
		if not frame:IsShown() then
			frame:Show()
		end
	elseif frame:IsShown() then
		frame:Hide()
	end
end

local unitWatch = CreateFrame("Frame")
unitWatch:Hide()

local timer = 0
unitWatch:SetScript("OnUpdate", function()
	timer = timer - arg1
	if timer <= 0 then
		timer = 0.2

		for k in pairs(unitExistsCache) do
			unitExistsCache[k] = nil
		end
		for frame in pairs(unitExistsWatchers) do
			updateUnitWatch(frame)
		end
	end
end)
unitWatch:SetScript("OnEvent", function() timer = 0 end)

unitWatch:RegisterEvent("PLAYER_TARGET_CHANGED")
unitWatch:RegisterEvent("PLAYER_REGEN_DISABLED")
unitWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
unitWatch:RegisterEvent("UNIT_PET")
unitWatch:RegisterEvent("RAID_ROSTER_UPDATE")
unitWatch:RegisterEvent("PARTY_MEMBERS_CHANGED")

function RegisterUnitWatch(frame)
	unitExistsWatchers[frame] = true
	unitWatch:Show()
	updateUnitWatch(frame)
end

function UnregisterUnitWatch(frame)
	unitExistsWatchers[frame] = nil
end

--[[
List of the various configuration attributes
======================================================
showRaid = [BOOLEAN] -- true if the header should be shown while in a raid
showParty = [BOOLEAN] -- true if the header should be shown while in a party and not in a raid
showPlayer = [BOOLEAN] -- true if the header should show the player when not in a raid
showSolo = [BOOLEAN] -- true if the header should be shown while not in a group (implies showPlayer)
nameList = [STRING] -- a comma separated list of player names (not used if 'groupFilter' is set)
groupFilter = [1-8, STRING] -- a comma seperated list of raid group numbers and/or uppercase class names and/or uppercase roles
strictFiltering = [BOOLEAN] - if true, then characters must match both a group and a class from the groupFilter list
point = [STRING] -- a valid XML anchoring point (Default: "TOP")
xOffset = [NUMBER] -- the x-Offset to use when anchoring the unit buttons (Default: 0)
yOffset = [NUMBER] -- the y-Offset to use when anchoring the unit buttons (Default: 0)
sortMethod = ["INDEX", "NAME"] -- defines how the group is sorted (Default: "INDEX")
sortDir = ["ASC", "DESC"] -- defines the sort order (Default: "ASC")
template = [STRING] -- the XML template to use for the unit buttons
templateType = [STRING] - specifies the frame type of the managed subframes (Default: "Button")
groupBy = [nil, "GROUP", "CLASS", "ROLE"] - specifies a "grouping" type to apply before regular sorting (Default: nil)
groupingOrder = [STRING] - specifies the order of the groupings (ie. "1,2,3,4,5,6,7,8")
maxColumns = [NUMBER] - maximum number of columns the header will create (Default: 1)
unitsPerColumn = [NUMBER or nil] - maximum units that will be displayed in a singe column, nil is infinate (Default: nil)
startingIndex = [NUMBER] - the index in the final sorted unit list at which to start displaying units (Default: 1)
columnSpacing = [NUMBER] - the ammount of space between the rows/columns (Default: 0)
columnAnchorPoint = [STRING] - the anchor point of each new column (ie. use LEFT for the columns to grow to the right)
--]]

function SecureGroupHeader_OnEvent()
	if (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") and this:IsVisible() then
		SecureGroupHeader_Update(this)
	end
end

-- relativePoint, xMultiplier, yMultiplier = getRelativePointAnchor(point)
-- Given a point return the opposite point and which axes the point
-- depends on.
local function getRelativePointAnchor(point)
	point = strupper(point)
	if point == "TOP" then
		return "BOTTOM", 0, -1
	elseif point == "BOTTOM" then
		return "TOP", 0, 1
	elseif point == "LEFT" then
		return "RIGHT", 1, 0
	elseif point == "RIGHT" then
		return "LEFT", -1, 0
	elseif point == "TOPLEFT" then
		return "BOTTOMRIGHT", 1, -1
	elseif point == "TOPRIGHT" then
		return "BOTTOMLEFT", -1, -1
	elseif point == "BOTTOMLEFT" then
		return "TOPRIGHT", 1, 1
	elseif point == "BOTTOMRIGHT" then
		return "TOPLEFT", -1, 1
	else
		return "CENTER", 0, 0
	end
end

function ApplyUnitButtonConfiguration(frame)
	RegisterUnitWatch(frame)
end

local function ApplyConfig(header, newChild, defaultConfigFunction)
	local configFunction = header.initialConfigFunction or defaultConfigFunction
	if type(configFunction) == "function" then
		configFunction(newChild)
		return true
	end
end

function SetupUnitButtonConfiguration(header, newChild, defaultConfigFunction)
	if ApplyConfig(header, newChild, defaultConfigFunction) then
		ApplyUnitButtonConfiguration(newChild)
	end
end

-- empties tbl and assigns the value true to each key passed as part of ...
local function fillTable(tbl, ...)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
	for i = 1, getn(arg), 1 do
		local key = arg[i]
		key = tonumber(key) or key
		tbl[key] = true
	end
end

-- same as fillTable() except that each key is also stored in
-- the array portion of the table in order
local function doubleFillTable(tbl, ...)
	fillTable(tbl, unpack(arg))
	for i = 1, getn(arg), 1 do
		tbl[i] = arg[i]
	end
end

--working tables
local tokenTable = {}
local sortingTable = {}
local groupingTable = {}
local tempTable = {}

-- creates child frames and finished configuring them
local function configureChildren(self)
	local point = self:GetAttribute("point") or "TOP" --default anchor point of "TOP"
	local relativePoint, xOffsetMult, yOffsetMult = getRelativePointAnchor(point)
	local xMultiplier, yMultiplier =  abs(xOffsetMult), abs(yOffsetMult)
	local xOffset = self:GetAttribute("xOffset") or 0 --default of 0
	local yOffset = self:GetAttribute("yOffset") or 0 --default of 0
	local sortDir = self:GetAttribute("sortDir") or "ASC" --sort ascending by default
	local columnSpacing = self:GetAttribute("columnSpacing") or 0
	local startingIndex = self:GetAttribute("startingIndex") or 1

	local unitCount = getn(sortingTable)
	local numDisplayed = unitCount - (startingIndex - 1)
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local numColumns
	if unitsPerColumn and numDisplayed > unitsPerColumn then
		numColumns = min(ceil(numDisplayed / unitsPerColumn), (self:GetAttribute("maxColumns") or 1))
	else
		unitsPerColumn = numDisplayed
		numColumns = 1
	end
	local loopStart = startingIndex
	local loopFinish = min((startingIndex - 1) + unitsPerColumn * numColumns, unitCount)
	local step = 1

	numDisplayed = loopFinish - (loopStart - 1)

	if sortDir == "DESC" then
		loopStart = unitCount - (startingIndex - 1)
		loopFinish = loopStart - (numDisplayed - 1)
		step = -1
	end

	-- ensure there are enough buttons
	local needButtons = max(1, numDisplayed)
	if not self:GetAttribute("child"..needButtons) then
		local name = self:GetName()
		if not name then
			self:Hide()
			return
		end
		for i = 1, needButtons, 1 do
			local childAttr = "child"..i
			if not self:GetAttribute(childAttr) then
				local newButton = CreateFrame("Button", name.."UnitButton"..i, self)
				newButton:SetFrameStrata("LOW")
				SetupUnitButtonConfiguration(self, newButton)
				self:SetAttribute(childAttr, newButton)
			end
		end
	end

	local columnAnchorPoint, columnRelPoint, colxMulti, colyMulti
	if numColumns > 1 then
		columnAnchorPoint = self:GetAttribute("columnAnchorPoint")
		columnRelPoint, colxMulti, colyMulti = getRelativePointAnchor(columnAnchorPoint)
	end

	local buttonNum = 0
	local columnNum = 1
	local columnUnitCount = 0
	local currentAnchor = self

	for i = loopStart, loopFinish, step do
		buttonNum = buttonNum + 1
		columnUnitCount = columnUnitCount + 1
		if columnUnitCount > unitsPerColumn then
			columnUnitCount = 1
			columnNum = columnNum + 1
		end

		local unitButton = self:GetAttribute("child"..buttonNum)
		unitButton:Hide()
		unitButton:ClearAllPoints()
		if buttonNum == 1 then
			unitButton:SetPoint(point, currentAnchor, point, 0, 0)
			if columnAnchorPoint then
				unitButton:SetPoint(columnAnchorPoint, currentAnchor, columnAnchorPoint, 0, 0)
			end
		elseif columnUnitCount == 1 then
			local columnAnchor = self:GetAttribute("child"..(buttonNum - unitsPerColumn))
			unitButton:SetPoint(columnAnchorPoint, columnAnchor, columnRelPoint, colxMulti * columnSpacing, colyMulti * columnSpacing)
		else
			unitButton:SetPoint(point, currentAnchor, relativePoint, xMultiplier * xOffset, yMultiplier * yOffset)
		end
		unitButton.unit = sortingTable[sortingTable[i]]
		unitButton:Show()

		currentAnchor = unitButton
	end
	repeat
		buttonNum = buttonNum + 1
		local unitButton = self:GetAttribute("child"..buttonNum)
		if unitButton then
			unitButton:Hide()
			unitButton.unit = nil
		end
	until not unitButton

	local unitButton = self:GetAttribute("child1")
	local unitButtonWidth = unitButton:GetWidth()
	local unitButtonHeight = unitButton:GetHeight()
	if numDisplayed > 0 then
		local width = xMultiplier * (unitsPerColumn - 1) * unitButtonWidth + ((unitsPerColumn - 1) * (xOffset * xOffsetMult)) + unitButtonWidth
		local height = yMultiplier * (unitsPerColumn - 1) * unitButtonHeight + ((unitsPerColumn - 1) * (yOffset * yOffsetMult)) + unitButtonHeight

		if numColumns > 1 then
			width = width + ((numColumns -1) * abs(colxMulti) * (width + columnSpacing))
			height = height + ((numColumns -1) * abs(colyMulti) * (height + columnSpacing))
		end

		self:SetWidth(width)
		self:SetHeight(height)
	else
		local minWidth = self:GetAttribute("minWidth") or (yMultiplier * unitButtonWidth)
		local minHeight = self:GetAttribute("minHeight") or (xMultiplier * unitButtonHeight)
		self:SetWidth(max(minWidth, 0.1))
		self:SetHeight(max(minHeight, 0.1))
	end
end

local function GetGroupHeaderType(self)
	local type, start, stop

	local nRaid = GetNumRaidMembers()
	local nParty = GetNumPartyMembers()
	if nRaid > 0 and self:GetAttribute("showRaid") then
		type = "RAID"
	elseif (nRaid > 0 or nParty > 0) and self:GetAttribute("showParty") then
		type = "PARTY"
	elseif self:GetAttribute("showSolo") then
		type = "SOLO"
	end
	if type then
		if type == "RAID" then
			start = 1
			stop = nRaid
		else
			if type == "SOLO" or self:GetAttribute("showPlayer") then
				start = 0
			else
				start = 1
			end
			stop = nParty
		end
	end

	return type, start, stop
end

local function GetGroupRosterInfo(type, index)
	local _, unit, name, subgroup, className
	if type == "RAID" then
		unit = "raid"..index
		name, _, subgroup, _, _, className = GetRaidRosterInfo(index)
	else
		if index > 0 then
			unit = "party"..index
		else
			unit = "player"
		end
		if UnitExists(unit) then
			name = UnitName(unit)
			_, className = UnitClass(unit)
		end
		subgroup = 1
	end
	return unit, name, subgroup, className
end

function SecureGroupHeader_Update(self)
	local nameList = self:GetAttribute("nameList")
	local groupFilter = self:GetAttribute("groupFilter")
	local sortMethod = self:GetAttribute("sortMethod")
	local groupBy = self:GetAttribute("groupBy")

	for key in pairs(sortingTable) do
		sortingTable[key] = nil
	end
	table.setn(sortingTable, 0)

	-- See if this header should be shown
	local type, start, stop = GetGroupHeaderType(self)
	if not type then
		configureChildren(self)
		return
	end

	if not groupFilter and not nameList then
		groupFilter = "1,2,3,4,5,6,7,8"
	end

	if groupFilter then
		-- filtering by a list of group numbers and/or classes
		fillTable(tokenTable, strsplit(",", groupFilter))
		local strictFiltering = self:GetAttribute("strictFiltering") -- non-strict by default
		for i = start, stop, 1 do
			local unit, name, subgroup, className = GetGroupRosterInfo(type, i)
			if name and ((not strictFiltering) and (tokenTable[subgroup] or tokenTable[className])) or (tokenTable[subgroup] and tokenTable[className]) then
				tinsert(sortingTable, name)
				sortingTable[name] = unit
				if groupBy == "GROUP" then
					groupingTable[name] = subgroup
				elseif groupBy == "CLASS" then
					groupingTable[name] = className
				end
			end
		end

		if groupBy then
			local groupingOrder = self:GetAttribute("groupingOrder")
			doubleFillTable(tokenTable, strsplit(",", groupingOrder))
			for k in pairs(tempTable) do
				tempTable[k] = nil
			end
			for _, grouping in ipairs(tokenTable) do
				grouping = tonumber(grouping) or grouping
				for k in ipairs(groupingTable) do
					groupingTable[k] = nil
				end
				table.setn(groupingTable, 0)
				for index, name in ipairs(sortingTable) do
					if groupingTable[name] == grouping then
						tinsert(groupingTable, name)
						tempTable[name] = true
					end
				end
				if sortMethod == "NAME" then -- sort by ID by default
					table.sort(groupingTable)
				end
				for _, name in ipairs(groupingTable) do
					tinsert(tempTable, name)
				end
			end
			-- handle units whose group didn't appear in groupingOrder
			for k in ipairs(groupingTable) do
				groupingTable[k] = nil
			end
			table.setn(groupingTable, 0)

			for index, name in ipairs(sortingTable) do
				if not tempTable[name] then
					tinsert(groupingTable, name)
				end
			end
			if sortMethod == "NAME" then -- sort by ID by default
				table.sort(groupingTable)
			end
			for _, name in ipairs(groupingTable) do
				tinsert(tempTable, name)
			end

			--copy the names back to sortingTable
			for index, name in ipairs(tempTable) do
				sortingTable[index] = name
			end

		elseif sortMethod == "NAME" then -- sort by ID by default
			table.sort(sortingTable)
		end
	else
		-- filtering via a list of names
		doubleFillTable(sortingTable, strsplit(",", nameList))
		for i = start, stop, 1 do
			local unit, name = GetGroupRosterInfo(type, i)
			if sortingTable[name] then
				sortingTable[name] = unit
			end
		end
		for i = getn(sortingTable), 1, -1 do
			local name = sortingTable[i]
			if sortingTable[name] == true then
				tremove(sortingTable, i)
			end
		end
		if sortMethod == "NAME" then
			table.sort(sortingTable)
		end
	end

	configureChildren(self)
end