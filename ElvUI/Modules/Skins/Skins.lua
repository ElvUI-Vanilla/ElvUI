local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:NewModule("Skins", "AceHook-3.0", "AceEvent-3.0");

--Cache global variables
--Lua functions
local _G = _G
local unpack, assert, pairs, ipairs, type, pcall = unpack, assert, pairs, ipairs, type, pcall
local tinsert, wipe = table.insert, table.wipe
local find, gfind, lower = string.find, string.gfind, string.lower
--WoW API / Variables
local CreateFrame = CreateFrame
local SetDesaturation = SetDesaturation
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local GetCVarBool = GetCVarBool

E.Skins = S
S.addonsToLoad = {}
S.nonAddonsToLoad = {}
S.allowBypass = {}
S.addonCallbacks = {}
S.nonAddonCallbacks = {["CallPriority"] = {}}

S.SQUARE_BUTTON_TEXCOORDS = {
	["UP"] = {     0.45312500,    0.64062500,     0.01562500,     0.20312500};
	["DOWN"] = {   0.45312500,    0.64062500,     0.20312500,     0.01562500};
	["LEFT"] = {   0.23437500,    0.42187500,     0.01562500,     0.20312500};
	["RIGHT"] = {  0.42187500,    0.23437500,     0.01562500,     0.20312500};
	["DELETE"] = { 0.01562500,    0.20312500,     0.01562500,     0.20312500}
}

function S:SquareButton_SetIcon(self, name)
	local coords = S.SQUARE_BUTTON_TEXCOORDS[strupper(name)]
	if coords then
		self.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	end
end

function S:SetModifiedBackdrop()
	if this.backdrop then this = this.backdrop end
	this:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))
end

function S:SetOriginalBackdrop()
	if this.backdrop then this = this.backdrop end
	this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
end

function S:HandleButton(f, strip)
	local name = f:GetName()
	if name then
		local left = _G[name .."Left"]
		local middle = _G[name .."Middle"]
		local right = _G[name .."Right"]

		if left then E:Kill(left) end
		if middle then E:Kill(middle) end
		if right then E:Kill(right) end
	end

	if f.Left then E:Kill(f.Left) end
	if f.Middle then E:Kill(f.Middle) end
	if f.Right then E:Kill(f.Right) end

	if f.SetNormalTexture then f:SetNormalTexture("") end
	if f.SetHighlightTexture then f:SetHighlightTexture("") end
	if f.SetPushedTexture then f:SetPushedTexture("") end
	if f.SetDisabledTexture then f:SetDisabledTexture("") end

	if strip then E:StripTextures(f) end

	E:SetTemplate(f, "Default", true)
	HookScript(f, "OnEnter", S.SetModifiedBackdrop)
	HookScript(f, "OnLeave", S.SetOriginalBackdrop)
end

