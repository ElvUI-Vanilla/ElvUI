if not LibStub then return end

local SD = LibStub:GetLibrary('StateDriver-1.0')
if not SD then return end

local Parser = SD:New('Parser')

local IsMounted = IsMounted
local IsStealthed = IsStealthed
local GetShapeshiftForm = GetShapeshiftForm

local _G = getfenv(0)
local function IsInShapeshiftForm(index)
    return GetShapeshiftForm() == tonumber(index)
end


function Parser:Initialize()
    self.casting = nil
    self.channel_spell = nil
    self.channeling = nil

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('SPELLCAST_START')
    self:RegisterEvent('SPELLCAST_CHANNEL_START')
    self:RegisterEvent('SPELLCAST_STOP')
    self:RegisterEvent('SPELLCAST_CHANNEL_STOP')
    -- self:SetScript('OnEvent', function() self[event](self) end)
end

local _CastSpellByName
local Hooked_CastSpellByName = function(spell, unit)
    if spell then
        self.channel_spell = spell
        _CastSpellByName(spell, unit)
    end
end

local HOOKED = false
function Parser:PLAYER_ENTERING_WORLD()
    if not HOOKED then
        _CastSpellByName = CastSpellByName
        CastSpellByName = Hooked_CastSpellByName
        HOOKED = true
    end
end

function Parser:SPELLCAST_START()
    self.casting = arg1
end

function Parser:SPELLCAST_CHANNEL_START()
    self.channeling = true
end

function Parser:SPELLCAST_STOP()
    self.casting = false
end

function Parser:SPELLCAST_CHANNEL_STOP()
    self.channel_spell = nil
    self.channeling = false
end

local conditions_map, casting, existence, hostility
do
    local function IsChanneling(dependency)
        return dependency and dependency == Parser.channeling or Parser.channeling
    end

    local function IsCasting(dependency)
        return dependency and dependency == Parser.casting or Parser.casting
    end

    local function IsMouseOverUnit()
        local is_mouseover = false

        is_mouseover = UnitName('mouseover') and 'mouseover'

        local frame = GetMouseFocus()
        if frame and frame.GetAttribute then
            is_mouseover = is_mouseover or frame:GetAttribute('unit')
        end
        is_mouseover = is_mouseover or frame and frame.unit

        return is_mouseover
    end

    local function modifierCondition(dependency)
        dependency = dependency == 'ctrl' and 'control' or dependency
        local modifier = string.gsub(dependency, "^%l", string.upper)
        return _G['Is' .. modifier .. 'KeyDown']()
    end

    -- Rename dependent?
    casting = {
        ['channeling'] = IsChanneling,
        ['nochanneling'] = function(dependency)
            return not IsChanneling(dependency)
        end,
        ['casting'] = IsCasting,
        ['nocasting'] = function(dependency)
            return not IsCasting(dependency)
        end,
        ['group'] = function(dependency)
            local in_raid = UnitInRaid('player')
            -- Player is apparently always in a party... Party Rock Anthem, GO!
            local in_party = UnitInParty('party1')

            if dependency then
                if dependency == 'raid' then
                    return in_raid
                else
                    return in_party
                end
            else
                return in_raid or in_party
            end
        end,
        ['nogroup'] = function(dependency)
            local in_raid = UnitInRaid('player')
            local in_party = UnitInParty('party1')

            if dependency then
                if dependency == 'raid' then
                    return not in_raid
                else
                    return not in_party
                end
            else
                return (not in_raid) and (not in_party)
            end
        end,
        ['mod'] = modifierCondition,
        ['modifier'] = modifierCondition,
        ['form'] = IsInShapeshiftForm,
        ['stance'] = IsInShapeshiftForm
    }

    existence = {
        ['exists'] = UnitExists,
        ['noexists'] = function(unit)
            return not UnitExists(unit)
        end,
        ['dead'] = function(unit)
            return UnitIsDead(unit) and not UnitAura(unit, 'Feign Death')
        end,
        ['nodead'] = function(unit)
            return not (UnitIsDead(unit) and not UnitAura(unit, 'Feign Death'))
        end,
    }


    hostility = {
        ['harm'] = function(unit_one, unit_two)
            return UnitExists(unit_two) and (not UnitIsFriend(unit_one, unit_two))
        end,
        ['nohelp'] = function(unit_one, unit_two)
            return UnitExists(unit_two) and (not UnitIsFriend(unit_one, unit_two))
        end,
        ['help'] = UnitIsFriend,
        ['noharm'] = UnitIsFriend
    }


    conditions_map = {
        -- Targets
        ['mouseover'] = IsMouseOverUnit,

        ['pet'] = HasPetUI,
        ['nopet'] = function() return not HasPetUI() end,

        ['party'] = UnitInParty,
        ['raid'] = UnitInRaid,

        ['combat'] = UnitAffectingCombat,

        ['mounted'] = IsMounted,
        -- ['indoors'] = IsIndoors,
        -- ['outdoors'] = IsOutdoors,
        ['stealth'] = IsStealthed,
        -- ['swimming'] = IsSwimming,

        ['bonusbar'] = function(bar_id)
            return false
        end,
    }

    for k, v in next, casting do conditions_map[k] = v end
    for k, v in next, existence do conditions_map[k] = v end
    for k, v in next, hostility do conditions_map[k] = v end
end

function CmdOptionParse(command)
    -- /action [conditions]
    local action, conditions

    -- Accumulating condition
    local acc_condition

    -- Condition-mapped function and dependency argument
    local func, dependency

    -- [@target]
    local target, is_cond_target

    if not string.find(command, ';') then
        command = command .. ' ;'
    end

    -- Iterate condition cases
    for _, cases in { string.split(';', command) } do
        conditions, action = string.match(cases, '%[([^%]]+)%]%s*(.+)')

        -- Does the action have any conditions?
        if conditions then
            conditions = { string.split(',', conditions) }
            acc_condition = true
            target = nil
            for _, cond in conditions do
                cond = string.trim(cond)
                cond, dependency = string.split(':', cond)

                -- Is the current condition a target command? Usually the first
                -- condition is
                is_cond_target =
                    string.match(cond, '@(.*)') or
                    string.match(cond, 'target=(.*)')

                -- Mouseover has a special condition, since unitframes don't
                -- utilise the mouseover unit, in which case it's mapped to
                -- player, target, partyN etc.
                func = conditions_map[is_cond_target or cond]

                if is_cond_target then
                    target = func and func() or is_cond_target
                else
                    local res

                    if hostility[cond] then
                        res = func and func('player', target or 'target')
                    elseif existence[cond] then
                        res = func and func(target or 'target')
                    elseif cond == 'combat' then
                        res = func and func('player')
                    elseif casting[cond] then
                        res = func and func(dependency)
                    else
                        res = func and func()
                    end

                    acc_condition = acc_condition and res
                end
            end

            -- Are all conditions met? Then perform that action
            if acc_condition then
                return string.trim(action), target
            end
        else
            local cases = string.trim(cases)
            return cases
        end
    end
end
SecureCmdOptionParse = CmdOptionParse

Parser:Initialize()