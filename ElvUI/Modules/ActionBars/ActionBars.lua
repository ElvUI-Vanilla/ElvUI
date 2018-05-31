local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:NewModule("ActionBars", "AceHook-3.0", "AceEvent-3.0");
local LSM = LibStub("LibSharedMedia-3.0");

--Cache global variables
--Lua functions
local _G = _G
local gsub, split = string.gsub, string.split
local ceil = math.ceil
local mod = math.mod
--WoW API / Variables
local CreateFrame = CreateFrame
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

E.ActionBars = AB

AB["handledBars"] = {}
AB["handledButtons"] = {}
AB["barDefaults"] = {
	["bar1"] = {
		["name"] = "Action",
		["position"] = "BOTTOM,ElvUIParent,BOTTOM,0,4",
	},
	["bar2"] = {
		["name"] = "MultiBarBottomRight",
		["position"] = "BOTTOM,ElvUI_Bar1,TOP,0,2"
	},
	["bar3"] = {
		["name"] = "MultiBarRight",
		["position"] = "LEFT,ElvUI_Bar1,RIGHT,4,0"
	},
	["bar4"] = {
		["name"] = "MultiBarLeft",
		["position"] = "RIGHT,ElvUIParent,RIGHT,-4,0"
	},
	["bar5"] = {
		["name"] = "MultiBarBottomLeft",
		["position"] = "RIGHT,ElvUI_Bar1,LEFT,-4,0"
	}
}

function AB:PositionAndSizeBar(barName)
	local buttonSpacing = E:Scale(self.db[barName].buttonspacing)
	local backdropSpacing = E:Scale((self.db[barName].backdropSpacing or self.db[barName].buttonspacing))
	local buttonsPerRow = self.db[barName].buttonsPerRow
	local numButtons = self.db[barName].buttons
	local size = E:Scale(self.db[barName].buttonsize)
	local point = self.db[barName].point
	local numColumns = ceil(numButtons / buttonsPerRow)
	local widthMult = self.db[barName].widthMult
	local heightMult = self.db[barName].heightMult
	local bar = self["handledBars"][barName]

	bar.db = self.db[barName]

	if numButtons < buttonsPerRow then
		buttonsPerRow = numButtons
	end

	if numColumns < 1 then
		numColumns = 1
	end

	if self.db[barName].backdrop then
		bar.backdrop:Show()
	else
		bar.backdrop:Hide()

		widthMult = 1
		heightMult = 1
	end

	local barWidth = (size * (buttonsPerRow * widthMult)) + ((buttonSpacing * (buttonsPerRow - 1)) * widthMult) + (buttonSpacing * (widthMult-1)) + ((self.db[barName].backdrop and (E.Border + backdropSpacing) or E.Spacing)*2)
	local barHeight = (size * (numColumns * heightMult)) + ((buttonSpacing * (numColumns - 1)) * heightMult) + (buttonSpacing * (heightMult-1)) + ((self.db[barName].backdrop and (E.Border + backdropSpacing) or E.Spacing)*2)
	E:Size(bar, barWidth, barHeight)

	bar.mouseover = self.db[barName].mouseover

	local horizontalGrowth, verticalGrowth
	if point == "TOPLEFT" or point == "TOPRIGHT" then
		verticalGrowth = "DOWN"
	else
		verticalGrowth = "UP"
	end

	if point == "BOTTOMLEFT" or point == "TOPLEFT" then
		horizontalGrowth = "RIGHT"
	else
		horizontalGrowth = "LEFT"
	end

	if self.db[barName].mouseover then
		bar:SetAlpha(0)
	else
		bar:SetAlpha(self.db[barName].alpha)
	end

	local button, lastButton, lastColumnButton, x, y
	local firstButtonSpacing = (self.db[barName].backdrop and (E.Border + backdropSpacing) or E.Spacing)
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = bar.buttons[i]
		lastButton = bar.buttons[i-1]
		lastColumnButton = bar.buttons[i-buttonsPerRow]
		button:ClearAllPoints()

		button:SetParent(bar)

		E:Size(button, size)
		ActionButton_ShowGrid(button)

		if i == 1 then
			if point == "BOTTOMLEFT" then
				x, y = firstButtonSpacing, firstButtonSpacing
			elseif point == "TOPRIGHT" then
				x, y = -firstButtonSpacing, -firstButtonSpacing
			elseif point == "TOPLEFT" then
				x, y = firstButtonSpacing, -firstButtonSpacing
			else
				x, y = -firstButtonSpacing, firstButtonSpacing
			end
			E:Point(button, point, bar, point, x, y)
		elseif mod((i - 1), buttonsPerRow) == 0 then
			x = 0
			y = -buttonSpacing
			local buttonPoint, anchorPoint = "TOP", "BOTTOM"
			if verticalGrowth == "UP" then
				y = buttonSpacing
				buttonPoint = "BOTTOM"
				anchorPoint = "TOP"
			end
			E:Point(button, buttonPoint, lastColumnButton, anchorPoint, x, y)
		else
			x = buttonSpacing
			y = 0
			local buttonPoint, anchorPoint = "LEFT", "RIGHT"
			if horizontalGrowth == "LEFT" then
				x = -buttonSpacing
				buttonPoint = "RIGHT"
				anchorPoint = "LEFT"
			end
			E:Point(button, buttonPoint, lastButton, anchorPoint, x, y)
		end

		if i > numButtons then
			button:SetScale(0.000001)
			button:SetAlpha(0)
		else
			button:SetScale(1)
			button:SetAlpha(1)
		end

		if self.db[barName].mouseover then
			button:SetAlpha(0)
		else
			button:SetAlpha(self.db[barName].alpha)
		end
	end

	if self.db[barName].enabled or not bar.initialized then
		if not self.db[barName].mouseover then
			bar:SetAlpha(self.db[barName].alpha)
		end

		bar:Show()

		if not bar.initialized then
			bar.initialized = true
			self:PositionAndSizeBar(barName)
			return
		end
	else
		bar:Hide()
	end

	E:SetMoverSnapOffset("ElvAB_"..bar.id, bar.db.buttonspacing / 2)
