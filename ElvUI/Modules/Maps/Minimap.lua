local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:NewModule("Minimap", "AceEvent-3.0");
E.Minimap = M

--Cache global variables
--Lua functions
local _G = _G
local strsub = strsub
--WoW API / Variables
local CreateFrame = CreateFrame
local ToggleCharacter = ToggleCharacter
local ToggleFrame = ToggleFrame
local ToggleAchievementFrame = ToggleAchievementFrame
local ToggleFriendsFrame = ToggleFriendsFrame
local IsAddOnLoaded = IsAddOnLoaded
local ToggleHelpFrame = ToggleHelpFrame
local GetZonePVPInfo = GetZonePVPInfo
local IsShiftKeyDown = IsShiftKeyDown
local ToggleDropDownMenu = ToggleDropDownMenu
local Minimap_OnClick = Minimap_OnClick
local GetMinimapZoneText = GetMinimapZoneText

local menuFrame = CreateFrame("Frame", "MinimapRightClickMenu", E.UIParent, "L_UIDropDownMenuTemplate")
local menuList = {
	{text = CHARACTER_BUTTON,
	func = function() ToggleCharacter("PaperDollFrame") end},
	{text = SPELLBOOK_ABILITIES_BUTTON,
	func = function() ToggleFrame(SpellBookFrame) end},
	{text = TALENTS_BUTTON,
	func = ToggleTalentFrame},
	{text = QUESTLOG_BUTTON,
	func = function() ToggleFrame(QuestLogFrame) end},
	{text = SOCIAL_BUTTON,
	func = function() ToggleFriendsFrame(1) end},
	{text = L["Farm Mode"],
	func = FarmMode},
	{text = BATTLEFIELD_MINIMAP,
	func = ToggleBattlefieldMinimap},
	{text = HELPFRAME_HOME_ISSUE3_HEADER,
	func = function() ToggleCharacter("HonorFrame") end},
	{text = HELP_BUTTON,
	func = ToggleHelpFrame}
}

function GetMinimapShape()
	return "SQUARE"
end

function M:GetLocTextColor()
	local pvpType = GetZonePVPInfo()
	if pvpType == "sanctuary" then
		return 0.035, 0.58, 0.84
	elseif pvpType == "arena" then
		return 0.84, 0.03, 0.03
	elseif pvpType == "friendly" then
		return 0.05, 0.85, 0.03
	elseif pvpType == "hostile" then
		return 0.84, 0.03, 0.03
	elseif pvpType == "contested" then
		return 0.9, 0.85, 0.05
	else
		return 0.84, 0.03, 0.03
	end
end

function M:Minimap_OnMouseUp(btn)
	local position = this:GetPoint()
	if arg1 == "MiddleButton" or (arg1 == "RightButton" and IsShiftKeyDown()) then
		if position then
			L_EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		else
			L_EasyMenu(menuList, menuFrame, "cursor", -160, 0, "MENU", 2)
		end
	else
		Minimap_OnClick(this)
	end
end

function M:Minimap_OnMouseWheel()
	if arg1 > 0 then
		_G.MinimapZoomIn:Click()
	elseif arg1 < 0 then
		_G.MinimapZoomOut:Click()
	end
end

function M:Update_ZoneText()
	if E.db.general.minimap.locationText == "HIDE" or not E.private.general.minimap.enable then return end
	Minimap.location:SetText(strsub(GetMinimapZoneText(),1,46))
	Minimap.location:SetTextColor(self:GetLocTextColor())
	E:FontTemplate(Minimap.location, E.LSM:Fetch("font", E.db.general.minimap.locationFont), E.db.general.minimap.locationFontSize, E.db.general.minimap.locationFontOutline)
end

function M:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UpdateSettings()
end

local isResetting
local function ResetZoom()
	Minimap:SetZoom(0)
	MinimapZoomIn:Enable()
	MinimapZoomOut:Disable()
	isResetting = false
end
local function SetupZoomReset()
	if E.db.general.minimap.resetZoom.enable and not isResetting then
		isResetting = true
		E:Delay(E.db.general.minimap.resetZoom.time, ResetZoom)
	end
end
hooksecurefunc(Minimap, "SetZoom", SetupZoomReset)

