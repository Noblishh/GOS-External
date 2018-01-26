local Heroes = {"Ahri"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"

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

class "Ahri"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/aa/Star_Guardian_Ahri_profileicon.png"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/19/Orb_of_Deception.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a8/Fox-Fire.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/04/Charm.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/8/86/Spirit_Rush.png"
local IgniteIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f4/Ignite.png"

function Ahri:LoadSpells()

	Q = {Range = 880, Width = 80, Delay = 0, Speed = 1100, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false}
	E = {Range = 975, Width = 80, Delay = 0.60, Speed = 1200, Collision = true, aoe = false, Type = "line"}

end

function Ahri:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Ahri", name = "Kypo's Ahri", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false, leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "Type", name = "Combo Logic", value = 1,drop = {"QWE", "EQW", "EWQ"}})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "Enable", name = "Enable", value = true})
	self.Menu.Clear:MenuElement({id = "QClear", name = "Use Q If Hit X Minion ", value = 3, min = 1, max = 5, step = 1, leftIcon = QIcon})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})
	self.Menu.Killsteal:MenuElement({id = "UseIG", name = "Use Ignite", value = true, leftIcon = IgniteIcon})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.isCC:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU, leftIcon = QIcon})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU, leftIcon = WIcon})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function Ahri:__init()
	
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

    function UseBotrk()
		local BTarget = CurrentTarget(500)
		if BTarget then 
			local botrkitem = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
			if botrkitem then
				Control.CastSpell(keybindings[botrkitem],BTarget.pos)
			end
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

function Ahri:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:ComboTypes()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
	end
	if self.Menu.Killsteal.UseIG:Value() then
		self:UseIG()
	end
		self:KillstealQ()
		self:KillstealW()
		self:KillstealE()
		self:SpellonCCQ()
		self:SpellonCCE()
end

function Ahri:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Ahri:GetValidMinion(range)
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

function Ahri:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Ahri:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Ahri:CanCast(spellSlot)
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

function Ahri:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Ahri:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Ahri:EnemyInRange(range)
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

function Ahri:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 880, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 700, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 975, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
			end
		end
end

function Ahri:CastSpell(spell,pos)
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

function Ahri:HpPred(unit, delay)
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

function Ahri:UseIG()
    local target = CurrentTarget(600)
	if self.Menu.Killsteal.UseIG:Value() and target then 
		local IGdamage = 70 + 20 * myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_1) then
				if IGdamage >= Ahri:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_2) then
				if IGdamage >= Ahri:HpPred(target, 1) + target.hpRegen * 1 then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
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

function Ahri:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if (buff.type == 5 or buff.type == 29 or buff.type == 8 or buff.type == 28 or buff.type == 22 or buff.type == 21 or buff.type == 25 or buff.type == 9 or buff.type == 7 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

-----------------------------
-- COMBO
-----------------------------

function Ahri:ComboTypes(target)
local mode = self.Menu.Combo.Type:Value() 
	if mode == 1 then
		self:QWE()
	elseif mode == 2 then
		self:EQW()
	elseif mode == 3 then
		self:EWQ()
end
end

function Ahri:QWE()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and self:CanCast(_W) then
			    Control.CastSpell(HK_W,castpos)
            end
		end
	end
 
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_E,castpos)
		    end
	    end
    end
end


function Ahri:EQW()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_E,castpos)
		    end
	    end
    end
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and self:CanCast(_W) then
			    Control.CastSpell(HK_W,castpos)
            end
		end
	end
end


function Ahri:EWQ()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_E,castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
	if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			    Control.CastSpell(HK_W,castpos)
            end
	end
	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end
end
	
	
-- HARASS

function Ahri:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if self.Menu.Harass.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and self:CanCast(_W) then
			    Control.CastSpell(HK_W,castpos)
            end
		end
	end

end

-- JUNGLE

function Ahri:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_Q) then 
			if self.Menu.Clear.Enable:Value() and minion and minion:GetCollision(80, 1100, 0) - 1 >= self.Menu.Clear.QClear:Value() then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end


-- KILLSTEAL


function Ahri:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({80, 130, 180, 230, 280})[level] + 0.35 * myHero.ap)
	return qdamage
end

function Ahri:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({40,65,90,115,140})[level] + 0.3 * myHero.ap)
	return wdamage
end

function Ahri:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({60, 95, 130, 165, 200})[level] + 0.6 * myHero.ap)
	return edamage
end

function Ahri:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

-- Q KS

function Ahri:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Ahri:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and not target.dead then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end



-- W KS


function Ahri:KillstealW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseW:Value() and target and self:CanCast(_W) then
		if self:EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Ahri:WDMG()
			if Wdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_W) and not target.dead and target  then
			    self:CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

-- E KS

function Ahri:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() then
		if self:EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		   	local Edamage = Ahri:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and not target.dead and self:CanCast(_E) then
			    self:CastSpell(HK_E,castpos)
				end
			end
		end
	end
end


-- E Spell on CC


function Ahri:SpellonCCE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.isCC.UseE:Value() and target and self:CanCast(_E) then
	if self:EnemyInRange(E.Range) then 
	local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
			    Control.CastSpell(HK_E,castpos)
				end
			end
		end
	end

-- Q Spell on CC


function Ahri:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.isCC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)