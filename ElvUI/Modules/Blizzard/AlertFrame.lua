local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:GetModule("Blizzard");

--Cache global variables
--Lua functions
local _G = _G
local pairs = pairs
--WoW API / Variables
local NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES

local AlertFrameHolder = CreateFrame("Frame", "AlertFrameHolder", E.UIParent)
AlertFrameHolder:SetWidth(250)
AlertFrameHolder:SetHeight(20)
AlertFrameHolder:SetPoint("TOP", E.UIParent, "TOP", 0, -18)

function E:PostAlertMove()
	local position = "TOP"
	local _, y = AlertFrameMover:GetCenter()
	local screenHeight = E.UIParent:GetTop()
	if y > (screenHeight / 2) then
		position = "TOP"
		AlertFrameMover:SetText(AlertFrameMover.textString .. " [Grow Down]")
	else
		position = "BOTTOM"
		AlertFrameMover:SetText(AlertFrameMover.textString .. " [Grow Up]")
	end

	local rollBars = E:GetModule("Misc").RollBars
	if E.private.general.lootRoll then
		local lastframe
		for i, frame in pairs(rollBars) do
			frame:ClearAllPoints()
			if i ~= 1 then
				if position == "TOP" then
					frame:SetPoint("TOP", lastframe, "BOTTOM", 0, -4)
				else
					frame:SetPoint("BOTTOM", lastframe, "TOP", 0, 4)
				end
			else
				if position == "TOP" then
					frame:SetPoint("TOP", AlertFrameHolder, "BOTTOM", 0, -4)
				else
					frame:SetPoint("BOTTOM", AlertFrameHolder, "TOP", 0, 4)
				end
			end
			lastframe = frame
		end
	elseif E.private.skins.blizzard.enable and E.private.skins.blizzard.lootRoll then
		local lastframe
		for i = 1, NUM_GROUP_LOOT_FRAMES do
			local frame = _G["GroupLootFrame" .. i]
			if frame then
				frame:ClearAllPoints()
				if i ~= 1 then
					if position == "TOP" then
						frame:SetPoint("TOP", lastframe, "BOTTOM", 0, -4)
					else
						frame:SetPoint("BOTTOM", lastframe, "TOP", 0, 4)
					end
				else
					if position == "TOP" then
						frame:SetPoint("TOP", AlertFrameHolder, "BOTTOM", 0, -4)
					else
						frame:SetPoint("BOTTOM", AlertFrameHolder, "TOP", 0, 4)
					end
				end
				lastframe = frame
			end
		end
	end
end

function B:AlertMovers()
	E:CreateMover(AlertFrameHolder, "AlertFrameMover", L["Loot / Alert Frames"], nil, nil, E.PostAlertMove)
end