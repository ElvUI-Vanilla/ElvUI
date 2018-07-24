--[[-----------------------------------------------------------------------------
Button Widget (Modified to change text color on SetDisabled method)
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "Button-ElvUI", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, unpack = pairs, unpack

-- WoW APIs
local _G = _G
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent
local IsShiftKeyDown = IsShiftKeyDown
-- GLOBALS: GameTooltip, ElvUI

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local dragdropButton
local function lockTooltip()
	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:SetText(" ")
	GameTooltip:Show()
end
local function dragdrop_OnMouseDown()
	if this.obj.dragOnMouseDown then
		dragdropButton.mouseDownFrame = this
		dragdropButton:SetText(this.obj.value or "Unknown")
		dragdropButton:SetWidth(this:GetWidth())
		dragdropButton:SetHeight(this:SetHeight())
		this.obj.dragOnMouseDown(this, arg1)
	end
end
local function dragdrop_OnMouseUp()
	if this.obj.dragOnMouseUp then
		this:SetAlpha(1)
		GameTooltip:Hide()
		dragdropButton:Hide()
		if dragdropButton.enteredFrame and dragdropButton.enteredFrame ~= this and dragdropButton.enteredFrame:IsMouseOver() then
			this.obj.dragOnMouseUp(this, arg1)
			this.obj.ActivateMultiControl(this.obj, arg1)
		end
		dragdropButton.enteredFrame = nil
		dragdropButton.mouseDownFrame = nil
	end
end
local function dragdrop_OnLeave()
	if this.obj.dragOnLeave then
		if dragdropButton.mouseDownFrame then
			lockTooltip()
		end
		if this == dragdropButton.mouseDownFrame then
			this:SetAlpha(0)
			dragdropButton:Show()
			this.obj.dragOnLeave(this)
		end
	end
end
local function dragdrop_OnEnter()
	if this.obj.dragOnEnter and dragdropButton:IsShown() then
		dragdropButton.enteredFrame = this
		lockTooltip()
		this.obj.dragOnEnter(this)
	end
end
local function dragdrop_OnClick()
	local button = arg1
	if this.obj.dragOnClick and button == "RightButton" then
		this.obj.dragOnClick(this, button)
		this.obj.ActivateMultiControl(this.obj, button)
	elseif this.obj.stateSwitchOnClick and (button == "LeftButton") and IsShiftKeyDown() then
		this.obj.stateSwitchOnClick(this, button)
		this.obj.ActivateMultiControl(this.obj, button)
	end
end

local function Button_OnClick()
	AceGUI:ClearFocus()
	PlaySound("igMainMenuOption")
	this.obj:Fire("OnClick", 2, arg1)
end

local function Control_OnEnter()
	this.obj:Fire("OnEnter")
end

local function Control_OnLeave()
	this.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetAutoWidth(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
		self.text:SetText(text)
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetAutoWidth"] = function(self, autoWidth)
		self.autoWidth = autoWidth
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
			self.text:SetTextColor(0.4, 0.4, 0.4)
		else
			self.frame:Enable()
			self.text:SetTextColor(1, 0.82, 0)
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate")
	frame:Hide()
	frame:EnableMouse(true)
	frame:SetScript("OnClick", Button_OnClick)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)

	-- dragdrop
	if not dragdropButton then
		dragdropButton = CreateFrame("Button", "ElvUIAceGUI30DragDropButton", UIParent, "UIPanelButtonTemplate")
		dragdropButton:SetFrameStrata("TOOLTIP")
		dragdropButton:SetFrameLevel(5)
		dragdropButton:SetPoint('BOTTOM', GameTooltip, "BOTTOM", 0, 10)
		dragdropButton:Hide()
		ElvUI[1]:GetModule('Skins'):HandleButton(dragdropButton)
	end
	HookScript(frame, "OnClick", dragdrop_OnClick)
	HookScript(frame, "OnEnter", dragdrop_OnEnter)
	HookScript(frame, "OnLeave", dragdrop_OnLeave)
	HookScript(frame, "OnMouseUp", dragdrop_OnMouseUp)
	HookScript(frame, "OnMouseDown", dragdrop_OnMouseDown)

	local text = frame:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 15, -1)
	text:SetPoint("BOTTOMRIGHT", -15, 1)
	text:SetJustifyV("MIDDLE")

	local widget = {
		text  = text,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
