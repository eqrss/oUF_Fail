local addon, ns = ...
local oUF = ns.oUF or oUF
local cfg = ns.cfg
local cast = ns.cast
local lib = CreateFrame("Frame")
local _, playerClass = UnitClass("player")



-- Set power colors
oUF.colors.power['RAGE'] = {1.0, 0, 0}
oUF.colors.power['FOCUS'] = {1.0, 0.75, 0.25}
oUF.colors.power['ENERGY'] = {0.65, 0.65, 0.35}
oUF.colors.power['RUNIC_POWER'] = {0.44, 0.44, 0.44}
oUF.colors.power['AMMOSLOT'] = {0.8, 0.6, 0}
oUF.colors.power['FUEL'] = {0, 0.55, 0.5}
oUF.colors.power['POWER_TYPE_STEAM'] = {0.55, 0.57, 0.61}
oUF.colors.power['POWER_TYPE_PYRITE'] = {0.6, 0.09, 0.17}
oUF.colors.power['POWER_TYPE_HEAT'] = {0.9, 0.45, 0.1}
oUF.colors.power['POWER_TYPE_OOZE'] = {0.1, 0.1, 0.9}
oUF.colors.power['POWER_TYPE_BLOOD_POWER'] = {0.9, 0.1, 0.1}

-- Set MANA color based on class
if playerClass ~= "WARRIOR" then
    oUF.colors.power['MANA'] = oUF.colors.class[playerClass] or {0.0, 0.56, 1.0} -- Default to blue if class color is not found
else
    oUF.colors.power['MANA'] = {0.0, 0.56, 1.0} -- Keep the original color for Warriors
end

local _, pType = UnitPowerType("player")
local pcolor = oUF.colors.power[pType] or {.3, .45, .65}
oUF.colors.runes = {{196 / 255, 30 / 255, 58 / 255}; {173 / 255, 217 / 255, 25 / 255}; {35 / 255, 127 / 255, 255 / 255}; {178 / 255, 53 / 255, 240 / 255}; }

-- GetRageColor function for dynamic rage color
local function GetRageColor(value, maxValue)
    local percentage = value / maxValue
    local baseColor = {0.69, 0.31, 0.31} -- Dark red for low rage
    local highColor = {1.0, 0.15, 0.15} -- Bright red for high rage
    
    -- Add pulsing effect when rage is high
    if percentage > 0.8 then
        local pulseIntensity = math.sin(GetTime() * 3) * 0.1 -- 10% brightness fluctuation
        highColor[1] = math.min(1.0, highColor[1] + pulseIntensity)
        highColor[2] = math.min(1.0, highColor[2] + pulseIntensity)
        highColor[3] = math.min(1.0, highColor[3] + pulseIntensity)
    end
    
    -- Interpolate between base and high color based on rage percentage
    local r = baseColor[1] + (highColor[1] - baseColor[1]) * percentage
    local g = baseColor[2] + (highColor[2] - baseColor[2]) * percentage
    local b = baseColor[3] + (highColor[3] - baseColor[3]) * percentage
    
    return r, g, b
end

-- FUNCTIONS
local retVal = function(f, val1, val2, val3)
    if f.mystyle == "player" or f.mystyle == "target" then
        return val1
    elseif f.mystyle == "raid" or f.mystyle == "party" then
        return val3
    else
        return val2
    end
end

local fixTex = function(tex)
    local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = tex:GetTexCoord()
    tex:SetTexCoord(ULy, ULx, LLy, LLx, URy, URx, LRy, LRx)
end

function lib.createBackdrop(f, size)
	f:SetBackdrop({
		bgFile = cfg.backdrop_texture,
		edgeFile = cfg.backdrop_edge_texture,
		tile = false,
		tileSize = 0,
		edgeSize = 5,
		insets = {
			left = 3,
			right = 3,
			top = 3,
			bottom = 3,
		}
	})
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0, 0, 0, 0.8)
end

-- Right Click Menu
lib.spawnMenu = function(self)
    local unit = self.unit:sub(1, -2)
    local cunit = self.unit:gsub("^%l", string.upper)
    
    if (cunit == "Vehicle") then
        cunit = "Pet"
    end
    
    if (unit == "party") then
        ToggleDropDownMenu(1, nil, _G["PartyMemberFrame" .. self.id .. "DropDown"], "cursor", 0, 0)
    elseif (_G[cunit .. "FrameDropDown"]) then
        ToggleDropDownMenu(1, nil, _G[cunit .. "FrameDropDown"], "cursor", 0, 0)
    elseif unit == "raid" then
        ToggleDropDownMenu(1, nil, _G["RaidFrameDropDown"], "cursor", 0, 0)
    end
end

--fontstring func
lib.gen_fontstring = function(f, name, size, outline)
    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetFont(name, size, outline)
    fs:SetShadowColor(0, 0, 0, 0.8)
    fs:SetShadowOffset(1, -1)
    return fs
end

--gen healthbar func
lib.gen_hpbar = function(f)
        --statusbar
        local s = CreateFrame("StatusBar", nil, f,BackdropTemplateMixin and "BackdropTemplate")
        s:SetStatusBarTexture(cfg.statusbar_texture)
        s:GetStatusBarTexture():SetHorizTile(true)
        s:SetHeight(retVal(f, 30, 24, 20))
        s:SetWidth(f:GetWidth())
        s:SetPoint("BOTTOM", 0, 0)
        s:SetFrameLevel(3)
        --helper
        local h = CreateFrame("Frame", nil, s,BackdropTemplateMixin and "BackdropTemplate")
        h:SetFrameLevel(2)
        h:SetPoint("TOPLEFT", -5, 5)
        h:SetPoint("BOTTOMRIGHT", 5, -5)
        lib.createBackdrop(h)
        --bg
        local b = s:CreateTexture(nil, "BACKGROUND")
        b:SetTexture(cfg.statusbar_texture)
        b:SetAllPoints(s)
        b:SetVertexColor(1, 0.1, 0.1, 0.8)
        f.Health = s
        f.Health.bg2 = b
end

