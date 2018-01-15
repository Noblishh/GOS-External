local Heroes = {"Veigar"}

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



---------------------------------------------------------------------------------------
-- Veigar
---------------------------------------------------------------------------------------

class "Veigar"

local HeroIcon = "http://static.lolskill.net/img/champions/64/veigar.png"

function Veigar:LoadSpells()

	Q = {Range = 900, Width = 70, Delay = 0.25, Speed = 2000, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 0, Delay = 1.25, Speed = 1400, Collision = false, aoe = true, Type = "circle", radius = 112}
	E = {Range = 700, Width = 0, Delay = 0.50, Speed = 1300, Collision = false, aoe = false, Type = "circle"}
	R = {Range = 650, Width = 0, Delay = 1.00, Speed = 2000, Collision = false, aoe = false, Type = "line"}

end

function Veigar:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Veigar", name = "Kypo's Veigar", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Combo:MenuElement({id = "WWait", name = "Only W when stunned", value = true})
	self.Menu.Combo:MenuElement({id = "EMode", name = "E Mode", drop = {"Edge", "Middle"}})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Toggle", value = false, toggle = true, key = string.byte("U")})
	self.Menu.Harass:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Lasthit:MenuElement({id = "AutoQFarm", name = "Auto Q Farm", value = false, toggle = true, key = string.byte("Z")})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "WHit", name = "W hits x minions", value = 3,min = 1, max = 6, step = 1})
	self.Menu.Clear:MenuElement({id = "harassActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Mana", name = "Mana", type = MENU})
	self.Menu.Mana:MenuElement({id = "QMana", name = "Min mana to use Q", value = 35, min = 0, max = 100, step = 1})
	self.Menu.Mana:MenuElement({id = "WMana", name = "Min mana to use W", value = 40, min = 0, max = 100, step = 1})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseW", name = "W", value = false})
	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS on:", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.isCC:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.isCC:MenuElement({id = "UseE", name = "E", value = false})
	self.Menu.isCC:MenuElement({id = "EMode", name = "E Mode", drop = {"Edge", "Middle"}})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    self.Menu.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})

	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Veigar:__init()
	
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

local function CircleCircleIntersection(c1, c2, r1, r2) 
	local D = GetDistance(c1, c2)
	if D > r1 + r2 or D <= math.abs(r1 - r2) then return nil end 
	local A = (r1 * r2 - r2 * r1 + D * D) / (2 * D) 
	local H = math.sqrt(r1 * r1 - A * A)
	local Direction = (c2 - c1):Normalized() 
	local PA = c1 + A * Direction 
	local S1 = PA + H * Direction:Perpendicular() 
	local S2 = PA - H * Direction:Perpendicular() 
	return S1, S2 
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

function Veigar:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Clear.harassActive:Value() then
		self:Clear()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end
		self:KillstealQ()
		self:KillstealW()
		self:KillstealR()
		self:SpellonCCQ()
		self:SpellonCCE()
		self:SpellonCCW()
		self:AutoQ()
		self:AutoQFarm()
end

function Veigar:Clear()
	if self:CanCast(_Q) then
	local qMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  self:isValidTarget(minion,900)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				qMinions[#qMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(50,112 + 80, qMinions)
		if BestHit >= self.Menu.Clear.WHit:Value() and self:CanCast(_W) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.WMana:Value() / 100 ) then
			Control.CastSpell(HK_W,BestPos)
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

function Veigar:isValidTarget(obj,range)
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

function Veigar:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Veigar:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 900 then
        return true
        end
    	end
    	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Veigar:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Veigar:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Veigar:CanCast(spellSlot)
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

function Veigar:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 900 then
        return true
        end
    	end
    	return false
end

function Veigar:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Veigar:EnemyInRange(range)
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

function Veigar:Draw()
if self.Menu.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 40, textPos.y + 100, Draw.Color(255, 60, 145, 201))
			end
if self.Menu.Lasthit.AutoQFarm:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q Farm", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 60, 145, 201))
			end
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range , self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, self.Menu.Drawings.R.Width:Value(), self.Menu.Drawings.R.Color:Value()) end

			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(255, 200, 200, 25))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, self.Menu.Drawings.HPColor:Value()) end
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

function Veigar:GrabObject()
	for i, ball in pairs(Balls) do
		if GetDistanceSqr(ball.pos) < W.Range*W.Range then
			return ball.pos
		end
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.isEnemy and isValidTarget(minion,W.Range-25)  then
			return minion.pos
		end
	end	
end

function Veigar:CastSpell(spell,pos)
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

function Veigar:HpPred(unit, delay)
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

