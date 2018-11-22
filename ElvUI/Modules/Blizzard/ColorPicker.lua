--[[
	Credit to Jaslm, most of this code is his from the addon ColorPickerPlus
]]
local E, L, DF = unpack(ElvUI)
local B = E:GetModule("Blizzard")
local S = E:GetModule("Skins")

local collectgarbage = collectgarbage
local tonumber = tonumber
local floor = math.floor
local format, strsub = string.format, strsub
local getn = table.getn

local CreateFrame = CreateFrame
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CLASS, DEFAULTS = CLASS, DEFAULTS

local colorBuffer = {}
local editingText

local function UpdateAlphaText()
	local a = OpacitySliderFrame:GetValue()
	a = (1 - a) * 100
	a = floor(a +.05)
	ColorPPBoxA:SetText(format("%d", a))
end

local function UpdateAlpha()
	local a = this:GetNumber()
	if a > 100 then
		a = 100
		ColorPPBoxA:SetText(format("%d", a))
	end
	a = 1 - (a / 100)
	editingText = true
	OpacitySliderFrame:SetValue(a)
	editingText = nil
end

local function UpdateColorTexts(r, g, b)
	if not r then r, g, b = ColorPickerFrame:GetColorRGB() end
	r = r * 255
	g = g * 255
	b = b * 255
	ColorPPBoxR:SetText(format("%d", r))
	ColorPPBoxG:SetText(format("%d", g))
	ColorPPBoxB:SetText(format("%d", b))
	ColorPPBoxH:SetText(format("%.2x%.2x%.2x", r, g, b))
end

local function UpdateColor()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local id = this:GetID()

	if id == 1 then
		r = format("%d", this:GetNumber())
		if not r then r = 0 end
		r = r / 255
	elseif id == 2 then
		g = format("%d", this:GetNumber())
		if not g then g = 0 end
		g = g / 255
	elseif id == 3 then
		b = format("%d", this:GetNumber())
		if not b then b = 0 end
		b = b / 255
	elseif id == 4 then
		-- hex values
		if this:GetNumLetters() == 6 then
			local rgb = this:GetText()
			r, g, b = tonumber(strsub(rgb, 0, 2), 16), tonumber(strsub(rgb, 3, 4), 16), tonumber(strsub(rgb, 5, 6), 16)
			if not r then r = 0 else r = r / 255 end
			if not g then g = 0 else g = g / 255 end
			if not b then b = 0 else b = b / 255 end
		else
			return
		end
	end

	-- This takes care of updating the hex entry when changing rgb fields and vice versa
	UpdateColorTexts(r, g, b)

	editingText = true
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorSwatch:SetTexture(r, g, b)
	editingText = nil
end

local function HandleUpdateLimiter()
	this.timeSinceUpdate = (this.timeSinceUpdate or 0) + arg1
	if this.timeSinceUpdate > 0.15 then
		this.allowUpdate = true
	else
		this.allowUpdate = false
	end
end

