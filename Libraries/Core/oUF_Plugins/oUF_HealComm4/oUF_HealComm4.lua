--[[
	oUF-HealComm bindings
	Credits: Krage (original oUF_HealComm)

	Elements handled: .HealCommBar, .HealCommText

	Options

	Optional:
	.HealCommOthersOnly: (boolean)       Ignore the player's outbound heals
	.HealCommTimeframe: (integer)        Only show heals that land in the next x seconds
	.allowHealCommOverflow: (boolean)    Allow the HealComm bar to flow beyond the end of the Health bar

	Functions that can be overridden from within a layout:
	:HealCommTextFormat(value)         Formats the heal amount passed for display on .HealCommText
]]
local _, ns = ...
local oUF = ns.oUF or oUF

assert(oUF, "oUF_HealComm4 was unable to locate oUF install")

local function Update(self, event, unit)
    if not self.unit or not unit or self.unit ~= unit then return end
    
    local element = self.HealPrediction
    if not element or not element.myBar then return end

    -- Get current health values
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local currentPercent = health / maxHealth

    -- Get incoming heals
    local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
    local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
    
    -- Hide bar if no heals incoming
    if myIncomingHeal == 0 and allIncomingHeal == 0 then
        element.myBar:Hide()
        return
    end

    -- Calculate heal size and ensure it doesn't overflow
    local healSize = myIncomingHeal / maxHealth
    local maxFill = math.min(1.0, currentPercent + healSize)
    
    -- Update the heal prediction bar
    element.myBar:SetMinMaxValues(0, 1)
    element.myBar:SetValue(maxFill - currentPercent)
    element.myBar:Show()
end

local function Path(self, ...)
    return (self.HealPrediction.Override or Update) (self, ...)
end

local function ForceUpdate(element)
    return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
    local element = self.HealPrediction
    if not element then return end

    if not element.myBar then return end

    element.__owner = self
    element.ForceUpdate = ForceUpdate

    self:RegisterEvent('UNIT_HEALTH', Path)
    self:RegisterEvent('UNIT_MAXHEALTH', Path)
    self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
    
    return true
end

local function Disable(self)
    local element = self.HealPrediction
    if not element then return end

    self:UnregisterEvent('UNIT_HEALTH', Path)
    self:UnregisterEvent('UNIT_MAXHEALTH', Path)
    self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
    
    if element.myBar then
        element.myBar:Hide()
    end
end

oUF:AddElement('HealPrediction', Update, Enable, Disable)
