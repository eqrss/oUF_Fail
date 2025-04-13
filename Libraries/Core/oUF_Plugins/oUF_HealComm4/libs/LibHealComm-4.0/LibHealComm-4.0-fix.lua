local _, ns = ...
local MAJOR = "LibHealComm-4.0"
local MINOR = 100  -- Retail için versiyon

-- Get existing library or create new
local HealComm = LibStub:NewLibrary(MAJOR, MINOR)
if not HealComm then return end

-- Retail spell IDs
local spellData = {
    PRIEST = {
        [2050]   = {{1.5, 0.12}, 6},     -- Heal
        [2061]   = {{1.5, 0.12}, 6},     -- Flash Heal
        [32546]  = {{1.5, 0.12}, 6},     -- Binding Heal
        [596]    = {{2.5, 0.12}, 6},     -- Prayer of Healing
        [34861]  = {{1.5, 0.12}, 6},     -- Holy Word: Sanctify
        [2060]   = {{3.0, 0.12}, 6},     -- Greater Heal
        [139]    = {{2.0, 0.12}, 6},     -- Renew
    },
    DRUID = {
        [8936]   = {{1.5, 0.12}, 6},     -- Regrowth
        [33763]  = {{1.5, 0.12}, 6},     -- Lifebloom
        [48438]  = {{1.5, 0.12}, 6},     -- Wild Growth
        [18562]  = {{1.5, 0.12}, 6},     -- Swiftmend
        [774]    = {{1.5, 0.12}, 6},     -- Rejuvenation
    },
    PALADIN = {
        [19750]  = {{1.5, 0.12}, 6},     -- Flash of Light
        [82326]  = {{2.5, 0.12}, 6},     -- Holy Light
        [85222]  = {{2.5, 0.12}, 6},     -- Light of Dawn
        [25914]  = {{1.5, 0.12}, 6},     -- Holy Shock
        [53563]  = {{3.0, 0.12}, 6},     -- Beacon of Light
    },
    SHAMAN = {
        [1064]   = {{1.5, 0.12}, 6},     -- Chain Heal
        [77472]  = {{1.5, 0.12}, 6},     -- Healing Wave
        [8004]   = {{1.5, 0.12}, 6},     -- Healing Surge
        [73920]  = {{1.5, 0.12}, 6},     -- Healing Rain
        [61295]  = {{1.5, 0.12}, 6},     -- Riptide
    },
    MONK = {
        [115175] = {{1.5, 0.12}, 6},     -- Soothing Mist
        [116670] = {{1.5, 0.12}, 6},     -- Vivify
        [124682] = {{2.0, 0.12}, 6},     -- Enveloping Mist
        [115310] = {{2.0, 0.12}, 6},     -- Revival
        [116849] = {{1.5, 0.12}, 6},     -- Life Cocoon
    },
    EVOKER = {
        [355936] = {{1.5, 0.12}, 6},     -- Dream Breath
        [364343] = {{1.5, 0.12}, 6},     -- Echo
        [367230] = {{1.5, 0.12}, 6},     -- Spiritbloom
        [355941] = {{2.0, 0.12}, 6},     -- Dream Flight
        [366155] = {{1.5, 0.12}, 6},     -- Reversion
    }
}

-- Initialize when spell data is available
local function InitializeHealData()
    if not HealComm.spellData then
        HealComm.spellData = spellData
    end
end

-- Wait for PLAYER_LOGIN when spell data is available
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeHealData()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)