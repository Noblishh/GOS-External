local Heroes = {"LeeSin"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"
require 'MapPositionGOS'

hkitems = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6,[ITEM_7] = HK_ITEM_7, [_Q] = HK_Q, [_W] = HK_W, [_E] = HK_E, [_R] = HK_R }
local _wards = {2055, 2049, 2050, 2301, 2302, 2303, 3340, 3361, 3362, 3711, 1408, 1409, 1410, 1411, 2043, 2055}
local ultimocast = 0
local Position=mousePos

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.2"

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


class "LeeSin"

local HeroIcon = "https://3.bp.blogspot.com/-v7GeY9BzkHI/WNl0yqN6j3I/AAAAAAAAg3A/n17yMJXQkoYaH-q_otWGfz-awgos22gEACLcB/s1600/dbc67cba44126327.jpg"

function LeeSin:LoadSpells()

	Q = {Range = 1000, Width = 60, Delay = 0.30, Speed = 1800, Collision = true, aoe = false, Type = "line"}
	Q2 = {Range = 1300, Width = 0, Delay = 0, Speed = 0, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false}
	E = {Range = 425, Width = 80, Delay = 0.10, Speed = 0, Collision = false, aoe = false, Type = "circular"}
	E2 = {Range = 575, Width = 80, Delay = 0.25, Speed = 2000, Collision = false, aoe = false}
	R = {Range = 375, Width = 80, Delay = 0.25, Speed = 1900, Collision = false, aoe = false, Type = "line"}

end

function LeeSin:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "LeeSin", name = "Kypo's LeeSin", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W when HP below %",value=25,min=5,max=50, step = 5})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E"})	
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQW", name = "QW", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})	
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Clear:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Ultimate", name = "Ultimate", type = MENU})
	self.Menu.Ultimate:MenuElement({id = "Min", name = "Min enemies", value = 3,min = 2, max = 5, step = 1})	
	
	self.Menu:MenuElement({id = "Modes", name = "Modes", type = MENU})
	self.Menu.Modes:MenuElement({id = "Wardjump", name = "Wardjump", key = string.byte("T")})
	self.Menu.Modes:MenuElement({id = "Flashkick", name = "Flashkick", key = string.byte("5")})
	self.Menu.Modes:MenuElement({id = "Insec", name = "Insec", key = string.byte("S")})
	-- self.Menu.Modes:MenuElement({id = "InAndOut", name = "In and Out, smite Dragon/Baron", key = string.byte("Capslock")})
	self.Menu.Modes:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Modes:MenuElement({id = "KickPos", name = "Kick Position", key = string.byte("6")})

	self.Menu:MenuElement({id = "AutoW", name = "AutoW", type = MENU})
	self.Menu.AutoW:MenuElement({id = "savehp", name = "Save allies when HP below ", value = 20,min = 0, max = 100, step = 5})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Killsteal:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "UseIG", name = "Use Ignite", value = true, leftIcon = IgniteIcon})
	
	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "QCC", name = "Q on CC", type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.isCC.QCC:MenuElement({id = "UseQ"..hero.charName, name = "Use Q on: "..hero.charName, value = false})
	end
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
    self.Menu.Items:MenuElement({id = "Youmuu", name = "Youmuu's Ghostblade", value = true})
	self.Menu.Items:MenuElement({id = "YoumuuDistance", name = "Youmuu's distance to use", value = 1000, min = 100, max = 1450, step = 50})
    self.Menu.Items:MenuElement({id = "BladeRK", name = "Blade of the Ruined King", value = true})
    self.Menu.Items:MenuElement({id = "Hydra", name = "Ravenous Hydra", value = true})
    self.Menu.Items:MenuElement({id = "Titantic", name = "Titanic Hydra", value = true})
    self.Menu.Items:MenuElement({id = "Tiamat", name = "Tiamat", value = true})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw Ward range", type = MENU})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
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

