if myHero.charName ~= "Draven" then return end

require "DamageLib"
require "MapPosition"
local RedPos = {Vector(410,183,424), Vector(14302,172,14388)}
local BluePos = {Vector(410,183,424)}

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

class "Draven"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/db/Element_of_Magma_profileicon.png"

function Draven:LoadSpells()

	Q = {Range = 550, Width = 0, Delay = 0.50, Speed = 20, Collision = true, aoe = false, Type = "line"}
	E = {Range = 1050, Width = 130, Delay = 0.40, Speed = 1600, Collision = false, aoe = true, Type = "line"}
	R = {Range = 20000, Width = 160, Delay = 0.80, Speed = 2000, Collision = false, aoe = false, Type = "line"}

end

function Draven:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Draven", name = "Kypo's Draven", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	-- self.Menu.Combo:MenuElement({id = "CatchQ", name = "Catch Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false, leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	-- self.Menu.Harass:MenuElement({id = "CatchQ", name = "Catch Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "UseE", name = "E", value = true, leftIcon = WIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
		
	self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseR", name = "Semi R", value = true, leftIcon = RIcon})
	self.Menu.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	self.Menu:MenuElement({id = "Baseult", name = "Baseult", type = MENU})
  	self.Menu.Baseult:MenuElement({type = MENU, id = "ultchamp", name = "Use ULT on:"})
  	for i, enemy in pairs(self:GetEnemyHeroes()) do
  	self.Menu.Baseult.ultchamp:MenuElement({id = enemy.charName, name = enemy.charName, value = false})
  	end
	self.Menu.Baseult:MenuElement({id = "Redside", name = "Enemy is RED side",value = false})
	self.Menu.Baseult:MenuElement({id = "Blueside", name = "Enemy is BLUE side",value = false})
	self.Menu.Baseult:MenuElement({id = "DontUlt", name = "Don't ult if pressed:", key = 32})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true, leftIcon = WIcon})
	self.Menu.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end	
	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = false, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = false, leftIcon = RIcon})
	end

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseE", name = "E", value = true, leftIcon = QIcon})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	self.Menu.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Snare, Knockup, Supression, Fear, Charm"})

	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = WIcon})
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


function Draven:__init()
	
	self:LoadSpells()
	self:LoadMenu()
	self:BaseUltData()
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

function Draven:vidapredicada(unit, time)
	if unit.health then return math.min(unit.maxHealth, unit.health+unit.hpRegen*(Game.Timer()-self.datadoenemigo[unit.networkID]+time)) end
end

function Draven:BaseUltData()
   	self.UltimateData = {
    ["Draven"] = {Delay = 0.4, Speed = 2000, Width = 160, Collision = true, Damage = function() return self:RDMG() end},
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

function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function Draven:pegoudanototal()
	local n = 0
	for i, damage in pairs(self.danoqpodev) do
    		n = n + damage
    	end
    	return n
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

function Draven:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:ComboW()
	end
	if self.Menu.Flee.fleeActive:Value() then
		self:Flee()
	end	
		self:BaseultR()
		self:BaseultB()
		self:KillstealE()
		self:KillstealR()
		self:RksCC()
		self:SpellonCCE()
		
end

function Draven:tempodechegarbase(unit, data)
	if data.Speed == math.huge and data.Delay ~= 0 then return data.Delay end
	local distance = unit.pos:DistanceTo(self.EnemySpawnPos.pos)
	local delay = data.Delay
	local missilespeed = data.Speed 
	return distance / missilespeed + delay
end

function Draven:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Draven:GetValidMinion(range)
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

function Draven:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Draven:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Draven:CanCast(spellSlot)
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

function Draven:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Draven:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Draven:EnemyInRange(range)
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

function Draven:Draw()
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 1100, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end			
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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			end
		end
		if self:CanCast(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, "circular" )
			Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
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

function Draven:GetRecallData(unit)
    	for i, recall in pairs(self.dadorecall) do
    		if recall.object.networkID == unit.networkID then
    			return {isRecalling = true, recall = recall.start+recall.duration-Game.Timer()}
	    	end
	end
	return {isRecalling = false, recall = 0}
end

function Draven:GetUltimateData(unit)
	return self.UltimateData[unit.charName]
end

function Draven:CastSpell(spell,pos)
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

function Draven:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

function Draven:ProcessRecall(unit, recall)
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

-----------------------------
-- BUFFS
-----------------------------

function Draven:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end
	
-----------------------------
-- COMBO
-----------------------------

function Draven:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	-- local qgrab = self:QGrab()
	    if self:EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q)
			-- self:QGrab()
		    end
	    end
	    end
		
