--[[
Name: StateDriver-1.0
Revision: $Rev: 107 $
Maintainers: martinjlowm
Website: https://github.com/martinjlowm/StateDriver/
Dependencies: Classy-1.0
License: None
]]

if not LibStub then return end

local SD = LibStub:NewLibrary('StateDriver-1.0', 0)
if not SD then return end

local Classy = LibStub('Classy-1.0')

local _G = getfenv(0)

function SD:New(name, parent)
    self[name] = Classy:New('Frame', parent)

    return self[name]
end

local function GetAttribute(self, prefix, name, suffix)
    local attributes = self.__state_driver.attributes
    local value

    if not name and not suffix then
        name = prefix
    else
        value = attributes[prefix .. name .. suffix]
        value = value or attributes['*' .. name .. suffix]
        value = value or attributes[prefix .. name .. '*']
        value = value or attributes['*' .. name .. '*']
    end

    return value or attributes[name]
end

local function SetAttribute(self, attr, value)
    local old_value = self.__state_driver.attributes[attr]
    self.__state_driver.attributes[attr] = value

    local func = self.__state_driver.handlers['OnAttributeChanged']
    if func and type(func) == 'function' and value ~= old_value then
        func(self, attr, value)
    end
end


-- Figure out where to place this
local function initPlayerDrop()
    UnitPopup_ShowMenu(PlayerFrameDropDown, "SELF", "player")
    if not (UnitInRaid("player") or GetNumPartyMembers() > 0) or UnitIsPartyLeader("player") and PlayerFrameDropDown.init and not CanShowResetInstances() then
        UIDropDownMenu_AddButton({text = RESET_INSTANCES, func = ResetInstances, notCheckable = 1}, 1)
        PlayerFrameDropDown.init = nil
    end
end


local ACTIONS = {}

ACTIONS.target = function(self, unit, button)
    if unit then
        if unit == 'none' then
            ClearTarget();
        elseif ( SpellIsTargeting() ) then
            SpellTargetUnit(unit);
        elseif ( CursorHasItem() ) then
            DropItemOnUnit(unit);
        else
            TargetUnit(unit);
        end
    end
end

ACTIONS.togglemenu = function(self, unit, button)
    if UnitIsUnit(unit, 'player') then
        UIDropDownMenu_Initialize(PlayerFrameDropDown, initPlayerDrop, 'MENU')
        PlayerFrameDropDown.init = true
        ToggleDropDownMenu(1, nil, PlayerFrameDropDown, 'cursor')
    elseif unit == 'pet' then
        ToggleDropDownMenu(1, nil, PetFrameDropDown, 'cursor')
    elseif unit == 'target' then
        ToggleDropDownMenu(1, nil, TargetFrameDropDown, 'cursor')
    elseif string.sub(unit, 1, 5) == 'party' then
        ToggleDropDownMenu(1, nil, _G['PartyMemberFrame' .. string.sub(unit,6) .. 'DropDown'], 'cursor')
    elseif string.sub(unit, 1, 4) == 'raid' then
        HideDropDownMenu(1)

        local menuFrame = FriendsDropDown
        menuFrame.displayMode = 'MENU'
        menuFrame.id = string.sub(this.unit,5)
        menuFrame.unit = unit
        menuFrame.name = UnitName(this.unit)
        menuFrame.initialize = function()
            UnitPopup_ShowMenu(getglobal(UIDROPDOWNMENU_OPEN_MENU), "PARTY", self.unit, self.name, self.id)
        end

        ToggleDropDownMenu(1, nil, FriendsDropDown, 'cursor')
    end
end

ACTIONS.macro = function(self, unit, button)
    local macro_text = self:GetAttribute('macrotext')
    local spell, unit = SecureCmdOptionParse(macro_text)
    CastSpellByName(spell, unit)
end

ACTIONS.spell = function(self, unit, button)
    local spell = self:GetAttribute('spell')
    CastSpellByName(spell)
end

ACTIONS.pet = function(self, unit, button)
    local index = self:GetAttribute('pet')
    CastPetAction(index, unit)
end

ACTIONS.func = function(self, unit, button)
    local func = SlashCmdList[self:GetAttribute('func')]

    if not func then
        error(string.format('Slash command `%s` does not exist in SlashCmdList'))
        return
    end

    func()
end

local link_pattern = '%[([^%]]+)%]'
local function CmdItemParse(item)
    local slot = tonumber(item)
    if slot then
        return nil, nil, slot
    end

    local link, name
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            link = GetContainerItemLink(bag, slot)

            if link then
                name = string.match(link, link_pattern)
                if name and name == item then
                    return name, bag, slot
                end
            end
        end
    end
end

ACTIONS.item = function(self, unit, button)
    local item = self:GetAttribute('item')

    if item then
        local name, bag, slot = CmdItemParse(item)
        UseItem(name, bag, slot)
    end
end

function UseItem(name, bag, slot)
    if bag then
        UseContainerItem(bag, slot)
    elseif slot then
        UseInventoryItem(slot)
    end
end

