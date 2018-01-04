local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Locked Settings, These settings are stored for your character only regardless of profile options.

V["general"] = {
	["loot"] = true,
	["lootRoll"] = true,
	["lootUnderMouse"] = false,
	["normTex"] = "ElvUI Norm",
	["glossTex"] = "ElvUI Norm",
	["dmgfont"] = "PT Sans Narrow",
	["namefont"] = "PT Sans Narrow",
	["chatBubbles"] = "backdrop",
	["chatBubbleFont"] = "PT Sans Narrow",
	["chatBubbleFontSize"] = 14,
	["chatBubbleFontOutline"] = "NONE",
	["pixelPerfect"] = true,
	["replaceBlizzFonts"] = true,
	["minimap"] = {
		["enable"] = true,
		["hideCalendar"] = true,
		["zoomLevel"] = 0,
	},
}

V["bags"] = {
	["enable"] = true,
	["bagBar"] = false,
}

V["nameplates"] = {
	["enable"] = true,
}

V["auras"] = {
	["enable"] = true,
	["disableBlizzard"] = true,
	["lbf"] = {
		enable = false,
		skin = "Blizzard"
	},
}

V["chat"] = {
	["enable"] = true,
}

V["skins"] = {
	["ace3"] = {
		["enable"] = true,
	},
	["blizzard"] = {
		["enable"] = true,
		["alertframes"] = true,
		["auctionhouse"] = true,
		["bags"] = true,
		["battlefield"] = true,
		["bgscore"] = true,
		["binding"] = true,
		["character"] = true,
		["debug"] = true,
		["dressingroom"] = true,
		["friends"] = true,
		["gossip"] = true,
		["greeting"] = true,
		["guildregistrar"] = true,
		["help"] = true,
		["inspect"] = true,
		["loot"] = true,
		["lootRoll"] = true,
		["macro"] = true,
		["mail"] = true,
		["merchant"] = true,
		["misc"] = true,
		["petition"] = true,
		["quest"] = true,
		["questtimers"] = true,
		["raid"] = true,
		["spellbook"] = true,
		["stable"] = true,
		["tabard"] = true,
		["talent"] = true,
		["taxi"] = true,
		["tooltip"] = true,
		["trade"] = true,
		["tradeskill"] = true,
		["trainer"] = true,
		["tutorial"] = true,
		["watchframe"] = true,
		["worldmap"] = true,
		["mirrorTimers"] = true
	},
}

V["tooltip"] = {
	["enable"] = true
}

V["unitframe"] = {
	["enable"] = true,
	["disabledBlizzardFrames"] = {
		["player"] = true,
		["target"] = true,
		["focus"] = true,
		["boss"] = true,
		["arena"] = true,
		["party"] = true,
	},
}

V["actionbar"] = {
	["enable"] = true,
	["lbf"] = {
		enable = false,
		skin = "Blizzard"
	},
}

V["cooldown"] = {
	enable = true
}