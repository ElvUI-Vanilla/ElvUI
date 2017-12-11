local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = getfenv()
local unpack = unpack
local select = select
--WoW API / Variables
local UnitName = UnitName
local IsFishingLoot = IsFishingLoot
local GetLootRollItemInfo = GetLootRollItemInfo
local GetItemQualityColor = GetItemQualityColor
local LOOTFRAME_NUMBUTTONS = LOOTFRAME_NUMBUTTONS
local NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES
local LOOT = LOOT

local function LoadSkin()
	-- if E.private.general.loot then return end
	-- if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.loot ~= true then return end

	E:StripTextures(LootFrame)

	E:CreateBackdrop(LootFrame, "Transparent")
	LootFrame.backdrop:SetPoint("TOPLEFT", 13, -14)
	LootFrame.backdrop:SetPoint("BOTTOMRIGHT", -68, 5)

	LootFramePortraitOverlay:SetParent(E.HiddenFrame)

	S:HandleCloseButton(LootCloseButton)

	for i = 1, LootFrame:GetNumRegions() do
		local region = select(i, LootFrame:GetRegions())
		if region:GetObjectType() == "FontString" then
			if region:GetText() == ITEMS then
				LootFrame.Title = region
			end
		end
	end

	LootFrame.Title:ClearAllPoints()
	LootFrame.Title:SetPoint("TOPLEFT", LootFrame.backdrop, "TOPLEFT", 4, -4)
	LootFrame.Title:SetJustifyH("LEFT")

	for i = 1, LOOTFRAME_NUMBUTTONS do
		local button = _G["LootButton" .. i]
		S:HandleItemButton(button, true)
	end

	S:HandleNextPrevButton(LootFrameDownButton)
	S:HandleNextPrevButton(LootFrameUpButton)
	S:SquareButton_SetIcon(LootFrameUpButton, "UP")
	S:SquareButton_SetIcon(LootFrameDownButton, "DOWN")

	HookScript(LootFrame, "OnShow", function()
		if IsFishingLoot() then
			this.Title:SetText(L["Fishy Loot"])
		elseif not UnitIsFriend("player", "target") and UnitIsDead("target") then
			this.Title:SetText(UnitName("target"))
		else
			this.Title:SetText(LOOT)
		end
	end)
end

local function LoadRollSkin()
	-- if E.private.general.lootRoll then return end
	-- if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.lootRoll then return end

	local function OnShow(self)
		E:SetTemplate(self, "Transparent")

		local cornerTexture = _G[self:GetName() .. "Corner"]
		cornerTexture:SetTexture()

		local iconFrame = _G[self:GetName() .. "IconFrame"]
		local _, _, _, quality = GetLootRollItemInfo(self.rollID)
		iconFrame:SetBackdropBorderColor(GetItemQualityColor(quality))
	end

	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local frame = _G["GroupLootFrame" .. i]
		frame:SetParent(UIParent)
		E:StripTextures(frame)

		local frameName = frame:GetName()
		local iconFrame = _G[frameName .. "IconFrame"]
		E:SetTemplate(iconFrame, "Default")

		local icon = _G[frameName .. "IconFrameIcon"]
		E:SetInside(icon)
		icon:SetTexCoord(unpack(E.TexCoords))

		local statusBar = _G[frameName .. "Timer"]
		E:StripTextures(statusBar)
		E:CreateBackdrop(statusBar, "Default")
		statusBar:SetStatusBarTexture(E["media"].normTex)
		E:RegisterStatusBar(statusBar)

		local decoration = _G[frameName .. "Decoration"]
		decoration:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Dragon")
		-- decoration:Size(130)
		decoration:SetWidth(130)
		decoration:SetHeight(130)
		decoration:SetPoint("TOPLEFT", -37, 20)

		local pass = _G[frameName .. "PassButton"]
		S:HandleCloseButton(pass, frame)

		HookScript(_G["GroupLootFrame" .. i], "OnShow", OnShow)
	end
end

S:AddCallback("Loot", LoadSkin)
S:AddCallback("LootRoll", LoadRollSkin)