end

function AB:CreateBar(id)
	local bar = CreateFrame("Button", "ElvUI_Bar"..id, E.UIParent)
	local point, anchor, attachTo, x, y = split(",", self["barDefaults"]["bar"..id].position)
	E:Point(bar, point, anchor, attachTo, x, y)
	bar.id = id
	E:CreateBackdrop(bar, "Default")
	bar:SetFrameStrata("LOW")
	local offset = E.Spacing
	E:Point(bar.backdrop, "TOPLEFT", bar, "TOPLEFT", offset, -offset)
	E:Point(bar.backdrop, "BOTTOMRIGHT", bar, "BOTTOMRIGHT", -offset, offset)
	bar.buttons = {}
	self:HookScript(bar, "OnEnter", "Bar_OnEnter")
	self:HookScript(bar, "OnLeave", "Bar_OnLeave")

	if id == 1 then
		bar.actionButtons = {}
		bar.bonusButtons = {}

		local button
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			button = _G["ActionButton"..i]
			button:SetParent(bar)
			bar.actionButtons[i] = button
			self:HookScript(button, "OnEnter", "Button_OnEnter")
			self:HookScript(button, "OnLeave", "Button_OnLeave")

			button = _G["BonusActionButton"..i]
			button:SetParent(bar)
			bar.bonusButtons[i] = button
			self:HookScript(button, "OnEnter", "Button_OnEnter")
			self:HookScript(button, "OnLeave", "Button_OnLeave")
		end

		bar.buttons = bar.actionButtons

		bar:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
		bar:SetScript("OnEvent", function()
			if GetBonusBarOffset() > 0 then
				bar.lastBonusBar = GetBonusBarOffset()

				for i = 1, NUM_ACTIONBAR_BUTTONS do
					bar.buttons[i]:SetParent(E.HiddenFrame)
				end

				bar.buttons = bar.bonusButtons
			else
				for i = 1, NUM_ACTIONBAR_BUTTONS do
					bar.buttons[i]:SetParent(E.HiddenFrame)
				end

				bar.buttons = bar.actionButtons
			end

			AB:PositionAndSizeBar("bar1")
		end)
	else
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			local button = _G[self["barDefaults"]["bar"..id].name.."Button"..i]
			bar.buttons[i] = button

			self:HookScript(button, "OnEnter", "Button_OnEnter")
			self:HookScript(button, "OnLeave", "Button_OnLeave")
		end
	end

	self["handledBars"]["bar"..id] = bar
	self:PositionAndSizeBar("bar"..id)
	E:CreateMover(bar, "ElvAB_"..id, L["Bar "]..id, nil, nil, nil,"ALL,ACTIONBARS")

	return bar
end

