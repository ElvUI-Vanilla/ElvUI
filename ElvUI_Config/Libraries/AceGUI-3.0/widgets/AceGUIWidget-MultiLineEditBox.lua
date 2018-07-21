local Type, Version = "MultiLineEditBox", 28
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs
local format = string.format

-- WoW APIs
local GetCursorInfo, GetSpellName, ClearCursor = GetCursorInfo, GetSpellName, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: ACCEPT, ChatFontNormal

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

if not AceGUIMultiLineEditBoxInsertLink then
	-- upgradeable hook
end

function _G.AceGUIMultiLineEditBoxInsertLink(text)
	for i = 1, AceGUI:GetWidgetCount(Type) do
		local editbox = _G[format("MultiLineEditBox%uEdit",i)]
		if editbox and editbox:IsVisible() and editbox.hasfocus then
			editbox:Insert(text)
			return true
		end
	end
end


local function Layout(self)
	self:SetHeight(self.numlines * 14 + (self.disablebutton and 19 or 41) + self.labelHeight)

	if self.labelHeight == 0 then
		self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
	else
		self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
	end

	if self.disablebutton then
		self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
		self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
	else
		self.scrollBar:SetPoint("BOTTOM", self.button, "TOP", 0, 18)
		self.scrollBG:SetPoint("BOTTOMLEFT", self.button, "TOPLEFT")
	end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function OnClick()                                                     -- Button
	local self = this.obj
	self.editBox:ClearFocus()
	if not self:Fire("OnEnterPressed", self.editBox:GetText()) then
		self.button:Disable()
	end
end

local function OnCursorChanged()                      -- EditBox
	local self, y = this.obj.scrollFrame, -arg2
	local offset = self:GetVerticalScroll()
	if y < offset then
		self:SetVerticalScroll(y)
	else
		y = y + arg4 - self:GetHeight()
		if y > offset then
			self:SetVerticalScroll(y)
		end
	end
end

local function OnEditFocusLost()                                             -- EditBox
	this.hasfocus = nil
	this:HighlightText(0, 0)
	this.obj:Fire("OnEditFocusLost")
end

local function OnEnter()                                                     -- EditBox / ScrollFrame
	local self = this.obj
	if not self.entered then
		self.entered = true
		self:Fire("OnEnter")
	end
end

local function OnLeave()                                                     -- EditBox / ScrollFrame
	local self = this.obj
	if self.entered then
		self.entered = nil
		self:Fire("OnLeave")
	end
end

local function OnMouseUp()                                                   -- ScrollFrame
	local self = this.obj.editBox
	self:SetFocus()
--	EditBoxSetCursorPosition(self, self:GetNumLetters())
end

local function OnReceiveDrag()                                               -- EditBox / ScrollFrame
	if not GetCursorInfo then print("TODO GetCursorInfo") return end	-- TODO

	local type, id, info = GetCursorInfo()
	if type == "spell" then
		local name, rank = GetSpellName(id, info)
		if rank ~= "" then
			name = name.."("..rank..")"
		end
		info = name
	elseif type ~= "item" then
		return
	end
	ClearCursor()
	local self = this.obj
	local editBox = self.editBox
	if not this.hasfocus then
		this.hasfocus = true
		editBox:SetFocus()
--		EditBoxSetCursorPosition(editBox, editBox:GetNumLetters())
	end
	editBox:Insert(info)
	self.button:Enable()
end

local function OnSizeChanged()                                -- ScrollFrame
	this.obj.editBox:SetWidth(this.obj.editBox:GetWidth())
end

local function OnTextChanged()                                               -- EditBox
	local self = this.obj
	local value = self.editBox:GetText()
	if not self.lastText or value ~= self.lastText then
		self:Fire("OnTextChanged", value)
		self.lastText = nil
		self.button:Enable()
	else
		self.button:Disable()
		self.lastText = value
	end
end

local function OnTextSet()                                                   -- EditBox
	this:HighlightText(0, 0)
--	EditBoxSetCursorPosition(this, this:GetNumLetters())
--	EditBoxSetCursorPosition(this, 0)
	this.obj.button:Disable()
end

local function OnVerticalScroll()                                    -- ScrollFrame
	local editBox = this.obj.editBox
	editBox:SetHitRectInsets(0, 0, arg1, editBox:GetHeight() - arg1 - this:GetHeight())
end

local function OnShowFocus()
	this.obj.editBox:SetFocus()
	this:SetScript("OnShow", nil)
end

local function OnEditFocusGained()
	this.hasfocus = true
	AceGUI:SetFocus(this.obj)
	this.obj:Fire("OnEditFocusGained")
end

