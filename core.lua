local addon, ns = ...
local cfg = ns.cfg
local lib = ns.lib
local oUF = oUF or ns.oUF

DAMAGE_TEXT_FONT = "Interface\\AddOns\\oUF_Fail\\media\\BlueMoon.ttf"

-- Unit has an Aura
function hasUnitAura(unit, name)

	local _, _, _, count, _, _, _, caster = C_UnitAuras.GetAuraDataByIndex(unit, name)
	if (caster and caster == "player") then
		return count
	end
end

-- Unit has a Debuff
function hasUnitDebuff(unit, name)

	local _, _, _, count, _, _, _, _ = C_UnitAuras.GetAuraDataByIndex(unit, name)
	if (count) then return count
	end
end

local function MyPvPUpdate(self, event, unit)
	if (unit ~= self.unit) then return end
	
	local pvp = self.MyPvP
	if (pvp) then
		local factionGroup = UnitFactionGroup(unit)
		if (not InCombatLockdown()) then
			if (UnitIsPVPFreeForAll(unit)) then
				pvp:SetTexture([[Interface\TargetingFrame\UI-PVP-FFA]])
				pvp:Show()
			elseif (UnitIsPVP(unit) and factionGroup) then
				if (factionGroup == 'Horde') then
					pvp:SetTexture([[Interface\Addons\oUF_Fail\media\Horde]])
				else
					pvp:SetTexture([[Interface\Addons\oUF_Fail\media\Alliance]])
				end
				pvp:Show()
			else
				pvp:Hide()
			end
		end
	end
end
	

oUF.colors.smooth = {0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22, 0.22,}
  -----------------------------
  -- STYLE FUNCTIONS
  -----------------------------

