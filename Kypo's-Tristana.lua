local Heroes = {"Tristana"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.2"

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

class "Tristana"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/06/TristanaSquare.png"

function Tristana:LoadSpells()

	Q = {Range = 550, Width = 20, Delay = 0.40, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	E = {Range = 500, Width = 0, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 500, Width = 0, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}

end

function Tristana:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Tristana", name = "Kypo's Tristana", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Combo:MenuElement({id = "R", name = "R", type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Combo.R:MenuElement({id = "RR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	self.Menu.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    self.Menu.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    self.Menu.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    self.Menu.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Tristana:__init()
	
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

function Tristana:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
		self:ComboRKS()
		self:UseBotrk()
	end	
	if self.Menu.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassE()
	end
end

function Tristana:HasBuff(unit, buffname)
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

function Tristana:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Tristana:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Tristana:CanCast(spellSlot)
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

function Tristana:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 550 then
        return true
        end
    	end
    	return false
end

function Tristana:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Tristana:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

-------------------------
-- DRAWINGS
-------------------------

function Tristana:Draw()
if self:CanCast(_W) and self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero, 900, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self:CanCast(_E) and self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero, GetERange(), self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self:CanCast(_R) and self.Menu.Drawings.R.Enabled:Value() then Draw.Circle(myHero, GetRRange(), self.Menu.Drawings.R.Width:Value(), self.Menu.Drawings.R.Color:Value()) end
		if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local damage = EDamage + RDamage
				if damage > hero.health and self:EnemyInRange(3500) then
					Draw.Text("Killable", 20, hero.pos2D.x, hero.pos2D.y,Draw.Color(200,255,255,255))				
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, self.Menu.Drawings.HPColor:Value())
				end
			end
end	
end	
end	

function Tristana:CastSpell(spell,pos)
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

function Tristana:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

-------------------------
-- BUFFS
-------------------------

function Tristana:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 22 or buff.type == 8 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Tristana:UseBotrk()
	local target = CurrentTarget(700)
	if target == nil then return end
		if self:EnemyInRange(700) then 
		local BOTR = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
		if BOTR and self:EnemyInRange(700) then
			Control.CastSpell(HKITEM[BOTR], target)
		end
	end
	end

function Tristana:Combo()
    local target = CurrentTarget(680)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(680) then
		Control.CastSpell(HK_Q)
		end
	    end
end

function Tristana:ComboE()
    local target = CurrentTarget(GetERange())
    if target == nil then return end
    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(GetERange()) then
		Control.CastSpell(HK_E, target)
		    end
	    end
	    end
		
function Tristana:ComboRKS()
	local hero = CurrentTarget(GetRRange())
    if hero == nil then return end
 	if self.Menu.Combo.R["RR"..hero.charName]:Value() and self:CanCast(_R) then
	if self:EnemyInRange(GetRRange()) then
   	local Rdamage = Tristana:RDMG()    
			if Rdamage >= self:HpPred(hero,1) + hero.hpRegen * 1 and not hero.dead then
				Control.CastSpell(HK_R, hero)
			end
        end
    end
end

function Tristana:HarassQ()
    local target = CurrentTarget(680)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(680) then
		Control.CastSpell(HK_Q)
		end
	    end
end

function Tristana:HarassE()
    local target = CurrentTarget(GetERange())
    if target == nil then return end
    if self.Menu.Harass.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(GetERange()) then
		Control.CastSpell(HK_E, target)
		    end
	    end
	    end
 

-------------------------
-- DMG
---------------------

function Tristana:RDMG()
    local level = myHero:GetSpellData(_R).level
    local edamage = (({300,400,500})[level] + 1.0 * myHero.ap)
	return edamage
end

-- function Tristana:EDMG()
    -- local level = myHero:GetSpellData(_E).level
	-- local edamage = ({60, 70, 80, 90, 100})[level] + ({0.5, 0.70, 0.80, 0.90})[level] * myHero.totalDamage + 0.5 * myHero.ap
	-- return edamage
-- end

-- function Tristana:StatikkshivDMG()
	-- local shiv = GetInventorySlotItem(3087)
	-- local level = myHero.levelData.level
		-- if shiv then
	-- local shivdamage = (({60,60,60,60,60,68,76,84,91,99,107,114,122,130,137,145,153,160})[level] + 1.0 * myHero.bonusDamage)
	-- return shivdamage
	-- end
	-- end

function Tristana:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 550 
end


function GetRRange()
	local level = myHero:GetSpellData(_R).level
	local range = ({665,720,725})[level]
	return range
end

function GetERange()
	local level = myHero:GetSpellData(_E).level
	local range = ({600,612,625,645,665})[level]
	return range
end
	
Callback.Add("Load",function() _G[myHero.charName]() end)