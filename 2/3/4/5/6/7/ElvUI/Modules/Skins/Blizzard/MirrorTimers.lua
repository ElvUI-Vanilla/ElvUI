local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local format = format
--WoW API / Variables

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.mirrorTimers ~= true then return end

	local function MirrorTimerFrame_OnUpdate(frame, elapsed)
		if (frame.paused) then
			return
		end

		if frame.timeSinceUpdate >= 0.3 then
			local minutes = frame.value / 60
			local seconds = math.mod(frame.value, 60)
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
	end

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local mirrorTimer = _G["MirrorTimer" .. i]
		local statusBar = _G["MirrorTimer" .. i .. "StatusBar"]
		local text = _G["MirrorTimer" .. i .. "Text"]

		E:StripTextures(mirrorTimer)
		-- mirrorTimer:Size(222, 18)
		mirrorTimer:SetWidth(222)
		mirrorTimer:SetHeight(18)
		mirrorTimer.label = text
		statusBar:SetStatusBarTexture(E["media"].normTex)
		E:RegisterStatusBar(statusBar)
		E:CreateBackdrop(statusBar)
		-- statusBar:Size(222, 18)
		statusBar:SetWidth(222)
		statusBar:SetHeight(18)
		text:Hide()

		local TimerText = mirrorTimer:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(TimerText)
		TimerText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
		mirrorTimer.TimerText = TimerText

		mirrorTimer.timeSinceUpdate = 0.3
		HookScript(mirrorTimer, "OnUpdate", MirrorTimerFrame_OnUpdate)

		E:CreateMover(mirrorTimer, "MirrorTimer" .. i .. "Mover", L["MirrorTimer"] .. i, nil, nil, nil, "ALL,SOLO")
	end
end

S:AddCallback("MirrorTimers", LoadSkin)