function AB:UpdateButtonSettings()
	for button, _ in pairs(self["handledButtons"]) do
		if button then
			self:StyleButton(button, button.noBackdrop)
		else
			self["handledButtons"][button] = nil
		end
	end

	for i = 1, 5 do
		self:PositionAndSizeBar("bar"..i)
	end

	self:PositionAndSizeBarPet()
	self:PositionAndSizeBarShapeShift()
end

function AB:StyleButton(button, noBackdrop)
	local name = button:GetName()
	local icon = _G[name.."Icon"]
	local count = _G[name.."Count"]
	local flash = _G[name.."Flash"]
	local hotkey = _G[name.."HotKey"]
	local border = _G[name.."Border"]
	local macroName = _G[name.."Name"]
	local normal = button:GetNormalTexture()
	local buttonCooldown = _G[name.."Cooldown"]
	local color = self.db.fontColor

	if flash then flash:SetTexture(nil) end
	if normal then normal:SetTexture(nil) normal:Hide() normal:SetAlpha(0) end
	if border then E:Kill(border) end

	if not button.noBackdrop then
		button.noBackdrop = noBackdrop
	end

	if count then
		count:ClearAllPoints()
		E:Point(count, "BOTTOMRIGHT", 0, 2)
		E:FontTemplate(count, LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
		count:SetTextColor(color.r, color.g, color.b)
	end

	if macroName then
		if self.db.macrotext then
			macroName:Show()
			E:FontTemplate(macroName, LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
			macroName:ClearAllPoints()
			E:Point(macroName, "BOTTOM", 2, 2)
			macroName:SetJustifyH("CENTER")
		else
			macroName:Hide()
		end
	end

	if not button.noBackdrop and not button.backdrop then
		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints()
	end

	if icon then
		icon:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(icon)
	end

	if self.db.hotkeytext then
		E:FontTemplate(hotkey, LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
		hotkey:SetTextColor(color.r, color.g, color.b)
	end

	self:FixKeybindText(button)
	E:StyleButton(button)

	if(not self.handledButtons[button]) then
		E:RegisterCooldown(buttonCooldown)

		self.handledButtons[button] = true
	end
end

function AB:Bar_OnEnter()
	if this.mouseover then
		UIFrameFadeIn(this, 0.2, this:GetAlpha(), this.db.alpha)
	end
end

function AB:Bar_OnLeave()
	if this.mouseover then
		UIFrameFadeOut(this, 0.2, this:GetAlpha(), 0)
	end
end

function AB:Button_OnEnter()
	local bar = (this:GetParent() == BonusActionBarFrame or this:GetParent() == MainMenuBarArtFrame) and ElvUI_Bar1 or this:GetParent()
	if bar.mouseover then
		UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), bar.db.alpha)
	end
end

function AB:Button_OnLeave()
	local bar = (this:GetParent() == BonusActionBarFrame or this:GetParent() == MainMenuBarArtFrame) and ElvUI_Bar1 or this:GetParent()
	if bar.mouseover then
		UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
	end
end

function AB:DisableBlizzard()
	MainMenuBar:EnableMouse(false)
	PetActionBarFrame:EnableMouse(false)
	ShapeshiftBarFrame:EnableMouse(false)

	local elements = {
		MainMenuBar,
		MainMenuBarArtFrame,
		MainMenuExpBar,
		BonusActionBarFrame,
		PetActionBarFrame,
		ReputationWatchBar,
		ShapeshiftBarFrame,
		ShapeshiftBarLeft,
		ShapeshiftBarMiddle,
		ShapeshiftBarRight,
	}
	for _, element in pairs(elements) do
		if element:GetObjectType() == "Frame" then
			element:UnregisterAllEvents()

			if element == MainMenuBarArtFrame then
				element:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
			end
		end

		if element ~= MainMenuBar then
			element:Hide()
		end
		element:SetAlpha(0)
	end
	elements = nil

	local uiManagedFrames = {
		"MultiBarLeft",
		"MultiBarRight",
		"MultiBarBottomLeft",
		"MultiBarBottomRight",
		"ShapeshiftBarFrame",
		"PETACTIONBAR_YPOS",
	}
	for _, frame in pairs(uiManagedFrames) do
		UIPARENT_MANAGED_FRAME_POSITIONS[frame] = nil
	end
	uiManagedFrames = nil
end

function AB:FixKeybindText(button)
	local hotkey = _G[button:GetName().."HotKey"]
	local text = hotkey:GetText()

	if text then
		text = gsub(text, "SHIFT%-", L["KEY_SHIFT"])
		text = gsub(text, "ALT%-", L["KEY_ALT"])
		text = gsub(text, "CTRL%-", L["KEY_CTRL"])
		text = gsub(text, "BUTTON", L["KEY_MOUSEBUTTON"])
		text = gsub(text, "MOUSEWHEELUP", L["KEY_MOUSEWHEELUP"])
		text = gsub(text, "MOUSEWHEELDOWN", L["KEY_MOUSEWHEELDOWN"])
		text = gsub(text, "NUMPAD", L["KEY_NUMPAD"])
		text = gsub(text, "PAGEUP", L["KEY_PAGEUP"])
		text = gsub(text, "PAGEDOWN", L["KEY_PAGEDOWN"])
		text = gsub(text, "SPACE", L["KEY_SPACE"])
		text = gsub(text, "INSERT", L["KEY_INSERT"])
		text = gsub(text, "HOME", L["KEY_HOME"])
		text = gsub(text, "DELETE", L["KEY_DELETE"])
		text = gsub(text, "NMULTIPLY", "*")
		text = gsub(text, "NMINUS", "N-")
		text = gsub(text, "NPLUS", "N+")

		if hotkey:GetText() == _G["RANGE_INDICATOR"] then
			hotkey:SetText("")
		else
			hotkey:SetText(text)
		end
	end

	if self.db.hotkeytext == true then
		hotkey:Show()
	else
		hotkey:Hide()
	end

	hotkey:ClearAllPoints()
	E:Point(hotkey, "TOPRIGHT", 0, -3)
end

function AB:ActionButton_Update()
	self:StyleButton(this)
end

function AB:ActionButton_GetPagedID(button)
	if button.isBonus and CURRENT_ACTIONBAR_PAGE == 1 then
		local offset = GetBonusBarOffset()
		if offset == 0 and ElvUI_Bar1 and ElvUI_Bar1.lastBonusBar then
			offset = ElvUI_Bar1.lastBonusBar
		end
		return button:GetID() + ((NUM_ACTIONBAR_PAGES + offset - 1) * NUM_ACTIONBAR_BUTTONS)
	end

	local parentName = button:GetParent():GetName()
	if parentName == "ElvUI_Bar5" then
		return button:GetID() + ((BOTTOMLEFT_ACTIONBAR_PAGE - 1) * NUM_ACTIONBAR_BUTTONS)
	elseif parentName == "ElvUI_Bar2" then
		return button:GetID() + ((BOTTOMRIGHT_ACTIONBAR_PAGE - 1) * NUM_ACTIONBAR_BUTTONS)
	elseif parentName == "ElvUI_Bar4" then
		return button:GetID() + ((LEFT_ACTIONBAR_PAGE - 1) * NUM_ACTIONBAR_BUTTONS)
	elseif parentName == "ElvUI_Bar3" then
		return button:GetID() + ((RIGHT_ACTIONBAR_PAGE - 1) * NUM_ACTIONBAR_BUTTONS)
	else
		return button:GetID() + ((CURRENT_ACTIONBAR_PAGE - 1) * NUM_ACTIONBAR_BUTTONS)
	end
end

local function IsInShapeshiftForm()
	for i = 1, GetNumShapeshiftForms() do
		_, _, active = GetShapeshiftFormInfo(i)
		if active ~= nil then return true end
	end
	return false
end

function AB:UNIT_PORTRAIT_UPDATE()
	if arg1 == "player" and E.myclass == "DRUID" then
		local inForm = IsInShapeshiftForm()
		if inForm then
			BonusActionBarFrame:Show()
		else
			BonusActionBarFrame:Hide()
		end
	end
end

function AB:Initialize()
	self.db = E.db.actionbar

	if E.private.actionbar.enable ~= true then return end

	self:DisableBlizzard()

	self:SetupMicroBar()

	for i = 1, 5 do
		self:CreateBar(i)
	end

	self:CreateBarPet()
	self:CreateBarShapeShift()

	self:UpdateButtonSettings()
	self:LoadKeyBinder()

	self:SecureHook("ActionButton_Update")
	self:RawHook("ActionButton_GetPagedID")
	self:SecureHook("PetActionBar_Update", "UpdatePet")
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")

	if E.myclass == "WARRIOR" or (E.myclass == "DRUID" and IsInShapeshiftForm()) then
		BonusActionBarFrame:Show()
	end
end

local function InitializeCallback()
	AB:Initialize()
end

E:RegisterModule(AB:GetName(), InitializeCallback)