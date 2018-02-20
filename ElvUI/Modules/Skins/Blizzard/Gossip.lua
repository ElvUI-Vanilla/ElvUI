local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.gossip ~= true then return end

	-- ItemTextFrame
	E:StripTextures(ItemTextFrame, true)
	E:StripTextures(ItemTextScrollFrame)

	S:HandleScrollBar(ItemTextScrollFrameScrollBar)

	E:CreateBackdrop(ItemTextFrame, "Transparent")
	ItemTextFrame.backdrop:SetPoint("TOPLEFT", 13, -13)
	ItemTextFrame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)

	S:HandleNextPrevButton(ItemTextPrevPageButton)
	S:HandleNextPrevButton(ItemTextNextPageButton)
	ItemTextPrevPageButton:ClearAllPoints()
	ItemTextNextPageButton:ClearAllPoints()
	ItemTextPrevPageButton:SetPoint("TOPLEFT", ItemTextFrame, "TOPLEFT", 30, -50)
	ItemTextNextPageButton:SetPoint("TOPRIGHT", ItemTextFrame, "TOPRIGHT", -48, -50)

	S:HandleCloseButton(ItemTextCloseButton)

	ItemTextPageText:SetTextColor(1, 1, 1)
	ItemTextPageText.SetTextColor = E.noop

	-- GossipFrame
	E:StripTextures(GossipFrameGreetingPanel)

	S:HandleScrollBar(GossipGreetingScrollFrameScrollBar, 5)

	E:Kill(GossipFramePortrait)

	E:CreateBackdrop(GossipFrame, "Transparent")
	GossipFrame.backdrop:SetPoint("TOPLEFT", 15, -19)
	GossipFrame.backdrop:SetPoint("BOTTOMRIGHT", -30, 67)

	S:HandleButton(GossipFrameGreetingGoodbyeButton)
	GossipFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", GossipFrame, -34, 71)

	S:HandleCloseButton(GossipFrameCloseButton)

	GossipGreetingText:SetTextColor(1, 1, 1)

	for i = 1, NUMGOSSIPBUTTONS do
		local button = _G["GossipTitleButton"..i]
		button:SetTextColor(1, 1, 1)
	end
end

S:AddCallback("Gossip", LoadSkin)