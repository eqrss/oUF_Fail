settingsDB = settingsDB or {}
settingsDB.enableCharacterILVLInfo = true

-- Add at the very top of the file to fix formatting issues
local format = string.format
local max = math.max

-- Castbar Timer
local function CastbarSetText(castingFrame)
    if not castingFrame.timer then return end
    if castingFrame.casting then
      castingFrame.timer:SetText(format("\124cFF00FF00%2.1f/%1.1f", max(castingFrame.maxValue - castingFrame.value, 0), castingFrame.maxValue))
     elseif castingFrame.channeling then
      castingFrame.timer:SetText(format("\124cFF00FF00%.1f", max(castingFrame.value, 0)))
    else
      castingFrame.timer:SetText("")
    end
  end
  
  function UpgradeDefaultCastbar(position)
    if not settingsDB.enableUpgradedCastbar then return end
    if not PlayerCastingBarFrame.timer then
      PlayerCastingBarFrame.timer = PlayerCastingBarFrame:CreateFontString(nil)
      PlayerCastingBarFrame.timer:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
      PlayerCastingBarFrame.timer:SetText("")
      PlayerCastingBarFrame.Icon:AdjustPointsOffset(2, -4)
      PlayerCastingBarFrame.Icon:SetScale(1.5)
      PlayerCastingBarFrame:HookScript("OnValueChanged", function(self)
        PlayerCastingBarFrame.Icon:Show()
        CastbarSetText(self)
      end)
    end
    PlayerCastingBarFrame.timer:ClearAllPoints()
    PlayerCastingBarFrame.timer:SetPoint(position, PlayerCastingBarFrame, position, 0, 1)
    if not TargetFrameSpellBar.timer then
      TargetFrameSpellBar.timer = TargetFrameSpellBar:CreateFontString(nil)
      TargetFrameSpellBar.timer:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
      TargetFrameSpellBar.timer:SetText("")
      TargetFrameSpellBar:HookScript("OnValueChanged", function(self)
        CastbarSetText(self)
      end)
    end
    TargetFrameSpellBar.timer:ClearAllPoints()
    TargetFrameSpellBar.timer:SetPoint(position, TargetFrameSpellBar, position, 0, 1)
    if not FocusFrameSpellBar.timer then
      FocusFrameSpellBar.timer = FocusFrameSpellBar:CreateFontString(nil)
      FocusFrameSpellBar.timer:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
      FocusFrameSpellBar.timer:SetText("")
      FocusFrameSpellBar:HookScript("OnValueChanged", function(self)
        CastbarSetText(self)
      end)
    end
    FocusFrameSpellBar.timer:ClearAllPoints()
    FocusFrameSpellBar.timer:SetPoint(position, FocusFrameSpellBar, position, 0, 1)
  end
  -- Castbar Timer // END

-- Decimal ilvl
local function DecimalILVL(statFrame, unit)
    if unit ~= "player" or (not settingsDB.enableDecimalILVL and not settingsDB.enableClassColorILVL) then
        return
    end
    local maxiLvl, equippediLvl = GetAverageItemLevel()
    local ilvlText
    if settingsDB.enableDecimalILVL then
        ilvlText = (equippediLvl ~= maxiLvl and string.format("%.2f".."/%.2f", equippediLvl, maxiLvl)) or string.format("%.2f", equippediLvl)
    end
    ilvlText = settingsDB.enableDecimalILVL and ilvlText or string.format("%d", equippediLvl)
    local classColor = (RAID_CLASS_COLORS[select(2, UnitClass(unit))]).colorStr or "ffa335ee"
    ilvlText = (settingsDB.enableClassColorILVL and "|c"..classColor..ilvlText.."|r") or ilvlText
    PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, ilvlText, false, ilvlText)  
end
hooksecurefunc("PaperDollFrame_SetItemLevel", DecimalILVL)
-- Decimal ilvl // END

