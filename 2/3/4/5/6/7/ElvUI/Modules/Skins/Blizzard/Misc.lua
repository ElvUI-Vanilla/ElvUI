local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local find, getn = string.find, table.getn
--WoW API / Variables
local IsAddOnLoaded = IsAddOnLoaded
local UnitIsUnit = UnitIsUnit
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.misc ~= true then return end
	-- Blizzard frame we want to reskin
	local skins = {
		"GameMenuFrame",
		"UIOptionsFrame",
		"OptionsFrame",
		"OptionsFrameDisplay",
		"OptionsFrameBrightness",
		"OptionsFrameWorldAppearance",
		"OptionsFramePixelShaders",
		"OptionsFrameMiscellaneous",
		"SoundOptionsFrame",
		"TicketStatusFrame",
		"StackSplitFrame"
	}

	for i = 1, getn(skins) do
		E:SetTemplate(_G[skins[i]], "Transparent")
	end

	local ChatMenus = {
		"ChatMenu",
		"EmoteMenu",
		"LanguageMenu",
		"VoiceMacroMenu",
	}

	for i = 1, getn(ChatMenus) do
		if _G[ChatMenus[i]] == _G["ChatMenu"] then
			HookScript(_G[ChatMenus[i]], "OnShow", function()
				E:SetTemplate(this, "Transparent", true)
				this:SetBackdropColor(unpack(E["media"].backdropfadecolor))
				this:ClearAllPoints()
				this:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 30)
			end)
		else
			HookScript(_G[ChatMenus[i]], "OnShow", function()
				E:SetTemplate(this, "Transparent", true)
				this:SetBackdropColor(unpack(E["media"].backdropfadecolor))
			end)
		end
	end

	for i = 1, OptionsFrame:GetNumRegions() do
		local region = select(i, OptionsFrame:GetRegions())
		if region:GetObjectType() == "Texture" then
			if i == 3 then
				E:Kill(region) -- Kill the nVidia logo
			end
		end
	end

	local function StyleButton(f)
		local width, height = (f:GetWidth() * .54), f:GetHeight()

		local left = f:CreateTexture(nil, "HIGHLIGHT")
		left:SetWidth(width)
		left:SetHeight(height)
		left:SetPoint("LEFT", f, "CENTER")
		left:SetTexture(1, 1, 1, 0.3)
		left:SetHeight(16)

		local right = f:CreateTexture(nil, "HIGHLIGHT")
		right:SetWidth(width)
		right:SetHeight(height)
		right:SetPoint("RIGHT", f, "CENTER")
		right:SetTexture(1, 1, 1, 0.3)
		right:SetHeight(16)
	end

	for i = 1, 32 do
		StyleButton(_G["ChatMenuButton"..i])
		StyleButton(_G["EmoteMenuButton"..i])
		StyleButton(_G["LanguageMenuButton"..i])
		StyleButton(_G["VoiceMacroMenuButton"..i])
	end

	-- Static Popups
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local staticPopup = _G["StaticPopup"..i]
		local itemFrameBox = _G["StaticPopup"..i.."EditBox"]
		local closeButton = _G["StaticPopup"..i.."CloseButton"]
		local wideBox = _G["StaticPopup"..i.."WideEditBox"]

		E:SetTemplate(staticPopup, "Transparent")

		S:HandleEditBox(itemFrameBox)
		itemFrameBox.backdrop:SetPoint("TOPLEFT", -2, -4)
		itemFrameBox.backdrop:SetPoint("BOTTOMRIGHT", 2, 4)

		for k = 1, itemFrameBox:GetNumRegions() do
			local region = select(k, itemFrameBox:GetRegions())
			if(region and region:GetObjectType() == "Texture") then
				if region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Left" or region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Right" then
					E:Kill(region)
				end
			end
		end

		E:StripTextures(closeButton)
		S:HandleCloseButton(closeButton)

		select(8, wideBox:GetRegions()):Hide()
		S:HandleEditBox(wideBox)
		wideBox:SetHeight(22)

		for j = 1, 2 do
			S:HandleButton(_G["StaticPopup"..i.."Button"..j])
		end
	end

	-- reskin all esc/menu buttons
	local BlizzardMenuButtons = {
		"Options",
		"SoundOptions",
		"UIOptions",
		"Keybindings",
		"Macros",
		"Logout",
		"Quit",
		"Continue",
	}

	for i = 1, getn(BlizzardMenuButtons) do
		local ElvuiMenuButtons = _G["GameMenuButton"..BlizzardMenuButtons[i]]
		if ElvuiMenuButtons then
			S:HandleButton(ElvuiMenuButtons)
		end
	end

	-- hide header textures and move text/buttons.
	local BlizzardHeader = {
		"GameMenuFrame",
		"UIOptionsFrame",
		"SoundOptionsFrame",
		"OptionsFrame",
	}

	for i = 1, getn(BlizzardHeader) do
		local title = _G[BlizzardHeader[i].."Header"]
		if title then
			title:SetTexture("")
			title:ClearAllPoints()
			if title == _G["GameMenuFrameHeader"] then
				title:SetPoint("TOP", GameMenuFrame, 0, 7)
			else
				title:SetPoint("TOP", BlizzardHeader[i], 0, 0)
			end
		end
	end

	-- here we reskin all "normal" buttons
	local BlizzardButtons = {
		"OptionsFrameOkay",
		"OptionsFrameCancel",
		"OptionsFrameDefaults",
		"SoundOptionsFrameOkay",
		"SoundOptionsFrameCancel",
		"SoundOptionsFrameDefaults",
		"UIOptionsFrameDefaults",
		"UIOptionsFrameOkay",
		"UIOptionsFrameCancel",
		"StackSplitOkayButton",
		"StackSplitCancelButton",
		"RolePollPopupAcceptButton"
	}

	for i = 1, getn(BlizzardButtons) do
		local ElvuiButtons = _G[BlizzardButtons[i]]
		if ElvuiButtons then
			S:HandleButton(ElvuiButtons)
		end
	end

	-- if a button position is not really where we want, we move it here
	OptionsFrameCancel:ClearAllPoints()
	OptionsFrameCancel:SetPoint("BOTTOMLEFT",OptionsFrame,"BOTTOMRIGHT",-105,15)
	OptionsFrameOkay:ClearAllPoints()
	OptionsFrameOkay:SetPoint("RIGHT",OptionsFrameCancel,"LEFT",-4,0)
	SoundOptionsFrameOkay:ClearAllPoints()
	SoundOptionsFrameOkay:SetPoint("RIGHT",SoundOptionsFrameCancel,"LEFT",-4,0)
	UIOptionsFrameOkay:ClearAllPoints()
	UIOptionsFrameOkay:SetPoint("RIGHT",UIOptionsFrameCancel,"LEFT", -4,0)

	-- others
	ZoneTextFrame:ClearAllPoints()
	ZoneTextFrame:SetPoint("TOP", UIParent, 0, -128)

	E:StripTextures(CoinPickupFrame)
	E:SetTemplate(CoinPickupFrame, "Transparent")

	S:HandleButton(CoinPickupOkayButton)
	S:HandleButton(CoinPickupCancelButton)

	StackSplitFrame:GetRegions():Hide()

	-- Declension frame
	if GetLocale() == "ruRU" then
		DeclensionFrame:SetTemplate("Transparent")

		S:HandleNextPrevButton(DeclensionFrameSetPrev)
		S:HandleNextPrevButton(DeclensionFrameSetNext)
		S:HandleButton(DeclensionFrameOkayButton)
		S:HandleButton(DeclensionFrameCancelButton)

		for i = 1, RUSSIAN_DECLENSION_PATTERNS do
			local editBox = _G["DeclensionFrameDeclension"..i.."Edit"]
			if editBox then
				E:StripTextures(editBox)
				S:HandleEditBox(editBox)
			end
		end
	end

	-- mac menu/option panel, made by affli.
	if IsMacClient() then
		S:HandleButton(GameMenuButtonMacOptions)

		-- Skin main frame and reposition the header
		MacOptionsFrame:SetTemplate("Default", true)
		MacOptionsFrameHeader:SetTexture("")
		MacOptionsFrameHeader:ClearAllPoints()
		MacOptionsFrameHeader:SetPoint("TOP", MacOptionsFrame, 0, 0)

		S:HandleDropDownBox(MacOptionsFrameResolutionDropDown)
		S:HandleDropDownBox(MacOptionsFrameFramerateDropDown)
		S:HandleDropDownBox(MacOptionsFrameCodecDropDown)

		S:HandleSliderFrame(MacOptionsFrameQualitySlider)

		for i = 1, 8 do
			S:HandleCheckBox(_G["MacOptionsFrameCheckButton"..i])
		end

		--Skin internal frames
		MacOptionsFrameMovieRecording:SetTemplate("Default", true)
		MacOptionsITunesRemote:SetTemplate("Default", true)

		--Skin buttons
		S:HandleButton(MacOptionsFrameCancel)
		S:HandleButton(MacOptionsFrameOkay)
		S:HandleButton(MacOptionsButtonKeybindings)
		S:HandleButton(MacOptionsFrameDefaults)
		S:HandleButton(MacOptionsButtonCompress)

		--Reposition and resize buttons
		local tPoint, tRTo, tRP, _, tY = MacOptionsButtonCompress:GetPoint()
		MacOptionsButtonCompress:SetWidth(136)
		MacOptionsButtonCompress:ClearAllPoints()
		MacOptionsButtonCompress:SetPoint(tPoint, tRTo, tRP, 4, tY)

		MacOptionsFrameCancel:SetWidth(96)
		MacOptionsFrameCancel:SetHeight(22)
		tPoint, tRTo, tRP, _, tY = MacOptionsFrameCancel:GetPoint()
		MacOptionsFrameCancel:ClearAllPoints()
		MacOptionsFrameCancel:SetPoint(tPoint, tRTo, tRP, -14, tY)

		MacOptionsFrameOkay:ClearAllPoints()
		MacOptionsFrameOkay:SetWidth(96)
		MacOptionsFrameOkay:SetHeight(22)
		MacOptionsFrameOkay:SetPoint("LEFT",MacOptionsFrameCancel, -99,0)

		MacOptionsButtonKeybindings:ClearAllPoints()
		MacOptionsButtonKeybindings:SetWidth(96)
		MacOptionsButtonKeybindings:SetHeight(22)
		MacOptionsButtonKeybindings:SetPoint("LEFT",MacOptionsFrameOkay, -99,0)

		MacOptionsFrameDefaults:SetWidth(96)
		MacOptionsFrameDefaults:SetHeight(22)

		MacOptionsCompressFrame:SetTemplate("Default", true)

		MacOptionsCompressFrameHeader:SetTexture("")
		MacOptionsCompressFrameHeader:ClearAllPoints()
		MacOptionsCompressFrameHeader:SetPoint("TOP", MacOptionsCompressFrame, 0, 0)

		S:HandleButton(MacOptionsCompressFrameDelete)
		S:HandleButton(MacOptionsCompressFrameSkip)
		S:HandleButton(MacOptionsCompressFrameCompress)

		MacOptionsCancelFrame:SetTemplate("Default", true)

		MacOptionsCancelFrameHeader:SetTexture("")
		MacOptionsCancelFrameHeader:ClearAllPoints()
		MacOptionsCancelFrameHeader:SetPoint("TOP", MacOptionsCancelFrame, 0, 0)

		S:HandleButton(MacOptionsCancelFrameNo)
		S:HandleButton(MacOptionsCancelFrameYes)
	end

	if GetLocale() == "koKR" then
		S:HandleButton(GameMenuButtonRatings)

		RatingMenuFrame:SetTemplate("Transparent")
		RatingMenuFrameHeader:Kill()
		S:HandleButton(RatingMenuButtonOkay)
	end

	E:StripTextures(OpacityFrame)
	E:SetTemplate(OpacityFrame, "Transparent")

	S:HandleSliderFrame(OpacityFrameSlider)

	--DROPDOWN MENU
	hooksecurefunc("UIDropDownMenu_Initialize", function()
		for i = 1, UIDROPDOWNMENU_MAXLEVELS do
			local buttonBackdrop = _G["DropDownList"..i.."Backdrop"]
			local buttonBackdropMenu = _G["DropDownList"..i.."MenuBackdrop"]

			E:SetTemplate(buttonBackdrop, "Transparent")
			E:SetTemplate(buttonBackdropMenu, "Transparent")

			for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G["DropDownList"..i.."Button"..j]
				local buttonHighlight = _G["DropDownList"..i.."Button"..j.."Highlight"]

				button:SetFrameLevel(buttonBackdrop:GetFrameLevel() + 1)
				buttonHighlight:SetTexture(1, 1, 1, 0.3)
				buttonHighlight:ClearAllPoints()
				buttonHighlight:SetHeight(16)

				if i == 1 then
					buttonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", -8, 0)
					buttonHighlight:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, 0)
				else
					buttonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 0)
					buttonHighlight:SetPoint("TOPRIGHT", button, "TOPRIGHT", -4, 0)
				end
			end
		end
	end)

	hooksecurefunc("L_UIDropDownMenu_Initialize", function()
		for i = 1, 2 do
			local buttonBackdrop = _G["L_DropDownList"..i.."Backdrop"]
			local buttonBackdropMenu = _G["L_DropDownList"..i.."MenuBackdrop"]

			E:SetTemplate(buttonBackdrop, "Transparent")
			E:SetTemplate(buttonBackdropMenu, "Transparent")

			for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G["L_DropDownList"..i.."Button"..j]
				local buttonHighlight = _G["L_DropDownList"..i.."Button"..j.."Highlight"]

				button:SetFrameLevel(buttonBackdrop:GetFrameLevel() + 1)
				buttonHighlight:SetTexture(1, 1, 1, 0.3)
				buttonHighlight:ClearAllPoints()
				buttonHighlight:SetHeight(16)

				if i == 1 then
					buttonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 0)
					buttonHighlight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 4, 0)
				else
					buttonHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 0)
					buttonHighlight:SetPoint("TOPRIGHT", button, "TOPRIGHT", -4, 0)
				end
			end
		end
	end)

	-- Interface Options
	UIOptionsFrame:SetScript("OnShow", function()
		UIOptionsFrame_Load()

		E:Kill(UIOptionsBlackground)

		E:StripTextures(UIOptionsFrame, true)

		UIOptionsFrame:EnableMouse(0)
		UIOptionsFrame:SetScale(UIParent:GetScale())
	end)

	local UIOptions = {
		"BasicOptions",
		"BasicOptionsGeneral",
		"BasicOptionsDisplay",
		"BasicOptionsCamera",
		"BasicOptionsHelp",
		"AdvancedOptions",
		"AdvancedOptionsActionBars",
		"AdvancedOptionsChat",
		"AdvancedOptionsRaid",
		"AdvancedOptionsCombatText",
	}

	for i = 1, getn(UIOptions) do
		local options = _G[UIOptions[i]]
		if options then
			E:SetTemplate(options, "Transparent")
		end
	end

	local interfacetab = {
		"UIOptionsFrameTab1",
		"UIOptionsFrameTab2",
	}
	for i = 1, getn(interfacetab) do
		local itab = _G[interfacetab[i]]
		if itab then
			E:StripTextures(itab)
			S:HandleTab(itab)
			E:SetTemplate(itab.backdrop, "Transparent")
			itab.backdrop:SetPoint("TOPLEFT", 10, E.PixelMode and -4 or -6)
			itab.backdrop:SetPoint("BOTTOMRIGHT", -10, E.PixelMode and -4 or -6)
		end
	end

	OptionsFrameDefaults:ClearAllPoints()
	OptionsFrameDefaults:SetPoint("TOPLEFT", OptionsFrame, "BOTTOMLEFT", 15, 36)

	for i = 1, 69 do
		local UIOptionsFrameCheckBox = _G["UIOptionsFrameCheckButton"..i]
		if UIOptionsFrameCheckBox then
			S:HandleCheckBox(UIOptionsFrameCheckBox)
		end
	end

	local interfacedropdown ={
		"CombatTextDropDown",
		"TargetofTargetDropDown",
		"CameraDropDown",
		"ClickCameraDropDown"
	}
	for i = 1, getn(interfacedropdown) do
		local idropdown = _G["UIOptionsFrame"..interfacedropdown[i]]
		if idropdown then
			S:HandleDropDownBox(idropdown)
		end
	end

	S:HandleButton(UIOptionsFrameResetTutorials)

	local optioncheckbox = {
		"OptionsFrameCheckButton1",
		"OptionsFrameCheckButton2",
		"OptionsFrameCheckButton3",
		"OptionsFrameCheckButton4",
		"OptionsFrameCheckButton5",
		"OptionsFrameCheckButton6",
		"OptionsFrameCheckButton7",
		"OptionsFrameCheckButton8",
		"OptionsFrameCheckButton9",
		"OptionsFrameCheckButton10",
		"OptionsFrameCheckButton11",
		"OptionsFrameCheckButton12",
		"OptionsFrameCheckButton13",
		"OptionsFrameCheckButton14",
		"OptionsFrameCheckButton15",
		"OptionsFrameCheckButton16",
		"OptionsFrameCheckButton17",
		"OptionsFrameCheckButton18",
		"OptionsFrameCheckButton19",
		"SoundOptionsFrameCheckButton1",
		"SoundOptionsFrameCheckButton2",
		"SoundOptionsFrameCheckButton3",
		"SoundOptionsFrameCheckButton4",
		"SoundOptionsFrameCheckButton5",
		"SoundOptionsFrameCheckButton6",
		"SoundOptionsFrameCheckButton7",
		"SoundOptionsFrameCheckButton8",
		"SoundOptionsFrameCheckButton9",
		"SoundOptionsFrameCheckButton10",
		"SoundOptionsFrameCheckButton11"
	}
	for i = 1, getn(optioncheckbox) do
		local ocheckbox = _G[optioncheckbox[i]]
		if ocheckbox then
			S:HandleCheckBox(ocheckbox)
		end
	end

	SoundOptionsFrameCheckButton1:SetPoint("TOPLEFT", "SoundOptionsFrame", "TOPLEFT", 16, -15)

	local optiondropdown = {
		"OptionsFrameResolutionDropDown",
		"OptionsFrameRefreshDropDown",
		"OptionsFrameMultiSampleDropDown",
		"SoundOptionsOutputDropDown",
	}
	for i = 1, getn(optiondropdown) do
		local odropdown = _G[optiondropdown[i]]
		if odropdown then
			S:HandleDropDownBox(odropdown, i == 3 and 195 or 165)
		end
	end

	for i = 1, 4 do
		local UIOptionsFrameSlider = _G["UIOptionsFrameSlider"..i]
		if UIOptionsFrameSlider then
			S:HandleSliderFrame(UIOptionsFrameSlider)
		end
	end

	-- Video Options Sliders
	for i = 1, 9 do
		S:HandleSliderFrame(_G["OptionsFrameSlider"..i])
	end

	-- Sound Options Sliders
	for i = 1, 4 do
		S:HandleSliderFrame(_G["SoundOptionsFrameSlider"..i])
	end

end

S:AddCallback("SkinMisc", LoadSkin)