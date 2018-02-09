local Heroes = {"Orianna"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib" 
local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.3"
local EDMG = {}

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

---------------------------------------------------------------------------------------
-- Orianna
---------------------------------------------------------------------------------------

class "Orianna"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/b0/OriannaSquare.png"

function Orianna:LoadSpells()

	Q = {Range = 825, Width = 40, Delay = 0.40, Speed = 1200, Collision = false, aoe = false, Type = "circular"}
	W = {Delay = 0.10, Speed = 1200, Collision = false, aoe = false, Type = "circular", Radius = 250}
	E = {Range = 1100, Width = 40, Delay = 0.35, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Delay = 0.35, Speed = 1200, Collision = false, aoe = false, Type = "circular", Radius = 325}

end

function Orianna:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Orianna", name = "Kypo's Orianna", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Combo:MenuElement({id = "Rkey", name = "R Key",  key = string.byte("T")})
	self.Menu.Combo:MenuElement({id	= "ShieldMinHealth", name="Min Health -> %",value=30,min=0,max=100})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "QCount", name = "Use Q on X minions", value = 3, min = 1, max = 4, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Killsteal:MenuElement({id = "Ignite", name = "Ignite", value = true})
	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS on: ", value = false, type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end

	self.Menu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.Menu.Misc:MenuElement({id = "UseR", name = "R", value = true})
	self.Menu.Misc:MenuElement({id = "RCount", name = "Use R on X targets", value = 2, min = 1, max = 5, step = 1})
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
    self.Menu.Items:MenuElement({id = "Zhonya", name = "Zhonya", value = true})
    self.Menu.Items:MenuElement({id = "ZhonyaHp", name = "Min HP",value=10,min=1,max=30})	
	

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	
		self.Menu:MenuElement({id = "WomboCombo", name = "Wombo Combo", type = MENU})
    self.Menu.WomboCombo:MenuElement({id = "AutoE", name = "Auto E on dashing Allys", value = true})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	--Ball
	self.Menu.Drawings:MenuElement({id = "B", name = "Draw R Range on Ball", type = MENU})
    self.Menu.Drawings.B:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.B:MenuElement({id = "Width", name = "Width", value = 5, min = 1, max = 5, step = 1})
    self.Menu.Drawings.B:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 87, 51)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Orianna:__init()
	
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

function Orianna:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:ComboW()
		self:BallMe()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	if self.Menu.Combo.Rkey:Value() then
		self:RKey()
	end		
	if self.Menu.WomboCombo.AutoE:Value() then
		self:AutoEDashingAllys()
	end		
		self:KillstealQ()
		self:KillstealW()
		self:KillstealR()
		self:Items()
		self:Autoshield()
		self:AutoultMe()
		self:Autoult1Ally()
		self:AutoultBall()
		self:IgniteSteal()
		self:Ball()
	
	end

	function Orianna:Ball()
		for i = 1, Game.ParticleCount() do 
			local particle = Game.Particle(i)
			if particle.name == "Orianna_Base_Q_yomu_ring_green.troy" then 
				ball = particle.pos 
				break
			end
		end	
		if HasBuff(myHero, "orianaghostself") then 
			ball = ball
		else
			for i = 1, Game.HeroCount() do
				local hero = Game.Hero(i)
				if HasBuff(hero, "orianaghost") then 
					ball = hero.pos 
					break
				end
			end
		end
	end
	
function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

local function GetDistanceSqr(p1, p2)
	    local dx, dz = p1.x - p2.x, p1.z - p2.z 
	    return dx * dx + dz * dz
	end

local function GetDistance(p1, p2)
		return sqrt(GetDistanceSqr(p1, p2))
	end

local function GetDistance2D(p1,p2)
		return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
	end

function Orianna:GetValidMinion(range)
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

function Orianna:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Orianna:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Orianna:CanCast(spellSlot)
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

function Orianna:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Orianna:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Orianna:EnemyInRange(range)
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

function Orianna:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.B.Enabled:Value() and self:CanCast(_R) and not HasBuff(myHero, "orianaghostself") then 
Draw.Circle(ball, 400, self.Menu.Drawings.B.Width:Value(), self.Menu.Drawings.B.Color:Value()) 
	else if self.Menu.Drawings.B.Enabled:Value() and self:CanCast(_R) and HasBuff(myHero, "orianaghostself") then
	Draw.Circle(myHero.pos, 400, self.Menu.Drawings.B.Width:Value(), self.Menu.Drawings.B.Color:Value()) 
	end 
