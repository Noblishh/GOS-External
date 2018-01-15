local Heroes = {"Yasuo"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypo's","8.1"

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
	

class "Yasuo"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/97/Blood_Moon_Yasuo_profileicon.png"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e5/Steel_Tempest.png"
local Q3Icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Steel_Tempest_3.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/61/Wind_Wall.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f8/Sweeping_Blade.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/c6/Last_Breath.png"

function Yasuo:LoadSpells()

	Q = {Range = 475, Width = 20, Delay = 0.40, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	Q3 = {Name = "YasuoQ3W", Range = 900, Width = 90, Delay = 0.50, Speed = 1500, Collision = false, aoe = false, Type = "line"}
	W = {Range = 400, Width = 90, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 475, Width = 80, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1200, Width = 1, Delay = 0.20, Speed = 10000, Collision = false, aoe = false, Type = "line"}

end

function Yasuo:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Yasuo", name = "Kypo's Yasuo", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false, leftIcon = EIcon})
	-- self.Menu.Combo:MenuElement({id = "EUnderTurret", name = "Use E Under Turret", value = false, leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Clear:MenuElement({id = "Q3Clear", name = "Use Q3 If Hit X Minion ", value = 3, min = 1, max = 5, step = 1, leftIcon = Q3Icon})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "AutoR", name = "Auto R Champs", type = MENU})
	self.Menu.AutoR:MenuElement({id = "AutoRXEnable", name = "R", value = true, leftIcon = RIcon})
	self.Menu.AutoR:MenuElement({id = "AutoRX", name = "Use R if champs are UP", value = 3, min = 2, max = 5, step = 1, leftIcon = RIcon})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Lasthit:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseE", name = "E on minions", value = true, leftIcon = EIcon})
	self.Menu.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E (OP!)", value = true, leftIcon = EIcon})
	
	self.Menu.Killsteal:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.isCC:MenuElement({id = "UseQ3", name = "Q3", value = true, leftIcon = Q3Icon})
	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU, leftIcon = QIcon})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU, leftIcon = WIcon})
    self.Menu.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Yasuo:__init()
	
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

function GetDistanceSqr(a, b)
if a.z ~= nil and b.z ~= nil then
    local x = (a.x - b.x);
    local z = (a.z - b.z);
    return x * x + z * z;
else
  local x = (a.x - b.x);
  local y = (a.y - b.y);
  return x * x + y * y;
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

function Yasuo:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Flee.fleeActive:Value() then
		self:Flee()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Jungle()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealE()
		self:SpellonCCQ3()
		self:AutoRX()
		self:RksKnockedUp()
		self:ClearQ3Count()
end

function Yasuo:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Yasuo:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Yasuo:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Yasuo:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Yasuo:CanCast(spellSlot)
	return self:IsReady(spellSlot) and self:CheckMana(spellSlot)
end

function EnableMovement()
	SetMovement(true)
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.2)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.10,{pos})
end

function Yasuo:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function Yasuo:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Yasuo:EnemyInRange(range)
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

