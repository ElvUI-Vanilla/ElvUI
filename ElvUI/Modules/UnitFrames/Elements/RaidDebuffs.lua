local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

--Cache global variables
--Lua functions
local unpack = unpack
--WoW API / Variables
local CreateFrame = CreateFrame

function UF:Construct_RaidDebuffs(frame)
	local rdebuff = CreateFrame("Frame", nil, frame.RaisedElementParent)
	E:SetTemplate(rdebuff, "Default", nil, nil, UF.thinBorders, true)
	rdebuff:SetFrameLevel(frame.RaisedElementParent:GetFrameLevel() + 20) --Make them appear above regular buffs or debuffs

	local offset = UF.thinBorders and E.mult or E.Border
	rdebuff.icon = rdebuff:CreateTexture(nil, "OVERLAY")
	rdebuff.icon:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(rdebuff.icon, rdebuff, offset, offset)

	rdebuff.count = rdebuff:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(rdebuff.count, nil, 10, "OUTLINE")
	E:Point(rdebuff.count, "BOTTOMRIGHT", 0, 2)
	rdebuff.count:SetTextColor(1, .9, 0)

	rdebuff.time = rdebuff:CreateFontString(nil, "OVERLAY")
	E:FontTemplate(rdebuff.time, nil, 10, "OUTLINE")
	E:Point(rdebuff.time, "CENTER")
	rdebuff.time:SetTextColor(1, .9, 0)

	return rdebuff
end

function UF:Configure_RaidDebuffs(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local rdebuffs = frame.RaidDebuffs

	if db.rdebuffs.enable then
		local stackColor = db.rdebuffs.stack.color
		local durationColor = db.rdebuffs.duration.color
		local rdebuffsFont = UF.LSM:Fetch("font", db.rdebuffs.font)
		if not frame:IsElementEnabled("RaidDebuffs") then
			frame:EnableElement("RaidDebuffs")
		end

		rdebuffs.showDispellableDebuff = db.rdebuffs.showDispellableDebuff
		rdebuffs.forceShow = frame.forceShowAuras
		E:Size(rdebuffs, db.rdebuffs.size)
		E:Point(rdebuffs, "BOTTOM", frame, "BOTTOM", db.rdebuffs.xOffset, db.rdebuffs.yOffset + frame.SPACING)

		E:FontTemplate(rdebuffs.count, rdebuffsFont, db.rdebuffs.fontSize, db.rdebuffs.fontOutline)
		rdebuffs.count:ClearAllPoints()
		E:Point(rdebuffs.count, db.rdebuffs.stack.position, db.rdebuffs.stack.xOffset, db.rdebuffs.stack.yOffset)
		rdebuffs.count:SetTextColor(stackColor.r, stackColor.g, stackColor.b, stackColor.a)

		E:FontTemplate(rdebuffs.time, rdebuffsFont, db.rdebuffs.fontSize, db.rdebuffs.fontOutline)
		rdebuffs.time:ClearAllPoints()
		E:Point(rdebuffs.time, db.rdebuffs.duration.position, db.rdebuffs.duration.xOffset, db.rdebuffs.duration.yOffset)
		rdebuffs.time:SetTextColor(durationColor.r, durationColor.g, durationColor.b, durationColor.a)
	elseif frame:IsElementEnabled("RaidDebuffs") then
		frame:DisableElement("RaidDebuffs")
		rdebuffs:Hide()
	end
end