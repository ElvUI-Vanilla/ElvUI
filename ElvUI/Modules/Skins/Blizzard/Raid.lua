local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local pairs = pairs
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.raid ~= true then return end

	-- RaidFrame
	local StripAllTextures = {
		"RaidGroup1",
		"RaidGroup2",
		"RaidGroup3",
		"RaidGroup4",
		"RaidGroup5",
		"RaidGroup6",
		"RaidGroup7",
		"RaidGroup8"
	}

	for _, object in pairs(StripAllTextures) do
		if _G[object] then
			E:StripTextures(_G[object])
		end
	end

	S:HandleButton(RaidFrameAddMemberButton)
	S:HandleButton(RaidFrameReadyCheckButton)
	S:HandleButton(RaidFrameRaidInfoButton)

	for i = 1, NUM_RAID_GROUPS*5 do
		S:HandleButton(_G["RaidGroupButton"..i], true)
	end

	for i = 1, 8 do
		for j = 1, 5 do
			E:StripTextures(_G["RaidGroup"..i.."Slot"..j])
			E:SetTemplate(_G["RaidGroup"..i.."Slot"..j], "Transparent")
		end
	end

	local function skinPulloutFrames()
		for i = 1, NUM_RAID_PULLOUT_FRAMES do
			local rp = _G["RaidPullout"..i]
			if not rp.backdrop then
				_G["RaidPullout"..i.."MenuBackdrop"]:SetBackdrop(nil)
				E:CreateBackdrop(rp, "Transparent")
				E:Point(rp.backdrop, "TOPLEFT", 9, -17)
				E:Point(rp.backdrop, "BOTTOMRIGHT", -7, 10)
			end
		end
	end

	hooksecurefunc("RaidPullout_GetFrame", function()
		skinPulloutFrames()
	end)

	--[[hooksecurefunc("RaidPullout_Update", function(pullOutFrame)
		local pfName = pullOutFrame:GetName()
		for i = 1, pullOutFrame.numPulloutButtons do
			local pfBName = pfName.."Button"..i
			local pfBObj = _G[pfBName]
			if not pfBObj.backdrop then
				for _, v in pairs{"HealthBar", "ManaBar", "Target", "TargetTarget"} do
					local sBar = pfBName..v
					E:StripTextures(_G[sBar])
					_G[sBar]:SetStatusBarTexture(E["media"].normTex)
				end

				E:Point(_G[pfBName.."ManaBar"], "TOP", "$parentHealthBar", "BOTTOM", 0, 0)
				E:Point(_G[pfBName.."Target"], "TOP", "$parentManaBar", "BOTTOM", 0, -1)

				E:CreateBackdrop(pfBObj, "Default")
				E:Point(pfBObj.backdrop, "TOPLEFT", E.PixelMode and 0 or -1, -(E.PixelMode and 10 or 9))
				E:Point(pfBObj.backdrop, "BOTTOMRIGHT", E.PixelMode and 0 or 1, E.PixelMode and 1 or 0)
			end

			if not _G[pfBName.."TargetTargetFrame"].backdrop then
				E:StripTextures(_G[pfBName.."TargetTargetFrame"])
				E:CreateBackdrop(_G[pfBName.."TargetTargetFrame"], "Default")
				E:Point(_G[pfBName.."TargetTargetFrame"].backdrop, "TOPLEFT", E.PixelMode and 10 or 9, -(E.PixelMode and 15 or 14))
				E:Point(_G[pfBName.."TargetTargetFrame"].backdrop, "BOTTOMRIGHT", -(E.PixelMode and 10 or 9), E.PixelMode and 8 or 7)
			end
		end
	end)]]

	-- ReadyCheckFrame
	E:StripTextures(ReadyCheckFrame)
	E:SetTemplate(ReadyCheckFrame, "Transparent")

	E:Kill(ReadyCheckPortrait)

	S:HandleButton(ReadyCheckFrameYesButton)
	S:HandleButton(ReadyCheckFrameNoButton)

	E:Point(ReadyCheckFrameYesButton, "RIGHT", ReadyCheckFrame, "CENTER", -1, 0)
	E:Point(ReadyCheckFrameNoButton, "LEFT", ReadyCheckFrameYesButton, "RIGHT", 3, 0)
	E:Point(ReadyCheckFrameText, "TOP", ReadyCheckFrame, "TOP", 0, -18)
end

S:AddCallbackForAddon("Blizzard_RaidUI", "RaidUI", LoadSkin)