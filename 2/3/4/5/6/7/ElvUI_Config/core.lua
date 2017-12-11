local E, L, V, P, G = unpack(ElvUI);
local D = {};
local AceGUI = LibStub("AceGUI-3.0");

local pairs = pairs;
local tsort, tinsert = table.sort, table.insert;
local format = string.format;

local UnitExists = UnitExists;
local UnitIsFriend = UnitIsFriend;
local UnitIsPlayer = UnitIsPlayer;
local UnitIsUnit = UnitIsUnit;
local UnitName = UnitName;

local DEFAULT_WIDTH = 890;
local DEFAULT_HEIGHT = 651;
local AC = LibStub("AceConfig-3.0");
local ACD = LibStub("AceConfigDialog-3.0");
local ACR = LibStub("AceConfigRegistry-3.0");
AC.RegisterOptionsTable(E, "ElvUI", E.Options);
ACD:SetDefaultSize("ElvUI", DEFAULT_WIDTH, DEFAULT_HEIGHT);

function E:RefreshGUI()
	self:RefreshCustomTextsConfigs();
	ACR:NotifyChange("ElvUI");
end

E.Options.args = {
	ElvUI_Header = {
		order = 1,
		type = "header",
		name = L["Version"] .. format(": |cff99ff33%s|r", E.version),
		width = "full"
	},
	LoginMessage = {
		order = 2,
		type = "toggle",
		name = L["Login Message"],
		get = function(info) return E.db.general.loginmessage; end,
		set = function(info, value) E.db.general.loginmessage = value; end
	},
	ToggleTutorial = {
		order = 3,
		type = "execute",
		name = L["Toggle Tutorials"],
		func = function() E:Tutorials(true); E:ToggleConfig(); end
	},
	Install = {
		order = 4,
		type = "execute",
		name = L["Install"],
		desc = L["Run the installation process."],
		func = function() E:Install(); E:ToggleConfig(); end
	},
	ToggleAnchors = {
		order = 5,
		type = "execute",
		name = L["Toggle Anchors"],
		desc = L["Unlock various elements of the UI to be repositioned."],
		func = function() E:ToggleConfigMode(); end
	},
	ResetAllMovers = {
		order = 6,
		type = "execute",
		name = L["Reset Anchors"],
		desc = L["Reset all frames to their original positions."],
		func = function() E:ResetUI(); end
	}
};