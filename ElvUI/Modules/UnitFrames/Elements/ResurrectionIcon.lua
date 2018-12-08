local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

function UF:Construct_ResurrectionIcon(frame)
	local tex = frame.RaisedElementParent.TextureParent:CreateTexture(nil, "OVERLAY")
	tex:SetTexture([[Interface\AddOns\ElvUI\media\textures\Raid-Icon-Rez]])
	E:Point(tex, "CENTER", frame.Health, "CENTER")
	E:Size(tex, 30)
	tex:SetDrawLayer("OVERLAY", 7)

	return tex
end

function UF:Configure_ResurrectionIcon(frame)
	local RI = frame.ResurrectIndicator
	local db = frame.db

	if db.resurrectIcon.enable then
		if not frame:IsElementEnabled("ResurrectIndicator") then
			frame:EnableElement("ResurrectIndicator")
		end
		RI:Show()
		E:Size(RI, db.resurrectIcon.size)

		local attachPoint = self:GetObjectAnchorPoint(frame, db.resurrectIcon.attachToObject)
		RI:ClearAllPoints()
		E:Point(RI, db.resurrectIcon.attachTo, attachPoint, db.resurrectIcon.attachTo, db.resurrectIcon.xOffset, db.resurrectIcon.yOffset)
	else
		if frame:IsElementEnabled("ResurrectIndicator") then
			frame:DisableElement("ResurrectIndicator")
		end
		RI:Hide()
	end
end