function LeeSin:__init()
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

function LeeSin:getFlash()
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

function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function LeeSin:ValidTarget(unit,range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end

function LeeSin:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:ComboQDelay()
		self:ComboE()
		self:ComboQ2()
		self:ComboW()
	end	
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
		self:HarassQ2()
		self:HarassWBack()
		self:HarassWBackM()
	end	
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
		self:ClearW()
		self:ClearE()
	end	
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
		self:LasthitE()
	end		
	if self.Menu.Modes.Wardjump:Value() then
		self:Wardjump()
	end			
	-- if self.Menu.Modes.InAndOut:Value() then
		-- self:InAndOut1()
	-- end	
	if self.Menu.Modes.KickPos:Value() then
		Position=mousePos
	end	
	if self.Menu.Modes.Flashkick:Value() then
		self:FK(Position)
	end
	if self.Menu.Modes.Insec:Value() then
	self:Insec(Position)
	end
	if self.Menu.Killsteal.UseIG:Value() then
		self:UseIG()
	end
		self:KillstealQ()
		self:KillstealE()
		self:RKS()
		self:SpellonCCQ()
		self:AutoW()
		self:Items()
		-- self:Autoult()
end

function LeeSin:Cast(spell,pos)
	Control.SetCursorPos(pos)
	Control.KeyDown(spell)
	Control.KeyUp(spell)
end

function HasBuff(unit, buffName)
		for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name:lower() == buffName:lower() and buff.count > 0 then
				return true
			end
		end
	return false
end

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function LeeSin:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function LeeSin:CanCast(spellSlot)
	return self:IsReady(spellSlot)
end

function LeeSin:validunit(unit)
	return unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable
end

function LeeSin:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
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

function LeeSin:EnemiesAround(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:isValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy then
			N = N + 1
		end
	end
	return N	
end

function LeeSin:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function LeeSin:Insec(poz)
	-- local mouseRadius = 200
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local wardslot = nil
		for t, ids in pairs(_wards) do
			if not wardslot then
				wardslot = self:PegarOsItems(ids)
elseif GetTickCount() > ultimocast + 200 then
				ultimocast = GetTickCount()
				if myHero.pos:DistanceTo(mousePos) < 1300 then		
	if target and self:CanCast(_R) and wardslot then
		local pos=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))+302,poz)
		local pos2=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))-705,poz)
		if Vector(myHero.pos):DistanceTo(pos)<=598 and not MapPosition:inWall(pos) then
			if self:ultimapos(target):DistanceTo(pos2)>302 or Vector(myHero.pos):DistanceTo(pos)>=100 and self:CanCast(_W) then
			self:Cast(hkitems[wardslot], pos)
			self:Cast(hkitems[_W], pos)		
			end
			if self:ultimapos(target):DistanceTo(pos2)<=302 then
				Control.CastSpell(HK_R,target)
			end
		elseif self:CanCast(_W) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)	
		end
	end
end
end
end
end
end

function LeeSin:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function LeeSin:ultimapos(targetx,from)
	local from=from or Vector(myHero.pos)
	local targetx=targetx or target
	return self:Normalized2(Vector(targetx.pos),from:DistanceTo(Vector(targetx.pos))+700,from)
end

function LeeSin:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function LeeSin:MinionInRange(range)
	local count = 0
	for i = 1,Game.MinionCount()  do
		local minion = Game.Minion(i)
		if minion.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function LeeSin:UseIG()
    local target = CurrentTarget(600)
	if self.Menu.Killsteal.UseIG:Value() and target then 
		local IGdamage = 70 + 20 * myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_1) then
				if IGdamage >= LeeSin:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if IsValidTarget(target, 600, true, myHero) and self:CanCast(SUMMONER_2) then
				if IGdamage >= LeeSin:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

-----------------------------
-- DRAWINGS
-----------------------------

