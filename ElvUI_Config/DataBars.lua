local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local mod = E:GetModule("DataBars");

local getn = table.getn

E.Options.args.databars = {
	type = "group",
	name = L["DataBars"],
	childGroups = "tab",
	get = function(info) return E.db.databars[ info[getn(info)] ] end,
	set = function(info, value) E.db.databars[ info[getn(info)] ] = value; end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["Setup on-screen display of information bars."]
		},
		spacer = {
			order = 2,
			type = "description",
			name = ""
		},
		experience = {
			order = 3,
			get = function(info) return mod.db.experience[ info[getn(info)] ] end,
			set = function(info, value) mod.db.experience[ info[getn(info)] ] = value; mod:UpdateExperienceDimensions() end,
			type = "group",
			name = L["XP Bar"],
			args = {
				enable = {
					order = 0,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.experience[ info[getn(info)] ] = value; mod:EnableDisable_ExperienceBar() end
				},
				mouseover = {
					order = 1,
					type = "toggle",
					name = L["Mouseover"]
				},
				hideAtMaxLevel = {
					order = 2,
					type = "toggle",
					name = L["Hide At Max Level"],
					set = function(info, value) mod.db.experience[ info[getn(info)] ] = value; mod:UpdateExperience() end
				},
				orientation = {
					order = 3,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 4,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 5,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 6,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 7,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 33, step = 1
				},
				fontOutline = {
					order = 8,
					type = "select",
					name = L["Font Outline"],
					values = {
						["NONE"] = L["None"],
						["OUTLINE"] = "OUTLINE",
						["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
						["THICKOUTLINE"] = "THICKOUTLINE"
					}
				},
				textFormat = {
					order = 9,
					type = "select",
					name = L["Text Format"],
					width = "double",
					values = {
						NONE = L["None"],
						PERCENT = L["Percent"],
						CUR = L["Current"],
						REM = L["Remaining"],
						CURMAX = L["Current - Max"],
						CURPERC = L["Current - Percent"],
						CURREM = L["Current - Remaining"],
						CURPERCREM = L["Current - Percent (Remaining)"]
					},
					set = function(info, value) mod.db.experience[ info[getn(info)] ] = value; mod:UpdateExperience() end
				}
			}
		},
		reputation = {
			order = 4,
			get = function(info) return mod.db.reputation[ info[getn(info)] ] end,
			set = function(info, value) mod.db.reputation[ info[getn(info)] ] = value; mod:UpdateReputationDimensions() end,
			type = "group",
			name = REPUTATION,
			args = {
				enable = {
					order = 0,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.reputation[ info[getn(info)] ] = value; mod:EnableDisable_ReputationBar() end
				},
				mouseover = {
					order = 1,
					type = "toggle",
					name = L["Mouseover"]
				},
				spacer = {
					order = 2,
					type = "description",
					name = " "
				},
				orientation = {
					order = 3,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 4,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 5,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 6,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 7,
					name = FONT_SIZE,
					type = "range",
					min = 6, max = 33, step = 1
				},
				fontOutline = {
					order = 8,
					type = "select",
					name = L["Font Outline"],
					values = {
						["NONE"] = L["None"],
						["OUTLINE"] = "OUTLINE",
						["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
						["THICKOUTLINE"] = "THICKOUTLINE"
					}
				},
				textFormat = {
					order = 9,
					type = "select",
					name = L["Text Format"],
					width = "double",
					values = {
						NONE = L["None"],
						CUR = L["Current"],
						REM = L["Remaining"],
						PERCENT = L["Percent"],
						CURMAX = L["Current - Max"],
						CURPERC = L["Current - Percent"],
						CURREM = L["Current - Remaining"],
						CURPERCREM = L["Current - Percent (Remaining)"],
					},
					set = function(info, value) mod.db.reputation[ info[getn(info)] ] = value; mod:UpdateReputation() end
				}
			}
		}
	}
}