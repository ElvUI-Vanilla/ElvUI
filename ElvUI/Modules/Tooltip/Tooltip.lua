local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local TT = E:NewModule("Tooltip", "AceHook-3.0", "AceEvent-3.0");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local twipe, tinsert, tconcat = table.wipe, table.insert, table.concat
local floor = math.floor
local find, format, match = string.find, string.format, string.match
--WoW API / Variables
local IsShiftKeyDown = IsShiftKeyDown
local UnitExists = UnitExists
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitName = UnitName
local GetGuildInfo = GetGuildInfo
local UnitPVPName = UnitPVPName
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitRace = UnitRace
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitReaction = UnitReaction
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitIsPVP = UnitIsPVP
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitIsUnit = UnitIsUnit
local SetTooltipMoney = SetTooltipMoney

local targetList = {}
local TAPPED_COLOR = {r = 0.6, g = 0.6, b = 0.6}

local classification = {
	worldboss = format("|cffAF5050 %s|r", BOSS),
	rareelite = format("|cffAF5050+ %s|r", ITEM_QUALITY3_DESC),
	elite = "|cffAF5050+|r",
	rare = format("|cffAF5050 %s|r", ITEM_QUALITY3_DESC)
}

function TT:GameTooltip_SetDefaultAnchor(tt, parent)
	if E.private.tooltip.enable ~= true then return end
	if tt:GetAnchorType() ~= "ANCHOR_NONE" then return end

	if parent then
		if self.db.healthBar.statusPosition == "BOTTOM" then
			if GameTooltipStatusBar.anchoredToTop then
				GameTooltipStatusBar:ClearAllPoints()
				E:Point(GameTooltipStatusBar, "TOPLEFT", GameTooltip, "BOTTOMLEFT", E.Border, -(E.Spacing * 3))
				E:Point(GameTooltipStatusBar, "TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -E.Border, -(E.Spacing * 3))
				E:Point(GameTooltipStatusBar.text, "CENTER", GameTooltipStatusBar, 0, -3)
				GameTooltipStatusBar.anchoredToTop = nil
			end
		else
			if not GameTooltipStatusBar.anchoredToTop then
				GameTooltipStatusBar:ClearAllPoints()
				E:Point(GameTooltipStatusBar, "BOTTOMLEFT", GameTooltip, "TOPLEFT", E.Border, (E.Spacing * 3))
				E:Point(GameTooltipStatusBar, "BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -E.Border, (E.Spacing * 3))
				E:Point(GameTooltipStatusBar.text, "CENTER", GameTooltipStatusBar, 0, 3)
				GameTooltipStatusBar.anchoredToTop = true
			end
		end
		if self.db.cursorAnchor then
			tt:SetOwner(parent, "ANCHOR_CURSOR")
			return;
		else
			tt:SetOwner(parent, "ANCHOR_NONE")
		end
	end

	if not E:HasMoverBeenMoved("TooltipMover") then
		if ElvUI_ContainerFrame and ElvUI_ContainerFrame:IsShown() then
			E:Point(tt, "BOTTOMRIGHT", ElvUI_ContainerFrame, "TOPRIGHT", 0, 18)
		elseif RightChatPanel:GetAlpha() == 1 and RightChatPanel:IsShown() then
			E:Point(tt, "BOTTOMRIGHT", RightChatPanel, "TOPRIGHT", 0, 18)
		else
			E:Point(tt, "BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", 0, 18)
		end
	else
		local point = E:GetScreenQuadrant(TooltipMover)
		if point == "TOPLEFT" then
			tt:SetPoint("TOPLEFT", TooltipMover)
		elseif point == "TOPRIGHT" then
			tt:SetPoint("TOPRIGHT", TooltipMover)
		elseif point == "BOTTOMLEFT" or point == "LEFT" then
			tt:SetPoint("BOTTOMLEFT", TooltipMover)
		else
			tt:SetPoint("BOTTOMRIGHT", TooltipMover)
		end
	end
end

function TT:SetStyle(tt)
	E:SetTemplate(this, "Transparent", nil, true)
	local r, g, b = this:GetBackdropColor()
	this:SetBackdropColor(r, g, b, self.db.colorAlpha)
end

function TT:RemoveTrashLines(tt)
	for i = 2, tt:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()

		if linetext == HELPFRAME_HOME_ISSUE3_HEADER or linetext == FACTION_ALLIANCE or linetext == FACTION_HORDE then
			tiptext:SetText(nil)
			tiptext:Hide()
		end
	end
end

function TT:GetLevelLine(tt, offset)
	for i = offset, tt:NumLines() do
		local tipText = _G["GameTooltipTextLeft"..i]
		if tipText:GetText() and find(tipText:GetText(), LEVEL) then
			return tipText
		end
	end
end

function TT:UPDATE_MOUSEOVER_UNIT(_, unit)
	if not unit then unit = "mouseover" end
	if not UnitExists(unit) then return end

	TT:RemoveTrashLines(GameTooltip)
	local level = UnitLevel(unit)
	local isShiftKeyDown = IsShiftKeyDown()

	local color
	if UnitIsPlayer(unit) then
		local localeClass, class = UnitClass(unit)
		local name = UnitName(unit)
		local guildName, guildRankName = GetGuildInfo(unit)
		local pvpName = UnitPVPName(unit)
		if not localeClass or not class then return end

		color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]

		GameTooltipTextLeft1:SetText(format("%s%s", E:RGBToHex(color.r, color.g, color.b), name))

		local diffColor = GetQuestDifficultyColor(level)
		local race = UnitRace(unit)

		if guildName then
			if self.db.guildRanks then
				GameTooltipTextLeft2:SetText(format("<|cff00ff10%s|r> [|cff00ff10%s|r]", guildName, guildRankName))
			else
				GameTooltipTextLeft2:SetText(format("<|cff00ff10%s|r>", guildName))
			end
			GameTooltip:AddLine(format("|cff%02x%02x%02x%s|r %s %s%s|r", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", race or "", E:RGBToHex(color.r, color.g, color.b), localeClass), 1, 1, 1)
		else
			GameTooltipTextLeft2:SetText(format("|cff%02x%02x%02x%s|r %s %s%s|r", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", race or "", E:RGBToHex(color.r, color.g, color.b), localeClass))
		end
	else
		if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
			color = TAPPED_COLOR
		else
			color = E.db.tooltip.useCustomFactionColors and E.db.tooltip.factionColors[UnitReaction(unit, "player")] or FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		end

		local levelLine = self:GetLevelLine(GameTooltip, 2)
		if levelLine then
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			local pvpFlag = ""
			local diffColor = GetQuestDifficultyColor(level)

			if UnitIsPVP(unit) then
				pvpFlag = format(" (%s)", HELPFRAME_HOME_ISSUE3_HEADER)
			end

			levelLine:SetText(format("|cff%02x%02x%02x%s|r%s %s%s", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", classification[creatureClassification] or "", creatureType or "", pvpFlag))
		end
	end

	local unitTarget = unit.."target"
	if self.db.targetInfo and unit ~= "player" and UnitExists(unitTarget) then
		local targetColor;
		if UnitIsPlayer(unitTarget) then
			local _, class = UnitClass(unitTarget);
			targetColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class];
		else
			local reaction = UnitReaction(unitTarget, "player") or 4
			targetColor = E.db.tooltip.useCustomFactionColors and E.db.tooltip.factionColors[reaction] or FACTION_BAR_COLORS[reaction]
		end

		GameTooltip:AddDoubleLine(format("%s:", TARGET), format("|cff%02x%02x%02x%s|r", targetColor.r * 255, targetColor.g * 255, targetColor.b * 255, UnitName(unitTarget)))
	end

	local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
	if self.db.targetInfo and (numParty > 0 or numRaid > 0) then
		for i = 1, (numRaid > 0 and numRaid or numParty) do
			local groupUnit = (numRaid > 0 and "raid"..i or "party"..i)
			if UnitIsUnit(groupUnit.."target", unit) and (not UnitIsUnit(groupUnit,"player")) then
				local _, class = UnitClass(groupUnit)
				local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
				tinsert(targetList, format("%s%s", E:RGBToHex(color.r, color.g, color.b), UnitName(groupUnit)))
			end
		end
		local numList = getn(targetList)
		if numList > 0 then
			GameTooltip:AddLine(format("%s (|cffffffff%d|r): %s", L["Targeted By:"], numList, tconcat(targetList, ", ")), nil, nil, nil, true)
			twipe(targetList)
		end
	end

	if color then
		GameTooltipStatusBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		GameTooltipStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
	end

	GameTooltip:Show()

	local textWidth = GameTooltipStatusBar.text:GetStringWidth()
	if textWidth then
		GameTooltip:SetMinimumWidth(textWidth)
	end
end

function TT:SetUnit(tt, unit)
	self:UPDATE_MOUSEOVER_UNIT(nil, unit)
end

function TT:GameTooltipStatusBar_OnValueChanged()
	if not arg1 or not self.db.healthBar.text or not this.text then return end

	local _, max = this:GetMinMaxValues()
	if arg1 > 0 and max == 1 then
		this.text:SetText(format("%d%%", floor(arg1 * 100)))
		this:SetStatusBarColor(TAPPED_COLOR.r, TAPPED_COLOR.g, TAPPED_COLOR.b) --most effeciant?
	elseif arg1 == 0 then
		this.text:SetText(DEAD)
	else
		this.text:SetText(E:ShortValue(arg1).." / "..E:ShortValue(max))
	end
end

function TT:SetItemRef(link)
	if find(link, "^item:") then
		local id = tonumber(match(link, "(%d+)"))
		ItemRefTooltip:AddLine(format("|cFFCA3C3C%s|r %d", ID, id))
		ItemRefTooltip:Show()
	end
end

function TT:CheckBackdropColor()
	if not GameTooltip:IsShown() then return end

	local r, g, b = GameTooltip:GetBackdropColor()
	if r and g and b then
		r = E:Round(r, 1)
		g = E:Round(g, 1)
		b = E:Round(b, 1)
		local red, green, blue = unpack(E.media.backdropfadecolor)
		if r ~= red or g ~= green or b ~= blue then
			GameTooltip:SetBackdropColor(red, green, blue, self.db.colorAlpha)
		end
	end
end

function TT:SetTooltipFonts()
	local font = E.LSM:Fetch("font", E.db.tooltip.font)
	local fontOutline = E.db.tooltip.fontOutline
	local headerSize = E.db.tooltip.headerFontSize
	local textSize = E.db.tooltip.textFontSize
	local smallTextSize = E.db.tooltip.smallTextFontSize

	GameTooltipHeaderText:SetFont(font, headerSize, fontOutline)
	GameTooltipText:SetFont(font, textSize, fontOutline)
	GameTooltipTextSmall:SetFont(font, smallTextSize, fontOutline)
	if GameTooltip.hasMoney then
		for i = 1, GameTooltip.numMoneyFrames do
			_G["GameTooltipMoneyFrame"..i.."PrefixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SuffixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."GoldButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SilverButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."CopperButtonText"]:SetFont(font, textSize, fontOutline)
		end
	end

	ShoppingTooltip1TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight4:SetFont(font, headerSize, fontOutline)
end

function TT:Initialize()
	self.db = E.db.tooltip

	if E.private.tooltip.enable ~= true then return end
	E.Tooltip = TT

	E:Height(GameTooltipStatusBar, self.db.healthBar.height)
	GameTooltipStatusBar:SetScript("OnValueChanged", nil)
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY")
	E:Point(GameTooltipStatusBar.text, "CENTER", GameTooltipStatusBar, 0, -3)
	E:FontTemplate(GameTooltipStatusBar.text, E.LSM:Fetch("font", self.db.healthBar.font), self.db.healthBar.fontSize, self.db.healthBar.fontOutline)

	if not GameTooltip.hasMoney then
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		GameTooltipMoneyFrame:Hide()
	end
	self:SetTooltipFonts()

	self:SecureHook("GameTooltip_SetDefaultAnchor")
	self:SecureHook("SetItemRef")
	self:SecureHook(GameTooltip, "SetUnit")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	self:HookScript(GameTooltipStatusBar, "OnValueChanged", "GameTooltipStatusBar_OnValueChanged")
end

local function InitializeCallback()
	TT:Initialize()
end

E:RegisterModule(TT:GetName(), InitializeCallback)