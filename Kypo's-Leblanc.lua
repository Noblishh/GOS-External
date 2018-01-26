local Heroes = {"Leblanc"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.2"

local HKITEM = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,
	[ITEM_7] = HK_ITEM_7,
}

if FileExist(COMMON_PATH .. "TPred.lua") then
	require 'TPred'
	PrintChat("TPred library loaded")
elseif FileExist(COMMON_PATH .. "Collision.lua") then
	require 'Collision'
	PrintChat("Collision library loaded")
end

function SetMovement(bool)
	if _G.EOWLoaded then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
	if bool then
		castSpell.state = 0
	end
end

class "Leblanc"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f1/LeBlancSquare.png"

function Leblanc:LoadSpells()

	Q = {Range = 700, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 600, Delay = 0.25, Speed = 2000, Collision = false, aoe = true, Type = "circular", Radius = 260}
	E = {Range = 925, Delay = 0.40, Speed = 1750, Collision = true, aoe = false, Type = "line", Radius = 27.5}

end

function Leblanc:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Leblanc", name = "Kypo's Leblanc", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseR", name = "Use R to cast E, when combo is finished", value = true})
	self.Menu.Combo:MenuElement({id = "Type", name = "Combo Logic", value = 1,drop = {"EWQ", "WEQ"}})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseWQ", name = "WQ", value = false, key = string.byte("6")})
	self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q", toggle = true, value = false, toggle, true, key = string.byte("Capslock")})
	
	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q to use passive?", value = true})
	self.Menu.Clear:MenuElement({id = "WHit", name = "W hits x minions", value = 3,min = 2, max = 8, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Flee", name = "E Key / Burst", type = MENU})
	self.Menu.Flee:MenuElement({id = "EKey", name = "E Key", key = string.byte("T")})
	self.Menu.Flee:MenuElement({id = "BurstEREQW", name = "Burst EREQW", key = string.byte("T")})

	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseIG", name = "Use Ignite", value = true})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "E", name = "E", value = true})
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
	self.Menu.Items:MenuElement({id = "Protobelt", name = "Hextech Protobelt", value = true})
	self.Menu.Items:MenuElement({id = "GLP", name = "Hextech GLP", value = true})
	self.Menu.Items:MenuElement({id = "Gunblade", name = "Hextech Gunblade", value = true})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Leblanc:__init()
	
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local orbwalkername = ""
	if _G.SDK then
		orbwalkername = "IC'S orbwalker"		
	elseif _G.EOW then
		orbwalkername = "EOW"	
	elseif _G.GOS then
		orbwalkername = "Noddy orbwalker"
	else
		orbwalkername = "Orbwalker not found"
	end
end

function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function GetInventorySlotItem(itemID)
		assert(type(itemID) == "number", "GetInventorySlotItem: wrong argument types (<number> expected)")
		for _, j in pairs({ ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
			if myHero:GetItemData(j).itemID == itemID and myHero:GetSpellData(j).currentCd == 0 then return j end
		end
		return nil
	    end

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
end

function Leblanc:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:ComboTypes()
	end	
	if self.Menu.Harass.UseWQ:Value() then
		self:WQ()
	end	
	if self.Menu.Killsteal.UseIG:Value() then
		self:UseIG()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
		self:ClearQP()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Items()
	end
	--E key/Burst
	if self.Menu.Flee.BurstEREQW:Value() then
	self:BurstEREQW()
	end
	if self.Menu.Flee.EKey:Value() and self:CanCast(HK_E) then
	self:EKey()
	end
		self:AutoQ()
		self:KillstealQ()
		self:KillstealE()
		self:KillstealQPassive()
		self:ECC()
	
end

function Leblanc:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Leblanc:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 1150 then
        return true
        end
    	end
    	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Leblanc:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Leblanc:CanCast(spellSlot)
	return self:IsReady(spellSlot)
end

function EnableMovement()
	SetMovement(true)
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.1)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.05,{pos})
end

function Leblanc:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Leblanc:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Leblanc:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

-----------------------------
-- DRAWINGS
-----------------------------

function Leblanc:Draw()
	if self.Menu.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(200, 255, 255, 255))
			end
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 700, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 925, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 600, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, self.Menu.Drawings.HPColor:Value())
				end
			end
		end	
	end

	if self:CanCast(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, E.Width, myHero.pos, not E.ignorecol, E.Type )
			Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end	
	end

