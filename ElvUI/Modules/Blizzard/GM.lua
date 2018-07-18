local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:GetModule("Blizzard");

function B:PositionGMFrames()
	TicketStatusFrame:ClearAllPoints()
	TicketStatusFrame:SetPoint("TOPLEFT", E.UIParent, "TOPLEFT", 250, -5)

	E:CreateMover(TicketStatusFrame, "GMMover", L["GM Ticket Frame"])
end