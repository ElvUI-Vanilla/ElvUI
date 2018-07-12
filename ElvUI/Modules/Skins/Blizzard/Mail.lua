local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack
--WoW API / Variables
local GetInboxHeaderInfo = GetInboxHeaderInfo
local GetInboxItem = GetInboxItem
local GetInboxNumItems = GetInboxNumItems
local GetItemInfo = GetItemInfo
local GetItemInfoByName = GetItemInfoByName
local GetItemQualityColor = GetItemQualityColor
local GetSendMailItem = GetSendMailItem
local hooksecurefunc = hooksecurefunc

local INBOXITEMS_TO_DISPLAY = INBOXITEMS_TO_DISPLAY

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.mail ~= true then return end

	-- Inbox Frame
	E:StripTextures(MailFrame, true)
	E:CreateBackdrop(MailFrame, "Transparent")
	E:Point(MailFrame.backdrop, "TOPLEFT", 10, -12)
	E:Point(MailFrame.backdrop, "BOTTOMRIGHT", -30, 74)

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local mail = _G["MailItem"..i]
		local button = _G["MailItem"..i.."Button"]
		local icon = _G["MailItem"..i.."ButtonIcon"]

		E:StripTextures(mail)
		E:CreateBackdrop(mail, "Default")
		E:Point(mail.backdrop, "TOPLEFT", 2, 1)
		E:Point(mail.backdrop, "BOTTOMRIGHT", -2, 2)

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

				if packageIcon and not isGM then
					local itemName = GetInboxItem(index)
					if itemName then
						local _, _, quality = GetItemInfoByName(itemName)

						if quality then
							button:SetBackdropBorderColor(GetItemQualityColor(quality))
						else
							button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
						end
					end
				elseif isGM then
					button:SetBackdropBorderColor(0, 0.56, 0.94)
				else
					button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
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

	E:StripTextures(SendMailPackageButton)
	E:SetTemplate(SendMailPackageButton, "Default", true)
	E:StyleButton(SendMailPackageButton, nil, true)

	hooksecurefunc("SendMailFrame_Update", function()
		local button = SendMailPackageButton
		local texture = button:GetNormalTexture()
		local itemName = GetSendMailItem()

		if itemName then
			local _, _, quality = GetItemInfoByName(itemName)

			if quality then
				button:SetBackdropBorderColor(GetItemQualityColor(quality))
			else
				button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
			texture:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(texture)
		else
			button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)

	SendMailBodyEditBox:SetTextColor(1, 1, 1)

	S:HandleScrollBar(SendMailScrollFrameScrollBar)

	S:HandleEditBox(SendMailNameEditBox)
	E:Point(SendMailNameEditBox.backdrop, "BOTTOMRIGHT", 2, 0)
	E:Point(SendMailNameEditBox, "TOPLEFT", 79, -46)

	S:HandleEditBox(SendMailSubjectEditBox)
	E:Point(SendMailSubjectEditBox.backdrop, "BOTTOMRIGHT", 2, 0)

	S:HandleEditBox(SendMailMoneyGold)
	S:HandleEditBox(SendMailMoneySilver)
	S:HandleEditBox(SendMailMoneyCopper)

	S:HandleButton(SendMailMailButton)
	E:Point(SendMailMailButton, "RIGHT", SendMailCancelButton, "LEFT", -2, 0)

	S:HandleButton(SendMailCancelButton)
	E:Point(SendMailCancelButton, "BOTTOMRIGHT", -45, 80)

	E:Point(SendMailMoneyFrame, "BOTTOMLEFT", 170, 84)

	-- Open Mail Frame
	E:StripTextures(OpenMailFrame, true)
	E:CreateBackdrop(OpenMailFrame, "Transparent")
	E:Point(OpenMailFrame.backdrop, "TOPLEFT", 12, -12)
	E:Point(OpenMailFrame.backdrop, "BOTTOMRIGHT", -34, 74)

	E:StripTextures(OpenMailPackageButton)
	E:StyleButton(OpenMailPackageButton)
	E:SetTemplate(OpenMailPackageButton, "Default", true)

	for _, region in ipairs({OpenMailPackageButton:GetRegions()}) do
		if region:GetObjectType() == "Texture" then
			region:SetTexCoord(unpack(E.TexCoords))
			E:SetInside(region)
		end
	end

	hooksecurefunc("OpenMail_Update", function()
		local index = InboxFrame.openMailID
		if not index then return end

		local _, _, _, _, _, _, _, hasItem = GetInboxHeaderInfo(index)

		if hasItem then
			local button = OpenMailPackageButton
			local texture = button:GetNormalTexture()
			local itemName = GetInboxItem(index)

			if itemName then
				local _, _, quality = GetItemInfoByName(itemName)

				if quality then
					button:SetBackdropBorderColor(GetItemQualityColor(quality))
				else
					button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
				texture:SetTexCoord(unpack(E.TexCoords))
				E:SetInside(texture)
			else
				button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
		end
	end)

	S:HandleCloseButton(OpenMailCloseButton)

	S:HandleButton(OpenMailReplyButton)
	E:Point(OpenMailReplyButton, "RIGHT", OpenMailDeleteButton, "LEFT", -2, 0)

	S:HandleButton(OpenMailDeleteButton)
	E:Point(OpenMailDeleteButton, "RIGHT", OpenMailCancelButton, "LEFT", -2, 0)

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