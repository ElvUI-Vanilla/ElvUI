local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local upper = string.upper
--WoW API / Variables
local GetWhoInfo = GetWhoInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GUILDMEMBERS_TO_DISPLAY = GUILDMEMBERS_TO_DISPLAY
local hooksecurefunc = hooksecurefunc

local localizedTable = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	localizedTable[v] = k
end

for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	localizedTable[v] = k
end

function LoadSkin()
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
		S:HandleButtonHighlight(_G["FriendsFrameFriendButton"..i], 0.6)
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
		local tab = _G["IgnoreFrameToggleTab"..i]
		E:StripTextures(tab)
		E:CreateBackdrop(tab, "Default", true)
		E:Point(tab.backdrop, "TOPLEFT", 3, -7)
		E:Point(tab.backdrop, "BOTTOMRIGHT", -2, -1)

		tab:SetScript("OnEnter", function() S:SetModifiedBackdrop(this) end)
		tab:SetScript("OnLeave", function() S:SetOriginalBackdrop(this) end)
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
		E:StyleButton(_G["WhoFrameColumnHeader"..i], nil, true)
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
	E:Size(WhoFrameEditBox, 338, 18)

	S:HandleButton(WhoFrameWhoButton)
	WhoFrameWhoButton:ClearAllPoints()
	E:Point(WhoFrameWhoButton, "BOTTOMLEFT", 16, 82)

	S:HandleButton(WhoFrameAddFriendButton)
	E:Point(WhoFrameAddFriendButton, "LEFT", WhoFrameWhoButton, "RIGHT", 3, 0)
	E:Point(WhoFrameAddFriendButton, "RIGHT", WhoFrameGroupInviteButton, "LEFT", -3, 0)

	S:HandleButton(WhoFrameGroupInviteButton)

	hooksecurefunc("WhoList_Update", function()
		local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
		local playerZone = GetRealZoneText()
		local playerGuild = GetGuildInfo("player")
		local playerRace = UnitRace("player")

		for i = 1, WHOS_TO_DISPLAY, 1 do
			local index = whoOffset + i
			local button = _G["WhoFrameButton"..i]
			local nameText = _G["WhoFrameButton"..i.."Name"]
			local levelText = _G["WhoFrameButton"..i.."Level"]
			local variableText = _G["WhoFrameButton"..i.."Variable"]

			local _, guild, _, race, class, zone = GetWhoInfo(index)

			local classFileName = localizedTable[class]
			if classFileName then
				local classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
				local levelTextColor = GetQuestDifficultyColor(level)

				button.icon:Show()
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))

				nameText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
				levelText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)

				if zone == playerZone then
					zone = "|cff00ff00"..zone
				end
				if guild == playerGuild then
					guild = "|cff00ff00"..guild
				end
				if race == playerRace then
					race = "|cff00ff00"..race
				end

				local columnTable = {zone, guild, race}

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

		S:HandleButtonHighlight(button)
		S:HandleButtonHighlight(_G["GuildFrameGuildStatusButton"..i])

		button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
		E:Point(button.icon, "LEFT", 48, -3)
		E:Size(button.icon, 15)
		button.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\Icons-Classes")

		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints(button.icon)

		_G["GuildFrameButton"..i.."Level"]:ClearAllPoints()
		E:Point(_G["GuildFrameButton"..i.."Level"], "TOPLEFT", 10, -3)

		E:Size(_G["GuildFrameButton"..i.."Name"], 100, 14)
		_G["GuildFrameButton"..i.."Name"]:ClearAllPoints()
		E:Point(_G["GuildFrameButton"..i.."Name"], "LEFT", 85, -3)

		_G["GuildFrameButton"..i.."Class"]:Hide()
	end

	hooksecurefunc("GuildStatus_Update", function()
		local _, level, class, online, classFileName
		local levelTextColor, classTextColor
		local button, buttonText

		if FriendsFrame.playerStatusFrame then
			for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
				button = _G["GuildFrameButton"..i]
				_, _, _, level, class, _, _, _, online = GetGuildRosterInfo(button.guildIndex)
				
				classFileName = localizedTable[class]
				if classFileName then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
						levelTextColor = GetQuestDifficultyColor(level)
						buttonText = _G["GuildFrameButton"..i.."Name"]
						buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						buttonText = _G["GuildFrameButton"..i.."Level"]
						buttonText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)
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
		E:StyleButton(_G["GuildFrameColumnHeader"..i], nil, true)
		E:StripTextures(_G["GuildFrameGuildStatusColumnHeader"..i])
		E:StyleButton(_G["GuildFrameGuildStatusColumnHeader"..i], nil, true)
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

	S:HandleCloseButton(GuildMemberDetailCloseButton)
	E:Point(GuildMemberDetailCloseButton, "TOPRIGHT", 2, 2)

	S:HandleButton(GuildFrameControlButton)
	S:HandleButton(GuildMemberRemoveButton)
	E:Point(GuildMemberRemoveButton, "BOTTOMLEFT", 8, 7)
	S:HandleButton(GuildMemberGroupInviteButton)
	E:Point(GuildMemberGroupInviteButton, "LEFT", GuildMemberRemoveButton, "RIGHT", 3, 0)

	S:HandleNextPrevButton(GuildFramePromoteButton, true)
	S:HandleNextPrevButton(GuildFrameDemoteButton, true)
	E:Point(GuildFrameDemoteButton, "LEFT", GuildFramePromoteButton, "RIGHT", 2, 0)

	E:SetTemplate(GuildMemberNoteBackground, "Default")
	E:SetTemplate(GuildMemberOfficerNoteBackground, "Default")

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
	E:Point(GuildControlPopupFrame.backdrop, "TOPLEFT", 3, -6)
	E:Point(GuildControlPopupFrame.backdrop, "BOTTOMRIGHT", -27, 27)

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 185)
	E:Size(GuildControlPopupFrameDropDownButton, 16)

	local function SkinPlusMinus(f, minus)
		f:SetNormalTexture("")
		f.SetNormalTexture = E.noop
		f:SetPushedTexture("")
		f.SetPushedTexture = E.noop
		f:SetHighlightTexture("")
		f.SetHighlightTexture = E.noop
		f:SetDisabledTexture("")
		f.SetDisabledTexture = E.noop

		f.Text = f:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(f.Text, nil, 22)
		E:Point(f.Text, "LEFT", 5, 0)
		if minus then
			f.Text:SetText("-")
		else
			f.Text:SetText("+")
		end
	end

	E:Point(GuildControlPopupFrameAddRankButton, "LEFT", GuildControlPopupFrameDropDown, "RIGHT", -8, 3)
	SkinPlusMinus(GuildControlPopupFrameAddRankButton)
	SkinPlusMinus(GuildControlPopupFrameRemoveRankButton, true)

	S:HandleEditBox(GuildControlPopupFrameEditBox)
	E:Point(GuildControlPopupFrameEditBox.backdrop, "TOPLEFT", 0, -5)
	E:Point(GuildControlPopupFrameEditBox.backdrop, "BOTTOMRIGHT", 0, 5)

	for i = 1, 17 do
		local Checkbox = _G["GuildControlPopupFrameCheckbox"..i]
		if Checkbox then
			S:HandleCheckBox(Checkbox)
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