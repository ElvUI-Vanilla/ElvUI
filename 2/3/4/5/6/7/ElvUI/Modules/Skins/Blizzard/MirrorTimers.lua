local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local floor, format = math.floor, string.format
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.mirrorTimers ~= true then return end

	hooksecurefunc("MirrorTimerFrame_OnUpdate", function(frame, elapsed)
		if frame.paused then
			return
		end

		if frame.timeSinceUpdate >= 0.3 then
			local minutes = frame.value / 60
			local seconds = frame.value - floor(frame.value / 60) * 60
			local text = frame.label:GetText()

			if frame.value > 0 then
				frame.TimerText:SetText(format("%s (%d:%02d)", text, minutes, seconds))
			else
				frame.TimerText:SetText(format("%s (0:00)", text))
			end
			frame.timeSinceUpdate = 0
		else
			frame.timeSinceUpdate = frame.timeSinceUpdate + elapsed
		end
	end)

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local mirrorTimer = _G["MirrorTimer"..i]
		local statusBar = _G["MirrorTimer"..i.."StatusBar"]
		local text = _G["MirrorTimer"..i.."Text"]

		E:StripTextures(mirrorTimer)
		mirrorTimer:SetWidth(222)
		mirrorTimer:SetHeight(18)
		mirrorTimer.label = text
		statusBar:SetStatusBarTexture(E["media"].normTex)
		E:RegisterStatusBar(statusBar)
		E:CreateBackdrop(statusBar)
		statusBar:SetWidth(222)
		statusBar:SetHeight(18)
		text:Hide()

		local TimerText = mirrorTimer:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(TimerText)
		TimerText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
		mirrorTimer.TimerText = TimerText

		mirrorTimer.timeSinceUpdate = 0.3

		E:CreateMover(mirrorTimer, "MirrorTimer"..i.."Mover", L["MirrorTimer"]..i, nil, nil, nil, "ALL,SOLO")
	end
end

S:AddCallback("MirrorTimers", LoadSkin)