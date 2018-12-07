local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.taxi ~= true then return end

	E:CreateBackdrop(TaxiFrame, "Transparent")
	E:Point(TaxiFrame.backdrop, "TOPLEFT", 11, -12)
	E:Point(TaxiFrame.backdrop, "BOTTOMRIGHT", -34, 75)

	E:StripTextures(TaxiFrame)

	E:Kill(TaxiPortrait)

	S:HandleCloseButton(TaxiCloseButton)

	E:CreateBackdrop(TaxiRouteMap, "Default")
end

S:AddCallback("Taxi", LoadSkin)