local UnitSpecific = {

	player = function(self, ...)

		self.mystyle = "player"

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(192, 42)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)
		lib.gen_combat_feedback(self)
		lib.gen_floating_combat_feedback(self)
		lib.gen_InfoIcons(self)
		lib.HealPred(self)

		-- Buffs and Debuffs
		if cfg.showPlayerAuras then
			BuffFrame:Hide()
			lib.createBuffs(self)
			lib.createDebuffs(self)
			lib.gen_WeaponEnchant(self)
		end

		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		-- self.Health.bg.multiplier = 0.2

		-- Power bar color customization
		if select(2, UnitClass("player")) == "MONK" then
			-- Use the same power settings as target frame for Monks
			self.Power.colorPower = false
			self.Power.colorClass = true  -- Disable class coloring
			self.Power.colorTapping = true
			self.Power.colorDisconnected = true
			self.Power.colorHappiness = false
			self.Power.colorHealth = true
			self.Power.colorReaction = true
			self.Power.bg.multiplier = 0.5
		else
			-- Default power settings for other classes
			self.Power.colorPower = true
			self.Power.colorClass = true
			self.Power.bg.multiplier = 0.2
		end

		self.Power.Smooth = true
		self.Power.frequentUpdates = true

		--lib.gen_castbar(self)
		lib.gen_mirrorcb(self)
		lib.debuffHighlight(self)
		self.Power.PostUpdate = lib.setPowerArrowColor

		-- PvP Icon
		local pvp = self.Health:CreateTexture(nil, "OVERLAY")
		pvp:SetHeight(32)
		pvp:SetWidth(32)
		pvp:SetPoint("BOTTOMLEFT", -8, -16		)
		self.MyPvP = pvp

		-- This makes oUF update the information.
		self:RegisterEvent("UNIT_FACTION", MyPvPUpdate)
		-- This makes oUF update the information on forced updates.
		table.insert(self.__elements, MyPvPUpdate)

		if cfg.showRunebar then lib.genRunes(self) end
		if cfg.showClassbar then lib.gen_Classbar(self) end
		lib.RogueComboPoints(self)
		lib.gen_AltPowerBar(self)

		-- Addons
		if cfg.showTotemBar then lib.gen_TotemBar(self) end
		--== smooth power text for player==--  

		-- Just call lib.HealPred
		lib.HealPred(self)
	end,

	target = function(self, ...)

		self.mystyle = "target"

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(256,38)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)
		lib.gen_combat_feedback(self)
		lib.gen_floating_combat_feedback(self)
		lib.HealPred(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.frequentUpdates = true
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorHappiness = false
		self.Power.colorHealth = true
		self.Power.colorReaction = true
		self.Power.colorClass = true
		self.Power.bg.multiplier = 0.5
		if cfg.ShowExtraUnitArrows then self.Power.PostUpdate = lib.setClassArrowColor end
		--lib.gen_castbar(self)
		lib.gen_mirrorcb(self)
		lib.debuffHighlight(self)

		-- PvP Icon
		local pvp = self.Health:CreateTexture(nil, "OVERLAY")
		--pvp:SetTexture(1, 0, 0)
		pvp:SetHeight(36)
		pvp:SetWidth(36)
		pvp:SetPoint("BOTTOMRIGHT", 24, -12)
		self.MyPvP = pvp

		-- This makes oUF update the information.
		self:RegisterEvent("UNIT_FACTION", MyPvPUpdate)
		-- This makes oUF update the information on forced updates.
		table.insert(self.__elements, MyPvPUpdate)

		if cfg.showTargetBuffs then	lib.createBuffs(self) end
		if cfg.showTargetDebuffs then lib.createDebuffs(self) end
	end,

	targettarget = function(self, ...)

		self.mystyle = "tot"

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(150, 30)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorHappiness = false
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.colorHealth = true
		self.Power.bg.multiplier = 0.5
		lib.HealPred(self)
		lib.createBuffs(self) 
		lib.createDebuffs(self)

	end,

	focus = function(self, ...)

		self.mystyle = "focus"

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(140, 30)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.Smooth = true
		self.Health.colorSmooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorHappiness = false
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.colorHealth = true
		self.Power.bg.multiplier = 0.5
		if cfg.ShowExtraUnitArrows then self.Power.PostUpdate = lib.setClassArrowColor end
		lib.gen_castbar(self)
		lib.HealPred(self)
		lib.createDebuffs(self)
	end,
	
	focustarget = function(self, ...)

		self.mystyle = "focustarget"

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(140, 30)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.colorClass = true
		self.Health.Smooth = true
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorPower = true
		self.Power.colorReaction = true
		self.Power.bg.multiplier = 0.5
		if cfg.ShowExtraUnitArrows then self.Power.PostUpdate = lib.setPowerArrowColor end
		lib.gen_castbar(self)
		lib.HealPred(self)

	end}

-- Pet style
  local function CreatePetStyle(self, unit)

		self.mystyle = "pet"
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = .3,
		}
		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(90,30)

		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorHappiness = false
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.colorHealth = true
		self.Power.bg.multiplier = 0.5
		lib.gen_castbar(self)
		lib.HealPred(self)

	end
	
 --Partypet style
  local function CreatePartyPetStyle(self)

		-- Size and Scale
		self:SetScale(cfg.scale)
		self:SetSize(90,30)
		self.mystyle = "partypet"
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = .3,
		}
		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.Smooth = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorHappiness = false
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.colorHealth = true
		self.Power.bg.multiplier = 0.5
		lib.gen_castbar(self)

	end
	
