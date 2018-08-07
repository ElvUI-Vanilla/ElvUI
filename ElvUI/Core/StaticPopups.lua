local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Cache global variables
--Lua functions
local _G = _G
local pairs, assert = pairs, assert
local getn, tremove, tContains, tinsert, wipe = table.getn, tremove, tContains, tinsert, table.wipe
local lower = string.lower
--WoW API / Variables
local CreateFrame = CreateFrame
local UnitIsDeadOrGhost, InCinematic = UnitIsDeadOrGhost, InCinematic
local GetBindingFromClick, RunBinding = GetBindingFromClick, RunBinding
local PurchaseSlot, GetBankSlotCost = PurchaseSlot, GetBankSlotCost
local MoneyFrame_Update = MoneyFrame_Update
local SetCVar, DisableAddOn = SetCVar, DisableAddOn
local ReloadUI, PlaySound, StopMusic = ReloadUI, PlaySound, StopMusic
local StaticPopup_Resize = StaticPopup_Resize

E.PopupDialogs = {}
E.StaticPopup_DisplayedFrames = {}

E.PopupDialogs["ELVUI_UPDATE_AVAILABLE"] = {
	text = L["ElvUI is five or more revisions out of date. You can download the newest version from https://github.com/ElvUI-Vanilla/ElvUI/"],
	hasEditBox = 1,
	OnShow = function()
		this.editBox:SetAutoFocus(false)
		this.editBox.width = this.editBox:GetWidth()
		E:Width(this.editBox, 220)
		this.editBox:SetText("https://github.com/ElvUI-Vanilla/ElvUI")
		this.editBox:HighlightText()
	end,
	OnHide = function()
		E:Width(this.editBox, this.editBox.width or 50)
		this.editBox.width = nil
	end,
	hideOnEscape = 1,
	button1 = OKAY,
	OnAccept = E.noop,
	EditBoxOnEnterPressed = function()
		this:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide()
	end,
	EditBoxOnTextChanged = function()
		if this:GetText() ~= "https://github.com/ElvUI-Vanilla/ElvUI" then
			this:SetText("https://github.com/ElvUI-Vanilla/ElvUI")
		end
		this:HighlightText()
		this:ClearFocus()
	end,
	OnEditFocusGained = function()
		this:HighlightText()
	end,
	showAlert = 1
}

E.PopupDialogs["CLIQUE_ADVERT"] = {
	text = L["Using the healer layout it is highly recommended you download the addon Clique if you wish to have the click-to-heal function."],
	button1 = YES,
	OnAccept = E.noop,
	showAlert = 1
}

E.PopupDialogs["CONFIRM_LOSE_BINDING_CHANGES"] = {
	text = CONFIRM_LOSE_BINDING_CHANGES,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		E:GetModule("ActionBars"):ChangeBindingProfile()
		E:GetModule("ActionBars").bindingsChanged = nil
	end,
	OnCancel = function()
		if ElvUIBindPopupWindowCheckButton:GetChecked() then
			ElvUIBindPopupWindowCheckButton:SetChecked()
		else
			ElvUIBindPopupWindowCheckButton:SetChecked(1)
		end
	end,
	timeout = 0,
	whileDead = 1,
	showAlert = 1
}

