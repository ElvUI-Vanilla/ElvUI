local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local LSM = LibStub("LibSharedMedia-3.0");

--Cache global variables
--Lua functions
local _G = _G
local unpack, type, select, getmetatable = unpack, type, select, getmetatable
--WoW API / Variables
local CreateFrame = CreateFrame
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

--Preload shit..
E.mult = 1
local backdropr, backdropg, backdropb, backdropa, borderr, borderg, borderb = 0, 0, 0, 1, 0, 0, 0

local function GetTemplate(t, isUnitFrameElement)
	backdropa = 1
	if t == "ClassColor" then
		if CUSTOM_CLASS_COLORS then
			borderr, borderg, borderb = CUSTOM_CLASS_COLORS[E.myclass].r, CUSTOM_CLASS_COLORS[E.myclass].g, CUSTOM_CLASS_COLORS[E.myclass].b
		else
			borderr, borderg, borderb = RAID_CLASS_COLORS[E.myclass].r, RAID_CLASS_COLORS[E.myclass].g, RAID_CLASS_COLORS[E.myclass].b
		end

		if t ~= "Transparent" then
			backdropr, backdropg, backdropb = unpack(E["media"].backdropcolor)
		else
			backdropr, backdropg, backdropb, backdropa = unpack(E["media"].backdropfadecolor)
		end
	elseif t == "Transparent" then
		if isUnitFrameElement then
			borderr, borderg, borderb = unpack(E["media"].unitframeBorderColor)
		else
			borderr, borderg, borderb = unpack(E["media"].bordercolor)
		end
		backdropr, backdropg, backdropb, backdropa = unpack(E["media"].backdropfadecolor)
	else
		if isUnitFrameElement then
			borderr, borderg, borderb = unpack(E["media"].unitframeBorderColor)
		else
			borderr, borderg, borderb = unpack(E["media"].bordercolor)
		end
		backdropr, backdropg, backdropb = unpack(E["media"].backdropcolor)
	end
end

function E:Size(frame, width, height)
	assert(width)
	frame:SetWidth(E:Scale(width))
	frame:SetHeight(E:Scale(height or width))
end

function E:Width(frame, width)
	assert(width)
	frame:SetWidth(E:Scale(width))
end

function E:Height(frame, height)
	assert(height)
	frame:SetHeight(E:Scale(height))
end

function E:Point(obj, arg1, arg2, arg3, arg4, arg5)
	if arg2 == nil then
		arg2 = obj:GetParent()
	end

	if type(arg1)=="number" then arg1 = E:Scale(arg1) end
	if type(arg2)=="number" then arg2 = E:Scale(arg2) end
	if type(arg3)=="number" then arg3 = E:Scale(arg3) end
	if type(arg4)=="number" then arg4 = E:Scale(arg4) end
	if type(arg5)=="number" then arg5 = E:Scale(arg5) end

	obj:SetPoint(arg1, arg2, arg3, arg4, arg5)
end

function E:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or E.Border
	yOffset = yOffset or E.Border
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", -xOffset, yOffset)
	obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", xOffset, -yOffset)
end

function E:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or E.Border
	yOffset = yOffset or E.Border
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", xOffset, -yOffset)
	obj:SetPoint("BOTTOMRIGHT", anchor2 or anchor, "BOTTOMRIGHT", -xOffset, yOffset)
end

