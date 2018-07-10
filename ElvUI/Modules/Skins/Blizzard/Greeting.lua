local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.greeting ~= true then return end

	E:StripTextures(QuestFrameGreetingPanel)

	E:Kill(QuestGreetingFrameHorizontalBreak)

	S:HandleScrollBar(QuestGreetingScrollFrameScrollBar)

	S:HandleButton(QuestFrameGreetingGoodbyeButton, true)
	QuestFrameGreetingGoodbyeButton:SetPoint("BOTTOMRIGHT", -37, 4)

	E:Height(QuestGreetingScrollFrame, 403)

	HookScript(QuestFrameGreetingPanel, "OnShow", function()
		GreetingText:SetTextColor(1, 0.80, 0.10)
		CurrentQuestsText:SetTextColor(1, 1, 1)
		AvailableQuestsText:SetTextColor(1, 0.80, 0.10)
	end)

	for i = 1, MAX_NUM_QUESTS do
		local button = _G["QuestTitleButton"..i]
		button:SetTextColor(1, 1, 0)
	end
end

S:AddCallback("Greeting", LoadSkin)