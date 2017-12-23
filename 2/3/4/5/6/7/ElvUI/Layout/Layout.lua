local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local LO = E:NewModule("Layout", "AceEvent-3.0");

--Cache global variables
--Lua functions

--WoW API / Variables
local CreateFrame = CreateFrame
local UIFrameFadeIn, UIFrameFadeOut = UIFrameFadeIn, UIFrameFadeOut

local PANEL_HEIGHT = 22
local SIDE_BUTTON_WIDTH = 16

E.Layout = LO

local function Panel_OnShow(self)
	self:SetFrameLevel(0)
	self:SetFrameStrata("BACKGROUND")
end

function LO:Initialize()
	self:CreateChatPanels()
	self:CreateMinimapPanels()

	self:SetDataPanelStyle()

	self.BottomPanel = CreateFrame("Frame", "ElvUI_BottomPanel", E.UIParent)
	E:SetTemplate(self.BottomPanel, "Transparent")
	self.BottomPanel:SetPoint("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", -1, -1)
	self.BottomPanel:SetPoint("BOTTOMRIGHT", E.UIParent, "BOTTOMRIGHT", 1, -1)
	self.BottomPanel:SetHeight(PANEL_HEIGHT)
	self.BottomPanel:SetScript("OnShow", function() Panel_OnShow(this) end)
	Panel_OnShow(self.BottomPanel)
	self:BottomPanelVisibility()

	self.TopPanel = CreateFrame("Frame", "ElvUI_TopPanel", E.UIParent)
	E:SetTemplate(self.TopPanel, "Transparent")
	self.TopPanel:SetPoint("TOPLEFT", E.UIParent, "TOPLEFT", -1, 1)
	self.TopPanel:SetPoint("TOPRIGHT", E.UIParent, "TOPRIGHT", 1, 1)
	self.TopPanel:SetHeight(PANEL_HEIGHT)
	self.TopPanel:SetScript("OnShow", function() Panel_OnShow(this) end)
	Panel_OnShow(self.TopPanel)
	self:TopPanelVisibility()
end

function LO:BottomPanelVisibility()
	if(E.db.general.bottomPanel) then
		self.BottomPanel:Show()
	else
		self.BottomPanel:Hide()
	end
end

function LO:TopPanelVisibility()
	if E.db.general.topPanel then
		self.TopPanel:Show()
	else
		self.TopPanel:Hide()
	end
end

local function ChatPanelLeft_OnFade()
	LeftChatPanel:Hide()
end

local function ChatPanelRight_OnFade()
	RightChatPanel:Hide()
end

local function ChatButton_OnEnter()
	if E.db[this.parent:GetName().."Faded"] then
		this.parent:Show()
		UIFrameFadeIn(this.parent, 0.2, this.parent:GetAlpha(), 1)
		UIFrameFadeIn(this, 0.2, this:GetAlpha(), 1)
	end

	if this == LeftChatToggleButton then
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 0, (E.PixelMode and 1 or 3))
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Chat Frame"], 1, 1, 1)
	else
		GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT", 0, (E.PixelMode and 1 or 3))
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Chat Frame"], 1, 1, 1)
	end

	GameTooltip:Show()
end

local function ChatButton_OnLeave()
	if E.db[this.parent:GetName().."Faded"] then
		UIFrameFadeOut(this.parent, 0.2, this.parent:GetAlpha(), 0)
		UIFrameFadeOut(this, 0.2, this:GetAlpha(), 0)
		this.parent.fadeInfo.finishedFunc = this.parent.fadeFunc
	end
	GameTooltip:Hide()
end

local function ChatButton_OnClick()
	GameTooltip:Hide()
	if E.db[this.parent:GetName().."Faded"] then
		E.db[this.parent:GetName().."Faded"] = nil
		UIFrameFadeIn(this.parent, 0.2, this.parent:GetAlpha(), 1)
		UIFrameFadeIn(this, 0.2, this:GetAlpha(), 1)
	else
		E.db[this.parent:GetName().."Faded"] = true
		UIFrameFadeOut(this.parent, 0.2, this.parent:GetAlpha(), 0)
		UIFrameFadeOut(this, 0.2, this:GetAlpha(), 0)
		this.parent.fadeInfo.finishedFunc = this.parent.fadeFunc
	end