--gen hp strings func
lib.gen_hpstrings = function(f, unit)
        --creating helper frame here so our font strings don't inherit healthbar parameters
        local h = CreateFrame("Frame", nil, f)
        h:SetAllPoints(f.Health)
        h:SetFrameLevel(15)
        local fontsize
        if f.mystyle == "player" then fontsize = cfg.healthbarfontsize
        elseif f.mystyle == "target" then fontsize = 17
        elseif f.mystyle == "raid" or f.mystyle == "party" then fontsize = 10
        else fontsize = 16
        end
        
        local name = lib.gen_fontstring(f.Health, cfg.font, fontsize, "THINOUTLINE")
        if f.mystyle == "player" then
            name:SetPoint("RIGHT", f.Health, "RIGHT", 0, 0)
            name:SetJustifyH("RIGHT")
        elseif f.mystyle == "raid" or f.mystyle == "party" then
            name:SetPoint("LEFT", f.Health, "LEFT", 0, 4)
            name:SetJustifyH("LEFT")
        else
            name:SetPoint("LEFT", f.Health, "TOPLEFT", 6, -1)
            name:SetJustifyH("LEFT")
        end
        
        local hpval = lib.gen_fontstring(f.Health, cfg.font, fontsize, "THINOUTLINE")
        if f.mystyle == "player" then
            hpval:SetPoint("RIGHT", f.Health, "RIGHT", 2, -6)
            hpval:SetJustifyH("RIGHT")
        elseif f.mystyle == "raid" or f.mystyle == "party" then
            hpval:SetPoint("RIGHT", f.Health, "RIGHT", 5, -6)
            hpval:SetJustifyH("RIGHT")
        elseif f.mystyle == "focus" or f.mystyle == "focustarget" then
            hpval:SetPoint("RIGHT", f.Health, "RIGHT", 2, -6)
            hpval:SetJustifyH("LEFT")
        else
            hpval:SetPoint("RIGHT", f.Health, "TOPRIGHT", retVal(f, 2, 2, -3), retVal(f, -25, -15, -17))
        end
        
        if f.mystyle == "player" then
            name:SetPoint("RIGHT", f, "RIGHT", 10, 6)
            
        elseif f.mystyle == "raid" or f.mystyle == "party" then
            name:SetPoint("CENTER", f, "CENTER", 0, 6)
        elseif f.mystyle == "target" or f.mystyle == "pet" then
            name:SetPoint("RIGHT", f, "RIGHT", 0, -12)
        else
            name:SetPoint("RIGHT", f, "RIGHT", 0, 0)
        end
        
        if f.mystyle == "player" then
            f:Tag(name, "[fail:afkdnd]")
        elseif f.mystyle == "target" or f.mystyle == "party" then
            f:Tag(name, "[fail:level] [fail:color][name][fail:afkdnd]")
        elseif f.mystyle == "raid" then
            f:Tag(name, "[fail:color][name][fail:afkdnd]")
        else
            f:Tag(name, "[fail:color][name]")
        end
        if f.mystyle == "player" then
            f:Tag(hpval, "[fail:color][curhp]")
        
        else
            
            f:Tag(hpval, retVal(f, "[fail:color][fail:hp]", "[fail:color][fail:raidhp]", "[fail:color][fail:raidhp]"))
        end
        
        local level = lib.gen_fontstring(f.Health, cfg.font, 18, "THINOUTLINE")
        level:SetPoint("LEFT", f.Health, "TOPLEFT", 6, -1)
        level:SetJustifyH("LEFT")
        if f.mystyle == "player" and cfg.ShowPlayerName then
            f:Tag(level, "[fail:level] [fail:color][name]")
        else
            end
end

--gen powerbar func
lib.gen_ppbar = function(f)
        --statusbar
        local s = CreateFrame("StatusBar", nil, f,BackdropTemplateMixin and "BackdropTemplate")
        s:SetStatusBarTexture(cfg.powerbar_texture)
        s:GetStatusBarTexture():SetHorizTile(true)
        if f.mystyle == "player" or f.mystyle == "pet" then
            s:SetHeight(20)
            s:SetWidth(f:GetWidth())
            s:SetPoint("TOP", f, "TOP", 8, 0)
        else
            s:SetHeight(retVal(f, 16, 14, 10))
            s:SetWidth(f:GetWidth())
            s:SetPoint("TOP", f, "TOP", 5, 0)
        end
        s:SetFrameLevel(1)
        
        -- Add dynamic color update for warrior rage
        if f.mystyle == "player" and playerClass == "WARRIOR" then
            s:HookScript("OnValueChanged", function(self, value)
                local powerType = UnitPowerType("player")
                if powerType == 1 then -- Check if it's rage
                    local maxPower = UnitPowerMax("player")
                    local r, g, b = GetRageColor(value, maxPower)
                    self:SetStatusBarColor(r, g, b)
                    -- Update background color with reduced intensity
                    if self.bg then
                        self.bg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3)
                    end
                end
            end)
        end
        
        --helper
        local h = CreateFrame("Frame", nil, s,BackdropTemplateMixin and "BackdropTemplate")
        h:SetFrameLevel(0)
        h:SetPoint("TOPLEFT", -5, 5)
        h:SetPoint("BOTTOMRIGHT", 5, -5)
        lib.createBackdrop(h)
        --bg
        local b = s:CreateTexture(nil, "BACKGROUND")
        b:SetTexture(cfg.powerbar_texture)
        b:SetAllPoints(s)
        --arrow
        if f.mystyle ~= "tot" and f.mystyle ~= "raid" and f.mystyle ~= "pet" then
            s.arrow = s:CreateTexture(nil, "OVERLAY")
            s.arrow:SetTexture([[Interface\Addons\oUF_Fail\media\textureArrow]])
            s.arrow:SetSize(16, 16)
            s.arrow:SetPoint("BOTTOM", s:GetStatusBarTexture(), "RIGHT", 0, retVal(f, 9, 9, 6))
            fixTex(s.arrow)
            
            if f.mystyle == "player" or f.mystyle == "target" then
                --== smooth power text for player==--
                local text = lib.gen_fontstring(f.Health, cfg.font, 20, "OUTLINE")
                text:SetPoint("RIGHT", s.arrow, "LEFT", 6, -8)
                
                -- Store text for click handler reference
                s.powerText = text
                
                -- Enerji değeri değiştiğinde çağrılacak fonksiyon
                local function UpdatePowerTextFormat(powerBar, value)
                    -- Eğer birim yoksa işlemi atla
                    if not f.unit then return end
                    
                    local color
                    local arrowDefaultColor = {0.55, 0, 0}  -- Dark Red
                    
                    if UnitIsPlayer(f.unit) then
                        -- Oyuncu için CLASS rengini kullan (powerType değil)
                        local _, class = UnitClass(f.unit)
                        if class == "WARRIOR" then
                            -- Warrior için default rengi kullan
                            color = arrowDefaultColor
                        else
                            color = class and oUF.colors.class[class] or {0.5, 0.5, 0.5}
                        end
                    else
                        -- NPC için reaction rengini kullan
                        local reaction = UnitReaction(f.unit, "player")
                        color = reaction and oUF.colors.reaction[reaction] or {1, 1, 0}
                    end
                    
                    -- Renk formatlaması
                    if value >= 1e3 then
                        text:SetFormattedText("|cff%02x%02x%02x%.1fk", color[1] * 255, color[2] * 255, color[3] * 255, value / 1e3)
                    else
                        text:SetFormattedText("|cff%02x%02x%02x%d", color[1] * 255, color[2] * 255, color[3] * 255, value)
                    end
                end
                
                -- Değer değiştiğinde formatlama yap
                s:HookScript("OnValueChanged", UpdatePowerTextFormat)
                
                -- Frame gösterildiğinde de renk güncelle
                f:HookScript("OnShow", function()
                    if f.unit then
                        local value = UnitPower(f.unit) or 0
                        UpdatePowerTextFormat(s, value)
                    end
                end)
                
                -- Tıklamalar için sadece ok rengini değiştir
                f:SetScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" and self.unit then
                        -- Ok rengini güncelle 
                        lib.UpdateArrowColor(self.unit, self.Power.arrow)
                        -- Metni de güncelle
                        local value = UnitPower(self.unit) or 0
                        UpdatePowerTextFormat(self.Power, value)
                    end
                end)
            else
                --==regular power text for everyone else==--
                local powertext = lib.gen_fontstring(f.Health, cfg.font, 18, "OUTLINE")
                powertext:SetPoint("RIGHT", s.arrow, "LEFT", 6, -8)
                --powertext:SetJustifyH("RIGHT")
                f:Tag(powertext, "[fail:pp]")
                
                -- Store text for tag reference
                s.powerText = powertext
                
                -- Birim değiştiğinde tag'i güncellemek için
                f:HookScript("OnShow", function(self)
                    if self.unit then
                        self:UpdateTags()
                    end
                end)
                
                -- Tıklama ile renk değiştirme. Tag sistemini kullanıyoruz
                -- bu nedenle sadece ok rengini değiştiriyoruz
                f:SetScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" and self.unit then
                        -- Ok rengini güncelle
                        lib.UpdateArrowColor(self.unit, self.Power.arrow)
                        -- Tag'i güncelle
                        self:UpdateTags()
                    end
                end)
            end
            
            --==No arrows for raid and boss==--
            if f.mystyle ~= "raid" and f.mystyle ~= "boss" then
                f:Tag(powa, "[fail:pp]")
            end
            
            if cfg.ShowExtraUnitArrows == "true" then
                s.arrow:Show()
            else
                s.arrow:Hide()
            end
        end
        
        f.Power = s
        f.Power.bg = b
