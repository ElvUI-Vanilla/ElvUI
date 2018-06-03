--[[
# Element: Castbar

Handles the visibility and updating of spell castbars.
Based upon oUF_Castbar by starlon.

## Widget

Castbar - A `StatusBar` to represent spell cast/channel progress.

## Sub-Widgets

.Text     - A `FontString` to represent spell name.
.Time     - A `FontString` to represent spell duration.

## Notes

A default texture will be applied to the StatusBar and Texture widgets if they don't have a texture or a color set.

## Options

.timeToHold - indicates for how many seconds the castbar should be visible after a _FAILED or _INTERRUPTED
              event. Defaults to 0 (number)

## Examples

    -- Position and size
    local Castbar = CreateFrame("StatusBar", nil, self)
    Castbar:SetSize(20, 20)
    Castbar:SetPoint("TOP")
    Castbar:SetPoint("LEFT")
    Castbar:SetPoint("RIGHT")

    -- Add a background
    local Background = Castbar:CreateTexture(nil, "BACKGROUND")
    Background:SetAllPoints(Castbar)
    Background:SetTexture(1, 1, 1, .5)

    -- Add a spark
    local Spark = Castbar:CreateTexture(nil, "OVERLAY")
    Spark:SetSize(20, 20)
    Spark:SetBlendMode("ADD")

    -- Add a timer
    local Time = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Time:SetPoint("RIGHT", Castbar)

    -- Add spell text
    local Text = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Text:SetPoint("LEFT", Castbar)

    -- Register it with oUF
    Castbar.bg = Background
    Castbar.Spark = Spark
    Castbar.Time = Time
    Castbar.Text = Text
    self.Castbar = Castbar
--]]
local ns = oUF
local oUF = ns.oUF

local match = string.match

local GetTime = GetTime

local function SPELLCAST_START(self, event, name, endTime)
	local element = self.Castbar
	if(not name) then
		return element:Hide()
	end

	endTime = endTime / 1000
	element.startTime = GetTime()
	element.duration = element.startTime
	element.max = endTime
	element.delay = 0
	element.casting = true
	element.holdTime = 0

	element:SetMinMaxValues(0, element.max)
	element:SetValue(0)

	if(element.Text) then element.Text:SetText(name) end
	if(element.Time) then element.Time:SetText() end

	--[[ Callback: Castbar:PostCastStart(unit, name)
	Called after the element has been updated upon a spell cast start.

	* self    - the Castbar widget
	* name    - name of the spell being cast (string)
	--]]
	if(element.PostCastStart) then
		element:PostCastStart(name)
	end
	element:Show()
end

local function SPELLCAST_FAILED(self, event)
	if(not self.casting) then return end

	local element = self.Castbar

	local text = element.Text
	if(text) then
		text:SetText(FAILED)
	end

	element.casting = nil
	element.holdTime = element.timeToHold or 0

	--[[ Callback: Castbar:PostCastFailed(unit, name)
	Called after the element has been updated upon a failed spell cast.

	* self    - the Castbar widget
	--]]
	if(element.PostCastFailed) then
		return element:PostCastFailed()
	end
end

local function SPELLCAST_INTERRUPTED(self, event)
	local element = self.Castbar

	local text = element.Text
	if(text) then
		text:SetText(INTERRUPTED)
	end

	element.casting = nil
	element.channeling = nil
	element.holdTime = element.timeToHold or 0

	--[[ Callback: Castbar:PostCastInterrupted(unit, name)
	Called after the element has been updated upon an interrupted spell cast.

	* self    - the Castbar widget
	--]]
	if(element.PostCastInterrupted) then
		return element:PostCastInterrupted()
	end
end

local function SPELLCAST_DELAYED(self, event, delay)
	local element = self.Castbar
	if(not delay or not element:IsShown()) then return end

	delay = delay / 1000
	local duration = GetTime() - (element.startTime / 1000)
	if(duration < 0) then duration = 0 end

	element.startTime = element.startTime + delay
	element.delay = delay
	element.duration = duration

	element:SetValue(duration)

	--[[ Callback: Castbar:PostCastDelayed(unit, name)
	Called after the element has been updated when a spell cast has been delayed.

	* self    - the Castbar widget
	--]]
	if(element.PostCastDelayed) then
		return element:PostCastDelayed()
	end
end

local function SPELLCAST_STOP(self, event)
	local element = self.Castbar

	if(element:IsShown()) then
		element.casting = nil
	end

	--[[ Callback: Castbar:PostCastStop(unit, name)
	Called after the element has been updated when a spell cast has finished.

	* self    - the Castbar widget
	--]]
	if(element.PostCastStop) then
		return element:PostCastStop()
	end
end

local function SPELLCAST_CHANNEL_START(self, event, endTime, name)
	local element = self.Castbar
	if(not name) then
		return
	end

	endTime = endTime / 1000
	element.startTime = GetTime()
	element.duration = element.startTime + endTime
	element.max = endTime
	element.delay = 0
	element.channeling = true
	element.holdTime = 0

	-- We have to do this, as it's possible for spell casts to never have _STOP
	-- executed or be fully completed by the OnUpdate handler before CHANNEL_START
	-- is called.
	element.casting = nil

	element:SetMinMaxValues(0, endTime)
	element:SetValue(endTime)

	if(element.Text) then element.Text:SetText(name) end
	if(element.Time) then element.Time:SetText() end

	--[[ Callback: Castbar:PostChannelStart(unit, name)
	Called after the element has been updated upon a spell channel start.

	* self    - the Castbar widget
	* name    - name of the channeled spell (string)
	--]]
	if(element.PostChannelStart) then
		element:PostChannelStart(name)
	end
	element:Show()
end