end

function HideLeftChat()
	ChatButton_OnClick(LeftChatToggleButton)
end

function HideRightChat()
	ChatButton_OnClick(RightChatToggleButton)
end

function HideBothChat()
	ChatButton_OnClick(LeftChatToggleButton)
	ChatButton_OnClick(RightChatToggleButton)
end

function LO:ToggleChatTabPanels(rightOverride, leftOverride)
	if leftOverride or not E.db.chat.panelTabBackdrop then
		LeftChatTab:Hide()
	else
		LeftChatTab:Show()
	end

	if rightOverride or not E.db.chat.panelTabBackdrop then
		RightChatTab:Hide()
	else
		RightChatTab:Show()
	end
end

function LO:SetChatTabStyle()
	if E.db.chat.panelTabTransparency then
		E:SetTemplate(LeftChatTab, "Transparent")
		E:SetTemplate(RightChatTab, "Transparent")
	else
		E:SetTemplate(LeftChatTab, "Default", true)
		E:SetTemplate(RightChatTab, "Default", true)
	end
end

function LO:SetDataPanelStyle()
	if E.db.datatexts.panelTransparency then
		if not E.db.datatexts.panelBackdrop then
			E:SetTemplate(LeftChatDataPanel, "NoBackdrop")
			E:SetTemplate(LeftChatToggleButton, "NoBackdrop")
			E:SetTemplate(RightChatDataPanel, "NoBackdrop")
			E:SetTemplate(RightChatToggleButton, "NoBackdrop")
		else
			E:SetTemplate(LeftChatDataPanel, "Transparent")
			E:SetTemplate(LeftChatToggleButton, "Transparent")
			E:SetTemplate(RightChatDataPanel, "Transparent")
			E:SetTemplate(RightChatToggleButton, "Transparent")
		end

		E:SetTemplate(LeftMiniPanel, "Transparent")
		E:SetTemplate(RightMiniPanel, "Transparent")
	else
		if not E.db.datatexts.panelBackdrop then
			E:SetTemplate(LeftChatDataPanel, "NoBackdrop")
			E:SetTemplate(LeftChatToggleButton, "NoBackdrop")
			E:SetTemplate(RightChatDataPanel, "NoBackdrop")
			E:SetTemplate(RightChatToggleButton, "NoBackdrop")
		else
			E:SetTemplate(LeftChatDataPanel, "Default", true)
			E:SetTemplate(LeftChatToggleButton, "Default", true)
			E:SetTemplate(RightChatDataPanel, "Default", true)
			E:SetTemplate(RightChatToggleButton, "Default", true)
		end

		E:SetTemplate(RightMiniPanel, "Default", true)
		E:SetTemplate(LeftMiniPanel, "Default", true)
	end
end