end

-- Ok simgesinin rengini güncelleme fonksiyonu
-- Update the arrow color update function
    lib.UpdateArrowColor = function(unit, arrowTexture)
        if not unit or not arrowTexture then return end
        
        local color
        local arrowDefaultColor = {0.55, 0, 0}  -- Dark Red
        
        if UnitIsPlayer(unit) then
            -- For players, use class color
            local _, class = UnitClass(unit)
            if class == "WARRIOR" then
                -- Use default color for Warriors
                color = arrowDefaultColor
            else
                color = class and oUF.colors.class[class] or arrowDefaultColor
            end
        else
            -- For NPCs, use reaction color
            local reaction = UnitReaction(unit, "player")
            color = reaction and oUF.colors.reaction[reaction] or {1, 1, 0}
        end
        
        arrowTexture:SetVertexColor(color[1], color[2], color[3])
        arrowTexture:Show()
    end

-- Power Bar Arrow Function
-- Special thanks to Zork and Rainrider for the initial implementation
-- And special thanks to MiRai, Phanx and Caleb for helping improve on it
local arrow = {[[Interface\Addons\oUF_Fail\media\textureArrow]]}
local arrowDefaultColor = {.55, 0, 0}-- Dark Red

-- Bu fonksiyon oUF tarafından otomatik olarak çağrılacak
lib.setPowerArrowColor = function(self)
    local unit = self.__owner.unit
    if not unit then return end
    
    lib.UpdateArrowColor(unit, self.arrow)
end

lib.setClassArrowColor = function(self)
    local unit = self.__owner.unit
    local _, classType = UnitClass(unit)
    if classType and UnitIsPlayer(unit) then
        local color = oUF.colors.class[classType] or arrowDefaultColor
        self.arrow:SetVertexColor(color[1], color[2], color[3])
        self.arrow:Show()
    else
        -- NPC için reaction rengi kullan
        local reaction = UnitReaction(unit, "player")
        if reaction then
            local color = oUF.colors.reaction[reaction] 
            self.arrow:SetVertexColor(color[1], color[2], color[3])
        else
            self.arrow:SetVertexColor(arrowDefaultColor[1], arrowDefaultColor[2], arrowDefaultColor[3])
        end
        self.arrow:Show()
    end
end

--gen combat and LFD icons
lib.gen_InfoIcons = function(f)
    local h = CreateFrame("Frame", nil, f,BackdropTemplateMixin and "BackdropTemplate")
    h:SetAllPoints(f)
    h:SetFrameLevel(10)
    --combat icon
    if f.mystyle == 'player' then
        f.CombatIndicator = h:CreateTexture(nil, 'OVERLAY')
        f.CombatIndicator:SetSize(16, 16)
        f.CombatIndicator:SetPoint('LEFT', -4, -16)
        f.CombatIndicator:SetTexture([[Interface\Addons\oUF_Fail\media\combat]])
    end
    -- rest icon
    if f.mystyle == 'player' and UnitLevel("Player") < 100 then
        f.RestingIndicator = h:CreateTexture(nil, 'OVERLAY')
        f.RestingIndicator:SetSize(22, 22)
        f.RestingIndicator:SetPoint('BOTTOMLEFT', -3, -3)
        f.RestingIndicator:SetTexture([[Interface\Addons\oUF_Fail\media\resting]])
        f.RestingIndicator:SetAlpha(0.75)
    end
    --Leader icon
    li = h:CreateTexture(nil, "OVERLAY")
    li:SetPoint("BOTTOMRIGHT", f, 0, -1)
    if f.mystyle ~= "player" then
        li:SetSize(12, 12)
    else
        li:SetSize(16, 16)
    end
    f.Leader = li
    
    --Assist icon
    ai = h:CreateTexture(nil, "OVERLAY")
    ai:SetPoint("TOPRIGHT", f, 4, 1)
    ai:SetSize(16, 16)
    ai:SetAlpha(1.0)
    if f.mystyle == "raid" then
        ai:Show()
    else
        ai:Hide()
    end
    f.Assistant = ai
    --ML icon
    local ml = h:CreateTexture(nil, 'OVERLAY')
    ml:SetSize(12, 12)
    ml:SetAlpha(1.0)
    ml:SetPoint('LEFT', f.Leader, -64, 2)
    if f.mystyle == "raid" then
        ml:Show()
    else
        ml:Hide()
    end
    f.MasterLooter = ml
end

-- LFG Role Indicator
lib.gen_LFDRole = function(f)
    local lfdi = lib.gen_fontstring(f.Health, cfg.smallfont, 10, "THINOUTLINE")
    lfdi:SetPoint('BOTTOM', f.Health, 'TOP', 0, 4)
    f:Tag(lfdi, "[fail:lfdrole]")
end

-- phase icon
lib.addPhaseIcon = function(self)
    local picon = self.Health:CreateTexture(nil, 'OVERLAY')
    picon:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 40, 8)
    picon:SetSize(16, 16)
    
    self.PhaseIndicator = picon
end

-- quest icon
lib.addQuestIcon = function(self)
    local qicon = self.Health:CreateTexture(nil, 'OVERLAY')
    qicon:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 8)
    qicon:SetSize(16, 16)
    
    self.QuestIndicator = qicon
end

--gen raid mark icons
lib.gen_RaidMark = function(f)
    local h = CreateFrame("Frame", nil, f,BackdropTemplateMixin and "BackdropTemplate")
    h:SetAllPoints(f)
    h:SetFrameLevel(10)
    h:SetAlpha(0.8)
    local ri = h:CreateTexture(nil, 'OVERLAY')
    ri:SetPoint("CENTER", f.Health, "BOTTOM", -8, 18)
    ri:SetTexture([[Interface\Addons\oUF_Fail\media\raidicons.blp]])
    local size = retVal(f, 24, 14, 18)
    ri:SetSize(size, size)
    f.RaidTargetIndicator = ri
end

--gen hilight texture
lib.gen_highlight = function(f)
    local OnEnter = function(f)
        UnitFrame_OnEnter(f)
        f.Highlight:Show()
    end
    local OnLeave = function(f)
        UnitFrame_OnLeave(f)
        f.Highlight:Hide()
    end
    f:SetScript("OnEnter", OnEnter)
    f:SetScript("OnLeave", OnLeave)
    local hl = f.Health:CreateTexture(nil, "OVERLAY")
    hl:SetAllPoints(f.Health)
    hl:SetTexture(cfg.highlight_texture)
    hl:SetVertexColor(.5, .5, .5, .1)
    hl:SetBlendMode("ADD")
    hl:Hide()
    f.Highlight = hl
