local Heroes = {"Jinx"}

require "DamageLib"
require "MapPosition"

local RedPos = {Vector(14350.0000,0,14350.0000),Vector(14350.0000,0,14350.0000)}
local BluePos = {Vector(400.0000,0,400.0000),Vector(400.0000,0,400.0000)}

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.1"

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

class "Jinx"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/71/Get_Excited%21.png"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/dd/Switcheroo%21.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/76/Zap%21.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/bb/Flame_Chompers%21.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a8/Super_Mega_Death_Rocket%21.png"

function Jinx:LoadSpells()

	Q = {Range = 700}
	W = {Range = 1450, Width = 40, Delay = 0.37, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	E = {Range = 900, Width = 50, Delay = 0.25, Speed = 1600, Collision = false, aoe = false}
	R = {Range = 20000, Width = 140, Delay = 0.95, Speed = 1700, Collision = true, aoe = false, Type = "line"}

end


function Jinx:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Jinx", name = "Kypo's Jinx", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	-- self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	-- self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	-- self.Menu.Clear:MenuElement({id = "UseQXminion", name = "Use Q2 on X minions", value = true, leftIcon = QIcon})
	-- self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Flee", name = "R key", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseR", name = "R", value = true, leftIcon = RIcon})
	self.Menu.Flee:MenuElement({id = "fleeActive", name = "R key (Global)", key = string.byte("T")})
	
	-- self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	-- self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	-- self.Menu.Lasthit:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	-- self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Baseult", name = "Baseult", type = MENU})
  	self.Menu.Baseult:MenuElement({type = MENU, id = "ultchamp", name = "Use ULT on:"})
  	for i, enemy in pairs(self:GetEnemyHeroes()) do
  	self.Menu.Baseult.ultchamp:MenuElement({id = enemy.charName, name = enemy.charName, value = false})
  	end
	self.Menu.Baseult:MenuElement({id = "Redside", name = "Enemy is RED side",value = false})
	self.Menu.Baseult:MenuElement({id = "Blueside", name = "Enemy is BLUE side",value = false})
	self.Menu.Baseult:MenuElement({id = "DontUlt", name = "Don't ult if pressed:", key = 32})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Killsteal:MenuElement({id = "UseRCC", name = "R on CC Only", value = true, leftIcon = RIcon})
	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = false, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseE", name = "E", value = true, leftIcon = QIcon})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Taunt, Charm, Knockup"})

	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU, leftIcon = WIcon})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	-- Baseult
	-- self.Menu.Drawings:MenuElement({id = "BaseUlt", name = "Draw Baseult range", type = MENU, leftIcon = RIcon})
    -- self.Menu.Drawings.BaseUlt:MenuElement({id = "Red", name = "Red Side", value = true})       
    -- self.Menu.Drawings.BaseUlt:MenuElement({id = "Blue", name = "Blue Side", value = true})       
    -- self.Menu.Drawings.BaseUlt:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    -- self.Menu.Drawings.BaseUlt:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Jinx:__init()
	self:BaseUltData()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	Callback.Add("ProcessRecall", function(unit, recall) self:ProcessRecall(unit, recall) end)
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

function Jinx:ProcessRecall(unit, recall)
	if not unit.isEnemy then return end
	if recall.isStart then
    		table.insert(self.dadorecall, {object = unit, start = Game.Timer(), duration = (recall.totalTime*0.001)})
    	else
      	for i, rc in pairs(self.dadorecall) do
        	if rc.object.networkID == unit.networkID then
          		table.remove(self.dadorecall, i)
        	end
      	end
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

function Jinx:GetRecallData(unit)
    	for i, recall in pairs(self.dadorecall) do
    		if recall.object.networkID == unit.networkID then
    			return {isRecalling = true, recall = recall.start+recall.duration-Game.Timer()}
	    	end
	end
	return {isRecalling = false, recall = 0}
end

function Jinx:GetUltimateData(unit)
	return self.UltimateData[unit.charName]
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
end


function Jinx:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:ComboQ()
	end
	if self.Menu.Flee.fleeActive:Value() then
		self:Flee()
	end
