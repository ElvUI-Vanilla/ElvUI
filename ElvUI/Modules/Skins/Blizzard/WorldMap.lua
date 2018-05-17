local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.worldmap ~= true then return end

	E:StripTextures(WorldMapFrame)
	E:CreateBackdrop(WorldMapPositioningGuide, "Transparent")

	S:HandleDropDownBox(WorldMapContinentDropDown, 170)
	S:HandleDropDownBox(WorldMapZoneDropDown, 170)

	E:Point(WorldMapZoneDropDown, "LEFT", WorldMapContinentDropDown, "RIGHT", -24, 0)
	E:Point(WorldMapZoomOutButton, "LEFT", WorldMapZoneDropDown, "RIGHT", -4, 3)

	S:HandleButton(WorldMapZoomOutButton)

	S:HandleCloseButton(WorldMapFrameCloseButton)

	E:CreateBackdrop(WorldMapDetailFrame, "Default")
end

S:AddCallback("SkinWorldMap", LoadSkin)