function S:HandleScrollBar(frame, thumbTrim)
	local name = frame:GetName()
	if _G[name.."BG"] then _G[name.."BG"]:SetTexture(nil) end
	if _G[name.."Track"] then _G[name.."Track"]:SetTexture(nil) end
	if _G[name.."Top"] then _G[name.."Top"]:SetTexture(nil) end
	if _G[name.."Bottom"] then _G[name.."Bottom"]:SetTexture(nil) end
	if _G[name.."Middle"] then _G[name.."Middle"]:SetTexture(nil) end

	if _G[name.."ScrollUpButton"] and _G[name.."ScrollDownButton"] then
		E:StripTextures(_G[name.."ScrollUpButton"])
		if not _G[name.."ScrollUpButton"].icon then
			S:HandleNextPrevButton(_G[name.."ScrollUpButton"])
			S:SquareButton_SetIcon(_G[name.."ScrollUpButton"], "UP")
			E:Size(_G[name.."ScrollUpButton"], _G[name.."ScrollUpButton"]:GetWidth() + 7, _G[name.."ScrollUpButton"]:GetHeight() + 7)
		end

		E:StripTextures(_G[name .."ScrollDownButton"])
		if not _G[name.."ScrollDownButton"].icon then
			S:HandleNextPrevButton(_G[name.."ScrollDownButton"])
			S:SquareButton_SetIcon(_G[name.."ScrollDownButton"], "DOWN")
			E:Size(_G[name.."ScrollDownButton"], _G[name.."ScrollDownButton"]:GetWidth() + 7, _G[name.."ScrollDownButton"]:GetHeight() + 7)
		end

		if not frame.trackbg then
			frame.trackbg = CreateFrame("Frame", nil, frame)
			E:Point(frame.trackbg, "TOPLEFT", _G[name .."ScrollUpButton"], "BOTTOMLEFT", 0, -1)
			E:Point(frame.trackbg, "BOTTOMRIGHT", _G[name .."ScrollDownButton"], "TOPRIGHT", 0, 1)
			E:SetTemplate(frame.trackbg, "Transparent")
		end

		if frame:GetThumbTexture() then
			if not thumbTrim then thumbTrim = 3 end
			frame:GetThumbTexture():SetTexture(nil)
			if not frame.thumbbg then
				frame.thumbbg = CreateFrame("Frame", nil, frame)
				E:Height(frame:GetThumbTexture(), 24)
				E:Point(frame.thumbbg, "TOPLEFT", frame:GetThumbTexture(), "TOPLEFT", 1, -thumbTrim)
				E:Point(frame.thumbbg, "BOTTOMRIGHT", frame:GetThumbTexture(), "BOTTOMRIGHT", -1, thumbTrim)
				E:SetTemplate(frame.thumbbg, "Default", true, true)
				frame.thumbbg:SetBackdropColor(0.6, 0.6, 0.6)
				if frame.trackbg then
					frame.thumbbg:SetFrameLevel(frame.trackbg:GetFrameLevel() + 1)
				end
			end
		end
	end
end

local tabs = {
	"LeftDisabled",
	"MiddleDisabled",
	"RightDisabled",
	"Left",
	"Middle",
	"Right"
}

function S:HandleTab(tab)
	local name = tab:GetName()
	for _, object in pairs(tabs) do
		local tex = _G[name..object]
		if tex then
			tex:SetTexture(nil)
		end
	end

	if tab.GetHighlightTexture and tab:GetHighlightTexture() then
		tab:GetHighlightTexture():SetTexture(nil)
	else
		E:StripTextures(tab)
	end

	tab.backdrop = CreateFrame("Frame", nil, tab)
	E:SetTemplate(tab.backdrop, "Default")
	tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
	E:Point(tab.backdrop, "TOPLEFT", 10, E.PixelMode and -1 or -3)
	E:Point(tab.backdrop, "BOTTOMRIGHT", -10, 3)
end

function S:HandleNextPrevButton(btn, buttonOverride)
	local inverseDirection = btn:GetName() and (find(lower(btn:GetName()), "left") or find(lower(btn:GetName()), "prev") or find(lower(btn:GetName()), "decrement") or find(lower(btn:GetName()), "promote"))

	E:StripTextures(btn)
	btn:SetNormalTexture(nil)
	btn:SetPushedTexture(nil)
	btn:SetHighlightTexture(nil)
	btn:SetDisabledTexture(nil)

	if not btn.icon then
		btn.icon = btn:CreateTexture(nil, "ARTWORK")
		E:Size(btn.icon, 13)
		E:Point(btn.icon, "CENTER", 0, 0)
		btn.icon:SetTexture("Interface\\AddOns\\ElvUI\\Media\\Textures\\SquareButtonTextures.blp")
		btn.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)

		btn:SetScript("OnMouseDown", function()
			if btn:IsEnabled() == 1 then
				E:Point(this.icon, "CENTER", -1, -1)
			end
		end)
		btn:SetScript("OnMouseUp", function()
			E:Point(this.icon, "CENTER", 0, 0)
		end)

		hooksecurefunc(btn, "Disable", function(self)
			SetDesaturation(self.icon, true)
			self.icon:SetAlpha(0.5)
		end)
		hooksecurefunc(btn, "Enable", function(self)
			SetDesaturation(self.icon, false)
			self.icon:SetAlpha(1.0)
		end)

		if btn:IsEnabled() == 0 then
			SetDesaturation(btn.icon, true)
			btn.icon:SetAlpha(0.5)
		end
	end

	if buttonOverride then
		if inverseDirection then
			S:SquareButton_SetIcon(btn, "UP")
		else
			S:SquareButton_SetIcon(btn, "DOWN")
		end
	else
		if inverseDirection then
			S:SquareButton_SetIcon(btn, "LEFT")
		else
			S:SquareButton_SetIcon(btn, "RIGHT")
		end
	end

	S:HandleButton(btn)
	E:Size(btn, btn:GetWidth() - 7, btn:GetHeight() - 7)