-- Party style
local function CreatePartyStyle(self)
	self.menu = lib.menu
	self:RegisterForClicks("AnyUp")
    self:SetAttribute("*type2", "menu")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
	if self:GetAttribute("unitsuffix") == "pet" then
      return CreatePartyPetStyle(self)
  	end
		self.mystyle = "party"
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = .3,
		}
		-- Generate Bars
		lib.gen_hpbar(self)
		lib.gen_hpstrings(self)
		lib.gen_highlight(self)
		lib.gen_ppbar(self)
		lib.gen_RaidMark(self)
		lib.ReadyCheck(self)
		lib.gen_LFDRole(self)

		--style specific stuff
		self.Health.frequentUpdates = true
		self.Health.colorSmooth = true
		self.Health.Smooth = true
		self.Power.Smooth = true
		-- self.Health.bg.multiplier = 0.3
		self.Power.colorClass = true
		self.Power.bg.multiplier = 0.5
		self.Power.arrow.colorPower = true
		if cfg.ShowExtraUnitArrows then self.Power.PostUpdate = lib.setClassArrowColor end
		lib.gen_InfoIcons(self)
		lib.CreateTargetBorder(self)
		lib.CreateThreatBorder(self)
		lib.HealPred(self)
		lib.debuffHighlight(self)
		lib.raidDebuffs(self)

		self.Health.PostUpdate = lib.PostUpdateRaidFrame
		
		-- Check if the function exists before registering events
		if lib.ChangedTarget then
			self:RegisterEvent('GROUP_ROSTER_UPDATE', lib.ChangedTarget)
		end
		
		if lib.UpdateThreat then
			self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", lib.UpdateThreat)
			self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", lib.UpdateThreat)
		end
		lib.HealPred(self)
	end
	
-- Raid frames layout
local CreateRaidStyle = function(self, unit, isSingle)
    self.menu = lib.menu
    self:RegisterForClicks("AnyUp")
    self:SetAttribute("type2", "togglemenu")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    self.mystyle = "failRaid"
    self.Range = {
        insideAlpha = 1,
        outsideAlpha = .3,
    }
    
    -- Generate Bars
    lib.gen_hpbar(self)
    lib.gen_hpstrings(self)
    lib.gen_highlight(self)
    lib.gen_ppbar(self)
    lib.gen_RaidMark(self)
    lib.ReadyCheck(self)
    
    --style specific stuff
    self.Health.frequentUpdates = true
    self.Health.colorSmooth = true
    self.Power.colorClass = true
    self.Power.bg.multiplier = 0.5
    lib.gen_InfoIcons(self)
    lib.CreateTargetBorder(self)
    lib.CreateThreatBorder(self)
    lib.HealPred(self)
    lib.debuffHighlight(self)
    lib.raidDebuffs(self)

    self.Health.PostUpdate = lib.PostUpdateRaidFrame
    
    -- Register events after frame is fully initialized
    self:HookScript("OnShow", function(frame)
        if frame:IsVisible() then
            frame:RegisterEvent('GROUP_ROSTER_UPDATE', lib.ChangedTarget)
            frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE", lib.UpdateThreat)
            frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", lib.UpdateThreat)
        end
    end)
	lib.HealPred(self)
end


-- The Shared Style Function
local GlobalStyle = function(self, unit, isSingle)

	self.menu = lib.spawnMenu
	self:RegisterForClicks('AnyDown')

	-- Call Unit Specific Styles
	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

-- Boss frames layout
local function CreateBossStyle(self, unit)

	self.mystyle = "failBoss"
			
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = .3,
	}

	-- Size and Scale
	self:SetSize(150,29)

	-- Generate Bars
	lib.gen_hpbar(self)
	lib.gen_hpstrings(self)
	lib.gen_highlight(self)
	lib.gen_ppbar(self)
	lib.gen_RaidMark(self)

	--style specific stuff
	self.Health.frequentUpdates = true
	self.Health.colorSmooth = true
	--self.Health.Smooth = true
	self.Power.frequentUpdates = true
	self.Power.Smooth = true
	self.Power.colorPower = true
	self.Power.colorReaction = true
	self.Power.colorTapping = true
	self.Power.bg.multiplier = 0.5
	lib.gen_castbar(self)
	--lib.gen_mirrorcb(self)

	--[[if cfg.showBossBuffs then	lib.createBuffs(self) end
	if cfg.showBossDebuffs then lib.createDebuffs(self) end
	]]
end

local function CreateMTStyle(self,unit,isSingle)
	self.mystyle = "failMT"
	self:SetSize(150,29)
	-- Generate Bars
	lib.gen_hpbar(self)
	lib.gen_hpstrings(self)
	lib.gen_highlight(self)
	lib.gen_ppbar(self)
	lib.gen_RaidMark(self)
	lib.ReadyCheck(self)
	lib.createDebuffs(self)
	self.Health.frequentUpdates = false
	self.Health.colorClass = true