function LO:ToggleChatPanels()
	LeftChatDataPanel:ClearAllPoints()
	RightChatDataPanel:ClearAllPoints()
	local SPACING = E.Border*3 - E.Spacing

	if E.db.datatexts.leftChatPanel then
		LeftChatDataPanel:Show()
		LeftChatToggleButton:Show()
	else
		LeftChatDataPanel:Hide()
		LeftChatToggleButton:Hide()
	end

	if E.db.datatexts.rightChatPanel then
		RightChatDataPanel:Show()
		RightChatToggleButton:Show()
	else
		RightChatDataPanel:Hide()
		RightChatToggleButton:Hide()
	end

	local panelBackdrop = E.db.chat.panelBackdrop
	if(panelBackdrop == "SHOWBOTH") then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SPACING + SIDE_BUTTON_WIDTH, SPACING)
		RightChatDataPanel:SetPoint("BOTTOMLEFT", RightChatPanel, "BOTTOMLEFT", SPACING, SPACING)
		LeftChatToggleButton:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SPACING, SPACING)
		RightChatToggleButton:SetPoint("BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", -SPACING, SPACING)
		LO:ToggleChatTabPanels()
	elseif(panelBackdrop == "HIDEBOTH") then
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SIDE_BUTTON_WIDTH, 0)
		RightChatDataPanel:SetPoint("BOTTOMLEFT", RightChatPanel, "BOTTOMLEFT")
		LeftChatToggleButton:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT")
		RightChatToggleButton:SetPoint("BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT")
		LO:ToggleChatTabPanels(true, true)
	elseif(panelBackdrop == "LEFT") then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SPACING + SIDE_BUTTON_WIDTH, SPACING)
		RightChatDataPanel:SetPoint("BOTTOMLEFT", RightChatPanel, "BOTTOMLEFT")
		LeftChatToggleButton:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SPACING, SPACING)
		RightChatToggleButton:SetPoint("BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT")
		LO:ToggleChatTabPanels(true)
	else
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT", SIDE_BUTTON_WIDTH, 0)
		RightChatDataPanel:SetPoint("BOTTOMLEFT", RightChatPanel, "BOTTOMLEFT", SPACING, SPACING)
		LeftChatToggleButton:SetPoint("BOTTOMLEFT", LeftChatPanel, "BOTTOMLEFT")
		RightChatToggleButton:SetPoint("BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", -SPACING, SPACING)
		LO:ToggleChatTabPanels(nil, true)
	end
end

