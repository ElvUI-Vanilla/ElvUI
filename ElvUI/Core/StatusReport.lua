local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Cache global variables
--Lua functions
local select = select
local max = math.max
--WoW API / Variables
local CreateFrame = CreateFrame
local GetAddOnInfo = GetAddOnInfo
local GetCurrentResolution = GetCurrentResolution
local GetCVar = GetCVar
local GetLocale = GetLocale
local GetNumAddOns = GetNumAddOns
local GetRealZoneText = GetRealZoneText
local GetScreenResolutions = GetScreenResolutions
local UnitLevel = UnitLevel

local function AreOtherAddOnsEnabled()
	local name, loadable, reason, _
	for i = 1, GetNumAddOns() do
		name, _, _, loadable, reason = GetAddOnInfo(i)
		if (name ~= "ElvUI" and name ~= "ElvUI_Config" and name ~= "!Compatibility" and name ~= "!DebugTools") and (loadable or (not loadable and reason == "DEMAND_LOADED")) then --Loaded or load on demand
			return "Yes"
		end
	end

	return "No"
end

local function GetUiScale()
	local uiScale = GetCVar("uiScale")
	local minUiScale = E.global.general.minUiScale

	return max(uiScale, minUiScale)
end

local function GetDisplayMode()
	local window, maximize = GetCVar("gxWindow"), GetCVar("gxMaximize")
	local displayMode

	if window == "1" then
		if maximize == "1" then
			displayMode = "Windowed (Fullscreen)"
		else
			displayMode = "Windowed"
		end
	else
		displayMode = "Fullscreen"
	end

	return displayMode
end

local EnglishClassName = {
	["DRUID"] = "Druid",
	["HUNTER"] = "Hunter",
	["MAGE"] = "Mage",
	["PALADIN"] = "Paladin",
	["PRIEST"] = "Priest",
	["ROGUE"] = "Rogue",
	["SHAMAN"] = "Shaman",
	["WARLOCK"] = "Warlock",
	["WARRIOR"] = "Warrior"
}

local function GetResolution()
	return (({GetScreenResolutions()})[GetCurrentResolution()] or GetCVar("gxWindowedResolution"))
end