end 

local function CreateArenaStyle(self, unit, isSingle)
	self.mystyle = "failArena"
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = .3,
	}

	-- Size and Scale
	self:SetSize(150,29)

	-- Generate Bars
	lib.gen_hpbar(self)
	lib.gen_hpstrings(self)
	lib.gen_highlight(self)
	lib.gen_ppbar(self)
	lib.gen_RaidMark(self)

	--style specific stuff
	self.Health.frequentUpdates = true
	self.Health.colorSmooth = true
	--self.Health.Smooth = true
	self.Power.frequentUpdates = true
	self.Power.Smooth = true
	self.Power.colorHealth = true
	self.Power.colorClass = true
	self.Power.bg.multiplier = 0.5
	lib.gen_castbar(self)
	lib.gen_mirrorcb(self)

	lib.createBuffs(self) 
	lib.createDebuffs(self) 
	
end

  -----------------------------
  -- SPAWN UNITS
  -----------------------------

oUF:RegisterStyle('fail', GlobalStyle)
oUF:RegisterStyle('failPet', CreatePetStyle)
oUF:RegisterStyle('failParty', CreatePartyStyle)
oUF:RegisterStyle('failRaid', CreateRaidStyle)
oUF:RegisterStyle('failMT', CreateMTStyle)
oUF:RegisterStyle('failArena', CreateArenaStyle)
oUF:RegisterStyle('failBoss', CreateBossStyle)

