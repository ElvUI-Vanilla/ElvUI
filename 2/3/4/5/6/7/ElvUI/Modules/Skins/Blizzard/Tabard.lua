local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.tabard ~= true then return end

	E:StripTextures(TabardFrame)
	E:Kill(TabardFramePortrait)
	E:CreateBackdrop(TabardFrame, "Transparent")
	TabardFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	TabardFrame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)
	E:CreateBackdrop(TabardModel, "Default")
	S:HandleButton(TabardFrameCancelButton)
	S:HandleButton(TabardFrameAcceptButton)
	S:HandleCloseButton(TabardFrameCloseButton)
	S:HandleRotateButton(TabardCharacterModelRotateLeftButton)
	S:HandleRotateButton(TabardCharacterModelRotateRightButton)
	E:StripTextures(TabardFrameCostFrame)
	E:StripTextures(TabardFrameCustomizationFrame)

	for i = 1, 5 do
		local custom = "TabardFrameCustomization"..i
		E:StripTextures(_G[custom])
		S:HandleNextPrevButton(_G[custom.."LeftButton"])
		S:HandleNextPrevButton(_G[custom.."RightButton"])

		if(i > 1) then
			_G[custom]:ClearAllPoints()
			_G[custom]:SetPoint("TOP", _G["TabardFrameCustomization"..i-1], "BOTTOM", 0, -6)
		else
			local point, anchor, point2, x, y = _G[custom]:GetPoint()
			_G[custom]:SetPoint(point, anchor, point2, x, y+4)
		end
	end

	TabardCharacterModelRotateLeftButton:SetPoint("BOTTOMLEFT", 4, 4)
	TabardCharacterModelRotateRightButton:SetPoint("TOPLEFT", TabardCharacterModelRotateLeftButton, "TOPRIGHT", 4, 0)
	hooksecurefunc(TabardCharacterModelRotateLeftButton, "SetPoint", function(self, point, _, _, xOffset, yOffset)
		if point ~= "BOTTOMLEFT" or xOffset ~= 4 or yOffset ~= 4 then
			self:SetPoint("BOTTOMLEFT", 4, 4)
		end
	end)

	hooksecurefunc(TabardCharacterModelRotateRightButton, "SetPoint", function(self, point, _, _, xOffset, yOffset)
		if point ~= "TOPLEFT" or xOffset ~= 4 or yOffset ~= 0 then
			self:SetPoint("TOPLEFT", TabardCharacterModelRotateLeftButton, "TOPRIGHT", 4, 0)
		end
	end)
end

S:AddCallback("Tabard", LoadSkin)