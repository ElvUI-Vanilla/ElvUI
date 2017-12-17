local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local pairs = pairs
local select = select
local unpack = unpack
local find, format, match,  split = string.find, string.format, string.match, string.split
--WoW API / Variables
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.quest ~= true then return end

	local QuestStrip = {
		"QuestFrame",
		"QuestLogFrame",
		"EmptyQuestLogFrame",
		"QuestFrameDetailPanel",
		"QuestDetailScrollFrame",
		"QuestDetailScrollChildFrame",
		"QuestRewardScrollFrame",
		"QuestRewardScrollChildFrame",
		"QuestFrameProgressPanel",
		"QuestFrameRewardPanel",
		"QuestFrameRewardPanel"
	}

	for _, object in pairs(QuestStrip) do
		E:StripTextures(_G[object], true)
	end

	local QuestButtons = {
		"QuestLogFrameAbandonButton",
		"QuestFrameExitButton",
		"QuestFramePushQuestButton",
		"QuestFrameCompleteButton",
		"QuestFrameGoodbyeButton",
		"QuestFrameCompleteQuestButton",
		"QuestFrameCancelButton",
		"QuestFrameGreetingGoodbyeButton",
		"QuestFrameAcceptButton",
		"QuestFrameDeclineButton"
	}

	for _, button in pairs(QuestButtons) do
		E:StripTextures(_G[button])
		S:HandleButton(_G[button])
	end

	for i = 1, MAX_NUM_ITEMS do
		local item = _G["QuestLogItem"..i]
		local icon = _G["QuestLogItem"..i.."IconTexture"]
		local count = _G["QuestLogItem"..i.."Count"]

		E:StripTextures(item)
		E:SetTemplate(item, "Default")
		E:StyleButton(item)
		item:SetWidth(item:GetWidth() - 4)
		item:SetFrameLevel(item:GetFrameLevel() + 2)

		icon:SetDrawLayer("OVERLAY")
		icon:SetWidth(icon:GetWidth() -(E.Spacing*2))
		icon:SetHeight(icon:GetHeight() -(E.Spacing*2))
		icon:SetPoint("TOPLEFT", E.Border, -E.Border)
		S:HandleIcon(icon)

		count:SetParent(item.backdrop)
		count:SetDrawLayer("OVERLAY")
	end

	for i = 1, 6 do
		local item = _G["QuestDetailItem"..i]
		local icon = _G["QuestDetailItem"..i.."IconTexture"]
		local count = _G["QuestDetailItem"..i.."Count"]

		E:StripTextures(item)
		E:SetTemplate(item, "Default")
		E:StyleButton(item)
		item:SetWidth(item:GetWidth() - 4)
		item:SetFrameLevel(item:GetFrameLevel() + 2)

		icon:SetDrawLayer("OVERLAY")
		icon:SetWidth(icon:GetWidth() -(E.Spacing*2))
		icon:SetHeight(icon:GetHeight() -(E.Spacing*2))
		icon:SetPoint("TOPLEFT", E.Border, -E.Border)
		S:HandleIcon(icon)

		count:SetParent(item.backdrop)
		count:SetDrawLayer("OVERLAY")
	end

	for i = 1, 6 do
		local item = _G["QuestRewardItem"..i]
		local icon = _G["QuestRewardItem"..i.."IconTexture"]
		local count = _G["QuestRewardItem"..i.."Count"]

		E:StripTextures(item)
		E:SetTemplate(item, "Default")
		E:StyleButton(item)
		item:SetWidth(item:GetWidth() - 4)
		item:SetFrameLevel(item:GetFrameLevel() + 2)

		icon:SetDrawLayer("OVERLAY")
		icon:SetWidth(icon:GetWidth() -(E.Spacing*2))
		icon:SetHeight(icon:GetHeight() -(E.Spacing*2))
		icon:SetPoint("TOPLEFT", E.Border, -E.Border)
		S:HandleIcon(icon)

		count:SetParent(item.backdrop)
		count:SetDrawLayer("OVERLAY")
	end

	local function QuestQualityColors(frame, text, quality, link)
		if link and not quality then
			_, _, quality = GetItemInfo(match(link, "item:(%d+)"))
		end

		if quality then
			if frame then
				frame:SetBackdropBorderColor(GetItemQualityColor(quality))
				frame.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
			end
			text:SetTextColor(GetItemQualityColor(quality))
		else
			if frame then
				frame:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				frame.backdrop:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
			text:SetTextColor(1, 1, 1)
		end
	end

	E:StripTextures(QuestRewardItemHighlight)
	E:SetTemplate(QuestRewardItemHighlight, "Default", nil, true)
	QuestRewardItemHighlight:SetBackdropBorderColor(1, 1, 0)
	QuestRewardItemHighlight:SetBackdropColor(0, 0, 0, 0)
	QuestRewardItemHighlight:SetWidth(142)
	QuestRewardItemHighlight:SetHeight(40)

	hooksecurefunc("QuestRewardItem_OnClick", function()
		QuestRewardItemHighlight:ClearAllPoints();
		E:SetOutside(QuestRewardItemHighlight, this:GetName() .. "IconTexture")
		_G[this:GetName() .. "Name"]:SetTextColor(1, 1, 0)

		for i = 1, MAX_NUM_ITEMS do
			local questItem = _G["QuestRewardItem"..i]
			local questName = _G["QuestRewardItem"..i.."Name"]
			local link = questItem.type and GetQuestItemLink(questItem.type, questItem:GetID())

			if questItem ~= this then
				QuestQualityColors(nil, questName, nil, link)
			end
		end
	end)

	local function QuestObjectiveTextColor()
		local numObjectives = GetNumQuestLeaderBoards()
		local objective
		local _, type, finished;
		local numVisibleObjectives = 0
		for i = 1, numObjectives do
			_, type, finished = GetQuestLogLeaderBoard(i)
			if type ~= "spell" then
				numVisibleObjectives = numVisibleObjectives + 1
				objective = _G["QuestLogObjective"..numVisibleObjectives]
				if finished then
					objective:SetTextColor(1, 0.80, 0.10)
				else
					objective:SetTextColor(0.6, 0.6, 0.6)
				end
			end
		end
	end

	hooksecurefunc("QuestLog_UpdateQuestDetails", function()
		local requiredMoney = GetQuestLogRequiredMoney()
		if requiredMoney > 0 then
			if requiredMoney > GetMoney() then
				QuestLogRequiredMoneyText:SetTextColor(0.6, 0.6, 0.6)
			else
				QuestLogRequiredMoneyText:SetTextColor(1, 0.80, 0.10)
			end
		end
	end)

	hooksecurefunc("QuestFrameItems_Update", function(questState)
		local titleTextColor = {1, 0.80, 0.10}
		local textColor = {1, 1, 1}

		QuestDetailObjectiveTitleText:SetTextColor(unpack(titleTextColor))
		QuestDetailRewardTitleText:SetTextColor(unpack(titleTextColor))
		QuestLogDescriptionTitle:SetTextColor(unpack(titleTextColor))
		QuestLogQuestTitle:SetTextColor(unpack(titleTextColor))
		QuestLogTitleText:SetTextColor(unpack(titleTextColor))
		QuestLogRewardTitleText:SetTextColor(unpack(titleTextColor))
		QuestRewardRewardTitleText:SetTextColor(unpack(titleTextColor))
		QuestRewardTitleText:SetTextColor(unpack(titleTextColor))
		QuestTitleText:SetTextColor(unpack(titleTextColor))
		QuestTitleFont:SetTextColor(unpack(titleTextColor))
		QuestTitleFont:SetFont("Fonts\\MORPHEUS.TTF", E.db.general.fontSize + 6)
		QuestTitleFont.SetFont = E.noop

		QuestDescription:SetTextColor(unpack(textColor))
		QuestDetailItemReceiveText:SetTextColor(unpack(textColor))
		QuestDetailSpellLearnText:SetTextColor(unpack(textColor))
		QuestDetailItemChooseText:SetTextColor(unpack(textColor))
		QuestFont:SetTextColor(unpack(textColor))
		QuestFontNormalSmall:SetTextColor(unpack(textColor))
		QuestLogObjectivesText:SetTextColor(unpack(textColor))
		QuestLogQuestDescription:SetTextColor(unpack(textColor))
		QuestLogItemChooseText:SetTextColor(unpack(textColor))
		QuestLogItemReceiveText:SetTextColor(unpack(textColor))
		QuestLogSpellLearnText:SetTextColor(unpack(textColor))
		QuestObjectiveText:SetTextColor(unpack(textColor))
		QuestRewardItemChooseText:SetTextColor(unpack(textColor))
		QuestRewardItemReceiveText:SetTextColor(unpack(textColor))
		QuestRewardSpellLearnText:SetTextColor(unpack(textColor))
		QuestRewardText:SetTextColor(unpack(textColor))

		QuestObjectiveTextColor()

		local numQuestRewards, numQuestChoices
		if questState == "QuestLog" then
			numQuestRewards, numQuestChoices = GetNumQuestLogRewards(), GetNumQuestLogChoices()
		else
			numQuestRewards, numQuestChoices = GetNumQuestRewards(), GetNumQuestChoices()
		end

		local rewardsCount = numQuestChoices + numQuestRewards
		if rewardsCount > 0 then
			local questItem, itemName, link
			local questItemName = questState.."Item"

			for i = 1, rewardsCount do
				questItem = _G[questItemName..i]
				itemName = _G[questItemName..i.."Name"]
				link = questItem.type and (questState == "QuestLog" and GetQuestLogItemLink or GetQuestItemLink)(questItem.type, questItem:GetID())

				QuestQualityColors(questItem, itemName, nil, link)
			end
		end
	end)

	QuestLogTimerText:SetTextColor(1, 1, 1)

	HookScript(QuestFrameGreetingPanel, "OnShow", function()
		GreetingText:SetTextColor(1, 0.80, 0.10)
		CurrentQuestsText:SetTextColor(1, 1, 1)
		AvailableQuestsText:SetTextColor(1, 1, 1)
	end)

	E:CreateBackdrop(QuestFrame, "Transparent")
	QuestFrame.backdrop:SetPoint("TOPLEFT", 15, -19)
	QuestFrame.backdrop:SetPoint("BOTTOMRIGHT", -30, 67)

	E:CreateBackdrop(QuestLogFrame, "Transparent")
	QuestLogFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	QuestLogFrame.backdrop:SetPoint("BOTTOMRIGHT", -1, 8)

	E:StripTextures(QuestLogListScrollFrame)
	E:CreateBackdrop(QuestLogListScrollFrame, "Default", true)
	QuestLogListScrollFrame:SetWidth(334)

	E:StripTextures(QuestLogDetailScrollFrame)
	E:CreateBackdrop(QuestLogDetailScrollFrame, "Default", true)
	QuestLogDetailScrollFrame:SetWidth(334)
	QuestLogDetailScrollFrame:SetHeight(296)
	QuestLogDetailScrollFrame:ClearAllPoints()
	QuestLogDetailScrollFrame:SetPoint("TOPRIGHT", QuestLogListScrollFrame, "BOTTOMRIGHT", 0, -6)

	QuestLogNoQuestsText:ClearAllPoints()
	QuestLogNoQuestsText:SetPoint("CENTER", EmptyQuestLogFrame, "CENTER", -45, 65)

	QuestLogFrameAbandonButton:SetPoint("BOTTOMLEFT", 18, 15)
	QuestLogFrameAbandonButton:SetWidth(126)

	QuestFramePushQuestButton:ClearAllPoints()
	QuestFramePushQuestButton:SetPoint("BOTTOM", QuestFrame, "BOTTOM", 18, 15)
	QuestFramePushQuestButton:SetWidth(118)

	QuestFrameExitButton:SetPoint("BOTTOMRIGHT", -8, 15)
	QuestFrameExitButton:SetWidth(100)

	S:HandleScrollBar(QuestLogDetailScrollFrameScrollBar)
	S:HandleScrollBar(QuestDetailScrollFrameScrollBar)
	S:HandleScrollBar(QuestLogListScrollFrameScrollBar)
	S:HandleScrollBar(QuestProgressScrollFrameScrollBar)
	S:HandleScrollBar(QuestRewardScrollFrameScrollBar)

	S:HandleCloseButton(QuestFrameCloseButton)

	S:HandleCloseButton(QuestLogFrameCloseButton)
	QuestLogFrameCloseButton:ClearAllPoints()
	QuestLogFrameCloseButton:SetPoint("TOPRIGHT", 2, -9)

	QuestLogTrack:Hide()

	local QuestTrack = CreateFrame("Button", "QuestTrack", QuestLogFrame, "UIPanelButtonTemplate")

	S:HandleButton(QuestTrack)
	QuestTrack:SetText(TRACK_QUEST)
	QuestTrack:SetPoint("TOP", QuestLogFrame, "TOP", -64, -42)
	QuestTrack:SetWidth(110)
	QuestTrack:SetHeight(21)

	HookScript(QuestTrack, "OnClick", function()
		if IsQuestWatched(GetQuestLogSelection()) then
			RemoveQuestWatch(GetQuestLogSelection())

			QuestWatch_Update()
		else
			if GetNumQuestLeaderBoards(GetQuestLogSelection()) == 0 then
				UIErrorsFrame:AddMessage(QUEST_WATCH_NO_OBJECTIVES, 1.0, 0.1, 0.1, 1.0)
				return
			end

			if GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS then
				UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, MAX_WATCHABLE_QUESTS), 1.0, 0.1, 0.1, 1.0)
				return
			end

			AddQuestWatch(GetQuestLogSelection())

			QuestLog_Update()
			QuestWatch_Update()
		end

		QuestLog_Update()
	end)

	hooksecurefunc("QuestLog_Update", function()
		local numEntries = GetNumQuestLogEntries()
		if numEntries == 0 then
			QuestTrack:Disable()
		else
			QuestTrack:Enable()
		end
		if EmptyQuestLogFrame:IsVisible() then
			QuestLogListScrollFrame:Hide()
		else
			QuestLogListScrollFrame:Show()
		end
	end)

	for i = 1, 6 do
		local item = _G["QuestProgressItem"..i]
		local icon = _G["QuestProgressItem"..i.."IconTexture"]
		local count = _G["QuestProgressItem"..i.."Count"]

		E:StripTextures(item)
		E:SetTemplate(item, "Default")
		E:StyleButton(item)
		item:SetWidth(item:GetWidth() - 4)
		item:SetFrameLevel(item:GetFrameLevel() + 2)

		icon:SetDrawLayer("OVERLAY")
		icon:SetWidth(icon:GetWidth() -(E.Spacing*2))
		icon:SetHeight(icon:GetHeight() -(E.Spacing*2))
		icon:SetPoint("TOPLEFT", E.Border, -E.Border)
		S:HandleIcon(icon)

		count:SetParent(item.backdrop)
		count:SetDrawLayer("OVERLAY")
	end

	hooksecurefunc("QuestFrameProgressItems_Update", function()
		QuestProgressTitleText:SetTextColor(1, 0.80, 0.10)
		QuestProgressText:SetTextColor(1, 1, 1)

		QuestProgressRequiredItemsText:SetTextColor(1, 0.80, 0.10)

		if GetQuestMoneyToGet() > GetMoney() then
			QuestProgressRequiredMoneyText:SetTextColor(0.6, 0.6, 0.6)
		else
			QuestProgressRequiredMoneyText:SetTextColor(1, 0.80, 0.10)
		end

		for i = 1, MAX_REQUIRED_ITEMS do
			local item = _G["QuestProgressItem"..i]
			local name = _G["QuestProgressItem"..i.."Name"]
			local link = item.type and GetQuestItemLink(item.type, item:GetID())

			QuestQualityColors(item, name, nil, link)
		end
	end)

	for i = 1, QUESTS_DISPLAYED do
		local questLogTitle = _G["QuestLogTitle"..i]

		questLogTitle:SetNormalTexture("")
		questLogTitle.SetNormalTexture = E.noop

		_G["QuestLogTitle"..i.."Highlight"]:SetTexture("")
		_G["QuestLogTitle"..i.."Highlight"].SetTexture = E.noop

		questLogTitle.Text = questLogTitle:CreateFontString(nil, "OVERLAY")
		E:FontTemplate(questLogTitle.Text, nil, 22)
		questLogTitle.Text:SetPoint("LEFT", 3, 0)
		questLogTitle.Text:SetText("+")

		hooksecurefunc(questLogTitle, "SetNormalTexture", function(self, texture)
			if find(texture, "MinusButton") then
				self.Text:SetText("-")
			elseif find(texture, "PlusButton") then
				self.Text:SetText("+")
			else
				self.Text:SetText("")
			end
		end)
	end

	E:StripTextures(QuestLogCollapseAllButton)
	QuestLogCollapseAllButton:SetNormalTexture("")
	QuestLogCollapseAllButton.SetNormalTexture = E.noop
	QuestLogCollapseAllButton:SetHighlightTexture("")
	QuestLogCollapseAllButton.SetHighlightTexture = E.noop
	QuestLogCollapseAllButton:SetDisabledTexture("")
	QuestLogCollapseAllButton.SetDisabledTexture = E.noop
	QuestLogCollapseAllButton:SetPoint("TOPLEFT", -45, 7)

	QuestLogCollapseAllButton.Text = QuestLogCollapseAllButton:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(QuestLogCollapseAllButton.Text, nil, 22)
	QuestLogCollapseAllButton.Text:SetPoint("LEFT", 3, 0)
	QuestLogCollapseAllButton.Text:SetText("+")

	hooksecurefunc(QuestLogCollapseAllButton, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self.Text:SetText("-")
		else
			self.Text:SetText("+")
		end
	end)
end

S:AddCallback("Quest", LoadSkin)