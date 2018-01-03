local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local find, gsub = string.find, string.gsub
--WoW API / Variables
local HookScript = HookScript

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.greeting ~= true then return end

	HookScript(QuestFrameGreetingPanel, "OnShow", function()
		E:StripTextures(QuestFrameGreetingPanel)
		S:HandleButton(QuestFrameGreetingGoodbyeButton, true)
		GreetingText:SetTextColor(1, 1, 1)
		CurrentQuestsText:SetTextColor(1, 1, 0)
		E:Kill(QuestGreetingFrameHorizontalBreak)
		AvailableQuestsText:SetTextColor(1, 1, 0)
		S:HandleScrollBar(QuestGreetingScrollFrameScrollBar)
		for i = 1, MAX_NUM_QUESTS do
			local button = _G["QuestTitleButton"..i]
			button:SetTextColor(1, 1, 1)
			if button:GetFontString() then
				if button:GetFontString():GetText() and find(button:GetFontString():GetText(), "|cff000000") then
					button:GetFontString():SetText(gsub(button:GetFontString():GetText(), "|cff000000", "|cffFFFF00"))
				end
			end
		end
	end)
end

S:AddCallback("Greeting", LoadSkin)