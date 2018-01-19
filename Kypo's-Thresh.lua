local Heroes = {"Thresh"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0.1","Kypos","8.1"

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


class "Thresh"

local HeroIcon = "https://i.pinimg.com/736x/1a/34/84/1a34847f568b4d3fd8de06540e29a838--thresh-sade.jpg"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/d5/Death_Sentence.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/44/Dark_Passage.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/71/Flay.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/c1/The_Box.png"
local IgniteIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f4/Ignite.png"

function Thresh:LoadSpells()

	Q = {Range = 1075, Width = 60, Delay = 0.50, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 950, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false, radius = 150}
	E = {Range = 400, Width = 80, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 450, Width = 80, Delay = 0.25, Speed = 1900, Collision = false, aoe = false, Type = "circular"}

end

function Thresh:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Thresh", name = "Kypo's Thresh", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "DelayQ", name = "Delay Q1 and Q2 (ms)", value = 0.8,min = 0.1,max = 0.8,step = 0.01})
	self.Menu.Combo:MenuElement({id = "MinQ", name = "Min Distance to Q", value = 1050,min = 200,max = 1075,step = 1})	
	self.Menu.Combo:MenuElement({id = "PullKey", name = "Pull Key",key = string.byte("5") })
	self.Menu.Combo:MenuElement({id = "PushKey", name = "Push Key",key = string.byte("6") })	
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Ultimate", name = "Ultimate", type = MENU})
	self.Menu.Ultimate:MenuElement({id = "Min", name = "Min enemies around", value = 2,min = 1, max = 5, step = 1, leftIcon = RIcon})

	self.Menu:MenuElement({id = "AutoW", name = "AutoW", type = MENU})
	self.Menu.AutoW:MenuElement({id = "Wmyself", name = "W myself when HP below ",value=25,min=5,max=50, step = 5, leftIcon = WIcon})
	self.Menu.AutoW:MenuElement({id = "savehp", name = "Save allies when HP below ", value = 20,min = 0, max = 100, step = 5, leftIcon = WIcon})
	self.Menu.AutoW:MenuElement({id = "shieldhp", name = "Shield allies on CC", value = 60 ,min = 0, max = 100, step = 5, leftIcon = WIcon})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})
	self.Menu.Killsteal:MenuElement({id = "UseIG", name = "Use Ignite", value = true, leftIcon = IgniteIcon})
	
	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "Enabled", name = "Enabled", value = true})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU, leftIcon = QIcon})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
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
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function Thresh:__init()
flashslot = self:getFlash()
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

local sqrt = math.sqrt
local function GetDistanceSqr(p1, p2)
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return (dx * dx + dz * dz)
end
local function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end
local function GetDistance2D(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end
local function ClosestToMouse(p1, p2) 
	if GetDistance(mousePos, p1) > GetDistance(mousePos, p2) then return p2 else return p1 end
end

function Thresh:getFlash()
	for i = 1, 5 do
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash" then
			return SUMMONER_1
		end
		if myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" then
			return SUMMONER_2
		end
	end
	return 0
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

function Thresh:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end	
	if self.Menu.isCC.Enabled:Value() then
		self:SpellonCCQ()
	end
	if self.Menu.AutoW.Wmyself:Value() then
		self:Autoshield()
	end
	if self.Menu.Killsteal.UseIG:Value() then
		self:UseIG()
	end
		self:KillstealQ()
		self:KillstealE()
		self:AutoW()
		self:Autoult()
		self:Edirections()
end

function Thresh:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Thresh:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Thresh:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Thresh:CanCast(spellSlot)
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

function Thresh:Autoshield()
	local pos = myHero.pos
	if self:CanCast(_W) and myHero.health<=myHero.maxHealth * self.Menu.AutoW.Wmyself:Value()/100 then 
	Control.CastSpell(HK_W, pos)
	end
end

function Thresh:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Thresh:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Thresh:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Thresh:UseIG()
    local target = CurrentTarget(600)
	if self.Menu.Killsteal.UseIG:Value() and target then 
		local IGdamage = 70 + 20 * myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_1) then
				if IGdamage >= Thresh:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_2) then
				if IGdamage >= Thresh:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

-----------------------------
-- DRAWINGS
-----------------------------

