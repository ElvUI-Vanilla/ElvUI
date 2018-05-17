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
	E:Point(ItemTextFrame.backdrop, "TOPLEFT", 13, -13)
	E:Point(ItemTextFrame.backdrop, "BOTTOMRIGHT", -32, 74)

	S:HandleNextPrevButton(ItemTextPrevPageButton)
	S:HandleNextPrevButton(ItemTextNextPageButton)
	ItemTextPrevPageButton:ClearAllPoints()
	ItemTextNextPageButton:ClearAllPoints()
	E:Point(ItemTextPrevPageButton, "TOPLEFT", ItemTextFrame, "TOPLEFT", 30, -50)
	E:Point(ItemTextNextPageButton, "TOPRIGHT", ItemTextFrame, "TOPRIGHT", -48, -50)

	S:HandleCloseButton(ItemTextCloseButton)

	ItemTextPageText:SetTextColor(1, 1, 1)
	ItemTextPageText.SetTextColor = E.noop

	-- GossipFrame
	E:StripTextures(GossipFrameGreetingPanel)

	S:HandleScrollBar(GossipGreetingScrollFrameScrollBar, 5)

	E:Kill(GossipFramePortrait)

	E:CreateBackdrop(GossipFrame, "Transparent")
	E:Point(GossipFrame.backdrop, "TOPLEFT", 15, -19)
	E:Point(GossipFrame.backdrop, "BOTTOMRIGHT", -30, 67)

	S:HandleButton(GossipFrameGreetingGoodbyeButton)
	E:Point(GossipFrameGreetingGoodbyeButton, "BOTTOMRIGHT", GossipFrame, -34, 71)

	S:HandleCloseButton(GossipFrameCloseButton)

	GossipGreetingText:SetTextColor(1, 1, 1)

	for i = 1, NUMGOSSIPBUTTONS do
		local button = _G["GossipTitleButton"..i]
		button:SetTextColor(1, 1, 1)
	end
end

S:AddCallback("Gossip", LoadSkin)