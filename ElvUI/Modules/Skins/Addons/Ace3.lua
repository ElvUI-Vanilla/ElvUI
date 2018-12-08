local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local select = select
local getn = table.getn
--WoW API / Variables
local CreateFrame = CreateFrame
local RegisterAsWidget, RegisterAsContainer

local function SkinButton(f, strip, noTemplate)
	local name = f:GetName()
	if name then
		local left = _G[name.."Left"]
		local middle = _G[name.."Middle"]
		local right = _G[name.."Right"]

		if left then E:Kill(left) end
		if middle then E:Kill(middle) end
		if right then E:Kill(right) end
	end

	if f.Left then E:Kill(f.Left) end
	if f.Middle then E:Kill(f.Middle) end
	if f.Right then E:Kill(f.Right) end

	if f.SetNormalTexture then f:SetNormalTexture("") end
	if f.SetHighlightTexture then f:SetHighlightTexture("") end
	if f.SetPushedTexture then f:SetPushedTexture("") end
	if f.SetDisabledTexture then f:SetDisabledTexture("") end

	if strip then E:StripTextures(f) end

	if not f.template and not noTemplate then
		E:SetTemplate(f, "Default", true)
	end

	HookScript(f, "OnEnter", S.SetModifiedBackdrop)
	HookScript(f, "OnLeave", S.SetOriginalBackdrop)
end

