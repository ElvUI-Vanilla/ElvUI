local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local hooksecurefunc = hooksecurefunc
local GetWhoInfo = GetWhoInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GUILDMEMBERS_TO_DISPLAY = GUILDMEMBERS_TO_DISPLAY
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local localizedTable = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	localizedTable[v] = k
end

for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	localizedTable[v] = k
end

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.friends ~= true then return end

	-- Friends Frame
	E:StripTextures(FriendsFrame, true)
	E:CreateBackdrop(FriendsFrame, "Transparent")
	E:Point(FriendsFrame.backdrop, "TOPLEFT", 10, -12)
	E:Point(FriendsFrame.backdrop, "BOTTOMRIGHT", -33, 76)

	S:HandleCloseButton(FriendsFrameCloseButton)

	for i = 1, 4 do
		S:HandleTab(_G["FriendsFrameTab"..i])
	end

	-- Friends List Frame
	for i = 1, 2 do
		local tab = _G["FriendsFrameToggleTab"..i]
		E:StripTextures(tab)
		E:CreateBackdrop(tab, "Default", true)
		E:Point(tab.backdrop, "TOPLEFT", 3, -7)
		E:Point(tab.backdrop, "BOTTOMRIGHT", -2, -1)

		tab:SetScript("OnEnter", S.SetModifiedBackdrop)
		tab:SetScript("OnLeave", S.SetOriginalBackdrop)
	end

	for i = 1, 10 do
		S:HandleButtonHighlight(_G["FriendsFrameFriendButton"..i])
	end

	E:StripTextures(FriendsFrameFriendsScrollFrame)

	S:HandleScrollBar(FriendsFrameFriendsScrollFrameScrollBar)

	S:HandleButton(FriendsFrameAddFriendButton)
	E:Point(FriendsFrameAddFriendButton, "BOTTOMLEFT", 17, 102)

	S:HandleButton(FriendsFrameSendMessageButton)

	S:HandleButton(FriendsFrameRemoveFriendButton)
	E:Point(FriendsFrameRemoveFriendButton, "TOP", FriendsFrameAddFriendButton, "BOTTOM", 0, -2)

	S:HandleButton(FriendsFrameGroupInviteButton)
	E:Point(FriendsFrameGroupInviteButton, "TOP", FriendsFrameSendMessageButton, "BOTTOM", 0, -2)

	-- Ignore List Frame
	for i = 1, 2 do
		local Tab = _G["IgnoreFrameToggleTab"..i]
		E:StripTextures(Tab)
		E:CreateBackdrop(Tab, "Default", true)
		E:Point(Tab.backdrop, "TOPLEFT", 3, -7)
		E:Point(Tab.backdrop, "BOTTOMRIGHT", -2, -1)

		Tab:SetScript("OnEnter", S.SetModifiedBackdrop)
		Tab:SetScript("OnLeave", S.SetOriginalBackdrop)
	end

	S:HandleButton(FriendsFrameIgnorePlayerButton)
	S:HandleButton(FriendsFrameStopIgnoreButton)

	for i = 1, 20 do
		S:HandleButtonHighlight(_G["FriendsFrameIgnoreButton"..i])
	end

	-- Who Frame
	WhoFrameColumnHeader3:ClearAllPoints()
	E:Point(WhoFrameColumnHeader3, "TOPLEFT", 20, -70)

	WhoFrameColumnHeader4:ClearAllPoints()
	E:Point(WhoFrameColumnHeader4, "LEFT", WhoFrameColumnHeader3, "RIGHT", -2, -0)
	E:Width(WhoFrameColumnHeader4, 48)

	WhoFrameColumnHeader1:ClearAllPoints()
	E:Point(WhoFrameColumnHeader1, "LEFT", WhoFrameColumnHeader4, "RIGHT", -2, -0)
	E:Width(WhoFrameColumnHeader1, 105)

	WhoFrameColumnHeader2:ClearAllPoints()
	E:Point(WhoFrameColumnHeader2, "LEFT", WhoFrameColumnHeader1, "RIGHT", -2, -0)

	for i = 1, 4 do
		E:StripTextures(_G["WhoFrameColumnHeader"..i])
		E:StyleButton(_G["WhoFrameColumnHeader"..i])
	end

	S:HandleDropDownBox(WhoFrameDropDown)

	for i = 1, 17 do
		local button = _G["WhoFrameButton"..i]
		local level = _G["WhoFrameButton"..i.."Level"]
		local name = _G["WhoFrameButton"..i.."Name"]

		button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
		E:Point(button.icon, "LEFT", 45, 0)
		E:Size(button.icon, 15)
		button.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\Icons-Classes")

		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints(button.icon)
		S:HandleButtonHighlight(button)

		level:ClearAllPoints()
		E:Point(level, "TOPLEFT", 12, -2)

		E:Size(name, 100, 14)
		name:ClearAllPoints()
		E:Point(name, "LEFT", 85, 0)

		_G["WhoFrameButton"..i.."Class"]:Hide()
	end

	E:StripTextures(WhoListScrollFrame)

	S:HandleScrollBar(WhoListScrollFrameScrollBar)

	S:HandleEditBox(WhoFrameEditBox)
	E:Point(WhoFrameEditBox, "BOTTOMLEFT", 17, 108)
	E:Size(WhoFrameEditBox, 339, 18)

	S:HandleButton(WhoFrameWhoButton)
	WhoFrameWhoButton:ClearAllPoints()
	E:Point(WhoFrameWhoButton, "BOTTOMLEFT", 16, 82)

	S:HandleButton(WhoFrameAddFriendButton)
	E:Point(WhoFrameAddFriendButton, "LEFT", WhoFrameWhoButton, "RIGHT", 3, 0)
	E:Point(WhoFrameAddFriendButton, "RIGHT", WhoFrameGroupInviteButton, "LEFT", -3, 0)

	S:HandleButton(WhoFrameGroupInviteButton)

	hooksecurefunc("WhoList_Update", function()
		local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
		local button, nameText, levelText, classText, variableText
		local _, guild, level, race, class, zone, classFileName
		local classTextColor, levelTextColor
		local index, columnTable

		local playerZone = GetRealZoneText()
		local playerGuild = GetGuildInfo("player")

		for i = 1, WHOS_TO_DISPLAY, 1 do
			index = whoOffset + i
			button = _G["WhoFrameButton"..i]
			nameText = _G["WhoFrameButton"..i.."Name"]
			levelText = _G["WhoFrameButton"..i.."Level"]
			classText = _G["WhoFrameButton"..i.."Class"]
			variableText = _G["WhoFrameButton"..i.."Variable"]

			_, guild, level, race, class, zone = GetWhoInfo(index)

			classFileName = localizedTable[class]
			classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
			levelTextColor = GetQuestDifficultyColor(level)

			if classFileName then
				button.icon:Show()
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))

				nameText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
				levelText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)

				if zone == playerZone then zone = "|cff00ff00"..zone end
				if guild == playerGuild then guild = "|cff00ff00"..guild end
				if race == E.myrace then race = "|cff00ff00"..race end

				columnTable = {zone, guild, race}

				variableText:SetText(columnTable[UIDropDownMenu_GetSelectedID(WhoFrameDropDown)])
			else
				button.icon:Hide()
			end
		end
	end)

	-- Guild Frame
	GuildFrameColumnHeader3:ClearAllPoints()
	E:Point(GuildFrameColumnHeader3, "TOPLEFT", 20, -70)

	GuildFrameColumnHeader4:ClearAllPoints()
	E:Point(GuildFrameColumnHeader4, "LEFT", GuildFrameColumnHeader3, "RIGHT", -2, -0)
	E:Width(GuildFrameColumnHeader4, 48)

	GuildFrameColumnHeader1:ClearAllPoints()
	E:Point(GuildFrameColumnHeader1, "LEFT", GuildFrameColumnHeader4, "RIGHT", -2, -0)
	E:Width(GuildFrameColumnHeader1, 105)

	GuildFrameColumnHeader2:ClearAllPoints()
	E:Point(GuildFrameColumnHeader2, "LEFT", GuildFrameColumnHeader1, "RIGHT", -2, -0)
	E:Width(GuildFrameColumnHeader2, 127)

	for i = 1, GUILDMEMBERS_TO_DISPLAY do
		local button = _G["GuildFrameButton"..i]
		local name = _G["GuildFrameButton"..i.."Name"]
		local level = _G["GuildFrameButton"..i.."Level"]

		button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
		E:Point(button.icon, "LEFT", 48, 0)
		E:Size(button.icon, 15)
		button.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\Icons-Classes")

		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints(button.icon)
		S:HandleButtonHighlight(button)

		level:ClearAllPoints()
		E:Point(level, "TOPLEFT", 10, -1)

		E:Size(name, 100, 14)
		name:ClearAllPoints()
		E:Point(name, "LEFT", 85, 0)

		_G["GuildFrameButton"..i.."Class"]:Hide()

		S:HandleButtonHighlight(_G["GuildFrameGuildStatusButton"..i])

		E:Point(_G["GuildFrameGuildStatusButton"..i.."Name"], "TOPLEFT", 14, 0)
	end

	hooksecurefunc("GuildStatus_Update", function()
		local _, level, class, zone, online, classFileName
		local button, buttonText, classTextColor, levelTextColor
		local playerZone = GetRealZoneText()

		if FriendsFrame.playerStatusFrame then
			for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
				button = _G["GuildFrameButton"..i]
				_, _, _, level, class, zone, _, _, online = GetGuildRosterInfo(button.guildIndex)

				classFileName = localizedTable[class]
				if classFileName then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
						levelTextColor = GetQuestDifficultyColor(level)

						buttonText = _G["GuildFrameButton"..i.."Name"]
						buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						buttonText = _G["GuildFrameButton"..i.."Level"]
						buttonText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)
						buttonText = _G["GuildFrameButton"..i.."Zone"]

						if zone == playerZone then
							buttonText:SetTextColor(0, 1, 0)
						end
					end

					button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))
				end
			end
		else
			for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
				button = _G["GuildFrameGuildStatusButton"..i]
				_, _, _, _, class, _, _, _, online = GetGuildRosterInfo(button.guildIndex)

				classFileName = localizedTable[class]
				if classFileName then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
						_G["GuildFrameGuildStatusButton"..i.."Name"]:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						_G["GuildFrameGuildStatusButton"..i.."Online"]:SetTextColor(1.0, 1.0, 1.0)
					end
				end
			end
		end
	end)

	E:StripTextures(GuildFrameLFGFrame)
	E:SetTemplate(GuildFrameLFGFrame, "Transparent")

	S:HandleCheckBox(GuildFrameLFGButton)

	for i = 1, 4 do
		E:StripTextures(_G["GuildFrameColumnHeader"..i])
		E:StyleButton(_G["GuildFrameColumnHeader"..i])
		E:StripTextures(_G["GuildFrameGuildStatusColumnHeader"..i])
		E:StyleButton(_G["GuildFrameGuildStatusColumnHeader"..i])
	end

	E:StripTextures(GuildListScrollFrame)
	S:HandleScrollBar(GuildListScrollFrameScrollBar)

	S:HandleNextPrevButton(GuildFrameGuildListToggleButton)

	S:HandleButton(GuildFrameGuildInformationButton)
	S:HandleButton(GuildFrameAddMemberButton)
	S:HandleButton(GuildFrameControlButton)

	-- Member Detail Frame
	E:StripTextures(GuildMemberDetailFrame)
	E:CreateBackdrop(GuildMemberDetailFrame, "Transparent")
	E:Point(GuildMemberDetailFrame, "TOPLEFT", GuildFrame, "TOPRIGHT", -31, -13)

	S:HandleCloseButton(GuildMemberDetailCloseButton, GuildMemberDetailFrame.backdrop)

	S:HandleButton(GuildMemberRemoveButton)
	E:Point(GuildMemberRemoveButton, "BOTTOMLEFT", 3, 3)

	S:HandleButton(GuildMemberGroupInviteButton)
	E:Point(GuildMemberGroupInviteButton, "LEFT", GuildMemberRemoveButton, "RIGHT", 13, 0)

	S:HandleNextPrevButton(GuildFramePromoteButton, true)
	GuildFramePromoteButton:SetHitRectInsets(0, 0, 0, 0)

	S:HandleNextPrevButton(GuildFrameDemoteButton, true)
	GuildFrameDemoteButton:SetHitRectInsets(0, 0, 0, 0)
	E:Point(GuildFrameDemoteButton, "LEFT", GuildFramePromoteButton, "RIGHT", 2, 0)

	E:StripTextures(GuildMemberNoteBackground)
	E:CreateBackdrop(GuildMemberNoteBackground, "Default")
	E:Point(GuildMemberNoteBackground.backdrop, "TOPLEFT", 0, -2)
	E:Point(GuildMemberNoteBackground.backdrop, "BOTTOMRIGHT", 0, -1)

	E:StripTextures(GuildMemberOfficerNoteBackground)
	E:CreateBackdrop(GuildMemberOfficerNoteBackground, "Default")
	E:Point(GuildMemberOfficerNoteBackground.backdrop, "TOPLEFT", 0, -2)
	E:Point(GuildMemberOfficerNoteBackground.backdrop, "BOTTOMRIGHT", 0, -1)

	E:Point(GuildFrameNotesLabel, "TOPLEFT", GuildFrame, "TOPLEFT", 23, -340)
	E:Point(GuildFrameNotesText, "TOPLEFT", GuildFrameNotesLabel, "BOTTOMLEFT", 0, -6)

	E:CreateBackdrop(GuildMOTDEditButton, "Default")
	E:Point(GuildMOTDEditButton.backdrop, "TOPLEFT", -7, 3)
	E:Point(GuildMOTDEditButton.backdrop, "BOTTOMRIGHT", 7, -2)
	GuildMOTDEditButton:SetHitRectInsets(-7, -7, -3, -2)

	-- Info Frame
	E:StripTextures(GuildInfoFrame)
	E:CreateBackdrop(GuildInfoFrame, "Transparent")
	E:Point(GuildInfoFrame.backdrop, "TOPLEFT", 3, -6)
	E:Point(GuildInfoFrame.backdrop, "BOTTOMRIGHT", -2, 3)

	E:SetTemplate(GuildInfoTextBackground, "Default")
	S:HandleScrollBar(GuildInfoFrameScrollFrameScrollBar)

	S:HandleCloseButton(GuildInfoCloseButton)

	S:HandleButton(GuildInfoSaveButton)
	E:Point(GuildInfoSaveButton, "BOTTOMLEFT", 8, 11)

	S:HandleButton(GuildInfoCancelButton)
	E:Point(GuildInfoCancelButton, "LEFT", GuildInfoSaveButton, "RIGHT", 3, 0)

	-- Control Frame
	E:StripTextures(GuildControlPopupFrame)
	E:CreateBackdrop(GuildControlPopupFrame, "Transparent")
	E:Point(GuildControlPopupFrame.backdrop, "TOPLEFT", 3, 0)

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 185)
	E:Size(GuildControlPopupFrameDropDownButton, 18)

	local function SkinPlusMinus(button, minus)
		button:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		button.SetNormalTexture = E.noop

		button:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		button.SetPushedTexture = E.noop

		button:SetHighlightTexture("")
		button.SetHighlightTexture = E.noop

		button:SetDisabledTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PlusMinusButton")
		button.SetDisabledTexture = E.noop
		button:GetDisabledTexture():SetDesaturated(true)

		if minus then
			button:GetNormalTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
			button:GetPushedTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
			button:GetDisabledTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
		else
			button:GetNormalTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
			button:GetPushedTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
			button:GetDisabledTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
		end
	end

	SkinPlusMinus(GuildControlPopupFrameAddRankButton)
	E:Point(GuildControlPopupFrameAddRankButton, "LEFT", GuildControlPopupFrameDropDown, "RIGHT", -8, 3)

	SkinPlusMinus(GuildControlPopupFrameRemoveRankButton, true)
	E:Point(GuildControlPopupFrameRemoveRankButton, "LEFT", GuildControlPopupFrameAddRankButton, "RIGHT", 4, 0)


	local left, right = select(6, GuildControlPopupFrameEditBox:GetRegions())
	E:Kill(left) E:Kill(right)

	S:HandleEditBox(GuildControlPopupFrameEditBox)
	E:Point(GuildControlPopupFrameEditBox.backdrop, "TOPLEFT", 0, -5)
	E:Point(GuildControlPopupFrameEditBox.backdrop, "BOTTOMRIGHT", 0, 5)

	for i = 1, 17 do
		local checkbox = _G["GuildControlPopupFrameCheckbox"..i]
		if checkbox then
			S:HandleCheckBox(checkbox)
		end
	end

	S:HandleButton(GuildControlPopupAcceptButton)
	S:HandleButton(GuildControlPopupFrameCancelButton)

	-- Raid Frame
	S:HandleButton(RaidFrameConvertToRaidButton)
	S:HandleButton(RaidFrameRaidInfoButton)

	-- Raid Info Frame
	E:StripTextures(RaidInfoFrame, true)
	E:SetTemplate(RaidInfoFrame, "Transparent")

	HookScript(RaidInfoFrame, "OnShow", function()
		if GetNumRaidMembers() > 0 then
			E:Point(RaidInfoFrame, "TOPLEFT", RaidFrame, "TOPRIGHT", -14, -12)
		else
			E:Point(RaidInfoFrame, "TOPLEFT", RaidFrame, "TOPRIGHT", -34, -12)
		end
	end)

	S:HandleCloseButton(RaidInfoCloseButton, RaidInfoFrame)

	E:StripTextures(RaidInfoScrollFrame)
	S:HandleScrollBar(RaidInfoScrollFrameScrollBar)
end

S:AddCallback("Friends", LoadSkin)