end
			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + RDamage + EDamage
				if damage > hero.health then
					Draw.Text("KILLABLE", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(200,255,255,255))
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
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
end
end

function Orianna:CastSpell(spell,pos)
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

function Orianna:HpPred(unit, delay)
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

function Orianna:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Orianna:EStacks(unit)
	if not unit then return 0 end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name and buff.name:lower() == "Oriannaexpungemarker" and buff.count > 0 and buff.expireTime >= Game.Timer() then
			return buff.count
		end
	end
	return 0
end

-----------------------------
-- COMBO
-----------------------------

function Orianna:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(1300) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
			end
		    end
	    end
	    end
function Orianna:ComboW()
	local target = CurrentTarget(1300)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
			if ball and target.pos:DistanceTo(ball) < 250 then
				Control.CastSpell(HK_W)
			else if not ball then return end
			end
		    end
			
end
	
function Orianna:BallMe()
	local target = CurrentTarget(300)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
			if myHero.pos:DistanceTo(target.pos) < 250 then
				Control.CastSpell(HK_W)
			end
		    end
	    end
	    
function Orianna:Autoshield()
    local target = CurrentTarget(1000)
	if target == nil then return end
	if self.Menu.Combo.UseE:Value() and self:CanCast(_E) and myHero.health<=myHero.maxHealth * self.Menu.Combo.ShieldMinHealth:Value()/100 then
	if self:EnemyInRange(1000) then 
	Control.CastSpell(HK_E, myHero)
	end
	end
end


-----------------------------
-- Clear
-----------------------------

function Orianna:Clear()
	if self:CanCast(_Q) then
	local qMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  isValidTarget(minion,825)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				qMinions[#qMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(825, 250, qMinions)
		if BestHit >= self.Menu.Clear.QCount:Value() and self.Menu.Clear.UseQ:Value() then
			Control.CastSpell(HK_Q,BestPos)
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
-- LASTHIT
-----------------------------

function Orianna:Lasthit()
	if self:CanCast(_Q) and self.Menu.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Orianna:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < 825 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= self:HpPred(minion,1) then
			    self:CastSpell(HK_Q,minion)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Orianna:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({60,90,120,150,180})[level] + 0.5 * myHero.ap)
	return qdamage
end

function Orianna:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({60,105,150,195,240})[level] + 0.7 * myHero.ap)
	return wdamage
end

function Orianna:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({150,225,300})[level] + 0.7 * myHero.ap)
	return rdamage
end


function isValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end

-----------------------------
-- Q KS
-----------------------------

function Orianna:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Orianna:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < 500 then
			if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
			else if target.pos:DistanceTo(myHero.pos) > 500 then
				Control.CastSpell(HK_E, myHero)
				return
				end
			end
		end
	end
end
end
end

-----------------------------
-- W KS
-----------------------------

function Orianna:KillstealW()
	local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.Killsteal.UseW:Value() and target and self:CanCast(_W) then
		   	local Wdamage = Orianna:WDMG()
			if Wdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if myHero.pos:DistanceTo(target.pos) < 220 and HasBuff(myHero, "orianaghostself") then
			    Control.CastSpell(HK_W)
			else if ball and ball:DistanceTo(target.pos) < 150 then
				Control.CastSpell(HK_W)
			else if myHero.pos:DistanceTo(target.pos) < 220 and not HasBuff(myHero, "orianaghostself") then
			    Control.CastSpell(HK_E, myHero)
			else for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)
				if hero.isAlly and HasBuff(hero, "orianaghost") then
				Control.CastSpell(HK_W)
			else if not ball then return end
				end
			end
		end
	end
	end
	end
	end
	end
	
-----------------------------
-- R KS
-----------------------------

function Orianna:KillstealR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) and target then
		   	local Rdamage = Orianna:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if myHero.pos:DistanceTo(target.pos) < 380 and HasBuff(myHero, "orianaghostself") then
			    Control.CastSpell(HK_R)
			else if ball and target.pos:DistanceTo(ball) < 380 then
				Control.CastSpell(HK_R)
			else if ball and myHero.pos:DistanceTo(target.pos) < 380 and target.pos:DistanceTo(ball) > 380 then
				Control.CastSpell(HK_E, myHero)
			else if not HasBuff(myHero, "orianaghostself") and ball and myHero.pos:DistanceTo(ball) > 380 and myHero.pos:DistanceTo(target.pos) < 380 then
				Control.CastSpell(HK_E, myHero)
			else for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)
				if hero.isAlly and HasBuff(hero, "orianaghost") and hero.pos:DistanceTo(target.pos) < 250 then
				Control.CastSpell(HK_R)
			else if not ball then return end
				end
			end
		end
		end
	end
	end
	end
	end
	end