function E:CreateStatusFrame()
	local function CreateSection(width, height, parent, anchor1, anchorTo, anchor2, yOffset)
		local section = CreateFrame("Frame", nil, parent)
		E:Size(section, width, height)
		E:Point(section, anchor1, anchorTo, anchor2, 0, yOffset)

		section.Header = CreateFrame("Frame", nil, section)
		E:Size(section.Header, 300, 30)
		E:Point(section.Header, "TOP", section)

		section.Header.Text = section.Header:CreateFontString(nil, "ARTWORK", "SystemFont")
		E:Point(section.Header.Text, "TOP")
		E:Point(section.Header.Text, "BOTTOM")
		section.Header.Text:SetJustifyH("CENTER")
		section.Header.Text:SetJustifyV("MIDDLE")
		local font, height, flags = section.Header.Text:GetFont()
		section.Header.Text:SetFont(font, height*1.3, flags)

		section.Header.LeftDivider = section.Header:CreateTexture(nil, "ARTWORK")
		E:Height(section.Header.LeftDivider, 8)
		E:Point(section.Header.LeftDivider, "LEFT", section.Header, "LEFT", 5, 0)
		E:Point(section.Header.LeftDivider, "RIGHT", section.Header.Text, "LEFT", -5, 0)
		section.Header.LeftDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		section.Header.LeftDivider:SetTexCoord(0.81, 0.94, 0.5, 1)

		section.Header.RightDivider = section.Header:CreateTexture(nil, "ARTWORK")
		E:Height(section.Header.RightDivider, 8)
		E:Point(section.Header.RightDivider, "RIGHT", section.Header, "RIGHT", -5, 0)
		E:Point(section.Header.RightDivider, "LEFT", section.Header.Text, "RIGHT", 5, 0)
		section.Header.RightDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		section.Header.RightDivider:SetTexCoord(0.81, 0.94, 0.5, 1)

		return section
	end

	local function CreateContentLines(num, parent, anchorTo)
		local content = CreateFrame("Frame", nil, parent)
		E:Size(content, 240, (num * 20) + ((num - 1) * 5)) --20 height and 5 spacing
		E:Point(content, "TOP", anchorTo, "BOTTOM", 0, -5)

		for i = 1, num do
			local line = CreateFrame("Frame", nil, content)
			E:Size(line, 240, 20)
			line.Text = line:CreateFontString(nil, "ARTWORK", "SystemFont")
			line.Text:SetTextColor(1, 1, 1)
			line.Text:SetAllPoints()
			line.Text:SetJustifyH("LEFT")
			line.Text:SetJustifyV("MIDDLE")
			content["Line"..i] = line

			if i == 1 then
				E:Point(content["Line"..i], "TOP", content, "TOP")
			else
				E:Point(content["Line"..i], "TOP", content["Line"..(i - 1)], "BOTTOM", 0, -5)
			end
		end

		return content
	end

	--Main frame
	local StatusFrame = CreateFrame("Frame", "ElvUIStatusReport", E.UIParent)
	E:Size(StatusFrame, 300, 640)
	E:Point(StatusFrame, "CENTER", E.UIParent, "CENTER")
	StatusFrame:SetFrameStrata("HIGH")
	E:CreateBackdrop(StatusFrame, "Transparent", nil, true)
	StatusFrame:Hide()
	E:CreateCloseButton(StatusFrame)
	StatusFrame:SetClampedToScreen(true)
	StatusFrame:SetMovable(true)
	StatusFrame:EnableMouse(true)
	StatusFrame:RegisterForDrag("LeftButton", "RightButton")
	StatusFrame:SetScript("OnDragStart", function()
		this:StartMoving()
	end)
	StatusFrame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
	end)

	--Title logo
	StatusFrame.TitleLogoFrame = CreateFrame("Frame", nil, StatusFrame)
	E:Size(StatusFrame.TitleLogoFrame, 128, 64)
	E:Point(StatusFrame.TitleLogoFrame, "CENTER", StatusFrame, "TOP", 0, 0)
	StatusFrame.TitleLogoFrame.Texture = StatusFrame.TitleLogoFrame:CreateTexture(nil, "ARTWORK")
	StatusFrame.TitleLogoFrame.Texture:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\logo.tga")
	StatusFrame.TitleLogoFrame.Texture:SetAllPoints()

	--Sections
	StatusFrame.Section1 = CreateSection(300, 150, StatusFrame, "TOP", StatusFrame, "TOP", -30)
	StatusFrame.Section2 = CreateSection(300, 175, StatusFrame, "TOP", StatusFrame.Section1, "BOTTOM", 0)
	StatusFrame.Section3 = CreateSection(300, 220, StatusFrame, "TOP", StatusFrame.Section2, "BOTTOM", 0)
	StatusFrame.Section4 = CreateSection(300, 60, StatusFrame, "TOP", StatusFrame.Section3, "BOTTOM", 0)

	--Section headers
	StatusFrame.Section1.Header.Text:SetText("|cfffe7b2cAddOn Info|r")
	StatusFrame.Section2.Header.Text:SetText("|cfffe7b2cWoW Info|r")
	StatusFrame.Section3.Header.Text:SetText("|cfffe7b2cCharacter Info|r")
	StatusFrame.Section4.Header.Text:SetText("|cfffe7b2cExport To|r")

	--Section content
	StatusFrame.Section1.Content = CreateContentLines(4, StatusFrame.Section1, StatusFrame.Section1.Header)
	StatusFrame.Section2.Content = CreateContentLines(5, StatusFrame.Section2, StatusFrame.Section2.Header)
	StatusFrame.Section3.Content = CreateContentLines(7, StatusFrame.Section3, StatusFrame.Section3.Header)
	StatusFrame.Section4.Content = CreateFrame("Frame", nil, StatusFrame.Section4)
	E:Size(StatusFrame.Section4.Content, 240, 25)
	E:Point(StatusFrame.Section4.Content, "TOP", StatusFrame.Section4.Header, "BOTTOM", 0, 0)

	--Content lines
	StatusFrame.Section1.Content.Line1.Text:SetText(format("Version of ElvUI: |cff4beb2c%s|r", E.version))
	StatusFrame.Section1.Content.Line2.Text:SetText(format("Other AddOns Enabled: |cff4beb2c%s|r", AreOtherAddOnsEnabled()))
	StatusFrame.Section1.Content.Line3.Text:SetText(format("Auto Scale Enabled: |cff4beb2c%s|r", (E.global.general.autoScale == true and "Yes" or "No")))
	StatusFrame.Section1.Content.Line4.Text:SetText(format("UI Scale Is: |cff4beb2c%.4f|r", GetUiScale()))

	StatusFrame.Section2.Content.Line1.Text:SetText(format("Version of WoW: |cff4beb2c%s (build %s)|r", E.wowpatch, E.wowbuild))
	StatusFrame.Section2.Content.Line2.Text:SetText(format("Client Language: |cff4beb2c%s|r", GetLocale()))
	StatusFrame.Section2.Content.Line3.Text:SetText(format("Display Mode: |cff4beb2c%s|r", GetDisplayMode()))
	StatusFrame.Section2.Content.Line4.Text:SetText(format("Resolution: |cff4beb2c%s|r", GetResolution()))
	StatusFrame.Section2.Content.Line5.Text:SetText(format("Using Mac Client: |cff4beb2c%s|r", (E.isMacClient == true and "Yes" or "No")))

	StatusFrame.Section3.Content.Line1.Text:SetText(format("Faction: |cff4beb2c%s|r", E.myfaction))
	StatusFrame.Section3.Content.Line2.Text:SetText(format("Race: |cff4beb2c%s|r", E.myrace))
	StatusFrame.Section3.Content.Line3.Text:SetText(format("Class: |cff4beb2c%s|r", EnglishClassName[E.myclass]))
	StatusFrame.Section3.Content.Line4.Text:SetText(format("Specialization: |cff4beb2c%s|r", select(2, E:GetTalentSpecInfo())))
	StatusFrame.Section3.Content.Line5.Text:SetText(format("Level: |cff4beb2c%s|r", UnitLevel("player")))
	StatusFrame.Section3.Content.Line6.Text:SetText(format("Zone: |cff4beb2c%s|r", GetRealZoneText()))
	StatusFrame.Section3.Content.Line7.Text:SetText(format("Realm: |cff4beb2c%s|r", E.myrealm))

	--Export buttons
	StatusFrame.Section4.Content.Button1 = CreateFrame("Button", nil, StatusFrame.Section4.Content, "UIPanelButtonTemplate")
	E:Size(StatusFrame.Section4.Content.Button1, 100, 25)
	E:Point(StatusFrame.Section4.Content.Button1, "LEFT", StatusFrame.Section4.Content, "LEFT")
	StatusFrame.Section4.Content.Button1:SetText("Forum")
	StatusFrame.Section4.Content.Button1:SetButtonState("DISABLED")
	E:GetModule("Skins"):HandleButton(StatusFrame.Section4.Content.Button1, true)

	StatusFrame.Section4.Content.Button2 = CreateFrame("Button", nil, StatusFrame.Section4.Content, "UIPanelButtonTemplate")
	E:Size(StatusFrame.Section4.Content.Button2, 100, 25)
	E:Point(StatusFrame.Section4.Content.Button2, "RIGHT", StatusFrame.Section4.Content, "RIGHT")
	StatusFrame.Section4.Content.Button2:SetText("Ticket")
	StatusFrame.Section4.Content.Button2:SetButtonState("DISABLED")
	E:GetModule("Skins"):HandleButton(StatusFrame.Section4.Content.Button2, true)

	E.StatusFrame = StatusFrame
end

local function UpdateDynamicValues()
	E.StatusFrame.Section2.Content.Line3.Text:SetText(format("Display Mode: |cff4beb2c%s|r", GetDisplayMode()))
	E.StatusFrame.Section2.Content.Line4.Text:SetText(format("Resolution: |cff4beb2c%s|r", GetResolution()))
	E.StatusFrame.Section3.Content.Line4.Text:SetText(format("Specialization: |cff4beb2c%s|r", select(2, E:GetTalentSpecInfo())))
	E.StatusFrame.Section3.Content.Line5.Text:SetText(format("Level: |cff4beb2c%s|r", UnitLevel("player")))
	E.StatusFrame.Section3.Content.Line6.Text:SetText(format("Zone: |cff4beb2c%s|r", GetRealZoneText()))
end

function E:ShowStatusReport()
	if not self.StatusFrame then
		self:CreateStatusFrame()
	end

	if not self.StatusFrame:IsShown() then
		UpdateDynamicValues()
		self.StatusFrame:Raise() --Set framelevel above everything else
		self.StatusFrame:Show()
	else
		self.StatusFrame:Hide()
	end
end
