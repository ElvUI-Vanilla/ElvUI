local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.gossip ~= true then return end

	E:StripTextures(ItemTextFrame, true)
	E:StripTextures(ItemTextScrollFrame)
	S:HandleScrollBar(ItemTextScrollFrameScrollBar)
	E:CreateBackdrop(ItemTextFrame, "Transparent")
	ItemTextFrame.backdrop:SetPoint("TOPLEFT", 13, -13)
	ItemTextFrame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)
	S:HandleCloseButton(ItemTextCloseButton)
	S:HandleNextPrevButton(ItemTextPrevPageButton)
	S:HandleNextPrevButton(ItemTextNextPageButton)
	ItemTextPageText:SetTextColor(1, 1, 1)
	ItemTextPageText.SetTextColor = E.noop

	S:HandleScrollBar(GossipGreetingScrollFrameScrollBar, 5)

	E:StripTextures(GossipFrameGreetingPanel)

	E:Kill(GossipFramePortrait)

	S:HandleButton(GossipFrameGreetingGoodbyeButton)
	GossipFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", GossipFrame, -34, 71)

	--[[for i = 1, NUMGOSSIPBUTTONS do
		local obj = select(3,_G["GossipTitleButton"..i]:GetRegions())
		obj:SetTextColor(1, 1, 1)
	end]]

	GossipGreetingText:SetTextColor(1,1,1)
	E:CreateBackdrop(GossipFrame, "Transparent")
	GossipFrame.backdrop:SetPoint("TOPLEFT", 15, -19)
	GossipFrame.backdrop:SetPoint("BOTTOMRIGHT", -30, 67)
	S:HandleCloseButton(GossipFrameCloseButton)

	hooksecurefunc("GossipFrameUpdate", function()
		for i=1, NUMGOSSIPBUTTONS do
			local button = _G["GossipTitleButton"..i]

			if button:GetFontString() then
				if button:GetFontString():GetText() and string.gfind(button:GetFontString():GetText(), "|cff000000") then
					button:GetFontString():SetText(string.gsub(button:GetFontString():GetText(), "|cff000000", "|cffFFFF00"))
				end
			end
		end
	end)
end

S:AddCallback("Gossip", LoadSkin)