local function SPELLCAST_CHANNEL_UPDATE(self, event, delay)
	local element = self.Castbar
	if(not element:IsShown()) then
		return
	end

	delay = delay / 1000
	local duration = element.startTime + (element.max - GetTime()) - delay
	element.delay = element.delay - duration
	element.duration = duration
	element.startTime = element.startTime - duration
	element:SetValue(duration)

	--[[ Callback: Castbar:PostChannelUpdate(unit, name)
	Called after the element has been updated after a channeled spell has been delayed or interrupted.

	* self    - the Castbar widget
	--]]
	if(element.PostChannelUpdate) then
		return element:PostChannelUpdate()
	end
end

local function SPELLCAST_CHANNEL_STOP(self, event)
	local element = self.Castbar
	if(element:IsShown()) then
		element.channeling = nil

		--[[ Callback: Castbar:PostChannelUpdate(unit, name)
		Called after the element has been updated after a channeled spell has been completed.

		* self    - the Castbar widget
		--]]
		if(element.PostChannelStop) then
			return element:PostChannelStop()
		end
	end
end

local function onUpdate(self, elapsed)
	if(self.casting) then
		local duration = GetTime() - self.startTime

		if(duration >= self.max) then
			self.casting = nil
			self:Hide()

			if(self.PostCastStop) then self:PostCastStop(self.__owner.unit) end
			return
		end

		if(self.Time) then
			if(self.delay ~= 0) then
				if(self.CustomDelayText) then
					self:CustomDelayText(duration)
				else
					self.Time:SetText(format("%.1f|cffff0000-%.1f|r", duration, self.delay))
				end
			else
				if(self.CustomTimeText) then
					self:CustomTimeText(duration)
				else
					self.Time:SetText(format("%.1f", duration))
				end
			end
		end

		self.duration = duration
		self:SetValue(duration)

		if(self.Spark) then
			self.Spark:SetPoint("CENTER", self, "LEFT", (duration / ((self.startTime + self.max) - self.startTime)) * self:GetWidth(), 0)
		end
	elseif(self.channeling) then
		local duration = self.startTime + (self.max - GetTime())

		if(duration <= 0) then
			self.channeling = nil
			self:Hide()

			if(self.PostChannelStop) then self:PostChannelStop(self.__owner.unit) end
			return
		end

		if(self.Time) then
			if(self.delay ~= 0) then
				if(self.CustomDelayText) then
					self:CustomDelayText(duration)
				else
					self.Time:SetText(format("%.1f|cffff0000-%.1f|r", duration, self.delay))
				end
			else
				if(self.CustomTimeText) then
					self:CustomTimeText(duration)
				else
					self.Time:SetText(format("%.1f", duration))
				end
			end
		end

		self.duration = duration
		self:SetValue(duration)
		if(self.Spark) then
			self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
		end
	elseif(self.holdTime > 0) then
		self.holdTime = self.holdTime - elapsed
	else
		self.casting = nil
		self.castName = nil
		self.channeling = nil

		self:Hide()
	end
end

local function Update(self, ...)
	SPELLCAST_START(self, unpack(arg))
	return SPELLCAST_CHANNEL_START(self, unpack(arg))
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Castbar
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		element.holdTime = 0
		element:SetScript("OnUpdate", function()
			if element.OnUpdate then

			else
				onUpdate(this, arg1)
			end
		end)

		if(unit == "player") then
			self:RegisterEvent("SPELLCAST_START", SPELLCAST_START)
			self:RegisterEvent("SPELLCAST_STOP", SPELLCAST_STOP)
			self:RegisterEvent("SPELLCAST_FAILED", SPELLCAST_FAILED)
			self:RegisterEvent("SPELLCAST_INTERRUPTED", SPELLCAST_INTERRUPTED)
			self:RegisterEvent("SPELLCAST_DELAYED", SPELLCAST_DELAYED)
			self:RegisterEvent("SPELLCAST_CHANNEL_START", SPELLCAST_CHANNEL_START)
			self:RegisterEvent("SPELLCAST_CHANNEL_UPDATE", SPELLCAST_CHANNEL_UPDATE)
			self:RegisterEvent("SPELLCAST_CHANNEL_STOP", SPELLCAST_CHANNEL_STOP)

			CastingBarFrame:UnregisterAllEvents()
			CastingBarFrame.Show = CastingBarFrame.Hide
			CastingBarFrame:Hide()
		end

		if(element:IsObjectType("StatusBar") and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		local spark = element.Spark
		if(spark and spark:IsObjectType("Texture") and not spark:GetTexture()) then
			spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		end

		element:Hide()

		return true
	end
end

local function Disable(self)
	local element = self.Castbar
	if(element) then
		element:Hide()

		self:UnregisterEvent("SPELLCAST_START", SPELLCAST_START)
		self:UnregisterEvent("SPELLCAST_FAILED", SPELLCAST_FAILED)
		self:UnregisterEvent("SPELLCAST_STOP", SPELLCAST_STOP)
		self:UnregisterEvent("SPELLCAST_INTERRUPTED", SPELLCAST_INTERRUPTED)
		self:UnregisterEvent("SPELLCAST_DELAYED", SPELLCAST_DELAYED)
		self:UnregisterEvent("SPELLCAST_CHANNEL_START", SPELLCAST_CHANNEL_START)
		self:UnregisterEvent("SPELLCAST_CHANNEL_UPDATE", SPELLCAST_CHANNEL_UPDATE)
		self:UnregisterEvent("SPELLCAST_CHANNEL_STOP", SPELLCAST_CHANNEL_STOP)

		element:SetScript("OnUpdate", nil)
	end
end

oUF:AddElement("Castbar", function() end, Enable, Disable)