local Heroes = {"Teemo"}
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
-- Teemo
---------------------------------------------------------------------------------------

class "Teemo"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/04/TeemoSquare.png"

function Teemo:LoadSpells()

	Q = {Range = 680, Width = 40, Delay = 0.40, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Delay = 1.00, Speed = 1200, Collision = false, aoe = false, Type = "line", Radius = 200}

end

function Teemo:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Teemo", name = "Kypo's Teemo", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseR", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "RCount", name = "Use R on X minions", value = 3, min = 1, max = 6, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "Ignite", name = "Ignite", value = true})	
	
	-- self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	-- self.Menu.Flee:MenuElement({id = "Rkey", name = "R on important spots",  key = string.byte("T")})

	self.Menu:MenuElement({id = "CC", name = "CC", type = MENU})
	self.Menu.CC:MenuElement({id = "UseR", name = "R", value = true})
	
	self.Menu:MenuElement({id = "Items", name = "Items", type = MENU})
    self.Menu.Items:MenuElement({id = "Zhonya", name = "Zhonya", value = true})
    self.Menu.Items:MenuElement({id = "ZhonyaHp", name = "Min HP",value=15,min=1,max=30})
	self.Menu.Items:MenuElement({id = "Protobelt", name = "Hextech Protobelt", value = true})
	self.Menu.Items:MenuElement({id = "GLP", name = "Hextech GLP", value = true})
	self.Menu.Items:MenuElement({id = "Gunblade", name = "Hextech Gunblade", value = true})	
	
	self.Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	self.Menu.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    self.Menu.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw E range", type = MENU})
    self.Menu.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R Loc
	self.Menu.Drawings:MenuElement({id = "RLoc", name = "Draw R Locs", type = MENU})
    self.Menu.Drawings.RLoc:MenuElement({id = "Enabled", name = "Normal", value = true})       
    self.Menu.Drawings.RLoc:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.RLoc:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Teemo:__init()
	
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

function Teemo:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:Items()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:Clear()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	-- if self.Menu.Flee.Rkey:Value() then
		-- self:RKey()
	-- end			
		self:KillstealQ()
		self:R()
		self:CC()
		self:Zhonya()
	end
	
function Teemo:R()
		for i = 1, Game.ParticleCount() do 
			local particle = Game.Particle(i)
			if particle.name == "Teemo_Base_R_CollisionBox_Ring" then 
				rr = particle.pos 
				break
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

function Teemo:GetValidMinion(range)
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

function Teemo:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Teemo:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Teemo:CanCast(spellSlot)
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

function Teemo:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Teemo:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Teemo:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Teemo:RDrawnormal()
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

function Teemo:RRange()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 1 then
		return 400
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 2 then
		return 650
	elseif self:CanCast(_R) and myHero:GetSpellData(_R).level == 3 then
		return 900
	end
end

local RLoc ={
Vector(3100,-68,10830), Vector(2892,-71,11282), Vector(3058,-70,11478), Vector(3186,-66,11656), Vector(3302,-63,11826), Vector(3792,-54,11458), Vector(3856,-71,11260), Vector(4186,43,11558), Vector(4408,57,11744), Vector(4406,56,11956), Vector(3750,54,12842), Vector(3923,53,12917), Vector(2562,53,13568), Vector(2214,53,13416), Vector(1990,52,13252), Vector(1766,45,13100), Vector(1569,53,12916), Vector(1392,53,12674), Vector(1220,53,12430), Vector(1128,53,12140), Vector(1942,53,11642), Vector(2480,33,11812), Vector(2782,21,11928), Vector(2884,53,12316), Vector(3592,-53,9640), Vector(3758,-50,9488), Vector(3532,49,9078), Vector(3540,-67,10178), Vector(6164,-68,9350), Vector(6356,-55,9212), Vector(6252,54,10296), Vector(6514,56,11332), Vector(5480,53,12670), Vector(5474,53,13060), Vector(5140,56,12320), Vector(4670,56,12438), Vector(8278,50,10274), Vector(8774,51,10540), Vector(8816,50,9796), Vector(7176,54,9818), Vector(7040,53,9058), Vector(7524,53,8692), Vector(4846,27,8422), Vector(4422,-66,9228), Vector(3864,-70,10472), Vector(3379,-68,11089), Vector(3468,-67,11446), Vector(3790,-71,10782), Vector(5206,57,11566), Vector(5838,56,10988), Vector(7424,51,11574), Vector(3298,52,7780), Vector(2984,52,7786), Vector(2442,50,7428), Vector(1962,50,7700), Vector(822,53,8164), Vector(1608,53,9306), Vector(1920,53,9630), Vector(2348,54,9744), Vector(2948,54,10068), Vector(3064,52,9772), Vector(3058,51,9298), Vector(4240,-67,9454), Vector(5248,-71,9130), Vector(5126,-26,8472), Vector(4874,52,7946), Vector(5992,52,7230), Vector(5634,52,7493), Vector(5110,51,7739), Vector(4840,51,7059), Vector(6806,55,13000), Vector(7334,56,12480), Vector(7870,56,11796), Vector(6968,54,11382), Vector(7833,52,10988), Vector(8494,50,9866), Vector(8942,50,11050), Vector(8150,56,11776), Vector(8534,56,12298), Vector(8734,55,12901), Vector(8412,53,13246), Vector(9580,53,13044), Vector(9610,52,12533), Vector(9636,52,11856), Vector(9353,53,11490), Vector(9022,55,11406)
}

