local Heroes = {"Syndra"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0.3","Kypos","8.1"

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
-- Syndra
---------------------------------------------------------------------------------------

class "Syndra"

local HeroIcon = "http://78.media.tumblr.com/6223c26bcee62fe17a723ca2fef97b24/tumblr_n4v50bP4EQ1rczihjo1_500.jpg"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/62/Dark_Sphere.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/d/d2/Force_of_Will.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/9c/Scatter_the_Weak.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/1d/Unleashed_Power.png"
local Balls = {}

function Syndra:LoadSpells()

	Q = {Range = 800, Width = 80, Delay = 0.50, Speed = 1750, Collision = false, aoe = false, Type = "circular", radius = 225}
	W = {Range = 950, Width = 80, Delay = 0.70, Speed = 1450, Collision = false, aoe = false, Type = "circular", radius = 225}
	E = {Range = 700, Width = 80, Delay = 0.25, Speed = 902, Collision = false, aoe = false}
	R = {Range = 750, Width = 0, Delay = 1.00, Speed = 0, Collision = false, aoe = false, Type = "line"}
	QE = {Range = 1100, Delay = 0.6, Speed = 1750, Type = "line"}

end

function Syndra:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Syndra", name = "Kypo's Syndra", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Combo:MenuElement({id = "UseQE", name = "QE", key = string.byte"T", leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Toggle", value = true, toggle = true, leftIcon = QIcon, key = string.byte("6")})
	self.Menu.Harass:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})	
	
	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Clear:MenuElement({id = "QHit", name = "E hits x minions", value = 3,min = 1, max = 6, step = 1, leftIcon = EIcon})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Mana", name = "Mana", type = MENU})
	self.Menu.Mana:MenuElement({id = "QMana", name = "Min mana to use Q", value = 35, min = 0, max = 100, step = 1, leftIcon = WIcon})
	self.Menu.Mana:MenuElement({id = "WMana", name = "Min mana to use W", value = 40, min = 0, max = 100, step = 1, leftIcon = WIcon})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Killsteal:MenuElement({id = "UseIG", name = "Use Ignite", value = true})
	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS on: ", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	
	self.Menu:MenuElement({type = MENU, id = "gapclose", name = "Anti Gapclose"})
	self.Menu.gapclose:MenuElement({id = "enabled", name = "Enabled", value = true})
	for i, hero in pairs(self:GetDashingHeroes()) do
		self.Menu.gapclose:MenuElement({id = "RU"..hero.charName, name = "Protect from dashes: "..hero.charName, value = true})
	end

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU, leftIcon = QIcon})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU, leftIcon = WIcon})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--QE
	self.Menu.Drawings:MenuElement({id = "QE", name = "Draw QE range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.QE:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.QE:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.QE:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})

	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Syndra:__init()
	
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

function Syndra:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end
	if self.Menu.gapclose.enabled:Value() then
		self:Antigap()
	end
	if self.Menu.Killsteal.UseIG:Value() then
		self:UseIG()
	end
		self:KillstealQ()
		self:KillstealR()
		self:SpellonCCQ()
		self:QE()
		self:AutoQ()
end

function Syndra:UseIG()
    local target = CurrentTarget(600)
	if self.Menu.Killsteal.UseIG:Value() and target then 
		local IGdamage = 70 + 20 * myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_1) then
				if IGdamage >= Syndra:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_2) then
				if IGdamage >= Syndra:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

function IsValidTarget(unit, range, onScreen)
    local range = range or 2000
    
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

function Syndra:Clear()
	if self:CanCast(_Q) then
	local qMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  self:isValidTarget(minion,800)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				qMinions[#qMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(800, 225 + 40, qMinions)
		if BestHit >= self.Menu.Clear.QHit:Value() and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
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

function Syndra:isValidTarget(obj,range)
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

function Syndra:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Syndra:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 800 then
        return true
        end
    	end
    	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Syndra:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Syndra:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Syndra:CanCast(spellSlot)
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

function Syndra:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Syndra:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Syndra:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Syndra:GetDashingHeroes()
	self.DashingHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.DashingHeroes, Hero)
		end
	end
	return self.DashingHeroes
end

function Syndra:Antigap()
		for i, hero in pairs(self:GetEnemyHeroes()) do 
			if hero.pathing.hasMovePath and hero.pathing.isDashing and hero.pathing.dashSpeed>500 then 
				for i, allyHero in pairs(self:GetDashingHeroes()) do 
					if self.Menu.gapclose["RU"..allyHero.charName] and self.Menu.gapclose["RU"..allyHero.charName]:Value() then 
						if GetDistance(hero.pathing.endPos,allyHero.pos)<700 then
							self:CastSpell(HK_E,hero.pos)
						end
					end
				end
			end
		end
	end

-----------------------------
-- DRAWINGS
-----------------------------

function Syndra:Draw()
if self.Menu.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(255, 60, 145, 201))
			end
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 800 , self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 925, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 700, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.QE.Enabled:Value() then Draw.Circle(myHero.pos, 1100, self.Menu.Drawings.QE.Width:Value(), self.Menu.Drawings.QE.Color:Value()) end

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
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, "circular" )
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

function Syndra:GrabObject()
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

function Syndra:CastSpell(spell,pos)
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

function Syndra:HpPred(unit, delay)
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

function Syndra:IsImmobileTarget(unit)
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

function Syndra:QE()
    local target = CurrentTarget(QE.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQE:Value() and target and self:CanCast(_Q) and self:CanCast(_E) then
			local pos = target:GetPrediction(QE.Speed,0.900)
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(Q.Range - 65)
			Control.SetCursorPos(pos) 
			Control.KeyDown(HK_Q)
			Control.KeyUp(HK_Q)
			Control.KeyDown(HK_E) 
			Control.KeyUp(HK_E) 
			end
end

function Syndra:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.WMana:Value() / 100 ) then
	    if self:EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
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

function Syndra:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
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

function Syndra:GetMySpheres()
		for i = 0, Game.ObjectCount() do
			local obj = Game.Object(i)
			if obj and not obj.dead and obj.name:find("Seed") then
				Balls[obj.networkID] = obj
			end
		end	
end

function Syndra:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({50, 95, 140, 185, 230})[level] + 0.65 * myHero.ap)
	return qdamage
end

function Syndra:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({90, 135 , 180})[myHero:GetSpellData(_R).level] + 0.2 * myHero.ap)*(3 + #Balls)
	return rdamage
end

function Syndra:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-----------------------------
-- Auto Q
-----------------------------

function Syndra:AutoQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Harass.AutoQ:Value() and target and self:CanCast(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Mana.QMana:Value() / 100 ) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and self:CanCast(_Q) then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
-----------------------------
-- R KS
-----------------------------

function Syndra:KillstealR()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(R.Range) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Syndra:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

-----------------------------
-- Q KS
-----------------------------

function Syndra:KillstealQ()
	local target = CurrentTarget(800)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(800) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 800, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			local castposR,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Qdamage = Syndra:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_Q) then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end
-----------------------------
-- Q Spell on CC
-----------------------------

function Syndra:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.isCC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

-----------------------------
-- MANA CHECK
-----------------------------

function Syndra:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Syndra:CheckMana(spellSlot)
	if myHero:GetSpellData(spellSlot).mana < myHero.mana then
		return true
	else
		return false
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)