-- CharacterInfo and InspectCharacter ILVL
local _G = _G
local defaultFont = STANDARD_TEXT_FONT
local defaultFontsize = 13
local defaultFontOutline = "OUTLINE"
local defaultGemSize = 14
local TwoHanders = {
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_2HWEAPON"] = true
}
local DKEnchants = {
    ["Hysteria"] = 460688,
    ["Razorice"] = 135842,
    ["Sanguination"] = 1778226,
    ["Spellwarding"] = 425952,
    ["Apocalypse"] = 237535,
    ["Fallen\nCrusader"] = 135957,
    ["Stoneskin\nGargoyle"] = 237480,
    ["Unending\nThirst"] = 3163621,
}
local RetailEnchants = {
    -- Rank3
    ["Cursed VersatilityProfessions-ChatIcon-Quality-Tier3"] = "+375 Versatility\n|cFFa335ee-110 Mastery|r",
    ["Cursed MasteryProfessions-ChatIcon-Quality-Tier3"] = "+375 Mastery\n|cFFa335ee-110 Critical Strike|r",
    ["Cursed HasteProfessions-ChatIcon-Quality-Tier3"] = "+375 Haste\n|cFFa335ee-110 Versatility|r",
    ["Cursed Critical StrikeProfessions-ChatIcon-Quality-Tier3"] = "+375 Critical Strike\n      |cFFa335ee-110 Haste|r",
    ["Cavalry's MarchProfessions-ChatIcon-Quality-Tier3"] = "+10% Mount",
    ["Scout's MarchProfessions-ChatIcon-Quality-Tier3"] = "+250 Speed",
    ["Defender's MarchProfessions-ChatIcon-Quality-Tier3"] = "+131 Stamina",
    ["Stormrider's AgilityProfessions-ChatIcon-Quality-Tier3"] = "+111 Agility\n+250 Speed",
    ["Council's IntellectProfessions-ChatIcon-Quality-Tier3"] = "+111 Intellect\n+5% Mana",
    ["Crystalline RadianceProfessions-ChatIcon-Quality-Tier3"] = "+150 Strength",
    ["Oathsworn's StrengthProfessions-ChatIcon-Quality-Tier3"] = "+111 Strength\n+374 Stamina",
    ["Chant of Winged GraceProfessions-ChatIcon-Quality-Tier3"] = "+125 Avoidance\n-20% Fall Damage",
    ["Chant of Leeching FangsProfessions-ChatIcon-Quality-Tier3"] = "+125 Leech\nHeal OOC",
    ["Chant of Burrowing RapidityProfessions-ChatIcon-Quality-Tier3"] = "+125 Speed     \nHearthstone CD",
    -- TODO: Rank2/1
}
local sumILVL = 0
local weaponLevel = 0
local characterSlots = {
    [1] = {id = 1, side = "LEFT", name = "Head", canEnchant = false},
    [2] = {id = 2, side = "LEFT", name = "Neck", canEnchant = false},
    [3] = {id = 3, side = "LEFT", name = "Shoulder", canEnchant = false},
    -- [4] = {id = 4, side = "LEFT", name = "Shirt", canEnchant = false},
    [5] = {id = 5, side = "LEFT", name = "Chest", canEnchant = true},
    [6] = {id = 6, side = "RIGHT", name = "Waist", canEnchant = false},
    [7] = {id = 7, side = "RIGHT", name = "Legs", canEnchant = true},
    [8] = {id = 8, side = "RIGHT", name = "Feet", canEnchant = true},
    [9] = {id = 9, side = "LEFT", name = "Wrist", canEnchant = true},
    [10] = {id = 10, side = "RIGHT", name = "Hands", canEnchant = false},
    [11] = {id = 11, side = "RIGHT", name = "Finger0", canEnchant = true},
    [12] = {id = 12, side = "RIGHT", name = "Finger1", canEnchant = true},
    [13] = {id = 13, side = "RIGHT", name = "Trinket0", canEnchant = false},
    [14] = {id = 14, side = "RIGHT", name = "Trinket1", canEnchant = false},
    [15] = {id = 15, side = "LEFT", name = "Back", canEnchant = true},
    [16] = {id = 16, side = "RIGHT", name = "MainHand", canEnchant = true},
    [17] = {id = 17, side = "LEFT", name = "SecondaryHand", canEnchant = true},
    --    [18] = {id = 18, side = "LEFT", name = "Ranged", canEnchant = false},
    [19] = {id = 19, side = "LEFT", name = "Tabard", canEnchant = false} -- using as an anchor for average ilvl
}
-- update these after each tier patch
local maxUpgaradeLevel = 535
local maxUpgradeLevels = {
    [476] = {10321, 10322, 10323, 10324, 10325, 10326, 10327, 10328}, -- Explorer
    [489] = {10305, 10306, 10307, 10308, 10309, 10310, 10311, 10312}, -- Adventurer
    [502] = {10341, 10342, 10343, 10344, 10345, 10346, 10347, 10348}, -- Veteran
    [515] = {10313, 10314, 10315, 10316, 10317, 10318, 10319, 10320}, -- Champion
    [522] = {10329, 10330, 10331, 10332, 10333, 10334}, -- Hero
    [525] = {
        9401,9402,9403,9404,9405, -- Qualities
        8785,
        8845,8846,
    9373,9374,9375,9376}, -- Crafted
    [528] = {10335, 10336, 10337, 10338, 10407, 10408, 10409, 10410, 10411, 10412, 10413, 10414, 10415, 10416, 10417, 10418}, -- Myth + Awakened
    -- [528] = {10407, 10408, 10409, 10410, 10411, 10412, 10413, 10414, 10415, 10416, 10417, 10418}, -- Awakened
    [535] = {10490, 10491, 10492, 10493, 10494, 10495, 10496, 10497, 10498, 10499, 10500, 10501, 10502, 10503} -- Awakened+
}