function E:SetTemplate(f, t, glossTex, ignoreUpdates, forcePixelMode, isUnitFrameElement)
	GetTemplate(t, isUnitFrameElement)

	if t then
		f.template = t
	end

	if glossTex then
		f.glossTex = glossTex
	end

	if ignoreUpdates then
		f.ignoreUpdates = ignoreUpdates
	end

	if forcePixelMode then
		f.forcePixelMode = forcePixelMode
	end

	local bgFile = E.media.blankTex
	if glossTex then
		bgFile = E.media.glossTex
	end

	if isUnitFrameElement then
		f.isUnitFrameElement = isUnitFrameElement
	end

	if t ~= "NoBackdrop" then
		if E.private.general.pixelPerfect or f.forcePixelMode then
			f:SetBackdrop({
				bgFile = bgFile,
				edgeFile = E["media"].blankTex,
				tile = false, tileSize = 0, edgeSize = E.mult,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
		else
			f:SetBackdrop({
				bgFile = bgFile,
				edgeFile = E["media"].blankTex,
				tile = false, tileSize = 0, edgeSize = E.mult,
				insets = {left = -E.mult, right = -E.mult, top = -E.mult, bottom = -E.mult}
			})
		end

		if not f.oborder and not f.iborder and not E.private.general.pixelPerfect and not f.forcePixelMode then
			local border = CreateFrame("Frame", nil, f)
			E:SetInside(border, f, E.mult, E.mult)
			border:SetBackdrop({
				edgeFile = E["media"].blankTex,
				edgeSize = E.mult,
				insets = {left = E.mult, right = E.mult, top = E.mult, bottom = E.mult}
			})
			border:SetBackdropBorderColor(0, 0, 0, 1)
			f.iborder = border

			if f.oborder then return end
			border = CreateFrame("Frame", nil, f)
			E:SetOutside(border, f, E.mult, E.mult)
			border:SetFrameLevel(f:GetFrameLevel() + 1)
			border:SetBackdrop({
				edgeFile = E["media"].blankTex,
				edgeSize = E.mult,
				insets = {left = E.mult, right = E.mult, top = E.mult, bottom = E.mult}
			})
			border:SetBackdropBorderColor(0, 0, 0, 1)
			f.oborder = border
		end
	else
		f:SetBackdrop(nil)
	end

	f:SetBackdropColor(backdropr, backdropg, backdropb, backdropa)
	f:SetBackdropBorderColor(borderr, borderg, borderb)

	if not f.ignoreUpdates then
		if f.isUnitFrameElement then
			E["unitFrameElements"][f] = true
		else
			E["frames"][f] = true
		end
	end
end

function E:CreateBackdrop(f, t, tex, ignoreUpdates, forcePixelMode, isUnitFrameElement)
	if not t then t = "Default" end

	local parent = f.IsObjectType and f:IsObjectType("Texture") and f:GetParent() or f

	local b = CreateFrame("Frame", nil, parent)
	if f.forcePixelMode or forcePixelMode then
		E:SetOutside(b, nil, E.mult, E.mult)
	else
		E:SetOutside(b)
	end
	E:SetTemplate(b, t, tex, ignoreUpdates, forcePixelMode, isUnitFrameElement)

	local frameLevel = parent.GetFrameLevel and parent:GetFrameLevel()
	local frameLevelMinusOne = frameLevel and (frameLevel - 1)
	if frameLevelMinusOne and (frameLevelMinusOne >= 0) then
		b:SetFrameLevel(frameLevelMinusOne)
	else
		b:SetFrameLevel(0)
	end

	f.backdrop = b
end

function E:CreateShadow(f)
	if f.shadow then return end

	borderr, borderg, borderb = 0, 0, 0
	backdropr, backdropg, backdropb = 0, 0, 0

	local shadow = CreateFrame("Frame", nil, f)
	shadow:SetFrameLevel(1)
	shadow:SetFrameStrata(f:GetFrameStrata())
	E:SetOutside(shadow, f, 3, 3)
	shadow:SetBackdrop({edgeFile = LSM:Fetch("border", "ElvUI GlowBorder"), edgeSize = E:Scale(3)})
	shadow:SetBackdropColor(backdropr, backdropg, backdropb, 0)
	shadow:SetBackdropBorderColor(borderr, borderg, borderb, 0.9)
	f.shadow = shadow
end

function E:Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(E.HiddenFrame)
	else
		object.Show = object.Hide
	end

	object:Hide()
end

function E:StripTextures(object, kill, alpha)
	if object:IsObjectType("Texture") then
		if kill then
			E:Kill(object)
		elseif alpha then
			object:SetAlpha(0)
		else
			object:SetTexture(nil)
		end
	else
		if object.GetNumRegions then
			for i = 1, object:GetNumRegions() do
				local region = select(i, object:GetRegions())
				if region and region.IsObjectType and region:IsObjectType("Texture") then
					if kill then
						E:Kill(region)
					elseif alpha then
						region:SetAlpha(0)
					else
						region:SetTexture(nil)
					end
				end
			end
		end
	end
end

function E:FontTemplate(fs, font, fontSize, fontStyle)
	fs.font = font
	fs.fontSize = fontSize
	fs.fontStyle = fontStyle

	font = font or LSM:Fetch("font", E.db["general"].font)
	fontSize = fontSize or E.db.general.fontSize

	if fontStyle == "OUTLINE" and (E.db.general.font == "Homespun") then
		if fontSize > 10 and not fs.fontSize then
			fontStyle = "MONOCHROMEOUTLINE"
			fontSize = 10
		end
	end

	fs:SetFont(font, fontSize, fontStyle)
	if fontStyle and (fontStyle ~= "NONE") then
		fs:SetShadowColor(0, 0, 0, 0.2)
	else
		fs:SetShadowColor(0, 0, 0, 1)
	end
	fs:SetShadowOffset((E.mult or 1), -(E.mult or 1))

	E["texts"][fs] = true
end

function E:StyleButton(button, noHover, noPushed, noChecked)
	if button.SetHighlightTexture and not button.hover and not noHover then
		local hover = button:CreateTexture()
		hover:SetTexture(1, 1, 1, 0.3)
		E:SetInside(hover)
		button.hover = hover
		button:SetHighlightTexture(hover)
	end

	if button.SetPushedTexture and not button.pushed and not noPushed then
		local pushed = button:CreateTexture()
		pushed:SetTexture(0.9, 0.8, 0.1, 0.3)
		E:SetInside(pushed)
		button.pushed = pushed
		button:SetPushedTexture(pushed)
	end

	if button.SetCheckedTexture and not button.checked and not noChecked then
		local checked = button:CreateTexture()
		checked:SetTexture(1, 1, 1)
		E:SetInside(checked)
		checked:SetAlpha(0.3)
		button.checked = checked
		button:SetCheckedTexture(checked)
	end

	local cooldown = button:GetName() and _G[button:GetName().."Cooldown"]
	if cooldown then
		cooldown:ClearAllPoints()
		E:SetInside(cooldown)
	end
end

function E:CreateCloseButton(frame, size, offset, texture, backdrop)
	size = (size or 16)
	offset = (offset or -6)
	texture = (texture or "Interface\\AddOns\\ElvUI\\media\\textures\\close.tga")

	local CloseButton = CreateFrame("Button", nil, frame)
	E:Size(CloseButton, size)
	E:Point(CloseButton, "TOPRIGHT", offset, offset)
	if backdrop then
		E:CreateBackdrop(CloseButton, "Default", true)
	end

	CloseButton.Texture = CloseButton:CreateTexture(nil, "OVERLAY")
	CloseButton.Texture:SetAllPoints()
	CloseButton.Texture:SetTexture(texture)

	CloseButton:SetScript("OnClick", function()
		this:GetParent():Hide()
	end)
	CloseButton:SetScript("OnEnter", function()
		this.Texture:SetVertexColor(unpack(E["media"].rgbvaluecolor))
	end)
	CloseButton:SetScript("OnLeave", function()
		this.Texture:SetVertexColor(1, 1, 1)
	end)

	frame.CloseButton = CloseButton
end

--[[local function addapi(object)
	local mt = getmetatable(object).__index
	if not object.Size then mt.Size = Size end
	if not object.Point then mt.Point = Point end
	if not object.SetOutside then mt.SetOutside = SetOutside end
	if not object.SetInside then mt.SetInside = SetInside end
	if not object.SetTemplate then mt.SetTemplate = SetTemplate end
	if not object.CreateBackdrop then mt.CreateBackdrop = CreateBackdrop end
	if not object.CreateShadow then mt.CreateShadow = CreateShadow end
	if not object.Kill then mt.Kill = Kill end
	if not object.Width then mt.Width = Width end
	if not object.Height then mt.Height = Height end
	if not object.FontTemplate then mt.FontTemplate = FontTemplate end
	if not object.StripTextures then mt.StripTextures = StripTextures end
	if not object.StyleButton then mt.StyleButton = StyleButton end
	if not object.CreateCloseButton then mt.CreateCloseButton = CreateCloseButton end
end

local handled = {["Frame"] = true}
local object = CreateFrame("Frame")
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())

object = EnumerateFrames()
while object do
	if not handled[object:GetObjectType()] then
		addapi(object)
		handled[object:GetObjectType()] = true
	end

	object = EnumerateFrames(object)
end--]]