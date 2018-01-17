local Heroes = {"Fizz"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.1"

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

class "Fizz"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/69/Fizz_profileicon.png"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a4/Urchin_Strike.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/6d/Seastone_Trident.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/9c/Playful.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/ca/Chum_the_Waters.png"

function Fizz:LoadSpells()

	Q = {Range = 550, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 225, Delay = 0.25}
	E = {Range = 800}
	R = {Range = 1300, Width = 160, Delay = 0.25, Speed = 1300, Collision = false, aoe = true}

end

function Fizz:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Fizz", name = "Kypo's Fizz", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = false, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "UseW", name = "W", value = true, leftIcon = WIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	self.Menu:MenuElement({id = "SemiR", name = "R Key", type = MENU})
	self.Menu.SemiR:MenuElement({id = "UseR", name = "R", key = string.byte("T")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end	self.Menu.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
	self.Menu.Items:MenuElement({id = "Protobelt", name = "Hextech Protobelt", value = true})
	self.Menu.Items:MenuElement({id = "GLP", name = "Hextech GLP", value = true})
	self.Menu.Items:MenuElement({id = "Gunblade", name = "Hextech Gunblade", value = true})

	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU, leftIcon = QIcon})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU, leftIcon = EIcon})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU, leftIcon = RIcon})
    self.Menu.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Fizz:__init()
	
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

function Fizz:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Items()
	end	
		self:KillstealQ()
		self:KillstealR()
		self:RksCC()
		self:SemiR()
		self:Wuse()
		self:Quse()
		self:Euse()
	
end

function Fizz:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Fizz:GetValidMinion(range)
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

function Fizz:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Fizz:CanCast(spellSlot)
	return self:IsReady(spellSlot)
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

function Fizz:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Fizz:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Fizz:EnemyInRange(range)
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

function Fizz:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 550, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 400, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1300, self.Menu.Drawings.R.Width:Value(), self.Menu.Drawings.R.Color:Value()) end
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
    if self:CanCast(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			local collisionc = R.ignorecol
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Fizz:CastSpell(spell,pos)
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

function Fizz:HpPred(unit, delay)
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

function Fizz:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

-----------------------------
-- COMBO
-----------------------------

function Fizz:CastQ(target)
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = target or (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.Range,"AP"))
	if target and target.type == "AIHeroClient" and self:CanCast(_Q) then
		Control.CastSpell(HK_Q, target)
	end
end

function Fizz:CastW()
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(200, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(200,"AP"))
	if target and GetDistance(myHero.pos,target.pos)>200 then
	Control.CastSpell(HK_W, target)
	end
end

function Fizz:CastE()
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(E.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(E.Range,"AP"))
	if target then
		Control.CastSpell(HK_E, target)
	end
end

function Fizz:SemiR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.SemiR.UseR:Value() and self:CanCast(_R) then
		if self:EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1300,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Fizz:Wuse()
 if self.Menu.Combo.comboActive:Value() and self.Menu.Combo.UseW:Value() and self:CanCast(_W) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if self:EnemyInRange(225) then 
			local level = myHero:GetSpellData(_W).level	
			if target then
			Control.CastSpell(HK_W,target)
		end
	end
end
end

function Fizz:Quse()
	if self.Menu.Combo.comboActive:Value() and self.Menu.Combo.UseQ:Value() and self:CanCast(_Q) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if self:EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end
end

function Fizz:Euse()
    if self.Menu.Combo.comboActive:Value() and self.Menu.Combo.UseE:Value() and self:CanCast(_E) then
	local target = CurrentTarget(800)
	if target == nil then return end
		if self:EnemyInRange(800) then 
			local level = myHero:GetSpellData(_E).level	
			if target then
			Control.CastSpell(HK_E,target)
		end
	end
end
end

-----------------------------
-- HARASS
-----------------------------

function Fizz:Harass()
     if self.Menu.Harass.UseQ:Value() and self.Menu.Harass.UseQ:Value() and self:CanCast(_Q) and self:EnemyInRange(Q.Range) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if self:EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end

     if self.Menu.Harass.UseQ:Value() and self.Menu.Harass.UseW:Value() and self:CanCast(_W) and self:EnemyInRange(W.Range) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if self:EnemyInRange(225) then 
			local level = myHero:GetSpellData(_W).level	
			if target then
			Control.CastSpell(HK_W,target)
			end
		end
	end
end

function HasBuff(unit, buffName, delay)
		for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name:lower() == buffName:lower()and buff.count > 0 then
				return true
			end
		end
	return false
end
	
-----------------------------
-- KILLSTEAL
-----------------------------

function Fizz:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({10, 25, 40, 55, 70})[level] + 0.55 * myHero.ap)
	return qdamage
end

function Fizz:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70, 115, 160, 205, 250})[level] + 0.8 * myHero.ap)
	return wdamage
end

function Fizz:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({225, 350, 490})[level] + 0.8 * myHero.ap)
	return rdamage
end

function Fizz:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 3340 
end

function Fizz:KillstealQ()
-----------------------------
-- Q KS
-----------------------------

	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		   	local Qdamage = Fizz:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    self:CastQ()
				end
			end
		end
	end
-----------------------------
-- R KS
-----------------------------

function Fizz:KillstealR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Fizz:RDMG()
			if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and self:CanCast(_R) then
			    self:CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R KS on CC
-----------------------------

function Fizz:RksCC()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.Killsteal.RCC["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
		if self:EnemyInRange(1300) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		 	local Rdamage = Fizz:RDMG()
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

-- Items

function Fizz:GetItemData(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and Game.CanUseSpell(spell) == 0 
end

function Fizz:Items()
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Protobelt:Value() then
		local protobelt = GetInventorySlotItem(3152)
		if protobelt and self:EnemyInRange(700) then
			Control.CastSpell(HKITEM[protobelt], target)
		end
	end
	
	local target = CurrentTarget(800)
	if target == nil then return end
		if self.Menu.Items.GLP:Value() then
		local GLP = GetInventorySlotItem(3030)
		if GLP and self:EnemyInRange(800) then
			Control.CastSpell(HKITEM[GLP], target)
		end
	end
	
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Gunblade:Value() then
		local Gunblade = GetInventorySlotItem(3146)
		if Gunblade and self:EnemyInRange(700 ) then
			Control.CastSpell(HKITEM[Gunblade], target)
		end
	end
	
end


Callback.Add("Load",function() _G[myHero.charName]() end)