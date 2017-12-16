local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Locked Settings, These settings are stored for your character only regardless of profile options.

V["general"] = {
	["normTex"] = "ElvUI Norm",
	["glossTex"] = "ElvUI Norm",
	["dmgfont"] = "PT Sans Narrow",
	["namefont"] = "PT Sans Narrow",
	["pixelPerfect"] = true,
	["replaceBlizzFonts"] = true,
	["minimap"] = {
		["enable"] = true
	},
}

V["auras"] = {
	["enable"] = true,
	["disableBlizzard"] = true,
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
	["enable"] = true
}

V["cooldown"] = {
	enable = true
}