function Draven:ComboW()	
	local target = CurrentTarget(1000)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if myHero.pos:DistanceTo(target.pos) > 700 then
			Control.CastSpell(HK_W)
		    end
	    end
end
-----------------------------
-- HARASS
-----------------------------

function Draven:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q)
		    end
	    end
		
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Harass.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			Control.CastSpell(HK_E, castpos)
		    end
	    end
    end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Draven:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({75,110,145,180,215})[level] + 0.5 * myHero.bonusDamage)
	return edamage
end

function Draven:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({250,350,500})[level] + 1.1 * myHero.bonusDamage)
	return rdamage
end

function Draven:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end


-----------------------------
-- E KS
-----------------------------

function Draven:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Draven:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_E) then
			Control.CastSpell(HK_E, castpos)
			end
			end
		end
	end
end

-----------------------------
-- R KS
-----------------------------

function Draven:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(2000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Draven:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end
end

-----------------------------
-- E Spell on CC
-----------------------------

function Draven:SpellonCCE()
    local target = CurrentTarget(1050)
	if target == nil then return end
	if self.Menu.isCC.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(1050) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			Control.CastSpell(HK_E, castpos)
			end
			end
		end
	end
end

-----------------------------
-- R KS on CC
-----------------------------

function Draven:RksCC()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if self.Menu.Killsteal.RCC["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = Draven:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end
end
end

function Draven:Flee()
    local target = CurrentTarget(20000)
	if target == nil then return end
	if self.Menu.Flee.UseR:Value() and self:CanCast(_R) then
		if self:EnemyInRange(20000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if target and (HitChance > 0 ) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end

-- function Draven:QGrab(particle, pos)
	-- for i = 0, Game.ParticleCount() do
		-- particle = Game.Particle(i)
		-- local dravenparticle = particle.pos
		-- local heropos = math.sqrt(DistTo(dravenparticle, myHero.pos))
		-- if particle.name == "Draven_Base_Q_reticle.troy" and heropos < 700 then
				-- if self-Menu.Combo.CatchQ:Value() and self:CanCast(_Q) then
				-- Control.SetCursorPos(dravenparticle)
				-- DelayAction(RightClick, dravenparticle.pos)
				-- end
				-- else if particle.name == "Draven_Base_Q_ReticleCatchSuccess" then
				-- print("Picked Axe!")
			-- end
		-- end
	-- end
-- end
		
-- and self:HasBuff(myHero, "DravenSpinning") or self:HasBuff(myHero, "dravenspinningleft")
		
-- Draven_Base_Q_activation.troy
-- Draven_Base_Q_Alt_mis.troy
-- Draven_Base_Q_buf.troy
-- Draven_Base_Q_catch_indicator.troy
-- Draven_Base_Q_crit_mis.troy
-- Draven_Base_Q_mis.troy
-- Draven_Base_Q_reticle.troy
-- Draven_Base_Q_reticle_self.troy
-- Draven_Base_Q_ReticleCatchSuccess.troy
-- Draven_Base_Q_tar.troy
	
	
	-- if myHero.attackData.state ~= 2 then
	-- MoveToParticle(dravenparticle)
	-- DelayAction(RightClick, dravenparticle.pos)
	-- Control.SetCursorPos(target)
	-- (RightClick)

function DistTo(firstpos, secondpos)
	local secondpos = secondpos or H.pos
	local distx = firstpos.x - secondpos.x
	local distyz = (firstpos.z or firstpos.y) - (secondpos.z or secondpos.y)
	local distf = (distx*distx) + (distyz*distyz)
	return distf
end

	
function MoveToParticle(position)
	if position ~= nil then
		if _G.SDK then
			_G.SDK.Orbwalker.ForceMovement = position
	else
		if _G.SDK then
			_G.SDK.Orbwalker.ForceMovement = nil
			end
		end
	end
end


--------- BASEULT DATA

function Draven:BaseultR()
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

function Draven:BaseultB()
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


function Draven:BaseultBlue()
		for i,pos in pairs(BluePos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end

function Draven:BaseultRed()
		for i,pos in pairs(RedPos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end

Callback.Add("Load",function() _G[myHero.charName]() end)