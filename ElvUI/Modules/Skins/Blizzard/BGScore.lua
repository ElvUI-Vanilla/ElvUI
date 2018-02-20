local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local split = string.split
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.bgscore ~= true then return end

	E:CreateBackdrop(WorldStateScoreFrame, "Transparent")
	WorldStateScoreFrame.backdrop:SetPoint("TOPLEFT", 10, -15)
	WorldStateScoreFrame.backdrop:SetPoint("BOTTOMRIGHT", -113, 67)

	E:StripTextures(WorldStateScoreFrame)

	E:StripTextures(WorldStateScoreScrollFrame)
	S:HandleScrollBar(WorldStateScoreScrollFrameScrollBar)

	local tab
	for i = 1, 3 do
		tab = _G["WorldStateScoreFrameTab"..i]

		S:HandleTab(tab)

		_G["WorldStateScoreFrameTab"..i.."Text"]:SetPoint("CENTER", 0, 2)
	end

	S:HandleButton(WorldStateScoreFrameLeaveButton)
	S:HandleCloseButton(WorldStateScoreFrameCloseButton)

	E:StyleButton(WorldStateScoreFrameKB)
	E:StyleButton(WorldStateScoreFrameDeaths)
	E:StyleButton(WorldStateScoreFrameHK)
	E:StyleButton(WorldStateScoreFrameHonorGained)
	E:StyleButton(WorldStateScoreFrameName)

	for i = 1, 5 do
		E:StyleButton(_G["WorldStateScoreColumn"..i])
	end

	hooksecurefunc("WorldStateScoreFrame_Update", function()
		local offset = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame)

		for i = 1, MAX_WORLDSTATE_SCORE_BUTTONS do
			local index = offset + i
			local name, _, _, _, _, faction = GetBattlefieldScore(index)
			if name then
				local n, r = split("-", name, 2)
				local myName = UnitName("player")

				if name == myName then
					n = "> "..n.." <"
				end

				if r then
					local color

					if faction == 1 then
						color = "|cff00adf0"
					else
						color = "|cffff1919"
					end
					r = color..r.."|r"
					n = n.."|cffffffff - |r"..r
				end

				local classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classToken] or RAID_CLASS_COLORS[classToken]

				_G["WorldStateScoreButton"..i.."NameText"]:SetText(n)
				_G["WorldStateScoreButton"..i.."NameText"]:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
			end
		end
	end)
end

S:AddCallback("WorldStateScore", LoadSkin)