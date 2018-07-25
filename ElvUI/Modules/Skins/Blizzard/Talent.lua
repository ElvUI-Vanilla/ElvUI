local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.talent ~= true then return end

	UIPanelWindows["TalentFrame"] = {area = "left", pushable = 0, whileDead = 1}

	E:StripTextures(TalentFrame)
	E:CreateBackdrop(TalentFrame, "Transparent")
	E:Point(TalentFrame.backdrop, "TOPLEFT", 13, -12)
	E:Point(TalentFrame.backdrop, "BOTTOMRIGHT", -31, 76)

	TalentFramePortrait:Hide()

	S:HandleCloseButton(TalentFrameCloseButton)

	E:Kill(TalentFrameCancelButton)

	for i = 1, 5 do
		S:HandleTab(_G["TalentFrameTab"..i])
	end

	E:StripTextures(TalentFrameScrollFrame)
	E:CreateBackdrop(TalentFrameScrollFrame, "Default")
	E:Point(TalentFrameScrollFrame.backdrop, "TOPLEFT", -1, 2)
	E:Point(TalentFrameScrollFrame.backdrop, "BOTTOMRIGHT", 6, -2)

	S:HandleScrollBar(TalentFrameScrollFrameScrollBar)
	E:Point(TalentFrameScrollFrameScrollBar, "TOPLEFT", TalentFrameScrollFrame, "TOPRIGHT", 10, -16)

	E:Point(TalentFrameSpentPoints, "TOP", 0, -42)
	E:Point(TalentFrameTalentPointsText, "BOTTOMRIGHT", TalentFrame, "BOTTOMLEFT", 220, 84)

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["TalentFrameTalent"..i]
		local icon = _G["TalentFrameTalent"..i.."IconTexture"]
		local rank = _G["TalentFrameTalent"..i.."Rank"]

		if talent then
			E:StripTextures(talent)
			E:SetTemplate(talent, "Default")
			E:StyleButton(talent)

			E:SetInside(icon)
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("ARTWORK")

			rank:SetFont(E.LSM:Fetch("font", E.db["general"].font), 12, "OUTLINE")
		end
	end
end

S:AddCallbackForAddon("Blizzard_TalentUI", "Talent", LoadSkin)