end

-- Create Target Border
function lib.CreateTargetBorder(self)
    local glowBorder = {edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2}
    self.TargetBorder = CreateFrame("Frame", nil, self,BackdropTemplateMixin and "BackdropTemplate")
    self.TargetBorder:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -4, 4)
    self.TargetBorder:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 5, -8)
    self.TargetBorder:SetBackdrop(glowBorder)
    self.TargetBorder:SetFrameLevel(2)
    self.TargetBorder:SetBackdropBorderColor(1.0, 1.0, 0.1, 0.6)
    self.TargetBorder:Hide()
end

-- Raid Frames Target Highlight Border
function lib.ChangedTarget(self, event, unit)

    --//if (UnitIsUnit('target', 'player')) then
    if(UnitExists(unit)) then
        self.TargetBorder:Show()
    else
        self.TargetBorder:Hide()
    end
end



-- Create Raid Threat Status Border
function lib.CreateThreatBorder(self)
    
    local glowBorder = {edgeFile = cfg.backdrop_edge_texture, edgeSize = 5}
    self.Thtborder = CreateFrame("Frame", nil, self,BackdropTemplateMixin and "BackdropTemplate")
    self.Thtborder:SetPoint("TOPLEFT", self, "TOPLEFT", -8, 9)
    self.Thtborder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 9, -8)
    self.Thtborder:SetBackdrop(glowBorder)
    self.Thtborder:SetFrameLevel(1)
    self.Thtborder:Hide()
end

-- Raid Frames Threat Highlight
function lib.UpdateThreat(self, event, unit)
    
    if (self.unit ~= unit) then return end
    
    local status = UnitThreatSituation(unit)
    unit = unit or self.unit
    
    if status and status > 1 then
        local r, g, b = GetThreatStatusColor(status)
        self.Thtborder:Show()
        self.Thtborder:SetBackdropBorderColor(r, g, b, 1.0)
    else
        self.Thtborder:SetBackdropBorderColor(0, 0, 0, 0.0)
        self.Thtborder:Hide()
    end
end


--[[ Castbar
local PostCastStart = function(castbar, unit)
    if unit ~= 'player' then
        if castbar.interrupt then
            castbar.Backdrop:SetBackdropBorderColor(1, .9, .4)
            castbar.Backdrop:SetBackdropColor(1, .9, .4)
        else
            castbar.Backdrop:SetBackdropBorderColor(0, 0, 0)
            castbar.Backdrop:SetBackdropColor(0, 0, 0)
        end
    end
end

local CustomTimeText = function(castbar, duration)
    if castbar.casting then
        castbar.Time:SetFormattedText("%.1f / %.1f", duration, castbar.max)
    elseif castbar.channeling then
        castbar.Time:SetFormattedText("%.1f / %.1f", castbar.max - duration, castbar.max)
    end
end]]

--gen castbar
lib.gen_castbar = function(f)
    if not cfg.Castbars then return end
    local cbColor = {95 / 255, 182 / 255, 255 / 255}
    local s = CreateFrame("StatusBar", "oUF_failCastbar" .. f.mystyle, f)
    s:SetHeight(16)
    --s:SetWidth(f:GetWidth() - 30)
    if f.mystyle == "focus" then
        s:SetWidth(f:GetWidth() * 2 - 14)
    elseif f.mystyle == "player" then
        s:SetWidth(f:GetWidth() - 21)
    else
        s:SetWidth(f:GetWidth() - 30)
    end
    if f.mystyle == "player" then
        s:SetPoint("BOTTOM", f, "TOP", 20, 13)
    elseif f.mystyle == "target" then
        s:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -30)
    elseif f.mystyle == "targettarget" then
        s:SetPoint("BOTTOM", f, "TOP", 0, 0)
    else
        s:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 30, -15)
    end
    s:SetStatusBarTexture(cfg.statusbar_texture)
    s:SetStatusBarColor(95 / 255, 182 / 255, 255 / 255, 1)
    s:SetFrameLevel(1)
    --color
    s.CastingColor = cbColor
    s.CompleteColor = {20 / 255, 208 / 255, 0 / 255}
    s.FailColor = {255 / 255, 12 / 255, 0 / 255}
    s.ChannelingColor = cbColor
    --helper
    local h = CreateFrame("Frame", nil, s,BackdropTemplateMixin and "BackdropTemplate")
    h:SetFrameLevel(0)
    h:SetPoint("TOPLEFT", -5, 5)
    h:SetPoint("BOTTOMRIGHT", 5, -5)
    lib.createBackdrop(h)
    --spark
    sp = s:CreateTexture(nil, "OVERLAY")
    sp:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    sp:SetBlendMode("ADD")
    sp:SetVertexColor(1, 1, 1, 1)
    sp:SetHeight(s:GetHeight() * 2.5)
    sp:SetWidth(s:GetWidth() / 18)
    --spell text
    local txt = lib.gen_fontstring(s, cfg.font, 16, "THINOUTLINE")
    txt:SetPoint("LEFT", 2, 10)
    txt:SetJustifyH("LEFT")
    --time
    local t = lib.gen_fontstring(s, cfg.font, 18, 'THINOUTLINE')
    t:SetPoint("RIGHT", -2, 0)
    txt:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    --icon
    local i = s:CreateTexture(nil, "ARTWORK")
    i:SetSize(24, 24)
    i:SetPoint("BOTTOMRIGHT", s, "BOTTOMLEFT", -6, 0)
    i:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    --helper2 for icon
    local h2 = CreateFrame("Frame", nil, s,BackdropTemplateMixin and "BackdropTemplate")
    h2:SetFrameLevel(0)
    h2:SetPoint("TOPLEFT", i, "TOPLEFT", -5, 5)
    h2:SetPoint("BOTTOMRIGHT", i, "BOTTOMRIGHT", 5, -5)
    lib.createBackdrop(h2)
    if f.mystyle == "player" then
        --latency (only for player unit)
        local z = s:CreateTexture(nil, "OVERLAY")
        z:SetTexture(cfg.statusbar_texture)
        z:SetVertexColor(1, 0.1, 0, .6)
        z:SetPoint("TOPRIGHT")
        z:SetPoint("BOTTOMRIGHT")
        s:SetFrameLevel(1)
        s.SafeZone = z
        -- custom latency display
        local l = lib.gen_fontstring(s, cfg.font, 10, "THINOUTLINE")
        l:SetPoint("CENTER", -2, 17)
        l:SetJustifyH("RIGHT")
        l:Hide()
        s.Lag = l
    --  f:RegisterEvent("UNIT_SPELLCAST_SENT", cast.OnCastSent)	--removed with 8.0
    end
    s.OnUpdate = cast.OnCastbarUpdate
    s.PostCastStart = cast.PostCastStart
    s.PostChannelStart = cast.PostCastStart
    s.PostCastStop = cast.PostCastStop
    s.PostChannelStop = cast.PostChannelStop
    s.PostCastFailed = cast.PostCastFailed
    s.PostCastInterrupted = cast.PostCastFailed
    
    f.Castbar = s
    f.Castbar.Text = txt
    f.Castbar.Time = t
    f.Castbar.Icon = i
    f.Castbar.Spark = sp
end

