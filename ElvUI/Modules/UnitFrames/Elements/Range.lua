local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

function UF:Construct_Range()
	local Range = {insideAlpha = 1, outsideAlpha = E.db.unitframe.OORAlpha}
	Range.Override = UF.UpdateRange

	return Range
end

function UF:Configure_Range(frame)
	local range = frame.Range
	if frame.db.rangeCheck then
		if not frame:IsElementEnabled("Range") then
			frame:EnableElement("Range")
		end

		range.outsideAlpha = E.db.unitframe.OORAlpha
	else
		if frame:IsElementEnabled("Range") then
			frame:DisableElement("Range")
		end
	end
end
