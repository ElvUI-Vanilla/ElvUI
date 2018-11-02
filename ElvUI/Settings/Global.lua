local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Global Settings
G["general"] = {
	["autoScale"] = true,
	["minUiScale"] = 0.64,
	["eyefinity"] = false,
	["smallerWorldMap"] = true,
	["WorldMapCoordinates"] = {
		["enable"] = true,
		["position"] = "BOTTOMLEFT",
		["xOffset"] = 0,
		["yOffset"] = 0
	},
	["versionCheck"] = true
}

G["classCache"] = {}

G["classtimer"] = {}

G["nameplates"] = {}

G["unitframe"] = {
	["specialFilters"] = {},
	["aurafilters"] = {}
}

G["chat"] = {
	["classColorMentionExcludedNames"] = {}
}

G["bags"] = {
	["ignoredItems"] = {}
}

G["profileCopy"] = {
	--Specific values
	["selected"] = "Minimalistic",
	["movers"] = {},
	--Modules
	["actionbar"] = {
		["general"] = true,
		["bar1"] = true,
		["bar2"] = true,
		["bar3"] = true,
		["bar4"] = true,
		["bar5"] = true,
		["bar6"] = true,
		["barPet"] = true,
		["barShapeShift"] = true,
		["microbar"] = true,
		["cooldown"] = true
	},
	["auras"] = {
		["general"] = true,
		["cooldown"] = true
	},
	["bags"] = {
		["general"] = true,
		["split"] = true,
		["vendorGrays"] = true,
		["bagBar"] = true,
		["cooldown"] = true
	},
	["chat"] = {
		["general"] = true
	},
	["cooldown"] = {
		["general"] = true,
		["fonts"] = true
	},
	["databars"] = {
		["experience"] = true,
		["reputation"] = true
	},
	["datatexts"] = {
		["general"] = true,
		["panels"] = true
	},
	["general"] = {
		["general"] = true,
		["minimap"] = true,
		["threat"] = true,
		["totems"] = true
	},
	["nameplates"] = {
		["general"] = true,
		["reactions"] = true,
		["units"] = {
			["FRIENDLY_PLAYER"] = true,
			["ENEMY_PLAYER"] = true,
			["FRIENDLY_NPC"] = true,
			["ENEMY_NPC"] = true
		}
	},
	["tooltip"] = {
		["general"] = true,
		["visibility"] = true,
		["healthBar"] = true
	},
	["unitframes"] = {
		["general"] = true,
		["cooldown"] = true,
		["colors"] = {
			["general"] = true,
			["power"] = true,
			["reaction"] = true,
			["healPrediction"] = true,
			["classResources"] = true,
			["frameGlow"] = true,
			["debuffHighlight"] = true
		},
		["units"] = {
			["player"] = true,
			["target"] = true,
			["targettarget"] = true,
			["targettargettarget"] = true,
			["focus"] = true,
			["focustarget"] = true,
			["pet"] = true,
			["pettarget"] = true,
			["arena"] = true,
			["party"] = true,
			["raid"] = true,
			["raid40"] = true,
			["raidpet"] = true,
			["tank"] = true,
			["assist"] = true
		}
	}
}