function Thresh:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1075, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 950, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 450, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage
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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.50 , 100, 1100,1900, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 18, 222, 33))
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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos,  E.ignorecol, E.Type )
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

function Thresh:CastSpell(spell,pos)
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

function Thresh:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function IsValidTarget(unit, range, onScreen)
    local range = range or 20000
    
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

function CountAllyEnemies(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if IsValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

function CountAlly(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if IsValidTarget(hero,range) and hero.team == myHero.team then
			N = N + 1
		end
	end
	return N	
end
-----------------------------
-- BUFFS
-----------------------------

function Thresh:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
function Thresh:GetEtarget(range)
	local result = nil
	local N = math.huge
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:isValidTarget(hero,range) and hero.isEnemy then
			local dmgtohero = getdmg("AA",hero,myHero) or 1
			local tokill = hero.health/dmgtohero
			if tokill < N or result == nil then
				N = tokill
				result = hero
			end
		end
	end
	return result
end

function CastEPush(target)
	if not isReady(_E) then return end
	local pos = target:GetPrediction(E.speed, E.delay)
	Control.CastSpell("E",pos)
end

function CastEPull(target)
	if not isReady(_E) then return end
	local pos = target:GetPrediction(2000, 0.25)
	pos = Vector(myHero.pos) + (Vector(myHero.pos) - Vector(pos)):Normalized()*400
	Control.CastSpell("E",pos)
end

function Thresh:isValidTarget(obj,range)
	range = range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end

function isReady(slot)
	return Game.CanUseSpell(slot) == READY
end

function Thresh:AutoW()
if isReady(_W) then
		for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)	
			if self:isValidTarget(hero,900) and hero.isAlly then
				if hero.health/hero.maxHealth <= self.Menu.AutoW.shieldhp:Value()/100 and self:IsImmobileTarget(hero) then
					Control.CastSpell("W",hero.pos)--hero:GetPrediction(W.speed,W.delay)
				end
				if hero.health/hero.maxHealth <= self.Menu.AutoW.savehp:Value()/100 and self:CountEnemy(hero.pos,900) > 0 then
					Control.CastSpell("W",hero.pos)
				end
			end
		end	
	end
end

function isQ1()
	return myHero:GetSpellData(_Q).name == "ThreshQ"
end

function isQ2()
	return myHero:GetSpellData(_Q).name == "ThreshQLeap"
end

function Thresh:CountEnemy(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:isValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

function Thresh:UltHit(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:isValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy then
			N = N + 1
		end
	end
	return N	
end

function Thresh:Autoult()
	if isReady(_R) and self:UltHit(myHero.pos,225) >= self.Menu.Ultimate.Min:Value() then
		Control.CastSpell("R")
	end
end
-----------------------------
-- COMBO
-----------------------------

function Thresh:Edirections()
	if self.Menu.Combo.PushKey:Value() then
		local etarget = self:GetEtarget(450)
		if etarget then 
			CastEPush(etarget)
		end
	elseif self.Menu.Combo.PullKey:Value()then
		local etarget = self:GetEtarget(450)
		if etarget then 
			CastEPull(etarget)
		end
	end
end

function Thresh:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.50 , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) and target.distance <= self.Menu.Combo.MinQ:Value() and Game.Timer() - myHero:GetSpellData(_Q).castTime >= self.Menu.Combo.DelayQ:Value() then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end

end

-----------------------------
-- KILLSTEAL
-----------------------------

function Thresh:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({80, 120, 160, 200, 240})[level] + 0.50 * myHero.ap)
	return qdamage
end

function Thresh:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({65, 95, 125, 155, 185})[level] + 0.4 * myHero.ap)
	return edamage
end

function Thresh:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

function Thresh:KillstealQ()
-----------------------------
-- Q KS
-----------------------------

	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.50 , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Thresh:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

-----------------------------
-- E KS
-----------------------------

function Thresh:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and self:CanCast(_E) then
		if self:EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Thresh:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_E) then
			    Control.CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

-----------------------------
-- Q Spell on CC
-----------------------------

function Thresh:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.isCC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.50 , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and target.distance <= self.Menu.Combo.MinQ:Value() and Game.Timer() - myHero:GetSpellData(_Q).castTime >= self.Menu.Combo.DelayQ:Value() and not isQ2() then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)