--	if self.Menu.Lasthit.lasthitActive:Value() then
--		self:Lasthit()
--	end
		self:KillstealW()
		self:KillstealR()
		self:SpellonCCE()
		self:RksCC()
		self:BaseultR()
		self:BaseultB()
end

function Jinx:vidapredicada(unit, time)
	if unit.health then return math.min(unit.maxHealth, unit.health+unit.hpRegen*(Game.Timer()-self.datadoenemigo[unit.networkID]+time)) end
end


function Jinx:BaseUltData()
   	self.UltimateData = {
    ["Jinx"] = {Delay = 0.4, Speed = 1700, Width = 140, Damage = function(source, target) return getdmg("R", target, source, 2) end},
   	}
	self.tempodechegar = 0
	self.Caras, self.dadorecall, self.datadoenemigo, self.danoqpodev = {}, {}, {}, {}
	for i = 1, Game.HeroCount() do
	  	local unit = Game.Hero(i)
  	  	if unit.isMe then 
  	    		goto continue
  	  	end
  	  	if unit.isEnemy then 
  	    		self.datadoenemigo[unit.networkID] = 0
  	    		table.insert(self.Caras, unit)
  	  	end
  	  	::continue::
    	end
    	for i = 1, Game.ObjectCount() do
  	  	local object = Game.Object(i)
  	  	if object.isAlly or object.type ~= Obj_AI_SpawnPoint then 
  	    		goto continue
  	  	end
  	  	self.EnemySpawnPos = object
  	  	break
  	  	::continue::
    	end
end

function Jinx:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Jinx:GetValidMinion(range)
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

function Jinx:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Jinx:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Jinx:CanCast(spellSlot)
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

function Jinx:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Jinx:pegoudanototal()
	local n = 0
	for i, damage in pairs(self.danoqpodev) do
    		n = n + damage
    	end
    	return n
end

function Jinx:tempodechegarbase(unit, data)
	if data.Speed == math.huge and data.Delay ~= 0 then return data.Delay end
	local distance = unit.pos:DistanceTo(self.EnemySpawnPos.pos)
	local delay = data.Delay
	local missilespeed = data.Speed 
	if unit.charName == "Jinx" then
		missilespeed = distance > 1350 and (2295000 + (distance - 1350) * 2200) / distance or data.Speed
    	end
	return distance / missilespeed + delay
end


function Jinx:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Jinx:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

-----------------------------
-- MANA CHECK
-----------------------------

function Jinx:CheckMana(spellSlot)
	if myHero:GetSpellData(spellSlot).mana < myHero.mana then
		return true
	else
		return false
	end
end

-----------------------------
-- DRAWINGS
-----------------------------

function Jinx:Draw()
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 1450, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 900, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end

			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = RDamage 
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
		if self:CanCast(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, not W.ignorecol, W.Type )
			end
		end
		if self:CanCast(_R) then
			local target = CurrentTarget(2000)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Jinx:CastSpell(spell,pos)
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

function Jinx:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

-----------------------------
-- KILLSTEAL DMG
-----------------------------


function Jinx:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70, 120, 170, 220, 270})[level] + 1.0 * myHero.ap)
	return wdamage
end

function Jinx:RDMG()
    local level = myHero:GetSpellData(_R).level
	local target = CurrentTarget(2800)
	if target == nil then return end
	local rdamage = (({250, 350, 500})[level] + 1.5 * myHero.totalDamage + 0.25 * (target.maxHealth - target.health))
	return rdamage
end

function Jinx:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-----------------------------
-- BUFFS
-----------------------------

function Jinx:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Jinx:IsCC(enemy)
	for i = 0, enemy.buffCount do
		local buff = enemy:GetBuff(i);
		if (buff.type == 5 or buff.type == 29 or buff.type == 9) then
			return true
		end
	end
	return false
end

-----------------------------
-- COMBO
-----------------------------

function Jinx:Combo()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    self:CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Jinx:ComboQ()	
	local target = CurrentTarget(700)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	local qrange = myHero:GetSpellData(_Q).range
	    if myHero.pos:DistanceTo(target.pos) > qrange and myHero:GetSpellData(_Q).toggleState == 1 then
			Control.CastSpell(HK_Q)
		else if myHero.pos:DistanceTo(target.pos) < qrange and myHero:GetSpellData(_Q).toggleState == 2 then
			Control.CastSpell(HK_Q)
		    end
	    end
