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
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local hooksecurefunc = hooksecurefunc

function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.friends ~= true then return end

	-- Friends Frame
	E:StripTextures(FriendsFrame, true)
	E:CreateBackdrop(FriendsFrame, "Transparent")
	FriendsFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	FriendsFrame.backdrop:SetPoint("BOTTOMRIGHT", -33, 76)

	S:HandleCloseButton(FriendsFrameCloseButton)

	for i = 1, 4 do
		S:HandleTab(_G["FriendsFrameTab"..i])
	end

	-- Friends List Frame
	for i = 1, 2 do
		local tab = _G["FriendsFrameToggleTab"..i]
		E:StripTextures(tab)
		E:CreateBackdrop(tab, "Default", true)
		tab.backdrop:SetPoint("TOPLEFT", 3, -7)
		tab.backdrop:SetPoint("BOTTOMRIGHT", -2, -1)

		tab:SetScript("OnEnter", function() S:SetModifiedBackdrop(this) end)
		tab:SetScript("OnLeave", function() S:SetOriginalBackdrop(this) end)
	end


	local r, g, b = 0.8, 0.8, 0.8
	local function StyleButton(f, scale)
		f:SetHighlightTexture(nil)
		local width, height = (f:GetWidth() * (scale or 0.5)), f:GetHeight()

		local leftGrad = f:CreateTexture(nil, "HIGHLIGHT")
		leftGrad:SetWidth(width)
		leftGrad:SetHeight(height)
		leftGrad:SetPoint("LEFT", f, "CENTER")
		leftGrad:SetTexture(E.media.blankTex)
		leftGrad:SetGradientAlpha("Horizontal", r, g, b, 0.35, r, g, b, 0)

		local rightGrad = f:CreateTexture(nil, "HIGHLIGHT")
		rightGrad:SetWidth(width)
		rightGrad:SetHeight(height)
		rightGrad:SetPoint("RIGHT", f, "CENTER")
		rightGrad:SetTexture(E.media.blankTex)
		rightGrad:SetGradientAlpha("Horizontal", r, g, b, 0, r, g, b, 0.35)
	end

	for i = 1, 10 do
		StyleButton(_G["FriendsFrameFriendButton"..i], 0.6)
	end

	E:StripTextures(FriendsFrameFriendsScrollFrame)

	S:HandleScrollBar(FriendsFrameFriendsScrollFrameScrollBar)

	S:HandleButton(FriendsFrameAddFriendButton)
	FriendsFrameAddFriendButton:SetPoint("BOTTOMLEFT", 17, 102)

	S:HandleButton(FriendsFrameSendMessageButton)

	S:HandleButton(FriendsFrameRemoveFriendButton)
	FriendsFrameRemoveFriendButton:SetPoint("TOP", FriendsFrameAddFriendButton, "BOTTOM", 0, -2)

	S:HandleButton(FriendsFrameGroupInviteButton)
	FriendsFrameGroupInviteButton:SetPoint("TOP", FriendsFrameSendMessageButton, "BOTTOM", 0, -2)

	-- Ignore List Frame
	for i = 1, 2 do
		local tab = _G["IgnoreFrameToggleTab"..i]
		E:StripTextures(tab)
		E:CreateBackdrop(tab, "Default", true)
		tab.backdrop:SetPoint("TOPLEFT", 3, -7)
		tab.backdrop:SetPoint("BOTTOMRIGHT", -2, -1)

		tab:SetScript("OnEnter", function() S:SetModifiedBackdrop(this) end)
		tab:SetScript("OnLeave", function() S:SetOriginalBackdrop(this) end)
	end

	S:HandleButton(FriendsFrameIgnorePlayerButton)
	S:HandleButton(FriendsFrameStopIgnoreButton)

	for i = 1, 20 do
		StyleButton(_G["FriendsFrameIgnoreButton"..i])
	end

	-- Who Frame
	WhoFrameColumnHeader3:ClearAllPoints()
	WhoFrameColumnHeader3:SetPoint("TOPLEFT", 20, -70)

	WhoFrameColumnHeader4:ClearAllPoints()
	WhoFrameColumnHeader4:SetPoint("LEFT", WhoFrameColumnHeader3, "RIGHT", -2, -0)
	WhoFrameColumnHeader4:SetWidth(48)

	WhoFrameColumnHeader1:ClearAllPoints()
	WhoFrameColumnHeader1:SetPoint("LEFT", WhoFrameColumnHeader4, "RIGHT", -2, -0)
	WhoFrameColumnHeader1:SetWidth(105)

	WhoFrameColumnHeader2:ClearAllPoints()
	WhoFrameColumnHeader2:SetPoint("LEFT", WhoFrameColumnHeader1, "RIGHT", -2, -0)

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
		button.icon:SetPoint("LEFT", 45, 0)
		button.icon:SetWidth(15)
		button.icon:SetHeight(15)
		button.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\Icons-Classes")

		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints(button.icon)
		StyleButton(button)

		level:ClearAllPoints()
		level:SetPoint("TOPLEFT", 12, -2)

		name:SetWidth(100)
		name:SetHeight(14)
		name:ClearAllPoints()
		name:SetPoint("LEFT", 85, 0)

		_G["WhoFrameButton"..i.."Class"]:Hide()
	end

	E:StripTextures(WhoListScrollFrame)
	S:HandleScrollBar(WhoListScrollFrameScrollBar)

	S:HandleEditBox(WhoFrameEditBox)
	WhoFrameEditBox:SetPoint("BOTTOMLEFT", 17, 108)
	WhoFrameEditBox:SetWidth(338)
	WhoFrameEditBox:SetHeight(18)

	S:HandleButton(WhoFrameWhoButton)
	WhoFrameWhoButton:ClearAllPoints()
	WhoFrameWhoButton:SetPoint("BOTTOMLEFT", 16, 82)

	S:HandleButton(WhoFrameAddFriendButton)
	WhoFrameAddFriendButton:SetPoint("LEFT", WhoFrameWhoButton, "RIGHT", 3, 0)
	WhoFrameAddFriendButton:SetPoint("RIGHT", WhoFrameGroupInviteButton, "LEFT", -3, 0)

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
			local classText = _G["WhoFrameButton"..i.."Class"]
			local variableText = _G["WhoFrameButton"..i.."Variable"]

			local _, guild, level, race, class, zone = GetWhoInfo(index)
			if class == UNKNOWN then return end

			if class then
				class = strupper(class)
			end

			local classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
			local levelTextColor = GetQuestDifficultyColor(level)

			if class then
				button.icon:Show()
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))

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
	GuildFrameColumnHeader3:SetPoint("TOPLEFT", 20, -70)

	GuildFrameColumnHeader4:ClearAllPoints()
	GuildFrameColumnHeader4:SetPoint("LEFT", GuildFrameColumnHeader3, "RIGHT", -2, -0)
	GuildFrameColumnHeader4:SetWidth(48)

	GuildFrameColumnHeader1:ClearAllPoints()
	GuildFrameColumnHeader1:SetPoint("LEFT", GuildFrameColumnHeader4, "RIGHT", -2, -0)
	GuildFrameColumnHeader1:SetWidth(105)

	GuildFrameColumnHeader2:ClearAllPoints()
	GuildFrameColumnHeader2:SetPoint("LEFT", GuildFrameColumnHeader1, "RIGHT", -2, -0)
	GuildFrameColumnHeader2:SetWidth(127)

	for i = 1, GUILDMEMBERS_TO_DISPLAY do
		local button = _G["GuildFrameButton"..i]

		StyleButton(button)
		StyleButton(_G["GuildFrameGuildStatusButton"..i])

		button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
		button.icon:SetPoint("LEFT", 48, -3)
		button.icon:SetWidth(15)
		button.icon:SetHeight(15)
		button.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\Icons-Classes")

		E:CreateBackdrop(button, "Default", true)
		button.backdrop:SetAllPoints(button.icon)

		_G["GuildFrameButton"..i.."Level"]:ClearAllPoints()
		_G["GuildFrameButton"..i.."Level"]:SetPoint("TOPLEFT", 10, -3)

		_G["GuildFrameButton"..i.."Name"]:SetWidth(100)
		_G["GuildFrameButton"..i.."Name"]:SetHeight(14)
		_G["GuildFrameButton"..i.."Name"]:ClearAllPoints()
		_G["GuildFrameButton"..i.."Name"]:SetPoint("LEFT", 85, -3)

		_G["GuildFrameButton"..i.."Class"]:Hide()
	end

	hooksecurefunc("GuildStatus_Update", function()
		if FriendsFrame.playerStatusFrame then
			for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
				local button = _G["GuildFrameButton"..i]
				local _, _, _, level, class, _, _, _, online = GetGuildRosterInfo(button.guildIndex)
				if class == UNKNOWN then return end

				if class then
					class = upper(class)
				end

				if class then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
						levelTextColor = GetQuestDifficultyColor(level)
						buttonText = _G["GuildFrameButton"..i.."Name"]
						buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						buttonText = _G["GuildFrameButton"..i.."Level"]
						buttonText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)
					end
					button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
				end
			end
		else
			local classFileName
			for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
				button = _G["GuildFrameGuildStatusButton"..i]
				_, _, _, _, class, _, _, _, online = GetGuildRosterInfo(button.guildIndex)
				if class == UNKNOWN then return end

				if class then
					class = upper(class)
				end

				if class then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
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
	GuildMemberDetailFrame:SetPoint("TOPLEFT", GuildFrame, "TOPRIGHT", -31, -13)

	S:HandleCloseButton(GuildMemberDetailCloseButton)
	GuildMemberDetailCloseButton:SetPoint("TOPRIGHT", 2, 2)

	S:HandleButton(GuildFrameControlButton)
	S:HandleButton(GuildMemberRemoveButton)
	GuildMemberRemoveButton:SetPoint("BOTTOMLEFT", 8, 7)
	S:HandleButton(GuildMemberGroupInviteButton)
	GuildMemberGroupInviteButton:SetPoint("LEFT", GuildMemberRemoveButton, "RIGHT", 3, 0)

	S:HandleNextPrevButton(GuildFramePromoteButton, true)
	S:HandleNextPrevButton(GuildFrameDemoteButton, true)
	GuildFrameDemoteButton:SetPoint("LEFT", GuildFramePromoteButton, "RIGHT", 2, 0)

	E:SetTemplate(GuildMemberNoteBackground, "Default")
	E:SetTemplate(GuildMemberOfficerNoteBackground, "Default")

	-- Info Frame
	E:StripTextures(GuildInfoFrame)
	E:CreateBackdrop(GuildInfoFrame, "Transparent")
	GuildInfoFrame.backdrop:SetPoint("TOPLEFT", 3, -6)
	GuildInfoFrame.backdrop:SetPoint("BOTTOMRIGHT", -2, 3)

	E:SetTemplate(GuildInfoTextBackground, "Default")
	S:HandleScrollBar(GuildInfoFrameScrollFrameScrollBar)

	S:HandleCloseButton(GuildInfoCloseButton)

	S:HandleButton(GuildInfoSaveButton)
	GuildInfoSaveButton:SetPoint("BOTTOMLEFT", 8, 11)
	S:HandleButton(GuildInfoCancelButton)
	GuildInfoCancelButton:SetPoint("LEFT", GuildInfoSaveButton, "RIGHT", 3, 0)

	-- Control Frame
	E:StripTextures(GuildControlPopupFrame)
	E:CreateBackdrop(GuildControlPopupFrame, "Transparent")
	GuildControlPopupFrame.backdrop:SetPoint("TOPLEFT", 3, -6)
	GuildControlPopupFrame.backdrop:SetPoint("BOTTOMRIGHT", -27, 27)

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 185)
	GuildControlPopupFrameDropDownButton:SetWidth(16)
	GuildControlPopupFrameDropDownButton:SetHeight(16)

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
		f.Text:SetPoint("LEFT", 5, 0)
		if minus then
			f.Text:SetText("-")
		else
			f.Text:SetText("+")
		end
	end

	GuildControlPopupFrameAddRankButton:SetPoint("LEFT", GuildControlPopupFrameDropDown, "RIGHT", -8, 3)
	SkinPlusMinus(GuildControlPopupFrameAddRankButton)
	SkinPlusMinus(GuildControlPopupFrameRemoveRankButton, true)

	S:HandleEditBox(GuildControlPopupFrameEditBox)
	GuildControlPopupFrameEditBox.backdrop:SetPoint("TOPLEFT", 0, -5)
	GuildControlPopupFrameEditBox.backdrop:SetPoint("BOTTOMRIGHT", 0, 5)

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
			RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", -14, -12)
		else
			RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", -34, -12)
		end
	end)

	S:HandleCloseButton(RaidInfoCloseButton, RaidInfoFrame)

	E:StripTextures(RaidInfoScrollFrame)
	S:HandleScrollBar(RaidInfoScrollFrameScrollBar)
end

S:AddCallback("Friends", LoadSkin)