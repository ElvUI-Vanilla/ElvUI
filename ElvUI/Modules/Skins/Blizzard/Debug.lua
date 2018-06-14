local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local getn = table.getn
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.debug ~= true then return end

	ScriptErrorsFrame:SetScale(UIParent:GetScale())
	E:SetTemplate(ScriptErrorsFrame, "Transparent")
	S:HandleScrollBar(ScriptErrorsFrameScrollFrameScrollBar)
	S:HandleCloseButton(ScriptErrorsFrameClose)
	E:FontTemplate(ScriptErrorsFrameScrollFrameText, nil, 13)
	E:CreateBackdrop(ScriptErrorsFrameScrollFrame, "Default")
	E:Point(ScriptErrorsFrameScrollFrame.backdrop, "BOTTOMRIGHT", 0, -3)
	ScriptErrorsFrameScrollFrame:SetFrameLevel(ScriptErrorsFrameScrollFrame:GetFrameLevel() + 2)

	E:SetTemplate(EventTraceFrame, "Transparent")
	S:HandleSliderFrame(EventTraceFrameScroll)

	local texs = {
		"TopLeft",
		"TopRight",
		"Top",
		"BottomLeft",
		"BottomRight",
		"Bottom",
		"Left",
		"Right",
		"TitleBG",
		"DialogBG",
	}

	for i = 1, getn(texs) do
		_G["ScriptErrorsFrame"..texs[i]]:SetTexture(nil)
		_G["EventTraceFrame"..texs[i]]:SetTexture(nil)
	end

	S:HandleButton(ScriptErrorsFrame.reload)
	S:HandleNextPrevButton(ScriptErrorsFrame.previous)
	S:HandleNextPrevButton(ScriptErrorsFrame.next)
	S:HandleButton(ScriptErrorsFrame.close)

	S:HandleButton(ScriptErrorsFrame.close)

	E:Point(ScriptErrorsFrame.reload, "BOTTOMLEFT", 12, 8)
	E:Point(ScriptErrorsFrame.previous, "BOTTOM", ScriptErrorsFrame, "BOTTOM", -50, 7)
	E:Point(ScriptErrorsFrame.next, "BOTTOM", ScriptErrorsFrame, "BOTTOM", 50, 7)
	E:Point(ScriptErrorsFrame.close, "BOTTOMRIGHT", -12, 8)

	local noscalemult = E.mult * GetCVar("uiScale")
	HookScript(FrameStackTooltip, "OnShow", function()
		E:SetTemplate(this, "Transparent")
		this:SetBackdropColor(unpack(E["media"].backdropfadecolor))
		this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
	end)

	HookScript(EventTraceTooltip, "OnShow", function()
		E:SetTemplate(this, "Transparent")
	end)

	S:HandleCloseButton(EventTraceFrameCloseButton)
end

S:AddCallbackForAddon("!DebugTools", "SkinDebugTools", LoadSkin)