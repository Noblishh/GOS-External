local Heroes = {"Nasus"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"


local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.2"

keybindings = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6}

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

class "Nasus"

local HeroIcon = "http://static.lolskill.net/img/champions/64/nasus.png"

function Nasus:LoadSpells()

	Q = {Range = 150, Width = 50, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 600, Width = 50, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	E = {Range = 650, Width = 400, Delay = 0.25, Speed = 1600, Collision = false, aoe = false, Type = "circular"}
	R = {Range = 800, Width = 1, Delay = 0.25, Speed = 1000, Collision = false, aoe = false}

end

function Nasus:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Nasus", name = "Kypo's Nasus", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Combo:MenuElement({id = "MinRCast", name = "R", value = true})
	self.Menu.Combo:MenuElement({id = "MinRHealth",name="Min Health -> %",value=20,min=10,max=100})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Clear:MenuElement({id = "EHit", name = "E hits x minions", value = 3,min = 1, max = 6, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Bonus", name = "Bonus", type = MENU})
	self.Menu.Bonus:MenuElement({id = "UseQ", name = "Auto Farm", value = false, toggle = true, key = string.byte("T")})
	self.Menu.Bonus:MenuElement({id = "QRange", name = "Draw/Set AutoQ range:", value = 300,min = 175, max = 700, step = 1})
	self.Menu.Bonus:MenuElement({id = "blank", type = SPACE , name = "It can also Steal jungle! (OP)"})

	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})

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


function Nasus:__init()
	
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

function Nasus:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealE()
		self:MinRCast()
		self:Autofarm()
end

function Nasus:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Nasus:GetValidMinion(range)
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

function Nasus:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Nasus:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Nasus:CanCast(spellSlot)
	return self:IsReady(spellSlot) and self:CheckMana(spellSlot)
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

function Nasus:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Nasus:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Nasus:EnemyInRange(range)
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

function Nasus:Draw()
	if self.Menu.Drawings.DrawDamage:Value() then
    for i = 1, Game.HeroCount() do
      local target = Game.Hero(i)
      if target and target.isEnemy and not target.dead and target.visible then
        local barPos = target.hpBar
        local health = target.health
        local maxHealth = target.maxHealth
        local Qdmg = self:QDMG(target)
          Draw.Rect(barPos.x + (( (health - Qdmg) / maxHealth) * 100) + 25, barPos.y - 13, (Qdmg / maxHealth )*100, 10, Draw.Color(200, 255, 255, 255))
			end
		end
	end

	
	if self.Menu.Bonus.UseQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Farm ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 255, 255, 255))
			end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 650, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Bonus.UseQ:Value() then Draw.Circle(myHero.pos, self.Menu.Bonus.QRange:Value(), Draw.Color(220, 207, 27, 73)) end
end

function Nasus:CastSpell(spell,pos)
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

function Nasus:HpPred(unit, delay)
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

function Nasus:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

-----------------------------
-- COMBO
-----------------------------

function Nasus:Combo()
    if self.Menu.Combo.UseQ:Value() and self:CanCast(_Q) then
		local target = CurrentTarget(300)
		if target == nil then return end
	    if self:EnemyInRange(300) then
			    Control.CastSpell(HK_Q)
		    end
	    end

	if self.Menu.Combo.UseW:Value() and self:CanCast(_W) then
	local target = CurrentTarget(600)
    if target == nil then return end
		if self:EnemyInRange(600) and target then 
			    Control.CastSpell(HK_W, target)
            end
		end
 
	if self.Menu.Combo.UseE:Value() and self:CanCast(_E) then
	local target = CurrentTarget(650)
    if target == nil then return end
		if self:EnemyInRange(650) and target then 
			    Control.CastSpell(HK_E, target)
            end
		end
end

-----------------------------
-- HARASS
-----------------------------