ACTIONS.assign = function(self, unit, button)
    local macro_text = self:GetAttribute('assign')
    local symbol, unit = SecureCmdOptionParse(macro_text)
    SetRaidTargetIcon(unit, symbol)
end

function Button_GetModifierPrefix(frame)
    local prefix = ''
    prefix = IsShiftKeyDown() and 'shift-' .. prefix or prefix
    prefix = IsControlKeyDown() and 'ctrl-' .. prefix or prefix
    return IsAltKeyDown() and 'alt-' .. prefix or prefix
end

function Button_GetButtonSuffix(button)
    if button == 'LeftButton' then
        return '1'
    elseif button == 'RightButton' then
        return '2'
    elseif button == 'MiddleButton' then
        return '3'
    end

    return '';
end

function Button_GetModifiedAttribute(frame, name, button, prefix, suffix)
    if not prefix then
        prefix = Button_GetModifierPrefix(frame)
    end
    if not suffix then
        suffix = Button_GetButtonSuffix(button)
    end

    return frame:GetAttribute(prefix, name, suffix)
end

local function OnClick(self, button)
    if not self.GetAttribute then return end

    local unit = self:GetAttribute('unit')

    local action_type = Button_GetModifiedAttribute(self, 'type', button)

    if action_type then
        local handler = ACTIONS[action_type]
        if handler and type(handler) == 'function' then
            handler(self, unit, button)
        end
    end

end

local function SetScript(self, handler, func)
    if self.__state_driver.handlers[handler] then
        if self:HasScript(handler) and handler == 'OnClick' then
            self.__state_driver._SetScript(self, handler, function(...)
                                               OnClick(this, arg1)
                                               func()
            end)
        else
            self.__state_driver.handlers[handler] = func
        end
    else
        self.__state_driver._SetScript(self, handler, func)
    end
end

local _CreateFrame = CreateFrame
function CreateFrame(...)
    local frame = _CreateFrame(unpack(arg))

    -- State Driver environment
    frame.__state_driver = {}

    frame.__state_driver._SetScript = frame.SetScript
    frame.SetScript = SetScript

    frame.__state_driver.attributes = {}
    frame.__state_driver.handlers = {
        ['OnAttributeChanged'] = true,
        ['OnClick'] = true
    }

    frame.GetAttribute = GetAttribute
    frame.SetAttribute = SetAttribute

    if frame:HasScript('OnClick') and not frame:GetScript('OnClick') then
        frame:SetScript('OnClick', NOOP)
    end

    return frame
end

local function Execute(frame, func)

end

local function WrapScript(frame, func)

end

local function UnwrapScript(frame, func)

end

local function ChildUpdate(frame, attr_snippet, value)
    local children = { frame:GetChildren() }
    local childUpdate

    for _, child in next, children do
        if child.GetAttribute then
            childUpdate = child:GetAttribute('_childupdate-' .. attr_snippet)
            if childUpdate then
                childUpdate(child, value)
            else
                childUpdate = child:GetAttribute('_childupdate')
                if childUpdate then
                    childUpdate(child, value)
                end
            end
            ChildUpdate(child, attr_snippet, value)
        end
    end
end

--
-- SecureStateDriverManager
-- Automatically sets states based on macro options for state driver frames
-- Also handled showing/hiding frames based on unit existence (code originally by Tem)
--

-- Register a frame attribute to be set automatically with changes in game state
function RegisterAttributeDriver(frame, attribute, values)
    frame.Execute = Execute
    frame.WrapScript = WrapScript
    frame.UnwrapScript = UnwrapScript
    frame.ChildUpdate = ChildUpdate
    if attribute and values and string.sub(attribute, 1, 1) ~= '_' then
        Manager:SetAttribute('setframe', frame)
        Manager:SetAttribute('setstate', attribute .. ' ' .. values)
    end
end

-- Unregister a frame from the state driver manager.
function UnregisterAttributeDriver(frame, attribute)
    if attribute then
        Manager:SetAttribute('setframe', frame)
        Manager:SetAttribute('setstate', attribute)
    else
        Manager:SetAttribute('delframe', frame)
    end
end

-- Bridge functions for compatibility
function RegisterStateDriver(frame, state, values)
    return RegisterAttributeDriver(frame, 'state-' .. state, values)
end

function UnregisterStateDriver(frame, state)
    return UnregisterAttributeDriver(frame, 'state-' .. state)
end

-- Register a frame to be notified when a unit's existence changes, the
-- unit is obtained from the frame's attributes. If asState is true then
-- notification is via the 'state-unitexists' attribute with values
-- true and false. Otherwise it's via :Show() and :Hide()
function RegisterUnitWatch(frame, asState)
    if asState then
        Manager:SetAttribute('addwatchstate', frame)
    else
        Manager:SetAttribute('addwatch', frame)
    end
end

-- Unregister a frame from the unit existence monitor.
function UnregisterUnitWatch(frame)
    SecureStateDriverManager:SetAttribute('removewatch', frame)
end

