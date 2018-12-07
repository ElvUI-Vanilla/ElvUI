local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.spellbook ~= true then return end

	local SpellBookFrame = _G["SpellBookFrame"]
	E:StripTextures(SpellBookFrame, true)
	E:CreateBackdrop(SpellBookFrame, "Transparent")
	E:Point(SpellBookFrame.backdrop, "TOPLEFT", 10, -12)
	E:Point(SpellBookFrame.backdrop, "BOTTOMRIGHT", -31, 75)

	SpellBookFrame:EnableMouseWheel(true)
	SpellBookFrame:SetScript("OnMouseWheel", function()
		--do nothing if not on an appropriate book type
		if SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
			return
		end

		local currentPage, maxPages = SpellBook_GetCurrentPage()

		if arg1 > 0 then
			if currentPage > 1 then
				PrevPageButton_OnClick()
			end
		else
			if currentPage < maxPages then
				NextPageButton_OnClick()
			end
		end
	end)

	for i = 1, 3 do
		local tab = _G["SpellBookFrameTabButton"..i]

		tab:GetNormalTexture():SetTexture("")
		tab:GetDisabledTexture():SetTexture("")

		S:HandleTab(tab)

		E:Point(tab.backdrop, "TOPLEFT", 14, E.PixelMode and -17 or -19)
		E:Point(tab.backdrop, "BOTTOMRIGHT", -14, 19)
	end

	S:HandleNextPrevButton(SpellBookPrevPageButton)
	S:HandleNextPrevButton(SpellBookNextPageButton)

	S:HandleCloseButton(SpellBookCloseButton)

	for i = 1, SPELLS_PER_PAGE do
		local button = _G["SpellButton"..i]
		E:StripTextures(button)

		_G["SpellButton"..i.."AutoCastable"]:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
		E:SetOutside(_G["SpellButton"..i.."AutoCastable"], button, 16, 16)

		E:CreateBackdrop(button, "Default", true)

		_G["SpellButton"..i.."IconTexture"]:SetTexCoord(unpack(E.TexCoords))

		E:RegisterCooldown(_G["SpellButton"..i.."Cooldown"])
	end

	hooksecurefunc("SpellButton_UpdateButton", function()
		local name = this:GetName()
		_G[name.."SpellName"]:SetTextColor(1, 0.80, 0.10)
		_G[name.."SubSpellName"]:SetTextColor(1, 1, 1)
		_G[name.."Highlight"]:SetTexture(1, 1, 1, 0.3)
	end)

	for i = 1, MAX_SKILLLINE_TABS do
		local tab = _G["SpellBookSkillLineTab"..i]

		E:StripTextures(tab)
		E:StyleButton(tab, nil, true)
		E:SetTemplate(tab, "Default", true)

		E:SetInside(tab:GetNormalTexture())
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end

	SpellBookPageText:SetTextColor(1, 1, 1)
end

S:AddCallback("SpellBook", LoadSkin)