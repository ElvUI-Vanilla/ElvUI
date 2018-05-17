local E, L, V, P, G = unpack(ElvUI); -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Cache global variables
--Lua functions
local _G = _G
local type, ipairs, tonumber = type, ipairs, tonumber
local floor = math.floor
--WoW API / Variables
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight
local RESET = RESET

local grid
local selectedValue = "ALL"

E.ConfigModeLayouts = {
	"ALL",
	"GENERAL",
	"SOLO",
	"PARTY",
	"RAID",
	"ACTIONBARS"
}

E.ConfigModeLocalizedStrings = {
	ALL = ALL,
	GENERAL = GENERAL,
	SOLO = SOLO,
	PARTY = PARTY,
	RAID = RAID,
	ACTIONBARS = ACTIONBAR_LABEL
}

function E:Grid_Show()
	if not grid then
		E:Grid_Create()
	elseif grid.boxSize ~= E.db.gridSize then
		grid:Hide()
		E:Grid_Create()
	else
		grid:Show()
	end
end

function E:Grid_Hide()
	if grid then
		grid:Hide()
	end
end

function E:ToggleConfigMode(override, configType)
	if override ~= nil and override ~= "" then E.ConfigurationMode = override end

	if E.ConfigurationMode ~= true then
		if not grid then
			E:Grid_Create()
		elseif grid.boxSize ~= E.db.gridSize then
			grid:Hide()
			E:Grid_Create()
		else
			grid:Show()
		end

		if not ElvUIMoverPopupWindow then
			E:CreateMoverPopup()
		end

		ElvUIMoverPopupWindow:Show()
		if(IsAddOnLoaded("ElvUI_Config")) then
			LibStub("AceConfigDialog-3.0"):Close("ElvUI")
			GameTooltip:Hide()
		end

		E.ConfigurationMode = true
	else
		if ElvUIMoverPopupWindow then
			ElvUIMoverPopupWindow:Hide()
		end

		if grid then
			grid:Hide()
		end

		E.ConfigurationMode = false
	end

	if type(configType) ~= "string" then
		configType = nil
	end

	self:ToggleMovers(E.ConfigurationMode, configType or "ALL")
end