function LeeSin:Draw()
Draw.Circle(Position,150,Draw.Color(170,255, 255, 255))
Draw.Circle(Vector(9072,52,4558),160,Draw.Color(170,255, 255, 255))
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 600, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(self.Menu.Drawings.HPColor:Value()))
					
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
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
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

function LeeSin:CastSpell(spell,pos)
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

function LeeSin:HpPred(unit, delay)
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

function LeeSin:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function LeeSin:GetEtarget(range)
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

function LeeSin:isValidTarget(obj,range)
	range = range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end

function LeeSin:Normalized2(q,x,i)
	local x=x or 1
	local qx=(q-i)
	qx=Vector(0,0,0)+qx
	qx=qx:Normalized()
	qx=qx*x
	qx=i+qx
	return qx
end

function LeeSin:FK(poz)
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if target and self:CanCast(_R) then
			local posicao1=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))+180,poz)
			local posicao2=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))-700,poz)
			if Vector(myHero.pos):DistanceTo(posicao1)<=360 and Vector(myHero.pos):DistanceTo(Vector(target.pos))<= 375 then
				if LeeSin:ultimapos(target):DistanceTo(posicao2)<=300 then
					Control.CastSpell(HK_R,target)
				elseif self:CanCast(flashslot) and not MapPosition:inWall(posicao1) then
					Control.CastSpell(HK_R,target)
					DelayAction(function()self:CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,posicao1)end,0.2)
				end
			elseif self:CanCast(flashslot) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and not MapPosition:inWall(posicao1) then
			    Control.CastSpell(HK_Q,castpos)			
			end
		end
	end
end

function LeeSin:AutoW()
if self:CanCast(_W) then
		for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)	
			if self:isValidTarget(hero,700) and hero.isAlly and not hero.isMe then
				if hero.health/hero.maxHealth <= self.Menu.AutoW.savehp:Value()/100 and self:CountEnemy(hero.pos,700) > 0 then
					Control.CastSpell("W",hero.pos)
				end
			end
		end	
	end
end

function isQ1()
	return myHero:GetSpellData(_Q).name == "BlindMonkQOne"
end

function isQ2()
	return myHero:GetSpellData(_Q).name == "BlindMonkQTwo"
end

function LeeSin:CountEnemy(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:isValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

-- function LeeSin:Autoult()
	-- for i = 1, Game.HeroCount() do
	-- local hero = Game.Hero(i)
		-- if hero and hero.isEnemy then
		-- if self:CanCast(_R) then 
		-- if myHero.pos:DistanceTo(hero.pos) < 375 and hero:GetCollision(90, 1200, 0.10) - 1 > self.Menu.Ultimate.Min:Value() then
		-- Control.CastSpell(HK_R, hero)
	-- end
-- end
-- end
-- end
-- end


-----------------------------
-- COMBO
-----------------------------

function LeeSin:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
	    if self:EnemyInRange(Q.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) and myHero.pos:DistanceTo(target.pos) > 250 then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end
    end
	
	function LeeSin:ComboQDelay()
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
		if self:EnemyInRange(200) and HasBuff(target, "BlindMonkQOne") then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			Control.CastSpell(HK_Q,castpos)
			-- print("150 range")
		    end
	    end
    end
    end

function LeeSin:ComboW()
    local target = CurrentTarget(500)
    if target == nil then return end
	if self:CanCast(_W) and myHero.health<=myHero.maxHealth * self.Menu.Combo.UseW:Value()/100 and self:EnemyInRange(500) and not target.dead and target.pos2D.onScreen then 
	Control.CastSpell(HK_W, myHero)
	end
end

function LeeSin:ComboQ2()
    local target = CurrentTarget(1300)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
	    if self:EnemyInRange(1300) and HasBuff(target, "BlindMonkQOne") then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
end
	
function LeeSin:ComboE()
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) and not target.dead and target.pos2D.onScreen then
	    if self:EnemyInRange(E.Range) then
			    Control.CastSpell(HK_E)
		    end
	    end
    end
	
