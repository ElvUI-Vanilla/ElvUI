local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local select = select
local getn = table.getn
--WoW API / Variables

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.spellbook ~= true then return end

	E:StripTextures(SpellBookFrame, true)
	E:CreateBackdrop(SpellBookFrame, "Transparent")
	SpellBookFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	SpellBookFrame.backdrop:SetPoint("BOTTOMRIGHT", -31, 75)

	for i = 1, 3 do
		local tab = _G["SpellBookFrameTabButton" .. i]

		tab:GetNormalTexture():SetTexture(nil)
		tab:GetDisabledTexture():SetTexture(nil)

		S:HandleTab(tab)

		tab.backdrop:SetPoint("TOPLEFT", 14, E.PixelMode and -17 or -19)
		tab.backdrop:SetPoint("BOTTOMRIGHT", -14, 19)
	end

	S:HandleNextPrevButton(SpellBookPrevPageButton)
	S:HandleNextPrevButton(SpellBookNextPageButton)

	S:HandleCloseButton(SpellBookCloseButton)

	for i = 1, SPELLS_PER_PAGE do
		local button = _G["SpellButton" .. i]
		local iconTexture = _G["SpellButton" .. i .. "IconTexture"]
		local cooldown = _G["SpellButton"..i.."Cooldown"]

		button:DisableDrawLayer("BACKGROUND")
		button:GetNormalTexture():SetTexture(nil)
		button:GetPushedTexture():SetTexture(nil)

		if iconTexture then
			iconTexture:SetTexCoord(unpack(E.TexCoords))

			if not button.backdrop then
				E:CreateBackdrop(button, "Default", true)
			end
		end

		if cooldown then
			E:RegisterCooldown(cooldown)
		end
	end

	hooksecurefunc("SpellButton_UpdateButton", function()
		local name = this:GetName()
		local spellName = _G[name.."SpellName"]
		local subSpellName = _G[name.."SubSpellName"]
		local iconTexture = _G[name.."IconTexture"]
		local highlight = _G[name.."Highlight"]

		spellName:SetTextColor(1, 0.80, 0.10)
		subSpellName:SetTextColor(1, 1, 1)

		if iconTexture then
			if highlight then
				highlight:SetTexture(1, 1, 1, 0.3)
			end
		end
	end)

	for i = 1, MAX_SKILLLINE_TABS do
		local tab = _G["SpellBookSkillLineTab"..i]

		E:StripTextures(tab)
		E:StyleButton(tab, nil, true)
		E:SetTemplate(tab, "Default", true)

		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		E:SetInside(tab:GetNormalTexture())
	end

	SpellBookPageText:SetTextColor(1, 1, 1)
end

S:AddCallback("SpellBook", LoadSkin)