function Nasus:Harass()
    local target = CurrentTarget(300)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(300) then
			    Control.CastSpell(HK_Q)
		    end
	    end

	if self.Menu.Harass.UseE:Value() and target and self:CanCast(_E) then
    local target = CurrentTarget(650)
    if target == nil then return end
		if self:EnemyInRange(650) and target then 
			    Control.CastSpell(HK_E, target)
		    end
	    end
    end
	
-----------------------------
-- Clear
-----------------------------

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

local function isValidTarget(obj,range)
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

function Nasus:Clear()
	if self.Menu.Clear.UseQ:Value() and self:CanCast(_Q) then
	for i = 1, Game.MinionCount() do
	local target = Game.Minion(i)
	if target and target.team == 300 or target.team ~= myHero.team then
			if myHero.pos:DistanceTo(target.pos) < 300 and target.isEnemy then
			if target then
				if self:QDMG(target) >= self:HpPred(target,1) then
				Control.CastSpell("Q")
				Control.Attack(target)
					end
				end
			end
		end
	end
	
	if self.Menu.Clear.UseE:Value() and self:CanCast(_E) then
	local eMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  isValidTarget(minion,650)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				eMinions[#eMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(450,400 + 48, eMinions)
		if BestHit >= self.Menu.Clear.EHit:Value() then
			Control.CastSpell(HK_E,BestPos)
		end
	end
end
end
end

-----------------------------
-- LASTHIT
-----------------------------

function Nasus:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local target = Game.Minion(i)
			if myHero.pos:DistanceTo(target.pos) < 200 and self.Menu.Lasthit.UseQ:Value() and not target.dead and target.isEnemy then
				if self:QDMG(target) >= self:HpPred(target,1) then
				Control.CastSpell("Q")
				Control.Attack(target)
				end
			end
		end
	end
end

-----------------------------
-- Bonus auto farm
-----------------------------

function Nasus:Autofarm()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local target = Game.Minion(i)
			if myHero.pos:DistanceTo(target.pos) < self.Menu.Bonus.QRange:Value() and self.Menu.Bonus.UseQ:Value() and target.isEnemy and not target.dead then
				if self:QDMG(target) >= self:HpPred(target,1) then
				Control.CastSpell("Q")
				Control.Attack(target)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

local function GetBuffIndexByName(unit,name)
  for i=1,unit.buffCount do
    local buff=unit:GetBuff(i)
    if buff.name==name then
      return i
    end
  end
end

function Nasus:QDMG(target)
local level = myHero:GetSpellData(_Q).level
return CalcPhysicalDamage(myHero, target, (myHero:GetBuff(GetBuffIndexByName(myHero,"NasusQStacks")).stacks + ({30, 50, 70, 90, 110})[level] + myHero.totalDamage))
end

function Nasus:EDMG()
    local level = myHero:GetSpellData(_E).level
	local edamage = (({55,95,135,175,215})[level] + 0.60 * myHero.ap)
	return edamage
end

function Nasus:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 650 
end

-----------------------------
-- Q KS
-----------------------------

function Nasus:KillstealQ()
	local target = CurrentTarget(300)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(300) then 
			local level = myHero:GetSpellData(_Q).level	
		   	local Qdamage = Nasus:QDMG(target)
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell("Q")
				Control.Attack(target)
				end
			end
end
end

-----------------------------
-- E KS
-----------------------------

function Nasus:KillstealE()
	local target = CurrentTarget(650)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(650) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, 650, E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Nasus:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_E) then
			    self:CastSpell(HK_E,castpos)
				end
			end
		end
end
end

-----------------------------
-- Min HP% to cast R
-----------------------------

function Nasus:MinRCast()
	if self.Menu.Combo.MinRCast:Value() and myHero.health<=myHero.maxHealth * self.Menu.Combo.MinRHealth:Value()/100 and self:CanCast(_R) then
		if self:EnemyInRange(700) then 
			local level = myHero:GetSpellData(_R).level	
			    Control.CastSpell(HK_R)
				end
			end
		end

Callback.Add("Load",function() _G[myHero.charName]() end)