local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

--Cache global variables
--Lua functions
local unpack, tonumber = unpack, tonumber
local abs, min = abs, math.min
--WoW API / Variables
local CreateFrame = CreateFrame
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitReaction = UnitReaction
--local UnitCanAttack = UnitCanAttack

local ns = oUF
local ElvUF = ns.oUF

local INVERT_ANCHORPOINT = {
	TOPLEFT = "BOTTOMRIGHT",
	LEFT = "RIGHT",
	BOTTOMLEFT = "TOPRIGHT",
	RIGHT = "LEFT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOMRIGHT = "TOPLEFT",
	CENTER = "CENTER",
	TOP = "BOTTOM",
	BOTTOM = "TOP",
}

function UF:Construct_Castbar(frame, moverName)
	local castbar = CreateFrame("StatusBar", nil, frame)
	castbar:SetFrameLevel(frame.RaisedElementParent:GetFrameLevel() + 30) --Make it appear above everything else
	self["statusbars"][castbar] = true
	castbar.CustomDelayText = self.CustomCastDelayText
	castbar.CustomTimeText = self.CustomTimeText
	castbar.PostCastStart = self.PostCastStart
	castbar.PostChannelStart = self.PostCastStart
	castbar:SetClampedToScreen(true)
	E:CreateBackdrop(castbar, "Default", nil, nil, self.thinBorders, true)

	castbar.Time = castbar:CreateFontString(nil, "OVERLAY")
	self:Configure_FontString(castbar.Time)
	castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", -4, 0)
	castbar.Time:SetTextColor(0.84, 0.75, 0.65)
	castbar.Time:SetJustifyH("RIGHT")

	castbar.Text = castbar:CreateFontString(nil, "OVERLAY")
	self:Configure_FontString(castbar.Text)
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", 4, 0)
	castbar.Text:SetTextColor(0.84, 0.75, 0.65)
	castbar.Text:SetJustifyH("LEFT")

	castbar.Spark = castbar:CreateTexture(nil, "OVERLAY")
	castbar.Spark:SetBlendMode("ADD")
	castbar.Spark:SetVertexColor(1, 1, 1)

	castbar.bg = castbar:CreateTexture(nil, "BORDER")
	castbar.bg:Hide()

	local button = CreateFrame("Frame", nil, castbar)
	local holder = CreateFrame("Frame", nil, castbar)
	E:SetTemplate(button, "Default", nil, nil, self.thinBorders, true)

	castbar.Holder = holder
	--these are placeholder so the mover can be created.. it will be changed.
	castbar.Holder:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -(frame.BORDER - frame.SPACING))
	castbar:SetPoint("BOTTOMLEFT", castbar.Holder, "BOTTOMLEFT", frame.BORDER, frame.BORDER)
	button:SetPoint("RIGHT", castbar, "LEFT", -E.Spacing*3, 0)

	if moverName then
		E:CreateMover(castbar.Holder, frame:GetName().."CastbarMover", moverName, nil, -6, nil, "ALL,SOLO")
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	local offset = frame.BORDER --use frame.BORDER since it may be different from E.Border due to forced thin borders
	E:SetInside(icon, nil, offset, offset)
	icon:SetTexCoord(unpack(E.TexCoords))
	icon.bg = button

	--Set to castbar.Icon
	castbar.ButtonIcon = icon

	return castbar
end