function M:UpdateSettings()
	E.MinimapSize = E.private.general.minimap.enable and E.db.general.minimap.size or Minimap:GetWidth() + 10
	E.MinimapWidth = E.MinimapSize
	E.MinimapHeight = E.MinimapSize

	if E.private.general.minimap.enable then
		Minimap:SetScale(E.MinimapSize / 140)
	end

	if LeftMiniPanel and RightMiniPanel then
		if E.db.datatexts.minimapPanels and E.private.general.minimap.enable then
			LeftMiniPanel:Show()
			RightMiniPanel:Show()
		else
			LeftMiniPanel:Hide()
			RightMiniPanel:Hide()
		end
	end

	if BottomMiniPanel then
		if E.db.datatexts.minimapBottom and E.private.general.minimap.enable then
			BottomMiniPanel:Show()
		else
			BottomMiniPanel:Hide()
		end
	end

	if BottomLeftMiniPanel then
		if E.db.datatexts.minimapBottomLeft and E.private.general.minimap.enable then
			BottomLeftMiniPanel:Show()
		else
			BottomLeftMiniPanel:Hide()
		end
	end

	if BottomRightMiniPanel then
		if E.db.datatexts.minimapBottomRight and E.private.general.minimap.enable then
			BottomRightMiniPanel:Show()
		else
			BottomRightMiniPanel:Hide()
		end
	end

	if TopMiniPanel then
		if E.db.datatexts.minimapTop and E.private.general.minimap.enable then
			TopMiniPanel:Show()
		else
			TopMiniPanel:Hide()
		end
	end

	if TopLeftMiniPanel then
		if E.db.datatexts.minimapTopLeft and E.private.general.minimap.enable then
			TopLeftMiniPanel:Show()
		else
			TopLeftMiniPanel:Hide()
		end
	end

	if TopRightMiniPanel then
		if E.db.datatexts.minimapTopRight and E.private.general.minimap.enable then
			TopRightMiniPanel:Show()
		else
			TopRightMiniPanel:Hide()
		end
	end

	if MMHolder then
		E:Width(MMHolder, E.MinimapWidth + E.Border + E.Spacing*3)

		if E.db.datatexts.minimapPanels then
			E:Height(MMHolder, E.MinimapHeight + (LeftMiniPanel and (LeftMiniPanel:GetHeight() + E.Border) or 24) + E.Spacing*3)
		else
			E:Height(MMHolder, E.MinimapHeight + E.Border + E.Spacing*3)
		end
	end

	if Minimap.location then
		E:Width(Minimap.location, E.MinimapSize)

		if E.db.general.minimap.locationText ~= "SHOW" or not E.private.general.minimap.enable then
			Minimap.location:Hide()
		else
			Minimap.location:Show()
		end
	end

	if MinimapMover then
		E:Size(MinimapMover, MMHolder:GetWidth(), MMHolder:GetHeight())
	end

	if GameTimeFrame then
		if E.private.general.minimap.hideCalendar then
			GameTimeFrame:Hide()
		else
			local pos = E.db.general.minimap.icons.calendar.position or "TOPRIGHT"
			local scale = E.db.general.minimap.icons.calendar.scale or 1
			GameTimeFrame:ClearAllPoints()
			E:Point(GameTimeFrame, pos, Minimap, pos, E.db.general.minimap.icons.calendar.xOffset or 0, E.db.general.minimap.icons.calendar.yOffset or 0)
			GameTimeFrame:SetScale(scale)
			GameTimeFrame:Show()
		end
	end

	if MiniMapMailFrame then
		local pos = E.db.general.minimap.icons.mail.position or "TOPRIGHT"
		local scale = E.db.general.minimap.icons.mail.scale or 1
		MiniMapMailFrame:ClearAllPoints()
		E:Point(MiniMapMailFrame, pos, Minimap, pos, E.db.general.minimap.icons.mail.xOffset or 3, E.db.general.minimap.icons.mail.yOffset or 4)
		MiniMapMailFrame:SetScale(scale)
	end

	if MiniMapBattlefieldFrame then
		local pos = E.db.general.minimap.icons.battlefield.position or "BOTTOMRIGHT"
		local scale = E.db.general.minimap.icons.battlefield.scale or 1
		MiniMapBattlefieldFrame:ClearAllPoints()
		E:Point(MiniMapBattlefieldFrame, pos, Minimap, pos, E.db.general.minimap.icons.battlefield.xOffset or 3, E.db.general.minimap.icons.battlefield.yOffset or 0)
		MiniMapBattlefieldFrame:SetScale(scale)
	end

	if MiniMapInstanceDifficulty then
		local pos = E.db.general.minimap.icons.difficulty.position or "TOPLEFT"
		local scale = E.db.general.minimap.icons.difficulty.scale or 1
		local x = E.db.general.minimap.icons.difficulty.xOffset or 0
		local y = E.db.general.minimap.icons.difficulty.yOffset or 0
		MiniMapInstanceDifficulty:ClearAllPoints()
		E:Point(MiniMapInstanceDifficulty, pos, Minimap, pos, x, y)
		MiniMapInstanceDifficulty:SetScale(scale)
	end
end

local function MinimapPostDrag()
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetAllPoints(Minimap)
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetAllPoints(Minimap)
end

