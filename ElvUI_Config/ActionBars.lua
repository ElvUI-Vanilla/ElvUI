local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars");
local group

--Cache global variables
--Lua functions
local _G = _G
local getn = table.getn
--WoW API / Variables
local SetCVar = SetCVar
local GameTooltip = _G["GameTooltip"]
local NONE, COLOR = NONE, COLOR
local LOCK_ACTIONBAR_TEXT = LOCK_ACTIONBAR_TEXT

local points = {
	["TOPLEFT"] = "TOPLEFT",
	["TOPRIGHT"] = "TOPRIGHT",
	["BOTTOMLEFT"] = "BOTTOMLEFT",
	["BOTTOMRIGHT"] = "BOTTOMRIGHT"
}

local ACD = LibStub("AceConfigDialog-3.0")

local function BuildABConfig()
	group["general"] = {
		order = 1,
		type = "group",
		name = L["General Options"],
		childGroups = "tab",
		disabled = function() return not E.private.actionbar.enable end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["General Options"]
			},
			toggleKeybind = {
				order = 2,
				type = "execute",
				name = L["Keybind Mode"],
				func = function()
					AB:ActivateBindMode()
					E:ToggleConfig()
					GameTooltip:Hide()
				end
			},
			cooldownText = {
				order = 3,
				type = "execute",
				name = L["Cooldown Text"],
				func = function() ACD:SelectGroup("ElvUI", "general", "cooldown") end
			},
			spacer = {
				order = 4,
				type = "description",
				name = ""
			},
			macrotext = {
				order = 5,
				type = "toggle",
				name = L["Macro Text"],
				desc = L["Display macro names on action buttons."]
			},
			hotkeytext = {
				order = 6,
				type = "toggle",
				name = L["Keybind Text"],
				desc = L["Display bind names on action buttons."]
			},
			keyDown = {
				order = 8,
				type = "toggle",
				name = L["Key Down"],
				desc = OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN
			},
			lockActionBars = {
				order = 9,
				type = "toggle",
				name = LOCK_ACTIONBAR_TEXT,
				desc = L["If you unlock actionbars then trying to move a spell might instantly cast it if you cast spells on key press instead of key release."],
				set = function(info, value)
					E.db.actionbar[ info[getn(info)] ] = value
					AB:UpdateButtonSettings()
					LOCK_ACTIONBAR = (value == true and 1 or 0)
				end
			},
			movementModifier = {
				order = 10,
				type = "select",
				name = L["Pick Up Action Key"],
				desc = L["The button you must hold down in order to drag an ability to another action button."],
				disabled = function() return (not E.private.actionbar.enable or not E.db.actionbar.lockActionBars) end,
				values = {
					["NONE"] = NONE,
					["SHIFT"] = "SHIFT_KEY",
					["ALT"] = "ALT_KEY",
					["CTRL"] = "CTRL_KEY"
				}
			},
			globalFadeAlpha = {
				order = 11,
				type = "range",
				name = L["Global Fade Transparency"],
				desc = L["Transparency level when not in combat, no target exists, full health, not casting, and no focus target exists."],
				min = 0, max = 1, step = 0.01,
				isPercent = true,
				set = function(info, value) E.db.actionbar[ info[getn(info)] ] = value AB.fadeParent:SetAlpha(1-value) end
			},
			colorGroup = {
				order = 12,
				type = "group",
				name = L["Colors"],
				guiInline = true,
				get = function(info)
					local t = E.db.actionbar[ info[getn(info)] ]
					local d = P.actionbar[ info[getn(info)] ]
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					local t = E.db.actionbar[ info[getn(info)] ]
					t.r, t.g, t.b = r, g, b

					tullaRange:LoadDefaults()
					tullaRange.colors = TULLARANGE_COLORS
					for button in pairs(tullaRange.buttonsToUpdate) do
						button.tullaRangeColor = nil
						tullaRange.UpdateButtonUsable(button)
					end
				end,
				args = {
					noRangeColor = {
						order = 1,
						type = "color",
						name = L["Out of Range"],
						desc = L["Color of the actionbutton when out of range."]
					},
					noPowerColor = {
						order = 2,
						type = "color",
						name = L["Out of Power"],
						desc = L["Color of the actionbutton when out of power (Mana, Rage, Focus, Holy Power)."]
					},
					usableColor = {
						order = 3,
						type = "color",
						name = L["Usable"],
						desc = L["Color of the actionbutton when usable."]
					},
					notUsableColor = {
						order = 4,
						type = "color",
						name = L["Not Usable"],
						desc = L["Color of the actionbutton when not usable."]
					}
				}
			},
			fontGroup = {
				order = 13,
				type = "group",
				guiInline = true,
				name = L["Fonts"],
				args = {
					font = {
						order = 4,
						type = "select", dialogControl = "LSM30_Font",
						name = L["Font"],
						values = AceGUIWidgetLSMlists.font
					},
					fontSize = {
						order = 5,
						type = "range",
						name = FONT_SIZE,
						min = 4, max = 212, step = 1
					},
					fontOutline = {
						order = 6,
						type = "select",
						name = L["Font Outline"],
						desc = L["Set the font outline."],
						values = {
							["NONE"] = NONE,
							["OUTLINE"] = "OUTLINE",
							["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
							["THICKOUTLINE"] = "THICKOUTLINE"
						}
					},
					fontColor = {
						order = 7,
						type = "color",
						name = COLOR,
						get = function(info)
							local t = E.db.actionbar[ info[getn(info)] ]
							local d = P.actionbar[ info[getn(info)] ]
							return t.r, t.g, t.b, t.a, d.r, d.g, d.b
						end,
						set = function(info, r, g, b)
							local t = E.db.actionbar[ info[getn(info)] ]
							t.r, t.g, t.b = r, g, b
							AB:UpdateButtonSettings()
						end
					}
				}
			}
		}
	}
	group["barPet"] = {
		order = 2,
		name = L["Pet Bar"],
		type = "group",
		guiInline = false,
		disabled = function() return not E.private.actionbar.enable end,
		get = function(info) return E.db.actionbar["barPet"][ info[getn(info)] ] end,
		set = function(info, value) E.db.actionbar["barPet"][ info[getn(info)] ] = value AB:PositionAndSizeBarPet() end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Pet Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"]
			},
			restorePosition = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				func = function() E:CopyTable(E.db.actionbar["barPet"], P.actionbar["barPet"]) E:ResetMovers(L["Pet Bar"]) AB:PositionAndSizeBarPet() end,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			backdrop = {
				order = 5,
				type = "toggle",
				name = L["Backdrop"],
				desc = L["Toggles the display of the actionbars backdrop."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			mouseover = {
				order = 6,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			inheritGlobalFade = {
				order = 7,
				type = "toggle",
				name = L["Inherit Global Fade"],
				desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			point = {
				order = 8,
				type = "select",
				name = L["Anchor Point"],
				desc = L["The first button anchors itself to this point on the bar."],
				values = points,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttons = {
				order = 8,
				type = "range",
				name = L["Buttons"],
				desc = L["The amount of buttons to display."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonsPerRow = {
				order = 10,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonsize = {
				order = 11,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonspacing = {
				order = 12,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			backdropSpacing = {
				order = 13,
				type = "range",
				name = L["Backdrop Spacing"],
				desc = L["The spacing between the backdrop and the buttons."],
				min = 0, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			heightMult = {
				order = 14,
				type = "range",
				name = L["Height Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			widthMult = {
				order = 15,
				type = "range",
				name = L["Width Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			alpha = {
				order = 16,
				type = "range",
				isPercent = true,
				name = L["Alpha"],
				min = 0, max = 1, step = 0.01,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			}
		}
	}
	group["stanceBar"] = {
		order = 3,
		name = L["Stance Bar"],
		type = "group",
		guiInline = false,
		disabled = function() return not E.ActionBars end,
		get = function(info) return E.db.actionbar["barShapeShift"][ info[getn(info)] ] end,
		set = function(info, value) E.db.actionbar["barShapeShift"][ info[getn(info)] ] = value; AB:PositionAndSizeBarShapeShift() end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Stance Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"]
			},
			restorePosition = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				func = function() E:CopyTable(E.db.actionbar["barShapeShift"], P.actionbar["barShapeShift"]) E:ResetMovers(L["Stance Bar"]) AB:PositionAndSizeBarShapeShift() end,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			backdrop = {
				order = 5,
				type = "toggle",
				name = L["Backdrop"],
				desc = L["Toggles the display of the actionbars backdrop."],
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			mouseover = {
				order = 6,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			inheritGlobalFade = {
				order = 7,
				type = "toggle",
				name = L["Inherit Global Fade"],
				desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			point = {
				order = 8,
				type = "select",
				name = L["Anchor Point"],
				desc = L["The first button anchors itself to this point on the bar."],
				values = points,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			buttons = {
				order = 9,
				type = "range",
				name = L["Buttons"],
				desc = L["The amount of buttons to display."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			buttonsPerRow = {
				order = 10,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			buttonsize = {
				order = 11,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			buttonspacing = {
				order = 12,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			backdropSpacing = {
				order = 13,
				type = "range",
				name = L["Backdrop Spacing"],
				desc = L["The spacing between the backdrop and the buttons."],
				min = 0, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			heightMult = {
				order = 14,
				type = "range",
				name = L["Height Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			widthMult = {
				order = 15,
				type = "range",
				name = L["Width Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			alpha = {
				order = 16,
				type = "range",
				isPercent = true,
				name = L["Alpha"],
				min = 0, max = 1, step = 0.01,
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			},
			style = {
				order = 17,
				type = "select",
				name = L["Style"],
				desc = L["This setting will be updated upon changing stances."],
				values = {
					["darkenInactive"] = L["Darken Inactive"],
					["classic"] = L["Classic"]
				},
				disabled = function() return not E.db.actionbar.barShapeShift.enabled end
			}
		}
	}
	group["microbar"] = {
		order = 4,
		type = "group",
		name = L["Micro Bar"],
		get = function(info) return E.db.actionbar.microbar[ info[getn(info)] ] end,
		set = function(info, value) E.db.actionbar.microbar[ info[getn(info)] ] = value AB:UpdateMicroPositionDimensions() end,
		disabled = function() return not E.private.actionbar.enable end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Micro Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"]
			},
			restorePosition = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				func = function() E:CopyTable(E.db.actionbar["microbar"], P.actionbar["microbar"]) E:ResetMovers(L["Micro Bar"]) AB:UpdateMicroPositionDimensions() end,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			buttonsPerRow = {
				order = 5,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = 8, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			xOffset = {
				order = 6,
				type = "range",
				name = L["xOffset"],
				min = -1, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			yOffset = {
				order = 7,
				type = "range",
				name = L["yOffset"],
				min = -1, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			alpha = {
				order = 8,
				type = "range",
				isPercent = true,
				name = L["Alpha"],
				desc = L["Change the alpha level of the frame."],
				min = 0, max = 1, step = 0.1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			mouseover = {
				order = 9,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.microbar.enabled end
			}
		}
	}
	for i = 1, 5 do
		local name = L["Bar "]..i
		local barNum = "bar"..i

		group[barNum] = {
			order = 4 + i,
			name = name,
			type = "group",
			disabled = function() return not E.private.actionbar.enable end,
			get = function(info) return E.db.actionbar[barNum][ info[getn(info)] ] end,
			set = function(info, value)
				E.db.actionbar[barNum][ info[getn(info)] ] = value
				AB:PositionAndSizeBar(barNum)
			end,
			args = {
				info = {
					order = 1,
					type = "header",
					name = name
				},
				enabled = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value)
						E.db.actionbar[barNum][ info[getn(info)] ] = value
						AB:PositionAndSizeBar(barNum)
					end
				},
				restorePosition = {
					order = 3,
					type = "execute",
					name = L["Restore Bar"],
					desc = L["Restore the actionbars default settings"],
					func = function()
						E:CopyTable(E.db.actionbar[barNum], P.actionbar[barNum])
						E:ResetMovers(name) AB:PositionAndSizeBar(barNum)
					end,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				spacer = {
					order = 4,
					type = "description",
					name = " "
				},
				backdrop = {
					order = 5,
					type = "toggle",
					name = L["Backdrop"],
					desc = L["Toggles the display of the actionbars backdrop."],
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				showGrid = {
					order = 6,
					type = "toggle",
					name = L["Show Empty Buttons"],
					set = function(info, value)
						E.db.actionbar[barNum][ info[getn(info)] ] = value
						AB:UpdateButtonSettingsForBar(barNum)
					end,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				mouseover = {
					order = 7,
					type = "toggle",
					name = L["Mouse Over"],
					desc = L["The frame is not shown unless you mouse over the frame."],
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				inheritGlobalFade = {
					order = 8,
					type = "toggle",
					name = L["Inherit Global Fade"],
					desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				point = {
					order = 9,
					type = "select",
					name = L["Anchor Point"],
					desc = L["The first button anchors itself to this point on the bar."],
					values = points,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				buttons = {
					order = 10,
					type = "range",
					name = L["Buttons"],
					desc = L["The amount of buttons to display."],
					min = 1, max = NUM_ACTIONBAR_BUTTONS, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				buttonsPerRow = {
					order = 11,
					type = "range",
					name = L["Buttons Per Row"],
					desc = L["The amount of buttons to display per row."],
					min = 1, max = NUM_ACTIONBAR_BUTTONS, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				buttonsize = {
					order = 12,
					type = "range",
					name = L["Button Size"],
					desc = L["The size of the action buttons."],
					min = 15, max = 60, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				buttonspacing = {
					order = 13,
					type = "range",
					name = L["Button Spacing"],
					desc = L["The spacing between buttons."],
					min = -1, max = 10, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				backdropSpacing = {
					order = 14,
					type = "range",
					name = L["Backdrop Spacing"],
					desc = L["The spacing between the backdrop and the buttons."],
					min = 0, max = 10, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				heightMult = {
					order = 15,
					type = "range",
					name = L["Height Multiplier"],
					desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
					min = 1, max = 5, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				widthMult = {
					order = 16,
					type = "range",
					name = L["Width Multiplier"],
					desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
					min = 1, max = 5, step = 1,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				},
				alpha = {
					order = 17,
					type = "range",
					name = L["Alpha"],
					isPercent = true,
					min = 0, max = 1, step = 0.01,
					disabled = function() return not E.db.actionbar[barNum].enabled end
				}
			}
		}
	end
end

E.Options.args.actionbar = {
	type = "group",
	name = L["ActionBars"],
	childGroups = "tree",
	get = function(info) return E.db.actionbar[ info[getn(info)] ] end,
	set = function(info, value) E.db.actionbar[ info[getn(info)] ] = value AB:UpdateButtonSettings() end,
	args = {
		enable = {
			order = 1,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.actionbar[ info[getn(info)] ] end,
			set = function(info, value) E.private.actionbar[ info[getn(info)] ] = value E:StaticPopup_Show("PRIVATE_RL") end
		},
		intro = {
			order = 2,
			type = "description",
			name = L["ACTIONBARS_DESC"]
		},
		header = {
			order = 3,
			type = "header",
			name = L["Shortcuts"],
		},
		spacer1 = {
			order = 4,
			type = "description",
			name = " ",
		},
		generalShortcut = {
			order = 5,
			type = "execute",
			name = L["General"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "general") end,
			disabled = function() return not E.ActionBars end,
		},
		petBarShortcut = {
			order = 6,
			type = "execute",
			name = L["Pet Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "barPet") end,
			disabled = function() return not E.ActionBars end,
		},
		stanceBarShortcut = {
			order = 7,
			type = "execute",
			name = L["Stance Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "stanceBar") end,
			disabled = function() return not E.ActionBars end,
		},
		spacer2 = {
			order = 8,
			type = "description",
			name = " ",
		},
		microbarShortcut = {
			order = 9,
			type = "execute",
			name = L["Micro Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "microbar") end,
			disabled = function() return not E.ActionBars end,
		},
		bar1Shortcut = {
			order = 10,
			type = "execute",
			name = L["Bar "]..1,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar1") end,
			disabled = function() return not E.ActionBars end,
		},
		bar2Shortcut = {
			order = 11,
			type = "execute",
			name = L["Bar "]..2,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar2") end,
			disabled = function() return not E.ActionBars end,
		},
		spacer3 = {
			order = 12,
			type = "description",
			name = " ",
		},
		bar3Shortcut = {
			order = 13,
			type = "execute",
			name = L["Bar "]..3,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar3") end,
			disabled = function() return not E.ActionBars end,
		},
		bar4Shortcut = {
			order = 14,
			type = "execute",
			name = L["Bar "]..4,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar4") end,
			disabled = function() return not E.ActionBars end,
		},
		bar5Shortcut = {
			order = 15,
			type = "execute",
			name = L["Bar "]..5,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar5") end,
			disabled = function() return not E.ActionBars end,
		}
	}
}
group = E.Options.args.actionbar.args
BuildABConfig()