local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.gossip ~= true then return end

	-- ItemTextFrame
	E:StripTextures(ItemTextScrollFrame)

	E:StripTextures(ItemTextFrame, true)
	E:CreateBackdrop(ItemTextFrame, "Transparent")
	E:Point(ItemTextFrame.backdrop, "TOPLEFT", 13, -13)
	E:Point(ItemTextFrame.backdrop, "BOTTOMRIGHT", -32, 74)

	S:HandleNextPrevButton(ItemTextPrevPageButton)
	ItemTextPrevPageButton:ClearAllPoints()
	ItemTextPrevPageButton:SetPoint("TOPLEFT", ItemTextFrame, "TOPLEFT", 30, -50)

	S:HandleNextPrevButton(ItemTextNextPageButton)
	ItemTextNextPageButton:ClearAllPoints()
	ItemTextNextPageButton:SetPoint("TOPRIGHT", ItemTextFrame, "TOPRIGHT", -48, -50)

	S:HandleScrollBar(ItemTextScrollFrameScrollBar)

	S:HandleCloseButton(ItemTextCloseButton)

	ItemTextPageText:SetTextColor(1, 1, 1)
	ItemTextPageText.SetTextColor = E.noop

	-- Gossip Frame
	E:StripTextures(GossipFrameGreetingPanel)
	E:Kill(GossipFramePortrait)

	E:CreateBackdrop(GossipFrame, "Transparent")
	GossipFrame.backdrop:SetPoint("TOPLEFT", 15, -11)
	GossipFrame.backdrop:SetPoint("BOTTOMRIGHT", -30, 0)

	E:Height(GossipGreetingScrollFrame, 403)

	GossipNpcNameFrame:SetPoint("TOP", GossipFrame, "TOP", -5, -19)

	S:HandleButton(GossipFrameGreetingGoodbyeButton)
	GossipFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", -37, 4)

	S:HandleScrollBar(GossipGreetingScrollFrameScrollBar, 5)

	S:HandleCloseButton(GossipFrameCloseButton)
	GossipFrameCloseButton:SetPoint("CENTER", GossipFrame, "TOPRIGHT", -44, -25)

	GossipGreetingText:SetTextColor(1, 1, 1)

	for i = 1, NUMGOSSIPBUTTONS do
		local button = _G["GossipTitleButton"..i]
		button:SetTextColor(1, 1, 1)
	end
end

S:AddCallback("Gossip", LoadSkin)