local function SkinDropdownPullout(self)
	if self and self.obj then
		local pullout = self.obj.pullout
		local dropdown = self.obj.dropdown

		if pullout and pullout.frame then
			if pullout.frame.template and pullout.slider.template then return end

			if not pullout.frame.template then
				E:SetTemplate(pullout.frame, "Default", true)
			end

			if not pullout.slider.template then
				E:SetTemplate(pullout.slider, "Default")
				E:Point(pullout.slider, "TOPRIGHT", pullout.frame, "TOPRIGHT", -10, -10)
				E:Point(pullout.slider, "BOTTOMRIGHT", pullout.frame, "BOTTOMRIGHT", -10, 10)
				if pullout.slider:GetThumbTexture() then
					pullout.slider:SetThumbTexture([[Interface\AddOns\ElvUI\media\textures\melli]])
					pullout.slider:GetThumbTexture():SetVertexColor(1, 0.82, 0, 0.8)
					E:Size(pullout.slider:GetThumbTexture(), 10, 14)
				end
			end
		elseif dropdown then
			E:SetTemplate(dropdown, "Default", true)

			if dropdown.slider then
				E:SetTemplate(dropdown.slider, "Default")
				E:Point(dropdown.slider, "TOPRIGHT", dropdown, "TOPRIGHT", -10, -10)
				E:Point(dropdown.slider, "BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -10, 10)

				if dropdown.slider:GetThumbTexture() then
					dropdown.slider:SetThumbTexture([[Interface\AddOns\ElvUI\media\textures\melli]])
					dropdown.slider:GetThumbTexture():SetVertexColor(1, 0.82, 0, 0.8)
					E:Size(dropdown.slider:GetThumbTexture(), 10, 14)
				end
			end

			if TYPE == "LSM30_Sound" then
				local frame = self.obj.frame
				local width = frame:GetWidth()
				E:Point(dropdown, "TOPLEFT", frame, "BOTTOMLEFT")
				E:Point(dropdown, "TOPRIGHT", frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 30, 0)
			end
		end
	end
end

function S:SkinAce3()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end
	local oldRegisterAsWidget = AceGUI.RegisterAsWidget

	RegisterAsWidget = function(self, widget)
		if not E.private.skins.ace3.enable then
			return oldRegisterAsWidget(self, widget)
		end
		local TYPE = widget.type
		if TYPE == "MultiLineEditBox" then
			local frame = widget.frame
			local scrollBG = widget.scrollBG or select(2, frame:GetChildren())

			if not scrollBG.template then
				E:SetTemplate(scrollBG, "Default")
			end

			SkinButton(widget.button)
			S:HandleScrollBar(widget.scrollBar)
			E:Point(widget.scrollBar, "RIGHT", frame, "RIGHT", 0 -4)

			E:Point(scrollBG, "TOPRIGHT", widget.scrollBar, "TOPLEFT", -2, 19)
			E:Point(scrollBG, "BOTTOMLEFT", widget.button, "TOPLEFT")
			E:Point(widget.scrollFrame, "BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 8)
		elseif TYPE == "CheckBox" then
			local check = widget.check
			local checkbg = widget.checkbg
			local highlight = widget.highlight

			E:CreateBackdrop(checkbg, "Default")
			E:SetInside(checkbg.backdrop, checkbg, 4, 4)
			checkbg.backdrop:SetFrameLevel(checkbg.backdrop:GetFrameLevel() + 1)
			checkbg:SetTexture("")
			checkbg.SetTexture = E.noop

			check:SetTexture([[Interface\AddOns\ElvUI\media\textures\melli]])
			check.SetTexture = E.noop
			check:SetVertexColor(1, 0.82, 0, 0.8)
			E:SetInside(check, checkbg.backdrop)
			check:SetParent(checkbg.backdrop)

			highlight:SetTexture("")
			highlight.SetTexture = E.noop
		elseif TYPE == "Dropdown" then
			local frame = widget.dropdown
			local button = widget.button
			local button_cover = widget.button_cover
			local text = widget.text

			E:StripTextures(frame)

			S:HandleNextPrevButton(button, true)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
			end

			E:Point(frame.backdrop, "TOPLEFT", 17, -2)
			E:Point(frame.backdrop, "BOTTOMRIGHT", -21, 0)

			widget.label:ClearAllPoints()
			E:Point(widget.label, "BOTTOMLEFT", frame.backdrop, "TOPLEFT", 2, 0)

			E:Size(button, 20, 20)
			button:ClearAllPoints()
			E:Point(button, "RIGHT", frame.backdrop, "RIGHT", -2, 0)
			button:SetParent(frame.backdrop)

			text:ClearAllPoints()
			E:Point(text, "RIGHT", frame.backdrop, "RIGHT", -26, 2)
			E:Point(text, "LEFT", frame.backdrop, "LEFT", 2, 0)
			text:SetParent(frame.backdrop)

			HookScript(button, "OnClick", SkinDropdownPullout)

			if button_cover then
				HookScript(button_cover, "OnClick", SkinDropdownPullout)
			end
		elseif TYPE == "LSM30_Font" or TYPE == "LSM30_Sound" or TYPE == "LSM30_Border" or TYPE == "LSM30_Background" or TYPE == "LSM30_Statusbar" then
			local frame = widget.frame
			local button = frame.dropButton
			local text = frame.text

			E:StripTextures(frame)

			S:HandleNextPrevButton(button, true)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
			end

			frame.label:ClearAllPoints()
			E:Point(frame.label, "BOTTOMLEFT", frame.backdrop, "TOPLEFT", 2, 0)

			text:ClearAllPoints()
			E:Point(text, "RIGHT", button, "LEFT", -2, 0)

			E:Size(button, 20, 20)
			button:ClearAllPoints()
			E:Point(button, "RIGHT", frame.backdrop, "RIGHT", -2, 0)

			E:Point(frame.backdrop, "TOPLEFT", 0, -21)
			E:Point(frame.backdrop, "BOTTOMRIGHT", -4, -1)

			if TYPE == "LSM30_Sound" then
				widget.soundbutton:SetParent(frame.backdrop)
				widget.soundbutton:ClearAllPoints()
				E:Point(widget.soundbutton, "LEFT", frame.backdrop, "LEFT", 2, 0)
			elseif TYPE == "LSM30_Statusbar" then
				widget.bar:SetParent(frame.backdrop)
				widget.bar:ClearAllPoints()
				E:Point(widget.bar, "TOPLEFT", frame.backdrop, "TOPLEFT", 2, -2)
				E:Point(widget.bar, "BOTTOMRIGHT", button, "BOTTOMLEFT", -1, 0)
			end

			button:SetParent(frame.backdrop)
			text:SetParent(frame.backdrop)

			HookScript(button, "OnClick", SkinDropdownPullout)
		elseif TYPE == "EditBox" then
			local frame = widget.editbox
			local button = widget.button

			E:Kill(_G[frame:GetName().."Left"])
			E:Kill(_G[frame:GetName().."Middle"])
			E:Kill(_G[frame:GetName().."Right"])

			E:Height(frame, 17)
			E:CreateBackdrop(frame, "Default")
			E:Point(frame.backdrop, "TOPLEFT", 2, -2)
			E:Point(frame.backdrop, "BOTTOMRIGHT", -2, 0)
			frame.backdrop:SetParent(widget.frame)
			frame:SetParent(frame.backdrop)
			frame:SetTextInsets(4, 43, 3, 3)
			frame.SetTextInsets = E.noop

			SkinButton(button)
			E:Point(button, "RIGHT", frame.backdrop, "RIGHT", -2, 0)

			hooksecurefunc(frame, "SetPoint", function(self, a, b, c, d, e)
				if d == 7 then
					self:SetPoint(a, b, c, 0, e)
				end
			end)
		elseif TYPE == "Button" or TYPE == "Button-ElvUI" then
			local frame = widget.frame

			SkinButton(frame, nil, true)

			E:StripTextures(frame)
			E:CreateBackdrop(frame, "Default", true)
			E:SetInside(frame.backdrop)

			widget.text:SetParent(frame.backdrop)
		elseif TYPE == "Slider" then
			local frame = widget.slider
			local editbox = widget.editbox
			local lowtext = widget.lowtext
			local hightext = widget.hightext
			local HEIGHT = 12

			E:StripTextures(frame)
			E:SetTemplate(frame, "Default")
			E:Height(frame, HEIGHT)

			frame:SetThumbTexture([[Interface\AddOns\ElvUI\media\textures\melli]])
			frame:GetThumbTexture():SetVertexColor(1, 0.82, 0, 0.8)
			E:Size(frame:GetThumbTexture(), HEIGHT - 2, HEIGHT - 2)

			E:SetTemplate(editbox, "Default")
			E:Height(editbox, 15)
			E:Point(editbox, "TOP", frame, "BOTTOM", 0, -1)

			E:Point(lowtext, "TOPLEFT", frame, "BOTTOMLEFT", 2, -2)
			E:Point(hightext, "TOPRIGHT", frame, "BOTTOMRIGHT", -2, -2)
		elseif TYPE == "Keybinding" then
			local button = widget.button
			local msgframe = widget.msgframe
			local msg = widget.msgframe.msg

			SkinButton(button)

			E:StripTextures(msgframe)
			E:CreateBackdrop(msgframe, "Default", true)
			E:SetInside(msgframe.backdrop)
			msgframe:SetToplevel(true)

			msg:ClearAllPoints()
			E:Point(msg, "LEFT", 10, 0)
			E:Point(msg, "RIGHT", -10, 0)
			msg:SetJustifyV("MIDDLE")
			E:Width(msg, msg:GetWidth() + 10)
		elseif (TYPE == "ColorPicker" or TYPE == "ColorPicker-ElvUI") then
			local frame = widget.frame
			local colorSwatch = widget.colorSwatch

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
			end

			E:Size(frame.backdrop, 24, 16)
			frame.backdrop:ClearAllPoints()
			E:Point(frame.backdrop, "LEFT", frame, "LEFT", 4, 0)
			frame.backdrop:SetBackdropColor(0, 0, 0, 0)
			frame.backdrop.SetBackdropColor = E.noop

			colorSwatch:SetTexture(E.media.blankTex)
			colorSwatch:ClearAllPoints()
			colorSwatch:SetParent(frame.backdrop)
			E:SetInside(colorSwatch, frame.backdrop)

			if frame.texture then
				frame.texture:SetTexture(0, 0, 0, 0)
			end

			if frame.checkers then
				frame.checkers:ClearAllPoints()
				frame.checkers:SetDrawLayer("ARTWORK")
				frame.checkers:SetParent(frame.backdrop)
				E:SetInside(frame.checkers, frame.backdrop)
			end
		end

		return oldRegisterAsWidget(self, widget)
	end
	AceGUI.RegisterAsWidget = RegisterAsWidget

	local oldRegisterAsContainer = AceGUI.RegisterAsContainer
	RegisterAsContainer = function(self, widget)
		if not E.private.skins.ace3.enable then
			return oldRegisterAsContainer(self, widget)
		end
		local TYPE = widget.type
		if TYPE == "ScrollFrame" then
			S:HandleScrollBar(widget.scrollbar)
		elseif TYPE == "InlineGroup" or TYPE == "TreeGroup" or TYPE == "TabGroup" or TYPE == "Frame" or TYPE == "DropdownGroup" or TYPE == "Window" then
			local frame = widget.content:GetParent()
			if TYPE == "Frame" then
				E:StripTextures(frame)
				if not E.GUIFrame then
					E.GUIFrame = frame
				end
				for i = 1, frame:GetNumChildren() do
					local child = select(i, frame:GetChildren())
					if child:GetObjectType() == "Button" and child:GetText() then
						SkinButton(child)
					else
						E:StripTextures(child)
					end
				end
			elseif TYPE == "Window" then
				E:StripTextures(frame)
				S:HandleCloseButton(frame.obj.closebutton)
			end
			E:SetTemplate(frame, "Transparent")

			if widget.treeframe then
				E:SetTemplate(widget.treeframe, "Transparent")
				E:Point(frame, "TOPLEFT", widget.treeframe, "TOPRIGHT", 1, 0)

				local oldRefreshTree = widget.RefreshTree
				widget.RefreshTree = function(self, scrollToSelection)
					oldRefreshTree(self, scrollToSelection)
					if not self.tree then return end
					local status = self.status or self.localstatus
					local groupstatus = status.groups
					local lines = self.lines
					local buttons = self.buttons
					local offset = status.scrollvalue

					for i = offset + 1, getn(lines) do
						local button = buttons[i - offset]
						if button then
							button.toggle:SetNormalTexture([[Interface\AddOns\ElvUI\media\textures\PlusMinusButton]])
							button.toggle:SetPushedTexture([[Interface\AddOns\ElvUI\media\textures\PlusMinusButton]])
							button.toggle:SetHighlightTexture("")

							if groupstatus[lines[i].uniquevalue] then
								button.toggle:GetNormalTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
								button.toggle:GetPushedTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
							else
								button.toggle:GetNormalTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
								button.toggle:GetPushedTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
							end
						end
					end
				end
			end

			if TYPE == "TabGroup" then
				local oldCreateTab = widget.CreateTab
				widget.CreateTab = function(self, id)
				local tab = oldCreateTab(self, id)
					E:StripTextures(tab)
					tab.backdrop = CreateFrame("Frame", nil, tab)
					E:SetTemplate(tab.backdrop, "Transparent")
					E:Delay(0.01, function() tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1) end) -- Temp Fix
					E:Point(tab.backdrop, "TOPLEFT", 10, -3)
					E:Point(tab.backdrop, "BOTTOMRIGHT", -10, 0)

					HookScript(tab, "OnShow", function()
						local tabLevel = this:GetFrameLevel()
						local tabBGLevel = this.backdrop:GetFrameLevel()

						if tabLevel <= tabBGLevel then
							this.backdrop:SetFrameLevel(tabLevel - 1)
						end
					end)

					return tab
				end
			end

			if widget.scrollbar then
				S:HandleScrollBar(widget.scrollbar)
			end
		elseif TYPE == "SimpleGroup" then
			local frame = widget.content:GetParent()
			E:SetTemplate(frame, "Transparent", nil, true) --ignore border updates
			frame:SetBackdropBorderColor(0, 0, 0, 0) --Make border completely transparent
		end

		return oldRegisterAsContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer
end

local function attemptSkin()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		S:SkinAce3()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", attemptSkin)

S:AddCallback("Ace3", attemptSkin)