-- mirror castbar!
lib.gen_mirrorcb = function(f)
    for _, barName in pairs({'MirrorTimer1', 'MirrorTimer2', 'MirrorTimer3'}) do
        local bar = _G[barName]
        if bar then
            local border = _G[barName .. 'Border']
            if border then
                border:Hide()
            end
            
            bar:SetParent(UIParent)
            bar:SetScale(1)
            bar:SetHeight(16)
            bar:SetWidth(280)
            
            if bar.SetBackdropColor then
                bar:SetBackdropColor(.1, .1, .1)
            end
            
            local background = bar:CreateTexture(barName .. 'Background', 'BACKGROUND')
            background:SetTexture(cfg.statusbar_texture)
            background:SetAllPoints(bar)
            background:SetVertexColor(.15, .15, .15, .75)
            
            local text = _G[barName .. 'Text']
            if text then
                text:SetFont(cfg.font, 14)
                text:ClearAllPoints()
                text:SetPoint('CENTER', bar, 0, 1)
            end
            
            local statusBar = _G[barName .. 'StatusBar']
            if statusBar then
                statusBar:SetAllPoints(bar)
            end
            
            -- glowing borders
            local h = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            h:SetFrameLevel(0)
            h:SetPoint("TOPLEFT", -5, 5)
            h:SetPoint("BOTTOMRIGHT", 5, -5)
            if lib.createBackdrop then
                lib.createBackdrop(h)
            end
        end
    end
end

-- Post Create Icon Function
local myPostCreateIcon = function(self, button)
        
        self.showDebuffType = true
        self.showBuffType = true
        --self.showStealableBuffs = true
        self.disableCooldown = true
        button.cd.noOCC = true
        button.cd.noCooldownCount = true
        
        --		button.icon:SetTexCoord(0,1,0,1)
        button.icon:SetTexCoord(.07, .93, .07, .93)
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        button.overlay:SetTexture(cfg.debuffBorder)
        button.overlay:SetTexCoord(0, 1, 0, 1)
        button.overlay.Hide = function(self)self:SetVertexColor(0.3, 0.3, 0.3) end
        
        
        button.time = lib.gen_fontstring(button, cfg.smallfont, 20, "OUTLINE")
        button.time:SetPoint("BOTTOM", button, 2, -4)
        button.time:SetJustifyH('CENTER')
        button.time:SetVertexColor(1, 1, 1)
        
        button.count = lib.gen_fontstring(button, cfg.smallfont, 15, "OUTLINE")
        button.count:ClearAllPoints()
        button.count:SetPoint("TOPRIGHT", button, 5, 3)
        button.count:SetJustifyH('RIGHT')
        button.count:SetVertexColor(1, 1, 1)
        
        -- helper
        local h = CreateFrame("Frame", nil, button,BackdropTemplateMixin and "BackdropTemplate")
        h:SetFrameLevel(0)
        h:SetPoint("TOPLEFT", -5, 5)
        h:SetPoint("BOTTOMRIGHT", 5, -5)
        lib.createBackdrop(h)
end

-- Post Update Icon Function
local myPostUpdateIcon = function(self, unit, icon, index, offset, filter, isDebuff)
        
        local _, _, _, _, duration, expirationTime, unitCaster, _ = C_UnitAuras.GetAuraDataByIndex(unit, index, icon.filter)
        
        if duration and duration > 0 then
            icon.time:Show()
            icon.timeLeft = expirationTime
            icon:SetScript("OnUpdate", CreateBuffTimer)
        else
            icon.time:Hide()
            icon.timeLeft = math.huge
            icon:SetScript("OnUpdate", nil)
        end
        
        -- Desaturate non-Player Debuffs
        if (icon.isDebuff) then
            if (unit == "target") then
                
                if (unitCaster == 'player' or unitCaster == 'vehicle') then
                    icon.icon:SetDesaturated(false)
                elseif (not UnitPlayerControlled(unit)) then -- If Unit is Player Controlled don't desaturate debuffs
                    icon:SetBackdropColor(0, 0, 0)
                    icon.overlay:SetVertexColor(0.3, 0.3, 0.3)
                    icon.icon:SetDesaturated(true)
                end
            end
        end
        
        -- Right Click Cancel Buff/Debuff
        icon:SetScript('OnMouseUp', function(self, mouseButton)
            if mouseButton == 'RightButton' then
                CancelUnitBuff('player', index, icon.filter)
            end end)
        
        icon.first = true
end

local FormatTime = function(s)
    local day, hour, minute = 86400, 3600, 60
    if s >= day then
        return format("%dd", floor(s / day + 0.5)), s % day
    elseif s >= hour then
        return format("%dh", floor(s / hour + 0.5)), s % hour
    elseif s >= minute then
        if s <= minute * 5 then
            return format("%d:%02d", floor(s / 60), s % minute), s - floor(s)
        end
        return format("%dm", floor(s / minute + 0.5)), s % minute
    elseif s >= minute / 12 then
        return floor(s + 0.5), (s * 100 - floor(s * 100)) / 100
    end
    return format("%.1f", s), (s * 100 - floor(s * 100)) / 100
end

-- Create Buff/Debuff Timer Function
function CreateBuffTimer(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.1 then
        if not self.first then
            self.timeLeft = self.timeLeft - self.elapsed
        else
            self.timeLeft = self.timeLeft - GetTime()
            self.first = false
        end
        
        if self.timeLeft > 0 and self.timeLeft <= 60 * 15 then -- Show time between 0 and 15 min
            local time = FormatTime(self.timeLeft)
            self.time:SetText(time)
            if self.timeLeft >= 6 and self.timeLeft <= 60 * 5 then -- if Between 5 min and 6sec
                self.time:SetTextColor(0.95, 0.95, 0.95)
            elseif self.timeLeft > 3 and self.timeLeft < 6 then -- if Between 6sec and 3sec
                self.time:SetTextColor(0.95, 0.70, 0)
            elseif self.timeLeft <= 3 then -- Below 3sec
                self.time:SetTextColor(0.9, 0.05, 0.05)
            else
                self.time:SetTextColor(0.95, 0.95, 0.95)-- Fallback Color
            end
        else
            self.time:Hide()
        end
        self.elapsed = 0
    end
end

-- Generates the Buffs
lib.createBuffs = function(f)
    b = CreateFrame("Frame", nil, f)
    b.onlyShowPlayer = cfg.buffsOnlyShowPlayer
    if f.mystyle == "target" then
        b:SetPoint("TOPLEFT", f, "TOPRIGHT", 16, 0)
        b.initialAnchor = "TOPLEFT"
        b["growth-x"] = "RIGHT"
        b["growth-y"] = "DOWN"
        b.size = 28
        b.num = 10
        b.spacing = 6
        b:SetHeight((b.size + b.spacing) * 4)
        b:SetWidth(f:GetWidth())
    elseif f.mystyle == "player" then
        b:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -5)
        b.initialAnchor = "TOPRIGHT"
        b["growth-x"] = "LEFT"
        b["growth-y"] = "DOWN"
        b.size = 36
        b.num = 40
        b.spacing = 5
        b:SetHeight((b.size + b.spacing) * 4)
        b:SetWidth(f:GetWidth() * 2)
    else
        b.num = 0
    end
    b.PostCreateIcon = myPostCreateIcon
    b.PostUpdateIcon = myPostUpdateIcon
    
    f.Buffs = b
end