local GetMaxUpgradeLevel = function(bonusId)
    for level, ids in pairs(maxUpgradeLevels) do
        for i, id in pairs(ids) do
            if id == bonusId then
                return level
            end
        end
    end
    return nil
end

local CreateSlotFrame = function(unitId, slot)
    if slot == nil then
        return nil
    end
    
    local slotPrefix = unitId == "player" and "Character" or "Inspect"

    local parent = _G[slotPrefix .. slot.name .. "Slot"]
    if parent == nil then
        return nil
    end
    
    local relativePoint = slot.side == "LEFT" and "RIGHT" or "LEFT"
    local offsetX = slot.side == "LEFT" and 13 or -13
    local offsetEnchantY = ((slot.id == 16 or slot.id == 17) and -12) or 8
    
    if parent.EquipmentSlotFrame == nil then
        parent.EquipmentSlotFrame = CreateFrame("Frame", parent:GetName() .. "EquipmentSlotFrame", parent)
        parent.EquipmentSlotFrame:SetPoint("CENTER")
        parent.EquipmentSlotFrame:SetAllPoints(parent)
    else
        return parent
    end
    
    if parent.EquipmentSlotFrame.levelString == nil then
        parent.EquipmentSlotFrame.levelString = parent.EquipmentSlotFrame:CreateFontString(parent.EquipmentSlotFrame:GetName() .. "Level", "OVERLAY")
        parent.EquipmentSlotFrame.levelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 0, 0)
        parent.EquipmentSlotFrame.levelString:SetFont(defaultFont, defaultFontsize, "OUTLINE")
        parent.EquipmentSlotFrame.levelString:Hide()
    end

    -- for average ilvl on inspect
    if slot.id == 19 then
        parent.EquipmentSlotFrame.levelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 140, 0)
        parent.EquipmentSlotFrame.tex = parent.EquipmentSlotFrame:CreateTexture()
        parent.EquipmentSlotFrame.tex:SetPoint("CENTER", parent.EquipmentSlotFrame.levelString, "CENTER", 0, 0)
        parent.EquipmentSlotFrame.tex:SetAtlas("UI-Character-Info-ItemLevel-Bounce", true)
        parent.EquipmentSlotFrame.tex:SetAlpha((unitId~="player" and 0.298) or 0)

        return parent
    end
    
    if parent.EquipmentSlotFrame.maxLevelString == nil then
        parent.EquipmentSlotFrame.maxLevelString = parent.EquipmentSlotFrame:CreateFontString(parent.EquipmentSlotFrame:GetName() .. "MaxLevel", "OVERLAY")
        parent.EquipmentSlotFrame.maxLevelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 0, -8)
        parent.EquipmentSlotFrame.maxLevelString:SetFont(defaultFont, defaultFontsize - 3, "OUTLINE")
        parent.EquipmentSlotFrame.maxLevelString:Hide()
    end
    
    if parent.EquipmentSlotFrame.enchantString == nil then
        parent.EquipmentSlotFrame.enchantString = parent.EquipmentSlotFrame:CreateFontString(parent.EquipmentSlotFrame:GetName() .. "Enchant", "OVERLAY")
        parent.EquipmentSlotFrame.enchantString:SetPoint(slot.side, parent.EquipmentSlotFrame, relativePoint,
        (slot.id == 17 and unitId~="player" and 3) or offsetX,
        (slot.id == 17 and unitId~="player" and 8) or offsetEnchantY)
        parent.EquipmentSlotFrame.enchantString:SetFont(defaultFont, defaultFontsize - 3, "OUTLINE")
        parent.EquipmentSlotFrame.enchantString:Hide()
    end
    
    if parent.EquipmentSlotFrame.socketFrame == nil then
        parent.EquipmentSlotFrame.socketFrame = {}
        for i = 1, 3 do
            if parent.EquipmentSlotFrame.socketFrame[i] == nil then
                parent.EquipmentSlotFrame.socketFrame[i] = CreateFrame("Button", parent.EquipmentSlotFrame:GetName() .. "Socket" .. i, parent.EquipmentSlotFrame, "SettingsCheckBoxTemplate")
                parent.EquipmentSlotFrame.socketFrame[i]:SetSize(defaultGemSize, defaultGemSize)
                local gemOffsetY = ((defaultGemSize) * ((i==1 and 1) or (i==2 and 0) or (i==3 and -1)))
                parent.EquipmentSlotFrame.socketFrame[i]:SetPoint(slot.side, parent.EquipmentSlotFrame:GetName(), relativePoint, slot.side=="LEFT" and -2 or 2, gemOffsetY)
                parent.EquipmentSlotFrame.socketFrame[i]:Disable()
                parent.EquipmentSlotFrame.socketFrame[i].gem = parent.EquipmentSlotFrame.socketFrame[i]:CreateTexture()
                parent.EquipmentSlotFrame.socketFrame[i].gem:ClearAllPoints()
                parent.EquipmentSlotFrame.socketFrame[i].gem:SetPoint("CENTER", parent.EquipmentSlotFrame.socketFrame[i], "CENTER", 0, 0)
                parent.EquipmentSlotFrame.socketFrame[i].gem:SetSize(defaultGemSize-6.5, defaultGemSize-6.5)
                parent.EquipmentSlotFrame.socketFrame[i]:Hide()
            end
        end
    end
    
    return parent