function Veigar:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
-----------------------------
-- COMBO
-----------------------------

function Veigar:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
		if self.Menu.Combo.EMode:Value() == 1 then
			Control.CastSpell(HK_E, Vector(target:GetPrediction(E.speed,E.delay))-Vector(Vector(target:GetPrediction(E.speed,E.delay))-Vector(myHero.pos)):Normalized()*289)
		elseif self.Menu.Combo.EMode:Value() == 2 then
			Control.CastSpell(HK_E,target)
		end
    end	
 end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.WMana:Value() / 100 ) then
	    if self:EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    local ImmobileEnemy = self:IsImmobileTarget(target)
			if (HitChance > 0 ) then
        if self.Menu.Combo.WWait:Value() and not ImmobileEnemy then return end
			Control.CastSpell(HK_W, castpos)
				end
	    end
    end
    end

local function GetPercentMP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.mana/unit.maxMana
end
-----------------------------
-- HARASS
-----------------------------

function Veigar:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
		    end
	    end
    end
 
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if self.Menu.Harass.UseW:Value() and target and self:CanCast(_W) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.WMana:Value() / 100 ) then
	    if self:EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_W, castpos)
		    end
	    end
    end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Veigar:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({65,105,145,185,215})[level] + 0.60 * myHero.ap)
	return qdamage
end

function Veigar:WDMG()
    local level = myHero:GetSpellData(_R).level
    local wdamage = (({100,150,200,250,300})[level] + 1.00 * myHero.ap)
	return wdamage
end

function Veigar:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({175,250,325})[level] + 0.75 * myHero.ap)
	return rdamage
end

function Veigar:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-----------------------------
-- Auto Q champ
-----------------------------

function Veigar:AutoQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Harass.AutoQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and self:CanCast(_Q) then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
	
-----------------------------
-- Auto Q Farm
-----------------------------

function Veigar:AutoQFarm()
	if self:CanCast(_Q) and self.Menu.Lasthit.AutoQFarm:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({70,110,150,190,230})[level] + 0.60 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and minion.isEnemy and not minion.dead then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				if Qdamage >= self:HpPred(minion,1) and (HitChance > 0 ) then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

function Veigar:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({70,110,150,190,230})[level] + 0.60 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				if Qdamage >= self:HpPred(minion,1) and (HitChance > 0 ) then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end
	
-----------------------------
-- R KS
-----------------------------

function Veigar:KillstealR()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(R.Range) then 
			local level = myHero:GetSpellData(_R).level	
			local dmg = GetPercentHP(target) > 33.3 and ({150, 225, 300})[level] + 0.75 * myHero.ap or ({330, 475, 630})[level] + 0.75 * myHero.ap
			local Rdamage = dmg +((0.015 * dmg) * (100 - ((target.health / target.maxHealth) * 100)))
			if Rdamage >= self:HpPred(target,1) * 1.2 + target.hpRegen * 2 then
				Control.CastSpell(HK_R, target)
				end
			end
		end
	end

-----------------------------
-- Q KS
-----------------------------

function Veigar:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Veigar:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

-----------------------------
-- W KS
-----------------------------

function Veigar:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Veigar:WDMG()
			if Wdamage >= self:HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			if (HitChance > 0 ) then
				Control.CastSpell(HK_W, castpos)
				end
			end
		end
	end
end
-----------------------------
-- Q CC
-----------------------------

function Veigar:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.isCC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and not target.dead then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

-----------------------------
-- E CC
-----------------------------

function Veigar:SpellonCCE()
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.isCC.UseE:Value() and target and self:CanCast(_E) then
		local ImmobileEnemy = self:IsImmobileTarget(target)
	    if self:EnemyInRange(E.Range) and ImmobileEnemy then
		if self.Menu.isCC.EMode:Value() == 1 then
			Control.CastSpell(HK_E, Vector(target:GetPrediction(E.speed,E.delay))-Vector(Vector(target:GetPrediction(E.speed,E.delay))-Vector(myHero.pos)):Normalized()*300)
		elseif self.Menu.isCC.EMode:Value() == 2 then
			Control.CastSpell(HK_E,target)
		end
    end	
 end
 end

-----------------------------
-- W CC
-----------------------------

function Veigar:SpellonCCW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if self.Menu.isCC.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
				Control.CastSpell(HK_W, castpos)
				end
			end
		end
	end

-----------------------------
-- MANA CHECK
-----------------------------

function Veigar:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Veigar:CheckMana(spellSlot)
	if myHero:GetSpellData(spellSlot).mana < myHero.mana then
		return true
	else
		return false
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)