-- Generates the Debuffs
lib.createDebuffs = function(f)
    b = CreateFrame("Frame", nil, f)
    if f.mystyle == "tot" or f.mystyle == "focus" then
        b.onlyShowPlayer = false
        b.size = 36
        b.num = 8
    else
        b.onlyShowPlayer = cfg.showTargetDebuffs
        b.size = 38
        b.num = 8
    end
    b.spacing = 6
    b:SetHeight((b.size + b.spacing) * 5)
    b:SetWidth(f:GetWidth())
    if (playerClass == "ROGUE" or playerClass == "DRUID") then
        b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 18)
    else
        b:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 6)
    end
    b.initialAnchor = "BOTTOMLEFT"
    b["growth-x"] = "RIGHT"
    b["growth-y"] = "UP"
    b.PostCreateIcon = myPostCreateIcon
    b.PostUpdateIcon = myPostUpdateIcon
    
    f.Debuffs = b
end

-- raid post update
lib.PostUpdateRaidFrame = function(Health, unit, min, max)
        
        local disconnnected = not UnitIsConnected(unit)
        local dead = UnitIsDead(unit)
        local ghost = UnitIsGhost(unit)
        
        if disconnnected or dead or ghost then
            Health:SetValue(max)
            
            if (disconnnected) then
                Health:SetStatusBarColor(0, 0, 0, 0.6)
            elseif (ghost) then
                Health:SetStatusBarColor(1, 1, 1, 0.6)
            elseif (dead) then
                Health:SetStatusBarColor(1, 0, 0, 0.7)
            end
        else
            Health:SetValue(min)
            if (unit == 'vehicle') then
                Health:SetStatusBarColor(22 / 255, 106 / 255, 44 / 255)
            end
        end
        
        if not UnitInRange(unit) then
            Health.bg2:SetVertexColor(.6, 0.3, 0.3, 1)
        else
            Health.bg2:SetVertexColor(1, 0.1, 0.1, 1)
        end
end

-- Class specific powers
lib.gen_AltPowerBar = function(self)
        
        local AdditionalPower = CreateFrame("StatusBar", "AdditionalPowerBar", self.Power)
        AdditionalPower:SetHeight(6)
        AdditionalPower:SetWidth(self.Power:GetWidth() - 20)
        AdditionalPower:SetPoint("TOP", self.Health, "BOTTOM", 0, -1)
        AdditionalPower:SetFrameLevel(1)
        AdditionalPower:SetStatusBarTexture(cfg.statusbar_texture)
        AdditionalPower:SetStatusBarColor(.117, .55, 1)
        
        AdditionalPower.bg = AdditionalPower:CreateTexture(nil, "BORDER")
        AdditionalPower.bg:SetTexture(cfg.statusbar_texture)
        AdditionalPower.bg:SetVertexColor(.05, .15, .4)
        AdditionalPower.bg:SetPoint("TOPLEFT", AdditionalPower, "TOPLEFT", 0, 0)
        AdditionalPower.bg:SetPoint("BOTTOMRIGHT", AdditionalPower, "BOTTOMRIGHT", 0, 0)
        
        local h = CreateFrame("Frame", nil, AdditionalPower,BackdropTemplateMixin and "BackdropTemplate")
        h:SetFrameLevel(0)
        h:SetPoint("TOPLEFT", -4, 4)
        h:SetPoint("BOTTOMRIGHT", 4, -4)
        lib.createBackdrop(h)
        self.AdditionalPower = AdditionalPower
        self.AdditionalPower.bg = AdditionalPower.bg
end

-- Runebar
lib.genRunes = function(self)
    if playerClass ~= "DEATHKNIGHT" then return end
    local Runes = CreateFrame("Frame", nil, self)
    Runes:SetPoint('CENTER', self.Health, 'TOP', 2, 1)
    Runes:SetHeight(8)
    Runes:SetWidth(self.Health:GetWidth())
    
    for i = 1, 6 do
        Runes[i] = CreateFrame("StatusBar", self:GetName() .. "_Runes" .. i, self)
        Runes[i]:SetHeight(8)
        Runes[i]:SetWidth((self.Health:GetWidth() / 6) - 5)
        Runes[i]:SetStatusBarTexture(cfg.statusbar_texture)
        Runes[i]:SetFrameLevel(10)
        Runes[i]:SetStatusBarColor(70 / 255, 180 / 255, 210 / 255)
        Runes[i].bg = Runes[i]:CreateTexture(nil, "BORDER")
        Runes[i].bg:SetTexture(cfg.statusbar_texture)
        Runes[i].bg:SetPoint("TOPLEFT", Runes[i], "TOPLEFT", 0, 0)
        Runes[i].bg:SetPoint("BOTTOMRIGHT", Runes[i], "BOTTOMRIGHT", 0, 0)
        Runes[i].bg.multiplier = 0.2
        
        local h = CreateFrame("Frame", nil, Runes[i])
        h:SetFrameLevel(1)
        h:SetPoint("TOPLEFT", -5, 5)
        h:SetPoint("BOTTOMRIGHT", 5, -5)
        lib.createBackdrop(h)
        
        if (i == 1) then
            Runes[i]:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -6)
        else
            Runes[i]:SetPoint('TOPLEFT', Runes[i - 1], 'TOPRIGHT', 1, 0)
        end
    end
    
    self.Runes = Runes
end

-- Class Power
lib.gen_Classbar = function(self)
        
        local maxPower, color
        if playerClass == "MAGE" then
            maxPower = 4
            color = {0.15, 0.55, 0.8}
        elseif playerClass == "MONK" then
            maxPower = 6
            color = {0.9, 0.99, 0.9}
        elseif playerClass == "PALADIN" then
            maxPower = 5
            color = {0.9, 0.95, 0.33}
        elseif playerClass == "WARLOCK" then
            maxPower = 5
            color = {0.86, 0.22, 1}
        end
        
        if maxPower ~= nil then
            local ClassIcons = CreateFrame("Frame", nil, self)
            ClassIcons:SetPoint('CENTER', self.Health, 'TOP', 0, 1)
            ClassIcons:SetHeight(8)
            ClassIcons:SetWidth(self.Health:GetWidth())
            ClassIcons:SetFrameLevel(10)
            
            for i = 1, maxPower do
                ClassIcons[i] = CreateFrame("StatusBar", self:GetName() .. playerClass .. i, self)
                ClassIcons[i]:SetHeight(8)
                ClassIcons[i]:SetWidth((ClassIcons:GetWidth() / maxPower) - 2.5)
                ClassIcons[i]:SetStatusBarTexture(cfg.statusbar_texture)
                ClassIcons[i]:SetStatusBarColor(color[1], color[2], color[3])
                ClassIcons[i]:SetFrameLevel(11)
                
                local h = CreateFrame("Frame", nil, ClassIcons[i],BackdropTemplateMixin and "BackdropTemplate")
                h:SetFrameLevel(10)
                h:SetPoint("TOPLEFT", -5, 5)
                h:SetPoint("BOTTOMRIGHT", 5, -5)
                lib.createBackdrop(h)
                
                if (i == 1) then
                    ClassIcons[i]:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -5)
                else
                    ClassIcons[i]:SetPoint('TOPLEFT', ClassIcons[i - 1], "TOPRIGHT", 3, 0)
                end
            end
            
            self.ClassPower = ClassIcons
        end
end