local function OnEscapePressed()
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.editBox:SetText("")
		self:SetDisabled(false)
		self:SetWidth(200)
		self:DisableButton(false)
		self:SetNumLines()
		self.entered = nil
		self:SetMaxLetters(0)
	end,

	["OnRelease"] = function(self)
		self:ClearFocus()
	end,

	["SetDisabled"] = function(self, disabled)
		local editBox = self.editBox
		if disabled then
			editBox:ClearFocus()
			editBox:EnableMouse(false)
			editBox:SetTextColor(0.5, 0.5, 0.5)
			self.label:SetTextColor(0.5, 0.5, 0.5)
			self.scrollFrame:EnableMouse(false)
			self.button:Disable()
		else
			editBox:EnableMouse(true)
			editBox:SetTextColor(1, 1, 1)
			self.label:SetTextColor(1, 0.82, 0)
			self.scrollFrame:EnableMouse(true)
		end
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			if self.labelHeight ~= 10 then
				self.labelHeight = 10
				self.label:Show()
			end
		elseif self.labelHeight ~= 0 then
			self.labelHeight = 0
			self.label:Hide()
		end
		Layout(self)
	end,

	["SetNumLines"] = function(self, value)
		if not value or value < 4 then
			value = 4
		end
		self.numlines = value
		Layout(self)
	end,

	["SetText"] = function(self, text)
		self.lastText = text
		self.editBox:SetText(text)
	end,

	["GetText"] = function(self)
		return self.editBox:GetText()
	end,

	["SetMaxLetters"] = function (self, num)
		self.editBox:SetMaxLetters(num or 0)
	end,

	["DisableButton"] = function(self, disabled)
		self.disablebutton = disabled
		if disabled then
			self.button:Hide()
		else
			self.button:Show()
		end
		Layout(self)
	end,

	["ClearFocus"] = function(self)
		self.editBox:ClearFocus()
		self.frame:SetScript("OnShow", nil)
	end,

	["SetFocus"] = function(self)
		self.editBox:SetFocus()
		if not self.frame:IsShown() then
			self.frame:SetScript("OnShow", OnShowFocus)
		end
	end,

	["HighlightText"] = function(self, from, to)
		self.editBox:HighlightText(from, to)
	end,

	["GetCursorPosition"] = function(self)
		--return EditBoxGetCursorPosition(self.editBox)
	end,

	["SetCursorPosition"] = function(self, pos)
		--return EditBoxSetCursorPosition(self.editBox, pos)
	end,

	["OnWidthSet"] = function(self, width)
		self.scrollFrame:SetWidth(width)
	end,

	["OnHeightSet"] = function(self, height)
		self.scrollFrame:SetHeight(height)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local widgetNum = AceGUI:GetNextWidgetNum(Type)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
	label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
	label:SetJustifyH("LEFT")
	label:SetText(ACCEPT)
	label:SetHeight(10)

	local button = CreateFrame("Button", format("%s%dButton", Type, widgetNum), frame, "UIPanelButtonTemplate")
	button:SetPoint("BOTTOMLEFT", 0, 4)
	button:SetHeight(22)
	button:SetWidth(label:GetStringWidth() + 24)
	button:SetText(ACCEPT)
	button:SetScript("OnClick", OnClick)
	button:Disable()

	local text = button:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
	text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
	text:SetJustifyV("MIDDLE")

	local scrollBG = CreateFrame("Frame", nil, frame)
	scrollBG:SetBackdrop(backdrop)
	scrollBG:SetBackdropColor(0, 0, 0)
	scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

	local scrollFrame = CreateFrame("ScrollFrame", format("%s%dScrollFrame", Type, widgetNum), frame, "UIPanelScrollFrameTemplate")

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
	scrollBar:SetPoint("BOTTOM", button, "TOP", 0, 18)
	scrollBar:SetPoint("RIGHT", frame, "RIGHT")

	scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
	scrollBG:SetPoint("BOTTOMLEFT", button, "TOPLEFT")

	scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
	scrollFrame:SetScript("OnEnter", OnEnter)
	scrollFrame:SetScript("OnLeave", OnLeave)
	scrollFrame:SetScript("OnMouseUp", OnMouseUp)
	scrollFrame:SetScript("OnReceiveDrag", OnReceiveDrag)
	scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
	HookScript(scrollFrame, "OnVerticalScroll", OnVerticalScroll)

	local editBox = CreateFrame("EditBox", format("%s%dEdit", Type, widgetNum), scrollFrame)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetMultiLine(true)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetScript("OnCursorChanged", OnCursorChanged)
	editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
	editBox:SetScript("OnEnter", OnEnter)
	editBox:SetScript("OnEscapePressed", OnEscapePressed)
	editBox:SetScript("OnLeave", OnLeave)
	editBox:SetScript("OnMouseDown", OnReceiveDrag)
	editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
	editBox:SetScript("OnTextChanged", OnTextChanged)
	editBox:SetScript("OnTextSet", OnTextSet)
	editBox:SetScript("OnEditFocusGained", OnEditFocusGained)


	scrollFrame:SetScrollChild(editBox)
	editBox:SetAllPoints()

	local widget = {
		button      = button,
		editBox     = editBox,
		frame       = frame,
		label       = label,
		labelHeight = 10,
		numlines    = 4,
		scrollBar   = scrollBar,
		scrollBG    = scrollBG,
		scrollFrame = scrollFrame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	button.obj, editBox.obj, scrollFrame.obj = widget, widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