-----------------------------
-- Harass
-----------------------------

function LeeSin:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQW:Value() and target and self:CanCast(_Q) and self:CanCast(_W) and not target.dead and target.pos2D.onScreen then
	    if self:EnemyInRange(Q.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end			
	end			

function LeeSin:HarassQ2()
    local target = CurrentTarget(1300)
    if target == nil then return end
    if self.Menu.Harass.UseQW:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
	    if self:EnemyInRange(1300) and HasBuff(target, "BlindMonkQOne") then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
			end

function LeeSin:HarassWBack()
local target = CurrentTarget(1300)
    if target == nil then return end
for i = 1,Game.HeroCount()  do
		local ally = Game.Hero(i)
		local m = math.huge
	if m and HasBuff(myHero, "BlindMonkQTwoDash") and ally.isAlly and not ally.dead and not ally.isMe and target.pos:DistanceTo(ally.pos) < 575 and not target.dead and target.pos2D.onScreen then
				Control.CastSpell(HK_W, ally)
				Control.CastSpell(HK_W, ally)
				Control.CastSpell(HK_W, ally)
				Control.CastSpell(HK_W, ally)

		    end
end
end


function LeeSin:HarassWBackM()
local target = CurrentTarget(1300)
    if target == nil then return end
for i = 1,Game.MinionCount()  do
		local minion = Game.Minion(i)
		local m = math.huge
	if m and HasBuff(myHero, "BlindMonkQTwoDash") and minion.isAlly and not minion.dead and target.pos:DistanceTo(minion.pos) < 575 and not target.dead and target.pos2D.onScreen then
				Control.CastSpell(HK_W, minion)
				Control.CastSpell(HK_W, minion)
				Control.CastSpell(HK_W, minion)
				Control.CastSpell(HK_W, minion)
		    end
end
end

-----------------------------
-- Clear
-----------------------------

function LeeSin:Clear()
local qdelay = Game.Timer() - myHero:GetSpellData(_Q).castTime >= 1.7
for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if self.Menu.Clear.UseQ:Value() and self:CanCast(_Q) then
		if not minion.isAlly and minion.pos:DistanceTo(myHero.pos) < 1000 and qdelay and not minion.dead and minion.pos2D.onScreen then
		Control.CastSpell(HK_Q, minion)
	else if self:MinionInRange(1300) and HasBuff(minion, "BlindMonkQOne") and qdelay and not minion.dead and minion.pos2D.onScreen then
			Control.CastSpell(HK_Q)
end
end
end
end
end

function LeeSin:ClearW()
for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if self.Menu.Clear.UseW:Value() and self:CanCast(_W) then
		if myHero.health<=myHero.maxHealth * 50/100 then
		Control.CastSpell(HK_W, myHero)
end
end
end
end

function LeeSin:ClearE()
local edelay = Game.Timer() - myHero:GetSpellData(_E).castTime >= 1.5
for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if self.Menu.Clear.UseE:Value() and self:CanCast(_E) then
		if not minion.isAlly and minion.pos:DistanceTo(myHero.pos) < E.Range and not minion.dead and minion.pos2D.onScreen and edelay then
		Control.CastSpell(HK_E)
end
end
end
end
-----------------------------
-- KILLSTEAL
-----------------------------

function LeeSin:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({55,85,115,145,175})[level] + 0.9 * myHero.totalDamage)
	return qdamage
end

function LeeSin:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({70,105,140,175,210})[level] + 1.0 * myHero.totalDamage)
	return edamage
end

function LeeSin:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 200, 300})[level] + 0.9 * myHero.totalDamage)
	return rdamage
end

function LeeSin:SmiteDMGQ()
    local level = myHero.levelData.lvl
    local sdamage = (({445, 465, 515, 570, 595, 625, 685, 570, 715, 815, 855, 895, 935, 975, 1025, 1075, 1125, 1450})[level] + 0.5 * myHero.totalDamage)
	return sdamage
