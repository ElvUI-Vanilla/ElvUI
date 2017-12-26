local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.guildregistrar ~= true then return end

	E:StripTextures(GuildRegistrarFrame, true)
	E:CreateBackdrop(GuildRegistrarFrame, "Transparent")
	GuildRegistrarFrame.backdrop:SetPoint("TOPLEFT", 12, -17)
	GuildRegistrarFrame.backdrop:SetPoint("BOTTOMRIGHT", -28, 65)
	E:StripTextures(GuildRegistrarGreetingFrame)
	S:HandleButton(GuildRegistrarFrameGoodbyeButton)
	S:HandleButton(GuildRegistrarFrameCancelButton)
	S:HandleButton(GuildRegistrarFramePurchaseButton)
	S:HandleCloseButton(GuildRegistrarFrameCloseButton)
	S:HandleEditBox(GuildRegistrarFrameEditBox)

	GuildRegistrarFrameEditBox:DisableDrawLayer("BACKGROUND")

	GuildRegistrarFrameEditBox:SetHeight(20)

	for i = 1, 2 do
		_G["GuildRegistrarButton"..i]:GetFontString():SetTextColor(1, 1, 1)
	end

	GuildRegistrarPurchaseText:SetTextColor(1, 1, 1)
	AvailableServicesText:SetTextColor(1, 1, 0)
end

S:AddCallback("GuildRegistrar", LoadSkin)