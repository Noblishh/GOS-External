local Heroes = {"KogMaw"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0.1","Kypo's","8.1"

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
	

class "KogMaw"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/45/Kog%27MawSquare.png"

function KogMaw:LoadSpells()

	Q = {Range = 1175, Width = 70, Delay = 0.70, Speed = 1650, collision = true, aoe = false, Type = "line"}
	W = {Width = 1, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 1280, Width = 120, Delay = 0.25, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Width = 50, Delay = 0.55, Speed = 1000, Collision = false, aoe = true, Type = "circular", radius = 100}

end

function KogMaw:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "KogMaw", name = "Kypo's KogMaw", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Clear:MenuElement({id = "EClear", name = "Use E If Hit X Minion ", value = 4, min = 2, max = 7, step = 1})
	self.Menu.Clear:MenuElement({id = "UseR", name = "R", value = true})
	self.Menu.Clear:MenuElement({id = "RHit", name = "E hits x minions", value = 3,min = 1, max = 6, step = 1, leftIcon = EIcon})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseR", name = "R", value = true})
	self.Menu.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "RCC", name = "Use R on CC", value = true, type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	
	self.Menu.Killsteal:MenuElement({id = "RR", name = "Use R (Prediction)", value = true, type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.isCC:MenuElement({id = "RCC", name = "Use R on CC", value = true, type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.isCC.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
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
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    self.Menu.Drawings.R:MenuElement({id = "Enabledn", name = "Enabled", value = true})       
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 150, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function KogMaw:__init()
	
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

function KogMaw:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Flee.fleeActive:Value() then
		self:Flee()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:Wcast()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
		self:ClearECount()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:RKSNormal()
		self:SpellonCCQ()
		self:RCC()
		self:RKSCC()
end

function KogMaw:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function KogMaw:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function GetPercentHP(unit)
  return 100 * unit.health / unit.maxHealth
end

function KogMaw:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function KogMaw:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function KogMaw:CanCast(spellSlot)
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

function KogMaw:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function KogMaw:GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
	end
end

function KogMaw:WGetEnemyHeroes()
	local result = {}
  	for i = 1, Game.HeroCount() do
    		local unit = Game.Hero(i)
    		if unit.isEnemy then
    			result[#result + 1] = unit
  		end
  	end
  	return result
end

function KogMaw:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function KogMaw:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function KogMaw:dashpos(unit)
	return myHero.pos + (unit.pos - myHero.pos):Normalized() * 600
	end
-----------------------------
-- DRAWINGS
-----------------------------

function KogMaw:Wcast()
	if myHero:GetSpellData(_W).level == 0 then
		return
	elseif self:CanCast(_W) and myHero:GetSpellData(_W).level == 1 then
	local target = CurrentTarget(630)
	if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(630) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif self:CanCast(_W) and myHero:GetSpellData(_W).level == 2 then
	local target = CurrentTarget(650)
	if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(650) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif self:CanCast(_W) and myHero:GetSpellData(_W).level == 3 then
	local target = CurrentTarget(670)
	if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(670) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif self:CanCast(_W) and myHero:GetSpellData(_W).level == 4 then
	local target = CurrentTarget(690)
	if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(690) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif self:CanCast(_W) and myHero:GetSpellData(_W).level == 5 then
	local target = CurrentTarget(710)
	if target == nil then return end
    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(630) then
			    Control.CastSpell(HK_W)
				end
			end
		
end
end

function KogMaw:RDrawnormal()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif not self:CanCast(_R) then goto continue
	::continue:: elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
		return Draw.Circle(myHero.pos, self:RRange(), self.Menu.Drawings.R.Width:Value(),  self.Menu.Drawings.R.Color:Value())
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
		return Draw.Circle(myHero.pos, self:RRange(), self.Menu.Drawings.R.Width:Value(),  self.Menu.Drawings.R.Color:Value())
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
		return Draw.Circle(myHero.pos, self:RRange(), self.Menu.Drawings.R.Width:Value(),  self.Menu.Drawings.R.Color:Value()) 
	end
end

function KogMaw:RRange()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
		return 1200
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
		return 1500
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
		return 1800
	end
end

function KogMaw:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1175, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 1280, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.R.Enabledn:Value() then self:RDrawnormal() end

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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
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
		
		if self:CanCast(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
		end
		
		if self:CanCast(_R) then
			local target = CurrentTarget(self:RRange())
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function KogMaw:CastSpell(spell,pos)
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

function KogMaw:HpPred(unit, delay)
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

function KogMaw:IsImmobileTarget(unit)
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
-- Flee
-----------------------------
	
function KogMaw:Flee()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	if target == nil then return end
    if self.Menu.Flee.UseR:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
    if self.Menu.Flee.UseR:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	if target == nil then return end
    if self.Menu.Flee.UseR:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

-----------------------------
-- COMBO
-----------------------------

function KogMaw:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < Q.Range then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
end
	
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < E.Range then
			    Control.CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

-----------------------------
-- HARASS
-----------------------------

function KogMaw:Harass()
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < Q.Range then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
end
end

-----------------------------
-- Clear
-----------------------------

function KogMaw:Clear()
	if self:CanCast(_R) then
	local rMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  self:isValidTarget(minion,1200)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				rMinions[#rMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(1200, 100 + 40, rMinions)
		if BestHit >= self.Menu.Clear.RHit:Value() and self.Menu.Clear.UseR:Value() then
			Control.CastSpell(HK_R,BestPos)
		end
	end
end
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

function KogMaw:isValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and not obj.isImmortal and obj.distance <= range
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

-----------------------------
-- LASTHIT
-----------------------------

function KogMaw:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({80,130,180,230,280})[level] + 0.50 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < 1175 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function KogMaw:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({80,130,180,230,280})[level] + 0.50 * myHero.ap)
	return qdamage
end

function KogMaw:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 140, 180})[level] + 0.65 * myHero.totalDamage + 0.25 * myHero.ap)
	return rdamage
end

function KogMaw:ValidTarget(unit,range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end

-----------------------------
-- Q KS
-----------------------------

function KogMaw:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = KogMaw:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				else if self:EnemyInRange(900) then 
				if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
				Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	end
	end
	end
	
-----------------------------
-- R KS normal
-----------------------------

function KogMaw:RKSNormal()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local Rdamage = KogMaw:RDMG()
	if target == nil then return end
    if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local Rdamage = KogMaw:RDMG()
    if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local Rdamage = KogMaw:RDMG()
	if target == nil then return end
    if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
	end
end

-----------------------------
-- Q / R Spell on CC
-----------------------------

function KogMaw:SpellonCCQ()
    local target = CurrentTarget(900)
	if target == nil then return end
	if self.Menu.isCC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R on CC
-----------------------------

function KogMaw:RCC()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if self.Menu.isCC.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local ImmobileEnemy = self:IsImmobileTarget(target)
    if self.Menu.isCC.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if self.Menu.isCC.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
end


-----------------------------
-- R KS on CC
-----------------------------

function KogMaw:RKSCC()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if self.Menu.Killsteal.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
    if self.Menu.Killsteal.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if self.Menu.Killsteal.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end
end
end

function KogMaw:ClearECount(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_E) then 
			if self.Menu.Clear.UseE:Value() and minion and minion:GetCollision(120, 1200, 0.25) - 1 >= self.Menu.Clear.EClear:Value() then
					Control.CastSpell(HK_E, minion)
    end
  end
end
end
end

Callback.Add("Load",function() _G[myHero.charName]() end)