-- Combo points
lib.RogueComboPoints = function(self)
    if (playerClass == "ROGUE" or playerClass == "DRUID") then
        
        local combo = CreateFrame("Frame", nil, self,BackdropTemplateMixin and "BackdropTemplate")
        combo:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -5)
        combo:SetHeight(8)
        combo:SetWidth(self:GetWidth())
        
        for i = 1, 8 do
            combo[i] = CreateFrame("StatusBar", self:GetName() .. "_CPoints" .. i, self,BackdropTemplateMixin and "BackdropTemplate")
            combo[i]:SetHeight(8)
            combo[i]:SetStatusBarTexture(cfg.statusbar_texture)
            combo[i]:SetFrameLevel(10)
            combo[i].bg = combo[i]:CreateTexture(nil, "BORDER")
            combo[i].bg:SetTexture(cfg.statusbar_texture)
            combo[i].bg:SetPoint("TOPLEFT", combo[i], "TOPLEFT", 0, 0)
            combo[i].bg:SetPoint("BOTTOMRIGHT", combo[i], "BOTTOMRIGHT", 0, 0)
            combo[i].bg.multiplier = 0.3
            
            local h = CreateFrame("Frame", nil, combo[i],BackdropTemplateMixin and "BackdropTemplate")
            h:SetFrameLevel(1)
            h:SetPoint("TOPLEFT", -5, 5)
            h:SetPoint("BOTTOMRIGHT", 5, -5)
            lib.createBackdrop(h)
            
            
            if (i == 1) then
                combo[i]:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -5)
            else
                combo[i]:SetPoint('TOPLEFT', combo[i - 1], 'TOPRIGHT', 2, 0)
            end
        end
        
        combo[1]:SetStatusBarColor(.3, .9, .3)
        combo[2]:SetStatusBarColor(.3, .9, .3)
        combo[3]:SetStatusBarColor(.3, .9, .3)
        combo[4]:SetStatusBarColor(.9, .9, 0)
        combo[5]:SetStatusBarColor(.9, .3, .3)
        combo[6]:SetStatusBarColor(.9, .3, .3)
        combo[7]:SetStatusBarColor(.9, .3, .3)
        combo[8]:SetStatusBarColor(.9, .3, .3)
        
        self.FailCPoints = combo
    end
end

-- ReadyCheck
lib.ReadyCheck = function(self)
    if cfg.RCheckIcon then
        rCheck = self.Health:CreateTexture(nil, "OVERLAY")
        rCheck:SetSize(14, 14)
        rCheck:SetPoint("BOTTOMLEFT", self.Health, "TOPRIGHT", -13, -12)
        self.ReadyCheckIndicator = rCheck
    end
end

-- raid debuffs
lib.raidDebuffs = function(f)
    if cfg.showRaidDebuffs then
        local raid_debuffs = {
            debuffs = {
                -- Any Zone
                ["Viper Sting"] = 12, -- Viper Sting
                ["Wound Poison"] = 9, -- Wound Poison
                ["Mortal Strike"] = 8, -- Mortal Strike
                ["Furious Attacks"] = 8, -- Furious Attacks
                ["Aimed Shot"] = 8, -- Aimed Shot
                ["Counterspell"] = 10, -- Counterspell
                ["Blind"] = 10, -- Blind
                ["Cyclone"] = 10, -- Cyclone
                ["Polymorph"] = 7, -- Polymorph
                ["Entangling Roots"] = 7, -- Entangling Roots
                ["Freezing Trap"] = 7, -- Freezing Trap
                ["Crippling Poison"] = 6, -- Crippling Poison
                ["Hamstring"] = 5, -- Hamstring
                ["Wing Clip"] = 5, -- Wing Clip
                ["Fear"] = 3, -- Fear
                ["Psychic Scream"] = 3, -- Psychic Scream
                ["Howl of Terror"] = 3, -- Howl of Terror
                -- Naxxramas
                ["Locust Swarm"] = 12,
                ["Necrotic Poison"] = 12,
                ["Web Wrap"] = 12,
                ["Jagged Knife"] = 12,
                ["Mutating Injection"] = 12,
                ["Detonate Mana"] = 12,
                ["Frost Blast"] = 12,
                ["Chains of Kel'Thuzad"] = 12,
                -- Ulduar
                ["Slag Pot"] = 12,
                ["Gravity Bomb"] = 12,
                ["Light Bomb"] = 12,
                ["Fusion Punch"] = 12,
                ["Static Disruption"] = 12,
                ["Stone Grip"] = 12,
                ["Crunch Armor"] = 12,
                ["Flash Freeze"] = 12,
                ["Unbalancing Strike"] = 12,
                ["Iron Roots"] = 12,
                ["Nature's Fury"] = 12,
                ["Napalm Shell"] = 12,
                ["Mark of the Faceless"] = 12,
                ["Sara's Fevor"] = 12,
                ["Squeeze"] = 12,
                ["Phase Punch"] = 12,
                -- Trial of the Crusader
                -- Beasts
              
                ["Impale"] = 12,
                ["Snobolled!"] = 12,
                ["Paralytic Toxin"] = 12,
                ["Burning Bile"] = 12,
                ["Arctic Breathe"] = 12,
                -- Jaraxxus
                ["Mistress' Kiss"] = 12,
                ["Legion Flame"] = 12,
                ["Incinerate Flesh"] = 11,
                -- Twins
                ["Touch of Darkness"] = 12,
                ["Touch of Light"] = 12,
                -- Anub
                ["Pursued by Anub'arak"] = 12,
                ["Penetrating Cold"] = 12,
                -- Icecrown Citadel
                -- Lord Marrowgar
                ["Impaled"] = 12,
                -- Gunship Battle
                ["Wounding Strike"] = 12,
                -- Saurfang
                ["Boiling Blood"] = 12,
                ["Mark of the Fallen Champion"] = 12,
                -- Festergut
                ["Gas Spore"] = 12,
                ["Vile Gas"] = 12,
                -- Rotface
                ["Mutated Infection"] = 12,
                -- Putricide
                ["Gaseous Bloat"] = 12,
                ["Volatile Ooze Adhesive"] = 12,
                -- Lana'thel
                ["Pact of the Darkfallen"] = 12,
                ["Essence of the Blood Queen"] = 10,
                -- Sindragosa
                ["Frost Beacon"] = 12,
                --		["Unchained Magic"] = 10,
                ["Instability"] = 12,
                -- Lich King
                ["Necrotic Plague"] = 12,
                ["Pain and Suffering"] = 12,
                ["Infest"] = 11,
                -- Ruby Sanctum
                ["Enervating Brand"] = 12, -- Enervating Brand
                ["Blazing Aura"] = 12, -- Blazing Aura
                ["Fiery Combustion"] = 12, -- Fiery Combustion
                ["Mark of Combustion"] = 12, -- Mark of Combustion (Fire)
                ["Soul Consumption"] = 12, -- Soul Consumption
                ["Mark Of Consumption"] = 12, -- Mark Of Consumption (Soul)
            },
        }
        
        local instDebuffs = {}
        local instances = raid_debuffs.instances
        local getzone = function()
            local zone = GetInstanceInfo()
            if instances[zone] then
                instDebuffs = instances[zone]
            else
                instDebuffs = {}
            end
        end
        
        local debuffs = raid_debuffs.debuffs
        local CustomFilter = function(icons, ...)
            local _, icon, name, _, _, _, dtype = ...
            if instDebuffs[name] then
                icon.priority = instDebuffs[name]
                return true
            elseif debuffs[name] then
                icon.priority = debuffs[name]
                return true
            else
                icon.priority = 0
            end
        end
        
        local dbsize = 18
        local debuffs = CreateFrame("Frame", nil, f)
        debuffs:SetWidth(dbsize)debuffs:SetHeight(dbsize)
        debuffs:SetPoint("TOPRIGHT", -10, 3)
        debuffs.size = dbsize
        
        debuffs.CustomFilter = CustomFilter
        f.raidDebuffs = debuffs
    end