function B:EnhanceColorPicker()
	if IsAddOnLoaded("ColorPickerPlus") then return end

	--Skin the default frame, move default buttons into place
	ColorPickerFrame:SetClampedToScreen(true)
	E:SetTemplate(ColorPickerFrame, "Transparent")

	ColorPickerFrameHeader:SetTexture("")
	ColorPickerFrameHeader:ClearAllPoints()
	ColorPickerFrameHeader:SetPoint("TOP", ColorPickerFrame, 0, 0)

	S:HandleButton(ColorPickerCancelButton)
	ColorPickerCancelButton:ClearAllPoints()
	E:Point(ColorPickerCancelButton, "BOTTOMRIGHT", ColorPickerFrame, "BOTTOMRIGHT", -6, 6)
	E:Point(ColorPickerCancelButton, "BOTTOMLEFT", ColorPickerFrame, "BOTTOM", 0, 6)

	S:HandleButton(ColorPickerOkayButton)
	ColorPickerOkayButton:ClearAllPoints()
	E:Point(ColorPickerOkayButton, "BOTTOMLEFT", ColorPickerFrame,"BOTTOMLEFT", 6, 6)
	E:Point(ColorPickerOkayButton, "RIGHT", ColorPickerCancelButton,"LEFT", -4, 0)

	S:HandleSliderFrame(OpacitySliderFrame)

	if OpacitySliderFrame:GetThumbTexture() then
		OpacitySliderFrame:SetThumbTexture(E.media.normTex)
		OpacitySliderFrame:GetThumbTexture():SetVertexColor(unpack(E.media.rgbvaluecolor))
		E:Size(OpacitySliderFrame:GetThumbTexture(), 10)
	end

	HookScript(ColorPickerFrame, "OnShow", function()
		-- get color that will be replaced
		local r, g, b = ColorPickerFrame:GetColorRGB()
		ColorPPOldColorSwatch:SetTexture(r, g, b)

			-- show/hide the alpha box
		if ColorPickerFrame.hasOpacity then
			ColorPPBoxA:Show()
			ColorPPBoxLabelA:Show()
			ColorPPBoxH:SetScript("OnTabPressed", function() ColorPPBoxA:SetFocus() end)
			UpdateAlphaText()
			this:SetWidth(405)
		else
			ColorPPBoxA:Hide()
			ColorPPBoxLabelA:Hide()
			ColorPPBoxH:SetScript("OnTabPressed", function() ColorPPBoxR:SetFocus() end)
			this:SetWidth(345)
		end

		--Set OnUpdate script to handle update limiter
		this:SetScript("OnUpdate", HandleUpdateLimiter)
	end)

	hooksecurefunc(ColorPickerFrame, "SetFrameLevel", function(self, level)
	    for _, child in ipairs({self:GetChildren()}) do
	        child:SetFrameLevel(level + 1)
	    end
	end)

	--Memory Fix, Colorpicker will call the this.func() 100x per second, causing fps/memory issues,
	--We overwrite the OnColorSelect script and set a limit on how often we allow a call to this.func
	ColorPickerFrame:SetScript("OnColorSelect", function()
		ColorSwatch:SetTexture(arg1, arg2, arg3)
		if not editingText then
			UpdateColorTexts(arg1, arg2, arg3)
		end
		if this.allowUpdate then
			this.func()
			this.timeSinceUpdate = 0
		end
	end)

	HookScript(ColorPickerOkayButton, "OnClick", function()
		collectgarbage() --Couldn't hurt to do this, this button usually executes a lot of code.
	end)

	HookScript(OpacitySliderFrame, "OnValueChanged", function()
		if not editingText then
			UpdateAlphaText()
		end
	end)

	-- make the Color Picker dialog a bit taller, to make room for edit boxes
	E:Height(ColorPickerFrame, ColorPickerFrame:GetHeight() + 40)

	-- move the Color Swatch
	ColorSwatch:ClearAllPoints()
	E:Point(ColorSwatch, "TOPLEFT", ColorPickerFrame, "TOPLEFT", 215, -45)

	-- add Color Swatch for original color
	local t = ColorPickerFrame:CreateTexture("ColorPPOldColorSwatch")
	local w, h = ColorSwatch:GetWidth(), ColorSwatch:GetHeight()
	E:Size(t, w * 0.75, h * 0.75)
	t:SetTexture(0, 0, 0)
	-- OldColorSwatch to appear beneath ColorSwatch
	t:SetDrawLayer("BORDER")
	E:Point(t, "BOTTOMLEFT", "ColorSwatch", "TOPRIGHT", -(w / 2), -(h / 3))

	-- add Color Swatch for the copied color
	t = ColorPickerFrame:CreateTexture("ColorPPCopyColorSwatch")
	E:Size(t, w, h)
	t:SetTexture(0, 0, 0)
	t:Hide()

	-- add copy button to the ColorPickerFrame
	local b = CreateFrame("Button", "ColorPPCopy", ColorPickerFrame, "UIPanelButtonTemplate")
	S:HandleButton(b)
	b:SetText(L["Copy"])
	b:SetWidth(60)
	b:SetHeight(22)
	b:SetPoint("TOPLEFT", "ColorSwatch", "BOTTOMLEFT", 0, -5)

	-- copy color into buffer on button click
	b:SetScript("OnClick", function()
		-- copy current dialog colors into buffer
		colorBuffer.r, colorBuffer.g, colorBuffer.b = ColorPickerFrame:GetColorRGB()

		-- enable Paste button and display copied color into swatch
		ColorPPPaste:Enable()
		ColorPPCopyColorSwatch:SetTexture(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		ColorPPCopyColorSwatch:Show()

		if ColorPickerFrame.hasOpacity then
			colorBuffer.a = OpacitySliderFrame:GetValue()
		else
			colorBuffer.a = nil
		end
	end)

	--class color button
	b = CreateFrame("Button", "ColorPPClass", ColorPickerFrame, "UIPanelButtonTemplate")
	b:SetText(CLASS)
	S:HandleButton(b)
	E:Width(b, 80)
	E:Height(b, 22)
	E:Point(b, "TOP", "ColorPPCopy", "BOTTOMRIGHT", 0, -7)

	b:SetScript("OnClick", function()
		local color = E.myclass == "PRIEST" and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass])
		ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
		ColorSwatch:SetTexture(color.r, color.g, color.b)
		if ColorPickerFrame.hasOpacity then
			OpacitySliderFrame:SetValue(0)
		end
	end)

	-- add paste button to the ColorPickerFrame
	b = CreateFrame("Button", "ColorPPPaste", ColorPickerFrame, "UIPanelButtonTemplate")
	b:SetText(L["Paste"])
	S:HandleButton(b)
	E:Width(b, 60)
	E:Height(b, 22)
	E:Point(b, "TOPLEFT", "ColorPPCopy", "TOPRIGHT", 2, 0)
	b:Disable() -- enable when something has been copied

	-- paste color on button click, updating frame components
	b:SetScript("OnClick", function()
		ColorPickerFrame:SetColorRGB(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		ColorSwatch:SetTexture(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		if ColorPickerFrame.hasOpacity then
			if colorBuffer.a then --color copied had an alpha value
				OpacitySliderFrame:SetValue(colorBuffer.a)
			end
		end
	end)

	-- add defaults button to the ColorPickerFrame
	b = CreateFrame("Button", "ColorPPDefault", ColorPickerFrame, "UIPanelButtonTemplate")
	b:SetText(DEFAULTS)
	S:HandleButton(b)
	E:Width(b, 80)
	E:Height(b, 22)
	E:Point(b, "TOPLEFT", "ColorPPClass", "BOTTOMLEFT", 0, -7)
	b:Disable() -- enable when something has been copied
	b:SetScript("OnHide", function()
		this.colors = nil
	end)
	b:SetScript("OnShow", function()
		if this.colors then
			this:Enable()
		else
			this:Disable()
		end
	end)

	-- paste color on button click, updating frame components
	b:SetScript("OnClick", function()
		local colorBuffer = this.colors
		ColorPickerFrame:SetColorRGB(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		ColorSwatch:SetTexture(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		if ColorPickerFrame.hasOpacity then
			if colorBuffer.a then
				OpacitySliderFrame:SetValue(colorBuffer.a)
			end
		end
	end)

	-- position Color Swatch for copy color
	E:Point(ColorPPCopyColorSwatch, "BOTTOM", "ColorPPPaste", "TOP", 0, 10)

	-- move the Opacity Slider Frame to align with bottom of Copy ColorSwatch
	OpacitySliderFrame:ClearAllPoints()
	E:Point(OpacitySliderFrame, "BOTTOM", "ColorPPDefault", "BOTTOM", 0, 0)
	E:Point(OpacitySliderFrame, "RIGHT", "ColorPickerFrame", "RIGHT", -35, 18)

	-- set up edit box frames and interior label and text areas
	local boxes = { "R", "G", "B", "H", "A" }
	for i = 1, getn(boxes) do

		local rgb = boxes[i]
		local box = CreateFrame("EditBox", "ColorPPBox"..rgb, ColorPickerFrame, "InputBoxTemplate")
		S:HandleEditBox(box)
		box:SetID(i)
		box:SetFrameStrata("DIALOG")
		box:SetAutoFocus(false)
		box:SetTextInsets(0, 17, 0, 0)
		box:SetJustifyH("RIGHT")
		E:Height(box, 24)

		if i == 4 then
			-- Hex entry box
			box:SetMaxLetters(6)
			E:Width(box, 56)
			box:SetNumeric(false)
		else
			box:SetMaxLetters(3)
			E:Width(box, 40)
			box:SetNumeric(true)
		end
		box:SetPoint("TOP", "ColorPickerWheel", "BOTTOM", 0, -15)

		-- label
		local label = box:CreateFontString("ColorPPBoxLabel"..rgb, "ARTWORK", "GameFontNormalSmall")
		label:SetTextColor(1, 1, 1)
		E:Point(label, "RIGHT", "ColorPPBox"..rgb, "LEFT", -5, 0)
		if i == 4 then
			label:SetText("#")
		else
			label:SetText(rgb)
		end

		-- set up scripts to handle event appropriately
		if i == 5 then
			box:SetScript("OnEscapePressed", function() this:ClearFocus() UpdateAlphaText() end)
			box:SetScript("OnEnterPressed", function() this:ClearFocus() UpdateAlphaText() end)
			box:SetScript("OnTextChanged", UpdateAlpha)
		else
			box:SetScript("OnEscapePressed", function() this:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnEnterPressed", function() this:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnTextChanged", UpdateColor)
		end

		box:SetScript("OnEditFocusGained", function() EditBoxSetCursorPosition(this, 0) this:HighlightText() end)
		box:SetScript("OnEditFocusLost", function()	this:HighlightText(0, 0) end)
		box:SetScript("OnTextSet", function() this:ClearFocus() end)
		box:Show()
	end

	-- finish up with placement
	E:Point(ColorPPBoxA, "RIGHT", "OpacitySliderFrame", "RIGHT", 10, 0)
	E:Point(ColorPPBoxH, "RIGHT", "ColorPPDefault", "RIGHT", -10, 0)
	E:Point(ColorPPBoxB, "RIGHT", "ColorPPDefault", "LEFT", -40, 0)
	E:Point(ColorPPBoxG, "RIGHT", "ColorPPBoxB", "LEFT", -25, 0)
	E:Point(ColorPPBoxR, "RIGHT", "ColorPPBoxG", "LEFT", -25, 0)

	-- define the order of tab cursor movement
	ColorPPBoxR:SetScript("OnTabPressed", function() ColorPPBoxG:SetFocus() end)
	ColorPPBoxG:SetScript("OnTabPressed", function() ColorPPBoxB:SetFocus() end)
	ColorPPBoxB:SetScript("OnTabPressed", function() ColorPPBoxH:SetFocus() end)
	ColorPPBoxA:SetScript("OnTabPressed", function() ColorPPBoxR:SetFocus() end)

	-- make the color picker movable.
	local mover = CreateFrame("Frame", nil, ColorPickerFrame)
	mover:SetPoint("TOPLEFT", ColorPickerFrame, "TOP", -60, 0)
	mover:SetPoint("BOTTOMRIGHT", ColorPickerFrame, "TOP", 60, -15)
	mover:EnableMouse(true)
	mover:SetScript("OnMouseDown", function() ColorPickerFrame:StartMoving() end)
	mover:SetScript("OnMouseUp", function() ColorPickerFrame:StopMovingOrSizing() end)
	ColorPickerFrame:SetUserPlaced(true)
	ColorPickerFrame:EnableKeyboard(false)
end