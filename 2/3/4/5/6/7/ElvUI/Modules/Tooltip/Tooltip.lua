local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local TT = E:NewModule("Tooltip", "AceHook-3.0", "AceEvent-3.0");

--Cache global variables
--Lua functions
local unpack = unpack
--WoW API / Variables

local classification = {
	worldboss = format("|cffAF5050 %s|r", BOSS),
	rareelite = format("|cffAF5050+ %s|r", ITEM_QUALITY3_DESC),
	elite = "|cffAF5050+|r",
	rare = format("|cffAF5050 %s|r", ITEM_QUALITY3_DESC)
}

function TT:SetStyle(tt)
	E:SetTemplate(this, "Transparent", nil, true)
	local r, g, b = this:GetBackdropColor()
	this:SetBackdropColor(r, g, b, self.db.colorAlpha)
end

function TT:RemoveTrashLines(tt)
	for i = 2, tt:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()

		if linetext == PVP or linetext == FACTION_ALLIANCE or linetext == FACTION_HORDE then
			tiptext:SetText(nil)
			tiptext:Hide()
		end
	end
end

function TT:GetLevelLine(tt, offset)
	for i=offset, tt:NumLines() do
		local tipText = _G["GameTooltipTextLeft"..i]
		if tipText:GetText() and string.find(tipText:GetText(), LEVEL) then
			return tipText
		end
	end
end

function TT:UPDATE_MOUSEOVER_UNIT()
	if not UnitExists("mouseover") then return end

	--TT:RemoveTrashLines(GameTooltip)
	local level = UnitLevel("mouseover")
	local isShiftKeyDown = IsShiftKeyDown()

	local color
	if UnitIsPlayer("mouseover") then
		local localeClass, class = UnitClass("mouseover")
		local name = UnitName("mouseover")
		local guildName, guildRankName = GetGuildInfo("mouseover")
		local pvpName = UnitPVPName("mouseover")
		if not localeClass or not class then return end

		color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]

		GameTooltipTextLeft1:SetText(format("%s%s", E:RGBToHex(color.r, color.g, color.b), name))

		local guildText
		if guildName then
			if self.db.guildRanks then
				guildText = format("<|cff00ff10%s|r> [|cff00ff10%s|r]", guildName, guildRankName)
			else
				guildText = format("<|cff00ff10%s|r>", guildName)
			end
		end

		local diffColor = GetQuestDifficultyColor(level)
		local race = UnitRace("mouseover")
		GameTooltipTextLeft2:SetText((guildText and guildText.."\n" or "")..format("|cff%02x%02x%02x%s|r %s %s%s|r", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", race or "", E:RGBToHex(color.r, color.g, color.b), localeClass))
	else
		if UnitIsTapped("mouseover") and not UnitIsTappedByPlayer("mouseover") then
			color = TAPPED_COLOR
		else
			color = E.db.tooltip.useCustomFactionColors and E.db.tooltip.factionColors[UnitReaction("mouseover", "player")] or FACTION_BAR_COLORS[UnitReaction("mouseover", "player")]
		end

		local levelLine = self:GetLevelLine(GameTooltip, 2)
		if levelLine then
			local creatureClassification = UnitClassification("mouseover")
			local creatureType = UnitCreatureType("mouseover")
			local pvpFlag = ""
			local diffColor = GetQuestDifficultyColor(level)

			if UnitIsPVP("mouseover") then
				pvpFlag = format(" (%s)", PVP)
			end

			levelLine:SetText(format("|cff%02x%02x%02x%s|r%s %s%s", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", classification[creatureClassification] or "", creatureType or "", pvpFlag))
		end
	end

	if(color) then
		GameTooltipStatusBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		GameTooltipStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
	end

	GameTooltip:Show()
end

function TT:SetUnit(...)
	print(unpack(arg))
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

function TT:Initialize()
	self.db = E.db.tooltip

	if E.private.tooltip.enable ~= true then return end
	E.Tooltip = TT

	self:SecureHook(GameTooltip, "SetUnit")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

local function InitializeCallback()
	TT:Initialize()
end

E:RegisterModule(TT:GetName(), InitializeCallback)