function E:Grid_Create()
	grid = CreateFrame("Frame", "EGrid", UIParent)
	grid.boxSize = E.db.gridSize
	grid:SetAllPoints(E.UIParent)
	grid:Show()

	local size = 1
	local width = E.eyefinity or GetScreenWidth()
	local ratio = width / GetScreenHeight()
	local height = GetScreenHeight() * ratio

	local wStep = width / E.db.gridSize
	local hStep = height / E.db.gridSize

	for i = 0, E.db.gridSize do
		local tx = grid:CreateTexture(nil, "BACKGROUND")
		if i == E.db.gridSize / 2 then
			tx:SetTexture(1, 0, 0)
		else
			tx:SetTexture(0, 0, 0)
		end
		E:Point(tx, "TOPLEFT", grid, "TOPLEFT", i*wStep - (size/2), 0)
		E:Point(tx, "BOTTOMRIGHT", grid, "BOTTOMLEFT", i*wStep + (size/2), 0)
	end
	height = GetScreenHeight()

	do
		local tx = grid:CreateTexture(nil, "BACKGROUND")
		tx:SetTexture(1, 0, 0)
		E:Point(tx, "TOPLEFT", grid, "TOPLEFT", 0, -(height/2) + (size/2))
		E:Point(tx, "BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height/2 + size/2))
	end

	for i = 1, floor((height/2)/hStep) do
		local tx = grid:CreateTexture(nil, "BACKGROUND")
		tx:SetTexture(0, 0, 0)

		E:Point(tx, "TOPLEFT", grid, "TOPLEFT", 0, -(height/2+i*hStep) + (size/2))
		E:Point(tx, "BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height/2+i*hStep + size/2))

		tx = grid:CreateTexture(nil, "BACKGROUND")
		tx:SetTexture(0, 0, 0)

		E:Point(tx, "TOPLEFT", grid, "TOPLEFT", 0, -(height/2-i*hStep) + (size/2))
		E:Point(tx, "BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height/2-i*hStep + size/2))
	end
end

local function ConfigMode_OnClick()
	selectedValue = this.value
	E:ToggleConfigMode(false, this.value)
	UIDropDownMenu_SetSelectedValue(ElvUIMoverPopupWindowDropDown, this.value)
end

local function ConfigMode_Initialize()
	local info = {}
	info.func = ConfigMode_OnClick

	for _, configMode in ipairs(E.ConfigModeLayouts) do
		info.text = E.ConfigModeLocalizedStrings[configMode]
		info.value = configMode
		UIDropDownMenu_AddButton(info)
	end

	UIDropDownMenu_SetSelectedValue(ElvUIMoverPopupWindowDropDown, selectedValue)
end

function E:NudgeMover(nudgeX, nudgeY)
	local mover = ElvUIMoverNudgeWindow.child

	local x, y, point = E:CalculateMoverPoints(mover, nudgeX, nudgeY)

	mover:ClearAllPoints()
	E:Point(mover, mover.positionOverride or point, E.UIParent, mover.positionOverride and "BOTTOMLEFT" or point, x, y)
	E:SaveMoverPosition(mover.name)

	E:UpdateNudgeFrame(mover, x, y)
end

function E:UpdateNudgeFrame(mover, x, y)
	if not(x and y) then
		x, y = E:CalculateMoverPoints(mover)
	end

	x = E:Round(x, 0)
	y = E:Round(y, 0)

	ElvUIMoverNudgeWindow.xOffset:SetText(x)
	ElvUIMoverNudgeWindow.yOffset:SetText(y)
	ElvUIMoverNudgeWindow.xOffset.currentValue = x
	ElvUIMoverNudgeWindow.yOffset.currentValue = y
	ElvUIMoverNudgeWindowHeader.title:SetText(mover.textString)
end

function E:AssignFrameToNudge()
	ElvUIMoverNudgeWindow.child = self
	E:UpdateNudgeFrame(self)
end

function E:CreateMoverPopup()
	local f = CreateFrame("Frame", "ElvUIMoverPopupWindow", UIParent)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetFrameLevel(99)
	f:SetClampedToScreen(true)
	E:Size(f, 360, 170)
	E:SetTemplate(f, "Transparent")
	E:Point(f, "BOTTOM", UIParent, "CENTER", 0, 100)
	f:SetScript("OnHide", function()
		if ElvUIMoverPopupWindowDropDown then
			UIDropDownMenu_SetSelectedValue(ElvUIMoverPopupWindowDropDown, "ALL")
		end
	end)
	f:Hide()

	local S = E:GetModule("Skins")

	local header = CreateFrame("Button", nil, f)
	E:SetTemplate(header, "Default", true)
	E:Size(header, 100, 25)
	E:Point(header, "CENTER", f, "TOP")
	header:SetFrameLevel(header:GetFrameLevel() + 2)
	header:EnableMouse(true)
	header:RegisterForClicks("AnyUp", "AnyDown")
	header:SetScript("OnMouseDown", function() f:StartMoving() end)
	header:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

	local title = header:CreateFontString("OVERLAY")
	E:FontTemplate(title)
	E:Point(title, "CENTER", header, "CENTER")
	title:SetText("ElvUI")

	local desc = f:CreateFontString("ARTWORK")
	desc:SetFontObject("GameFontHighlight")
	desc:SetJustifyV("TOP")
	desc:SetJustifyH("LEFT")
	E:Point(desc, "TOPLEFT", 18, -32)
	E:Point(desc, "BOTTOMRIGHT", -18, 48)
	desc:SetText(L["DESC_MOVERCONFIG"])

	local snapping = CreateFrame("CheckButton", f:GetName().."CheckButton", f, "OptionsCheckButtonTemplate")
	_G[snapping:GetName().."Text"]:SetText(L["Sticky Frames"])

	snapping:SetScript("OnShow", function()
		this:SetChecked(E.db.general.stickyFrames)
	end)

	snapping:SetScript("OnClick", function()
		E.db.general.stickyFrames = this:GetChecked()
	end)

	local lock = CreateFrame("Button", f:GetName().."CloseButton", f, "OptionsButtonTemplate")
	_G[lock:GetName().."Text"]:SetText(L["Lock"])

	lock:SetScript("OnClick", function()
		E:ToggleConfigMode(true)

		if(IsAddOnLoaded("ElvUI_Config")) then
			LibStub("AceConfigDialog-3.0"):Open("ElvUI")
		end

		selectedValue = "ALL"
		UIDropDownMenu_SetSelectedValue(ElvUIMoverPopupWindowDropDown, selectedValue)
	end)

	local align = CreateFrame("EditBox", f:GetName().."EditBox", f, "InputBoxTemplate")
	E:Size(align, 32, 17)
	align:SetAutoFocus(false)
	align:SetScript("OnEscapePressed", function()
		this:SetText(E.db.gridSize)
		this:ClearFocus()
	end)
	align:SetScript("OnEnterPressed", function()
		local text = this:GetText()
		if tonumber(text) then
			if tonumber(text) <= 256 and tonumber(text) >= 4 then
				E.db.gridSize = tonumber(text)
			else
				this:SetText(E.db.gridSize)
			end
		else
			this:SetText(E.db.gridSize)
		end
		E:Grid_Show()
		this:ClearFocus()
	end)
	align:SetScript("OnEditFocusLost", function()
		this:SetText(E.db.gridSize)
	end)
	align:SetScript("OnShow", function()
		this:ClearFocus()
		this:SetText(E.db.gridSize)
	end)

	align.text = align:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	E:Point(align.text, "RIGHT", align, "LEFT", -4, 0)
	align.text:SetText(L["Grid Size:"])

	--position buttons
	E:Point(snapping, "BOTTOMLEFT", 14, 10)
	E:Point(lock, "BOTTOMRIGHT", -14, 14)
	E:Point(align, "TOPRIGHT", lock, "TOPLEFT", -4, -2)

	S:HandleCheckBox(snapping)
	S:HandleButton(lock)
	S:HandleEditBox(align)

	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:SetScript("OnEvent", function()
		if this:IsShown() then
			this:Hide()
			E:Grid_Hide()
			E:ToggleConfigMode(true)
		end
	end)

	local configMode = CreateFrame("Frame", f:GetName().."DropDown", f, "UIDropDownMenuTemplate")
	E:Point(configMode, "BOTTOMRIGHT", lock, "TOPRIGHT", 8, -5)
	S:HandleDropDownBox(configMode, 148)
	configMode.text = configMode:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	E:Point(configMode.text, "RIGHT", configMode.backdrop, "LEFT", -2, 0)
	configMode.text:SetText(L["Config Mode:"])

	UIDropDownMenu_Initialize(configMode, ConfigMode_Initialize)

	local nudgeFrame = CreateFrame("Frame", "ElvUIMoverNudgeWindow", E.UIParent)
	nudgeFrame:SetFrameStrata("DIALOG")
	E:Size(nudgeFrame, 200, 110)
	E:SetTemplate(nudgeFrame, "Transparent")
	E:Point(nudgeFrame, "TOP", ElvUIMoverPopupWindow, "BOTTOM", 0, -15)
	nudgeFrame:SetFrameLevel(100)
	nudgeFrame:Hide()
	nudgeFrame:EnableMouse(true)
	nudgeFrame:SetClampedToScreen(true)
	HookScript(ElvUIMoverPopupWindow, "OnHide", function() ElvUIMoverNudgeWindow:Hide() end)

	header = CreateFrame("Button", "ElvUIMoverNudgeWindowHeader", nudgeFrame)
	E:SetTemplate(header, "Default", true)
	E:Size(header, 100, 25)
	E:Point(header, "CENTER", nudgeFrame, "TOP")
	header:SetFrameLevel(header:GetFrameLevel() + 2)

	title = header:CreateFontString("OVERLAY")
	E:FontTemplate(title)
	E:Point(title, "CENTER", header, "CENTER")
	title:SetText(L["Nudge"])
	header.title = title

	local xOffset = CreateFrame("EditBox", nudgeFrame:GetName().."XEditBox", nudgeFrame, "InputBoxTemplate")
	E:Size(xOffset, 50, 17)
	xOffset:SetAutoFocus(false)
	xOffset.currentValue = 0
	xOffset:SetScript("OnEscapePressed", function()
		this:SetText(E:Round(xOffset.currentValue))
		this:ClearFocus()
	end)
	xOffset:SetScript("OnEnterPressed", function()
		local num = this:GetText()
		if(tonumber(num)) then
			local diff = num - xOffset.currentValue
			xOffset.currentValue = num
			E:NudgeMover(diff)
		end
		this:SetText(E:Round(xOffset.currentValue))
		this:ClearFocus()
	end)
	xOffset:SetScript("OnEditFocusLost", function()
		this:SetText(E:Round(xOffset.currentValue))
	end)
	xOffset:SetScript("OnShow", function()
		this:ClearFocus()
		this:SetText(E:Round(xOffset.currentValue))
	end)

	xOffset.text = xOffset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	E:Point(xOffset.text, "RIGHT", xOffset, "LEFT", -4, 0)
	xOffset.text:SetText("X:")
	E:Point(xOffset, "BOTTOMRIGHT", nudgeFrame, "CENTER", -6, 8)
	nudgeFrame.xOffset = xOffset
	S:HandleEditBox(xOffset)

	local yOffset = CreateFrame("EditBox", nudgeFrame:GetName().."YEditBox", nudgeFrame, "InputBoxTemplate")
	E:Size(yOffset, 50, 17)
	yOffset:SetAutoFocus(false)
	yOffset.currentValue = 0
	yOffset:SetScript("OnEscapePressed", function()
		this:SetText(E:Round(yOffset.currentValue))
		this:ClearFocus()
	end)
	yOffset:SetScript("OnEnterPressed", function()
		local num = this:GetText()
		if(tonumber(num)) then
			local diff = num - yOffset.currentValue
			yOffset.currentValue = num
			E:NudgeMover(nil, diff)
		end
		this:SetText(E:Round(yOffset.currentValue))
		this:ClearFocus()
	end)
	yOffset:SetScript("OnEditFocusLost", function()
		this:SetText(E:Round(yOffset.currentValue))
	end)
	yOffset:SetScript("OnShow", function()
		this:ClearFocus()
		this:SetText(E:Round(yOffset.currentValue))
	end)

	yOffset.text = yOffset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	E:Point(yOffset.text, "RIGHT", yOffset, "LEFT", -4, 0)
	yOffset.text:SetText("Y:")
	E:Point(yOffset, "BOTTOMLEFT", nudgeFrame, "CENTER", 16, 8)
	nudgeFrame.yOffset = yOffset
	S:HandleEditBox(yOffset)

	local resetButton = CreateFrame("Button", nudgeFrame:GetName().."ResetButton", nudgeFrame, "UIPanelButtonTemplate")
	resetButton:SetText(RESET)
	E:Point(resetButton, "TOP", nudgeFrame, "CENTER", 0, 2)
	E:Size(resetButton, 100, 25)
	resetButton:SetScript("OnClick", function()
		if(ElvUIMoverNudgeWindow.child.textString) then
			E:ResetMovers(ElvUIMoverNudgeWindow.child.textString)
			E:UpdateNudgeFrame(ElvUIMoverNudgeWindow.child)
		end
	end)
	S:HandleButton(resetButton)
	-- Up Button
	local upButton = CreateFrame("Button", nudgeFrame:GetName().."PrevButton", nudgeFrame)
	E:Size(upButton, 26)
	E:Point(upButton, "BOTTOMRIGHT", nudgeFrame, "BOTTOM", -6, 4)
	upButton:SetScript("OnClick", function()
		E:NudgeMover(nil, 1)
	end)
	upButton.icon = upButton:CreateTexture(nil, "ARTWORK")
	E:Size(upButton.icon, 13)
	E:Point(upButton.icon, "CENTER", 0, 0)
	upButton.icon:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\SquareButtonTextures.blp]])
	upButton.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)

	S:SquareButton_SetIcon(upButton, "UP")
	S:HandleButton(upButton)
	-- Down Button
	local downButton = CreateFrame("Button", nudgeFrame:GetName().."DownButton", nudgeFrame)
	E:Size(downButton, 26)
	E:Point(downButton, "BOTTOMLEFT", nudgeFrame, "BOTTOM", 6, 4)
	downButton:SetScript("OnClick", function()
		E:NudgeMover(nil, -1)
	end)
	downButton.icon = downButton:CreateTexture(nil, "ARTWORK")
	E:Size(downButton.icon, 13)
	E:Point(downButton.icon, "CENTER", 0, 0)
	downButton.icon:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\SquareButtonTextures.blp]])
	downButton.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)

	S:SquareButton_SetIcon(downButton, "DOWN")
	S:HandleButton(downButton)
	-- Left Button
	local leftButton = CreateFrame("Button", nudgeFrame:GetName().."LeftButton", nudgeFrame)
	E:Size(leftButton, 26)
	E:Point(leftButton, "RIGHT", upButton, "LEFT", -6, 0)
	leftButton:SetScript("OnClick", function()
		E:NudgeMover(-1)
	end)
	leftButton.icon = leftButton:CreateTexture(nil, "ARTWORK")
	E:Size(leftButton.icon, 13)
	E:Point(leftButton.icon, "CENTER", 0, 0)
	leftButton.icon:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\SquareButtonTextures.blp]])
	leftButton.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)

	S:SquareButton_SetIcon(leftButton, "LEFT")
	S:HandleButton(leftButton)
	-- Right Button
	local rightButton = CreateFrame("Button", nudgeFrame:GetName().."RightButton", nudgeFrame)
	E:Size(rightButton, 26)
	E:Point(rightButton, "LEFT", downButton, "RIGHT", 6, 0)
	rightButton:SetScript("OnClick", function()
		E:NudgeMover(1)
	end)
	rightButton.icon = rightButton:CreateTexture(nil, "ARTWORK")
	E:Size(rightButton.icon, 13)
	E:Point(rightButton.icon, "CENTER", 0, 0)
	rightButton.icon:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\SquareButtonTextures.blp]])
	rightButton.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)

	S:SquareButton_SetIcon(rightButton, "RIGHT")
	S:HandleButton(rightButton)
end