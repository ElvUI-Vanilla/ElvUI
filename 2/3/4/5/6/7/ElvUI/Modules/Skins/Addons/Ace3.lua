local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local pairs = pairs
--WoW API / Variables
local CreateFrame = CreateFrame

local RegisterAsWidget, RegisterAsContainer
local function SetModifiedBackdrop(self)
	if self.backdrop then self = self.backdrop end
	self:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))
end

local function SetOriginalBackdrop(self)
	if self.backdrop then self = self.backdrop end
	self:SetBackdropBorderColor(unpack(E["media"].bordercolor))
end

local function SkinScrollBar(frame, thumbTrim)
	if _G[frame:GetName().."BG"] then _G[frame:GetName().."BG"]:SetTexture(nil) end
	if _G[frame:GetName().."Track"] then _G[frame:GetName().."Track"]:SetTexture(nil) end

	if _G[frame:GetName().."Top"] then
		_G[frame:GetName().."Top"]:SetTexture(nil)
		_G[frame:GetName().."Bottom"]:SetTexture(nil)
		_G[frame:GetName().."Middle"]:SetTexture(nil)
	end

	if _G[frame:GetName().."ScrollUpButton"] and _G[frame:GetName().."ScrollDownButton"] then
		E:StripTextures(_G[frame:GetName().."ScrollUpButton"])
		if not _G[frame:GetName().."ScrollUpButton"].icon then
			S:HandleNextPrevButton(_G[frame:GetName().."ScrollUpButton"])
			S:SquareButton_SetIcon(_G[frame:GetName().."ScrollUpButton"], "UP")
			_G[frame:GetName().."ScrollUpButton"]:SetWidth(_G[frame:GetName().."ScrollUpButton"]:GetWidth() + 7)
			_G[frame:GetName().."ScrollUpButton"]:SetHeight(_G[frame:GetName().."ScrollUpButton"]:GetHeight() + 7)
		end

		E:StripTextures(_G[frame:GetName().."ScrollDownButton"])
		if not _G[frame:GetName().."ScrollDownButton"].icon then
			S:HandleNextPrevButton(_G[frame:GetName().."ScrollDownButton"])
			S:SquareButton_SetIcon(_G[frame:GetName().."ScrollDownButton"], "DOWN")
			_G[frame:GetName().."ScrollDownButton"]:SetWidth(_G[frame:GetName().."ScrollDownButton"]:GetWidth() + 7)
			_G[frame:GetName().."ScrollDownButton"]:SetHeight(_G[frame:GetName().."ScrollDownButton"]:GetHeight() + 7)
		end

		if not frame.trackbg then
			frame.trackbg = CreateFrame("Frame", nil, frame)
			frame.trackbg:SetPoint("TOPLEFT", _G[frame:GetName().."ScrollUpButton"], "BOTTOMLEFT", 0, -1)
			frame.trackbg:SetPoint("BOTTOMRIGHT", _G[frame:GetName().."ScrollDownButton"], "TOPRIGHT", 0, 1)
			E:SetTemplate(frame.trackbg, "Transparent")
		end

		if frame:GetThumbTexture() then
			if not thumbTrim then thumbTrim = 3 end
			frame:GetThumbTexture():SetTexture(nil)
			frame:GetThumbTexture():SetHeight(24)
			if not frame.thumbbg then
				frame.thumbbg = CreateFrame("Frame", nil, frame)
				frame.thumbbg:SetPoint("TOPLEFT", frame:GetThumbTexture(), "TOPLEFT", 2, -thumbTrim)
				frame.thumbbg:SetPoint("TOPLEFT", frame:GetThumbTexture(), "TOPLEFT", 2, -thumbTrim)
				frame.thumbbg:SetPoint("BOTTOMRIGHT", frame:GetThumbTexture(), "BOTTOMRIGHT", -2, thumbTrim)
				E:SetTemplate(frame.thumbbg, "Default", true, true)
				frame.thumbbg:SetBackdropColor(0.3, 0.3, 0.3)
				if frame.trackbg then
					frame.thumbbg:SetFrameLevel(frame.trackbg:GetFrameLevel() + 1)
				end
			end
		end
	end