end

function S:HandleRotateButton(btn)
	E:SetTemplate(btn, "Default")
	E:Size(btn, btn:GetWidth() - 14, btn:GetHeight() - 14)

	btn:GetNormalTexture():SetTexCoord(0.27, 0.73, 0.27, 0.68)
	btn:GetPushedTexture():SetTexCoord(0.27, 0.73, 0.27, 0.68)

	btn:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)

	E:SetInside(btn:GetNormalTexture())
	btn:GetPushedTexture():SetAllPoints(btn:GetNormalTexture())
	btn:GetHighlightTexture():SetAllPoints(btn:GetNormalTexture())
end

function S:HandleEditBox(frame)
	if not frame then return end

	E:CreateBackdrop(frame, "Default")
	frame.backdrop:SetFrameLevel(frame:GetFrameLevel())

	if frame:GetName() then
		if _G[frame:GetName() .."Left"] then E:Kill(_G[frame:GetName() .."Left"]) end
		if _G[frame:GetName() .."Middle"] then E:Kill(_G[frame:GetName() .."Middle"]) end
		if _G[frame:GetName() .."Right"] then E:Kill(_G[frame:GetName() .."Right"]) end
		if _G[frame:GetName() .."Mid"] then E:Kill(_G[frame:GetName() .."Mid"]) end

		if gfind(frame:GetName(), "Silver") or gfind(frame:GetName(), "Copper") then
			E:Point(frame.backdrop, "BOTTOMRIGHT", -12, -2)
		end
	end
end