function UF:Configure_Castbar(frame)
	if not frame.VARIABLES_SET then return end
	local castbar = frame.Castbar
	local db = frame.db
	E:Width(castbar, db.castbar.width - ((frame.BORDER+frame.SPACING)*2))
	E:Height(castbar, db.castbar.height - ((frame.BORDER+frame.SPACING)*2))
	E:Width(castbar.Holder, db.castbar.width)
	E:Height(castbar.Holder, db.castbar.height)
	if castbar.Holder:GetScript("OnSizeChanged") then
		castbar.Holder:GetScript("OnSizeChanged")(castbar.Holder)
	end

	--Icon
	if db.castbar.icon then
		castbar.Icon = castbar.ButtonIcon
		if not db.castbar.iconAttached then
			E:Size(castbar.Icon.bg, db.castbar.iconSize)
		else
			if db.castbar.insideInfoPanel and frame.USE_INFO_PANEL then
				E:Size(castbar.Icon.bg, db.infoPanel.height - frame.SPACING*2)
			else
				E:Size(castbar.Icon.bg, db.castbar.height-frame.SPACING*2)
			end

			E:Width(castbar, db.castbar.width - castbar.Icon.bg:GetWidth() - (frame.BORDER + frame.SPACING*5))
		end

		castbar.Icon.bg:Show()
	else
		castbar.ButtonIcon.bg:Hide()
		castbar.Icon = nil
	end

	if db.castbar.spark then
		castbar.Spark:Show()
	else
		castbar.Spark:Hide()
	end

	castbar:ClearAllPoints()
	if db.castbar.insideInfoPanel and frame.USE_INFO_PANEL then
		if not db.castbar.iconAttached then
			E:SetInside(castbar, frame.InfoPanel, 0, 0)
		else
			local iconWidth = db.castbar.icon and (castbar.Icon.bg:GetWidth() - frame.BORDER) or 0
			if frame.ORIENTATION == "RIGHT" then
				castbar:SetPoint("TOPLEFT", frame.InfoPanel, "TOPLEFT")
				castbar:SetPoint("BOTTOMRIGHT", frame.InfoPanel, "BOTTOMRIGHT", -iconWidth - frame.SPACING*3, 0)
			else
				castbar:SetPoint("TOPLEFT", frame.InfoPanel, "TOPLEFT",  iconWidth + frame.SPACING*3, 0)
				castbar:SetPoint("BOTTOMRIGHT", frame.InfoPanel, "BOTTOMRIGHT")
			end
		end

		if castbar.Holder.mover then
			E:DisableMover(castbar.Holder.mover:GetName())
		end
	else
		local isMoved = E:HasMoverBeenMoved(frame:GetName().."CastbarMover") or not castbar.Holder.mover
		if not isMoved then
			castbar.Holder.mover:ClearAllPoints()
		end

		castbar:ClearAllPoints()
		if frame.ORIENTATION ~= "RIGHT"  then
			E:Point(castbar, "BOTTOMRIGHT", castbar.Holder, "BOTTOMRIGHT", -(frame.BORDER+frame.SPACING), frame.BORDER+frame.SPACING)
			if not isMoved then
				E:Point(castbar.Holder.mover, "TOPRIGHT", frame, "BOTTOMRIGHT", 0, -(frame.BORDER - frame.SPACING))
			end
		else
			E:Point(castbar, "BOTTOMLEFT", castbar.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
			if not isMoved then
				E:Point(castbar.Holder.mover, "TOPLEFT", frame, "BOTTOMLEFT", 0, -(frame.BORDER - frame.SPACING))
			end
		end

		if castbar.Holder.mover then
			E:EnableMover(castbar.Holder.mover:GetName())
		end
	end

	if not db.castbar.iconAttached and db.castbar.icon then
		local attachPoint = db.castbar.iconAttachedTo == "Frame" and frame or frame.Castbar
		local anchorPoint = db.castbar.iconPosition
		castbar.Icon.bg:ClearAllPoints()
		E:Point(castbar.Icon.bg, INVERT_ANCHORPOINT[anchorPoint], attachPoint, anchorPoint, db.castbar.iconXOffset, db.castbar.iconYOffset)
	elseif db.castbar.icon then
		castbar.Icon.bg:ClearAllPoints()
		if frame.ORIENTATION == "RIGHT" then
			E:Point(castbar.Icon.bg, "LEFT", castbar, "RIGHT", frame.SPACING*3, 0)
		else
			E:Point(castbar.Icon.bg, "RIGHT", castbar, "LEFT", -frame.SPACING*3, 0)
		end
	end

	if db.castbar.enable and not frame:IsElementEnabled("Castbar") then
		frame:EnableElement("Castbar")
	elseif not db.castbar.enable and frame:IsElementEnabled("Castbar") then
		frame:DisableElement("Castbar")

		if castbar.Holder.mover then
			E:DisableMover(castbar.Holder.mover:GetName())
		end
	end
end

function UF:CustomCastDelayText(duration)
	local db = self:GetParent().db
	if not db then return end

	if self.channeling then
		if db.castbar.format == "CURRENT" then
			self.Time:SetText(format("%.1f |cffaf5050%.1f|r", abs(duration - self.max), self.delay))
		elseif db.castbar.format == "CURRENTMAX" then
			self.Time:SetText(format("%.1f / %.1f |cffaf5050%.1f|r", duration, self.max, self.delay))
		elseif db.castbar.format == "REMAINING" then
			self.Time:SetText(format("%.1f |cffaf5050%.1f|r", duration, self.delay))
		end
	else
		if db.castbar.format == "CURRENT" then
			self.Time:SetText(format("%.1f |cffaf5050%s %.1f|r", duration, "+", self.delay))
		elseif db.castbar.format == "CURRENTMAX" then
			self.Time:SetText(format("%.1f / %.1f |cffaf5050%s %.1f|r", duration, self.max, "+", self.delay))
		elseif db.castbar.format == "REMAINING" then
			self.Time:SetText(format("%.1f |cffaf5050%s %.1f|r", abs(duration - self.max), "+", self.delay))
		end
	end
end

function UF:CustomTimeText(duration)
	local db = self:GetParent().db
	if not db then return end

	if self.channeling then
		if db.castbar.format == "CURRENT" then
			self.Time:SetText(format("%.1f", abs(duration - self.max)))
		elseif db.castbar.format == "CURRENTMAX" then
			self.Time:SetText(format("%.1f / %.1f", duration, self.max))
			self.Time:SetText(format("%.1f / %.1f", abs(duration - self.max), self.max))
		elseif db.castbar.format == "REMAINING" then
			self.Time:SetText(format("%.1f", duration))
		end
	else
		if db.castbar.format == "CURRENT" then
			self.Time:SetText(format("%.1f", duration))
		elseif db.castbar.format == "CURRENTMAX" then
			self.Time:SetText(format("%.1f / %.1f", duration, self.max))
		elseif db.castbar.format == "REMAINING" then
			self.Time:SetText(format("%.1f", abs(duration - self.max)))
		end
	end
end

function UF:PostCastStart(name)
	local db = self:GetParent().db
	if not db or not db.castbar then return; end

	self.Text:SetText(name)

	-- Get length of Time, then calculate available length for Text
	local timeWidth = self.Time:GetStringWidth()
	local textWidth = self:GetWidth() - timeWidth - 10
	local textStringWidth = self.Text:GetStringWidth()

	if timeWidth == 0 or textStringWidth == 0 then
		E:Delay(0.05, function() -- Delay may need tweaking
			textWidth = self:GetWidth() - self.Time:GetStringWidth() - 10
			textStringWidth = self.Text:GetStringWidth()
			if textWidth > 0 then self.Text:SetWidth(min(textWidth, textStringWidth)) end
		end)
	else
		self.Text:SetWidth(min(textWidth, textStringWidth))
	end

	self.Spark:SetHeight(self:GetHeight() * 2)

	local colors = ElvUF.colors
	local r, g, b = colors.castColor[1], colors.castColor[2], colors.castColor[3]

	local t
	if UF.db.colors.castClassColor and UnitIsPlayer("player") then
		local _, class = UnitClass("player")
		t = ElvUF.colors.class[class]
	elseif UF.db.colors.castReactionColor and UnitReaction("player", "player") then
		t = ElvUF.colors.reaction[UnitReaction("player", "player")]
	end

	if t then
		r, g, b = t[1], t[2], t[3]
	end
--[[
	if self.notInterruptible and unit ~= "player" and UnitCanAttack("player", unit) then
		r, g, b = colors.castNoInterrupt[1], colors.castNoInterrupt[2], colors.castNoInterrupt[3]
	end
]]
	self:SetStatusBarColor(r, g, b)
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentCastbar, self, self.bg, nil, true)
	if self.bg:IsShown() then
		self.bg:SetTexture(r * 0.25, g * 0.25, b * 0.25)

		local _, _, _, alpha = self.backdrop:GetBackdropColor()
		self.backdrop:SetBackdropColor(r * 0.58, g * 0.58, b * 0.58, alpha)
	end
end