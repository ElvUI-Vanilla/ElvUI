local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack, select = unpack, select
--WoW API / Variables
local hooksecurefunc = hooksecurefunc
local GetInboxItem = GetInboxItem
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetSendMailItem = GetSendMailItem
local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY
local ATTACHMENTS_MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE

local function LoadSkin()
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.mail ~= true then return end

	-- Inbox Frame
	E:StripTextures(MailFrame, true)
	E:CreateBackdrop(MailFrame, "Transparent")
	MailFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
	MailFrame.backdrop:SetPoint("BOTTOMRIGHT", -30, 74)

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local mail = _G["MailItem"..i]
		local button = _G["MailItem"..i.."Button"]
		local icon = _G["MailItem"..i.."ButtonIcon"]

		E:StripTextures(mail)
		E:CreateBackdrop(mail, "Default")
		mail.backdrop:SetPoint("TOPLEFT", 2, 1)
		mail.backdrop:SetPoint("BOTTOMRIGHT", -2, 2)

		E:StripTextures(button)
		E:SetTemplate(button, "Default", true)
		E:StyleButton(button)

		icon:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(icon)
	end

	hooksecurefunc("InboxFrame_Update", function()
		local numItems = GetInboxNumItems()
		local index = ((InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY) + 1

		for i = 1, INBOXITEMS_TO_DISPLAY do
			if index <= numItems then
				local packageIcon, _, _, _, _, _, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(index)
				local button = _G["MailItem"..i.."Button"]

				button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				if packageIcon and not isGM then
					local ItemLink = GetInboxItemLink(index, 1)

					if ItemLink then
						local quality = select(3, GetItemInfo(ItemLink))

						if quality and quality > 1 then
							button:SetBackdropBorderColor(GetItemQualityColor(quality))
						else
							button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
						end
					end
				elseif isGM then
					button:SetBackdropBorderColor(0, 0.56, 0.94)
				end
			end

			index = index + 1
		end
	end)

	S:HandleNextPrevButton(InboxPrevPageButton)
	S:HandleNextPrevButton(InboxNextPageButton)

	S:HandleCloseButton(InboxCloseButton)

	for i = 1, 2 do
		local tab = _G["MailFrameTab"..i]

		E:StripTextures(tab)
		S:HandleTab(tab)
	end

	-- Send Mail Frame
	E:StripTextures(SendMailFrame)

	E:StripTextures(SendMailScrollFrame, true)
	E:SetTemplate(SendMailScrollFrame, "Default")

	-- hooksecurefunc("SendMailFrame_Update", function()
	-- 	for i = 1, ATTACHMENTS_MAX_SEND do
	-- 		local button = _G["SendMailAttachment"..i]
	-- 		local texture = button:GetNormalTexture()
	-- 		local itemName = GetSendMailItem(i)

	-- 		if not button.skinned then
	-- 			E:StripTextures(button)
	-- 			E:SetTemplate(button, "Default", true)
	-- 			E:StyleButton(button, nil, true)

	-- 			button.skinned = true
	-- 		end

	-- 		if itemName then
	-- 			local quality = select(3, GetItemInfo(itemName))

	-- 			if quality and quality > 1 then
	-- 				button:SetBackdropBorderColor(GetItemQualityColor(quality))
	-- 			else
	-- 				button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
	-- 			end

	-- 			texture:SetTexCoord(unpack(E.TexCoords))
	-- 			E:SetInside(texture)
	-- 		else
	-- 			button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
	-- 		end
	-- 	end
	-- end)

	SendMailBodyEditBox:SetTextColor(1, 1, 1)

	S:HandleScrollBar(SendMailScrollFrameScrollBar)

	S:HandleEditBox(SendMailNameEditBox)
	SendMailNameEditBox.backdrop:SetPoint("BOTTOMRIGHT", 2, 0)
	SendMailNameEditBox:SetPoint("TOPLEFT", 79, -46)

	S:HandleEditBox(SendMailSubjectEditBox)
	SendMailSubjectEditBox.backdrop:SetPoint("BOTTOMRIGHT", 2, 0)

	S:HandleEditBox(SendMailMoneyGold)
	S:HandleEditBox(SendMailMoneySilver)
	S:HandleEditBox(SendMailMoneyCopper)

	S:HandleButton(SendMailMailButton)
	SendMailMailButton:SetPoint("RIGHT", SendMailCancelButton, "LEFT", -2, 0)

	S:HandleButton(SendMailCancelButton)
	SendMailCancelButton:SetPoint("BOTTOMRIGHT", -45, 80)

	SendMailMoneyFrame:SetPoint("BOTTOMLEFT", 170, 84)

	-- Open Mail Frame
	E:StripTextures(OpenMailFrame, true)
	E:CreateBackdrop(OpenMailFrame, "Transparent")
	OpenMailFrame.backdrop:SetPoint("TOPLEFT", 12, -12)
	OpenMailFrame.backdrop:SetPoint("BOTTOMRIGHT", -34, 74)

	-- for i = 1, 12 do
	-- 	local button = _G["OpenMailAttachmentButton"..i]
	-- 	local icon = _G["OpenMailAttachmentButton"..i.."IconTexture"]
	-- 	local count = _G["OpenMailAttachmentButton"..i.."Count"]

	-- 	E:StripTextures(button)
	-- 	E:SetTemplate(button, "Default", true)
	-- 	E:StyleButton(button)

	-- 	if icon then
	-- 		icon:SetTexCoord(unpack(E.TexCoords))
	-- 		icon:SetDrawLayer("ARTWORK")
	-- 		E:SetInside(icon)

	-- 		count:SetDrawLayer("OVERLAY")
	-- 	end
	-- end

	-- hooksecurefunc("OpenMailFrame_UpdateButtonPositions", function()
	-- 	for i = 1, ATTACHMENTS_MAX_RECEIVE do
	-- 		local ItemLink = GetInboxItemLink(InboxFrame.openMailID, i)
	-- 		local button = _G["OpenMailAttachmentButton"..i]

	-- 		button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
	-- 		if ItemLink then
	-- 			local quality = select(3, GetItemInfo(ItemLink))

	-- 			if quality and quality > 1 then
	-- 				button:SetBackdropBorderColor(GetItemQualityColor(quality))
	-- 			else
	-- 				button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
	-- 			end
	-- 		end
	-- 	end
	-- end)

	S:HandleCloseButton(OpenMailCloseButton)

	S:HandleButton(OpenMailReplyButton)
	OpenMailReplyButton:SetPoint("RIGHT", OpenMailDeleteButton, "LEFT", -2, 0)

	S:HandleButton(OpenMailDeleteButton)
	OpenMailDeleteButton:SetPoint("RIGHT", OpenMailCancelButton, "LEFT", -2, 0)

	S:HandleButton(OpenMailCancelButton)

	E:StripTextures(OpenMailScrollFrame, true)
	E:SetTemplate(OpenMailScrollFrame, "Default")

	S:HandleScrollBar(OpenMailScrollFrameScrollBar)

	OpenMailBodyText:SetTextColor(1, 1, 1)
	InvoiceTextFontNormal:SetTextColor(1, 1, 1)
	OpenMailInvoiceBuyMode:SetTextColor(1, 0.80, 0.10)

	E:Kill(OpenMailArithmeticLine)

	E:StripTextures(OpenMailLetterButton)
	E:SetTemplate(OpenMailLetterButton, "Default", true)
	E:StyleButton(OpenMailLetterButton)

	OpenMailLetterButtonIconTexture:SetTexCoord(unpack(E.TexCoords))
	OpenMailLetterButtonIconTexture:SetDrawLayer("ARTWORK")
	E:SetInside(OpenMailLetterButtonIconTexture)

	OpenMailLetterButtonCount:SetDrawLayer("OVERLAY")

	E:StripTextures(OpenMailMoneyButton)
	E:SetTemplate(OpenMailMoneyButton, "Default", true)
	E:StyleButton(OpenMailMoneyButton)

	OpenMailMoneyButtonIconTexture:SetTexCoord(unpack(E.TexCoords))
	OpenMailMoneyButtonIconTexture:SetDrawLayer("ARTWORK")
	E:SetInside(OpenMailMoneyButtonIconTexture)

	OpenMailMoneyButtonCount:SetDrawLayer("OVERLAY")
end

S:AddCallback("Mail", LoadSkin)