end
end

-----------------------------
-- HARASS
-----------------------------

function Jinx:Harass()
    local target = CurrentTarget(1400)
    if target == nil then return end
    if self.Menu.Harass.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(1400) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    self:CastSpell(HK_W,castpos)
		    end
	    end
    end
end

-----------------------------
-- W KS
-----------------------------

function Jinx:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, not W.ignorecol, W.Type )
		   	local Wdamage = Jinx:WDMG()
			if Wdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_W) then
			    self:CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R KS
-----------------------------

function Jinx:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(2000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	local Rdamage = Jinx:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Jinx:Flee()
    local target = CurrentTarget(20000)
	if target == nil then return end
	if self.Menu.Flee.UseR:Value() and self:CanCast(_R) then
		if self:EnemyInRange(20000) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range, R.Speed, myHero.pos, not R.ignorecol, R.Type )
			if (HitChance > 0 ) and target then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end

-----------------------------
-- E Spell on CC
-----------------------------

function Jinx:SpellonCCE()
    local target = CurrentTarget(900)
	if target == nil then return end
	if self.Menu.isCC.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, 900,E.Speed, myHero.pos, E.ignorecol, E.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    self:CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R KS on CC
-----------------------------

function Jinx:RksCC()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if self.Menu.Killsteal.UseRCC:Value() and self:CanCast(_R) then
		if self:EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = Jinx:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

--------- BASEULT DATA

function Jinx:BaseultR()
	if not self.Menu.Baseult.Redside:Value() or myHero.dead or not self:CanCast(_R) then return end
	for i, enemy in pairs(self.Caras) do
		if enemy.visible then
			self.datadoenemigo[enemy.networkID] = Game.Timer()
		end
	end
	for i, enemy in pairs(self.Caras) do
		if enemy.valid and not enemy.dead and self.Menu.Baseult.ultchamp[enemy.charName]:Value() and self:GetRecallData(enemy).isRecalling then
			local tempodechegar = self:tempodechegarbase(myHero, self:GetUltimateData(myHero))
			local recall = self:GetRecallData(enemy).recall
            		if recall >= tempodechegar then
            			self.danoqpodev[myHero.networkID] = self:GetUltimateData(myHero).Damage(myHero, enemy)
            		else
            			self.danoqpodev[myHero.networkID] = 0
            		end
            		if self:pegoudanototal() < self:vidapredicada(enemy, recall) then return end
            		self.tempodechegar = tempodechegar
            		if recall - tempodechegar > 0.1 or self.Menu.Baseult.DontUlt:Value() then return end
					self:BaseultRed()
            		self.tempodechegar = 0
        	end
    	end
end

function Jinx:BaseultB()
	if not self.Menu.Baseult.Blueside:Value() or myHero.dead or not self:CanCast(_R) then return end
	for i, enemy in pairs(self.Caras) do
		if enemy.visible then
			self.datadoenemigo[enemy.networkID] = Game.Timer()
		end
	end
	for i, enemy in pairs(self.Caras) do
		if enemy.valid and not enemy.dead and self.Menu.Baseult.ultchamp[enemy.charName]:Value() and self:GetRecallData(enemy).isRecalling then
			local tempodechegar = self:tempodechegarbase(myHero, self:GetUltimateData(myHero))
			local recall = self:GetRecallData(enemy).recall
            		if recall >= tempodechegar then
            			self.danoqpodev[myHero.networkID] = self:GetUltimateData(myHero).Damage(myHero, enemy)
            		else
            			self.danoqpodev[myHero.networkID] = 0
            		end
            		if self:pegoudanototal() < self:vidapredicada(enemy, recall) then return end
            		self.tempodechegar = tempodechegar
            		if recall - tempodechegar > 0.1 or self.Menu.Baseult.DontUlt:Value() then return end
					self:BaseultBlue()
            		self.tempodechegar = 0
        	end
    	end
end


function Jinx:BaseultBlue()
		for i,pos in pairs(BluePos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end

function Jinx:BaseultRed()
		for i,pos in pairs(RedPos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end

Callback.Add("Load",function() _G[myHero.charName]() end)