function M:Initialize()
	E:SetTemplate(menuFrame, "Transparent", true)

	self:UpdateSettings()

	if not E.private.general.minimap.enable then
		Minimap:SetMaskTexture("Textures\\MinimapMask")
		return
	end

	local mmholder = CreateFrame("Frame", "MMHolder", UIParent)
	E:Point(mmholder, "TOPRIGHT", E.UIParent, "TOPRIGHT", -3, -3)
	E:Size(mmholder, E.MinimapWidth + 29, E.MinimapHeight + 53)
	Minimap:ClearAllPoints()
	E:Point(Minimap, "TOPRIGHT", mmholder, "TOPRIGHT", -E.Border, -E.Border)

	Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
	Minimap.backdrop = CreateFrame("Frame", nil, UIParent)
	E:SetOutside(Minimap.backdrop, Minimap)
	Minimap.backdrop:SetFrameStrata(Minimap:GetFrameStrata())
	Minimap.backdrop:SetFrameLevel(Minimap:GetFrameLevel() - 1)
	E:SetTemplate(Minimap.backdrop, "Default")
	HookScript(Minimap, "OnEnter", function()
		if E.db.general.minimap.locationText ~= "MOUSEOVER" or not E.private.general.minimap.enable then
			return
		end
		this.location:Show()
	end)

	HookScript(Minimap, "OnLeave", function()
		if E.db.general.minimap.locationText ~= "MOUSEOVER" or not E.private.general.minimap.enable then
			return
		end
		this.location:Hide()
	end)

	Minimap.location = Minimap:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(Minimap.location, nil, nil, "OUTLINE")
	E:Point(Minimap.location, "TOP", Minimap, "TOP", 0, -2)
	Minimap.location:SetJustifyH("CENTER")
	Minimap.location:SetJustifyV("MIDDLE")
	if E.db.general.minimap.locationText ~= "SHOW" or not E.private.general.minimap.enable then
		Minimap.location:Hide()
	end

	MinimapBorder:Hide()
	MinimapBorderTop:Hide()

	MinimapToggleButton:Hide()

	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	MinimapZoneTextButton:Hide()

	MiniMapMailBorder:Hide()
	MiniMapMailIcon:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\mail")

	MiniMapBattlefieldBorder:Hide()

	E:CreateMover(MMHolder, "MinimapMover", L["Minimap"], nil, nil, MinimapPostDrag)

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", M.Minimap_OnMouseWheel)
	Minimap:SetScript("OnMouseUp", M.Minimap_OnMouseUp)

	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Update_ZoneText")
	self:RegisterEvent("ZONE_CHANGED", "Update_ZoneText")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "Update_ZoneText")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update_ZoneText")

	local fm = CreateFrame("Minimap", "FarmModeMap", E.UIParent)
	E:Size(fm, E.db.farmSize)
	E:Point(fm, "TOP", E.UIParent, "TOP", 0, -120)
	fm:SetClampedToScreen(true)
	E:CreateBackdrop(fm, "Default")
	fm:EnableMouseWheel(true)
	fm:SetScript("OnMouseWheel", M.Minimap_OnMouseWheel)
	fm:SetScript("OnMouseUp", M.Minimap_OnMouseUp)
	fm:RegisterForDrag("LeftButton", "RightButton")
	fm:SetMovable(true)
	fm:SetScript("OnDragStart", function() this:StartMoving() end)
	fm:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	fm:Hide()

	FarmModeMap:SetScript("OnShow", function()
		if BuffsMover and not E:HasMoverBeenMoved("BuffsMover") then
			BuffsMover:ClearAllPoints()
			E:Point(BuffsMover, "TOPRIGHT", E.UIParent, "TOPRIGHT", -3, -3)
		end

		if DebuffsMover and not E:HasMoverBeenMoved("DebuffsMover") then
			DebuffsMover:ClearAllPoints()
			E:Point(DebuffsMover, "TOPRIGHT", ElvUIPlayerBuffs, "BOTTOMRIGHT", 0, -3)
		end

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetAllPoints(FarmModeMap)
	end)

	FarmModeMap:SetScript("OnHide", function()
		if BuffsMover and not E:HasMoverBeenMoved("BuffsMover") then
			E:ResetMovers(L["Player Buffs"])
		end

		if DebuffsMover and not E:HasMoverBeenMoved("DebuffsMover") then
			E:ResetMovers(L["Player Debuffs"])
		end

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetAllPoints(Minimap)
	end)

	HookScript(UIParent, "OnShow", function()
		if not FarmModeMap.enabled then
			FarmModeMap:Hide()
		end
	end)
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterInitialModule(M:GetName(), InitializeCallback)