local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions

--WoW API / Variables

local function LoadSkin()
	E:StripTextures(BattlefieldFrame)

	E:CreateBackdrop(BattlefieldFrame, "Transparent")
	BattlefieldFrame.backdrop:SetPoint("TOPLEFT", 11, -12)
	BattlefieldFrame.backdrop:SetPoint("BOTTOMRIGHT", -34, 74)

	E:StripTextures(BattlefieldListScrollFrame)
	S:HandleScrollBar(BattlefieldListScrollFrameScrollBar)

	S:HandleButton(BattlefieldFrameCancelButton)
	S:HandleButton(BattlefieldFrameJoinButton)
	S:HandleButton(BattlefieldFrameGroupJoinButton)

	S:HandleCloseButton(BattlefieldFrameCloseButton)
end

S:AddCallback("Battlefield", LoadSkin)