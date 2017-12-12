local E, L, V, P, G = unpack(ElvUI);
--local D = E:GetModule("Distributor");
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
local AC = LibStub("AceConfig-3.0-ElvUI");
local ACD = LibStub("AceConfigDialog-3.0-ElvUI");
local ACR = LibStub("AceConfigRegistry-3.0-ElvUI");

AC:RegisterOptionsTable("ElvUI", E.Options);
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

local DONATOR_STRING = "";
local DEVELOPER_STRING = "";
local TESTER_STRING = "";
local LINE_BREAK = "\n";
local DONATORS = {
	"Dandruff",
	"Tobur/Tarilya",
	"Netu",
	"Alluren",
	"Thorgnir",
	"Emalal",
	"Bendmeova",
	"Curl",
	"Zarac",
	"Emmo",
	"Oz",
	"Hawké",
	"Aynya",
	"Tahira",
	"Karsten Lumbye Thomsen",
	"Thomas B. aka Pitschiqüü",
	"Sea Garnet",
	"Paul Storry",
	"Azagar",
	"Archury",
	"Donhorn",
	"Woodson Harmon",
	"Phoenyx",
	"Feat",
	"Konungr",
	"Leyrin",
	"Dragonsys",
	"Tkalec",
	"Paavi",
	"Giorgio",
	"Bearscantank",
	"Eidolic",
	"Cosmo",
	"Adorno",
	"Domoaligato",
	"Smorg",
	"Pyrokee",
	"Portable",
	"Ithilyn"
};

local DEVELOPERS = {
	"Tukz",
	"Haste",
	"Nightcracker",
	"Omega1970",
	"Hydrazine"
};

local TESTERS = {
	"Tukui Community",
	"|cffF76ADBSarah|r - For Sarahing",
	"Affinity",
	"Modarch",
	"Bladesdruid",
	"Tirain",
	"Phima",
	"Veiled",
	"Blazeflack",
	"Repooc",
	"Darth Predator",
	"Alex",
	"Nidra",
	"Kurhyus",
	"BuG",
	"Yachanay",
	"Catok"
}

tsort(DONATORS, function(a, b) return a < b end);
for _, donatorName in pairs(DONATORS) do
	tinsert(E.CreditsList, donatorName);
	DONATOR_STRING = DONATOR_STRING .. LINE_BREAK .. donatorName;
end

tsort(DEVELOPERS, function(a,b) return a < b end);
for _, devName in pairs(DEVELOPERS) do
	tinsert(E.CreditsList, devName);
	DEVELOPER_STRING = DEVELOPER_STRING .. LINE_BREAK .. devName;
end

tsort(TESTERS, function(a, b) return a < b end)
for _, testerName in pairs(TESTERS) do
	tinsert(E.CreditsList, testerName);
	TESTER_STRING = TESTER_STRING .. LINE_BREAK .. testerName;
end



