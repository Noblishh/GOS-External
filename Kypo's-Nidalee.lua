local Heroes = {"Nidalee"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypos","8.3"

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
-- Nidalee
---------------------------------------------------------------------------------------

class "Nidalee"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/7c/NidaleeSquare.png"

function Nidalee:LoadSpells()

	Q = {Range = 1500, Width = 40, Delay = 0.45, Speed = 1600, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 0, Delay = 0.95, Speed = 1200, Collision = true, aoe = false, Type = "circular"}
	E = {Range = 600, Delay = 0.30, Speed = 900, Collision = false, aoe = false, Type = "line"}
	R = {Speed = 943, Collision = false, aoe = false, Type = "line"}
	Trap = {Range = 700, Delay = 0, Speed = 1200, Collision = false, aoe = false}

end

function Nidalee:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Nidalee", name = "Kypo's Nidalee", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Combo:MenuElement({id	= "Eheal",name="Min Health to heal -> %",value=50,min=0,max=70})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Clear:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Clear:MenuElement({id	= "Eheal",name="Min Health to heal -> %",value=40,min=0,max=70})
	self.Menu.Clear:MenuElement({id = "WECount", name = "Use W/E on X minions (Lane Only)", value = 3, min = 1, max = 5, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "{Q} Javelin Toss", key = string.byte("T")})
	self.Menu.Killsteal:MenuElement({id = "Ignite", name = "Ignite", value = true})	

	self.Menu:MenuElement({id = "CC", name = "CC", type = MENU})
	self.Menu.CC:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.CC:MenuElement({id = "UseW", name = "W Trap", value = true})
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
    self.Menu.Items:MenuElement({id = "Zhonya", name = "Zhonya", value = true})
    self.Menu.Items:MenuElement({id = "ZhonyaHp", name = "Min HP",value=15,min=1,max=30})
	self.Menu.Items:MenuElement({id = "Protobelt", name = "Hextech Protobelt", value = true})
	self.Menu.Items:MenuElement({id = "GLP", name = "Hextech GLP", value = true})
	self.Menu.Items:MenuElement({id = "Gunblade", name = "Hextech Gunblade", value = true})	
	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Human", name = "Human", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Animal", name = "Animal", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    self.Menu.Drawings.W:MenuElement({id = "Human", name = "Human", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Animal", name = "Animal", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 87, 51)})		
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Nidalee:__init()	
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

function Nidalee:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	
	if self.Menu.Combo.comboActive:Value() then
		self:DistQ()
		self:ComboQAnimal()
		self:ComboQHuman()
		self:ComboWAnimal()
		self:ComboEAnimal()
		self:AutoHealCombo()
		self:ChangeToR()
		self:ChangeToRHuman()
		self:Items()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
		self:ClearQ()
		self:ClearW()
		self:ClearE()
		self:AutoHealClear()
		self:ChangeToR()
		self:ChangeToRHuman()
		self:DistQClear()
		self:ClearQQminion()
		self:ClearWMinionJump()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end				
		self:KillstealQ()
		self:CC()
		self:CCW()
		self:Zhonya()
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

function Nidalee:GetValidMinion(range)
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

function Nidalee:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Nidalee:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Nidalee:CanCast(spellSlot)
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

function Nidalee:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Nidalee:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Nidalee:EnemyInRange(range)
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

function Nidalee:Draw()
if self.Menu.Drawings.Q.Human:Value() and myHero:GetSpellData(_Q).name == "JavelinToss" then Draw.Circle(myHero.pos, Q.Range, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Human:Value() and myHero:GetSpellData(_Q).name == "JavelinToss" then Draw.Circle(myHero.pos, W.Range, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
if self.Menu.Drawings.W.Animal:Value() and myHero:GetSpellData(_Q).name == "Takedown" then Draw.Circle(myHero.pos, 400, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end

if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local QDamage2 = (self:CanCast(_Q) and getdmg("QM",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + QDamage2
				local damage2 = self:QDMG()
				if damage > hero.health then
					Draw.Text("KILLABLE", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
				if damage2 > hero.health then
					Draw.Text("Q KILLABLE", 35, hero.pos2D.x - 75, hero.pos2D.y - 190,Draw.Color(200, 255, 87, 51))	
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, self.Menu.Drawings.HPColor:Value())
				end
			end
		end	
	end
if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local damage2 = self:QDMG()
				if damage2 > hero.health then
					Draw.Text("Q KILLABLE", 35, hero.pos2D.x - 75, hero.pos2D.y - 190,Draw.Color(200, 255, 87, 51))	
				end
			end
		end	
	end
    if self:CanCast(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local Qdamage = Nidalee:QDMG()
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end 
		end 
		if self:CanCast(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			
			if (TPred) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 41, 41))
			end
		end
end


function Nidalee:CastSpell(spell,pos)
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

function Nidalee:HpPred(unit, delay)
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

function Nidalee:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 8 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
	return false	
end

function Nidalee:isHuman()
	return myHero:GetSpellData(_Q).name == "JavelinToss"
end

function Nidalee:isAnimal()
	return myHero:GetSpellData(_Q).name == "Takedown"
end

-----------------------------
-- COMBO
-----------------------------

--Q
function Nidalee:ComboQHuman()
    local target = CurrentTarget(1500)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and self:isHuman() and target.pos2D.onScreen then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    self:CastSpell(HK_Q,castpos)
			end
		end
	end
end

function Nidalee:ComboQAnimal()
	local target = CurrentTarget(450)
    if target == nil then return end  
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) and self:isAnimal() and target.pos2D.onScreen then	
		if myHero.pos:DistanceTo(target.pos) < 450 then
		Control.CastSpell(HK_Q)
	end
end
end

function Nidalee:DistQ()
local target = CurrentTarget()
    if target == nil then return end
		if target.pos:DistanceTo(myHero.pos) > 400 and self:isAnimal() and self:CanCast(_R) and not HasBuff(target, "NidaleePassiveHunted") and target.pos2D.onScreen then
			    Control.CastSpell(HK_R)
		else if target.pos:DistanceTo(myHero.pos) < 400 and self:isHuman() and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
	end
end
end

-- W
function Nidalee:ComboWAnimal()
local target = CurrentTarget(900)
    if target == nil then return end
	if target.pos2D.onScreen then
		if self.Menu.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 400 and not HasBuff(target, "NidaleePassiveHunted") and self:isAnimal() and self:CanCast(_W) then
			    Control.CastSpell(HK_W, target)
		else if self.Menu.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 700 and HasBuff(target, "NidaleePassiveHunted") and self:isAnimal() and self:CanCast(_W) then
			    Control.CastSpell(HK_W, target)
		else if self.Menu.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 700 and HasBuff(target, "NidaleePassiveHunted") and self:isHuman() and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
		else if self.Menu.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 900 and self:isHuman() and self:CanCast(_W) and not self:CanCast(_Q) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
	end
end
end
end
end
end
end

function Nidalee:AutoHealCombo()
local target = CurrentTarget(900)
    if target == nil then return end
		if myHero.health<=myHero.maxHealth * self.Menu.Combo.Eheal:Value()/100 and target.pos:DistanceTo(myHero.pos) < 900 and self:isHuman() and self:CanCast(_E) then
			    Control.CastSpell(HK_E, myHero)		
		else if myHero.health<=myHero.maxHealth * self.Menu.Combo.Eheal:Value()/100 and target.pos:DistanceTo(myHero.pos) < 900 and self:isAnimal() and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
	end
end
end

function Nidalee:ChangeToR()
if self:isAnimal() and not self:CanCast(_W) and not self:CanCast(_Q) and not self:CanCast(_E) and self:CanCast(_R) then
		Control.CastSpell(HK_R)
	end
end

function Nidalee:ChangeToRHuman()
if self:isHuman() and not self:CanCast(_W) and not self:CanCast(_Q) and self:CanCast(_R) then
		Control.CastSpell(HK_R)
	end
end

-- E
function Nidalee:ComboEAnimal()
local target = CurrentTarget(350)
    if target == nil then return end
		if self.Menu.Combo.UseE:Value() and target.pos:DistanceTo(myHero.pos) < 350 and self:isAnimal() and self:CanCast(_E) then
			    Control.CastSpell(HK_E, target)
	end
end


-----------------------------
-- Clear
-----------------------------

function Nidalee:Clear()
	if self:CanCast(_W) and self:isAnimal() then
	local wMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if isValidTarget(minion,350) then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				wMinions[#wMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(350, 300, wMinions)
		if BestHit >= self.Menu.Clear.WECount:Value() and self.Menu.Clear.UseW:Value() then
		Control.CastSpell(HK_W,BestPos)			
		else if self:CanCast(_E) and self:isAnimal() then
		local BestPosE, BestHitE = GetBestCircularFarmPosition(200, 350, wMinions)
		if BestHitE >= self.Menu.Clear.WECount:Value() and self.Menu.Clear.UseE:Value() then
		Control.CastSpell(HK_E,BestPosE)
		end
	end
end
end
end

function Nidalee:ClearE()
	if self.Menu.Clear.UseE:Value() and self:isAnimal() and self:CanCast(_E) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 350 then
			Control.CastSpell(HK_E,minion)
end
end
end
end
end
end

function Nidalee:ClearQ()
	if self.Menu.Clear.UseQ:Value() and self:isHuman() and self:CanCast(_Q) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 or minion.name == "SRU_Krug" then
			if minion.pos:DistanceTo(myHero.pos) < 1500 then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 1 ) and minion.pos2D.onScreen then
			Control.CastSpell(HK_Q,castpos)
			else if self:isAnimal() and self:CanCast(_Q) and minion.pos:DistanceTo(myHero.pos) < 300 then
			Control.CastSpell(HK_Q, minion)
	end
end
end
end
end
end
end

function Nidalee:ClearQQminion()
	if self.Menu.Clear.UseQ:Value() and self:isAnimal() and self:CanCast(_Q) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 350 then
			Control.CastSpell(HK_Q, minion)
	end
end
end
end
end

function Nidalee:ClearW()
if self.Menu.Clear.UseW:Value() then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 900 then
		   local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and self:CanCast(_W) then
			Control.CastSpell(HK_W,castpos)
		else if HasBuff(minion, "NidaleePassiveHunted") and self:isHuman() and self:CanCast(_R) then
			Control.CastSpell(HK_R)	
		else if self:isAnimal() and not HasBuff(minion, "NidaleePassiveHunted") and self:CanCast(_W) and minion.pos:DistanceTo(myHero.pos) < 400 then
			Control.CastSpell(HK_W, minion)
							end
						end
					end
				end
			end
		end
	end
end

function Nidalee:ClearWMinionJump()
if self.Menu.Clear.UseW:Value() then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 700 then
		if HasBuff(minion, "NidaleePassiveHunted") and self:isAnimal() and self:CanCast(_W) and minion.pos:DistanceTo(myHero.pos) < 700 then
			Control.CastSpell(HK_W, minion)		
					end
				end
			end
		end
	end
end

function Nidalee:AutoHealClear()
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 600 then
		if myHero.health<=myHero.maxHealth * self.Menu.Clear.Eheal:Value()/100 and minion.pos:DistanceTo(myHero.pos) < 600 and self:isHuman() and self:CanCast(_E) then
			    Control.CastSpell(HK_E, myHero)		
		else if myHero.health<=myHero.maxHealth * self.Menu.Clear.Eheal:Value()/100 and minion.pos:DistanceTo(myHero.pos) < 60 and self:isAnimal() and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
	end
end
end
end
end
end

function Nidalee:DistQClear()
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
		if minion.pos:DistanceTo(myHero.pos) > 400 and self:isAnimal() and self:CanCast(_R) and not HasBuff(minion, "NidaleePassiveHunted") then
			    Control.CastSpell(HK_R)
		else if minion.pos:DistanceTo(myHero.pos) < 400 and self:isHuman() and self:CanCast(_R) then
			    Control.CastSpell(HK_R)
	end
end
end
end
end

-- SRU_Razorbeak
-- SRU_Red
-- SRU_Krug
-- SRU_Gromp
-- SRU_Blue
-- SRU_
-- SRU_
-- SRU_
-- SRU_

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

function Nidalee:Lasthit()
	if self:CanCast(_Q) and self.Menu.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Nidalee:QDMG()
			local QdamageA = Nidalee:QdamageAnimal()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= self:HpPred(minion,1) and self:isHuman() and (HitChance > 0 ) then
			    self:CastSpell(HK_Q, castpos)
			else if minion.pos:DistanceTo(myHero.pos) < 300 and self:isAnimal() then
				if QdamageA >= self:HpPred(minion,1) then
			    self:CastSpell(HK_Q, minion)
				end
			end
		end
	end
end
end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Nidalee:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({170, 190, 230, 260, 300})[level] + 1.2 * myHero.ap
	return qdamage
end

function Nidalee:QdamageAnimal()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({70, 85, 100, 115, 130})[level] + 0.4 * myHero.ap
	return qdamage
end

function Nidalee:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = ({70, 130, 190, 250})[myHero:GetSpellData(_R).level] + 0.45 * myHero.ap
	return edamage
end

function Nidalee:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = ({200, 300, 400})[level] + 0.7 * myHero.ap
	return rdamage
end


function isValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end

-------------------------
--Q KS
-------------------------

function Nidalee:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Nidalee:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:isHuman() and target.pos:DistanceTo(myHero.pos) > 900 then
			    self:CastSpell(HK_Q,castpos)
			else if self:isAnimal()	and self:CanCast(_R) then
			Control.CastSpell(HK_R)
				end
			end
		end
	end
end
end

function Nidalee:Zhonya()
    local target = CurrentTarget(500)
	if target == nil then return end
		if self.Menu.Items.Zhonya:Value() and myHero.pos:DistanceTo(target.pos) < 500 and myHero.health<=myHero.maxHealth * self.Menu.Items.ZhonyaHp:Value()/100 and not HasBuff(myHero, "camouflagestealth") then
		local Zhonya = GetInventorySlotItem(3157) or GetInventorySlotItem(2421)
		if Zhonya then
			Control.CastSpell(HKITEM[Zhonya])
		end
	end
	end
function Nidalee:Items()	
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

function Nidalee:IgniteSteal()
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
	
function Nidalee:CC()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.CC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy and self:isHuman() and (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
			else if self:isAnimal() and self:CanCast(_R) then
				Control.CastSpell(HK_R)
				end
			end
		end
	end
	end
	
function Nidalee:CCW()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.CC.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if ImmobileEnemy and self:isHuman() and (HitChance > 0 ) then
				Control.CastSpell(HK_W, castpos)
			else if self:isAnimal() and self:CanCast(_R) then
				Control.CastSpell(HK_R)
				end
			end
		end
	end
	end

Callback.Add("Load",function() _G[myHero.charName]() end)