oUF:Factory(function(self)
    -- Single Frames
    self:SetActiveStyle('fail')
    local player = self:Spawn('player')
    player:SetPoint("CENTER", UIParent, cfg.PlayerRelativePoint, cfg.PlayerX, cfg.PlayerY)
    
    local target = self:Spawn('target')
    target:SetPoint("CENTER", UIParent, cfg.TargetRelativePoint, cfg.TargetX, cfg.TargetY)
    
    if cfg.showtot then 
        local tot = self:Spawn('targettarget')
        tot:SetPoint("BOTTOMLEFT", oUF_failTarget, cfg.TotRelativePoint, cfg.TotX, cfg.TotY)
    end
    
    if cfg.showfocus then
        local focus = self:Spawn('focus')
        focus:SetPoint("BOTTOMRIGHT", oUF_failPlayer, cfg.FocusRelativePoint, cfg.FocusX, cfg.FocusY)
    end
    
    if cfg.showfocustarget then
        local focustarget = self:Spawn('focustarget')
        focustarget:SetPoint("BOTTOMLEFT", oUF_failFocus, "TOPRIGHT", cfg.FocusTargetX, cfg.FocusTargetY)
    end

    if cfg.showpet then 
        self:SetActiveStyle("failPet")
        local pet = self:Spawn("pet", "oUF_failPetFrame")
        pet:SetPoint("TOPRIGHT", oUF_failPlayer, "TOPLEFT", -14, 0)
        pet:SetScale(cfg.scale)
    end

    -- Party Frames
    if cfg.ShowParty then
        self:SetActiveStyle('failParty')
        local party = oUF:SpawnHeader('failParty', nil, 'custom  [group:party,nogroup:raid][@raid6,noexists,group:raid] show;hide',
        "showParty", true,
        "showPlayer", false,
        'template',
        'oUF_failPartyPet',
        "yoffset", -20,
        "oUF-initialConfigFunction", ([[
            self:SetWidth(%d)
            self:SetHeight(%d)
        ]]):format(128, 26))
        party:SetScale(cfg.partyScale)
        party:SetPoint('BOTTOM', UIParent, 'CENTER', cfg.PartyX, cfg.PartyY)
    else
        oUF:DisableBlizzard'party'
    end    
    
    -- Raid frames
    if cfg.ShowRaid then
        self:SetActiveStyle("failRaid")
        local raidAnchor = CreateFrame("Frame", "oUF_RaidAnchor", UIParent, "BackdropTemplate")
        
        -- Check saved position
        local savedPos = _G.oUF_FailPositions["oUF_RaidAnchor"]
        if savedPos then
            raidAnchor:SetPoint(savedPos.point, UIParent, savedPos.relativePoint, savedPos.x, savedPos.y)
        else
            raidAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.RaidX, cfg.RaidY)
        end

        raidAnchor:SetSize(800, 200)
        raidAnchor:SetMovable(true)
        raidAnchor:EnableMouse(true)
        raidAnchor:RegisterForDrag("LeftButton")
        raidAnchor:SetUserPlaced(true)
        raidAnchor:SetClampedToScreen(true)

        -- Raid 10 (6-10 players)
        local raid10 = self:SpawnHeader(
            "oUF_Raid10", nil, "custom [@raid11,exists] hide; [@raid6,exists] show; hide",
            "showRaid", true,
            "showParty", false,
            "showPlayer", true,
            "showSolo", false,
            "xoffset", 8,
            "yOffset", -8,
            "groupFilter", "1,2,3,4,5,6,7,8",
            "groupBy", "GROUP",
            "groupingOrder", "1,2,3,4,5,6,7,8",
            "sortMethod", "INDEX",
            "maxColumns", 2,
            "unitsPerColumn", 5,
            "columnSpacing", 8,
            "point", "TOP",
            "columnAnchorPoint", "LEFT",
            "oUF-initialConfigFunction", [[
                self:SetWidth(95)
                self:SetHeight(25)
                self:SetAttribute('*type1', 'target')
                self:SetAttribute('*type2', 'togglemenu')
            ]]
        )
        raid10:ClearAllPoints()
        raid10:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
        raid10:SetParent(raidAnchor)

        -- Raid 25 (11-25 players)
        local raid25 = self:SpawnHeader(
            "oUF_Raid25", nil, "custom [@raid26,exists] hide; [@raid11,exists] show; hide",
            "showRaid", true,
            "showParty", false,
            "showPlayer", true,
            "showSolo", false,
            "xoffset", 8,
            "yOffset", -8,
            "groupFilter", "1,2,3,4,5",
            "groupBy", "GROUP",
            "groupingOrder", "1,2,3,4,5",
            "sortMethod", "INDEX",
            "maxColumns", 5,
            "unitsPerColumn", 5,
            "columnSpacing", 8,
            "point", "TOP",
            "columnAnchorPoint", "LEFT",
            "oUF-initialConfigFunction", [[
                self:SetWidth(95)
                self:SetHeight(25)
                self:SetAttribute('*type1', 'target')
                self:SetAttribute('*type2', 'togglemenu')
            ]]
        )
        raid25:ClearAllPoints()
        raid25:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
        raid25:SetParent(raidAnchor)

        -- Raid 40 (26-40 players)
        local raid40 = self:SpawnHeader(
            "oUF_Raid40", nil, "custom [@raid26,exists] show; hide",
            "showRaid", true,
            "showParty", false,
            "showPlayer", true,
            "showSolo", false,
            "xoffset", 8,
            "yOffset", -8,
            "groupFilter", "1,2,3,4,5,6,7,8",
            "groupBy", "GROUP",
            "groupingOrder", "1,2,3,4,5,6,7,8",
            "sortMethod", "INDEX",
            "maxColumns", 8,
            "unitsPerColumn", 5,
            "columnSpacing", 8,
            "point", "TOP",
            "columnAnchorPoint", "LEFT",
            "oUF-initialConfigFunction", [[
                self:SetWidth(95)
                self:SetHeight(25)
                self:SetAttribute('*type1', 'target')
                self:SetAttribute('*type2', 'togglemenu')
            ]]
        )
        raid40:ClearAllPoints()
        raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
        raid40:SetParent(raidAnchor)
    end 
            
    -- Main Tank Frames
    if cfg.showMTFrames then
        self:SetActiveStyle('failMT')
        local tank = oUF:SpawnHeader('oUF_MT', nil, 'raid',
            'oUF-initialConfigFunction', ([[
                self:SetWidth(%d)
                self:SetHeight(%d)
            ]]):format(80, 22),
            'showRaid', true,
            'groupFilter', 'MAINTANK',
            'yOffset', 8,
            'point' , 'BOTTOM',
            'template', 'oUF_MainTank')
        tank:SetPoint("TOP", UIParent, "TOP", cfg.TankX, cfg.TankY)
    end

    -- Boss Frames
    if cfg.showBossFrames then
        self:SetActiveStyle('failBoss')
        local boss = {}
        for i = 1, MAX_BOSS_FRAMES do
            boss[i] = self:Spawn("boss"..i, "oUF_Boss"..i)
            if i == 1 then
                boss[i]:SetPoint("CENTER", UIParent, "CENTER", cfg.BossX, cfg.BossY)
            else
                boss[i]:SetPoint("BOTTOMRIGHT", boss[i-1], "BOTTOMRIGHT", 0, 60)
            end
        end
    end

    -- Arena Frames
    if cfg.showArenaFrames then
        self:SetActiveStyle('failArena')

        local arena = {}
        for i = 1, 5 do
            arena[i] = self:Spawn("arena"..i, "oUF_Arena"..i)
            if i == 1 then
                arena[i]:SetPoint("BOTTOMRIGHT", UIParent, "TOPRIGHT", cfg.BossX, cfg.BossY)
            else
                arena[i]:SetPoint("BOTTOMRIGHT", arena[i-1], "BOTTOMRIGHT", 0, 90)
            end
            arena[i]:SetSize(150, 30)
        end    

        local FailPrepArena = {}
        for i = 1, 5 do
            FailPrepArena[i] = CreateFrame("Frame", "FailPrepArena"..i, UIParent)
            FailPrepArena[i]:SetAllPoints(arena[i])
            FailPrepArena[i]:SetBackdropColor(0,0,0)
            FailPrepArena[i].Health = CreateFrame("StatusBar", nil, FailPrepArena[i])
            FailPrepArena[i].Health:SetAllPoints()
            FailPrepArena[i].Health:SetStatusBarTexture(cfg.statusbar_texture)
            FailPrepArena[i].Health:SetStatusBarColor(.3, .3, .3, 1)
            FailPrepArena[i].SpecClass = FailPrepArena[i].Health:CreateFontString(nil, "OVERLAY")
            FailPrepArena[i].SpecClass:SetFont(cfg.font, 9, "OUTLINE")
            FailPrepArena[i].SpecClass:SetPoint("CENTER")
            FailPrepArena[i]:Hide()
        end

        local ArenaListener = CreateFrame("Frame", "FailArenaListener", UIParent)
        ArenaListener:RegisterEvent("PLAYER_ENTERING_WORLD")
        ArenaListener:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        ArenaListener:RegisterEvent("ARENA_OPPONENT_UPDATE")
        ArenaListener:SetScript("OnEvent", function(self, event)
            if event == "ARENA_OPPONENT_UPDATE" then
                for i=1, 5 do
                    local f = _G["FailPrepArena"..i]
                    f:Hide()
                end            
            else
                local numOpps = GetNumArenaOpponentSpecs()
                
                if numOpps > 0 then
                    for i=1, 5 do
                        local f = _G["FailPrepArena"..i]
                        local s = GetArenaOpponentSpec(i)
                        local _, spec, class = nil, "UNKNOWN", "UNKNOWN"
                        
                        if s and s > 0 then 
                            _, spec, _, _, _, _, class = GetSpecializationInfoByID(s)
                        end
                        
                        if (i <= numOpps) then
                            if class and spec then
                                f.SpecClass:SetText(spec.."  -  "..LOCALIZED_CLASS_NAMES_MALE[class])
                                
                                local color = arena[i].colors.class[class]
                                f.Health:SetStatusBarColor(unpack(color))
                                
                                f:Show()
                            end
                        else
                            f:Hide()
                        end
                    end
                else
                    for i=1, 5 do
                        local f = _G["FailPrepArena"..i]
                        f:Hide()
                    end            
                end
            end
        end)
    end
end)
