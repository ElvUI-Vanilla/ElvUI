local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.questtimer ~= true then return end

	E:StripTextures(QuestTimerFrame)
	E:SetTemplate(QuestTimerFrame, "Transparent")

	QuestTimerHeader:SetPoint("TOP", 1, 8)

	E:CreateMover(QuestTimerFrame, "QuestTimerFrameMover", QUEST_TIMERS)

	QuestTimerFrame:ClearAllPoints()
	QuestTimerFrame:SetAllPoints(QuestTimerFrameMover)

	local QuestTimerFrameHolder = CreateFrame("Frame", "QuestTimerFrameHolder", E.UIParent)
	-- QuestTimerFrameHolder:Size(150, 22)
	QuestTimerFrameHolder:SetWidth(150)
	QuestTimerFrameHolder:SetHeight(22)
	QuestTimerFrameHolder:SetPoint("TOP", QuestTimerFrameMover, "TOP")

	hooksecurefunc(QuestTimerFrame, "SetPoint", function(_, _, parent)
		if parent ~= QuestTimerFrameHolder then
			QuestTimerFrame:ClearAllPoints()
			QuestTimerFrame:SetPoint("TOP", QuestTimerFrameHolder, "TOP")
		end
	end)
end

S:AddCallback("QuestTimer", LoadSkin)