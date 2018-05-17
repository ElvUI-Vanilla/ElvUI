local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
--WoW API / Variables

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.binding ~= true then return end

	E:StripTextures(KeyBindingFrame)
	E:CreateBackdrop(KeyBindingFrame, "Transparent")
	E:Point(KeyBindingFrame.backdrop, "TOPLEFT", 2, 0)
	E:Point(KeyBindingFrame.backdrop, "BOTTOMRIGHT", -42, 12)

	local bindingKey1, bindingKey2
	for i = 1, KEY_BINDINGS_DISPLAYED do
		bindingKey1 = _G["KeyBindingFrameBinding"..i.."Key1Button"]
		bindingKey2 = _G["KeyBindingFrameBinding"..i.."Key2Button"]

		S:HandleButton(bindingKey1)
		S:HandleButton(bindingKey2)
		E:Point(bindingKey2, "LEFT", bindingKey1, "RIGHT", 1, 0)
	end

	S:HandleScrollBar(KeyBindingFrameScrollFrameScrollBar)

	S:HandleCheckBox(KeyBindingFrameCharacterButton)

	S:HandleButton(KeyBindingFrameDefaultButton)
	S:HandleButton(KeyBindingFrameCancelButton)
	S:HandleButton(KeyBindingFrameOkayButton)
	E:Point(KeyBindingFrameOkayButton, "RIGHT", KeyBindingFrameCancelButton, "LEFT", -3, 0)
	S:HandleButton(KeyBindingFrameUnbindButton)
	E:Point(KeyBindingFrameUnbindButton, "RIGHT", KeyBindingFrameOkayButton, "LEFT", -3, 0)
end

S:AddCallbackForAddon("Blizzard_BindingUI", "Binding", LoadSkin)