function S:HandleDropDownBox(frame, width)
	local button = _G[frame:GetName().."Button"]
	if not button then return end

	if not width then width = 155 end

	E:StripTextures(frame)
	E:Width(frame, width)

	if _G[frame:GetName().."Text"] then
		_G[frame:GetName().."Text"]:ClearAllPoints()
		E:Point(_G[frame:GetName().."Text"], "RIGHT", button, "LEFT", -2, 0)
	end

	if button then
		button:ClearAllPoints()
		E:Point(button, "RIGHT", frame, "RIGHT", -10, 3)

		self:HandleNextPrevButton(button, true)
	end
	E:CreateBackdrop(frame, "Default")
	E:Point(frame.backdrop, "TOPLEFT", 20, -2)
	E:Point(frame.backdrop, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	frame.backdrop:SetFrameLevel(frame:GetFrameLevel())
end

function S:HandleCheckBox(frame, noBackdrop)
	frame:SetNormalTexture(nil)
	frame:SetPushedTexture(nil)
	frame:SetHighlightTexture(nil)
	frame:SetDisabledTexture(nil)

	if noBackdrop then
		E:SetTemplate(frame, "Default")
		E:Size(frame, 16)
	else
		E:CreateBackdrop(frame, "Default")
		E:SetInside(frame.backdrop, nil, 4, 4)
		frame.backdrop:SetFrameLevel(frame:GetFrameLevel())
	end
end

function S:HandleIcon(icon, parent)
	parent = parent or icon:GetParent()

	icon:SetTexCoord(unpack(E.TexCoords))
	E:CreateBackdrop(parent, "Default")
	icon:SetParent(parent.backdrop)
	E:SetOutside(parent.backdrop, icon)
end

function S:HandleItemButton(b, shrinkIcon)
	if b.isSkinned then return end

	local icon = b.icon or b.IconTexture or b.iconTexture
	local texture
	if b:GetName() and _G[b:GetName() .."IconTexture"] then
		icon = _G[b:GetName() .."IconTexture"]
	elseif b:GetName() and _G[b:GetName() .."Icon"] then
		icon = _G[b:GetName() .."Icon"]
	end

	if icon and icon:GetTexture() then
		texture = icon:GetTexture()
	end

	E:StripTextures(b)
	E:CreateBackdrop(b, "Default", true)
	E:StyleButton(b)

	if icon then
		icon:SetTexCoord(unpack(E.TexCoords))

		if shrinkIcon then
			b.backdrop:SetAllPoints()
			E:SetInside(icon, b)
		else
			E:SetOutside(b.backdrop, icon)
		end
		icon:SetParent(b.backdrop)

		if texture then
			icon:SetTexture(texture)
		end
	end
	b.isSkinned = true
end

function S:HandleCloseButton(f, point, text)
	E:StripTextures(f)

	if f:GetNormalTexture() then f:SetNormalTexture("") f.SetNormalTexture = E.noop end
	if f:GetPushedTexture() then f:SetPushedTexture("") f.SetPushedTexture = E.noop end

	if not f.backdrop then
		E:CreateBackdrop(f, "Default", true)
		E:Point(f.backdrop, "TOPLEFT", 7, -8)
		E:Point(f.backdrop, "BOTTOMRIGHT", -8, 8)

		HookScript(f, "OnEnter", function() S:SetModifiedBackdrop(this) end)
		HookScript(f, "OnLeave", function() S:SetOriginalBackdrop(this) end)
	end
	if not text then text = "x" end
	if not f.text then
		f.text = f:CreateFontString(nil, "OVERLAY")
		f.text:SetFont([[Interface\AddOns\ElvUI\Media\Fonts\PT_Sans_Narrow.ttf]], 16, "OUTLINE")
		f.text:SetText(text)
		f.text:SetJustifyH("CENTER")
		E:Point(f.text, "CENTER", f, "CENTER", -1, 1)
	end

	if point then
		E:Point(f, "TOPRIGHT", point, "TOPRIGHT", 2, 2)
	end
end

function S:HandleSliderFrame(frame)
	local orientation = frame:GetOrientation()
	local SIZE = 12
	E:StripTextures(frame)
	E:CreateBackdrop(frame, "Default")
	frame.backdrop:SetAllPoints()
	hooksecurefunc(frame, "SetBackdrop", function(_, backdrop)
		if backdrop ~= nil then
			frame:SetBackdrop(nil)
		end
	end)
	frame:SetThumbTexture(E["media"].blankTex)
	frame:GetThumbTexture():SetVertexColor(0.3, 0.3, 0.3)
	E:Size(frame:GetThumbTexture(), SIZE-2)
	if orientation == "VERTICAL" then
		E:Width(frame, SIZE)
	else
		E:Height(frame, SIZE)

		for _, region in ipairs({frame:GetRegions()}) do
			if region and region:GetObjectType() == "FontString" then
				local point, anchor, anchorPoint, x, y = region:GetPoint()
				if find(anchorPoint, "BOTTOM") then
					E:Point(region, point, anchor, anchorPoint, x, y - 4)
				end
			end
		end

		--[[for i = 1, frame:GetNumRegions() do
			local region = select(i, frame:GetRegions())
			if region and region:GetObjectType() == "FontString" then
				local point, anchor, anchorPoint, x, y = region:GetPoint()
				if anchorPoint:find("BOTTOM") then
					E:Point(region, point, anchor, anchorPoint, x, y - 4)
				end
			end
		end]]
	end
end

function S:HandleIconSelectionFrame(frame, numIcons, buttonNameTemplate, frameNameOverride)
	assert(frame, "HandleIconSelectionFrame: frame argument missing")
	assert(numIcons and type(numIcons) == "number", "HandleIconSelectionFrame: numIcons argument missing or not a number")
	assert(buttonNameTemplate and type(buttonNameTemplate) == "string", "HandleIconSelectionFrame: buttonNameTemplate argument missing or not a string")

	local frameName = frameNameOverride or frame:GetName() --We need override in case Blizzard fucks up the naming (guild bank)
	local scrollFrame = _G[frameName.."ScrollFrame"]
	local editBox = _G[frameName.."EditBox"]
	local okayButton = _G[frameName.."OkayButton"] or _G[frameName.."Okay"]
	local cancelButton = _G[frameName.."CancelButton"] or _G[frameName.."Cancel"]

	E:StripTextures(frame)
	E:StripTextures(scrollFrame)
	editBox:DisableDrawLayer("BACKGROUND") --Removes textures around it

	E:CreateBackdrop(frame, "Transparent")
	E:Point(frame.backdrop, "TOPLEFT", frame, "TOPLEFT", 10, -12)
	E:Point(frame.backdrop, "BOTTOMRIGHT", cancelButton, "BOTTOMRIGHT", 5, -5)

	S:HandleButton(okayButton)
	S:HandleButton(cancelButton)
	S:HandleEditBox(editBox)

	for i = 1, numIcons do
		local button = _G[buttonNameTemplate..i]
		local icon = _G[button:GetName().."Icon"]
		E:StripTextures(button)
		E:SetTemplate(button, "Default")
		E:StyleButton(button, nil, true)
		E:SetInside(icon)
		icon:SetTexCoord(unpack(E.TexCoords))
	end
end

function S:ADDON_LOADED()
	if self.allowBypass[arg1] then
		if self.addonsToLoad[arg1] then
			--Load addons using the old deprecated register method
			self.addonsToLoad[arg1]()
			self.addonsToLoad[arg1] = nil
		elseif self.addonCallbacks[arg1] then
			--Fire events to the skins that rely on this addon
			for index, event in ipairs(self.addonCallbacks[arg1]["CallPriority"]) do
				self.addonCallbacks[arg1][event] = nil
				self.addonCallbacks[arg1]["CallPriority"][index] = nil
				E.callbacks:Fire(event)
			end
		end
		return
	end

	if not E.initialized then return end

	if self.addonsToLoad[arg1] then
		self.addonsToLoad[arg1]()
		self.addonsToLoad[arg1] = nil
	elseif self.addonCallbacks[arg1] then
		for index, event in ipairs(self.addonCallbacks[arg1]["CallPriority"]) do
			self.addonCallbacks[arg1][event] = nil
			self.addonCallbacks[arg1]["CallPriority"][index] = nil
			E.callbacks:Fire(event)
		end
	end
end

--Old deprecated register function. Keep it for the time being for any plugins that may need it.
function S:RegisterSkin(name, loadFunc, forceLoad, bypass)
	if bypass then
		self.allowBypass[name] = true
	end

	if forceLoad then
		loadFunc()
		self.addonsToLoad[name] = nil
	elseif name == "ElvUI" then
		tinsert(self.nonAddonsToLoad, loadFunc)
	else
		self.addonsToLoad[name] = loadFunc
	end
end

--Add callback for skin that relies on another addon.
--These events will be fired when the addon is loaded.
function S:AddCallbackForAddon(addonName, eventName, loadFunc, forceLoad, bypass)
	if not addonName or type(addonName) ~= "string" then
		E:Print("Invalid argument #1 to S:AddCallbackForAddon (string expected)")
		return
	elseif not eventName or type(eventName) ~= "string" then
		E:Print("Invalid argument #2 to S:AddCallbackForAddon (string expected)")
		return
	elseif not loadFunc or type(loadFunc) ~= "function" then
		E:Print("Invalid argument #3 to S:AddCallbackForAddon (function expected)")
		return
	end

	if bypass then
		self.allowBypass[addonName] = true
	end

	--Create an event registry for this addon, so that we can fire multiple events when this addon is loaded
	if not self.addonCallbacks[addonName] then
		self.addonCallbacks[addonName] = {["CallPriority"] = {}}
	end

	if self.addonCallbacks[addonName][eventName] or E.ModuleCallbacks[eventName] or E.InitialModuleCallbacks[eventName] then
		--Don't allow a registered callback to be overwritten
		E:Print("Invalid argument #2 to S:AddCallbackForAddon (event name:", eventName, "is already registered, please use a unique event name)")
		return
	end

	--Register loadFunc to be called when event is fired
	E.RegisterCallback(E, eventName, loadFunc)

	if forceLoad then
		E.callbacks:Fire(eventName)
	else
		--Insert eventName in this addons' registry
		self.addonCallbacks[addonName][eventName] = true
		self.addonCallbacks[addonName]["CallPriority"][getn(self.addonCallbacks[addonName]["CallPriority"]) + 1] = eventName
	end
end

--Add callback for skin that does not rely on a another addon.
--These events will be fired when the Skins module is initialized.
function S:AddCallback(eventName, loadFunc)
	if not eventName or type(eventName) ~= "string" then
		E:Print("Invalid argument #1 to S:AddCallback (string expected)")
		return
	elseif not loadFunc or type(loadFunc) ~= "function" then
		E:Print("Invalid argument #2 to S:AddCallback (function expected)")
		return
	end

	if self.nonAddonCallbacks[eventName] or E.ModuleCallbacks[eventName] or E.InitialModuleCallbacks[eventName] then
		--Don't allow a registered callback to be overwritten
		E:Print("Invalid argument #1 to S:AddCallback (event name:", eventName, "is already registered, please use a unique event name)")
		return
	end

	--Add event name to registry
	self.nonAddonCallbacks[eventName] = true
	self.nonAddonCallbacks["CallPriority"][getn(self.nonAddonCallbacks["CallPriority"]) + 1] = eventName

	--Register loadFunc to be called when event is fired
	E.RegisterCallback(E, eventName, loadFunc)
end

function S:Initialize()
	self.db = E.private.skins

	--Fire events for Blizzard addons that are already loaded
	for addon in pairs(self.addonCallbacks) do
		if IsAddOnLoaded(addon) then
			for index, event in ipairs(self.addonCallbacks[addon]["CallPriority"]) do
				self.addonCallbacks[addon][event] = nil
				self.addonCallbacks[addon]["CallPriority"][index] = nil
				E.callbacks:Fire(event)
			end
		end
	end
	--Fire event for all skins that doesn't rely on a Blizzard addon
	for index, event in ipairs(self.nonAddonCallbacks["CallPriority"]) do
		self.nonAddonCallbacks[event] = nil
		self.nonAddonCallbacks["CallPriority"][index] = nil
		E.callbacks:Fire(event)
	end

	--Old deprecated load functions. We keep this for the time being in case plugins make use of it.
	for addon, loadFunc in pairs(self.addonsToLoad) do
		if IsAddOnLoaded(addon) then
			self.addonsToLoad[addon] = nil
			local _, catch = pcall(loadFunc)
			if catch and GetCVarBool("ShowErrors") == "1" then
				ScriptErrorsFrame_OnError(catch, false)
			end
		end
	end

	for _, loadFunc in pairs(self.nonAddonsToLoad) do
		local _, catch = pcall(loadFunc)
		if catch and GetCVarBool("ShowErrors") == "1" then
			ScriptErrorsFrame_OnError(catch, false)
		end
	end
	wipe(self.nonAddonsToLoad)
end

S:RegisterEvent("ADDON_LOADED")

local function InitializeCallback()
	S:Initialize()
end

E:RegisterModule(S:GetName(), InitializeCallback)