function Leblanc:CastSpell(spell,pos)
	local customcast = self.Menu.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = self.Menu.delay:Value()
		local ticker = GetTickCount()
		if castSpell.state == 0 and ticker > castSpell.casting then
			castSpell.state = 1
			castSpell.mouse = mousePos
			castSpell.tick = ticker
			if ticker - castSpell.tick < Game.Latency() then
				SetMovement(false)
				Control.SetCursorPos(pos)
				Control.KeyDown(spell)
				Control.KeyUp(spell)
				DelayAction(LeftClick,delay/1000,{castSpell.mouse})
				castSpell.casting = ticker + 500
			end
		end
	end
end

function Leblanc:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

-----------------------------
-- BUFFS
-----------------------------

function Leblanc:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

-----------------------------
-- COMBO
-----------------------------

function Leblanc:ComboTypes(target)
local mode = self.Menu.Combo.Type:Value() 
	if mode == 1 then
		self:EWQ()
	elseif mode == 2 then
		self:WEQ()
end
end

-- 1
function Leblanc:EWQ()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and self:CanCast(_E) and self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end

local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and self:CanCast(_W) then
	    if self:EnemyInRange(W.Range) and HasBuff(target, "leblanceroot") or HasBuff(target, "LeblancPMark") then
			    Control.CastSpell(HK_W, target)
		    end
	    end
		
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
			    Control.CastSpell(HK_Q, target)
		    end
	    end
end


-- 2
function Leblanc:WEQ()
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and self:CanCast(_W) and self:EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
		    end
	    end


local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and self:CanCast(_E) and self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end
		
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
			    Control.CastSpell(HK_Q, target)
		    end
	    end
end

-----------------------------
-- Clear
-----------------------------

function Leblanc:Clear()
	if self:CanCast(_W) then
	local wMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  self:isValidTarget(minion,600)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				wMinions[#wMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(600, 260 + 40, wMinions)
		if BestHit >= self.Menu.Clear.WHit:Value() then
			Control.CastSpell(HK_W,BestPos)
		end
	end
end
end

function Leblanc:ClearQP()
if self.Menu.Clear.UseQ:Value() then
	if self:CanCast(_Q) then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local pBuff = GetBuffData(minion,"LeblancPMark")
			if self:isValidTarget(minion,600) and pBuff then
			DelayAction(function()
			if not self:CanCast(_Q) and not self:CanCast(HK_W) then return end
			Control.CastSpell(HK_Q, minion)
			end, 1.20) end
			end
		end
	end
end

function GetBestCircularFarmPosition(range, radius, objects)
    local BestPos 
    local BestHit = 0
    for i, object in pairs(objects) do
        local hit = CountObjectsNearPos(object.pos, range, radius, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = object.pos
            if BestHit == #objects then
               break
            end
         end
    end
    return BestPos, BestHit
end

function Leblanc:isValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and not obj.isImmortal and obj.distance <= range
end

function CountObjectsNearPos(pos, range, radius, objects)
    local n = 0
    for i, object in pairs(objects) do
        if GetDistanceSqr(pos, object.pos) <= radius * radius then
            n = n + 1
        end
    end
    return n
end

-----------------------------
-- HARASS
-----------------------------

function Leblanc:WQ()
     if self.Menu.Harass.UseWQ:Value() then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and self:CanCast(_W) and self:EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
		if self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) and HasBuff(target, "LeblancPMark") then
			DelayAction(function()
			if not self:CanCast(_Q) then return end
			Control.CastSpell(HK_Q, target)
			end, 0.95) end
		    end
		    end
	    end
		end
end

function Leblanc:AutoQ()
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
if target and self:CanCast(_Q) and self:EnemyInRange(Q.Range) and self.Menu.Harass.AutoQ:Value() then
			Control.CastSpell(HK_Q, target)
		end
	end


function HasBuff(unit, buffName, delay)
		for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name:lower() == buffName:lower()and buff.count > 0 then
				return true
			end
		end
	return false
end
	
-----------------------------
-- KILLSTEAL
-----------------------------

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function Leblanc:UseIG()
    local target = CurrentTarget(600)
	if self.Menu.Killsteal.UseIG:Value() and target then 
		local IGdamage = 70 + 20 * myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if self:IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_1) then
				if IGdamage >= self:HpPred(target, 1) + target.hpRegen * 1.3 then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if self:IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_2) then
				if IGdamage >= self:HpPred(target, 1) + target.hpRegen * 1.3 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