function Orianna:Items()
    local target = CurrentTarget(500)
	if target == nil then return end
		if self.Menu.Items.Zhonya:Value() and myHero.pos:DistanceTo(target.pos) < 500 and myHero.health<=myHero.maxHealth * self.Menu.Items.ZhonyaHp:Value()/100 then
		local Zhonya = GetInventorySlotItem(3157) or GetInventorySlotItem(2421)
		if Zhonya then
			Control.CastSpell(HKITEM[Zhonya])
		end
	end
end

function Orianna:IgniteSteal()
	local target = CurrentTarget(600)
	if target == nil then return end
	if self.Menu.Killsteal.Ignite:Value() and target then
		if self:EnemyInRange(600) then 
			local IgniteDMG = 50+20*myHero.levelData.lvl
			if IgniteDMG >= self:HpPred(target,1) + target.hpRegen * 3 then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and self:IsReady(SUMMONER_1) then
            Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and self:IsReady(SUMMONER_2) then
            Control.CastSpell(HK_SUMMONER_2, target)				
			end
			end
		end
	end
	end

function Orianna:EnemiesNear(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:EnemiesNearAlly(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range + hero.boundingRadius) and hero.isAlly and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:EnemiesNearBall(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if isValidTarget(hero,range + hero.boundingRadius) and hero.isAlly and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:AutoultMe() --work
if self.Menu.Misc.UseR:Value() then
	if self:EnemiesNear(myHero.pos,380) >= self.Menu.Misc.RCount:Value() and HasBuff(myHero, "orianaghostself") then
		Control.CastSpell(HK_R)
	else if not HasBuff(myHero, "orianaghostself") and self:EnemiesNear(myHero.pos,380) >= self.Menu.Misc.RCount:Value() and self:CanCast(_E) and self:CanCast(_R) then
		Control.CastSpell(HK_E, myHero)
	end
end
end
end

function Orianna:Autoult1Ally()
	local target = CurrentTarget(600)
	if target == nil then return end
	if self.Menu.Misc.UseR:Value() and self:CanCast(_R) then
	for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isAlly and not hero.isMe then
	if HasBuff(hero, "orianaghost") and self:EnemiesNearAlly(hero.pos,380) >= self.Menu.Misc.RCount:Value() and target.pos:DistanceTo(hero.pos) < 380 then
		Control.CastSpell(HK_R)
	end
end
end
end
end

function Orianna:AutoultBall()
if self.Menu.Misc.UseR:Value() and self:CanCast(_R) then
   		local N = 0 
    		for i = 1, Game.HeroCount() do 
    			local hero = Game.Hero(i)
    			if hero.isEnemy and not hero.dead and hero.isTargetable then 
					if hero.pos:DistanceTo(ball) < 380 then 
    					N = N + 1 
    				end
    			end
    		end
    		if N >= self.Menu.Misc.RCount:Value() then 
    	Control.CastSpell(HK_R)
end
end
end

function Orianna:RKey()
if self:CanCast(_R) then
   	for i = 1, Game.HeroCount() do 
    	local hero = Game.Hero(i)
    	if hero.isEnemy and not hero.dead and hero.isTargetable then 
			if hero.pos:DistanceTo(ball) < 380 then 
     	Control.CastSpell(HK_R)
	else if HasBuff(myHero, "orianaghost") then
		if hero.pos:DistanceTo(myHero) < 380 then
		Control.CastSpell(HK_R)

end
end
end
end
end
end
end

function Orianna:GetDashingHeroes()
	self.DashingHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			table.insert(self.DashingHeroes, Hero)
		end
	end
	return self.DashingHeroes
end

function Orianna:AutoEDashingAllys()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
		if hero.pathing.hasMovePath and hero.pathing.isDashing and hero.pathing.dashSpeed > 500 then 
				for i, allyHero in pairs(self:GetDashingHeroes()) do 
					if myHero.pos:DistanceTo(hero.pos) < 1100 and self:CanCast(_E) then 
							Control.CastSpell(HK_E,hero.pos)
						end
					end
				end
			end
		end
	end

Callback.Add("Load",function() _G[myHero.charName]() end)