function Yasuo:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 900, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 475, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1200, self.Menu.Drawings.R.Width:Value(), self.Menu.Drawings.R.Color:Value()) end
			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
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
    if self:CanCast(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 255, 000, 255))
			end
		end
		if self:CanCast(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if self:CanCast(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			end
		end
		if self:CanCast(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

function Yasuo:CastSpell(spell,pos)
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

function Yasuo:HpPred(unit, delay)
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

function Yasuo:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Yasuo:IsKnockedUp(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 29 or buff.type == 30 or buff.type == 39) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Yasuo:CountKnockedUpEnemies(range)
		local count = 0
		local rangeSqr = range * range
		for i = 1, Game.HeroCount()do
		local hero = Game.Hero(i)
			if hero.isEnemy and hero.alive and GetDistanceSqr(myHero.pos, hero.pos) <= rangeSqr then
			if Yasuo:IsKnockedUp(hero)then
			count = count + 1
    end
  end
end
return count
end

function HasBuff(unit, buffName)
		for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name:lower() == buffName:lower()and buff.count > 0 then
				return true
			end
		end
	return false
end


function Yasuo:AutoRX()
		if self:CanCast(_R) and self.Menu.AutoR.AutoRXEnable:Value() then
		if Yasuo:CountKnockedUpEnemies(1400) >= self.Menu.AutoR.AutoRX:Value() then
		Control.CastSpell(HK_R)
end
end
end

-----------------------------
-- Flee
-----------------------------

function Yasuo:Flee()
	if self:CanCast(_E) then
		local level = myHero:GetSpellData(_E).level	
		local target = self:EnemyInRange(475)
  		for i = 1, Game.MinionCount()do
		local minion = Game.Minion(i)
		if minion.isEnemy and minion.alive and minion.isTargetable and not HasBuff(minion, "YasuoDashWrapper") then
			if myHero.pos:DistanceTo(minion.pos) < 475 and self.Menu.Flee.UseE:Value() then
				Control.CastSpell(HK_E,minion.pos)
        end
        end
        end
        end
        end

function Yasuo:GetGapCloseEnemiesHero(pos, range, target)
for i = 1, Game.HeroCount()do
  local hero = Game.Hero(i)
  if hero.isEnemy and hero ~= target and hero.alive and hero.isTargetable then
    if GetDistanceSqr(hero.pos, pos) <= 475 and GetDistanceSqr(myHero.pos, hero.pos) < 475 and not HasBuff(hero, "YasuoDashWrapper")then
      return hero
    end
  end
return false
end
end

function Yasuo:GetGapCloseEnemiesMinions(pos, range)
for i = 1, Game.MinionCount()do
  local minion = Game.Minion(i)
  if minion.isEnemy and minion.alive and minion.isTargetable then
    if GetDistanceSqr(minion.pos, pos) <= 475 and GetDistanceSqr(myHero.pos, minion.pos) < 475 and not HasBuff(minion, "YasuoDashWrapper") then
      return minion
    end
  end
return false
end
end

-----------------------------
-- COMBO
-----------------------------

function Yasuo:Combo()
    local target = CurrentTarget(900)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    Control.CastSpell(HK_Q,castpos)
			end
	    end
    end

    local target = CurrentTarget(475)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(475) and not HasBuff(target, "YasuoDashWrapper") then
			    Control.CastSpell(HK_E,target)
		    end
	    end
    end
end

-----------------------------
-- HARASS
-----------------------------

function Yasuo:Harass()
    local target = CurrentTarget(900)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range ,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,target)
				else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end
    end

end
-----------------------------
-- JUNGLE
-----------------------------

function Yasuo:Jungle()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_Q) then 
			if self.Menu.Clear.UseQ:Value() and minion and self:CanCast(_Q) then
				if ValidTarget(minion, 475) and myHero.pos:DistanceTo(minion.pos) < 475 then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

-----------------------------
-- LASTHIT
-----------------------------

function Yasuo:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
			if myHero.pos:DistanceTo(minion.pos) < 475 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end

if self:CanCast(_E) then
		local level = myHero:GetSpellData(_E).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = (({60,70,80,90,100})[level] + 0.2 * myHero.totalDamage)
			if minion.pos:DistanceTo(myHero.AttackRange) < 475 and self.Menu.Lasthit.UseE:Value() and minion.isEnemy and not HasBuff(minion, "YasuoDashWrapper") then
				if Edamage >= minion.health and self:CanCast(_E) then
				Control.CastSpell(HK_E,minion.pos)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Yasuo:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
	return qdamage
end

function Yasuo:EDMG()
    local level = myHero:GetSpellData(_W).level
    local edamage = (({60,70,80,90,100})[level] + 0.2 * myHero.totalDamage)
	return edamage
end

function Yasuo:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 200, 350})[level] + 1.5 * myHero.totalDamage)
	return rdamage
end

function Yasuo:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-----------------------------
-- Q KS
-----------------------------
function Yasuo:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Yasuo:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				else if self:EnemyInRange(900) then 
				if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "YasuoQ3W") then
				Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	end
	end
	end

	function Yasuo:KillstealE()
	local target = CurrentTarget(475)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(475) then 
			local level = myHero:GetSpellData(_E).level	
		   	local Edamage = Yasuo:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 1 and not HasBuff(target, "YasuoDashWrapper") then
			    Control.CastSpell(HK_E,target)
				end
			end
		end
	end

-----------------------------
-- Q3 Spell on CC
-----------------------------

function Yasuo:SpellonCCQ3()
    local target = CurrentTarget(900)
	if target == nil then return end
	if self.Menu.isCC.UseQ3:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and HasBuff(myHero, "YasuoQ3W") then
			    self:CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R KS on CC
-----------------------------

function Yasuo:RksKnockedUp()
    local target = CurrentTarget(1200)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(1200) then 
			local ImmobileEnemy = self:IsKnockedUp(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Yasuo:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

function VectorPointProjectionOnLineSegment(v1, v2, v)
  local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
  local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
  local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
  local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
  local isOnSegment = rS == rL
  local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
  return pointSegment, pointLine, isOnSegment
end


function Yasuo:ClearQ3Count(range)
for i = 1, Game.MinionCount()do
  local minion = Game.Minion(i)
  if minion.isEnemy and minion.alive and minion.isTargetable and GetDistanceSqr(myHero.pos, minion.pos) <= 900 then
    if Yasuo:GetMinionCollision(minion.pos, 60) >= self.Menu.Clear.Q3Clear:Value()then
      return minion
    end
  end
end
return false
end

function Yasuo:GetMinionCollision(castPos, width, exclude)
local Count = 0
local w = (width + 48) * (width + 48)
for i = Game.MinionCount(), 1, - 1 do
  local minion = Game.Minion(i)
  if minion.isEnemy and minion ~= exclude and minion.alive and minion.isTargetable  then
    local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHero.pos, castPos, minion.pos)
    if isOnSegment and GetDistanceSqr(pointSegment, minion.pos) < w then
      Count = Count + 1
    end
  end
end
return Count
end

Callback.Add("Load",function() _G[myHero.charName]() end)