end

local function UpdateAverageItemLevel(unitId, positionBySlot)
    if unitId == nil or UnitGUID(unitId) == nil or positionBySlot == nil or
       characterSlots[positionBySlot] == nil then
		return
	end

    local slot = characterSlots[positionBySlot]
    local parent = CreateSlotFrame(unitId, slot)
    if parent == nil or parent.EquipmentSlotFrame == nil then
        return
    end

    if not settingsDB.enableCharacterILVLInfo then
        parent.EquipmentSlotFrame:Hide()
        return
    end

    local averageILVL = (unitId~="player" and string.format("%.2f", (sumILVL+weaponLevel)/16)) or ""
    local classColor = (RAID_CLASS_COLORS[select(2, UnitClass(unitId))]).colorStr or "ffa335ee"
    parent.EquipmentSlotFrame.levelString:SetText("|c"..classColor..averageILVL.."|r")
    parent.EquipmentSlotFrame.levelString:Show()
    parent.EquipmentSlotFrame:Show()
end

local function SetupItemLevel(parent, itemLevel, itemPayloadSplit, itemRarityColorHex)
    if not settingsDB.enableCharacterILVLInfo then
        parent.EquipmentSlotFrame.levelString:Hide()
        parent.EquipmentSlotFrame.maxLevelString:Hide()
        return
    end

    local maxLevel = nil

    parent.EquipmentSlotFrame.levelString:SetTextColor(1, 1, 1, 1)
    parent.EquipmentSlotFrame.maxLevelString:SetTextColor(0, 1, 0, 1)

    if itemLevel == nil then
        parent.EquipmentSlotFrame.levelString:Hide()
        parent.EquipmentSlotFrame.maxLevelString:Hide()
    else
        parent.EquipmentSlotFrame.levelString:SetText(tostring(itemLevel))
        parent.EquipmentSlotFrame.levelString:Show()
        parent.EquipmentSlotFrame.maxLevelString:Show()
    end

    local numBonuses = tonumber(itemPayloadSplit[13])
    if numBonuses ~= nil and numBonuses > 0 then
        for i = 14, 13 + numBonuses do
            local bonusId = tonumber(itemPayloadSplit[i])
            if bonusId ~= nil then
                local maxLevelUpgrade = GetMaxUpgradeLevel(bonusId)
                if maxLevelUpgrade ~= nil then
                    maxLevel = maxLevelUpgrade
                end
            end
        end
    end
    
    if maxLevel == nil then
        parent.EquipmentSlotFrame.levelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 0, 0)
        parent.EquipmentSlotFrame.maxLevelString:Hide()
    else
        parent.EquipmentSlotFrame.maxLevelString:SetText(tostring(maxLevel))
        if itemLevel ~= maxLevel then
            parent.EquipmentSlotFrame.levelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 0, 4)
            parent.EquipmentSlotFrame.maxLevelString:Show()
        else
            parent.EquipmentSlotFrame.levelString:SetPoint("CENTER", parent.EquipmentSlotFrame, "CENTER", 0, 0)
            parent.EquipmentSlotFrame.maxLevelString:Hide()
        end
    end
    
    if itemLevel ~= nil then
        if itemLevel == maxLevel or itemLevel >= maxUpgaradeLevel then
            local itemRarityRed = tonumber("0x"..itemRarityColorHex:sub(1,2))/255
            local itemRarityGreen = tonumber("0x"..itemRarityColorHex:sub(3,4))/255
            local itemRarityBlue = tonumber("0x"..itemRarityColorHex:sub(5,6))/255
            parent.EquipmentSlotFrame.levelString:SetTextColor(itemRarityRed, itemRarityGreen, itemRarityBlue, 1)
        end
    end