--
-- Private implementation
--
local secureAttributeDrivers = {}
local unitExistsWatchers = {}
local unitExistsCache = setmetatable(
    {},
    { __index = function(t,k)
          local v = UnitExists(k) or false
          t[k] = v
          return v
    end
})
local STATE_DRIVER_UPDATE_THROTTLE = 0.1
local timer = 0

local wipe = table.wipe

-- Check to see if a frame is registered
function UnitWatchRegistered(frame)
    return not (unitExistsWatchers[frame] == nil)
end

local function SecureStateDriverManager_UpdateUnitWatch(frame, doState)
    -- Not really so secure, eh?
    local unit = frame:GetAttribute('unit')
    local exists = (unit and unitExistsCache[unit])
    if doState then
        local attr = exists or false
        if frame:GetAttribute('state-unitexists') ~= attr then
            frame:SetAttribute('state-unitexists', attr)
        end
    else
        if exists then
            frame:Show()
            frame:SetAttribute('statehidden', nil)
        else
            frame:Hide()
            frame:SetAttribute('statehidden', true)
        end
    end
end

local pairs = pairs

-- consolidate duplicated code for footprint and maintainability
local function resolveDriver(frame, attribute, values)
    local newValue = SecureCmdOptionParse(values)

    if attribute == 'state-visibility' then
        if newValue == 'show' then
            frame:Show()
            frame:SetAttribute('statehidden', nil)
        elseif newValue == 'hide' then
            frame:Hide()
            frame:SetAttribute('statehidden', true)
        end
    elseif newValue then
        if newValue == 'nil' then
            newValue = nil
        else
            newValue = tonumber(newValue) or newValue
        end
        local oldValue = frame:GetAttribute(attribute)
        if newValue ~= oldValue then
            frame:SetAttribute(attribute, newValue)
            local onState = frame:GetAttribute('_on' .. attribute)
            if onState then
                onState(frame, attribute, newValue)
            end
        end
    end
end

local function OnUpdate()
    local self, elapsed = this, arg1

    timer = timer - elapsed
    if timer <= 0 then
        timer = STATE_DRIVER_UPDATE_THROTTLE

        -- Handle state driver updates
        for frame, drivers in next, secureAttributeDrivers do
            for attribute, values in next, drivers do
                resolveDriver(frame, attribute, values)
            end
        end

        -- Handle unit existence changes
        wipe(unitExistsCache)
        for k in next, unitExistsCache do
            unitExistsCache[k] = nil
        end
        for frame, doState in next, unitExistsWatchers do
            SecureStateDriverManager_UpdateUnitWatch(frame, doState)
        end
    end
end

local function OnEvent()
    local self, event = this, arg1

    timer = 0
end

local function OnAttributeChanged(self, name, value)
    if not value then
        return
    end

    if name == 'setframe' then
        if not secureAttributeDrivers[value] then
            secureAttributeDrivers[value] = {}
        end
        SecureStateDriverManager:Show()
    elseif name == 'delframe' then
        secureAttributeDrivers[value] = nil
    elseif name == 'setstate' then
        local frame = self:GetAttribute('setframe')
        local attribute, values = string.match(value, '^(%S+)%s*(.*)$')

        if values == '' then
            secureAttributeDrivers[frame][attribute] = nil
        else
            secureAttributeDrivers[frame][attribute] = values
            resolveDriver(frame, attribute, values)
        end
        -- Two frames registering with identical setstate fails unless the value
        -- is reset afterwards
        self:SetAttribute('setstate', nil)
    elseif name == 'addwatch' or name == 'addwatchstate' then
        local doState = (name == 'addwatchstate')
        unitExistsWatchers[value] = doState
        SecureStateDriverManager:Show()
        SecureStateDriverManager_UpdateUnitWatch(value, doState)
    elseif name == 'removewatch' then
        unitExistsWatchers[value] = nil
    elseif name == 'updatetime' then
        STATE_DRIVER_UPDATE_THROTTLE = value
    end
end


Manager = SD:New('Manager')
Manager:SetScript('OnUpdate', OnUpdate)
Manager:SetScript('OnEvent', OnEvent)
Manager:SetScript('OnAttributeChanged', OnAttributeChanged)

-- Events that trigger early rescans
Manager:RegisterEvent('MODIFIER_STATE_CHANGED')
Manager:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
Manager:RegisterEvent('UPDATE_BONUS_ACTIONBAR')
Manager:RegisterEvent('PLAYER_ENTERING_WORLD')
Manager:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
Manager:RegisterEvent('UPDATE_STEALTH')
Manager:RegisterEvent('PLAYER_TARGET_CHANGED')
Manager:RegisterEvent('PLAYER_FOCUS_CHANGED')
Manager:RegisterEvent('PLAYER_REGEN_DISABLED')
Manager:RegisterEvent('PLAYER_REGEN_ENABLED')
Manager:RegisterEvent('UNIT_PET')
Manager:RegisterEvent('GROUP_ROSTER_UPDATE')
-- Deliberately ignoring mouseover and others' target changes because they change so much

_G['SecureStateDriverManager'] = Manager