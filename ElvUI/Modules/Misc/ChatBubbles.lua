local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:GetModule("Misc");
local CH = E:GetModule("Chat");
local CC = E:GetModule("ClassCache");

--Cache global variables
--Lua functions
local select, unpack, type = select, unpack, type
local format, gsub, match, gmatch = string.format, string.gsub, string.match, string.gmatch
local strlower = strlower
--WoW API / Variables
local CreateFrame = CreateFrame

function M:UpdateBubbleBorder()
	if not this.text then return end

	if E.private.general.chatBubbles == "backdrop" then
		if E.PixelMode then
			this:SetBackdropBorderColor(this.text:GetTextColor())
		else
			local r, g, b = this.text:GetTextColor()
			this.bordertop:SetTexture(r, g, b)
			this.borderbottom:SetTexture(r, g, b)
			this.borderleft:SetTexture(r, g, b)
			this.borderright:SetTexture(r, g, b)
		end
	end

	if E.private.chat.enable and E.private.general.classCache and E.private.general.classColorMentionsSpeech then
		local classColorTable, isFirstWord, rebuiltString, lowerCaseWord, tempWord, wordMatch, classMatch
		local text = this.text:GetText()
		if text and match(text, "%s-[^%s]+%s*") then
			for word in gmatch(text, "%s-[^%s]+%s*") do
				tempWord = gsub(word, "^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$","%1%2")
				lowerCaseWord = strlower(tempWord)

				classMatch = CC:GetCacheTable()[E.myrealm][tempWord]
				wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classMatch] or RAID_CLASS_COLORS[classMatch]
					word = gsub(word, gsub(tempWord, "%-","%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
				end

				if not isFirstWord then
					rebuiltString = word
					isFirstWord = true
				else
					rebuiltString = format("%s%s", rebuiltString, word)
				end
			end

			if rebuiltString ~= nil then
				this.text:SetText(rebuiltString)
			end
		end
	end
end

function M:SkinBubble(frame)
	local mult = E.mult * UIParent:GetScale()
	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region:GetObjectType() == "Texture" then
			region:SetTexture(nil)
		elseif region:GetObjectType() == "FontString" then
			frame.text = region
		end
	end

	if frame.text then
		if E.private.general.chatBubbles == "backdrop" then
			if E.PixelMode then
				E:SetTemplate(frame, "Transparent", true)
				frame:SetBackdropColor(unpack(E.media.backdropfadecolor))
				frame:SetBackdropBorderColor(0, 0, 0)
			else
				frame:SetBackdrop(nil)
			end

			local r, g, b = frame.text:GetTextColor()
			if not E.PixelMode then
				if not frame.backdrop then
					frame.backdrop = frame:CreateTexture(nil, "BACKGROUND")
					frame.backdrop:SetAllPoints(frame)
					frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))

					frame.bordertop = frame:CreateTexture(nil, "OVERLAY")
					E:Point(frame.bordertop, "TOPLEFT", frame, "TOPLEFT", -mult*2, mult*2)
					E:Point(frame.bordertop, "TOPRIGHT", frame, "TOPRIGHT", mult*2, mult*2)
					E:Height(frame.bordertop, mult)
					frame.bordertop:SetTexture(r, g, b)

					frame.bordertop.backdrop = frame:CreateTexture(nil, "BORDER")
					E:Point(frame.bordertop.backdrop, "TOPLEFT", frame.bordertop, "TOPLEFT", -mult, mult)
					E:Point(frame.bordertop.backdrop, "TOPRIGHT", frame.bordertop, "TOPRIGHT", mult, mult)
					E:Height(frame.bordertop.backdrop, mult * 3)
					frame.bordertop.backdrop:SetTexture(0, 0, 0)

					frame.borderbottom = frame:CreateTexture(nil, "OVERLAY")
					E:Point(frame.borderbottom, "BOTTOMLEFT", frame, "BOTTOMLEFT", -mult*2, -mult*2)
					E:Point(frame.borderbottom, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", mult*2, -mult*2)
					E:Height(frame.borderbottom, mult)
					frame.borderbottom:SetTexture(r, g, b)

					frame.borderbottom.backdrop = frame:CreateTexture(nil, "BORDER")
					E:Point(frame.borderbottom.backdrop, "BOTTOMLEFT", frame.borderbottom, "BOTTOMLEFT", -mult, -mult)
					E:Point(frame.borderbottom.backdrop, "BOTTOMRIGHT", frame.borderbottom, "BOTTOMRIGHT", mult, -mult)
					E:Height(frame.borderbottom.backdrop, mult * 3)
					frame.borderbottom.backdrop:SetTexture(0, 0, 0)

					frame.borderleft = frame:CreateTexture(nil, "OVERLAY")
					E:Point(frame.borderleft, "TOPLEFT", frame, "TOPLEFT", -mult*2, mult*2)
					E:Point(frame.borderleft, "BOTTOMLEFT", frame, "BOTTOMLEFT", mult*2, -mult*2)
					E:Width(frame.borderleft, mult)
					frame.borderleft:SetTexture(r, g, b)

					frame.borderleft.backdrop = frame:CreateTexture(nil, "BORDER")
					E:Point(frame.borderleft.backdrop, "TOPLEFT", frame.borderleft, "TOPLEFT", -mult, mult)
					E:Point(frame.borderleft.backdrop, "BOTTOMLEFT", frame.borderleft, "BOTTOMLEFT", -mult, -mult)
					E:Width(frame.borderleft.backdrop, mult * 3)
					frame.borderleft.backdrop:SetTexture(0, 0, 0)

					frame.borderright = frame:CreateTexture(nil, "OVERLAY")
					E:Point(frame.borderright, "TOPRIGHT", frame, "TOPRIGHT", mult*2, mult*2)
					E:Point(frame.borderright, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -mult*2, -mult*2)
					E:Width(frame.borderright, mult)
					frame.borderright:SetTexture(r, g, b)

					frame.borderright.backdrop = frame:CreateTexture(nil, "BORDER")
					E:Point(frame.borderright.backdrop, "TOPRIGHT", frame.borderright, "TOPRIGHT", mult, mult)
					E:Point(frame.borderright.backdrop, "BOTTOMRIGHT", frame.borderright, "BOTTOMRIGHT", mult, -mult)
					E:Width(frame.borderright.backdrop, mult * 3)
					frame.borderright.backdrop:SetTexture(0, 0, 0)
				end
			else
				frame:SetBackdropColor(unpack(E.media.backdropfadecolor))
				frame:SetBackdropBorderColor(r, g, b)
			end

			E:FontTemplate(frame.text, E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)
		elseif E.private.general.chatBubbles == "backdrop_noborder" then
			frame:SetBackdrop(nil)

			if not frame.backdrop then
				frame.backdrop = frame:CreateTexture(nil, "ARTWORK")
				E:SetInside(frame.backdrop, frame, 4, 4)
				frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))
			end
			E:FontTemplate(frame.text, E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)

			frame:SetClampedToScreen(false)
		elseif E.private.general.chatBubbles == "nobackdrop" then
			frame:SetBackdrop(nil)
			E:FontTemplate(frame.text, E.LSM:Fetch("font", E.private.general.chatBubbleFont), E.private.general.chatBubbleFontSize, E.private.general.chatBubbleFontOutline)
			frame:SetClampedToScreen(false)
		end
	end

	HookScript(frame, "OnShow", M.UpdateBubbleBorder)
	frame:SetFrameStrata("DIALOG")
	M.UpdateBubbleBorder(frame)
	frame.isBubblePowered = true
end

function M:IsChatBubble(frame)
	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region.GetTexture and region:GetTexture() and type(region:GetTexture() == "string" and strlower(region:GetTexture()) == [[interface\tooltips\chatbubble-background]]) then return true end
	end
	return false
end

local numChildren = 0
function M:LoadChatBubbles()
	if E.private.general.bubbles == false then
		E.private.general.chatBubbles = "disabled"
		E.private.general.bubbles = nil
	end

	if E.private.general.chatBubbles == "disabled" then return end

	local frame = CreateFrame("Frame")
	frame.lastupdate = -2

	frame:SetScript("OnUpdate", function()
		this.lastupdate = this.lastupdate + arg1
		if this.lastupdate < .1 then return end
		this.lastupdate = 0

		local count = WorldFrame:GetNumChildren()
		if count ~= numChildren then
			for i = numChildren + 1, count do
				local frame = select(i, WorldFrame:GetChildren())

				if frame.GetObjectType and frame:GetObjectType() == "Frame" and M:IsChatBubble(frame) then
					M:SkinBubble(frame)
				end
			end
			numChildren = count
		end
	end)
end