function LO:CreateChatPanels()
	local SPACING = E.Border*3 - E.Spacing
	--Left Chat
	local lchat = CreateFrame("Frame", "LeftChatPanel", E.UIParent)
	lchat:SetFrameStrata("BACKGROUND")
	lchat:SetWidth(E.db.chat.panelWidth)
	lchat:SetHeight(E.db.chat.panelHeight)
	lchat:SetPoint("BOTTOMLEFT", E.UIParent, 4, 4)
	lchat:SetFrameLevel(lchat:GetFrameLevel() + 2)
	E:CreateBackdrop(lchat, "Transparent")
	lchat.backdrop:SetAllPoints()
	E:CreateMover(lchat, "LeftChatMover", L["Left Chat"])

	--Background Texture
	lchat.tex = lchat:CreateTexture(nil, "OVERLAY")
	E:SetInside(lchat.tex)
	lchat.tex:SetTexture(E.db.chat.panelBackdropNameLeft)
	lchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Left Chat Tab
	local lchattab = CreateFrame("Frame", "LeftChatTab", LeftChatPanel)
	lchattab:SetPoint("TOPLEFT", lchat, "TOPLEFT", SPACING, -SPACING)
	lchattab:SetPoint("BOTTOMRIGHT", lchat, "TOPRIGHT", -SPACING, -(SPACING + PANEL_HEIGHT))
	E:SetTemplate(lchattab, E.db.chat.panelTabTransparency == true and "Transparent" or "Default", true)

	--Left Chat Data Panel
	local lchatdp = CreateFrame("Frame", "LeftChatDataPanel", LeftChatPanel)
	lchatdp:SetWidth(E.db.chat.panelWidth -((SPACING*2) + SIDE_BUTTON_WIDTH))
	lchatdp:SetHeight(PANEL_HEIGHT)
	lchatdp:SetPoint("BOTTOMLEFT", lchat, "BOTTOMLEFT", SPACING + SIDE_BUTTON_WIDTH, SPACING)
	E:SetTemplate(lchatdp, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	E:GetModule("DataTexts"):RegisterPanel(lchatdp, 3, "ANCHOR_TOPLEFT", -16, (E.PixelMode and 1 or 3))

	--Left Chat Toggle Button
	local lchattb = CreateFrame("Button", "LeftChatToggleButton", E.UIParent)
	lchattb.parent = LeftChatPanel
	LeftChatPanel.fadeFunc = ChatPanelLeft_OnFade
	lchattb:SetPoint("TOPRIGHT", lchatdp, "TOPLEFT", E.Border - E.Spacing*3, 0)
	lchattb:SetPoint("BOTTOMLEFT", lchat, "BOTTOMLEFT", SPACING, SPACING)
	E:SetTemplate(lchattb, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	lchattb:SetScript("OnEnter", ChatButton_OnEnter)
	lchattb:SetScript("OnLeave", ChatButton_OnLeave)
	lchattb:SetScript("OnClick", ChatButton_OnClick)
	lchattb.text = lchattb:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(lchattb.text)
	lchattb.text:SetPoint("CENTER", lchattb)
	lchattb.text:SetJustifyH("CENTER")
	lchattb.text:SetText("<")

	--Right Chat
	local rchat = CreateFrame("Frame", "RightChatPanel", E.UIParent)
	rchat:SetFrameStrata("BACKGROUND")
	rchat:SetWidth(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth)
	rchat:SetHeight(E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	rchat:SetPoint("BOTTOMRIGHT", E.UIParent, -4, 4)
	rchat:SetFrameLevel(lchat:GetFrameLevel() + 2)
	E:CreateBackdrop(rchat, "Transparent")
	rchat.backdrop:SetAllPoints()
	E:CreateMover(rchat, "RightChatMover", L["Right Chat"])

	--Background Texture
	rchat.tex = rchat:CreateTexture(nil, "OVERLAY")
	E:SetInside(rchat.tex)
	rchat.tex:SetTexture(E.db.chat.panelBackdropNameRight)
	rchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Right Chat Tab
	local rchattab = CreateFrame("Frame", "RightChatTab", RightChatPanel)
	rchattab:SetPoint("TOPRIGHT", rchat, "TOPRIGHT", -SPACING, -SPACING)
	rchattab:SetPoint("BOTTOMLEFT", rchat, "TOPLEFT", SPACING, -(SPACING + PANEL_HEIGHT))
	E:SetTemplate(rchattab, E.db.chat.panelTabTransparency == true and "Transparent" or "Default", true)

	--Right Chat Data Panel
	local rchatdp = CreateFrame("Frame", "RightChatDataPanel", RightChatPanel)
	rchatdp:SetWidth((E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth) -((SPACING*2) + SIDE_BUTTON_WIDTH))
	rchatdp:SetHeight(PANEL_HEIGHT)
	rchatdp:SetPoint("BOTTOMLEFT", rchat, "BOTTOMLEFT", SPACING, SPACING)
	E:SetTemplate(rchatdp, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	E:GetModule("DataTexts"):RegisterPanel(rchatdp, 3, "ANCHOR_TOPRIGHT", 16, (E.PixelMode and 1 or 3))

	--Right Chat Toggle Button
	local rchattb = CreateFrame("Button", "RightChatToggleButton", E.UIParent)
	rchattb.parent = RightChatPanel
	RightChatPanel.fadeFunc = ChatPanelRight_OnFade
	rchattb:SetPoint("TOPLEFT", rchatdp, "TOPRIGHT", -E.Border + E.Spacing*3, 0)
	rchattb:SetPoint("BOTTOMRIGHT", rchat, "BOTTOMRIGHT", -SPACING, SPACING)
	E:SetTemplate(rchattb, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	rchattb:SetScript("OnEnter", ChatButton_OnEnter)
	rchattb:SetScript("OnLeave", ChatButton_OnLeave)
	rchattb:SetScript("OnClick", ChatButton_OnClick)
	rchattb.text = rchattb:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(rchattb.text)
	rchattb.text:SetPoint("CENTER", rchattb)
	rchattb.text:SetJustifyH("CENTER")
	rchattb.text:SetText(">")

	--Load Settings
	if E.db["LeftChatPanelFaded"] then
		LeftChatToggleButton:SetAlpha(0)
		LeftChatPanel:Hide()
	end

	if E.db["RightChatPanelFaded"] then
		RightChatToggleButton:SetAlpha(0)
		RightChatPanel:Hide()
	end

	self:ToggleChatPanels()
end

function LO:CreateMinimapPanels()
	local lminipanel = CreateFrame("Frame", "LeftMiniPanel", Minimap.backdrop)
	lminipanel:SetWidth(E.db.general.minimap.size/2 + (E.PixelMode and 1 or 3))
	lminipanel:SetHeight(PANEL_HEIGHT)
	lminipanel:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", -E.Border, (E.PixelMode and 0 or -3))
	E:SetTemplate(lminipanel, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	E:GetModule("DataTexts"):RegisterPanel(lminipanel, 1, "ANCHOR_BOTTOMLEFT", lminipanel:GetWidth() * 2, -(E.PixelMode and 1 or 3))

	local rminipanel = CreateFrame("Frame", "RightMiniPanel", Minimap.backdrop)
	rminipanel:SetWidth(E.db.general.minimap.size/2 + (E.PixelMode and 1 or 3))
	rminipanel:SetHeight(PANEL_HEIGHT)
	rminipanel:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", E.Border, (E.PixelMode and 0 or -3))
	E:SetTemplate(rminipanel, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)
	E:GetModule("DataTexts"):RegisterPanel(rminipanel, 1, "ANCHOR_BOTTOM", 0, -(E.PixelMode and 1 or 3))

	if E.db.datatexts.minimapPanels then
		LeftMiniPanel:Show()
		RightMiniPanel:Show()
	else
		LeftMiniPanel:Hide()
		RightMiniPanel:Hide()
	end

	local configtoggle = CreateFrame("Button", "ElvConfigToggle", Minimap.backdrop)
	if E.db.general.reminder.position == "LEFT" then
		configtoggle:SetPoint("TOPRIGHT", lminipanel, "TOPLEFT", (E.PixelMode and 1 or -1), 0);
		configtoggle:SetPoint("BOTTOMRIGHT", lminipanel, "BOTTOMLEFT", (E.PixelMode and 1 or -1), 0);
	else
		configtoggle:SetPoint("TOPLEFT", rminipanel, "TOPRIGHT", (E.PixelMode and -1 or 1), 0);
		configtoggle:SetPoint("BOTTOMLEFT", rminipanel, "BOTTOMRIGHT", (E.PixelMode and -1 or 1), 0);
	end

	configtoggle:RegisterForClicks("AnyUp")
	configtoggle:SetWidth(E.RBRWidth)
	E:SetTemplate(configtoggle, E.db.datatexts.panelTransparency and "Transparent" or "Default", true)

	configtoggle.text = configtoggle:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(configtoggle.text, E.LSM:Fetch("font", E.db.datatexts.font), E.db.datatexts.fontSize, E.db.datatexts.fontOutline)
	configtoggle.text:SetText("C")
	configtoggle.text:SetPoint("CENTER", 0, 0)
	configtoggle.text:SetJustifyH("CENTER")

	configtoggle:SetScript("OnClick", function(_, btn)
		if btn == "LeftButton" then
			E:ToggleConfig()
		else
			E:BGStats()
		end
	end)

	configtoggle:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, -4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Configuration"], 1, 1, 1)

		if E.db.datatexts.battleground then
			GameTooltip:AddDoubleLine(L["Right Click:"], L["Show BG Texts"], 1, 1, 1)
		end
		GameTooltip:Show()
	end)

	configtoggle:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local f = CreateFrame("Frame", "BottomMiniPanel", Minimap.backdrop)
	f:SetPoint("BOTTOM", Minimap, "BOTTOM")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOM", 0, -10)

	f = CreateFrame("Frame", "TopMiniPanel", Minimap.backdrop)
	f:SetPoint("TOP", Minimap, "TOP")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOM", 0, -10)

	f = CreateFrame("Frame", "TopLeftMiniPanel", Minimap.backdrop)
	f:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOMLEFT", 0, -10)

	f = CreateFrame("Frame", "TopRightMiniPanel", Minimap.backdrop)
	f:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOMRIGHT", 0, -10)

	f = CreateFrame("Frame", "BottomLeftMiniPanel", Minimap.backdrop)
	f:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOMLEFT", 0, -10)

	f = CreateFrame("Frame", "BottomRightMiniPanel", Minimap.backdrop)
	f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
	f:SetWidth(75)
	f:SetHeight(20)
	E:GetModule("DataTexts"):RegisterPanel(f, 1, "ANCHOR_BOTTOMRIGHT", 0, -10)
end

local function InitializeCallback()
	LO:Initialize()
end

E:RegisterModule(LO:GetName(), InitializeCallback)