local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local getn = table.getn
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.help ~= true then return end

	local helpFrameButtons = {
		"GeneralBack",
		"GeneralButton",
		"GeneralButton2",
		"GeneralCancel",
		"GMBack",
		"GMCancel",
		"HarassmentBack",
		"HarassmentCancel",
		"HomeIssues",
		"HomeCancel",
		"OpenTicketSubmit",
		"OpenTicketCancel",
		"PhysicalHarassmentButton",
		"VerbalHarassmentButton",
	}

	E:StripTextures(HelpFrame)
	E:CreateBackdrop(HelpFrame, "Transparent")
	E:Point(HelpFrame.backdrop, "TOPLEFT", 6, -2)
	E:Point(HelpFrame.backdrop, "BOTTOMRIGHT", -45, 14)

	S:HandleCloseButton(HelpFrameCloseButton)
	E:Point(HelpFrameCloseButton, "TOPRIGHT", -42, 0)

	for i = 1, getn(helpFrameButtons) do
		local helpButton = _G["HelpFrame"..helpFrameButtons[i]]
		S:HandleButton(helpButton)
	end

	-- hide header textures and move text/buttons.
	local BlizzardHeader = {
		"KnowledgeBaseFrame"
	}

	for i = 1, getn(BlizzardHeader) do
		local title = _G[BlizzardHeader[i].."Header"]
		if title then
			title:SetTexture("")
			title:ClearAllPoints()
			if title == _G["GameMenuFrameHeader"] then
				E:Point(title, "TOP", GameMenuFrame, 0, 0)
			else
				E:Point(title, "TOP", BlizzardHeader[i], -22, -8)
			end
		end
	end

	E:StripTextures(HelpFrameOpenTicketDivider)

	S:HandleScrollBar(HelpFrameOpenTicketScrollFrame)
	S:HandleScrollBar(HelpFrameOpenTicketScrollFrameScrollBar)

	E:Point(HelpFrameOpenTicketSubmit, "RIGHT", HelpFrameOpenTicketCancel, "LEFT", -2, 0)

	E:Kill(HelpFrameHarassmentDivider)
	E:Kill(HelpFrameHarassmentDivider2)
end

S:AddCallback("Help", LoadSkin)