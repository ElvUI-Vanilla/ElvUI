local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
--WoW API / Variables
local hooksecurefunc = hooksecurefunc
local GetWhoInfo = GetWhoInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GUILDMEMBERS_TO_DISPLAY = GUILDMEMBERS_TO_DISPLAY
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS

function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.friends ~= true then return end

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
		-- leftGrad:Size(width, height)
		leftGrad:SetWidth(width)
		leftGrad:SetHeight(height)
		leftGrad:SetPoint("LEFT", f, "CENTER")
		leftGrad:SetTexture(E.media.blankTex)
		leftGrad:SetGradientAlpha("Horizontal", r, g, b, 0.35, r, g, b, 0)

		local rightGrad = f:CreateTexture(nil, "HIGHLIGHT")
		-- rightGrad:Size(width, height)
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
	for i = 1, 4 do
		E:StripTextures(_G["WhoFrameColumnHeader"..i])
		E:StyleButton(_G["WhoFrameColumnHeader"..i], nil, true)
	end

	S:HandleDropDownBox(WhoFrameDropDown)

	E:StripTextures(WhoListScrollFrame)
	S:HandleScrollBar(WhoListScrollFrameScrollBar)

	S:HandleEditBox(WhoFrameEditBox)
	WhoFrameEditBox:SetPoint("BOTTOMLEFT", 17, 108)
	WhoFrameEditBox:SetWidth(326)
	WhoFrameEditBox:SetHeight(18)

	S:HandleButton(WhoFrameWhoButton)
	WhoFrameWhoButton:ClearAllPoints()
	WhoFrameWhoButton:SetPoint("BOTTOMLEFT", 16, 82)

	S:HandleButton(WhoFrameAddFriendButton)
	WhoFrameAddFriendButton:SetPoint("LEFT", WhoFrameWhoButton, "RIGHT", 3, 0)
	WhoFrameAddFriendButton:SetPoint("RIGHT", WhoFrameGroupInviteButton, "LEFT", -3, 0)

	S:HandleButton(WhoFrameGroupInviteButton)

	-- Guild Frame
	for i = 1, GUILDMEMBERS_TO_DISPLAY do
		StyleButton(_G["GuildFrameGuildStatusButton"..i])
	end

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

	S:HandleButton(GuildFrameControlButton)
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
	GuildInfoSaveButton:SetPoint("BOTTOMLEFT", 104, 11)
	S:HandleButton(GuildInfoCancelButton)
	GuildInfoCancelButton:SetPoint("LEFT", GuildInfoSaveButton, "RIGHT", 3, 0)
	-- S:HandleButton(GuildInfoGuildEventButton)
	-- GuildInfoGuildEventButton:SetPoint("RIGHT", GuildInfoSaveButton, "LEFT", -28, 0)

	-- GuildEventLog Frame
	-- E:StripTextures(GuildEventLogFrame)
	-- E:CreateBackdrop(GuildEventLogFrame, "Transparent")
	-- GuildEventLogFrame.backdrop:SetPoint("TOPLEFT", 3, -6)
	-- GuildEventLogFrame.backdrop:SetPoint("BOTTOMRIGHT", -2, 5)

	-- E:SetTemplate(GuildEventFrame, "Default")

	-- S:HandleScrollBar(GuildEventLogScrollFrameScrollBar)
	-- S:HandleCloseButton(GuildEventLogCloseButton)

	-- GuildEventLogCancelButton:SetPoint("BOTTOMRIGHT", -9, 9)
	-- S:HandleButton(GuildEventLogCancelButton)

	-- Control Frame
	E:StripTextures(GuildControlPopupFrame)
	E:CreateBackdrop(GuildControlPopupFrame, "Transparent")
	GuildControlPopupFrame.backdrop:SetPoint("TOPLEFT", 3, -6)
	GuildControlPopupFrame.backdrop:SetPoint("BOTTOMRIGHT", -27, 27)

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 185)
	-- GuildControlPopupFrameDropDownButton:Size(16)
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