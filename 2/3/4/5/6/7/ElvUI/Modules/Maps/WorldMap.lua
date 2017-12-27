local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:NewModule("WorldMap", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");
E.WorldMap = M

--Cache global variables
--Lua functions
local format = string.format
--WoW API / Variables
local CreateFrame = CreateFrame
local GetPlayerMapPosition = GetPlayerMapPosition
local GetCursorPosition = GetCursorPosition
local PLAYER = PLAYER

local INVERTED_POINTS = {
	["TOPLEFT"] = "BOTTOMLEFT",
	["TOPRIGHT"] = "BOTTOMRIGHT",
	["BOTTOMLEFT"] = "TOPLEFT",
	["BOTTOMRIGHT"] = "TOPRIGHT",
	["TOP"] = "BOTTOM",
	["BOTTOM"] = "TOP"
}

function M:UpdateCoords()
	if not WorldMapFrame:IsShown() then return end
	local x, y = GetPlayerMapPosition("player")
	x = x and E:Round(100 * x, 2) or 0
	y = y and E:Round(100 * y, 2) or 0

	if x ~= 0 and y ~= 0 then
		CoordsHolder.playerCoords:SetText(PLAYER..":   "..format("%.2f, %.2f", x, y))
	else
		CoordsHolder.playerCoords:SetText("")
	end

	local scale = WorldMapDetailFrame:GetEffectiveScale()
	local width = WorldMapDetailFrame:GetWidth()
	local height = WorldMapDetailFrame:GetHeight()
	local centerX, centerY = WorldMapDetailFrame:GetCenter()
	local x, y = GetCursorPosition()
	local adjustedX = (x / scale - (centerX - (width / 2))) / width
	local adjustedY = (centerY + (height / 2) - y / scale) / height

	if adjustedX >= 0 and adjustedY >= 0 and adjustedX <= 1 and adjustedY <= 1 then
		adjustedX = E:Round(100 * adjustedX, 2)
		adjustedY = E:Round(100 * adjustedY, 2)
		CoordsHolder.mouseCoords:SetText("MOUSE_LABEL"..":  "..format("%.2f, %.2f", adjustedX, adjustedY))
	else
		CoordsHolder.mouseCoords:SetText("")
	end
end

function M:PositionCoords()
	local db = E.global.general.WorldMapCoordinates
	local position = db.position
	local xOffset = db.xOffset
	local yOffset = db.yOffset

	local x, y = 5, 5
	if position == "BOTTOMRIGHT" or position == "TOPRIGHT" then x = -5 end
	if position == "TOPLEFT" or position == "TOP" or position == "TOPRIGHT" then y = -5 end

	CoordsHolder.playerCoords:ClearAllPoints()
	CoordsHolder.playerCoords:SetPoint(position, WorldMapDetailFrame, position, x + xOffset, y + yOffset)
	CoordsHolder.mouseCoords:ClearAllPoints()
	CoordsHolder.mouseCoords:SetPoint(position, CoordsHolder.playerCoords, INVERTED_POINTS[position], 0, y)
end

function M:Initialize()
	if E.global.general.WorldMapCoordinates.enable then
		local coordsHolder = CreateFrame("Frame", "CoordsHolder", WorldMapFrame)
		coordsHolder:SetFrameStrata(WorldMapDetailFrame:GetFrameStrata())
		coordsHolder.playerCoords = coordsHolder:CreateFontString(nil, "OVERLAY")
		coordsHolder.mouseCoords = coordsHolder:CreateFontString(nil, "OVERLAY")
		coordsHolder.playerCoords:SetTextColor(1, 1 ,0)
		coordsHolder.mouseCoords:SetTextColor(1, 1 ,0)
		coordsHolder.playerCoords:SetFontObject(NumberFontNormal)
		coordsHolder.mouseCoords:SetFontObject(NumberFontNormal)
		coordsHolder.playerCoords:SetPoint("BOTTOMLEFT", WorldMapDetailFrame, "BOTTOMLEFT", 5, 5)
		coordsHolder.playerCoords:SetText(PLAYER..":   0, 0")
		coordsHolder.mouseCoords:SetPoint("BOTTOMLEFT", coordsHolder.playerCoords, "TOPLEFT", 0, 5)
		coordsHolder.mouseCoords:SetText("MOUSE_LABEL"..":   0, 0")

		coordsHolder:SetScript("OnUpdate", self.UpdateCoords)

		self:PositionCoords()
	end

	if E.global.general.smallerWorldMap then
		BlackoutWorld:SetTexture(nil)

		WorldMapFrame:SetParent(UIParent)
		WorldMapFrame:EnableKeyboard(false)
		HookScript(WorldMapFrame, "OnShow", function()
			WorldMapFrame:SetScale(E.UIParent:GetScale())
		end)
		WorldMapFrame:EnableMouse(false)

		UIPanelWindows["WorldMapFrame"] = {area = "center", pushable = 0, whileDead = 1}

		HookScript(DropDownList1, "OnShow", function()
			if DropDownList1:GetScale() ~= UIParent:GetScale() then
				DropDownList1:SetScale(UIParent:GetScale())
			end
		end)
	end
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterInitialModule(M:GetName(), InitializeCallback)