----------------------------------------------------------------------------- Without Passive

function Leblanc:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({55,90,125,160,195})[level] + 0.50 * myHero.ap)
	return qdamage
end

function Leblanc:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({80,120,160,200,240})[level] + 1.0 * myHero.ap * 2)
	return edamage
end

----------------------------------------------------------------------------- With Passive

function Leblanc:QDMGPassive()
    local level = myHero:GetSpellData(_Q).level
    local passive = myHero.levelData.lvl
    local qdamage = (({55,90,125,160,195})[level] + 0.50 * myHero.ap) + (({30,40,50,60,70,80,90,100,120,140,160,180,200,220,240,260,280,300})[passive])
	return qdamage
end

function Leblanc:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-----------------------------
-- Q KS
-----------------------------

function Leblanc:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
		   	local Qdamage = Leblanc:QDMG()
		   	local QdamagePassive = Leblanc:QDMGPassive()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_Q, target)
				end
			end
		end
	end
	
function Leblanc:KillstealQPassive()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
		   	local QdamagePassive = Leblanc:QDMGPassive()
			if HasBuff(target, "LeblancPMark") and QdamagePassive >= self:HpPred(target,1) + target.hpRegen * 1 then
			DelayAction(function()
			if not self:CanCast(_Q) then return end
			Control.CastSpell(HK_Q, target)
			end, 1.00) end
				end
			end
		end
	
-----------------------------
-- E KS
-----------------------------

function Leblanc:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(Q.Range) then 
		   	local Edamage = Leblanc:EDMG()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target and Edamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end
	    end
	    end

-----------------------------
-- R KS on CC
-----------------------------

function Leblanc:ECC()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.isCC.E:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(E.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    self:CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

-- Items

function Leblanc:GetItemData(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and Game.CanUseSpell(spell) == 0 
end

function Leblanc:Items()
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Protobelt:Value() then
		local protobelt = GetInventorySlotItem(3152)
		if protobelt and self:EnemyInRange(700) then
			Control.CastSpell(HKITEM[protobelt], target)
		end
	end
	
	local target = CurrentTarget(800)
	if target == nil then return end
		if self.Menu.Items.GLP:Value() then
		local GLP = GetInventorySlotItem(3030)
		if GLP and self:EnemyInRange(800) then
			Control.CastSpell(HKITEM[GLP], target)
		end
	end
	
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Gunblade:Value() then
		local Gunblade = GetInventorySlotItem(3146)
		if Gunblade and self:EnemyInRange(700 ) then
			Control.CastSpell(HKITEM[Gunblade], target)
		end
	end
	
end

----------Flee

function Leblanc:BurstEREQW()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and self:CanCast(_E) and self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end
		
if not self:CanCast(_E) then
local target = CurrentTarget(E.Range)
    if target == nil then return end
			if target and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
		    end
		    end
		
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and self:CanCast(_E) and self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target and self:CanCast(_E) then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end
		
if not self:CanCast(_E) then
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target then
	    if self:EnemyInRange(Q.Range) then
			-- Control.CastSpell(HK_Q, target)
			if self:CanCast(_Q) then
				Control.CastSpell(HK_Q, target)
		    end
	    end
	    end
	    end

if not self:CanCast(_Q) then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and self:CanCast(_W) and self:EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
		    end
	    end
end
end


function Leblanc:EKey()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and self:CanCast(_E) and self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    Control.CastSpell(HK_E, castpos)
		    end
	    end
end

Callback.Add("Load",function() _G[myHero.charName]() end)