local Heroes = {"Zed"}

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0","Kypo's","8.1"

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
	

class "Zed"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/c7/Death_Sworn_Zed_profileicon.png"

function Zed:LoadSpells()

	Q = {Range = 900, Width = 45, Delay = 0.15, Speed = 902, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 90, Delay = 0.10, Speed = 1750, Collision = false, aoe = false, Type = "line"}
	E = {Range = 290, Width = 100, Delay = 0.05, Speed = 0, Collision = false, aoe = false, Type = "circular"}
	R = {Range = 625, Width = 1, Delay = 0, Speed = 0, Collision = false, aoe = false, Type = "line"}

end

function Zed:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Zed", name = "Kypo's Zed", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Combo:MenuElement({id = "UseW", name = "W", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false})
	self.Menu.Combo:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Combo.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Clear:MenuElement({id = "QClear", name = "Use Q If Hit X Minion ", value = 3, min = 1, max = 5, step = 1})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseWEQ", name = "WEQ", value = false, key = string.byte("T")})
	self.Menu.Flee:MenuElement({id = "RKey", name = "R Key", value = false, key = string.byte("2")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	self.Menu.Killsteal:MenuElement({id = "Ignite", name = "Ignite", value = true})
	
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
    self.Menu.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	self.Menu.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    self.Menu.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    self.Menu.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    self.Menu.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 241, 79, 79)})
	
	self.Menu.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    self.Menu.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Zed:__init()
	
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

function Zed:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end	
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
		self:RCombo()
	end
	if self.Menu.Clear.clearActive:Value() then
		self:ClearQCount()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealE()
		self:Flee()
		self:Items()
		self:IgniteSteal()
end

function Zed:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Zed:Ignite(target)
    if target and GetDistance(myHero.pos, target.pos) <= 600 then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and self:IsReady(SUMMONER_1) then
            Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and self:IsReady(SUMMONER_2) then
            Control.CastSpell(HK_SUMMONER_2, target)
        end
    end
end

function Zed:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function Zed:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Zed:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Zed:CanCast(spellSlot)
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

function Zed:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function Zed:GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
	end
end

function Zed:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Zed:EnemyInRange(range)
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

function Zed:Draw()
-- for i, shadow in pairs(self:Shadowpos()) do
			-- if shadow then
				-- Draw.Circle(shadow.pos,80,1, Draw.Color(200, 183, 107, 255))
			-- end
		-- end
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 900, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 650, self.Menu.Drawings.W.Width:Value(), self.Menu.Drawings.W.Color:Value()) end
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
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
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

function Zed:CastSpell(spell,pos)
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

function Zed:HpPred(unit, delay)
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

function Zed:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function HasBuff(unit, buffName)
		for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name:lower() == buffName:lower()and buff.count > 0 then
				return true
			end
		end
	return false
end

-----------------------------
-- Flee
-----------------------------

function Zed:Flee()
local target = CurrentTarget(750)
if target == nil then return end
	if self.Menu.Flee.UseWEQ:Value() then
		if self:CanCast(_Q) and self:CanCast(_W) and self:CanCast(_E) and myHero:GetSpellData(_W).name ~= "ZedW2" then
            if self:EnemyInRange(750) then
				local castposq,HitChanceq, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				local castposw,HitChancew, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
				if (HitChancew > 0 ) then
				self:CastWforFlee(castposw)
                DelayAction(function()
                Control.CastSpell(HK_E)
                end, 0.50)
				if (HitChanceq > 0 ) then
                DelayAction(function()
                Control.CastSpell(HK_Q, castposq)
            end, 0.3)
			end
		end
	end
end
end

	local target = CurrentTarget(630)
    if target == nil then return end
	    if self.Menu.Flee.RKey:Value() and target and self:CanCast(_R) then
	    if self:EnemyInRange(630) then
			Control.SetCursorPos(target)
			Control.KeyDown(HK_R)
			Control.KeyUp(HK_R)
			-- Control.CastSpell(HK_R, target.pos)
		end
	end


end

function Zed:CastWforFlee(canto)
    if canto then
            Control.CastSpell(HK_W, canto)
            if not self:HasBuff(myHero, "ZedWHandler") then
            canto = canto
        end
    end  
end

function Zed:NoR2(cast)
    if cast then
            Control.CastSpell(HK_R, cast)
            if not self:HasBuff(target, "zedrtargetmark") then
            cast = cast
        end
    end  
end

function Zed:RCombo()
	local target = CurrentTarget(630)
	if target == nil then return end
	if self.Menu.Combo.RR["UseR"..target.charName]:Value() and target and self:CanCast(_R) then
		if self:EnemyInRange(630) and not HasBuff(target, "zedrtargetmark") then 
			Control.CastSpell(HK_R, target)
		else if target and HasBuff(target, "zedrtargetmark") then
			return end
		end
	end
end

-----------------------------
-- COMBO
-----------------------------

