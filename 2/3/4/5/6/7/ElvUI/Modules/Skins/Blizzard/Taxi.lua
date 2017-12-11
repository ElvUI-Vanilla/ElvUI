local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.taxi ~= true then return end

	E:CreateBackdrop(TaxiFrame, "Transparent")
	TaxiFrame.backdrop:SetPoint("TOPLEFT", 11, -12)
	TaxiFrame.backdrop:SetPoint("BOTTOMRIGHT", -34, 75)

	E:StripTextures(TaxiFrame)

	E:Kill(TaxiPortrait)

	S:HandleCloseButton(TaxiCloseButton)

	E:CreateBackdrop(TaxiRouteMap, "Default")
end

S:AddCallback("Taxi", LoadSkin)