E.PopupDialogs["TUKUI_ELVUI_INCOMPATIBLE"] = {
	text = L["Oh lord, you have got ElvUI and Tukui both enabled at the same time. Select an addon to disable."],
	OnAccept = function() DisableAddOn("ElvUI") ReloadUI() end,
	OnCancel = function() DisableAddOn("Tukui") ReloadUI() end,
	button1 = "ElvUI",
	button2 = "Tukui",
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["DISABLE_INCOMPATIBLE_ADDON"] = {
	text = L["Do you swear not to post in technical support about something not working without first disabling the addon/module combination first?"],
	OnAccept = function() E.global.ignoreIncompatible = true end,
	OnCancel = function() E:StaticPopup_Hide("DISABLE_INCOMPATIBLE_ADDON") E:StaticPopup_Show("INCOMPATIBLE_ADDON", E.PopupDialogs["INCOMPATIBLE_ADDON"].addon, E.PopupDialogs["INCOMPATIBLE_ADDON"].module) end,
	button1 = L["I Swear"],
	button2 = DECLINE,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["INCOMPATIBLE_ADDON"] = {
	text = L["INCOMPATIBLE_ADDON"],
	OnAccept = function() DisableAddOn(E.PopupDialogs["INCOMPATIBLE_ADDON"].addon) ReloadUI() end,
	OnCancel = function() E.private[lower(E.PopupDialogs["INCOMPATIBLE_ADDON"].module)].enable = false ReloadUI() end,
	button3 = L["Disable Warning"],
	OnAlt = function ()
		E:StaticPopup_Hide("INCOMPATIBLE_ADDON")
		E:StaticPopup_Show("DISABLE_INCOMPATIBLE_ADDON")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["PIXELPERFECT_CHANGED"] = {
	text = L["You have changed the Thin Border Theme option. You will have to complete the installation process to remove any graphical bugs."],
	button1 = ACCEPT,
	OnAccept = E.noop,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["CONFIGAURA_SET"] = {
	text = L["Because of the mass confusion caused by the new aura system I've implemented a new step to the installation process. This is optional. If you like how your auras are setup go to the last step and click finished to not be prompted again. If for some reason you are prompted repeatedly please restart your game."],
	button1 = ACCEPT,
	OnAccept = E.noop,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["QUEUE_TAINT"] = {
	text = L["You have changed your UIScale, however you still have the AutoScale option enabled in ElvUI. Press accept if you would like to disable the Auto Scale option."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["FAILED_UISCALE"] = {
	text = L["You have changed your UIScale, however you still have the AutoScale option enabled in ElvUI. Press accept if you would like to disable the Auto Scale option."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() E.global.general.autoScale = false ReloadUI() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["CONFIG_RL"] = {
	text = L["One or more of the changes you have made require a ReloadUI."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["GLOBAL_RL"] = {
	text = L["One or more of the changes you have made will effect all characters using this addon. You will have to reload the user interface to see the changes you have made."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["PRIVATE_RL"] = {
	text = L["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["KEYBIND_MODE"] = {
	text = L["Hover your mouse over any actionbutton or spellbook button to bind it. Press the escape key or right click to clear the current actionbutton's keybinding."],
	button1 = L["Save"],
	button2 = L["Discard"],
	OnAccept = function() E:GetModule("ActionBars"):DeactivateBindMode(true) end,
	OnCancel = function() E:GetModule("ActionBars"):DeactivateBindMode(false) end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs["DELETE_GRAYS"] = {
	text = format("|cffff0000%s|r", L["Delete gray items?"]),
	button1 = YES,
	button2 = NO,
	OnAccept = function() E:GetModule("Bags"):VendorGrays(true) end,
	OnShow = function()
		MoneyFrame_Update(this:GetName().."MoneyFrame", E.PopupDialogs["DELETE_GRAYS"].Money)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false,
	hasMoneyFrame = 1
}

E.PopupDialogs["BUY_BANK_SLOT"] = {
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = PurchaseSlot,
	OnShow = function()
		MoneyFrame_Update(this:GetName().."MoneyFrame", GetBankSlotCost())
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
}

E.PopupDialogs["CANNOT_BUY_BANK_SLOT"] = {
	text = L["Can't buy anymore slots!"],
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["NO_BANK_BAGS"] = {
	text = L["You must purchase a bank slot first!"],
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["RESETUI_CHECK"] = {
	text = L["Are you sure you want to reset every mover back to it's default position?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		E:ResetAllUI()
	end,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["HARLEM_SHAKE"] = {
	text = L["ElvUI needs to perform database optimizations please be patient."],
	button1 = OKAY,
	OnAccept = function()
		if E.isMassiveShaking then
			E:StopHarlemShake()
		else
			E:BeginHarlemShake()
			return true
		end
	end,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["HELLO_KITTY"] = {
	text = L["ElvUI needs to perform database optimizations please be patient."],
	button1 = OKAY,
	OnAccept = function()
		E:SetupHelloKitty()
	end,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["HELLO_KITTY_END"] = {
	text = L["Do you enjoy the new ElvUI?"],
	button1 = L["Yes, Keep Changes!"],
	button2 = L["No, Revert Changes!"],
	OnAccept = function()
		E:Print(L["Type /hellokitty to revert to old settings."])
		StopMusic()
		SetCVar("Sound_EnableAllSound", E.oldEnableAllSound)
		SetCVar("Sound_EnableMusic", E.oldEnableMusic)
	end,
	OnCancel = function()
		E:RestoreHelloKitty()
		StopMusic()
		SetCVar("Sound_EnableAllSound", E.oldEnableAllSound)
		SetCVar("Sound_EnableMusic", E.oldEnableMusic)
	end,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["DISBAND_RAID"] = {
	text = L["Are you sure you want to disband the group?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() E:GetModule("Misc"):DisbandRaidGroup() end,
	timeout = 0,
	whileDead = 1
}

E.PopupDialogs["CONFIRM_LOOT_DISTRIBUTION"] = {
	text = CONFIRM_LOOT_DISTRIBUTION,
	button1 = YES,
	button2 = NO,
	timeout = 0,
	hideOnEscape = 1
}

E.PopupDialogs["RESET_PROFILE_PROMPT"] = {
	text = L["Are you sure you want to reset all the settings on this profile?"],
	button1 = YES,
	button2 = NO,
	timeout = 0,
	hideOnEscape = 1,
	OnAccept = function() E:ResetProfile() end
}

E.PopupDialogs["APPLY_FONT_WARNING"] = {
	text = L["Are you sure you want to apply this font to all ElvUI elements?"],
	OnAccept = function()
		local font = E.db.general.font
		local fontSize = E.db.general.fontSize

		E.db.bags.itemLevelFont = font
		E.db.bags.itemLevelFontSize = fontSize
		E.db.bags.countFont = font
		E.db.bags.countFontSize = fontSize
		E.db.nameplates.font = font
		E.db.nameplates.fontSize = fontSize
		E.db.actionbar.font = font
		E.db.actionbar.fontSize = fontSize
		E.db.auras.font = font
		E.db.auras.fontSize = fontSize
		E.db.chat.font = font
		E.db.chat.fontSize = fontSize
		E.db.chat.tabFont = font
		E.db.chat.tapFontSize = fontSize
		E.db.datatexts.font = font
		E.db.datatexts.fontSize = fontSize
		E.db.tooltip.font = font
		E.db.tooltip.fontSize = fontSize
		E.db.tooltip.headerFontSize = fontSize
		E.db.tooltip.textFontSize = fontSize
		E.db.tooltip.smallTextFontSize = fontSize
		E.db.tooltip.healthBar.font = font
		E.db.tooltip.healthBar.fontSize = fontSize
		E.db.unitframe.font = font
		E.db.unitframe.fontSize = fontSize
		E.db.unitframe.units.party.rdebuffs.font = font
		E.db.unitframe.units.raid.rdebuffs.font = font
		-- E.db.unitframe.units.raid40.rdebuffs.font = font

		E:UpdateAll(true)
	end,
	OnCancel = function() E:StaticPopup_Hide("APPLY_FONT_WARNING") end,
	button1 = YES,
	button2 = CANCEL,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = false
}

local MAX_STATIC_POPUPS = 4

function E:StaticPopup_OnShow()
	PlaySound("igMainMenuOpen")

	local dialog = E.PopupDialogs[this.which]
	local OnShow = dialog.OnShow
	if OnShow then
		OnShow(this.data)
	end
	if dialog.enterClicksFirstButton then
		this:SetScript("OnKeyDown", E.StaticPopup_OnKeyDown)
	end
end

function E:StaticPopup_EscapePressed()
	local closed = nil
	for _, frame in pairs(E.StaticPopup_DisplayedFrames) do
		if frame:IsShown() and frame.hideOnEscape then
			local standardDialog = E.PopupDialogs[frame.which]
			if standardDialog then
				local OnCancel = standardDialog.OnCancel
				local noCancelOnEscape = standardDialog.noCancelOnEscape
				if OnCancel and not noCancelOnEscape then
					OnCancel(frame, frame.data, "clicked")
				end
				frame:Hide()
			else
				E:StaticPopupSpecial_Hide(frame)
			end
			closed = 1
		end
	end
	return closed
end

function E:StaticPopupSpecial_Hide(frame)
	frame:Hide()
	E:StaticPopup_CollapseTable()
end

function E:StaticPopup_CollapseTable()
	local displayedFrames = E.StaticPopup_DisplayedFrames
	local index = getn(displayedFrames)
	while((index >= 1) and (not displayedFrames[index]:IsShown())) do
		tremove(displayedFrames, index)
		index = index - 1
	end
end

function E:StaticPopup_SetUpPosition(dialog)
	if not tContains(E.StaticPopup_DisplayedFrames, dialog) then
		local lastFrame = E.StaticPopup_DisplayedFrames[getn(E.StaticPopup_DisplayedFrames)]
		if lastFrame then
			dialog:SetPoint("TOP", lastFrame, "BOTTOM", 0, -4)
		else
			dialog:SetPoint("TOP", E.UIParent, "TOP", 0, -100)
		end
		tinsert(E.StaticPopup_DisplayedFrames, dialog)
	end
end

function E:StaticPopupSpecial_Show(frame)
	if frame.exclusive then
		E:StaticPopup_HideExclusive()
	end
	E:StaticPopup_SetUpPosition(frame)
	frame:Show()
end

function E:StaticPopupSpecial_Hide(frame)
	frame:Hide()
	E:StaticPopup_CollapseTable()
end

function E:StaticPopup_IsLastDisplayedFrame(frame)
	for i = getn(E.StaticPopup_DisplayedFrames), 1, -1 do
		local popup = E.StaticPopup_DisplayedFrames[i]
		if popup:IsShown() then
			return frame == popup
		end
	end
	return false
end

function E:StaticPopup_OnKeyDown(key)
	if GetBindingFromClick(key) == "TOGGLEGAMEMENU" then
		return E:StaticPopup_EscapePressed()
	elseif GetBindingFromClick(key) == "SCREENSHOT" then
		RunBinding("SCREENSHOT")
		return
	end

	local dialog = E.PopupDialogs[this.which]
	if dialog then
		if arg1 == "ENTER" and dialog.enterClicksFirstButton then
			local frameName = this:GetName()
			local button
			local i = 1
			while true do
				button = _G[frameName.."Button"..i]
				if button then
					if button:IsShown() then
						E:StaticPopup_OnClick(this, i)
						return
					end
					i = i + 1
				else
					break
				end
			end
		end
	end
end

function E:StaticPopup_OnHide()
	PlaySound("igMainMenuClose")

	E:StaticPopup_CollapseTable()

	local dialog = E.PopupDialogs[this.which]
	local OnHide = dialog.OnHide
	if OnHide then
		OnHide(this.data)
	end
	if dialog.enterClicksFirstButton then
		this:SetScript("OnKeyDown", nil)
	end
end

function E:StaticPopup_OnUpdate()
	if this.timeleft and this.timeleft > 0 then
		local which = this.which
		local timeleft = this.timeleft - arg1
		if timeleft <= 0 then
			if not E.PopupDialogs[which].timeoutInformationalOnly then
				this.timeleft = 0
				local OnCancel = E.PopupDialogs[which].OnCancel
				if OnCancel then
					OnCancel(this.data, "timeout")
				end
				this:Hide()
			end
			return
		end
		this.timeleft = timeleft
	end

	if this.startDelay then
		local which = this.which
		local timeleft = this.startDelay - arg1
		if timeleft <= 0 then
			this.startDelay = nil
			local text = _G[this:GetName().."Text"]
			text:SetText(format(E.PopupDialogs[which].text, text.text_arg1, text.text_arg2))
			local button1 = _G[this:GetName().."Button1"]
			button1:Enable()
			StaticPopup_Resize(this, which)
			return
		end
		this.startDelay = timeleft
	end

	local onUpdate = E.PopupDialogs[this.which].OnUpdate
	if onUpdate then
		onUpdate(arg1, this)
	end
end

function E:StaticPopup_OnClick(index)
	if not self:IsShown() then
		return
	end
	local which = self.which
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end
	local hide = true
	if index == 1 then
		local OnAccept = info.OnAccept
		if OnAccept then
			hide = not OnAccept(self, self.data, self.data2)
		end
	elseif index == 3 then
		local OnAlt = info.OnAlt
		if OnAlt then
			OnAlt(self, self.data, "clicked")
		end
	else
		local OnCancel = info.OnCancel
		if OnCancel then
			hide = not OnCancel(self, self.data, "clicked")
		end
	end

	if hide and (which == self.which) and (index ~= 3 or not info.noCloseOnAlt) then
		self:Hide()
	end
end

function E:StaticPopup_EditBoxOnEnterPressed()
	local EditBoxOnEnterPressed, which, dialog
	local parent = this:GetParent()
	if parent.which then
		which = parent.which
		dialog = parent
	elseif parent:GetParent().which then
		which = parent:GetParent().which
		dialog = parent:GetParent()
	end
	EditBoxOnEnterPressed = E.PopupDialogs[which].EditBoxOnEnterPressed
	if EditBoxOnEnterPressed then
		EditBoxOnEnterPressed(this, dialog.data)
	end
end

function E:StaticPopup_EditBoxOnEscapePressed()
	local EditBoxOnEscapePressed = E.PopupDialogs[this:GetParent().which].EditBoxOnEscapePressed
	if EditBoxOnEscapePressed then
		EditBoxOnEscapePressed(this, this:GetParent().data)
	end
end

function E:StaticPopup_EditBoxOnTextChanged(userInput)
	local EditBoxOnTextChanged = E.PopupDialogs[this:GetParent().which].EditBoxOnTextChanged
	if EditBoxOnTextChanged then
		EditBoxOnTextChanged(this, this:GetParent().data)
	end
end

function E:StaticPopup_FindVisible(which, data)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end
	for index = 1, MAX_STATIC_POPUPS, 1 do
		local frame = _G["ElvUI_StaticPopup"..index]
		if (frame:IsShown() and (frame.which == which) and (not info.multiple or (frame.data == data))) then
			return frame
		end
	end
	return nil
end

function E:StaticPopup_Resize(dialog, which)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end

	local name = dialog:GetName()
	local text = _G[name.."Text"]
	local editBox = _G[name.."EditBox"]
	local button1 = _G[name.."Button1"]

	local maxHeightSoFar, maxWidthSoFar = (dialog.maxHeightSoFar or 0), (dialog.maxWidthSoFar or 0)
	local width = 320

	if dialog.numButtons == 3 then
		width = 440
	elseif info.showAlert or info.showAlertGear or info.closeButton then
		width = 420
	elseif info.editBoxWidth and info.editBoxWidth > 260 then
		width = width + (info.editBoxWidth - 260)
	end

	if width > maxWidthSoFar then
		E:Width(dialog, width)
		dialog.maxWidthSoFar = width
	end

	local height = 32 + text:GetHeight() + 8 + button1:GetHeight()
	if info.hasEditBox then
		height = height + 8 + editBox:GetHeight()
	elseif info.hasMoneyFrame then
		height = height + 16
	end

	if height > maxHeightSoFar then
		E:Height(dialog, height)
		dialog.maxHeightSoFar = height
	end
end

function E:StaticPopup_OnEvent()
	self.maxHeightSoFar = 0
	E:StaticPopup_Resize(self, self.which)
end

local tempButtonLocs = {}
function E:StaticPopup_Show(which, text_arg1, text_arg2, data)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end

	if UnitIsDeadOrGhost("player") and not info.whileDead then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	if InCinematic() and not info.interruptCinematic then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	if info.cancels then
		for index = 1, MAX_STATIC_POPUPS, 1 do
			local frame = _G["ElvUI_StaticPopup"..index]
			if (frame:IsShown() and (frame.which == info.cancels)) then
				frame:Hide()
				local OnCancel = E.PopupDialogs[frame.which].OnCancel
				if OnCancel then
					OnCancel(frame, frame.data, "override")
				end
			end
		end
	end

	local dialog = nil
	dialog = E:StaticPopup_FindVisible(which, data)
	if dialog then
		if not info.noCancelOnReuse then
			local OnCancel = info.OnCancel
			if OnCancel then
				OnCancel(dialog, dialog.data, "override")
			end
		end
		dialog:Hide()
	end
	if not dialog then
		local index = 1
		if info.preferredIndex then
			index = info.preferredIndex
		end
		for i = index, MAX_STATIC_POPUPS do
			local frame = _G["ElvUI_StaticPopup"..i]
			if not frame:IsShown() then
				dialog = frame
				break
			end
		end
		if not dialog and info.preferredIndex then
			for i = 1, info.preferredIndex do
				local frame = _G["ElvUI_StaticPopup"..i]
				if not frame:IsShown() then
					dialog = frame
					break
				end
			end
		end
	end
	if not dialog then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	dialog.maxHeightSoFar, dialog.maxWidthSoFar = 0, 0

	local name = dialog:GetName()
	local text = _G[name.."Text"]
	text:SetText(format(info.text, text_arg1, text_arg2))

	if info.closeButton then
		local closeButton = _G[name.."CloseButton"]
		if info.closeButtonIsHide then
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up")
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down")
		else
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		end
		closeButton:Show()
	else
		_G[name.."CloseButton"]:Hide()
	end

	local editBox = _G[name.."EditBox"]
	if info.hasEditBox then
		editBox:Show()

		if info.maxLetters then
			editBox:SetMaxLetters(info.maxLetters)
		end
		if info.maxBytes then
			editBox:SetMaxBytes(info.maxBytes)
		end
		editBox:SetText("")
		if info.editBoxWidth then
			E:Width(editBox, info.editBoxWidth)
		else
			E:Width(editBox, 130)
		end
	else
		editBox:Hide()
	end

	if info.hasMoneyFrame then
		_G[name.."MoneyFrame"]:Show()
	else
		_G[name.."MoneyFrame"]:Hide()
	end

	dialog.which = which
	dialog.timeleft = info.timeout
	dialog.hideOnEscape = info.hideOnEscape
	dialog.exclusive = info.exclusive
	dialog.enterClicksFirstButton = info.enterClicksFirstButton
	dialog.data = data

	local button1 = _G[name.."Button1"]
	local button2 = _G[name.."Button2"]

	do
		assert(getn(tempButtonLocs) == 0)

		tinsert(tempButtonLocs, button1)
		tinsert(tempButtonLocs, button2)

		for i = getn(tempButtonLocs), 1, -1 do
			if info["button"..i] then
				tempButtonLocs[i]:SetText(info["button"..i])
			end
			tempButtonLocs[i]:Hide()
			tempButtonLocs[i]:ClearAllPoints()
			if not (info["button"..i] and (not info["DisplayButton"..i] or info["DisplayButton"..i](dialog))) then
				tremove(tempButtonLocs, i)
			end
		end

		local numButtons = getn(tempButtonLocs)
		dialog.numButtons = numButtons
		if numButtons == 2 then
			tempButtonLocs[1]:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -6, 16)
		elseif numButtons == 1 then
			tempButtonLocs[1]:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 16)
		end

		for i = 1, numButtons do
			if i > 1 then
				tempButtonLocs[i]:SetPoint("LEFT", tempButtonLocs[i-1], "RIGHT", 13, 0)
			end

			local width = tempButtonLocs[i]:GetTextWidth()
			if width > 110 then
				E:Width(tempButtonLocs[i], width + 20)
			else
				E:Width(tempButtonLocs[i], 120)
			end
			tempButtonLocs[i]:Enable()
			tempButtonLocs[i]:Show()
		end

		wipe(tempButtonLocs)
		table.setn(tempButtonLocs, 0)
	end

	local alertIcon = _G[name.."AlertIcon"]
	if info.showAlert then
		alertIcon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
		alertIcon:SetPoint("LEFT", 24, 0)
		alertIcon:Show()
	elseif info.showAlertGear then
		alertIcon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
		alertIcon:SetPoint("LEFT", 24, 0)
		alertIcon:Show()
	else
		alertIcon:SetTexture()
		alertIcon:Hide()
	end

	if info.StartDelay then
		dialog.startDelay = info.StartDelay()
		button1:Disable()
	else
		dialog.startDelay = nil
		button1:Enable()
	end

	E:StaticPopup_SetUpPosition(dialog)
	dialog:Show()

	E:StaticPopup_Resize(dialog, which)

	if info.sound then
		PlaySound(info.sound)
	end

	return dialog
end

function E:StaticPopup_Hide(which, data)
	for index = 1, MAX_STATIC_POPUPS, 1 do
		local dialog = _G["ElvUI_StaticPopup"..index]
		if ((dialog.which == which) and (not data or (data == dialog.data))) then
			dialog:Hide()
		end
	end
end

function E:Contruct_StaticPopups()
	E.StaticPopupFrames = {}

	local S = self:GetModule("Skins")
	for index = 1, MAX_STATIC_POPUPS do
		E.StaticPopupFrames[index] = CreateFrame("Frame", "ElvUI_StaticPopup"..index, E.UIParent, "StaticPopupTemplate")
		E.StaticPopupFrames[index]:SetID(index)

		E.StaticPopupFrames[index]:SetScript("OnShow", E.StaticPopup_OnShow)
		E.StaticPopupFrames[index]:SetScript("OnHide", E.StaticPopup_OnHide)
		E.StaticPopupFrames[index]:SetScript("OnUpdate", E.StaticPopup_OnUpdate)
		E.StaticPopupFrames[index]:SetScript("OnEvent", E.StaticPopup_OnEvent)

		local name = E.StaticPopupFrames[index]:GetName()
		for i = 1, 2 do
			local button = _G[name.."Button"..i]
			S:HandleButton(button)

			button:SetScript("OnClick", function()
				E.StaticPopup_OnClick(this:GetParent(), this:GetID())
			end)

			E.StaticPopupFrames[index]["button"..i] = button
		end

		_G[name.."EditBox"]:SetScript("OnEnterPressed", E.StaticPopup_EditBoxOnEnterPressed)
		_G[name.."EditBox"]:SetScript("OnEscapePressed", E.StaticPopup_EditBoxOnEscapePressed)
		_G[name.."EditBox"]:SetScript("OnTextChanged", E.StaticPopup_EditBoxOnTextChanged)

		E:SetTemplate(E.StaticPopupFrames[index], "Transparent")

		E.StaticPopupFrames[index].text = _G[name.."Text"]
		E.StaticPopupFrames[index].editBox = _G[name.."EditBox"]

		_G[name.."EditBox"]:DisableDrawLayer("BACKGROUND")

		S:HandleEditBox(_G[name.."EditBox"])

		S:HandleEditBox(_G[name.."MoneyInputFrameGold"])
		S:HandleEditBox(_G[name.."MoneyInputFrameSilver"])
		S:HandleEditBox(_G[name.."MoneyInputFrameCopper"])
		_G[name.."EditBox"].backdrop:SetPoint("TOPLEFT", -2, -4)
		_G[name.."EditBox"].backdrop:SetPoint("BOTTOMRIGHT", 2, 4)
	end

	E:SecureHook("StaticPopup_Resize", "StaticPopup_SetUpPosition")
	E:SecureHook("StaticPopup_OnHide", "StaticPopup_CollapseTable")
end