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
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.misc ~= true then return end

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

	-- ChatMenus
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
				E:Point(this, "BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 35)
			end)
		else
			HookScript(_G[ChatMenus[i]], "OnShow", function()
				E:SetTemplate(this, "Transparent", true)
				this:SetBackdropColor(unpack(E["media"].backdropfadecolor))
			end)
		end
	end

	for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
		E:StyleButton(_G["ChatMenuButton"..i])
		E:StyleButton(_G["EmoteMenuButton"..i])
		E:StyleButton(_G["LanguageMenuButton"..i])
		E:StyleButton(_G["VoiceMacroMenuButton"..i])
	end

	-- UIDropDownMenu
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
				buttonHighlight:SetAllPoints(button)

				if i == 1 then
					E:Point(buttonHighlight, "TOPLEFT", button, "TOPLEFT", -8, 0)
					E:Point(buttonHighlight, "TOPRIGHT", button, "TOPRIGHT", -8, 0)
				else
					E:Point(buttonHighlight, "TOPLEFT", button, "TOPLEFT", -4, 0)
					E:Point(buttonHighlight, "TOPRIGHT", button, "TOPRIGHT", -4, 0)
				end
			end
		end
	end)

	-- L_UIDropDownMenu
	hooksecurefunc("L_UIDropDownMenu_Initialize", function()
		for i = 1, 2 do
			local buttonBackdrop = _G["L_DropDownList"..i.."Backdrop"]
			local buttonBackdropMenu = _G["L_DropDownList"..i.."MenuBackdrop"]

			E:SetTemplate(buttonBackdrop, "Transparent")
			E:SetTemplate(buttonBackdropMenu, "Transparent")

			if i == 2 then
				E:Point(buttonBackdropMenu, "TOPRIGHT", -4, 0)
			end

			for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G["L_DropDownList"..i.."Button"..j]
				local buttonHighlight = _G["L_DropDownList"..i.."Button"..j.."Highlight"]

				button:SetFrameLevel(buttonBackdrop:GetFrameLevel() + 1)
				buttonHighlight:SetTexture(1, 1, 1, 0.3)
				buttonHighlight:SetAllPoints(button)

				if i == 2 then
					E:Point(buttonHighlight, "TOPLEFT", button, "TOPLEFT", -8, 0)
					E:Point(buttonHighlight, "TOPRIGHT", button, "TOPRIGHT", 0, 0)
				end
			end
		end
	end)

	-- Kill the nVidia logo
	local _, _, nVidiaLogo = OptionsFrame:GetRegions()
	if nVidiaLogo:GetObjectType() == "Texture" then
		E:Kill(nVidiaLogo)
	end

	-- Static Popups
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local staticPopup = _G["StaticPopup"..i]
		local itemFrameBox = _G["StaticPopup"..i.."EditBox"]
		local closeButton = _G["StaticPopup"..i.."CloseButton"]
		local wideBox = _G["StaticPopup"..i.."WideEditBox"]

		E:SetTemplate(staticPopup, "Transparent")

		itemFrameBox:DisableDrawLayer("BACKGROUND")

		S:HandleEditBox(itemFrameBox)
		E:Point(itemFrameBox.backdrop, "TOPLEFT", -2, -4)
		E:Point(itemFrameBox.backdrop, "BOTTOMRIGHT", 2, 4)

		E:StripTextures(closeButton)
		S:HandleCloseButton(closeButton)

		local _, _, _, _, _, _, _, region = wideBox:GetRegions()
		if region then
			region:Hide()
		end
		 --select(8, wideBox:GetRegions()):Hide()
		S:HandleEditBox(wideBox)
		E:Height(wideBox, 22)

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
		"SoundOptionsFrame",
		"OptionsFrame",
	}

	for i = 1, getn(BlizzardHeader) do
		local title = _G[BlizzardHeader[i].."Header"]
		if title then
			title:SetTexture("")
			title:ClearAllPoints()
			if title == _G["GameMenuFrameHeader"] then
				E:Point(title, "TOP", GameMenuFrame, 0, 7)
			else
				E:Point(title, "TOP", BlizzardHeader[i], 0, 0)
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
	E:Point(OptionsFrameCancel, "BOTTOMLEFT",OptionsFrame,"BOTTOMRIGHT",-105,15)
	OptionsFrameOkay:ClearAllPoints()
	E:Point(OptionsFrameOkay, "RIGHT",OptionsFrameCancel,"LEFT",-4,0)
	SoundOptionsFrameOkay:ClearAllPoints()
	E:Point(SoundOptionsFrameOkay, "RIGHT",SoundOptionsFrameCancel,"LEFT",-4,0)
	UIOptionsFrameOkay:ClearAllPoints()
	E:Point(UIOptionsFrameOkay, "RIGHT",UIOptionsFrameCancel,"LEFT", -4,0)

	-- others
	ZoneTextFrame:ClearAllPoints()
	E:Point(ZoneTextFrame, "TOP", UIParent, 0, -128)

	E:StripTextures(CoinPickupFrame)
	E:SetTemplate(CoinPickupFrame, "Transparent")

	S:HandleButton(CoinPickupOkayButton)
	S:HandleButton(CoinPickupCancelButton)

	-- Stack Split Frame
	StackSplitFrame:GetRegions():Hide()

	StackSplitFrame.bg1 = CreateFrame("Frame", nil, StackSplitFrame)
	E:SetTemplate(StackSplitFrame.bg1, "Transparent")
	E:Point(StackSplitFrame.bg1, "TOPLEFT", 10, -15)
	E:Point(StackSplitFrame.bg1, "BOTTOMRIGHT", -10, 55)
	StackSplitFrame.bg1:SetFrameLevel(StackSplitFrame.bg1:GetFrameLevel() - 1)

	E:StripTextures(OpacityFrame)
	E:SetTemplate(OpacityFrame, "Transparent")

	S:HandleSliderFrame(OpacityFrameSlider)

	-- Interface Options
	UIOptionsFrame:SetParent(E.UIParent)
	UIOptionsFrame:EnableMouse(false)

	hooksecurefunc("UIOptionsFrame_Load", function()
		E:StripTextures(UIOptionsFrame)
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
		E:SetTemplate(options, "Transparent")
	end

	BasicOptions.backdrop = CreateFrame("Frame", nil, BasicOptions)
	E:Point(BasicOptions.backdrop, "TOPLEFT", BasicOptionsGeneral, -20, 35)
	E:Point(BasicOptions.backdrop, "BOTTOMRIGHT", BasicOptionsHelp, 20, -130)
	E:SetTemplate(BasicOptions.backdrop, "Transparent")

	AdvancedOptions.backdrop = CreateFrame("Frame", nil, AdvancedOptions)
	E:Point(AdvancedOptions.backdrop, "TOPLEFT", BasicOptionsGeneral, -20, 35)
	E:Point(AdvancedOptions.backdrop, "BOTTOMRIGHT", BasicOptionsHelp, 20, -130)
	E:SetTemplate(AdvancedOptions.backdrop, "Transparent")

	for i = 1, 2 do
		local tab = _G["UIOptionsFrameTab"..i]
		E:StripTextures(tab, true)
		E:CreateBackdrop(tab, "Transparent")

		tab:SetFrameLevel(tab:GetParent():GetFrameLevel() + 2)
		tab.backdrop:SetFrameLevel(tab:GetParent():GetFrameLevel() + 1)

		E:Point(tab.backdrop, "TOPLEFT", 5, E.PixelMode and -14 or -16)
		E:Point(tab.backdrop, "BOTTOMRIGHT", -5, E.PixelMode and -4 or -6)

		tab:SetScript("OnClick", function()
			PanelTemplates_Tab_OnClick(UIOptionsFrame)
			if AdvancedOptions:IsShown() then
				BasicOptions:Show()
				AdvancedOptions:Hide()
			else
				BasicOptions:Hide()
				AdvancedOptions:Show()
			end
			PlaySound("igCharacterInfoTab")
		end)

		HookScript(tab, "OnEnter", S.SetModifiedBackdrop)
		HookScript(tab, "OnLeave", S.SetOriginalBackdrop)
	end

	for _, child in ipairs({UIOptionsFrame:GetChildren()}) do
		if child.GetPushedTexture and child:GetPushedTexture() and not child:GetName() then
			child:SetFrameLevel(UIOptionsFrame:GetFrameLevel() + 2)
			S:HandleCloseButton(child, UIOptionsFrame.backdrop)
		end
	end

	--[[for i = 1, UIOptionsFrame:GetNumChildren() do
		local child = select(i, UIOptionsFrame:GetChildren())
		if child.GetPushedTexture and child:GetPushedTexture() and not child:GetName() then
			child:SetFrameLevel(UIOptionsFrame:GetFrameLevel() + 2)
			S:HandleCloseButton(child, UIOptionsFrame.backdrop)
		end
	end--]]

	OptionsFrameDefaults:ClearAllPoints()
	E:Point(OptionsFrameDefaults, "TOPLEFT", OptionsFrame, "BOTTOMLEFT", 15, 36)

	S:HandleButton(UIOptionsFrameResetTutorials)

	E:Point(SoundOptionsFrameCheckButton1, "TOPLEFT", "SoundOptionsFrame", "TOPLEFT", 16, -15)

	-- Interface Options Frame Dropdown
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

	-- Video Options Frame Dropdown
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

	-- Interface Options Checkboxes
	for index, value in UIOptionsFrameCheckButtons do
		local UIOptionsFrameCheckBox = _G["UIOptionsFrameCheckButton"..value.index]
		if UIOptionsFrameCheckBox then
			S:HandleCheckBox(UIOptionsFrameCheckBox)
		end
	end

	-- Video Options Checkboxes
	for index, value in OptionsFrameCheckButtons do
		local OptionsFrameCheckButton = _G["OptionsFrameCheckButton"..value.index]
		if OptionsFrameCheckButton then
			S:HandleCheckBox(OptionsFrameCheckButton)
		end
	end

	-- Sound Options Checkboxes
	for index, value in SoundOptionsFrameCheckButtons do
		local SoundOptionsFrameCheckButton = _G["SoundOptionsFrameCheckButton"..value.index]
		if SoundOptionsFrameCheckButton then
			S:HandleCheckBox(SoundOptionsFrameCheckButton)
		end
	end

	-- Interface Options Sliders
	for i, v in UIOptionsFrameSliders do
		S:HandleSliderFrame(_G["UIOptionsFrameSlider"..i])
	end

	-- Video Options Sliders
	for i, v in OptionsFrameSliders do
		S:HandleSliderFrame(_G["OptionsFrameSlider"..i])
	end

	-- Sound Options Sliders
	for i, v in SoundOptionsFrameSliders do
		S:HandleSliderFrame(_G["SoundOptionsFrameSlider"..i])
	end
end

S:AddCallback("SkinMisc", LoadSkin)