end

local function GetItemInfoData(unitId, slotId, itemSockets)
    if not settingsDB.enableCharacterEnchantsInfo and not settingsDB.enableCharacterGemsInfo then return end
    local itemEnchant = nil
    local itemEnchantAtlas = ""
    local itemSocketCount = 0

    local enchantPattern = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.*)")
    local enchantAtlasPattern = "(.*)|A:(.*):20:20|a"

    local tooltipData = C_TooltipInfo.GetInventoryItem(unitId, slotId)
    if tooltipData ~= nil then
        for i, line in pairs(tooltipData.lines) do 
            local text = line.leftText
            local enchantString = string.match(text, enchantPattern)
            if enchantString ~= nil then
                if string.find(enchantString, "|A:") then
                    itemEnchant, itemEnchantAtlas = string.match(enchantString, enchantAtlasPattern)
                else
                    itemEnchant = enchantString
                    itemEnchantAtlas = nil
                end
            end
            
            if line.gemIcon then
                itemSocketCount = itemSocketCount + 1
                itemSockets[itemSocketCount] = line.gemIcon
            elseif line.socketType then
                itemSocketCount = itemSocketCount + 1
                itemSockets[itemSocketCount] = "character-emptysocket"
            end
        end
    end

    return itemEnchant, itemEnchantAtlas, itemSocketCount
end

local function SetupItemEnchant(parent, slot, itemEnchant, itemEnchantAtlas, itemEquipLoc)
    if not settingsDB.enableCharacterEnchantsInfo then
        parent.EquipmentSlotFrame.enchantString:Hide()
        return
    end

    if itemEnchant == nil then
        if slot.canEnchant == true then
            itemEnchant = "No enchant"
            parent.EquipmentSlotFrame.enchantString:SetText(itemEnchant)
            parent.EquipmentSlotFrame.enchantString:SetTextColor(1, 0, 0, 1)
            if (itemEquipLoc ~= "INVTYPE_HOLDABLE" and itemEquipLoc ~= "INVTYPE_SHIELD") then
                parent.EquipmentSlotFrame.enchantString:Show()
            else
                parent.EquipmentSlotFrame.enchantString:Hide()
            end
        else
            parent.EquipmentSlotFrame.enchantString:Hide()
        end
    else
        if slot.id == 16 or slot.id == 17 then
            itemEnchant = itemEnchant:gsub("Authority", "")
            itemEnchant = itemEnchant:gsub("the", "")
            itemEnchant = itemEnchant:gsub("of", "")
            itemEnchant = itemEnchant:gsub("Rune", "")
            itemEnchant = itemEnchant:gsub("^%s+", ""):gsub("%s+$", "")
            itemEnchant = itemEnchant:gsub("% ", "\n",1)
        elseif slot.id == 7 then
            itemEnchant = itemEnchant:gsub(" & ", "\n       ")
        end
        itemEnchant = itemEnchant:gsub("^%s+", ""):gsub("%s+$", "")

        parent.EquipmentSlotFrame.enchantString:SetTextColor(0, 1, 0, 1)
        if slot.side == "RIGHT" then
            parent.EquipmentSlotFrame.enchantString:SetText((RetailEnchants[itemEnchant..(itemEnchantAtlas or "")] or itemEnchant) .. " " ..
                                                            ((itemEnchantAtlas and ("|A:"..itemEnchantAtlas..":15:15|a")) or
                                                             (DKEnchants[itemEnchant] and ("|T"..DKEnchants[itemEnchant]..":15:15|t")) or ""))
        else
            parent.EquipmentSlotFrame.enchantString:SetText(((itemEnchantAtlas and ("|A:"..itemEnchantAtlas..":15:15|a")) or
                                                             (DKEnchants[itemEnchant] and ("|T"..DKEnchants[itemEnchant]..":15:15|t")) or "") ..
                                                            (RetailEnchants[itemEnchant..(itemEnchantAtlas or "")] or itemEnchant))
        end
        parent.EquipmentSlotFrame.enchantString:Show()
    end