end

function LeeSin:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

function LeeSin:KillstealQ()

-----------------------------
-- Q KS
-----------------------------

	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = LeeSin:QDMG()
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

function LeeSin:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and self:CanCast(_E) and not target.dead and target.pos2D.onScreen then
		if self:EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = LeeSin:EDMG()
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

function LeeSin:SpellonCCQ()
    local target = CurrentTarget(1000)
	if target == nil then return end
	if self.Menu.isCC.QCC["UseQ"..target.charName]:Value() and target and self:CanCast(_Q) and not target.dead and target.pos2D.onScreen then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
			    self:CastSpell(HK_Q,castpos)
				end
			end
		end
	end


function LeeSin:RKS()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) and not target.dead and target.pos2D.onScreen then
		if self:EnemyInRange(R.Range) then 
		 	local Rdamage = LeeSin:RDMG()
			if Rdamage >= self:HpPred(target,0) + target.hpRegen * 1 then
			    self:CastSpell(HK_R,target)
				end
			end
		end
	end
	
function LeeSin:PegarOsItems(itemID, target)
	local target = myHero
	for _, j in pairs({ ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6, ITEM_7 }) do
		if target:GetItemData(j).itemID == itemID and (target:GetSpellData(j).ammo > 0 or target:GetItemData(j).ammo > 0) then return j end
	end
	return nil
end

function LeeSin:Wardjump(key, param)
	local mouseRadius = 200
	if self.Menu.Modes.Wardjump:Value() and self:CanCast(_W) then
		local wardslot = nil
		for t, ids in pairs(_wards) do
			if not wardslot then
				wardslot = self:PegarOsItems(ids)
			end
		end
		if wardslot then
			local ward,dis = self:WardM()
			if ward~=nil and dis~=nil and dis<mouseRadius then
				if myHero.pos:DistanceTo(ward.pos) <=600 then
					self:Cast(hkitems[_W], ward.pos);
				end
			elseif GetTickCount() > ultimocast + 200 then
				ultimocast = GetTickCount()
				if myHero.pos:DistanceTo(mousePos) < 600 then
					self:Cast(hkitems[wardslot], mousePos)
					self:Cast(hkitems[_W], mousePos)
				else
					newpos = myHero.pos:Extended(mousePos,600)
					self:Cast(hkitems[wardslot], newpos)
					self:Cast(hkitems[_W], newpos)
				end
			end
		end
	end
end

function LeeSin:WardM()
	local maisperto, doperto = math.huge, nil
	for i = 1, Game.WardCount() do
		local ward = Game.Ward(i)
		if ward~=nil then
			if (ward.isAlly and not ward.isMe) then
				if not self:validunit(ward) and myHero.pos:DistanceTo(ward.pos) < 700 then
					local distanciaatual = ward.pos:DistanceTo(mousePos)
					if distanciaatual < maisperto then
						maisperto = distanciaatual
						doperto = ward
					end
				end
			end
		end
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion~=nil then
			if (minion.isAlly) then
				if not self:validunit(minion) and myHero.pos:DistanceTo(minion.pos) < 700 then
					local distanciaatual = minion.pos:DistanceTo(mousePos)
					if distanciaatual < maisperto then
						maisperto = distanciaatual
						doperto = minion
					end
				end
			end
		end
	end
	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero~=nil then
			if (hero.isAlly and not hero.isMe) then
				if not self:validunit(hero) and myHero.pos:DistanceTo(hero.pos) < 700 then
					local distanciaatual = hero.pos:DistanceTo(mousePos)
					if distanciaatual < maisperto then
						maisperto = distanciaatual
						doperto = hero
					end
				end
			end
		end
	end
	return doperto, maisperto
end

-- local DragonPos1 = {Vector(9072,52,4558),Vector(9072,52,4558)}