end

local function SkinButton(f, strip, noTemplate)
	local name = f:GetName()

	if(name) then
		local left = _G[name.."Left"]
		local middle = _G[name.."Middle"]
		local right = _G[name.."Right"]

		if(left) then E:Kill(left) end
		if(middle) then E:Kill(middle) end
		if(right) then E:Kill(right) end
	end

	if(f.Left) then E:Kill(f.Left) end
	if(f.Middle) then E:Kill(f.Middle) end
	if(f.Right) then E:Kill(f.Right) end

	if f.SetNormalTexture then f:SetNormalTexture("") end
	if f.SetHighlightTexture then f:SetHighlightTexture("") end
	if f.SetPushedTexture then f:SetPushedTexture("") end
	if f.SetDisabledTexture then f:SetDisabledTexture("") end

	if strip then E:StripTextures(f) end

	if not f.template and not noTemplate then
		E:SetTemplate(f, "Default", true)
	end

	HookScript(f, "OnEnter", function() SetModifiedBackdrop(this) end)
	HookScript(f, "OnLeave", function() SetOriginalBackdrop(this) end)
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

			if not widget.scrollBG.template then
				E:SetTemplate(widget.scrollBG, "Default")
			end

			SkinButton(widget.button)
			SkinScrollBar(widget.scrollBar)
			widget.scrollBar:SetPoint("RIGHT", frame, "RIGHT", 0 -4)
			widget.scrollBG:SetPoint("TOPRIGHT", widget.scrollBar, "TOPLEFT", -2, 19)
			widget.scrollBG:SetPoint("BOTTOMLEFT", widget.button, "TOPLEFT")
			widget.scrollFrame:SetPoint("BOTTOMRIGHT", widget.scrollBG, "BOTTOMRIGHT", -4, 8)
		elseif TYPE == "CheckBox" then
			E:Kill(widget.checkbg)
			E:Kill(widget.highlight)

			if not widget.skinnedCheckBG then
				widget.skinnedCheckBG = CreateFrame("Frame", nil, widget.frame)
				E:SetTemplate(widget.skinnedCheckBG, "Default")
				widget.skinnedCheckBG:SetPoint("TOPLEFT", widget.checkbg, "TOPLEFT", 4, -4)
				widget.skinnedCheckBG:SetPoint("BOTTOMRIGHT", widget.checkbg, "BOTTOMRIGHT", -4, 4)
			end

			widget.check:SetParent(widget.skinnedCheckBG)
		elseif TYPE == "Dropdown" then
			local frame = widget.dropdown
			local button = widget.button
			local text = widget.text
			E:StripTextures(frame)

			button:ClearAllPoints()
			button:SetPoint("RIGHT", frame, "RIGHT", -20, 0)

			S:HandleNextPrevButton(button, true)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
				frame.backdrop:SetPoint("TOPLEFT", 20, -2)
				frame.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
			end
			button:SetParent(frame.backdrop)
			text:SetParent(frame.backdrop)
			HookScript(button, "OnClick", function()
				local dropdown = this.obj.pullout
				if dropdown.frame then
					E:SetTemplate(dropdown.frame, "Default", true)
					if dropdown.slider then
						E:SetTemplate(dropdown.slider, "Default")
						dropdown.slider:SetPoint("TOPRIGHT", dropdown.frame, "TOPRIGHT", -10, -10)
						dropdown.slider:SetPoint("BOTTOMRIGHT", dropdown.frame, "BOTTOMRIGHT", -10, 10)

						if dropdown.slider:GetThumbTexture() then
							dropdown.slider:SetThumbTexture(E["media"].blankTex)
							dropdown.slider:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
							-- dropdown.slider:GetThumbTexture():Size(10, 12)
							dropdown.slider:GetThumbTexture():SetWidth(10)
							dropdown.slider:GetThumbTexture():SetHeight(12)
						end
					end
				end
			end)
		elseif TYPE == "LSM30_Font" or TYPE == "LSM30_Sound" or TYPE == "LSM30_Border" or TYPE == "LSM30_Background" or TYPE == "LSM30_Statusbar" then
			local frame = widget.frame
			local button = frame.dropButton
			local text = frame.text
			E:StripTextures(frame)

			S:HandleNextPrevButton(button, true)
			frame.text:ClearAllPoints()
			frame.text:SetPoint("RIGHT", button, "LEFT", -2, 0)

			button:ClearAllPoints()
			button:SetPoint("RIGHT", frame, "RIGHT", -10, -6)

			if not frame.backdrop then
				E:CreateBackdrop(frame, "Default")
				if TYPE == "LSM30_Font" then
					frame.backdrop:SetPoint("TOPLEFT", 20, -17)
				elseif TYPE == "LSM30_Sound" then
					frame.backdrop:SetPoint("TOPLEFT", 20, -17)
					widget.soundbutton:SetParent(frame.backdrop)
					widget.soundbutton:ClearAllPoints()
					widget.soundbutton:SetPoint("LEFT", frame.backdrop, "LEFT", 2, 0)
				elseif TYPE == "LSM30_Statusbar" then
					frame.backdrop:SetPoint("TOPLEFT", 20, -17)
					widget.bar:SetParent(frame.backdrop)
					E:SetInside(widget.bar)
				elseif TYPE == "LSM30_Border" or TYPE == "LSM30_Background" then
					frame.backdrop:SetPoint("TOPLEFT", 42, -16)
				end

				frame.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
			end
			button:SetParent(frame.backdrop)
			text:SetParent(frame.backdrop)
			HookScript(button, "OnClick", function()
				local dropdown = this.obj.dropdown
				if dropdown then
					E:SetTemplate(dropdown, "Default", true)
					if dropdown.slider then
						E:SetTemplate(dropdown.slider, "Transparent")
						dropdown.slider:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -10, -10)
						dropdown.slider:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -10, 10)

						if dropdown.slider:GetThumbTexture() then
							dropdown.slider:SetThumbTexture(E["media"].blankTex)
							dropdown.slider:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
							-- dropdown.slider:GetThumbTexture():Size(10, 12)
							dropdown.slider:GetThumbTexture():SetWidth(10)
							dropdown.slider:GetThumbTexture():SetHeight(12)
						end
					end

					if TYPE == "LSM30_Sound" then
						local frame = this.obj.frame
						local width = frame:GetWidth()
						dropdown:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
						dropdown:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 30, 0)
					end
				end
			end)
		elseif TYPE == "EditBox" then
			local frame = widget.editbox
			local button = widget.button
			E:Kill(_G[frame:GetName().."Left"])
			E:Kill(_G[frame:GetName().."Middle"])
			E:Kill(_G[frame:GetName().."Right"])
			frame:SetHeight(17)
			E:CreateBackdrop(frame, "Default")
			frame.backdrop:SetPoint("TOPLEFT", -2, 0)
			frame.backdrop:SetPoint("BOTTOMRIGHT", 2, 0)
			frame.backdrop:SetParent(widget.frame)
			frame:SetParent(frame.backdrop)
			SkinButton(button)
		elseif TYPE == "Button" then
			local frame = widget.frame
			SkinButton(frame, nil, true)
			E:StripTextures(frame)
			E:CreateBackdrop(frame, "Default", true)
			E:SetInside(frame.backdrop)
			widget.text:SetParent(frame.backdrop)
		elseif TYPE == "Button-ElvUI" then
			local frame = widget.frame
			SkinButton(frame, nil, true)
			E:StripTextures(frame)
			E:CreateBackdrop(frame, "Default", true)
			E:SetInside(frame.backdrop)
			widget.text:SetParent(frame.backdrop)
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
			msg:SetPoint("LEFT", 10, 0)
			msg:SetPoint("RIGHT", -10, 0)
			msg:SetJustifyV("MIDDLE")
			msg:SetWidth(msg:GetWidth() + 10)
		elseif TYPE == "Slider" then
			local frame = widget.slider
			local editbox = widget.editbox
			local lowtext = widget.lowtext
			local hightext = widget.hightext
			local HEIGHT = 12

			E:StripTextures(frame)
			E:SetTemplate(frame, "Default")
			frame:SetHeight(HEIGHT)
			frame:SetThumbTexture(E["media"].blankTex)
			frame:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
			-- frame:GetThumbTexture():Size(HEIGHT-2,HEIGHT+2)
			frame:GetThumbTexture():SetWidth(HEIGHT-2)
			frame:GetThumbTexture():SetHeight(HEIGHT+2)

			E:SetTemplate(editbox, "Default")
			editbox:SetHeight(15)
			editbox:SetPoint("TOP", frame, "BOTTOM", 0, -1)

			lowtext:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, -2)
			hightext:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -2, -2)

		--[[elseif TYPE == "ColorPicker" then
			local frame = widget.frame
			local colorSwatch = widget.colorSwatch
		]]
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
			local frame = widget.scrollbar
			SkinScrollBar(frame)
		elseif TYPE == "InlineGroup" or TYPE == "TreeGroup" or TYPE == "TabGroup-ElvUI" or TYPE == "Frame" or TYPE == "DropdownGroup" or TYPE == "Window" then
			local frame = widget.content:GetParent()
			if TYPE == "Frame" then
				E:StripTextures(frame)
				if(not E.GUIFrame) then
					E.GUIFrame = frame
				end
				
				for _, child in ipairs({frame:GetChildren()}) do
					if child:GetObjectType() == "Button" and child:GetText() then
						SkinButton(child)
					else
						E:StripTextures(child)
					end
				end

				--[[for i=1, frame:GetNumChildren() do
					local child = select(i, frame:GetChildren())
					if child:GetObjectType() == "Button" and child:GetText() then
						SkinButton(child)
					else
						E:StripTextures(child)
					end
				end]]
			elseif TYPE == "Window" then
				E:StripTextures(frame)
				S:HandleCloseButton(frame.obj.closebutton)
			end
			E:SetTemplate(frame, "Transparent")

			if widget.treeframe then
				E:SetTemplate(widget.treeframe, "Transparent")
				frame:SetPoint("TOPLEFT", widget.treeframe, "TOPRIGHT", 1, 0)

				local oldCreateButton = widget.CreateButton
				widget.CreateButton = function(self)
					local button = oldCreateButton(self)
					E:StripTextures(button.toggle)
					button.toggle.SetNormalTexture = E.noop
					button.toggle.SetPushedTexture = E.noop
					button.toggleText = button.toggle:CreateFontString(nil, "OVERLAY")
					E:FontTemplate(button.toggleText, nil, 19)
					button.toggleText:SetPoint("CENTER", 0, 0)
					button.toggleText:SetText("+")
					return button
				end

				local oldRefreshTree = widget.RefreshTree
				widget.RefreshTree = function(self, scrollToSelection)
					oldRefreshTree(self, scrollToSelection)
					if not self.tree then return end
					local status = self.status or self.localstatus
					local groupstatus = status.groups
					local lines = self.lines
					local buttons = self.buttons

					for i, line in pairs(lines) do
						local button = buttons[i]
						if groupstatus[line.uniquevalue] and button then
							button.toggleText:SetText("-")
						elseif button then
							button.toggleText:SetText("+")
						end
					end
				end
			end

			if TYPE == "TabGroup-ElvUI" then
				local oldCreateTab = widget.CreateTab
				widget.CreateTab = function(self, id)
					local tab = oldCreateTab(self, id)
					E:StripTextures(tab)
					tab.backdrop = CreateFrame("Frame", nil, tab)
					E:SetTemplate(tab.backdrop, "Transparent")
					tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
					tab.backdrop:SetPoint("TOPLEFT", 10, -3)
					tab.backdrop:SetPoint("BOTTOMRIGHT", -10, 0)
					return tab
				end
			end

			if widget.scrollbar then
				SkinScrollBar(widget.scrollbar)
			end
		elseif TYPE == "SimpleGroup" then
			local frame = widget.content:GetParent()
			E:SetTemplate(frame, "Transparent", nil, true) --ignore border updates
			frame:SetBackdropBorderColor(0,0,0,0) --Make border completely transparent
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