end

local function SetupItemGems(parent, itemLink, itemSockets, itemSocketCount)
    if not settingsDB.enableCharacterGemsInfo then
        parent.EquipmentSlotFrame.socketFrame[1]:Hide()
        parent.EquipmentSlotFrame.socketFrame[2]:Hide()
        parent.EquipmentSlotFrame.socketFrame[3]:Hide()
        return
    end
    for i = 1, 3 do
        local _, gemLink = C_Item.GetItemGem(itemLink, i)
        local socketFrame = parent.EquipmentSlotFrame.socketFrame[i]
        local point, relativeTo, relativePoint, offset_x, offset_y = socketFrame:GetPoint()

        if i==1 and itemSockets[2]==nil then
            parent.EquipmentSlotFrame.socketFrame[1]:SetPoint(point, relativeTo, relativePoint, offset_x, 0)
        elseif i==2 and itemSockets[2] ~=nil and itemSockets[3]==nil then
            parent.EquipmentSlotFrame.socketFrame[1]:SetPoint(point, relativeTo, relativePoint, offset_x, defaultGemSize/2)
            parent.EquipmentSlotFrame.socketFrame[2]:SetPoint(point, relativeTo, relativePoint, offset_x, -defaultGemSize/2)
        elseif i==3 and itemSockets[3]~=nil then
            parent.EquipmentSlotFrame.socketFrame[1]:SetPoint(point, relativeTo, relativePoint, offset_x, defaultGemSize)
            parent.EquipmentSlotFrame.socketFrame[2]:SetPoint(point, relativeTo, relativePoint, offset_x, 0)
        end
        
        if gemLink == nil then
            if i <= itemSocketCount then
                if itemSockets[i] ~= nil then
                    socketFrame:SetNormalAtlas(itemSockets[i])
                    socketFrame:Show()
                    socketFrame.gem:Hide()
                else
                    socketFrame:Hide()
                end
            else
                socketFrame:Hide()
            end
            socketFrame:SetScript("OnEnter", function()
                return
            end)
        else
            socketFrame:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(socketFrame, "ANCHOR_CURSOR")
                    GameTooltip:SetHyperlink(gemLink)
                    GameTooltip:Show()
            end)
            socketFrame:SetScript("OnLeave", function()
                    GameTooltip:Hide()
            end)
            if itemSockets[i] ~= nil then
                socketFrame:SetNormalAtlas("character-emptysocket")
                socketFrame:Show()
                socketFrame.gem:SetTexture(itemSockets[i])
                socketFrame.gem:SetDrawLayer("Overlay", 0)
                socketFrame.gem:SetTexCoord(.08, .92, .08, .92)
                socketFrame.gem:Show()
            else
                socketFrame:Hide()
                socketFrame.gem:Hide()
            end
        end
    end
end

function UpdateEquipmentSlot(unitId, slotId)
    if not settingsDB.characterInfoFlag or 
       unitId == nil or UnitGUID(unitId) == nil or slotId == nil or
       characterSlots[slotId] == nil or slotId == 19 then
		return
	end

    local slot = characterSlots[slotId]
    local parent = CreateSlotFrame(unitId, slot)
    if parent == nil or parent.EquipmentSlotFrame == nil then
        return
    end
    
    local itemLink = GetInventoryItemLink(unitId, slotId)
    if itemLink == nil or itemLink == "" then
        parent.EquipmentSlotFrame:Hide()
        return
        
    end
    
    local itemPayload = string.match(itemLink, "item:([%-?%d:]+)")
    if itemPayload == nil then
        parent.EquipmentSlotFrame:Hide()
        return
    end
    
    local itemEnchant = nil
    local itemEnchantAtlas = nil
    local itemSocketCount = 0
    local itemSockets = {}
    
    local itemPayloadSplit = {strsplit(":", itemPayload)}
    local itemEquipLoc =select(9,C_Item.GetItemInfo(itemLink))
    local itemLevel = select(1,C_Item.GetDetailedItemLevelInfo(itemLink))

    SetupItemLevel(parent, itemLevel, itemPayloadSplit, string.sub(itemLink, 5, 10):gsub("#",""))
    itemEnchant, itemEnchantAtlas, itemSocketCount = GetItemInfoData(unitId, slotId, itemSockets)
    SetupItemEnchant(parent, slot, itemEnchant, itemEnchantAtlas, itemEquipLoc)
    SetupItemGems(parent, itemLink, itemSockets, itemSocketCount)
    
    parent.EquipmentSlotFrame:Show()
    
    local _, _, _, weaponType = C_Item.GetItemInfoInstant(itemLink)
    if(slotId == 16 and TwoHanders[weaponType] and GetInspectSpecialization(unitId) ~= 72) then
        weaponLevel = itemLevel
    end
    return itemLevel