function Zed:Combo()
local target = CurrentTarget(750)
    if target == nil then return end
	    if self.Menu.Combo.UseW:Value() and target and self:CanCast(_W) then
	    if self:EnemyInRange(750) then
			Control.CastSpell(HK_W, target)
		else if self.Menu.Combo.UseE:Value() and self:EnemyInRange(290) then
			Control.CastSpell(HK_E)
		end
	end
	end
	
	local target = CurrentTarget(290)
    if target == nil then return end
	    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(290) then
			Control.CastSpell(HK_E)
		end
	end
	
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
end

-----------------------------
-- HARASS
-----------------------------

function Zed:Harass()
local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	
	local target = CurrentTarget(290)
    if target == nil then return end
	-- local shadowpos = self:Shadowpos(pos)
    if self.Menu.Harass.UseE:Value() and target and self:CanCast(_E) then
	    if self:EnemyInRange(290) then
			Control.CastSpell(HK_E)
		end
	end

end

-- function Zed:Shadowpos()
	-- self.Shadow = {}
	-- for i = 1, Game.ObjectCount() do
		-- local shadow = Game.Object(i)
		-- if shadow and not shadow.dead and shadow.name:find("ZedWHandler") then
			-- table.insert(self.Shadow, shadow)
		-- end
	-- end
	-- return self.Shadow
-- end


-----------------------------
-- Clear
-----------------------------

function Zed:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_Q) then 
			if self.Menu.Clear.UseQ:Value() and minion then
				if Zed:ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

-----------------------------
-- LASTHIT
-----------------------------

function Zed:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = self:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < 900 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end

if self:CanCast(_E) then
		local level = myHero:GetSpellData(_E).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = self:EDMG()
			if minion.pos:DistanceTo(myHero.AttackRange) < 290 and self.Menu.Lasthit.UseE:Value() and minion.isEnemy and not minion.dead then
				if Edamage >= minion.health and self:CanCast(_E) then
				Control.CastSpell(HK_E)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Zed:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({60,95,120,160,160})[level] + 0.6 * myHero.totalDamage)
	return qdamage
end

function Zed:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({70,95,120,145,170})[level] + 0.2 * myHero.totalDamage)
	return edamage
end

-- function Zed:RDMG()
    -- local level = myHero:GetSpellData(_R).level
    -- local rdamage = (({100, 200, 350})[level] + 1.5 * myHero.totalDamage)
	-- return rdamage
-- end

function Zed:ValidTarget(unit,range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end

-----------------------------
-- Q KS
-----------------------------

function Zed:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Zed:QDMG()
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
	
	function Zed:IgniteSteal()
	local target = CurrentTarget(600)
	if target == nil then return end
	if self.Menu.Killsteal.Ignite:Value() and target then
		if self:EnemyInRange(600) then 
			local IgniteDMG = 50+20*myHero.levelData.lvl
			if IgniteDMG >= self:HpPred(target,1) + target.hpRegen * 3 then
				self:Ignite(target)
				end
			end
		end
	end

	function Zed:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
		   	local Edamage = Zed:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_E,target)
				end
			end
		end
	end


function Zed:ClearQCount(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_Q) then 
			if self.Menu.Clear.UseQ:Value() and minion and minion:GetCollision(45, 902, 0.15) - 1 >= self.Menu.Clear.QClear:Value() then
					Control.CastSpell(HK_Q, minion)
    end
  end
end
end
end

function Zed:Items()
	local target = CurrentTarget(self.Menu.Items.YoumuuDistance:Value())
	if target == nil then return end
		if self.Menu.Items.Youmuu:Value() and myHero.pos:DistanceTo(target.pos) < self.Menu.Items.YoumuuDistance:Value() then
		local Youmuu = GetInventorySlotItem(3142)
		if Youmuu and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(HKITEM[Youmuu])
		end
	end
	
	local target = CurrentTarget(550)
	if target == nil then return end
		if self.Menu.Items.BladeRK:Value() then
		local BladeRK = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
		if BladeRK and self:EnemyInRange(550) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(HKITEM[BladeRK], target)
		end
	end
	
	local target = CurrentTarget(320)
	if target == nil then return end
		if self.Menu.Items.Hydra:Value() then
		local Hydra = GetInventorySlotItem(3074) or GetInventorySlotItem(3077)
		if Hydra and self:EnemyInRange(320) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(HKITEM[Hydra], target)
		end
	end
	
	local target = CurrentTarget(700)
	if target == nil then return end
		if self.Menu.Items.Hydra:Value() then
		local Hydra = GetInventorySlotItem(3748) or GetInventorySlotItem(3077)
		if Hydra and self:EnemyInRange(700) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(HKITEM[Hydra], target)
		end
	end
	
	local target = CurrentTarget(320)
	if target == nil then return end
		if self.Menu.Items.Tiamat:Value() then
		local Tiamat = GetInventorySlotItem(3077)
		if Tiamat and self:EnemyInRange(320) and self.Menu.Combo.comboActive:Value() then
			Control.CastSpell(HKITEM[Tiamat], target)
		end
	end
	end


Callback.Add("Load",function() _G[myHero.charName]() end)