end

-- oUF_HealPred
function lib.HealPred(self)
    if not self.Health then return end
    
    -- Create heal prediction statusbar if it doesn't exist
    if not self.HealPrediction then
        local hp = CreateFrame("StatusBar", nil, self.Health)
        hp:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        hp:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        hp:SetWidth(self.Health:GetWidth())
        hp:SetStatusBarTexture(cfg.statusbar_texture or [[Interface\TargetingFrame\UI-StatusBar]])
        hp:SetStatusBarColor(0.25, 1.0, 0.25, 0.5)
        hp:SetFrameLevel(self.Health:GetFrameLevel() + 2)
        
        self.HealPrediction = {
            myBar = hp,
            maxOverflow = 1.0
        }
    end
end

-- Addons/Plugins -------------------------------------------
-- oUF_DebuffHighlight
lib.debuffHighlight = function(self)
    if cfg.enableDebuffHighlight then
        local dbh = self.Health:CreateTexture(nil, "OVERLAY")
        dbh:SetAllPoints(self.Health)
        dbh:SetTexture(cfg.debuffhighlight_texture)
        dbh:SetBlendMode("ADD")
        dbh:SetVertexColor(0, 0, 0, 0)-- set alpha to 0 to hide the texture
        self.DebuffHighlight = dbh
        self.DebuffHighlightAlpha = 0.5
        self.DebuffHighlightFilter = true
    end
end

-- oUF_CombatFeedback
lib.gen_combat_feedback = function(f)
    if C_AddOns.IsAddOnLoaded("oUF_CombatFeedback") then
        local h = CreateFrame("Frame", nil, f.Health)
        h:SetAllPoints(f.Health)
        h:SetFrameLevel(30)
        local cfbt = lib.gen_fontstring(h, cfg.font, 18, "THINOUTLINE")
        cfbt:SetPoint("CENTER", f.Health, "BOTTOM", 0, -1)
        cfbt.maxAlpha = 0.75
        cfbt.ignoreEnergize = true
        f.CombatFeedbackText = cfbt
    end
end

 -- oUF_FloatingCombatFeedback
 lib.gen_floating_combat_feedback = function(self)
    if C_AddOns.IsAddOnLoaded("oUF_FloatingCombatFeedback") and cfg.FloatingCombatFeedback then
    self.FloatingCombatFeedback = CreateFrame("Frame", nil, self.Health)
	self.FloatingCombatFeedback:SetFrameLevel(30)
	self.FloatingCombatFeedback:SetPoint("CENTER", self.Health, "BOTTOM", 0, -1)
    for i = 1, 6 do
		self.FloatingCombatFeedback[i] = lib.gen_fontstring(self.FloatingCombatFeedback, cfg.font, 18, "THINOUTLINE")
	end
	self.FloatingCombatFeedback.ignoreEnergize = true
	if cfg.FountainMode then
		self.FloatingCombatFeedback.Mode = "Fountain"
	else
		self.FloatingCombatFeedback.Mode = "Standard"	
	end
	end
end


-- oUF_WeaponEnchant (temporary weapon enchant icon)
local function WeapEnchantIcon(self, icon, icons)
    local iconwidth = icon:GetWidth()
    icon.time = icon:CreateFontString(nil, 'OVERLAY')
    icon.time:SetFont(cfg.font, iconwidth / 2.6, 12)
    icon.time:SetPoint("BOTTOM", icon, 0, -2)
    icon.time:SetJustifyH('CENTER')
    icon.time:SetVertexColor(1.0, 0.8, 0.1)
    
    icon.overlay:SetTexture("Interface\\AddOns\\oUF_Fail\\media\\iconborder.tga")
    icon.overlay:SetTexCoord(0, 1, 0, 1)
    icon.overlay:SetVertexColor(0, 0, 0, 0.9)
    
    icon.icon:SetTexCoord(.08, .92, .08, .92)

end

    local CreateEnchantTimer = function(self, icons)
        for i = 1, 2 do
            local icon = icons[i]
            if icon.expTime then
                icon.timeLeft = icon.expTime - GetTime()
                icon.time:Show()
            else
                icon.time:Hide()
            end
            icon:SetScript("OnUpdate", CreateAuraTimer)
        end
    end
    
    lib.gen_WeaponEnchant = function(self)
        if C_AddOns.IsAddOnLoaded("oUF_WeaponEnchant") then
            self.Enchant = CreateFrame("Frame", nil, self)
            self.Enchant:SetSize(64, 32)
            self.Enchant:SetPoint("TOPRIGHT", self.Power, "BOTTOMLEFT", 0, 0)
            self.Enchant.size = 32
            self.Enchant.spacing = 2
            self.Enchant.initialAnchor = "TOPRIGHT"
            self.Enchant["growth-x"] = "LEFT"
            self.Enchant:SetFrameLevel(10)
            self.PostCreateEnchantIcon = WeapEnchantIcon
            self.PostUpdateEnchantIcons = CreateEnchantTimer
        end
    end

-- Addon seviyesinde global target değişim eventi
local targetChangeFrame = CreateFrame("Frame")
targetChangeFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetChangeFrame:SetScript("OnEvent", function(self, event)
    -- Hedef değiştiğinde tüm frameler için güncelle
    if event == "PLAYER_TARGET_CHANGED" then
        -- Target ve Focus frame'lerini bul ve güncelle
        if oUF_failTarget and oUF_failTarget.Power and oUF_failTarget.Power.arrow then
            lib.UpdateArrowColor("target", oUF_failTarget.Power.arrow)
            
            -- Target için power text güncellemesi
            if oUF_failTarget.Power.powerText then
                local value = UnitPower("target") or 0
                local color
                
                if UnitIsPlayer("target") then
                    -- Oyuncu için CLASS rengini kullan (powerType değil)
                    local _, class = UnitClass("target")
                    color = class and oUF.colors.class[class] or {0.5, 0.5, 0.5}
                else
                    -- NPC için reaction rengini kullan
                    local reaction = UnitReaction("target", "player")
                    color = reaction and oUF.colors.reaction[reaction] or {1, 1, 0}
                end
                
                -- Format the text with the right color
                local text = oUF_failTarget.Power.powerText
                if text then
                    if value >= 1e3 then
                        text:SetFormattedText("|cff%02x%02x%02x%.1fk", color[1] * 255, color[2] * 255, color[3] * 255, value / 1e3)
                    else
                        text:SetFormattedText("|cff%02x%02x%02x%d", color[1] * 255, color[2] * 255, color[3] * 255, value)
                    end
                end
            end
        end
        
        if oUF_failFocus and oUF_failFocus.Power and oUF_failFocus.Power.arrow then
            lib.UpdateArrowColor("focus", oUF_failFocus.Power.arrow)
        end
        
        -- Tag güncelleme için
        if oUF_failTarget then
            oUF_failTarget:UpdateTags()
        end
        
        if oUF_failFocus then
            oUF_failFocus:UpdateTags()
        end
    end
end)

-- hand the lib to the namespace for further usage
ns.lib = lib