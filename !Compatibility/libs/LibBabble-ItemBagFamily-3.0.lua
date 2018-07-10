local MAJOR_VERSION = "LibBabble-ItemFamily-3.0"
local MINOR_VERSION = 90000 + tonumber(string.match("$Revision: 50 $", "%d+"))

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub("LibBabble-3.0"):New(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local GAME_LOCALE = GetLocale()

lib:SetBaseTranslations {
	["Quiver"] = true,
	["Ammo Pouch"] = true,
	["Soul Bag"] = true,
	["Herb Bag"] = true,
	["Enchanting Bag"] = true,
}

if GAME_LOCALE == "enUS" then
	lib:SetCurrentTranslations(true)
elseif GAME_LOCALE == "deDE" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "frFR" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "zhCN" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "zhTW" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "koKR" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "esES" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "esMX" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Quiver",
		["Ammo Pouch"] = "Ammo Pouch",
		["Soul Bag"] = "Soul Bag",
		["Herb Bag"] = "Herb Bag",
		["Enchanting Bag"] = "Enchanting Bag",
	}
elseif GAME_LOCALE == "ruRU" then
	lib:SetCurrentTranslations {
		["Quiver"] = "Колчан",
		["Ammo Pouch"] = "Подсумок",
		["Soul Bag"] = "Сумка душ",
		["Herb Bag"] = "Сумка травника",
		["Enchanting Bag"] = "Сумка зачаровывателя",
	}
else
	error(string.format("%s: Locale %q not supported", MAJOR_VERSION, GAME_LOCALE))
end