-----------------------------
-- DRAWINGS
-----------------------------

function Teemo:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.R.Enabled:Value() then self:RDrawnormal() end

			if self.Menu.Drawings.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (self:CanCast(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + RDamage + EDamage
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
	if self.Menu.Drawings.RLoc.Enabled:Value() then
	for i=1,150,1 do
		if myHero.pos:DistanceTo(RLoc[i]) < 900 and self:CanCast(_R) then
					Draw.Circle(RLoc[i],80,self.Menu.Drawings.RLoc.Width:Value(), self.Menu.Drawings.RLoc.Color:Value()) 
end
end
end
end


function Teemo:CastSpell(spell,pos)
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

function Teemo:HpPred(unit, delay)
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

function Teemo:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
	return false	
end

-----------------------------
-- COMBO
-----------------------------

function Teemo:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q, target)
		end
	end
end


-----------------------------
-- Clear
-----------------------------

function Teemo:Clear()
	if self:CanCast(_R) then
	local rMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  isValidTarget(minion,self:RRange())  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				rMinions[#rMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(self:RRange(), 350, rMinions)
		if BestHit >= self.Menu.Clear.RCount:Value() and self.Menu.Clear.UseR:Value() then
		Control.CastSpell(HK_R,BestPos)
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

function Teemo:Lasthit()
	if self:CanCast(_Q) and self.Menu.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Teemo:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= self:HpPred(minion,1) then
			    Control.CastSpell(HK_Q,minion)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Teemo:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({80, 125, 170, 215, 260})[level] + 0.8 * myHero.ap
	return qdamage
end

function Teemo:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = ({200, 325, 450})[level] + 0.5 * myHero.ap
	return rdamage
end


function isValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end

-----------------------------
-- Q KS
-----------------------------

function Teemo:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Teemo:QDMG()
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

function Teemo:KillstealW()
	local target = CurrentTarget(1300)
	if target == nil then return end
	if self.Menu.Killsteal.UseW:Value() and target and self:CanCast(_W) then
		   	local Wdamage = Teemo:WDMG()
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



function Teemo:Zhonya()
    local target = CurrentTarget(500)
	if target == nil then return end
		if self.Menu.Items.Zhonya:Value() and myHero.pos:DistanceTo(target.pos) < 500 and myHero.health<=myHero.maxHealth * self.Menu.Items.ZhonyaHp:Value()/100 and not HasBuff(myHero, "camouflagestealth") then
		local Zhonya = GetInventorySlotItem(3157) or GetInventorySlotItem(2421)
		if Zhonya then
			Control.CastSpell(HKITEM[Zhonya])
		end
	end
	end
function Teemo:Items()	
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

function Teemo:IgniteSteal()
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
	
function Teemo:CC()
    local target = CurrentTarget(self:RRange())
	if target == nil then return end
	if self.Menu.CC.UseR:Value() and target and self:CanCast(_R) then
		if self:EnemyInRange(self:RRange()) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if ImmobileEnemy then
				Control.CastSpell(HK_R, target)
				end
			end
		end
	end

Callback.Add("Load",function() _G[myHero.charName]() end)