-- function LeeSin:InAndOut1()
			-- local m = math.huge
	-- local wardslot = nil
		-- for t, ids in pairs(_wards) do
			-- if not wardslot then
				-- wardslot = self:PegarOsItems(ids)
-- elseif GetTickCount() > ultimocast + 200 then
				-- ultimocast = GetTickCount()
-- for i = 1, Game.MinionCount() do
	-- local minion = Game.Minion(i)
    -- if self.Menu.Modes.InAndOut:Value() and self:CanCast(_Q) then
		-- if not minion.isAlly and minion.pos:DistanceTo(myHero.pos) < 1000 then
		-- Control.CastSpell(HK_Q, minion)
	-- else if self:MinionInRange(1300) and HasBuff(minion, "BlindMonkQOne") then
			-- Control.CastSpell(HK_Q)
	-- if m and HasBuff(myHero, "BlindMonkQTwoDash") and minion.pos:DistanceTo(DragonPos1.pos) < 700 then
			-- self:Cast(HK_W, Vector(9072,52,4558))
-- end
-- end
-- end
-- end
-- end
-- end
-- end
-- end

function GetInventorySlotItem(itemID)
		assert(type(itemID) == "number", "GetInventorySlotItem: wrong argument types (<number> expected)")
		for _, j in pairs({ ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
			if myHero:GetItemData(j).itemID == itemID and myHero:GetSpellData(j).currentCd == 0 then return j end
		end
		return nil
	    end

function LeeSin:Items()
	local target = CurrentTarget(self.Menu.Items.YoumuuDistance:Value())
	if target == nil then return end
		if self.Menu.Items.Youmuu:Value() and myHero.pos:DistanceTo(target.pos) < self.Menu.Items.YoumuuDistance:Value() then
		local Youmuu = GetInventorySlotItem(3142)
		if Youmuu and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(hkitems[Youmuu])
		end
	end
	
	local target = CurrentTarget(550)
	if target == nil then return end
		if self.Menu.Items.BladeRK:Value() then
		local BladeRK = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
		if BladeRK and self:EnemyInRange(550) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(hkitems[BladeRK], target)
		end
	end
	
	local target = CurrentTarget(320)
	if target == nil then return end
		if self.Menu.Items.Hydra:Value() then
		local Hydra = GetInventorySlotItem(3074) or GetInventorySlotItem(3077)
		if Hydra and self:EnemyInRange(320) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(hkitems[Hydra], target)
		end
	end
	
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Hydra:Value() then
		local Hydra = GetInventorySlotItem(3748) or GetInventorySlotItem(3077)
		if Hydra and self:EnemyInRange(700) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(hkitems[Hydra], target)
		end
	end
	
	local target = CurrentTarget(320)
	if target == nil then return end
		if self.Menu.Items.Tiamat:Value() then
		local Tiamat = GetInventorySlotItem(3077)
		if Tiamat and self:EnemyInRange(320) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(hkitems[Tiamat], target)
		end
	end
	end
	
function LeeSin:Lasthit(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
	local Qdamage = LeeSin:QDMG()
		if self:CanCast(_Q) and not minion.dead and minion.pos2D.onScreen and myHero.pos:DistanceTo(minion.pos) > 250 then 
		if Qdamage >= self:HpPred(minion,1) + minion.hpRegen * 1 then
			Control.CastSpell(HK_Q, minion)
    end
  end
end
end
end

function LeeSin:LasthitE(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
	local Edamage = LeeSin:EDMG()
		if self:CanCast(_E) and myHero.pos:DistanceTo(minion.pos) < 425 and not minion.dead and minion.pos2D.onScreen and not self:CanCast(_Q) then 
		if Edamage >= self:HpPred(minion,1) + minion.hpRegen * 1 then
			Control.CastSpell(HK_E)
    end
  end
end
end
end


Callback.Add("Load",function() _G[myHero.charName]() end)