end

function UpdateAllEquipmentSlots(unitId)
    if not settingsDB.characterInfoFlag then
		return
	end
    sumILVL = 0
    weaponLevel = 0
    for slotId in pairs(characterSlots) do
        sumILVL = sumILVL + (UpdateEquipmentSlot(unitId, slotId) or 0)
    end
    UpdateAverageItemLevel(unitId, 19)
end

-- Add this at the end of the file - simple bag item level display based on SimpleItemLevel approach
settingsDB.characterInfoFlag = true -- Enable character info functionality

local function SimpleItemLevelDisplay()
    local frame = CreateFrame("Frame")
    local fontSize = 12
    
    local function CreateOrUpdateItemLevel(button, bagID, slotID)
        if not button then return end
        
        -- Create our fontstring if it doesn't exist yet
        if not button.levelString then
            button.levelString = button:CreateFontString(nil, "OVERLAY")
            button.levelString:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
            button.levelString:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        
        -- Get item link
        local itemLink = C_Container.GetContainerItemLink(bagID, slotID)
        if not itemLink then
            button.levelString:SetText("")
            if button.upgradeArrow then button.upgradeArrow:Hide() end
            return
        end
        
        -- Get item level and type
        local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink) 
        if not itemLevel then
            button.levelString:SetText("")
            if button.upgradeArrow then button.upgradeArrow:Hide() end
            return
        end
        
        local _, _, quality, _, _, itemType, itemSubType, _, itemEquipLoc = C_Item.GetItemInfo(itemLink)
        
        -- Only show for specific equipment types as requested: weapons, armor, trinket, ring, back, and neck
        local shouldShow = false
        
        if itemType == "Weapon" then
            shouldShow = true
        elseif itemType == "Armor" then
            -- For armor, only show specific slots (trinket, ring, back, neck)
            if itemEquipLoc == "INVTYPE_NECK" or       -- Neck
               itemEquipLoc == "INVTYPE_FINGER" or     -- Ring
               itemEquipLoc == "INVTYPE_TRINKET" or    -- Trinket
               itemEquipLoc == "INVTYPE_CLOAK" then    -- Back
                shouldShow = true
            -- Also show for main armor pieces (head, chest, legs, etc.)
            elseif itemSubType ~= "Junk" and itemSubType ~= "Miscellaneous" then
                shouldShow = true
            end
        end
        
        if not shouldShow then
            button.levelString:SetText("")
            if button.upgradeArrow then button.upgradeArrow:Hide() end
            return
        end
        
        -- Set text with color based on quality
        local r, g, b = C_Item.GetItemQualityColor(quality or 1)
        button.levelString:SetTextColor(r, g, b)
        button.levelString:SetText(itemLevel)
        
        -- Kontrol edilecek yukarı ok - Lazy initialization
        if not button.upgradeArrow then
            button.upgradeArrow = button:CreateTexture(nil, "OVERLAY")
            button.upgradeArrow:SetSize(20, 20)
            button.upgradeArrow:SetPoint("TOPLEFT", 0, 0)
            
            -- Texture ayarları
            local customTexturePath = "Interface\\AddOns\\oUF_Fail\\media\\UpgradeArrow"
            local defaultTexturePath = "Interface\\Buttons\\Arrow-Up-Up"
            
            button.upgradeArrow:SetTexture(customTexturePath)
            if not button.upgradeArrow:GetTexture() then
                button.upgradeArrow:SetTexture(defaultTexturePath)
            end
                      
            button.upgradeArrow:SetDrawLayer("OVERLAY", 7)
        end
        
        -- Yükseltme kontrolü - sadece item level yüksekse göster
        local isUpgrade = false
        
        -- İtemin ekipman slotunu tespit et
        local slotToCheck = nil
        if itemEquipLoc then
            -- 2 yuvalı slot tiplerini özel işle (yüzük, trinket)
            if itemEquipLoc == "INVTYPE_FINGER" then
                -- İki yüzük arasında düşük seviyeli olanı bul
                local finger1Link = GetInventoryItemLink("player", 11)
                local finger2Link = GetInventoryItemLink("player", 12)
                local finger1Level = finger1Link and C_Item.GetDetailedItemLevelInfo(finger1Link) or 0
                local finger2Level = finger2Link and C_Item.GetDetailedItemLevelInfo(finger2Link) or 0
                
                slotToCheck = (finger1Level <= finger2Level) and 11 or 12
            elseif itemEquipLoc == "INVTYPE_TRINKET" then
                -- İki trinket arasında düşük seviyeli olanı bul
                local trinket1Link = GetInventoryItemLink("player", 13)
                local trinket2Link = GetInventoryItemLink("player", 14)
                local trinket1Level = trinket1Link and C_Item.GetDetailedItemLevelInfo(trinket1Link) or 0
                local trinket2Level = trinket2Link and C_Item.GetDetailedItemLevelInfo(trinket2Link) or 0
                
                slotToCheck = (trinket1Level <= trinket2Level) and 13 or 14
            else
                -- Diğer tip slotları ilgili tabloda ara
                local equipSlotMap = {
                    ["INVTYPE_HEAD"] = 1,
                    ["INVTYPE_NECK"] = 2,
                    ["INVTYPE_SHOULDER"] = 3,
                    ["INVTYPE_CHEST"] = 5, ["INVTYPE_ROBE"] = 5,
                    ["INVTYPE_WAIST"] = 6,
                    ["INVTYPE_LEGS"] = 7,
                    ["INVTYPE_FEET"] = 8,
                    ["INVTYPE_WRIST"] = 9,
                    ["INVTYPE_HAND"] = 10,
                    ["INVTYPE_CLOAK"] = 15,
                    ["INVTYPE_WEAPON"] = 16, ["INVTYPE_2HWEAPON"] = 16, 
                    ["INVTYPE_RANGED"] = 16, ["INVTYPE_RANGEDRIGHT"] = 16,
                    ["INVTYPE_WEAPONOFFHAND"] = 17, ["INVTYPE_SHIELD"] = 17, 
                    ["INVTYPE_HOLDABLE"] = 17
                }
                slotToCheck = equipSlotMap[itemEquipLoc]
            end
            
            -- Mevcut giyilen item kontrolü
            if slotToCheck then
                local equippedLink = GetInventoryItemLink("player", slotToCheck)
                local equippedLevel = equippedLink and C_Item.GetDetailedItemLevelInfo(equippedLink) or 0
                
                -- En az 3+ ilvl fark olsun
                if itemLevel > equippedLevel + 3 then
                    isUpgrade = true
                end
            end
        end
        
        -- Yükseltme durumuna göre oku göster/gizle
        if isUpgrade then
            button.upgradeArrow:Show()
        else
            button.upgradeArrow:Hide()
        end
    end
    
    local function UpdateBagItemLevels()
        -- Tüm konteyner tiplerini işle (normal çantalar ve birleşik çanta)
        local function ProcessContainer(container)
            if not container or not container:IsShown() then return end
            
            local bagID = container:GetID()
            local numSlots = C_Container.GetContainerNumSlots(bagID)
            
            for slotID = 1, numSlots do
                local buttonName = container:GetName().."Item"..slotID
                local button = _G[buttonName]
                if button then
                    CreateOrUpdateItemLevel(button, bagID, slotID)
                end
            end
        end
        
        -- Açık olan tüm normal çantaları işle
        for frameIndex = 1, NUM_CONTAINER_FRAMES do
            local container = _G["ContainerFrame"..frameIndex]
            ProcessContainer(container)
        end
        
        -- Birleşik çantayı işle (Dragonflight)
        if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() and ContainerFrameCombinedBags.Items then
            for i = 1, #ContainerFrameCombinedBags.Items do
                local button = ContainerFrameCombinedBags.Items[i]
                if button and button.bagID then
                    CreateOrUpdateItemLevel(button, button.bagID, button:GetID())
                end
            end
        end
    end
    
    -- Sadece bir adet timer kullan - 0.1 saniye sonra çağrılacak
    local updateTimer = nil
    local function ScheduleUpdate()
        if updateTimer then return end
        
        updateTimer = C_Timer.After(0.1, function()
            UpdateBagItemLevels()
            updateTimer = nil
        end)
    end
    
    -- Register for events
    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    
    -- Update on event
    frame:SetScript("OnEvent", ScheduleUpdate)
    
    -- Çanta açılışlarında güncelleme yap
    if _G.OpenBag then
        hooksecurefunc("OpenBag", ScheduleUpdate)
    end
    
    if _G.ToggleAllBags then
        hooksecurefunc("ToggleAllBags", ScheduleUpdate)
    end
    
    -- İlk yükleme
    C_Timer.After(1, UpdateBagItemLevels)
   
end

SimpleItemLevelDisplay()



