local Heroes = {"Lucian","Morgana","Twitch","Jhin","Ashe","Alistar","Ahri","Azir","Blitzcrank","Draven","Ezreal","Fizz","Jinx","Kalista","KogMaw","Leblanc","LeeSin","Lux","Nasus","Nidalee","Orianna","Syndra","Teemo","Thresh","Tristana","Caitlyn","Veigar","Yasuo","Zed", "Annie","Akali"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"
require "MapPosition"

local AIOIcon = "https://raw.githubusercontent.com/Kypos/GOS-External/master/misc/AIOIcon.png"
local EssentialsIcon = "https://raw.githubusercontent.com/Kypos/GOS-External/master/misc/Essentials.png"

local _wards = {2055, 2049, 2050, 2301, 2302, 2303, 3340, 3361, 3362, 3711, 1408, 1409, 1410, 1411, 2043, 2055}
local ultimocast = 0
local Position=mousePos
local RedPos = {Vector(14300,172,14380)}
local BluePos = {Vector(408,183,418)}
local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v0.3","Kypos","8.4"
local EDMG = {}

local HKITEM = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,
	[ITEM_7] = HK_ITEM_7,
}

keybindings = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6}
hkitems = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6,[ITEM_7] = HK_ITEM_7, [_Q] = HK_Q, [_W] = HK_W, [_E] = HK_E, [_R] = HK_R }


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

function GetPercentHP(unit)
  return 100 * unit.health / unit.maxHealth
end

function DisableOrb()
	if _G.SDK.TargetSelector:GetTarget(900) then
		_G.SDK.Orbwalker:SetMovement(false)
		_G.SDK.Orbwalker:SetAttack(false)
		end
end

function EnableOrb()
	if _G.SDK.TargetSelector:GetTarget(900) then
		_G.SDK.Orbwalker:SetMovement(true)
		_G.SDK.Orbwalker:SetAttack(true)	
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

function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end


function EnemyInRange(range)
	local count = 0
	for i, target in ipairs(GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
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

function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

function EnemiesNear(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function GetEnemyHeroes()
	EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return EnemyHeroes
end

function GetAllyHeroes()
	AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and not Hero.isMe then
			table.insert(AllyHeroes, Hero)
		end
	end
	return AllyHeroes
end

function IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Ready(spellSlot)
	return IsReady(spellSlot)
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

function CastSpell(spell,pos)
	local customcast = AIO.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = AIO.delay:Value()
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

function GetDistanceSqrYas(a, b)
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

function GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
	end
end


-- CHAMPS:

class "Fizz"


function Fizz:LoadSpells()

	Q = {Range = 550, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 225, Delay = 0.25}
	E = {Range = 800}
	R = {Range = 1300, Width = 150, Delay = 0.60, Speed = 1300, Collision = false, aoe = true}

end

function Fizz:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Fizz", name = "Kypo's AIO: Fizz", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = false})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "SemiR", name = "R Key", type = MENU})
	AIO.SemiR:MenuElement({id = "UseR", name = "R", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Fizz:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
		self:KillstealQ()
		self:KillstealR()
		self:RksCC()
		self:SemiR()
		self:Wuse()
		self:Quse()
		self:Euse()
	
end

function Fizz:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 550, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 400, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1300, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_R) then
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

function Fizz:CastQ(target)
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = target or (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.Range,"AP"))
	if target and target.type == "AIHeroClient" and Ready(_Q) then
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
	if AIO.SemiR.UseR:Value() and Ready(_R) then
		if EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1300,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and Ready(_R) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Fizz:Wuse()
 if AIO.Combo.comboActive:Value() and AIO.Combo.UseW:Value() and Ready(_W) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if EnemyInRange(225) then 
			local level = myHero:GetSpellData(_W).level	
			if target then
			Control.CastSpell(HK_W,target)
		end
	end
end
end

function Fizz:Quse()
	if AIO.Combo.comboActive:Value() and AIO.Combo.UseQ:Value() and Ready(_Q) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end
end

function Fizz:Euse()
    if AIO.Combo.comboActive:Value() and AIO.Combo.UseE:Value() and Ready(_E) then
	local target = CurrentTarget(800)
	if target == nil then return end
		if EnemyInRange(800) then 
			local level = myHero:GetSpellData(_E).level	
			if target then
			Control.CastSpell(HK_E,target)
		end
	end
end
end

function Fizz:Harass()
     if AIO.Harass.UseQ:Value() and AIO.Harass.UseQ:Value() and Ready(_Q) and EnemyInRange(Q.Range) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end

     if AIO.Harass.UseQ:Value() and AIO.Harass.UseW:Value() and Ready(_W) and EnemyInRange(W.Range) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if EnemyInRange(225) then 
			local level = myHero:GetSpellData(_W).level	
			if target then
			Control.CastSpell(HK_W,target)
			end
		end
	end
end
	
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

function Fizz:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		   	local Qdamage = Fizz:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    self:CastQ()
				end
			end
		end
	end

function Fizz:KillstealR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Fizz:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Fizz:RksCC()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
		if EnemyInRange(1300) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		 	local Rdamage = Fizz:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

class "Veigar"


function Veigar:LoadSpells()

	Q = {Range = 900, Width = 70, Delay = 0.40, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 0, Delay = 0.90, Speed = 2000, Collision = false, aoe = true, Type = "circle", radius = 112}
	E = {Range = 725, Width = 0, Delay = 0.50, Speed = 20, Collision = false, aoe = false, Type = "circle"}
	R = {Range = 650, Width = 0, Delay = 1.00, Speed = 500, Collision = false, aoe = false, Type = "line"}

end

function Veigar:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Veigar", name = "Kypo's AIO: Veigar", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "WWait", name = "Only W when stunned", value = true})
	AIO.Combo:MenuElement({id = "EMode", name = "E Mode", drop = {"Edge", "Middle"}})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "AutoQ", name = "Auto Q Toggle", value = false, toggle = true, key = string.byte("U")})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "AutoQFarm", name = "Auto Q Farm", value = false, toggle = true, key = string.byte("Z")})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "WHit", name = "W hits x minions", value = 3,min = 1, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Mana", name = "Mana", type = MENU})
	AIO.Mana:MenuElement({id = "QMana", name = "Min mana to use Q", value = 35, min = 0, max = 100, step = 1})
	AIO.Mana:MenuElement({id = "WMana", name = "Min mana to use W", value = 40, min = 0, max = 100, step = 1})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = false})
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS on:", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "UseW", name = "W", value = true})
	AIO.isCC:MenuElement({id = "UseE", name = "E", value = false})
	AIO.isCC:MenuElement({id = "EMode", name = "E Mode", drop = {"Edge", "Middle"}})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})

	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Veigar:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
	if AIO.Combo.comboActive:Value() then
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
	if Ready(_Q) and AIO.Clear.UseW:Value() then
	local qMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,900)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				qMinions[#qMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(50,112 + 80, qMinions)
		if BestHit >= AIO.Clear.WHit:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= AIO.Mana.WMana:Value() / 100 ) then
			CastSpell(HK_W,BestPos)
		end
	end
end
end

function Veigar:Draw()
if AIO.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 40, textPos.y + 100, Draw.Color(255, 60, 145, 201))
		end
if AIO.Lasthit.AutoQFarm:Value() then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q Farm", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 60, 145, 201))
			end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range , AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(255, 200, 200, 25))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value()) end
				end
			end
		end	
		
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 255, 000, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

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

function Veigar:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and (myHero.mana/myHero.maxMana >= AIO.Mana.QMana:Value() / 100 ) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
		if AIO.Combo.EMode:Value() == 1 then
			CastSpell(HK_E, Vector(target:GetPrediction(E.speed,E.delay))-Vector(Vector(target:GetPrediction(E.speed,E.delay))-Vector(myHero.pos)):Normalized()*270)
		elseif AIO.Combo.EMode:Value() == 2 then
			CastSpell(HK_E,target)
		end
    end	
 end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) and (myHero.mana/myHero.maxMana >= AIO.Mana.WMana:Value() / 100 ) then
	    if EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    local ImmobileEnemy = self:IsImmobileTarget(target)
			if (HitChance > 0 ) then
        if AIO.Combo.WWait:Value() and not ImmobileEnemy then return end
			CastSpell(HK_W, castpos)
				end
	    end
    end
    end

function Veigar:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) and (myHero.mana/myHero.maxMana >= AIO.Mana.QMana:Value() / 100 ) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
		    end
	    end
    end
 
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) and (myHero.mana/myHero.maxMana >= AIO.Mana.WMana:Value() / 100 ) then
	    if EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_W, castpos)
		    end
	    end
    end
end

function Veigar:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({65,105,145,185,215})[level] + 0.60 * myHero.ap)
	return qdamage
end

function Veigar:WDMG()
    local level = myHero:GetSpellData(_R).level
    local wdamage = ({100,150,200,250,300})[level] + 1.00 * myHero.ap
	return wdamage
end

function Veigar:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({175,250,325})[level] + 0.75 * myHero.ap)
	return rdamage
end

function Veigar:AutoQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Harass.AutoQ:Value() and target and Ready(_Q) and (myHero.mana/myHero.maxMana >= AIO.Mana.QMana:Value() / 100 ) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and Ready(_Q) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end

function Veigar:AutoQFarm()
	if Ready(_Q) and AIO.Lasthit.AutoQFarm:Value() and (myHero.mana/myHero.maxMana >= AIO.Mana.QMana:Value() / 100 ) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({70,110,150,190,230})[level] + 0.60 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and minion.isEnemy and not minion.dead then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				if Qdamage >= HpPred(minion,1) and (HitChance > 0 ) then
				CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

function Veigar:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({70,110,150,190,230})[level] + 0.60 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				if Qdamage >= HpPred(minion,1) and (HitChance > 0 ) then
				CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

function Veigar:KillstealR()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(R.Range) then 
			local level = myHero:GetSpellData(_R).level	
			local dmg = GetPercentHP(target) > 33.3 and ({150, 225, 300})[level] + 0.75 * myHero.ap or ({330, 475, 630})[level] + 0.75 * myHero.ap
			local Rdamage = dmg +((0.015 * dmg) * (100 - ((target.health / target.maxHealth) * 100)))
			if Rdamage >= HpPred(target,1) * 1.2 + target.hpRegen * 2 then
				CastSpell(HK_R, target)
				end
			end
		end
	end

function Veigar:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Veigar:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

function Veigar:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Veigar:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			if (HitChance > 0 ) then
				CastSpell(HK_W, castpos)
				end
			end
		end
	end
end

function Veigar:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and not target.dead then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

function Veigar:SpellonCCE()
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.isCC.UseE:Value() and target and Ready(_E) then
		local ImmobileEnemy = self:IsImmobileTarget(target)
	    if EnemyInRange(E.Range) and ImmobileEnemy then
		if AIO.isCC.EMode:Value() == 1 then
			Control.CastSpell(HK_E, Vector(target:GetPrediction(E.speed,E.delay))-Vector(Vector(target:GetPrediction(E.speed,E.delay))-Vector(myHero.pos)):Normalized()*300)
		elseif AIO.isCC.EMode:Value() == 2 then
			CastSpell(HK_E,target)
		end
    end	
 end
 end

function Veigar:SpellonCCW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.isCC.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
				CastSpell(HK_W, castpos)
				end
			end
		end
	end

class "Nasus"


function Nasus:LoadSpells()

	Q = {Range = 150, Width = 50, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 600, Width = 50, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	E = {Range = 650, Width = 400, Delay = 0.25, Speed = 1600, Collision = false, aoe = false, Type = "circular"}
	R = {Range = 800, Width = 1, Delay = 0.25, Speed = 1000, Collision = false, aoe = false}

end

function Nasus:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Nasus", name = "Kypo's AIO: Nasus", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "MinRCast", name = "R", value = true})
	AIO.Combo:MenuElement({id = "MinRHealth",name="Min Health -> %",value=20,min=10,max=100})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "EHit", name = "E hits x minions", value = 3,min = 1, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Bonus", name = "Bonus", type = MENU})
	AIO.Bonus:MenuElement({id = "UseQ", name = "Auto Farm", value = false, toggle = true, key = string.byte("T")})
	AIO.Bonus:MenuElement({id = "QRange", name = "Draw/Set AutoQ range:", value = 300,min = 175, max = 700, step = 1})
	AIO.Bonus:MenuElement({id = "blank", type = SPACE , name = "It can also Steal jungle! (OP)"})

	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})

	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})

	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Nasus:__init()
	
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

function Nasus:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:HarassE()
		self:HarassQ()
	end
	if AIO.Combo.comboActive:Value() then
		self:ComboE()
		self:ComboQ()
		self:ComboW()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealE()
		self:MinRCast()
		self:Autofarm()
end

function Nasus:Draw()
	if AIO.Drawings.DrawDamage:Value() then
    for i = 1, Game.HeroCount() do
      local target = Game.Hero(i)
      if target and target.isEnemy and not target.dead and target.visible then
        local barPos = target.hpBar
        local health = target.health
        local maxHealth = target.maxHealth
        local Qdmg = self:QDMG(target)
          Draw.Rect(barPos.x + (( (health - Qdmg) / maxHealth) * 100) + 25, barPos.y - 13, (Qdmg / maxHealth )*100, 10, Draw.Color(200, 255, 255, 255))
			end
		end
	end

	
	if AIO.Bonus.UseQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Farm ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(220, 255, 255, 255))
			end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 650, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if AIO.Bonus.UseQ:Value() then Draw.Circle(myHero.pos, AIO.Bonus.QRange:Value(), Draw.Color(220, 207, 27, 73)) end
end

function Nasus:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Nasus:ComboQ()
    if AIO.Combo.UseQ:Value() and Ready(_Q) then
		local target = CurrentTarget(300)
		if target == nil then return end
	    if EnemyInRange(300) then
			    Control.CastSpell(HK_Q)
		    end
	    end
	    end
		
function Nasus:ComboW()
	if AIO.Combo.UseW:Value() and Ready(_W) then
	local target = CurrentTarget(600)
    if target == nil then return end
		if EnemyInRange(600) and target then 
			    Control.CastSpell(HK_W, target)
            end
		end
		end
		
function Nasus:ComboE()
	if AIO.Combo.UseE:Value() and Ready(_E) then
	local target = CurrentTarget(650)
    if target == nil then return end
		if EnemyInRange(650) and target then 
			    CastSpell(HK_E, target)
            end
		end
end

function Nasus:HarassQ()
    local target = CurrentTarget(300)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(300) then
			    Control.CastSpell(HK_Q)
		    end
	    end
	    end
		
function Nasus:HarassE()
    local target = CurrentTarget(650)
    if target == nil then return end
	if AIO.Harass.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(650) and target then 
			    CastSpell(HK_E, target)
		    end
	    end
    end

function Nasus:Clear()
	if AIO.Clear.UseQ:Value() and Ready(_Q) then
	for i = 1, Game.MinionCount() do
	local target = Game.Minion(i)
	if target and target.team == 300 or target.team ~= myHero.team then
			if myHero.pos:DistanceTo(target.pos) < 300 and target.isEnemy then
			if target then
				if self:QDMG(target) >= HpPred(target,1) then
				Control.CastSpell(HK_Q)
				Control.Attack(target)
					end
				end
			end
		end
	end
	
	if AIO.Clear.UseE:Value() and Ready(_E) then
	local eMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,650)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				eMinions[#eMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(450,400 + 48, eMinions)
		if BestHit >= AIO.Clear.EHit:Value() then
			Control.CastSpell(HK_E,BestPos)
		end
	end
end
end
end

function Nasus:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local target = Game.Minion(i)
			if myHero.pos:DistanceTo(target.pos) < 200 and AIO.Lasthit.UseQ:Value() and not target.dead and target.isEnemy then
				if self:QDMG(target) >= HpPred(target,1) then
				Control.CastSpell(HK_Q)
				Control.Attack(target)
				end
			end
		end
	end
end

function Nasus:Autofarm()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local target = Game.Minion(i)
			if myHero.pos:DistanceTo(target.pos) < AIO.Bonus.QRange:Value() and AIO.Bonus.UseQ:Value() and target.isEnemy and not target.dead then
				if self:QDMG(target) >= HpPred(target,1) then
				Control.CastSpell(HK_Q)
				Control.Attack(target)
				end
			end
		end
	end
end

local function GetBuffIndexByName(unit,name)
  for i=1,unit.buffCount do
    local buff=unit:GetBuff(i)
    if buff.name==name then
      return i
    end
  end
end

function Nasus:QDMG(target)
local level = myHero:GetSpellData(_Q).level
return CalcPhysicalDamage(myHero, target, (myHero:GetBuff(GetBuffIndexByName(myHero,"NasusQStacks")).stacks + ({30, 50, 70, 90, 110})[level] + myHero.totalDamage))
end

function Nasus:EDMG()
    local level = myHero:GetSpellData(_E).level
	local edamage = (({55,95,135,175,215})[level] + 0.60 * myHero.ap)
	return edamage
end

function Nasus:KillstealQ()
	local target = CurrentTarget(300)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(300) then 
			local level = myHero:GetSpellData(_Q).level	
		   	local Qdamage = Nasus:QDMG(target)
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_Q)
				Control.Attack(target)
				end
			end
end
end


function Nasus:KillstealE()
	local target = CurrentTarget(650)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(650) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, 650, E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Nasus:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_E) then
			    CastSpell(HK_E,castpos)
				end
			end
		end
end
end

function Nasus:MinRCast()
	if AIO.Combo.MinRCast:Value() and myHero.health<=myHero.maxHealth * AIO.Combo.MinRHealth:Value()/100 and Ready(_R) then
		if EnemyInRange(700) then 
			local level = myHero:GetSpellData(_R).level	
			    Control.CastSpell(HK_R)
				end
			end
		end
		
class "Ahri"

function Ahri:LoadSpells()

	Q = {Range = 880, Width = 80, Delay = 0, Speed = 1100, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false}
	E = {Range = 975, Width = 80, Delay = 0.60, Speed = 1200, Collision = true, aoe = false, Type = "line"}

end

function Ahri:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Ahri", name = "Kypo's AIO: Ahri", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "Type", name = "Combo Logic", value = 1,drop = {"QWE", "EQW", "EWQ"}})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "Enable", name = "Enable", value = true})
	AIO.Clear:MenuElement({id = "QClear", name = "Use Q If Hit X Minion ", value = 3, min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "UseE", name = "E", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Ahri:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Combo.comboActive:Value() then
		self:ComboTypes()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
		self:KillstealQ()
		self:KillstealW()
		self:KillstealE()
		self:SpellonCCQ()
		self:SpellonCCE()
end

-----------------------------
-- DRAWINGS
-----------------------------

function Ahri:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 880, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 700, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 975, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 255, 000, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
			end
		end
end

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

function Ahri:ComboTypes(target)
local mode = AIO.Combo.Type:Value() 
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
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) then
			    CastSpell(HK_W,castpos)
            end
		end
	end
 
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_E,castpos)
		    end
	    end
    end
end

function Ahri:EQW()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_E,castpos)
		    end
	    end
    end
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) then
			    CastSpell(HK_W,castpos)
            end
		end
	end
end

function Ahri:EWQ()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_E,castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			    CastSpell(HK_W,castpos)
            end
	end
	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end
end

function Ahri:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if AIO.Harass.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) then
			    CastSpell(HK_W,castpos)
            end
		end
	end

end

function Ahri:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.Enable:Value() and minion and minion:GetCollision(80, 1100, 0) - 1 >= AIO.Clear.QClear:Value() then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end

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


function Ahri:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Ahri:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and not target.dead then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Ahri:KillstealW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Ahri:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_W) and not target.dead and target  then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Ahri:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() then
		if EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		   	local Edamage = Ahri:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and not target.dead and Ready(_E) then
			    CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

function Ahri:SpellonCCE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.isCC.UseE:Value() and target and Ready(_E) then
	if EnemyInRange(E.Range) then 
	local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
			    CastSpell(HK_E,castpos)
				end
			end
		end
	end

function Ahri:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

class "Zed"

function Zed:LoadSpells()

	Q = {Range = 900, Width = 45, Delay = 0.15, Speed = 902, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 90, Delay = 0.10, Speed = 1750, Collision = false, aoe = false, Type = "line"}
	E = {Range = 290, Width = 100, Delay = 0.05, Speed = 0, Collision = false, aoe = false, Type = "circular"}
	R = {Range = 625, Width = 1, Delay = 0, Speed = 0, Collision = false, aoe = false, Type = "line"}

end

function Zed:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Zed", name = "Kypo's AIO: Zed", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "AutoBack", name = "Auto R2 if target dies?", value = false})
	AIO.Combo:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Combo.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "QClear", name = "Use Q If Hit X Minion ", value = 3, min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "UseWEQ", name = "WEQ", value = false, key = string.byte("T")})
	AIO.Flee:MenuElement({id = "RKey", name = "R Key", value = false, key = string.byte("2")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Shadow", name = "Draw shadow?", value = true})       
    AIO.Drawings.W:MenuElement({id = "ShadowLines", name = "Draw shadow line?", value = true})       
    AIO.Drawings.W:MenuElement({id = "LWidth", name = "Line Width", value = 4, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "LColor", name = "Line Color", color = Draw.Color(200, 241, 79, 79)})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 241, 79, 79)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Zed:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end	
	if AIO.Harass.harassActive:Value() then
		self:Harass()
		self:HarassE()
	end
	if AIO.Combo.comboActive:Value() then
		self:RCombo()
		self:ComboE()
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() then
		self:ClearQCount()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealQShadow()
		self:KillstealE()
		self:KillstealEShadow()
		self:FleeW()
		self:FleeQ()
		self:FleeE()
		self:FleeR()
		Shadowpos()
end

function Shadowpos()
for i = 0, Game.ParticleCount() do
			local obj = Game.Particle(i)
			if obj and not obj.dead and obj.visible and GetDistance(myHero.pos,obj.pos) < 1300 and obj.name == ("Zed_Base_W_cloneswap_buf") then
			shadow = obj
	end
end
end

function Zed:Draw()
if shadow and Ready(_W) and AIO.Drawings.W.Shadow:Value() and myHero:GetSpellData(1).toggleState == 2 and not shadow.dead then Draw.Circle(shadow, 290, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) 
	end
if shadow and not shadow.dead and shadow.visible and AIO.Drawings.W.ShadowLines:Value() and Ready(_W) and HasBuff(myHero, "ZedWHandler") then
	local posTo2D = myHero.pos:ToScreen();
						Draw.Line(posTo2D.x,posTo2D.y,shadow.pos2D.x,shadow.pos2D.y,AIO.Drawings.W.LWidth:Value(), AIO.Drawings.W.LColor:Value())
				end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 900, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 650, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

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

function Zed:FleeW()
local target = CurrentTarget(900)
if target == nil then return end
	if AIO.Flee.UseWEQ:Value() then
		if Ready(_Q) and Ready(_W) and Ready(_E) and myHero:GetSpellData(_W).name ~= "ZedW2" then
            if EnemyInRange(900) then
				local castposw,HitChancew, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
				if (HitChancew > 0 ) then
				self:CastWforFlee(castposw)
			end
		end
	end
end
end

function Zed:FleeQ()
local target = CurrentTarget(900)
if target == nil then return end
	if AIO.Flee.UseWEQ:Value() then
		if Ready(_Q) and Ready(_W) and myHero:GetSpellData(1).toggleState == 2 then
            if EnemyInRange(900) then
				local castposq,HitChanceq, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
                Control.CastSpell(HK_Q, castposq)
			end
		end
	end
end

function Zed:FleeR()
	local target = CurrentTarget(630)
    if target == nil then return end
	    if AIO.Flee.RKey:Value() and target and Ready(_R) then
	    if EnemyInRange(630) then
		Control.CastSpell(HK_R, target)
		end
	end
end

function Zed:FleeE()
	for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isEnemy and not hero.dead and not hero.isMe then
    if AIO.Flee.UseWEQ:Value() and Ready(_E) then
	if shadow and GetDistance(shadow.pos,hero.pos) < 290 then
			Control.CastSpell(HK_E)
		elseif GetDistance(myHero.pos,hero.pos) < 290 then
			Control.CastSpell(HK_E)
	end
	end
	end
	end
	end

function Zed:CastWforFlee(canto)
    if canto then
            Control.CastSpell(HK_W, canto)
            if not HasBuff(myHero, "ZedWHandler") then
            canto = canto
        end
    end  
end

function Zed:RCombo()
	local target = CurrentTarget(630)
	if target == nil then return end
	if AIO.Combo.RR["UseR"..target.charName]:Value() and target and Ready(_R) then
		if EnemyInRange(630) and not HasBuff(target, "zedrtargetmark") then 
			Control.CastSpell(HK_R, target)
		else if AIO.Combo.AutoBack:Value() and HasBuff(myHero, "ZedR2") and HasBuff(target, "zedrdeathmark") then
			if target == nil then
			Control.CastSpell(HK_R)
		end
	end
end
end
end
	
function Zed:Combo()
for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy and not hero.dead and hero.visible then
	    if AIO.Combo.UseW:Value() and Ready(_W) then
	    if GetDistance(myHero.pos,hero.pos) < 750 then
			Control.CastSpell(HK_W, hero)
		end
	end
	end
	end
	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy and not hero.dead and hero.visible then
	if AIO.Combo.UseE:Value() and Ready(_E) then
	    if GetDistance(myHero.pos,hero.pos) < 290 then
			Control.CastSpell(HK_E)
		end
	end
	end
	end
	
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy and not hero.dead and hero.visible then
    if AIO.Combo.UseQ:Value() and Ready(_Q) then
	    if GetDistance(myHero.pos,hero.pos) < 900 then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(hero, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
end
end
end

function Zed:ComboE()
	for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isEnemy and not hero.dead and not hero.isMe then
    if AIO.Combo.UseE:Value() and Ready(_E) then
	if shadow and GetDistance(shadow.pos,hero.pos) < 290 then
			Control.CastSpell(HK_E)
	end
	end
	end
	end
	end

function Zed:Harass()
local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	
	local target = CurrentTarget(290)
    if target == nil then return end
    if AIO.Harass.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(290) then
			Control.CastSpell(HK_E)
		end
	end
	end

function Zed:HarassE()
	for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isEnemy and not hero.dead and not hero.isMe then
    if AIO.Harass.UseE:Value() and Ready(_E) then
	if shadow and GetDistance(shadow.pos,hero.pos) < 290 then
			Control.CastSpell(HK_E)
	end
	end
	end
	end
	end

function Zed:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 then
					CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

function Zed:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = self:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < 900 and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end

if Ready(_E) then
		local level = myHero:GetSpellData(_E).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = self:EDMG()
			if minion.pos:DistanceTo(myHero.AttackRange) < 290 and AIO.Lasthit.UseE:Value() and minion.isEnemy and not minion.dead then
				if Edamage >= minion.health and Ready(_E) then
				Control.CastSpell(HK_E)
				end
			end
		end
	end

	if Ready(_E) then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = self:EDMG()
			if shadow and GetDistance(shadow.pos,minion.pos) < 290 and AIO.Lasthit.UseE:Value() and minion.isEnemy and not minion.dead then
				if Edamage >= minion.health and Ready(_E) then
				Control.CastSpell(HK_E)
				end
			end
		end
	end
end

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

function Zed:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Zed:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    CastSpell(HK_Q,castpos)
				else if EnemyInRange(900) then 
				if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
				CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	end
	end
	end
	
function Zed:KillstealQShadow()
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
		if hero.isEnemy and not hero.dead and hero.visible then
			if AIO.Killsteal.UseQ:Value() and Ready(_Q) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(hero, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Zed:QDMG()
			if Qdamage >= HpPred(hero,1) + hero.hpRegen * 1 then
			if shadow and GetDistance(shadow.pos,hero.pos) < 900 then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q, castpos)
			elseif Qdamage >= HpPred(hero,1) + hero.hpRegen * 1 then
			if shadow and GetDistance(shadow.pos,hero.pos) < 900 and GetDistance(myHero.pos,hero.pos) > 900 then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q, castpos)
				end
			end
		end
	end
	end
	end
	end
	end
	end

	function Zed:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
		   	local Edamage = Zed:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end

function Zed:KillstealEShadow()
  	for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
		if hero.isEnemy and not hero.dead and hero.visible then
	if AIO.Killsteal.UseE:Value() and Ready(_E) then
		   	local Edamage = Zed:EDMG()
			if Edamage >= HpPred(hero,1) + hero.hpRegen * 1 then
			if shadow and GetDistance(shadow.pos,hero.pos) < 290 then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end
	end
	end

function Zed:ClearQCount(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion and minion:GetCollision(45, 902, 0.15) - 1 >= AIO.Clear.QClear:Value() then
					CastSpell(HK_Q, minion)
    end
  end
end
end
end
	
class "Yasuo"

local Q3Icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Steel_Tempest_3.png"

function Yasuo:LoadSpells()

	Q = {Range = 475, Width = 50, Delay = 0,30, Speed = 1500, Collision = false, aoe = false, Type = "line"}
	Q3 = {Name = "YasuoQ3W", Range = 900, Width = 90, Delay = 0.25, Speed = 1500, Collision = false, aoe = false, Type = "line"}
	W = {Range = 400, Width = 0, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 475, Width = 80, Delay = 0.25, Speed = 0, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1200, Width = 0, Delay = 0.20, Speed = 20, Collision = false, aoe = false, Type = "line"}

end

function Yasuo:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Yasuo", name = "Kypos AIO: Yasuo", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	-- AIO.Combo:MenuElement({id = "EUnderTurret", name = "Use E Under Turret", value = false})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "Q3Clear", name = "Use Q3 If Hit X Minion ", value = 3, min = 1, max = 5, step = 1, leftIcon = Q3Icon})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "AutoR", name = "Auto R Champs", type = MENU})
	AIO.AutoR:MenuElement({id = "AutoRXEnable", name = "R", value = true})
	AIO.AutoR:MenuElement({id = "AutoRX", name = "Use R if champs are UP", value = 3, min = 2, max = 5, step = 1})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "UseE", name = "E on minions/gapclose", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseQ3", name = "Q3", value = true, leftIcon = Q3Icon})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E (OP!)", value = true})
	
	AIO.Killsteal:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "UseQ3", name = "Q3", value = true, leftIcon = Q3Icon})
	
    AIO:MenuElement({type = MENU, name = "Windwall",  id = "Windwall"})
        		AIO.Windwall:MenuElement({id = "Enable", name = "Enabled", value = true})
        		AIO.Windwall:MenuElement({type = MENU, id = "DetectedSpells", name = "Spells"})
        			AIO.Windwall.DetectedSpells:MenuElement({id = "info", name = "Detecting Spells, Please Wait...", drop = {" "}})
        				do
        					local Delay = Game.Timer() > 10 and 0 or 10 - Game.Timer()
						local Added = false
						DelayAction(function()
        						for i, enemy in pairs(Yasuo:WGetEnemyHeroes()) do
        							if Yasuo.SpellData[enemy.charName] then
        								for i, v in pairs(Yasuo.SpellData[enemy.charName]) do
        									if enemy and v then
        										local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]
        										AIO.Windwall.DetectedSpells:MenuElement({type = MENU, id = v.name, name = enemy.charName.." | "..SlotToStr.." | "..v.name, value = true})
        										AIO.Windwall.DetectedSpells[v.name]:MenuElement({id = "Use", name = "Enabled", value = true})
        										Added = true
        									end
        								end
        							end
        						end
        					AIO.Windwall.DetectedSpells.info:Remove()
        					if not Added then
        						AIO.Windwall.DetectedSpells:MenuElement({id = "info", name = "No Spells Detected", drop = {" "}})
        					end
        					end, Delay)
        				end
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Yasuo:__init()
	
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

function Yasuo:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end
	if AIO.Windwall.Enable:Value() then
		self:Windwall()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() and Ready(_Q) then
		self:Clear()
		self:ClearQ3()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealQ3()
		self:KillstealE()
		self:SpellonCCQ3()
		self:AutoRX()
		self:RksKnockedUp()
end

-- All credits to Shulepin from the Windwall.

function Yasuo:Windwall()
		for i = 1, Game.MissileCount() do
			local spell = nil
			local obj = Game.Missile(i)
			local data = obj.missileData
			local source = GetHeroByHandle(data.owner)
			if source then 
				if Yasuo.SpellData[source.charName] then
					spell = Yasuo.SpellData[source.charName][data.name:lower()]
				end
				if spell and not spell.isSkillshot and data.target == myHero.handle then
					if AIO.Windwall.DetectedSpells[spell.name].Use:Value() then
					Control.CastSpell(HK_W, obj.pos)
					return
					end
				end
				if spell and spell.isSkillshot and obj.isEnemy and data.speed and data.width and data.endPos and obj.pos then
					if AIO.Windwall.DetectedSpells[spell.name].Use:Value() then
						local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(obj.pos, data.endPos, myHero.pos)
						if isOnSegment and myHero.pos:DistanceTo(Vector(pointSegment.x, myHero.pos.y, pointSegment.y)) < data.width + myHero.boundingRadius then
						Control.CastSpell(HK_W, obj.pos)
						end
					end
				end
			end
		end
	end
	
	Yasuo.SpellData = {
		["Aatrox"] = {
			["aatroxeconemissile"] = {slot = 2, name = "Blade of Torment", isSkillshot = true}
		},
		["Ahri"] = {
			["ahriorbmissile"] = { slot = 0, name = "Orb of Deception", isSkillshot = true },
			["ahrifoxfiremissiletwo"] = {slot = 1, name = "Fox-Fire", isSkillshot = false},
			["ahriseducemissile"] = {slot = 2, name = "Charm", isSkillshot = true},
			["ahritumblemissile"] = {slot = 3, name = "SpiritRush", isSkillshot = false}
		},
		["Akali"] = {
			["akalimota"] = {slot = 0, name = "Mark of the Assasin", isSkillshot = false}
		},
		["Amumu"] = {
			["sadmummybandagetoss"] = {slot = 0, name = "Bandage Toss", isSkillshot = true}
		},
		["Anivia"] = {
			["flashfrostspell"] = {slot = 0, name = "Flash Frost", isSkillshot = true},
			["frostbite"] = {slot = 2, name = "Frostbite", isSkillshot = false}
		},
		["Annie"] = {
			["disintegrate"] = {slot = 0, name = "Disintegrate", isSkillshot = false}
		},
		["Ashe"] = {
			["volleyattack"] = {slot = 1, name = "Volley", isSkillshot = true},
			["enchantedcrystalarrow"] = {slot = 3, name = "Enchanted Crystal Arrow", isSkillshot = true}
		},
		["AurelionSol"] = {
			["aurelionsolqmissile"] = {slot = 0, name = "Starsurge", isSkillshot = true}
		},
		["Bard"] = {
			["bardqmissile"] = {slot = 0, name = "Cosmic Binding", isSkillshot = true}
		},
		["Blitzcrank"] = {
			["rocketgrabmissile"] = {slot = 0, name = "Rocket Grab", isSkillshot = true}
		},
		["Brand"] = {
			["brandqmissile"] = {slot = 0, name = "Sear", isSkillshot = true},
			["brandr"] = {slot = 3, name = "Pyroclasm", isSkillshot = false}
		},
		["Braum"] = {
			["braumqmissile"] = {slot = 0, name = "Winter's Bite", isSkillshot = true},
			["braumrmissile"] = {slot = 3, name = "Glacial Fissure", isSkillshot = true}
		},
		["Caitlyn"] = {
			["caitlynpiltoverpeacemaker"] = {slot = 0, name = "Piltover Peacemaker", isSkillshot = true},
			["caitlynaceintheholemissile"] = {slot = 3, name = "Ace in the Hole", isSkillshot = false}
		},
		["Cassiopeia"] = {
			["cassiopeiatwinfang"] = {slot = 2, name = "Twin Fang", isSkillshot = false}
		},
		["Nautilus"] = {
			["nautilusanchordragmissile"] = {slot = 0, name = "", isSkillshot = true}
		},
		["Nidalee"] = {
			["JavelinToss"] = {slot = 0, name = "Javelin Toss", isSkillshot = true}
		},
		["Nocturne"] = {
			["nocturneduskbringer"] = {slot = 0, name = "Duskbringer", isSkillshot = true}
		},
		["Pantheon"] = {
			["pantheonq"] = {slot = 0, name = "Spear Shot", isSkillshot = false}
		},
		["RekSai"] = {
			["reksaiqburrowedmis"] = {slot = 0, name = "Prey Seeker", isSkillshot = true}
		},
		["Rengar"] = {
			["rengarefinal"] = {slot = 2, name = "Bola Strike", isSkillshot = true}
		},
		["Riven"] = {
			["rivenlightsabermissile"] = {slot = 3, name = "Wind Slash", isSkillshot = true}
		},
		["Rumble"] = {
			["rumblegrenade"] = {slot = 2, name = "Electro Harpoon", isSkillshot = true}
		},
		["Ryze"] = {
			["ryzeq"] = {slot = 0, name = "Overload", isSkillshot = true},
			["ryzee"] = {slot = 2, name = "Spell Flux", isSkillshot = false}
		},
		["Sejuani"] = {
			["sejuaniglacialprison"] = {slot = 3, name = "Glacial Prison", isSkillshot = true}
		},
		["Sivir"] = {
			["sivirqmissile"] = {slot = 0, name = "Boomerang Blade", isSkillshot = true}
		},
		["Skarner"] = {
			["skarnerfracturemissile"] = {slot = 0, name = "Fracture ", isSkillshot = true}
		},
		["Shaco"] = {
			["twoshivpoison"] = {slot = 2, name = "Two-Shiv Poison", isSkillshot = false}
		},
		["Sona"] = {
			["sonaqmissile"] = {slot = 0, name = "Hymn of Valor", isSkillshot = false},
			["sonar"] = {slot = 3, name = "Crescendo ", isSkillshot = true}
		},
		["Swain"] = {
			["swaintorment"] = {slot = 2, name = "Torment", isSkillshot = false}
		},
		["Syndra"] = {
			["syndrarspell"] = {slot = 3, name = "Unleashed Power", isSkillshot = false}
		},
		["Teemo"] = {
			["blindingdart"] = {slot = 0, name = "Blinding Dart", isSkillshot = false}
		},
		["Tristana"] = {
			["detonatingshot"] = {slot = 2, name = "Explosive Charge", isSkillshot = false}
		},
		["Corki"] = {
			["phosphorusbombmissile"] = {slot = 0, name = "Phosphorus Bomb", isSkillshot = true},
			["missilebarragemissile"] = {slot = 3, name = "Missile Barrage", isSkillshot = true},
			["missilebarragemissile2"] = {slot = 3, name = "Big Missile Barrage", isSkillshot = true}
		},
		["Diana"] = {
			["dianaarcthrow"] = {slot = 0, name = "Crescent Strike", isSkillshot = true}
		},
		["DrMundo"] = {
			["infectedcleavermissile"] = {slot = 0, name = "Infected Cleaver", isSkillshot = true}
		},
		["Draven"] = {
			["dravenr"] = {slot = 3, name = "Whirling Death", isSkillshot = true}
		},
		["Ekko"] = {
			["ekkoqmis"] = {slot = 0, name = "Timewinder", isSkillshot = true}
		},
		["Elise"] = {
			["elisehumanq"] = {slot = 0, name = "Neurotoxin", isSkillshot = false},
			["elisehumane"] = {slot = 2, name = "Cocoon", isSkillshot = true}
		},
		["Ezreal"] = {
			["ezrealmysticshotmissile"] = {slot = 0, name = "Mystic Shot", isSkillshot = true},
			["ezrealessencefluxmissile"] = {slot = 1, name = "Essence Flux", isSkillshot = true},
			["ezrealarcaneshiftmissile"] = {slot = 2, name = "Arcane Shift", isSkillshot = false},
			["ezrealtrueshotbarrage"] = {slot = 3, name = "Trueshot Barrage", isSkillshot = true}
		},
		["FiddleSticks"] = {
			["fiddlesticksdarkwindmissile"] = {slot = 2, name = "Dark Wind", isSkillshot = false}
		},
		["Gangplank"] = {
			["parley"] = {slot = 0, name = "Parley", isSkillshot = false}
		},
		["Gnar"] = {
			["gnarqmissile"] = {slot = 0, name = "Boomerang Throw", isSkillshot = true},
			["gnarbigqmissile"] = {slot = 0, name = "Boulder Toss", isSkillshot = true}
		},
		["Gragas"] = {
			["gragasqmissile"] = {slot = 0, name = "Barrel Roll", isSkillshot = true},
			["gragasrboom"] = {slot = 3, name = "Explosive Cask", isSkillshot = true}
		},
		["Graves"] = {
			["gravesqlinemis"] = {slot = 0, name = "End of the Line", isSkillshot = true},
			["graveschargeshotshot"] = {slot = 3, name = "Collateral Damage", isSkillshot = true}
		},
		["Illaoi"] = {
			["illaoiemis"] = {slot = 2, name = "Test of Spirit", isSkillshot = true}
		},
		["Irelia"] = {
			["IreliaTranscendentBlades"] = {slot = 3, name = "Transcendent Blades", isSkillshot = true}
		},
		["Janna"] = {
			["howlinggalespell"] = {slot = 0, name = "Howling Gale", isSkillshot = true},
			["sowthewind"] = {slot = 1, name = "Zephyr", isSkillshot = false}
		},
		["Jayce"] = {
			["jayceshockblastmis"] = {slot = 0, name = "Shock Blast", isSkillshot = true},
			["jayceshockblastwallmis"] = {slot = 0, name = "Empowered Shock Blast", isSkillshot = true}
		},
		["Jinx"] = {
			["jinxwmissile"] = {slot = 1, name = "Zap!", isSkillshot = true},
			["jinxr"] = {slot = 3, name = "Super Mega Death Rocket!", isSkillshot = true}
		},
		["Jhin"] = {
			["jhinwmissile"] = {slot = 1, name = "Deadly Flourish", isSkillshot = true},
			["jhinrshotmis"] = {slot = 3, name = "Curtain Call's", isSkillshot = true}
		},
		["Kalista"] = {
			["kalistamysticshotmis"] = {slot = 0, name = "Pierce", isSkillshot = true}
		},
		["Karma"] = {
			["karmaqmissile"] = {slot = 0, name = "Inner Flame ", isSkillshot = true},
			["karmaqmissilemantra"] = {slot = 0, name = "Mantra: Inner Flame", isSkillshot = true}
		},
		["Kassadin"] = {
			["nulllance"] = {slot = 0, name = "Null Sphere", isSkillshot = false}
		},
		["Katarina"] = {
			["katarinaqmis"] = {slot = 0, name = "Bouncing Blade", isSkillshot = false}
		},
		["Kayle"] = {
			["judicatorreckoning"] = {slot = 0, name = "Reckoning", isSkillshot = false}
		},
		["Kennen"] = {
			["kennenshurikenhurlmissile1"] = {slot = 0, name = "Thundering Shuriken", isSkillshot = true}
		},
		["Khazix"] = {
			["khazixwmissile"] = {slot = 1, name = "Void Spike", isSkillshot = true}
		},
		["KogMaw"] = {
			["kogmawq"] = {slot = 0, name = "Caustic Spittle", isSkillshot = true},
			["kogmawvoidoozemissile"] = {slot = 3, name = "Void Ooze", isSkillshot = true},
		},
		["Leblanc"] = {
			["leblancchaosorbm"] = {slot = 0, name = "Shatter Orb", isSkillshot = false},
			["leblancsoulshackle"] = {slot = 2, name = "Ethereal Chains", isSkillshot = true},
			["leblancsoulshacklem"] = {slot = 2, name = "Ethereal Chains Clone", isSkillshot = true}
		},
		["LeeSin"] = {
			["blindmonkqone"] = {slot = 0, name = "Sonic Wave", isSkillshot = true}
		},
		["Leona"] = {
			["LeonaZenithBladeMissile"] = {slot = 2, name = "Zenith Blade", isSkillshot = true}
		},
		["Lissandra"] = {
			["lissandraqmissile"] = {slot = 0, name = "Ice Shard", isSkillshot = true},
			["lissandraemissile"] = {slot = 2, name = "Glacial Path ", isSkillshot = true}
		},
		["Lucian"] = {
			["lucianwmissile"] = {slot = 1, name = "Ardent Blaze", isSkillshot = true},
			["lucianrmissileoffhand"] = {slot = 3, name = "The Culling", isSkillshot = true}
		},
		["Lulu"] = {
			["luluqmissile"] = {slot = 0, name = "Glitterlance", isSkillshot = true}
		},
		["Lux"] = {
			["luxlightbindingmis"] = {slot = 0, name = "", isSkillshot = true}
		},
		["Malphite"] = {
			["seismicshard"] = {slot = 0, name = "Seismic Shard", isSkillshot = false}
		},
		["MissFortune"] = {
			["missfortunericochetshot"] = {slot = 0, name = "Double Up", isSkillshot = false}
		},
		["Morgana"] = {
			["darkbindingmissile"] = {slot = 0, name = "Dark Binding ", isSkillshot = true}
		},
		["Nami"] = {
			["namiwmissileenemy"] = {slot = 1, name = "Ebb and Flow", isSkillshot = false}
		},
		["Nunu"] = {
			["iceblast"] = {slot = 2, name = "Ice Blast", isSkillshot = false}
		},
		["TahmKench"] = {
			["tahmkenchqmissile"] = {slot = 0, name = "Tongue Lash", isSkillshot = true}
		},
		["Taliyah"] = {
			["taliyahqmis"] = {slot = 0, name = "Threaded Volley", isSkillshot = true}
		},
		["Talon"] = {
			["talonrakemissileone"] = {slot = 1, name = "Rake", isSkillshot = true}
		},
		["TwistedFate"] = {
			["bluecardpreattack"] = {slot = 1, name = "Blue Card", isSkillshot = false},
			["goldcardpreattack"] = {slot = 1, name = "Gold Card", isSkillshot = false},
			["redcardpreattack"] = {slot = 1, name = "Red Card", isSkillshot = false}
		},
		["Urgot"] = {
			--
		},
		["Varus"] = {
			["varusqmissile"] = {slot = 0, name = "Piercing Arrow", isSkillshot = true},
			["varusrmissile"] = {slot = 3, name = "Chain of Corruption", isSkillshot = true}
		},
		["Vayne"] = {
			["vaynecondemnmissile"] = {slot = 2, name = "Condemn", isSkillshot = false}
		},
		["Veigar"] = {
			["veigarbalefulstrikemis"] = {slot = 0, name = "Baleful Strike", isSkillshot = true},
			["veigarr"] = {slot = 3, name = "Primordial Burst", isSkillshot = false}
		},
		["Velkoz"] = {
			["velkozqmissile"] = {slot = 0, name = "Plasma Fission", isSkillshot = true},
			["velkozqmissilesplit"] = {slot = 0, name = "Plasma Fission Split", isSkillshot = true}
 		},
		["Viktor"] = {
			["viktorpowertransfer"] = {slot = 0, name = "Siphon Power", isSkillshot = false},
			["viktordeathraymissile"] = {slot = 2, name = "Death Ray", isSkillshot = true}
		},
		["Vladimir"] = {
			["vladimirtidesofbloodnuke"] = {slot = 2, name = "Tides of Blood", isSkillshot = false}
		},
		["Yasuo"] = {
			["yasuoq3w"] = {slot = 0, name = "Gathering Storm", isSkillshot = true}
		},
		["Zed"] = {
			["zedqmissile"] = {slot = 0, name = "Razor Shuriken ", isSkillshot = true}
		},
		["Zyra"] = {
			["zyrae"] = {slot = 2, name = "Grasping Roots", isSkillshot = true}
		}
	}


function Yasuo:WGetEnemyHeroes()
	local result = {}
  	for i = 1, Game.HeroCount() do
    		local unit = Game.Hero(i)
    		if unit.isEnemy then
    			result[#result + 1] = unit
  		end
  	end
  	return result
end

function Yasuo:dashpos(unit)
	return myHero.pos + (unit.pos - myHero.pos):Normalized() * 600
	end

function Yasuo:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 900, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 475, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1200, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

function Yasuo:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Yasuo:IsKnockedUp(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 29 or buff.type == 30 or buff.type == 39) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Yasuo:CountKnockedUpEnemies(range)
		local count = 0
		local rangeSqr = range * range
		for i = 1, Game.HeroCount()do
		local hero = Game.Hero(i)
			if hero.isEnemy and hero.alive and GetDistanceSqrYas(myHero.pos, hero.pos) <= rangeSqr then
			if Yasuo:IsKnockedUp(hero)then
			count = count + 1
    end
  end
end
return count
end

function Yasuo:AutoRX()
		if Ready(_R) and AIO.AutoR.AutoRXEnable:Value() then
		if Yasuo:CountKnockedUpEnemies(1400) >= AIO.AutoR.AutoRX:Value() then
		Control.CastSpell(HK_R)
end
end
end

function Yasuo:Flee()
	if Ready(_E) then
			local minion = self:getminion()
			if minion then
				Control.CastSpell(HK_E,minion)
			end
		end
	end
	
function Yasuo:getminion()
		local gebest = nil
		local perto = math.huge
		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if minion and minion.team == 300 or minion.team ~= myHero.team then
				local rato = GetDistance(myHero.pos, mousePos)
				local jogador = GetDistance(Yasuo:dashpos(minion), mousePos)
				local enemigo = GetDistance(Yasuo:dashpos(minion), myHero.pos)
				if jogador < rato and enemigo < perto and not HasBuff(minion, "YasuoDashWrapper") and GetDistance(myHero.pos, minion.pos) < 475 then
					gebest = minion
					perto = enemigo
				end
			end
		end
		return gebest
	end

function Yasuo:Combo()
    local target = CurrentTarget(900)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	
	if AIO.Combo.UseE:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 2000 and AIO.Combo.comboActive:Value() and not HasBuff(myHero, "YasuoQ3W") then		
	self:Flee()
	end
	
	local target = CurrentTarget(475)
    if target == nil then return end
	    if AIO.Combo.UseE:Value() and target and Ready(_E) and not HasBuff(target, "YasuoDashWrapper") then
	    if EnemyInRange(475) then
			Control.CastSpell(HK_E,target)
		end
	end
end

function Yasuo:Harass()
    local target = CurrentTarget(900)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range ,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,target)
				else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end
    end

end

function Yasuo:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 475) and myHero.pos:DistanceTo(minion.pos) < 475 and not HasBuff(myHero, "YasuoQ3W") then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.name == "SRU_Razorbeak" or minion.name == "SRU_Red" or minion.name == "SRU_Blue" or minion.name == "SRU_Krug" or minion.name == "SRU_Gromp" or minion.name == "SRU_MurkWolf" or minion.name == "SRU_KrugMini" or minion.name == "SRU_Dragon_Fire" or minion.name == "SRU_Dragon_Air" or minion.name == "SRU_Dragon_Earth" or minion.name == "SRU_Dragon_Water" or minion.name == "SRU_Dragon_Elder" or minion.name == "SRU_Baron" or minion.name == "SRU_Herald" then
		if Ready(_Q) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q3.Delay , Q3.Width, Q3.Range ,Q3.Speed, myHero.pos, Q3.ignorecol, Q3.Type )
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 then
					if (HitChance > 0 ) and HasBuff(myHero, "YasuoQ3W") then
					Control.CastSpell(HK_Q, castpos)
					end
				end
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
-- SRU_MurkWolf
-- SRU_KrugMini
-- SRU_MiniKrugB
-- Sru_Crab
-- SRU_Dragon_Fire
-- SRU_Dragon_Air
-- SRU_Dragon_Earth
-- SRU_Dragon_Water
-- SRU_Dragon_Elder

	
function Yasuo:ClearE()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_E) then 
			if AIO.Clear.UseE:Value() and minion then
				if ValidTarget(minion, 475) and myHero.pos:DistanceTo(minion.pos) < 475 and not HasBuff(minion, "YasuoDashWrapper") then
					Control.CastSpell(HK_E, minion)
					end
				end
			end
		end
	end
end

function Yasuo:ClearQ3()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 and HasBuff(myHero, "YasuoQ3W") and minion:GetCollision(90, 1600, 0.10) - 1 >= AIO.Clear.Q3Clear:Value() then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

function Yasuo:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
			if myHero.pos:DistanceTo(minion.pos) < 475 and AIO.Lasthit.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end

if Ready(_E) then
		local level = myHero:GetSpellData(_E).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = (({60,70,80,90,100})[level] + 0.2 * myHero.totalDamage)
			if minion.pos:DistanceTo(myHero.AttackRange) < 475 and AIO.Lasthit.UseE:Value() and minion.isEnemy and not HasBuff(minion, "YasuoDashWrapper") then
				if Edamage >= minion.health and Ready(_E) then
				Control.CastSpell(HK_E,minion.pos)
				end
			end
		end
	end
end

function Yasuo:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
	return qdamage
end

function Yasuo:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({45,50,60,70,80})[level] + 0.2 * myHero.totalDamage)
	return edamage
end

function Yasuo:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 200, 350})[level] + 1.5 * myHero.totalDamage)
	return rdamage
end

function Yasuo:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Yasuo:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				else if EnemyInRange(900) then 
				if Qdamage >= HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "YasuoQ3W") then
				CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	end
	end
	end
	
function Yasuo:KillstealQ3()
	local target = CurrentTarget(900)
	if target == nil then return end
	if AIO.Killsteal.UseQ3:Value() and target and Ready(_Q) then
		if EnemyInRange(Q3.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 900, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Yasuo:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "YasuoQ3W") then
			if (HitChance > 0 ) and Ready(_Q) then
			    Control.CastSpell(HK_Q,castpos)

				end
			end
		end
	end
	end

	function Yasuo:KillstealE()
	local target = CurrentTarget(475)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(475) then 
			local level = myHero:GetSpellData(_E).level	
		   	local Edamage = Yasuo:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 and not HasBuff(target, "YasuoDashWrapper") then
			    Control.CastSpell(HK_E,target)
				end
			end
		end
	end

function Yasuo:SpellonCCQ3()
    local target = CurrentTarget(900)
	if target == nil then return end
	if AIO.isCC.UseQ3:Value() and target and Ready(_Q) then
		if EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and HasBuff(myHero, "YasuoQ3W") then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Yasuo:RksKnockedUp()
    local target = CurrentTarget(1200)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(1200) then 
			local ImmobileEnemy = self:IsKnockedUp(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Yasuo:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

class "Tristana"


function Tristana:LoadSpells()

	Q = {Range = 550, Width = 20, Delay = 0.40, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	E = {Range = 500, Width = 0, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 500, Width = 0, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}

end

function Tristana:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Tristana", name = "Kypos AIO: Tristana", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "R", name = "R", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Combo.R:MenuElement({id = "RR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Tristana:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
		self:ComboRKS()
		self:UseBotrk()
	end	
	if AIO.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassE()
	end
end

function Tristana:Draw()
if Ready(_W) and Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero, 900, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and Ready(_E) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero, GetERange(), AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
		if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local damage = EDamage + RDamage
				if damage > hero.health and EnemyInRange(3500) then
					Draw.Text("Killable", 20, hero.pos2D.x, hero.pos2D.y,Draw.Color(200,255,255,255))				
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
end	
end	
end	

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
		if EnemyInRange(700) then 
		local BOTR = GetInventorySlotItem(3153) or GetInventorySlotItem(3144)
		if BOTR and EnemyInRange(700) then
			Control.CastSpell(HKITEM[BOTR], target)
		end
	end
	end

function Tristana:Combo()
    local target = CurrentTarget(680)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(680) then
		Control.CastSpell(HK_Q)
		end
	    end
end

function Tristana:ComboE()
    local target = CurrentTarget(GetERange())
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(GetERange()) then
		Control.CastSpell(HK_E, target)
		    end
	    end
	    end
		
function Tristana:ComboRKS()
	local hero = CurrentTarget(R.Range)
    if hero == nil then return end
 	if AIO.Combo.R["RR"..hero.charName]:Value() and Ready(_R) then
	if EnemyInRange(R.Range) then
   	local Rdamage = Tristana:RDMG()    
			if Rdamage >= HpPred(hero,1) + hero.hpRegen * 1 and not hero.dead then
				Control.CastSpell(HK_R, hero)
			end
        end
    end
end

function Tristana:HarassQ()
    local target = CurrentTarget(680)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(680) then
		Control.CastSpell(HK_Q)
		end
	    end
end

function Tristana:HarassE()
    local target = CurrentTarget(GetERange())
    if target == nil then return end
    if AIO.Harass.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(GetERange()) then
		Control.CastSpell(HK_E, target)
		    end
	    end
	    end

function Tristana:RDMG()
    local level = myHero:GetSpellData(_R).level
    local edamage = (({300,400,500})[level] + 1.0 * myHero.ap)
	return edamage
end

function GetERange()
	local level = myHero.levelData.lvl
	local range = ({610,617,624,631,638,645,651,658,665,672,679,686,693,700,707,714,721,728})[level]
	return range
end

class "Thresh"

function Thresh:LoadSpells()

	Q = {Range = 1075, Width = 60, Delay = 0.50, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 950, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false, radius = 150}
	E = {Range = 400, Width = 80, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 450, Width = 80, Delay = 0.25, Speed = 1900, Collision = false, aoe = false, Type = "circular"}

end

function Thresh:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Thresh", name = "Kypo's AIO: Thresh", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "Auto W on ally?", value = true})
	AIO.Combo:MenuElement({id = "DelayQ", name = "Delay Q1 and Q2 (ms)", value = 0.8,min = 0.1,max = 0.8,step = 0.01})
	AIO.Combo:MenuElement({id = "MinQ", name = "Min Distance to Q", value = 1050,min = 200,max = 1075,step = 1})	
	AIO.Combo:MenuElement({id = "PullKey", name = "Pull Key",key = string.byte("5") })
	AIO.Combo:MenuElement({id = "PushKey", name = "Push Key",key = string.byte("6") })	
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Ultimate", name = "Ultimate", type = MENU})
	AIO.Ultimate:MenuElement({id = "Min", name = "Min enemies around", value = 2,min = 1, max = 5, step = 1})

	AIO:MenuElement({id = "AutoW", name = "AutoW", type = MENU})
	AIO.AutoW:MenuElement({id = "Wmyself", name = "W myself when HP below ",value=25,min=5,max=50, step = 5})
	AIO.AutoW:MenuElement({id = "savehp", name = "Save allies when HP below ", value = 20,min = 0, max = 100, step = 5})
	AIO.AutoW:MenuElement({id = "shieldhp", name = "Shield allies on CC", value = 60 ,min = 0, max = 100, step = 5})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	
	AIO:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.CC:MenuElement({id = "QQ"..hero.charName, name = "Use Q on: "..hero.charName, value = false})
	end	

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function Thresh:__init()
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

function Thresh:getFlash()
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

function Thresh:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end	
	if AIO.AutoW.Wmyself:Value() then
		self:Autoshield()
	end
		self:KillstealQ()
		self:UseWAlly()
		self:KillstealE()
		self:AutoW()
		self:Autoult()
		self:SpellonCCQ()
		self:Edirections()
end

function Thresh:Autoshield()
	local pos = myHero.pos
	if Ready(_W) and myHero.health<=myHero.maxHealth * AIO.AutoW.Wmyself:Value()/100 then 
	Control.CastSpell(HK_W, pos)
	end
end

function Thresh:UseWAlly()
	   local target = CurrentTarget(Q.Range)
    if target == nil then return end
	for i,ally in pairs(GetAllyHeroes()) do
		if ValidTarget(ally,950) and myHero.pos:DistanceTo(ally.pos) < 950 then
		if AIO.Combo.UseW:Value() and Ready(_W) and HasBuff(target, "ThreshQ") then
		Control.CastSpell(HK_W, ally)
	end
end
end
end

function Thresh:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1075, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 950, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 450, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.50 , 100, 1100,1900, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 18, 222, 33))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos,  E.ignorecol, E.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

function Thresh:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and not buff.name == "ThreshQ" and buff.count > 0 then
				return true
			end
		end
		return false	
	end
function Thresh:GetEtarget(range)
	local result = nil
	local N = math.huge
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range) and hero.isEnemy then
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

function CastEPush(target)
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if not Ready(_E) then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
	Control.CastSpell(HK_E, castpos)
end

function CastEPull(target)
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if not Ready(_E) then return end
	local pos = target:GetPrediction(2000, 0.25)
	pos = Vector(myHero.pos) + (Vector(myHero.pos) - Vector(pos)):Normalized()*400
	Control.CastSpell(HK_E, pos)
end

function Thresh:AutoW()
if Ready(_W) then
		for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)	
			if ValidTarget(hero,900) and hero.isAlly then
				if hero.health/hero.maxHealth <= AIO.AutoW.shieldhp:Value()/100 and self:IsImmobileTarget(hero) then
					Control.CastSpell(HK_W, hero.pos)
				end
				if hero.health/hero.maxHealth <= AIO.AutoW.savehp:Value()/100 and self:CountEnemy(hero.pos,900) > 0 then
					Control.CastSpell(HK_W, hero.pos)
				end
			end
		end	
	end
end

function isQ1()
	return myHero:GetSpellData(_Q).name == "ThreshQ"
end

function isQ2()
	return myHero:GetSpellData(_Q).name == "ThreshQLeap"
end

function Thresh:CountEnemy(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

function Thresh:UltHit(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy then
			N = N + 1
		end
	end
	return N	
end

function Thresh:Autoult()
	if Ready(_R) and self:UltHit(myHero.pos,225) >= AIO.Ultimate.Min:Value() then
		Control.CastSpell(HK_R)
	end
end

function Thresh:Edirections()
	if AIO.Combo.PushKey:Value() then
		local etarget = self:GetEtarget(450)
		if etarget then 
			CastEPush(etarget)
		end
	elseif AIO.Combo.PullKey:Value()then
		local etarget = self:GetEtarget(450)
		if etarget then 
			CastEPull(etarget)
		end
	end
end

function Thresh:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) and target.distance <= AIO.Combo.MinQ:Value() and Game.Timer() - myHero:GetSpellData(_Q).castTime >= AIO.Combo.DelayQ:Value() and myHero.pos:DistanceTo(target.pos) > 350 then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end
end

function Thresh:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({80, 120, 160, 200, 240})[level] + 0.50 * myHero.ap)
	return qdamage
end

function Thresh:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({65, 95, 125, 155, 185})[level] + 0.4 * myHero.ap)
	return edamage
end

function Thresh:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Thresh:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Thresh:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and Ready(_E) then
		if EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Thresh:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_E) then
			    Control.CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

function Thresh:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.CC["QQ"..target.charName]:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy and (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end

class "Teemo"


function Teemo:LoadSpells()

	Q = {Range = 680, Width = 40, Delay = 0.40, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Delay = 1.00, Speed = 1200, Collision = false, aoe = false, Type = "line", Radius = 200}

end

function Teemo:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Teemo", name = "Kypo's AIO: Teemo", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseR", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "RCount", name = "Use R on X minions", value = 3, min = 1, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	
	-- AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	-- AIO.Flee:MenuElement({id = "Rkey", name = "R on important spots",  key = string.byte("T")})

	AIO:MenuElement({id = "CC", name = "CC", type = MENU})
	AIO.CC:MenuElement({id = "UseR", name = "R", value = true})	
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw E range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R Loc
	AIO.Drawings:MenuElement({id = "RLoc", name = "Draw R Locs", type = MENU})
    AIO.Drawings.RLoc:MenuElement({id = "Enabled", name = "Normal", value = true})       
    AIO.Drawings.RLoc:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.RLoc:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Teemo:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	-- if AIO.Flee.Rkey:Value() then
		-- self:RKey()
	-- end			
		self:KillstealQ()
		self:R()
		self:CC()
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
	for i, target in ipairs(GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Teemo:RDrawnormal()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif not Ready(_R) then goto continue
	::continue:: elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value()) 
	end
end

function Teemo:RRange()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return 400
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return 650
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return 900
	end
end

local RLoc ={
Vector(3100,-68,10830), Vector(2892,-71,11282), Vector(3058,-70,11478), Vector(3186,-66,11656), Vector(3302,-63,11826), Vector(3792,-54,11458), Vector(3856,-71,11260), Vector(4186,43,11558), Vector(4408,57,11744), Vector(4406,56,11956), Vector(3750,54,12842), Vector(3923,53,12917), Vector(2562,53,13568), Vector(2214,53,13416), Vector(1990,52,13252), Vector(1766,45,13100), Vector(1569,53,12916), Vector(1392,53,12674), Vector(1220,53,12430), Vector(1128,53,12140), Vector(1942,53,11642), Vector(2480,33,11812), Vector(2782,21,11928), Vector(2884,53,12316), Vector(3592,-53,9640), Vector(3758,-50,9488), Vector(3532,49,9078), Vector(3540,-67,10178), Vector(6164,-68,9350), Vector(6356,-55,9212), Vector(6252,54,10296), Vector(6514,56,11332), Vector(5480,53,12670), Vector(5474,53,13060), Vector(5140,56,12320), Vector(4670,56,12438), Vector(8278,50,10274), Vector(8774,51,10540), Vector(8816,50,9796), Vector(7176,54,9818), Vector(7040,53,9058), Vector(7524,53,8692), Vector(4846,27,8422), Vector(4422,-66,9228), Vector(3864,-70,10472), Vector(3379,-68,11089), Vector(3468,-67,11446), Vector(3790,-71,10782), Vector(5206,57,11566), Vector(5838,56,10988), Vector(7424,51,11574), Vector(3298,52,7780), Vector(2984,52,7786), Vector(2442,50,7428), Vector(1962,50,7700), Vector(822,53,8164), Vector(1608,53,9306), Vector(1920,53,9630), Vector(2348,54,9744), Vector(2948,54,10068), Vector(3064,52,9772), Vector(3058,51,9298), Vector(4240,-67,9454), Vector(5248,-71,9130), Vector(5126,-26,8472), Vector(4874,52,7946), Vector(5992,52,7230), Vector(5634,52,7493), Vector(5110,51,7739), Vector(4840,51,7059), Vector(6806,55,13000), Vector(7334,56,12480), Vector(7870,56,11796), Vector(6968,54,11382), Vector(7833,52,10988), Vector(8494,50,9866), Vector(8942,50,11050), Vector(8150,56,11776), Vector(8534,56,12298), Vector(8734,55,12901), Vector(8412,53,13246), Vector(9580,53,13044), Vector(9610,52,12533), Vector(9636,52,11856), Vector(9353,53,11490), Vector(9022,55,11406)
}

function Teemo:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then self:RDrawnormal() end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + RDamage + EDamage
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 50, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))				
					else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
end
	if AIO.Drawings.RLoc.Enabled:Value() then
	for i=1,150,1 do
		if myHero.pos:DistanceTo(RLoc[i]) < 900 and Ready(_R) then
					Draw.Circle(RLoc[i],80,AIO.Drawings.RLoc.Width:Value(), AIO.Drawings.RLoc.Color:Value()) 
end
end
end
end

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

function Teemo:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q, target)
		end
	end
end

function Teemo:Clear()
	if Ready(_R) then
	local rMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,self:RRange())  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				rMinions[#rMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(self:RRange(), 350, rMinions)
		if BestHit >= AIO.Clear.RCount:Value() and AIO.Clear.UseR:Value() then
		Control.CastSpell(HK_R,BestPos)
		end
	end
end
end

function Teemo:Lasthit()
	if Ready(_Q) and AIO.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Teemo:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= HpPred(minion,1) then
			    Control.CastSpell(HK_Q,minion)
				end
			end
		end
	end
end

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

function Teemo:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Teemo:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
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
	
function Teemo:CC()
    local target = CurrentTarget(self:RRange())
	if target == nil then return end
	if AIO.CC.UseR:Value() and target and Ready(_R) then
		if EnemyInRange(self:RRange()) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if ImmobileEnemy then
				Control.CastSpell(HK_R, target)
				end
			end
		end
	end
	
class "Syndra"

local Balls = {}

function Syndra:LoadSpells()

	Q = {Range = 800, Width = 80, Delay = 0.50, Speed = 1750, Collision = false, aoe = false, Type = "circular", radius = 225}
	W = {Range = 950, Width = 80, Delay = 0.70, Speed = 1450, Collision = false, aoe = false, Type = "circular", radius = 225}
	E = {Range = 700, Width = 80, Delay = 0.25, Speed = 902, Collision = false, aoe = false}
	R = {Range = 750, Width = 0, Delay = 1.00, Speed = 0, Collision = false, aoe = false, Type = "line"}
	QE = {Range = 1200, Width = 70, Delay = 0.40, Speed = 1500, Type = "line"}

end

function Syndra:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Syndra", name = "Kypo's AIO: Syndra", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "UseQE", name = "QE", key = string.byte"T"})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "AutoQ", name = "Auto Q Toggle", value = true, toggle = true, key = string.byte("6")})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})	
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", key = string.byte "X"})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "QHit", name = "Q hits x minions", value = 3,min = 1, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS on: ", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Balls", name = "Draw Balls?", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})
	--QE
	AIO.Drawings:MenuElement({id = "QE", name = "Draw QE range", type = MENU})
    AIO.Drawings.QE:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.QE:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.QE:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(180, 227, 29, 191)})

	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Syndra:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
	end
	if AIO.Lasthit.UseQ:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealW()
		self:KillstealR()
		self:SpellonCCQ()
		self:QE()
		
		self:AutoQ()

	if Ready(_Q) then BallUpdate = false
	elseif not Ready(_Q) and not BallUpdate then
		BallUpdate = true
		DelayAction(function() FindBall() end , 0.70)
	end	
	end
	
function FindBall()
		for i = 0, Game.ObjectCount() do
			local obj = Game.Object(i)
			if obj and not obj.dead and obj.name:find("Seed") then
				Balls[obj.networkID] = obj
			end
		end	
end

function Syndra:Clear()
	local Minions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if ValidTarget(minion,Q.Range) then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy then
				Minions[#Minions+1] = minion
			end	
		end
	end	
	if Ready(_Q) and AIO.Clear.UseQ:Value() then
		local BestPos, BestHit = GetBestCircularFarmPosition(Q.Range,90 + 48, Minions)
		if BestHit >= AIO.Clear.QHit:Value() then
			Control.CastSpell(HK_Q,BestPos)
		end
	end	
	if Ready(_W) and AIO.Clear.UseW:Value() then
		local BestPos, BestHit = GetBestCircularFarmPosition(W.Range,90 + 48, Minions)
		if BestHit >= 0 then
			Control.CastSpell(HK_W,BestPos)
		end
	end

	
	if #mobs == 0 then return end
	table.sort(mobs,function(a,b) return a.maxHealth > b.maxHealth end)
	local mob = mobs[1]
	if Ready(_Q) and AIO.Clear.UseQ:Value() then
		Control.CastSpell(HK_Q, mob)
	end	
	if Ready(_W) and AIO.Clear.UseW:Value() then
	local BestPos, BestHit = GetBestCircularFarmPosition(W.Range,90 + 48, mobs)
		if BestHit >= AIO.Clear.WHit:Value() then
		Control.CastSpell(HK_W,mob)	end
end		
end		

function Syndra:Draw()
if AIO.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(255, 60, 145, 201))
			end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 800 , AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 925, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 700, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if AIO.Drawings.QE.Enabled:Value() then Draw.Circle(myHero.pos, 1200, AIO.Drawings.QE.Width:Value(), AIO.Drawings.QE.Color:Value()) end
for i, ball in pairs(Balls) do
if ball and not ball.dead and AIO.Drawings.Q.Balls:Value() then Draw.Circle(ball, 45, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) 
	else
		Balls[ball.networkID] = nil
	end
end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(255, 255, 000, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, "circular" )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

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

function Syndra:QE()
    local target = CurrentTarget(QE.Range)
    if target == nil then return end
    local pos,HitChance, pos = TPred:GetBestCastPosition(target, QE.Delay , QE.Width, QE.Range, QE.Speed, myHero.pos, QE.ignorecol, QE.Type )
    if AIO.Combo.UseQE:Value() and target and Ready(_Q) and Ready(_E) then
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(Q.Range - 60)
			Control.CastSpell(HK_Q, pos)
			Control.CastSpell(HK_E, pos)
			end
end

function Syndra:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
		    end
	    end
    end
	
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_W, castpos)
				end
	    end
    end
end

function Syndra:ComboE()
if AIO.Combo.UseE:Value() and Ready(_E) then
		for i = 1, Game.HeroCount()  do
			local hero = Game.Hero(i)
			if hero.isEnemy and ValidTarget(hero, 2000) then
				for id, ball in pairs(Balls) do
					if self:GetDistanceSqrSyndra(ball.pos,myHero.pos) < 600*600 then
						local enemyPos =  TPred:GetBestCastPosition(hero, E.Delay , 60, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
						local endPos = ball.pos  + (ball.pos - myHero.pos):Normalized()*1200
						local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(ball.pos,endPos,enemyPos)
						if isOnSegment and self:GetDistanceSqrSyndra(pointSegment,enemyPos) < (60)*(60) then
							Control.CastSpell(HK_E,ball.pos)
						end
					end
				end
			end		
		end
	end
	end
	
function Syndra:GetDistanceSqrSyndra(p1, p2)
    p2 = p2 or myHero.pos
    return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function Syndra:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
		    end
	    end
    end
 
	local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_W, castpos)
		    end
	    end
    end
end

function Syndra:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({50, 95, 140, 185, 230})[level] + 0.65 * myHero.ap)
	return qdamage
end

function Syndra:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70,110,150,190,230})[level] + 0.65 * myHero.ap)
	return wdamage
end

function Syndra:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({90, 135 , 180})[myHero:GetSpellData(_R).level] + 0.2 * myHero.ap)*(3 + #Balls)
	return rdamage
end

function Syndra:AutoQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Harass.AutoQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and Ready(_Q) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end

function Syndra:KillstealR()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(R.Range) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Syndra:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			    Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Syndra:KillstealQ()
	local target = CurrentTarget(800)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(800) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 800, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Syndra:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

function Syndra:Lasthit()
if Ready(_Q) then
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.isEnemy or minion.team == 300 then
		   	local Qdamage = Syndra:QDMG()
			if Qdamage >= HpPred(minion,1) + minion.hpRegen * 1 and GetDistance(myHero.pos,minion.pos) < Q.Range then
				Control.CastSpell(HK_Q, minion.pos)
				end
			end
		end
	end
end

function Syndra:GrabThings()
	for i, ball in pairs(Balls) do
		if myHero.pos:DistanceTo(ball.pos) < 950 then
			return ball.pos
		end
	end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.isEnemy or minion.team == 300 then
		if GetDistance(myHero.pos,minion.pos) < W.Range then
			return minion.pos
		end
	end	
end
end

function Syndra:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
		   	local Wdamage = Syndra:WDMG()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local WGrab = Syndra:GrabThings()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if Ready(_W) and myHero:GetSpellData(1).toggleState == 2 and (HitChance > 0 ) then
				Control.CastSpell(HK_W, castpos)
			else if Ready(_W) and myHero:GetSpellData(1).toggleState == 1 then
				Control.CastSpell(HK_W, WGrab)
				end
			end
		end
	end
end
end

function Syndra:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

class "Jinx"


function Jinx:LoadSpells()

	Q = {Range = 700}
	W = {Range = 1450, Width = 40, Delay = 0.35, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	E = {Range = 900, Width = 50, Delay = 0.25, Speed = 1600, Collision = false, aoe = false}
	R = {Range = 20000, Width = 140, Delay = 0.80, Speed = 1700, Collision = true, aoe = false, Type = "line"}

end


function Jinx:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Jinx", name = "Kypo's AIO: Jinx", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	-- AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	-- AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	-- AIO.Clear:MenuElement({id = "UseQXminion", name = "Use Q2 on X minions", value = true})
	-- AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Flee", name = "R key", type = MENU})
	AIO.Flee:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "R key (Global)", key = string.byte("T")})
	
	-- AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	-- AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	-- AIO.Lasthit:MenuElement({id = "UseW", name = "W", value = true})
	-- AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "UseRCC", name = "R on CC Only", value = true})
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = false, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = false})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseE", name = "E", value = true})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Taunt, Charm, Knockup"})

	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Jinx:__init()
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


function Jinx:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboQ()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end
--	if AIO.Lasthit.lasthitActive:Value() then
--		self:Lasthit()
--	end
		self:KillstealW()
		self:KillstealR()
		self:SpellonCCE()
		self:RksCC()
end

function Jinx:Draw()
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 1450, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 900, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
Draw.CircleMinimap(myHero.pos, 6000, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value())

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero)) * 8
				local damage = RDamage + WDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(6000)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 6000, R.Speed, myHero.pos, not R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Jinx:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70, 120, 170, 220, 270})[level] + 1.0 * myHero.totalDamage)
	return wdamage
end

function Jinx:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Jinx:Combo()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) and GetDistance(myHero.pos, target.pos) > 100 then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Jinx:ComboQ()	
	local target = CurrentTarget(700)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if GetDistance(myHero.pos,target.pos) <= 800 and myHero:GetSpellData(_Q).toggleState == 1 and GetDistance(myHero.pos,target.pos) >= 620 then
			Control.CastSpell(HK_Q)
		elseif GetDistance(myHero.pos,target.pos) <= 620 and myHero:GetSpellData(_Q).toggleState == 2 then
			Control.CastSpell(HK_Q)
		    end
	    end
end

function Jinx:Harass()
    local target = CurrentTarget(1400)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(1400) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) and GetDistance(myHero.pos, target.pos) > 60 then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Jinx:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, not W.ignorecol, W.Type )
		   	local Wdamage = Jinx:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and target.pos2D.onScreen and GetDistance(myHero.pos, target.pos) > 100 then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Jinx:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	local Rdamage = (getdmg("R",target,myHero))
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 and GetDistance(myHero.pos, target.pos) > 400 then
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Jinx:Flee()
    local target = CurrentTarget(6000)
	if target == nil then return end
	if AIO.Flee.UseR:Value() and Ready(_R) then
		if EnemyInRange(6000) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 6000, R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Jinx:SpellonCCE()
    local target = CurrentTarget(900)
	if target == nil then return end
	if AIO.isCC.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if ImmobileEnemy then
			if target.pos2D.onScreen then
			    CastSpell(HK_E,target)
				end
			end
		end
	end
end

function Jinx:RksCC()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.UseRCC:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = (getdmg("R",target,myHero))
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen and GetDistance(myHero.pos, target.pos) > 200 then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end
	
class "Kalista"


function Kalista:LoadSpells()

	Q = {Range = 1150, Width = 40, Delay = 0.35, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	E = {Range = 1000, Delay = 0.25}
	R = {Range = 1200, Width = 160, Delay = 1.35, Speed = 2000, Collision = false, aoe = false, Type = "circular"}

end

function Kalista:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Kalista", name = "Kypo's AIO: Kalista", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "ECount", name = "Use E on X minions", value = 3, min = 1, max = 7, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})	
	
	AIO:MenuElement({id = "Misc", name = "Misc", type = MENU})
	AIO.Misc:MenuElement({id = "AutoE", name = "Auto E", value = true})
	-- AIO.Misc:MenuElement({id = "QWall", name = "Q Walljump", key = string.byte("T")})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--Q Walljump
	AIO.Drawings:MenuElement({id = "WJ", name = "Draw Walljump Circles", type = MENU})
    AIO.Drawings.WJ:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.WJ:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.WJ:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
	AIO.Drawings:MenuElement({id = "DrawDamageMinion", name = "Draw damage on Minions", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

local Pos1 ={
Vector(9500,45,2808), Vector(9600,50,3100),
Vector(9322,-71,4508), Vector(9058,52,4634),

Vector(9434,63,2142), Vector(9572,49,2408), 
Vector(8272,51,2908), Vector(8144,52,3160), 
Vector(5874,52,2008), Vector(5766,50,1756), 
Vector(4774,51,3408), Vector(4524,96,3258), 
Vector(2924,96,4608), Vector(3074,96,4558), 
Vector(3168,54,4866), Vector(3024,57,6108), 
Vector(3156,52,6362), Vector(3774,52,7408), 
Vector(3674,52,7706), Vector(2552,52,9188), 
Vector(2874,51,9206), Vector(3242,51,9680), 
Vector(3524,-57,9706), Vector(3274,-65,10306), 
Vector(3074,54,10056), Vector(3322,-65,10174), 
Vector(3774,-6,9156), Vector(4084,-66,9280), 
Vector(5074,-71,10006), Vector(5128,-71,9698), 
Vector(4278,-71,10264), Vector(4474,-71,10456), 
Vector(5724,56,10806), Vector(5478,-71,10658), 
Vector(6024,53,9806), Vector(6054,-48,9492), 
Vector(8608,50,9646), 
Vector(8772,52,9356), Vector(10192,50,9076), 
Vector(10122,52,9356), Vector(10772,63,8506), 
Vector(10608,64,8686), Vector(11222,52,7856), 
Vector(11122,62,8156), Vector(11624,63,8678), 
Vector(11772,50,8856), Vector(11772,54,8106), 
Vector(12072,52,8106), Vector(11094,52,7208), 
Vector(11108,52,7506), Vector(10866,52,7204), 
Vector(10792,52,7484), Vector(11672,52,6508), 
Vector(11638,51,6204), Vector(11972,52,5658), 
Vector(12250,52,5542), Vector(11844,-71,4408), 
Vector(12058,53,4552), Vector(11562,-71,4816), 
Vector(11772,52,4958), Vector(11569,52,5240), 
Vector(11328,-59,5290), Vector(10672,-71,4508), 
Vector(10436,-71,4402), Vector(7280,53,5890), 
Vector(7156,57,5594), Vector(4024,52,6408), 
Vector(4266,52,6230), Vector(3532,51,7012), 
Vector(3548,51,6948), Vector(3674,52,6708), 
Vector(7472,52,6258), Vector(7740,-39,6392), 
Vector(7980,50,5930), Vector(8078,-71,6200), 
Vector(8268,19,5800), Vector(8266,-71,6054), 
Vector(7140,-47,8296), Vector(7322,53,8462), 
Vector(6870,-70,8616), Vector(7106,53,8644), 
Vector(6772,53,8976), Vector(6544,-71,8860),
Vector(12170,91,10240), Vector(12114,57,9980), 
Vector(11556,91,10442), Vector(11574,91,10456), 
Vector(11476,52,10160), Vector(10172,91,12156), 
Vector(9874,54,12128), Vector(10322,93,11606), 
Vector(10022,52,11556), Vector(2688,96,4664), 
Vector(2764,53,4950), Vector(4934,52,2856), Vector(4732,96,2794),
Vector(5002,52,2166), Vector(4748,96,2056),
Vector(7264,52,5900), Vector(7174,58,5608)
}

local Pos2 ={
Vector(8772,52,9356), Vector(10192,50,9076), 
Vector(10122,52,9356), Vector(10772,63,8506), 
Vector(10608,64,8686), Vector(11222,52,7856), 
Vector(11122,62,8156), Vector(11624,63,8678), 
Vector(11772,50,8856), Vector(11772,54,8106), 
Vector(12072,52,8106), Vector(11094,52,7208), 
Vector(11108,52,7506), Vector(10866,52,7204), 
Vector(10792,52,7484), Vector(11672,52,6508), 
Vector(11638,51,6204), Vector(11972,52,5658), 
Vector(12250,52,5542), Vector(11844,-71,4408), 
Vector(12058,53,4552), Vector(11562,-71,4816), 
Vector(11772,52,4958), Vector(11569,52,5240), 
Vector(11328,-59,5290), Vector(10672,-71,4508), 
Vector(10436,-71,4402), Vector(7280,53,5890), 
Vector(7156,57,5594), Vector(4024,52,6408), 
Vector(4266,52,6230), Vector(3532,51,7012), 
Vector(3548,51,6948), Vector(3674,52,6708), 
Vector(7472,52,6258), Vector(7740,-39,6392), 
Vector(7980,50,5930), Vector(8078,-71,6200), 
Vector(8268,19,5800), Vector(8266,-71,6054), 
Vector(7140,-47,8296), Vector(7322,53,8462), 
Vector(6870,-70,8616), Vector(7106,53,8644), 
Vector(6772,53,8976), Vector(6544,-71,8860),
Vector(12170,91,10240), Vector(12114,57,9980), 
Vector(11556,91,10442), Vector(11574,91,10456), 
Vector(11476,52,10160), Vector(10172,91,12156), 
Vector(9874,54,12128), Vector(10322,93,11606), 
Vector(10022,52,11556), Vector(2688,96,4664), 
Vector(2764,53,4950), Vector(4934,52,2856), Vector(4732,96,2794),
Vector(5002,52,2166), Vector(4748,96,2056),
Vector(7264,52,5900), Vector(7174,58,5608)
}

local Pos3 ={
Vector(4266,52,6230), Vector(3532,51,7012), 
Vector(3548,51,6948), Vector(3674,52,6708), 
Vector(7472,52,6258), Vector(7740,-39,6392), 
Vector(7980,50,5930), Vector(8078,-71,6200), 
Vector(8268,19,5800), Vector(8266,-71,6054), 
Vector(7140,-47,8296), Vector(7322,53,8462), 
Vector(6870,-70,8616), Vector(7106,53,8644), 
Vector(6772,53,8976), Vector(6544,-71,8860),
Vector(12170,91,10240), Vector(12114,57,9980), 
Vector(11556,91,10442), Vector(11574,91,10456), 
Vector(11476,52,10160), Vector(10172,91,12156), 
Vector(9874,54,12128), Vector(10322,93,11606), 
Vector(10022,52,11556), Vector(2688,96,4664), 
Vector(2764,53,4950), Vector(4934,52,2856), Vector(4732,96,2794),
Vector(5002,52,2166), Vector(4748,96,2056),
Vector(7064,50,5500), Vector(7820,40,5908)
}

function Kalista:__init()
	
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

function Kalista:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	if AIO.Misc.AutoE:Value() then
		self:AutoE()
	end		
	-- if AIO.Misc.QWall:Value() then
		-- self:CastQWall()
	-- end	
	
		self:KillstealQ()
		self:SpellonCCQ()
end

function Kalista:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + EDamage 
				if damage > hero.health then
					Draw.Text("KILLABLE", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(200,255,255,255))	
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
				end
if AIO.Drawings.DrawDamageMinion:Value() then
    for i = 1, Game.MinionCount() do
      local minion = Game.Minion(i)
        local barPos = minion.hpBar
		if minion and minion.isEnemy and not minion.dead and barPos.onScreen and minion.visible then
				local EDamage = (Ready(_E) and getdmg("E",minion,myHero) or 0)
				local damage = EDamage
				local percentage = tostring(0.1*math.floor(1000*damage/(minion.health))).."%"
				if HasBuff(minion, "kalistaexpungemarker") then
				Draw.Text(percentage,20,minion.pos:To2D())
				end
				end
		end
		end
		if AIO.Drawings.WJ.Enabled:Value() then
				for i=1,39,1 do
					if myHero.pos:DistanceTo(Pos1[i]) < 1700 then
						Draw.Circle(Pos1[i],40,AIO.Drawings.WJ.Width:Value(), AIO.Drawings.WJ.Color:Value())
					else if myHero.pos:DistanceTo(Pos2[i]) < 1700 then
						Draw.Circle(Pos2[i],40,AIO.Drawings.WJ.Width:Value(), AIO.Drawings.WJ.Color:Value())
						else if myHero.pos:DistanceTo(Pos3[i]) < 1700 then
						Draw.Circle(Pos3[i],40,AIO.Drawings.WJ.Width:Value(), AIO.Drawings.WJ.Color:Value())
					end
				end
				end
				end
				end
				end

function Kalista:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Kalista:EStacks(unit)
	if not unit then return 0 end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name and buff.name:lower() == "kalistaexpungemarker" and buff.count > 0 and buff.expireTime >= Game.Timer() then
			return buff.count
		end
	end
	return 0
end

function Kalista:Combo()
	for i = 1, Game.MinionCount() do
	local m = Game.Minion(i)
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
			else if m.pos:DistanceTo(target.pos) < 1000 then
		if m.isEnemy and ValidTarget(m,E.Range) then
			local stack = Kalista:EStacks(m)
			if stack > 0 then
				EDMG[m.networkID] = {Unit = m, Damage = Kalista:EDMG(m,stack)}
			else
				EDMG[m.networkID]  = nil
			end
			if stack > 0 and Kalista:EDMG(m,stack) > m.health then
				Control.CastSpell(HK_E)
			end
		    end
	    end
    end
    end
    end
    end
    end

function Kalista:AutoE()
if Ready(_E) then
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy and ValidTarget(hero,E.Range) then
			local stack = Kalista:EStacks(hero)
			if stack > 0 then
				EDMG[hero.networkID] = {Unit = hero, Damage = Kalista:EDMG(hero,stack)}
			else
				EDMG[hero.networkID]  = nil
			end
			if stack > 0 and Kalista:EDMG(hero,stack) > hero.health + hero.shieldAD + hero.hpRegen * 1.5 then
				Control.CastSpell(HK_E)
			end
		end
	end	
end
end

function Kalista:Clear()
	if AIO.Clear.UseQ:Value() and Ready(_Q) then
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and not minion.dead and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 1150) and myHero.pos:DistanceTo(minion.pos) < 1150 and not minion.dead then
				local Qdamage = Kalista:QDMG()
				if Qdamage >= HpPred(minion,1) + minion.hpRegen * 1 then
				if minion:GetCollision(40, 1150, 0.10) - 1 >= 2 then
					CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
	end
	end
	
	local minions = 0
	for i = 1, Game.MinionCount() do
	local m = Game.Minion(i)
		if m.isEnemy and ValidTarget(m,E.Range) then
			local stack = Kalista:EStacks(m)
			if stack > 0 then
				EDMG[m.networkID] = {Unit = m, Damage = Kalista:EDMG(m,stack)}
			else
				EDMG[m.networkID]  = nil
			end
			if stack > 0 and Kalista:EDMG(m,stack) > m.health then
			if (m.team == 300 and AIO.Clear.UseE:Value()) then	
				Control.CastSpell(HK_E)
			else
				minions = minions + 1	
			end
		end
			if minions >= AIO.Clear.ECount:Value() then
			Control.CastSpell(HK_E)
end
end
end
end
end

function Kalista:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Kalista:QDMG()
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if myHero.pos:DistanceTo(minion.pos) < 1150 and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= HpPred(minion,1) and (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function CalcDanoAntes(source, target, total)
	local ArmorPenPercent = source.armorPenPercent
	local ArmorPenFlat = source.armorPen * (0.6 + (0.4 * (target.levelData.lvl / 18)))
	local BonusArmorPen = source.bonusArmorPenPercent

	local armor = target.armor
	
	local bonusArmor = target.bonusArmor
	local baseArmor =  armor - bonusArmor
	
	local value = nil
	if armor <= 0 then
		value = 2 - 100 / (100 - armor)
	else
		baseArmor = baseArmor*ArmorPenPercent
		bonusArmor = bonusArmor*ArmorPenPercent*BonusArmorPen
		armor = baseArmor + bonusArmor
		if armor > ArmorPenFlat then
			armor = armor - ArmorPenFlat
		end
		value = 100 /(100 + armor)
	end
	if target.type ~= myHero.type then
		return value * total
	end	
	if HasBuff(source,"Exhaust") then
		total = total*0.6
	end
	if target.charName == "Garen" and HasBuff(target,"GarenW") then
		total = total*0.7
	elseif target.charName == "MaoKai" and HasBuff(target,"MaokaiDrainDefense") then
		total = total*0.7
	elseif target.charName == "MasterYi" and HasBuff(target,"Meditate") then
		total = total - total * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level]
	elseif target.charName == "Braum" and HasBuff(target,"BraumShieldRaise") then
		total = total*(1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level])	
	elseif target.charName == "Urgot" and HasBuff(target,"urgotswapdef") then
		total = total*(1 - ({0.3, 0.4, 0.5})[target:GetSpellData(_R).level])
	elseif target.charName == "Amumu" and HasBuff(target,"Tantrum") then
		total = total - ({2, 4, 6, 8, 10})[target:GetSpellData(_E).level]
	elseif target.charName == "Annie" and HasBuff(target,"MoltenShield") then
		total = total*(1 - ({0.16,0.22,0.28,0.34,0.4})[target:GetSpellData(_E).level])		
	end
	return value * total
end

function Kalista:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({10,70,130,190,250})[level] + 1.0 * myHero.totalDamage)
	return qdamage
end

function Kalista:EDMG(unit, stacks)
    local level = myHero:GetSpellData(_E).level
    local edamage = ({20, 30, 40, 50, 60})[level] + 0.6 * myHero.totalDamage
	local stacks = (stacks - 1)*(({10, 14, 19, 25, 32})[level]+({0.2, 0.225, 0.25, 0.275, 0.3})[level] * myHero.totalDamage)
	return CalcDanoAntes(myHero,unit,edamage + stacks)
end

function Kalista:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Kalista:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Kalista:SpellonCCQ()
    local target = CurrentTarget(1150)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(1150) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

class "KogMaw"


function KogMaw:LoadSpells()

	Q = {Range = 1175, Width = 70, Delay = 0.70, Speed = 1650, collision = true, aoe = false, Type = "line"}
	W = {Width = 1, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 1280, Width = 120, Delay = 0.25, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Width = 50, Delay = 0.55, Speed = 1000, Collision = false, aoe = true, Type = "circular", radius = 100}

end

function KogMaw:LoadMenu()
	AIO = MenuElement({type = MENU, id = "KogMaw", name = "Kypo's AIO: KogMaw", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "EClear", name = "Use E If Hit X Minion ", value = 4, min = 2, max = 7, step = 1})
	AIO.Clear:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Clear:MenuElement({id = "RHit", name = "E hits x minions", value = 3,min = 1, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "RCC", name = "Use R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	
	AIO.Killsteal:MenuElement({id = "RR", name = "Use R (Prediction)", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "RCC", name = "Use R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.isCC.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabledn", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 150, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function KogMaw:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:Wcast()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
		self:ClearECount()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:RKSNormal()
		self:SpellonCCQ()
		self:RCC()
		self:RKSCC()
end

function KogMaw:Wcast()
	if myHero:GetSpellData(_W).level == 0 then
		return
	elseif Ready(_W) and myHero:GetSpellData(_W).level == 1 then
	local target = CurrentTarget(630)
	if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(630) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif Ready(_W) and myHero:GetSpellData(_W).level == 2 then
	local target = CurrentTarget(650)
	if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(650) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif Ready(_W) and myHero:GetSpellData(_W).level == 3 then
	local target = CurrentTarget(670)
	if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(670) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif Ready(_W) and myHero:GetSpellData(_W).level == 4 then
	local target = CurrentTarget(690)
	if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(690) then
			    Control.CastSpell(HK_W)
				end
			end
		
			elseif Ready(_W) and myHero:GetSpellData(_W).level == 5 then
	local target = CurrentTarget(710)
	if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(630) then
			    Control.CastSpell(HK_W)
				end
			end
		
end
end

function KogMaw:RDrawnormal()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif not Ready(_R) then goto continue
	::continue:: elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return Draw.Circle(myHero.pos, self:RRange(), AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value()) 
	end
end

function KogMaw:RRange()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return 1200
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return 1500
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return 1800
	end
end

function KogMaw:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1175, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 1280, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if AIO.Drawings.R.Enabledn:Value() then self:RDrawnormal() end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			end
		end
		
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
		end
		
		if Ready(_R) then
			local target = CurrentTarget(self:RRange())
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

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
	
function KogMaw:Flee()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	if target == nil then return end
    if AIO.Flee.UseR:Value() and target and Ready(_R) then
	    if EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
    if AIO.Flee.UseR:Value() and target and Ready(_R) then
	    if EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	if target == nil then return end
    if AIO.Flee.UseR:Value() and target and Ready(_R) then
	    if EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function KogMaw:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < Q.Range then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
end
	
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < E.Range then
			    CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

function KogMaw:Harass()
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				if myHero.pos:DistanceTo(target.pos) < Q.Range then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
end
end

function KogMaw:Clear()
	if Ready(_R) then
	local rMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,1200)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				rMinions[#rMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(1200, 100 + 40, rMinions)
		if BestHit >= AIO.Clear.RHit:Value() and AIO.Clear.UseR:Value() then
			Control.CastSpell(HK_R,BestPos)
		end
	end
end
end

function KogMaw:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({80,130,180,230,280})[level] + 0.50 * myHero.ap)
			if myHero.pos:DistanceTo(minion.pos) < 1175 and AIO.Lasthit.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health then
				CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

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

function KogMaw:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = KogMaw:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    CastSpell(HK_Q,castpos)
				else if EnemyInRange(900) then 
				if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
				CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	end
	end
	end

function KogMaw:RKSNormal()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local Rdamage = KogMaw:RDMG()
	if target == nil then return end
    if AIO.Killsteal.RR["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local Rdamage = KogMaw:RDMG()
    if AIO.Killsteal.RR["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local Rdamage = KogMaw:RDMG()
	if target == nil then return end
    if AIO.Killsteal.RR["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
	end
end

function KogMaw:SpellonCCQ()
    local target = CurrentTarget(900)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function KogMaw:RCC()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if AIO.isCC.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local ImmobileEnemy = self:IsImmobileTarget(target)
    if AIO.isCC.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if AIO.isCC.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function KogMaw:RKSCC()
if myHero:GetSpellData(_R).level == 0 then
	return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
	local target = CurrentTarget(1200)
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1200) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1200, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
	local target = CurrentTarget(1500)
	if target == nil then return end
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
    if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1500) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1500, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
				end
			end
		end

	
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
	local target = CurrentTarget(1800)
	local Rdamage = KogMaw:RDMG()
	local ImmobileEnemy = self:IsImmobileTarget(target)
	if target == nil then return end
    if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
	    if EnemyInRange(1800) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1800, R.Speed, myHero.pos, R.ignorecol, R.Type )
		    if (HitChance > 0 ) and ImmobileEnemy then
				if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_R,castpos)
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
		if Ready(_E) then 
			if AIO.Clear.UseE:Value() and minion and minion:GetCollision(120, 1200, 0.25) - 1 >= AIO.Clear.EClear:Value() then
					CastSpell(HK_E, minion)
    end
  end
end
end
end

class "Leblanc"


function Leblanc:LoadSpells()

	Q = {Range = 700, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 600, Delay = 0.25, Speed = 2000, Collision = false, aoe = true, Type = "circular", Radius = 260}
	E = {Range = 925, Delay = 0.40, Speed = 1750, Collision = true, aoe = false, Type = "line", Radius = 27.5}

end

function Leblanc:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Leblanc", name = "Kypo's AIO: Leblanc", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "Type", name = "Combo Logic", value = 1,drop = {"EWQ", "WEQ"}})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseWQ", name = "WQ", value = false, key = string.byte("6")})
	AIO.Harass:MenuElement({id = "UseWo", name = "W Only", value = false, key = string.byte("V")})
	AIO.Harass:MenuElement({id = "AutoQ", name = "Auto Q", toggle = true, value = false, toggle, true, key = string.byte("Capslock")})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q to use passive?", value = true})
	AIO.Clear:MenuElement({id = "WHit", name = "W hits x minions", value = 3,min = 2, max = 8, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Flee", name = "E Key / Burst", type = MENU})
	AIO.Flee:MenuElement({id = "EKey", name = "E Key", key = string.byte("T")})
	AIO.Flee:MenuElement({id = "BurstEREQW", name = "Burst EREQW", key = string.byte("T")})

	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "E", name = "E", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Leblanc:__init()
	
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

function Leblanc:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:ComboTypes()
	end	
	if AIO.Harass.UseWQ:Value() then
		self:WQ()
	end	
	if AIO.Clear.clearActive:Value() then
		self:Clear()
		self:ClearQP()
	end
	--E key/Burst
	if AIO.Flee.BurstEREQW:Value() then
	self:BurstEREQW()
	self:BurstEQW()
	end
	if AIO.Flee.EKey:Value() and Ready(HK_E) then
	self:EKey()
	end
		self:AutoQ()
		self:KillstealQ()
		self:KillstealE()
		self:KillstealQPassive()
		self:ECC()
		self:UseWo()
	
end

function Leblanc:Draw()
	if AIO.Harass.AutoQ:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Auto Q ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(200, 255, 255, 255))
			end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 700, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 925, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 600, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end

	if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Range, E.Speed, E.Width, myHero.pos, not E.ignorecol, E.Type )
			Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end	
	end

function Leblanc:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Leblanc:ComboTypes(target)
local mode = AIO.Combo.Type:Value() 
	if mode == 1 then
		self:EWQ()
	elseif mode == 2 then
		self:WEQ()
end
end

-- 1
function Leblanc:EWQ()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and Ready(_E) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Range, E.Speed, E.Width, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    CastSpell(HK_E, castpos)
		    end
	    end

local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) then
	    if EnemyInRange(W.Range) and HasBuff(target, "leblanceroot") or HasBuff(target, "LeblancPMark") then
			    CastSpell(HK_W, target)
		    end
	    end
		
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			    CastSpell(HK_Q, target)
		    end
	    end
end


-- 2
function Leblanc:WEQ()
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) and EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    CastSpell(HK_W, castpos)
		    end
	    end


local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and Ready(_E) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    CastSpell(HK_E, castpos)
		    end
	    end
		
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			    Control.CastSpell(HK_Q, target)
		    end
	    end
end

function Leblanc:Clear()
	if Ready(_W) then
	local wMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,600)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				wMinions[#wMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(600, 260 + 40, wMinions)
		if BestHit >= AIO.Clear.WHit:Value() then
			Control.CastSpell(HK_W,BestPos)
		end
	end
end
end

function Leblanc:ClearQP()
if AIO.Clear.UseQ:Value() then
	if Ready(_Q) then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local pBuff = GetBuffData(minion,"LeblancPMark")
			if ValidTarget(minion,600) and pBuff then
			DelayAction(function()
			if not Ready(_Q) and not Ready(HK_W) then return end
			Control.CastSpell(HK_Q, minion)
			end, 1.20) end
			end
		end
	end
end

function Leblanc:WQ()
     if AIO.Harass.UseWQ:Value() then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) and EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    CastSpell(HK_W, castpos)
		if Ready(_Q) then
	    if EnemyInRange(Q.Range) and HasBuff(target, "LeblancPMark") then
			DelayAction(function()
			if not Ready(_Q) then return end
			Control.CastSpell(HK_Q, target)
			end, 0.95) end
		    end
		    end
	    end
		end
end

function Leblanc:UseWo()
     if AIO.Harass.UseWo:Value() then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) and EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    CastSpell(HK_W, castpos)
end
end
end
end

function Leblanc:AutoQ()
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
if target and Ready(_Q) and EnemyInRange(Q.Range) and AIO.Harass.AutoQ:Value() then
			Control.CastSpell(HK_Q, target)
		end
	end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

----------------------------------------------------------------------------- Without Passive

function Leblanc:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({55,90,125,160,195})[level] + 0.50 * myHero.ap)
	return qdamage
end

function Leblanc:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({80,120,160,200,240})[level] + 1.0 * myHero.ap * 2)
	return edamage
end

----------------------------------------------------------------------------- With Passive

function Leblanc:QDMGPassive()
    local level = myHero:GetSpellData(_Q).level
    local passive = myHero.levelData.lvl
    local qdamage = (({55,90,125,160,195})[level] + 0.50 * myHero.ap) + (({30,40,50,60,70,80,90,100,120,140,160,180,200,220,240,260,280,300})[passive])
	return qdamage
end

function Leblanc:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Leblanc:QDMG()
		   	local QdamagePassive = Leblanc:QDMGPassive()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_Q, target)
				end
			end
		end
	end
	
function Leblanc:KillstealQPassive()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local QdamagePassive = Leblanc:QDMGPassive()
			if HasBuff(target, "LeblancPMark") and QdamagePassive >= HpPred(target,1) + target.hpRegen * 1 then
			DelayAction(function()
			if not Ready(_Q) then return end
			Control.CastSpell(HK_Q, target)
			end, 1.00) end
				end
			end
		end

function Leblanc:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(Q.Range) then 
		   	local Edamage = Leblanc:EDMG()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target and Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_E, castpos)
		    end
	    end
	    end
	    end

function Leblanc:ECC()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.isCC.E:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

function Leblanc:BurstEREQW()
local target = CurrentTarget(E.Range)
    if target == nil then return end
	if Ready(_R) then
    if target and Ready(_E) and Ready(_W) and Ready(_Q) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    CastSpell(HK_E, castpos)
		    end
	    end
		
if not Ready(_E) then
local target = CurrentTarget(E.Range)
    if target == nil then return end
			if target and Ready(_R) then
			    Control.CastSpell(HK_R)
		    end
		    end
		
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and Ready(_E) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target and Ready(_E) then
			    CastSpell(HK_E, castpos)
		    end
	    end
		
if not Ready(_E) then
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target then
	    if EnemyInRange(Q.Range) then
			-- Control.CastSpell(HK_Q, target)
			if Ready(_Q) then
				Control.CastSpell(HK_Q, target)
		    end
	    end
	    end
	    end

if not Ready(_Q) then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) and EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
		    end
	    end
end
end
end

function Leblanc:BurstEQW()
local target = CurrentTarget(E.Range)
    if target == nil then return end
	if not Ready(_R) then
    if target and Ready(_E) and Ready(_W) and Ready(_Q) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    CastSpell(HK_E, castpos)
		    end
	    end
		
if not Ready(_E) and Ready(_W) and Ready(_Q) then
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if target then
	    if EnemyInRange(Q.Range) then
			-- Control.CastSpell(HK_Q, target)
			if Ready(_Q) then
				Control.CastSpell(HK_Q, target)
		    end
	    end
	    end
	    end
	    end

if not Ready(_Q) and Ready(_W) then
local target = CurrentTarget(W.Range)
    if target == nil then return end
    if target and Ready(_W) and EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Radius, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		if (HitChance > 0 ) then
			    Control.CastSpell(HK_W, castpos)
		    end
	    end
end
end

function Leblanc:EKey()
local target = CurrentTarget(E.Range)
    if target == nil then return end
    if target and Ready(_E) and EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Radius, E.Range, E.Speed, myHero.pos, not E.ignorecol, E.Type )
			if (HitChance > 0 ) and target then
			    CastSpell(HK_E, castpos)
		    end
	    end
end

class "Orianna"


function Orianna:LoadSpells()

	Q = {Range = 825, Width = 40, Delay = 0.40, Speed = 1200, Collision = false, aoe = false, Type = "circular"}
	W = {Delay = 0.10, Speed = 1200, Collision = false, aoe = false, Type = "circular", Radius = 250}
	E = {Range = 1100, Width = 40, Delay = 0.35, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	R = {Delay = 0.35, Speed = 1200, Collision = false, aoe = false, Type = "circular", Radius = 325}

end

function Orianna:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Orianna", name = "Kypo's AIO: Orianna", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "Rkey", name = "R Key",  key = string.byte("T")})
	AIO.Combo:MenuElement({id	= "ShieldMinHealth", name="Min Health -> %",value=30,min=0,max=100})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "QCount", name = "Use Q on X minions", value = 3, min = 1, max = 4, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS on: ", value = false, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end

	AIO:MenuElement({id = "Misc", name = "Misc", type = MENU})
	AIO.Misc:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Misc:MenuElement({id = "RCount", name = "Use R on X targets", value = 2, min = 1, max = 5, step = 1})
	

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	
		AIO:MenuElement({id = "WomboCombo", name = "Wombo Combo", type = MENU})
    AIO.WomboCombo:MenuElement({id = "AutoE", name = "Auto E on dashing Allys", value = true})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	--Ball
	AIO.Drawings:MenuElement({id = "B", name = "Draw R Range on Ball", type = MENU})
    AIO.Drawings.B:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.B:MenuElement({id = "Width", name = "Width", value = 5, min = 1, max = 5, step = 1})
    AIO.Drawings.B:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 87, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Orianna:__init()
	
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

function Orianna:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboW()
		self:BallMe()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	if AIO.Combo.Rkey:Value() then
		self:RKey()
	end		
	if AIO.WomboCombo.AutoE:Value() then
		self:AutoEDashingAllys()
	end		
		self:KillstealQ()
		self:KillstealW()
		self:KillstealR()
		
		self:Autoshield()
		self:AutoultMe()
		self:Autoult1Ally()
		self:AutoultBall()
		self:Ball()
	
	end

	function Orianna:Ball()
		for i = 1, Game.ParticleCount() do 
			local particle = Game.Particle(i)
			if particle.name == "Orianna_Base_Q_yomu_ring_green.troy" then 
				ball = particle.pos 
				break
			end
		end	
		if HasBuff(myHero, "orianaghostself") then 
			ball = ball
		else
			for i = 1, Game.HeroCount() do
				local hero = Game.Hero(i)
				if HasBuff(hero, "orianaghost") then 
					ball = hero.pos 
					break
				end
			end
		end
	end

function Orianna:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if AIO.Drawings.B.Enabled:Value() and Ready(_R) and not HasBuff(myHero, "orianaghostself") then 
Draw.Circle(ball, 400, AIO.Drawings.B.Width:Value(), AIO.Drawings.B.Color:Value()) 
	else if AIO.Drawings.B.Enabled:Value() and Ready(_R) and HasBuff(myHero, "orianaghostself") then
	Draw.Circle(myHero.pos, 400, AIO.Drawings.B.Width:Value(), AIO.Drawings.B.Color:Value()) 
	end 
end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + RDamage + EDamage
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 50, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))				
					else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
				end
		  if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
end
end

function Orianna:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Orianna:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(1300) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
			end
		    end
	    end
	    end
		
function Orianna:ComboW()
	local target = CurrentTarget(1300)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
			if ball and target.pos:DistanceTo(ball) < 240 then
				Control.CastSpell(HK_W)
			else if not ball then return end
			end
		    end
			
end
	
function Orianna:BallMe()
	local target = CurrentTarget(300)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
			if myHero.pos:DistanceTo(target.pos) < 250 then
				Control.CastSpell(HK_W)
			end
		    end
	    end
	    
function Orianna:Autoshield()
    local target = CurrentTarget(1000)
	if target == nil then return end
	if AIO.Combo.UseE:Value() and Ready(_E) and myHero.health<=myHero.maxHealth * AIO.Combo.ShieldMinHealth:Value()/100 then
	if EnemyInRange(1000) then 
	Control.CastSpell(HK_E, myHero)
	end
	end
end

function Orianna:Clear()
	if Ready(_Q) then
	local qMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,825)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				qMinions[#qMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(825, 250, qMinions)
		if BestHit >= AIO.Clear.QCount:Value() and AIO.Clear.UseQ:Value() then
			Control.CastSpell(HK_Q,BestPos)
		end
	end
end
end

function Orianna:Lasthit()
	if Ready(_Q) and AIO.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Orianna:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < 825 and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= HpPred(minion,1) then
			    CastSpell(HK_Q,minion)
				end
			end
		end
	end
end

function Orianna:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({60,90,120,150,180})[level] + 0.5 * myHero.ap)
	return qdamage
end

function Orianna:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({60,105,150,195,240})[level] + 0.7 * myHero.ap)
	return wdamage
end

function Orianna:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({150,225,300})[level] + 0.7 * myHero.ap)
	return rdamage
end

function Orianna:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Orianna:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
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

function Orianna:KillstealW()
	local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		   	local Wdamage = Orianna:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
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

function Orianna:KillstealR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) and target then
		   	local Rdamage = Orianna:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if myHero.pos:DistanceTo(target.pos) < 380 and HasBuff(myHero, "orianaghostself") then
			    Control.CastSpell(HK_R)
			else if ball and target.pos:DistanceTo(ball) < 380 then
				Control.CastSpell(HK_R)
			else if ball and myHero.pos:DistanceTo(target.pos) < 380 and target.pos:DistanceTo(ball) > 380 then
				Control.CastSpell(HK_E, myHero)
			else if not HasBuff(myHero, "orianaghostself") and ball and myHero.pos:DistanceTo(ball) > 380 and myHero.pos:DistanceTo(target.pos) < 380 then
				Control.CastSpell(HK_E, myHero)
			else for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)
				if hero.isAlly and HasBuff(hero, "orianaghost") and hero.pos:DistanceTo(target.pos) < 250 then
				Control.CastSpell(HK_R)
			else if not ball then return end
				end
			end
		end
		end
	end
	end
	end
	end
	end


function Orianna:EnemiesNear(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:EnemiesNearAlly(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:EnemiesNearBall(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isAlly and not hero.dead then
			N = N + 1
		end
	end
	return N	
end

function Orianna:AutoultMe() --work
if AIO.Misc.UseR:Value() then
	if self:EnemiesNear(myHero.pos,380) >= AIO.Misc.RCount:Value() and HasBuff(myHero, "orianaghostself") then
		Control.CastSpell(HK_R)
	else if not HasBuff(myHero, "orianaghostself") and self:EnemiesNear(myHero.pos,380) >= AIO.Misc.RCount:Value() and Ready(_E) and Ready(_R) then
		Control.CastSpell(HK_E, myHero)
	end
end
end
end

function Orianna:Autoult1Ally()
	local target = CurrentTarget(600)
	if target == nil then return end
	if AIO.Misc.UseR:Value() and Ready(_R) then
	for i = 1, Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isAlly and not hero.isMe then
	if HasBuff(hero, "orianaghost") and self:EnemiesNearAlly(hero.pos,380) >= AIO.Misc.RCount:Value() and target.pos:DistanceTo(hero.pos) < 380 then
		Control.CastSpell(HK_R)
	end
end
end
end
end

function Orianna:AutoultBall()
if AIO.Misc.UseR:Value() and Ready(_R) then
   		local N = 0 
    		for i = 1, Game.HeroCount() do 
    			local hero = Game.Hero(i)
    			if hero.isEnemy and not hero.dead and hero.isTargetable then 
					if hero.pos:DistanceTo(ball) < 380 then 
    					N = N + 1 
    				end
    			end
    		end
    		if N >= AIO.Misc.RCount:Value() then 
    	Control.CastSpell(HK_R)
end
end
end

function Orianna:RKey()
if Ready(_R) then
   	for i = 1, Game.HeroCount() do 
    	local hero = Game.Hero(i)
    	if hero.isEnemy and not hero.dead and hero.isTargetable then 
			if hero.pos:DistanceTo(ball) < 380 then 
     	Control.CastSpell(HK_R)
	else if HasBuff(myHero, "orianaghost") then
		if hero.pos:DistanceTo(myHero) < 380 then
		Control.CastSpell(HK_R)

end
end
end
end
end
end
end

function Orianna:GetDashingHeroes()
	self.DashingHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			table.insert(self.DashingHeroes, Hero)
		end
	end
	return self.DashingHeroes
end

function Orianna:AutoEDashingAllys()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
		if hero.pathing.hasMovePath and hero.pathing.isDashing and hero.pathing.dashSpeed > 500 then 
				for i, allyHero in pairs(self:GetDashingHeroes()) do 
					if myHero.pos:DistanceTo(hero.pos) < 1100 and Ready(_E) then 
							Control.CastSpell(HK_E,hero.pos)
						end
					end
				end
			end
		end
	end

class "Blitzcrank"


function Blitzcrank:LoadSpells()

	Q = {Range = 950, Width = 70, Delay = 0.30, Speed = 1800, Collision = true, aoe = false}
	E = {Range = 280, Delay = 0}
	R = {Range = 600, Width = 0, Delay = 0.01, Speed = 347, Collision = false, aoe = false, Type = "circular"}

end

function Blitzcrank:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Blitzcrank", name = "Kypo's AIO: Blitzcrank", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	-- AIO.Combo:MenuElement({id = "Rkey", name = "R Key", value = false, key = string.byte("6"), tooltip = "make sure this key is unique and has no movement"})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Killsteal:MenuElement({id = "RR", name = "R on:", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Use Q on:"})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.isCC:MenuElement({id = "UseQ"..hero.charName, name = ""..hero.charName, value = true})
	end

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Blitzcrank:__init()
	
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

function Blitzcrank:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
	end
		self:KillstealQ()
		self:KillstealE()
		self:KillstealR()
		self:SpellonCCQ()
end

function Blitzcrank:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 950, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 600, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
	
    if Ready(_Q) then
			if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end
end

function Blitzcrank:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Blitzcrank:Combo()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and target.pos:DistanceTo(myHero.pos) > 450 then
			Control.CastSpell(HK_Q,castpos)
		end
	end
	end

function Blitzcrank:ComboE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Combo.UseE:Value() and target and Ready(_E) then
	if EnemyInRange(E.Range) then 
			Control.CastSpell(HK_E)
		end
	end
	end

function Blitzcrank:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({80, 135, 190, 245, 300})[level] + 1.0 * myHero.ap
	return qdamage
end

function Blitzcrank:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = myHero.totalDamage * 2
	return edamage
end

function Blitzcrank:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = ({250, 375, 500})[level] + 1.0 * myHero.ap
	return rdamage
end

function Blitzcrank:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
	if EnemyInRange(Q.Range) then 
			local Qdamage = Blitzcrank:QDMG()
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if (HitChance > 0 ) then
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			Control.CastSpell(HK_Q,castpos)
end
end
end
end
end

function Blitzcrank:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
	if EnemyInRange(E.Range) then 
			local Edamage = Blitzcrank:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			    Control.CastSpell("E")
				Control.Attack(target)	
				end
			end
		end
	end

function Blitzcrank:KillstealR()
	local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and target and Ready(_R) then
	if EnemyInRange(R.Range) then 
			local Rdamage = Blitzcrank:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 and not target.dead then
			    Control.CastSpell(HK_R)
				end
			end
		end
	end

function Blitzcrank:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.isCC["UseQ"..target.charName]:Value() and target and Ready(_Q) then
	if EnemyInRange(Q.Range) then 
	local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and target.pos2D.onScreen and target.visible then 
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

class "Draven"


function Draven:LoadSpells()

	Q = {Range = 550, Width = 0, Delay = 0.50, Speed = 20, Collision = true, aoe = false, Type = "line"}
	E = {Range = 1050, Width = 130, Delay = 0.40, Speed = 1600, Collision = false, aoe = true, Type = "line"}
	R = {Range = 20000, Width = 160, Delay = 0.80, Speed = 2000, Collision = false, aoe = false, Type = "line"}

end

function Draven:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Draven", name = "Kypo's AIO: Draven", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	-- AIO.Combo:MenuElement({id = "CatchQ", name = "Catch Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	-- AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	-- AIO.Harass:MenuElement({id = "CatchQ", name = "Catch Q", value = true})
	AIO.Harass:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
		
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "UseR", name = "Semi R", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = false, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = false})
	end

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseE", name = "E", value = true})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Snare, Knockup, Supression, Fear, Charm"})

	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Draven:__init()
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

function Draven:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboW()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end	
		self:KillstealE()
		self:KillstealR()
		self:RksCC()
		self:SpellonCCE()	
end

function Draven:Draw()
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 1100, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end			
		if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, "circular" )
			Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

function Draven:CastSpell(spell,pos)
	local customcast = AIO.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = AIO.delay:Value()
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

function Draven:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Draven:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	-- local qgrab = self:QGrab()
	    if EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q)
			-- self:QGrab()
		    end
	    end
	    end
		
function Draven:ComboW()	
	local target = CurrentTarget(1000)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if myHero.pos:DistanceTo(target.pos) > 700 then
			Control.CastSpell(HK_W)
		    end
	    end
end

function Draven:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q)
		    end
	    end
		
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Harass.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) then
			Control.CastSpell(HK_E, castpos)
		    end
	    end
    end
end

function Draven:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({75,110,145,180,215})[level] + 0.5 * myHero.bonusDamage)
	return edamage
end

function Draven:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({250,350,500})[level] + 1.1 * myHero.bonusDamage)
	return rdamage
end

function Draven:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Draven:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_E) then
			Control.CastSpell(HK_E, castpos)
			end
			end
		end
	end
end

function Draven:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Draven:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end
end

function Draven:SpellonCCE()
    local target = CurrentTarget(1050)
	if target == nil then return end
	if AIO.isCC.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(1050) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			Control.CastSpell(HK_E, castpos)
			end
			end
		end
	end
end

function Draven:RksCC()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = Draven:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end
end
end

function Draven:Flee()
    local target = CurrentTarget(20000)
	if target == nil then return end
	if AIO.Flee.UseR:Value() and Ready(_R) then
		if EnemyInRange(20000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if target and (HitChance > 0 ) then
			Control.CastSpell(HK_R, castpos)
				end
			end
		end
	end

-- function Draven:QGrab(particle, pos)
	-- for i = 0, Game.ParticleCount() do
		-- particle = Game.Particle(i)
		-- local dravenparticle = particle.pos
		-- local heropos = math.sqrt(DistTo(dravenparticle, myHero.pos))
		-- if particle.name == "Draven_Base_Q_reticle.troy" and heropos < 700 then
				-- if self-Menu.Combo.CatchQ:Value() and Ready(_Q) then
				-- Control.SetCursorPos(dravenparticle)
				-- DelayAction(RightClick, dravenparticle.pos)
				-- end
				-- else if particle.name == "Draven_Base_Q_ReticleCatchSuccess" then
				-- print("Picked Axe!")
			-- end
		-- end
	-- end
-- end
		
-- and HasBuff(myHero, "DravenSpinning") or HasBuff(myHero, "dravenspinningleft")
		
-- Draven_Base_Q_activation.troy
-- Draven_Base_Q_Alt_mis.troy
-- Draven_Base_Q_buf.troy
-- Draven_Base_Q_catch_indicator.troy
-- Draven_Base_Q_crit_mis.troy
-- Draven_Base_Q_mis.troy
-- Draven_Base_Q_reticle.troy
-- Draven_Base_Q_reticle_self.troy
-- Draven_Base_Q_ReticleCatchSuccess.troy
-- Draven_Base_Q_tar.troy
	
	
	-- if myHero.attackData.state ~= 2 then
	-- MoveToParticle(dravenparticle)
	-- DelayAction(RightClick, dravenparticle.pos)
	-- Control.SetCursorPos(target)
	-- (RightClick)

function DistTo(firstpos, secondpos)
	local secondpos = secondpos or H.pos
	local distx = firstpos.x - secondpos.x
	local distyz = (firstpos.z or firstpos.y) - (secondpos.z or secondpos.y)
	local distf = (distx*distx) + (distyz*distyz)
	return distf
end

	
function MoveToParticle(position)
	if position ~= nil then
		if _G.SDK then
			_G.SDK.Orbwalker.ForceMovement = position
	else
		if _G.SDK then
			_G.SDK.Orbwalker.ForceMovement = nil
			end
		end
	end
end

class "Ezreal"


function Ezreal:LoadSpells()

	Q = {Range = 1150, Width = 80, Delay = 0.25, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 1050, Width = 80, Delay = 0.25, Speed = 1600, Collision = false, aoe = false, Type = "line"}
	E = {Range = 475, Delay = 0.25}
	R = {Range = 2000, Width = 160, Delay = 1.35, Speed = 2000, Collision = false, aoe = false, Type = "line"}

end

function Ezreal:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Ezreal", name = "Kypo's AIO: Ezreal", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "RCConly", name = "R KS CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCConly:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "UseW", name = "W", value = true})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Snare, Taunt, Charm, Knockup..etc"})

	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Ezreal:__init()
	
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

function Ezreal:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealR()
		self:SpellonCCW()
		self:SpellonCCQ()
		self:RksCC()
end

function Ezreal:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1150, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 1000, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 475, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

function Ezreal:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Ezreal:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos) 
		    end
	    end
    end

	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) then
			CastSpell(HK_W, castpos)
            end
		end
	end
 
    local target = CurrentTarget(500)
    if target == nil then return end
	if AIO.Combo.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(500) then
			Control.CastSpell(HK_E, mousePos)
		end
	end
end

function Ezreal:Harass()
    local target = CurrentTarget(1150)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
		    end
	    end
    end

	if AIO.Harass.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) then
			    CastSpell(HK_W,castpos)
            end
		end
	end

end

function Ezreal:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 1150) and myHero.pos:DistanceTo(minion.pos) < 1150 and not minion.dead then
					CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

function Ezreal:Lasthit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({40, 55, 75, 95, 115})[level] + 1.1 * myHero.totalDamage)
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if myHero.pos:DistanceTo(minion.pos) < 1150 and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= HpPred(minion,1) and (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Ezreal:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({40, 55, 75, 95, 115})[level] + 1.1 * myHero.totalDamage)
	return qdamage
end

function Ezreal:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70, 115, 160, 205, 250})[level] + 0.8 * myHero.ap)
	return wdamage
end

function Ezreal:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({200, 250, 300})[level] + 1.0 * myHero.totalDamage + 0.90 * myHero.ap)
	return rdamage
end

function Ezreal:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Ezreal:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Ezreal:KillstealW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Ezreal:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_W) and target  then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Ezreal:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Ezreal:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Ezreal:SpellonCCW()
    local target = CurrentTarget(1000)
	if target == nil then return end
	if AIO.isCC.UseW:Value() and target and Ready(_W) then
	if EnemyInRange(1000) then 
	local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_W).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Ezreal:SpellonCCQ()
    local target = CurrentTarget(1150)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(1150) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function Ezreal:RksCC()
    local target = CurrentTarget(1500)
	if target == nil then return end
	if AIO.Killsteal.RCConly["UseR"..target.charName]:Value() and target and Ready(_R) then
		if EnemyInRange(1500) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Ezreal:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

class "Fizz"


function Fizz:LoadSpells()

	Q = {Range = 550, Delay = 0.25, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 225, Delay = 0.25}
	E = {Range = 800}
	R = {Range = 1300, Width = 150, Delay = 0.60, Speed = 1300, Collision = false, aoe = true}

end

function Fizz:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Fizz", name = "Kypo's AIO: Fizz", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = false})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "SemiR", name = "R Key", type = MENU})
	AIO.SemiR:MenuElement({id = "UseR", name = "R", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Fizz:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end	
		self:KillstealQ()
		self:KillstealR()
		self:RksCC()
		self:SemiR()
		self:Wuse()
		self:Quse()
		self:Euse()
	
end

function Fizz:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 550, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 400, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1300, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_R) then
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

function Fizz:CastQ(target)
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = target or (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.Range,"AP"))
	if target and target.type == "AIHeroClient" and Ready(_Q) then
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
	if AIO.SemiR.UseR:Value() and Ready(_R) then
		if EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 1300,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and Ready(_R) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Fizz:Wuse()
 if AIO.Combo.comboActive:Value() and AIO.Combo.UseW:Value() and Ready(_W) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if EnemyInRange(225) then 
			local level = myHero:GetSpellData(_W).level	
			if target then
			Control.CastSpell(HK_W,target)
		end
	end
end
end

function Fizz:Quse()
	if AIO.Combo.comboActive:Value() and AIO.Combo.UseQ:Value() and Ready(_Q) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end
end

function Fizz:Euse()
    if AIO.Combo.comboActive:Value() and AIO.Combo.UseE:Value() and Ready(_E) then
	local target = CurrentTarget(800)
	if target == nil then return end
		if EnemyInRange(800) then 
			local level = myHero:GetSpellData(_E).level	
			if target then
			Control.CastSpell(HK_E,target)
		end
	end
end
end

function Fizz:Harass()
     if AIO.Harass.UseQ:Value() and AIO.Harass.UseQ:Value() and Ready(_Q) and EnemyInRange(Q.Range) then
	local target = CurrentTarget(550)
	if target == nil then return end
		if EnemyInRange(550) then 
			local level = myHero:GetSpellData(_Q).level	
			if target then
			Control.CastSpell(HK_Q,target)
		end
	end
end

     if AIO.Harass.UseQ:Value() and AIO.Harass.UseW:Value() and Ready(_W) and EnemyInRange(W.Range) then
	local target = CurrentTarget(225)
	if target == nil then return end
		if EnemyInRange(225) then 
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

function Fizz:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		   	local Qdamage = Fizz:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    self:CastQ()
				end
			end
		end
	end

function Fizz:KillstealR()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(1300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Fizz:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Fizz:RksCC()
    local target = CurrentTarget(1300)
	if target == nil then return end
	if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and target and Ready(_R) then
		if EnemyInRange(1300) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		 	local Rdamage = Fizz:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

function Fizz:GetItemData(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and Game.CanUseSpell(spell) == 0 
end

class "LeeSin"


function LeeSin:LoadSpells()

	Q = {Range = 1000, Width = 60, Delay = 0.30, Speed = 1800, Collision = true, aoe = false, Type = "line"}
	Q2 = {Range = 1300, Width = 0, Delay = 0, Speed = 0, Collision = false, aoe = false, Type = "line"}
	W = {Range = 700, Width = 80, Delay = 0.25, Speed = 800, Collision = false, aoe = false}
	E = {Range = 425, Width = 80, Delay = 0.10, Speed = 0, Collision = false, aoe = false, Type = "circular"}
	E2 = {Range = 575, Width = 80, Delay = 0.25, Speed = 2000, Collision = false, aoe = false}
	R = {Range = 375, Width = 80, Delay = 0.25, Speed = 1900, Collision = false, aoe = false, Type = "line"}

end

function LeeSin:LoadMenu()
	AIO = MenuElement({type = MENU, id = "LeeSin", name = "Kypo's AIO: LeeSin", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W when HP below %",value=25,min=5,max=50, step = 5})
	AIO.Combo:MenuElement({id = "UseE", name = "E"})	
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQW", name = "QW", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})	
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	-- AIO:MenuElement({id = "Ultimate", name = "Ultimate", type = MENU})
	-- AIO.Ultimate:MenuElement({id = "Min", name = "Min enemies", value = 3,min = 2, max = 5, step = 1})	
	
	AIO:MenuElement({id = "Modes", name = "Modes", type = MENU})
	AIO.Modes:MenuElement({id = "Wardjump", name = "Wardjump", key = string.byte("T")})
	AIO.Modes:MenuElement({id = "Flashkick", name = "Flashkick", key = string.byte("5")})
	AIO.Modes:MenuElement({id = "Insec", name = "Insec", key = string.byte("S")})
	-- AIO.Modes:MenuElement({id = "InAndOut", name = "In and Out, smite Dragon/Baron", key = string.byte("Capslock")})
	AIO.Modes:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Modes:MenuElement({id = "KickPos", name = "Kick Position", key = string.byte("6")})

	AIO:MenuElement({id = "AutoW", name = "AutoW", type = MENU})
	AIO.AutoW:MenuElement({id = "savehp", name = "Save allies when HP below ", value = 20,min = 0, max = 100, step = 5})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Killsteal:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	
	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "QCC", name = "Q on CC", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.isCC.QCC:MenuElement({id = "UseQ"..hero.charName, name = "Use Q on: "..hero.charName, value = false})
	end

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw Ward range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function LeeSin:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboQDelay()
		self:ComboE()
		self:ComboQ2()
		self:ComboW()
	end	
	if AIO.Harass.harassActive:Value() then
		self:Harass()
		self:HarassQ2()
		self:HarassWBack()
		self:HarassWBackM()
	end	
	if AIO.Clear.clearActive:Value() then
		self:Clear()
		self:ClearW()
		self:ClearE()
	end	
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
		self:LasthitE()
	end		
	if AIO.Modes.Wardjump:Value() then
		self:Wardjump()
	end			
	-- if AIO.Modes.InAndOut:Value() then
		-- self:InAndOut1()
	-- end	
	if AIO.Modes.KickPos:Value() then
		Position=mousePos
	end	
	if AIO.Modes.Flashkick:Value() then
		self:FK(Position)
	end
	if AIO.Modes.Insec:Value() then
	self:Insec(Position)
	end
		self:KillstealQ()
		self:KillstealE()
		self:RKS()
		self:SpellonCCQ()
		self:AutoW()
		
		-- self:Autoult()
end

function LeeSin:Cast(spell,pos)
	Control.SetCursorPos(pos)
	Control.KeyDown(spell)
	Control.KeyUp(spell)
end

function LeeSin:validunit(unit)
	return unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable
end

function LeeSin:EnemiesAround(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if ValidTarget(hero,range + hero.boundingRadius) and hero.isEnemy then
			N = N + 1
		end
	end
	return N	
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
	if target and Ready(_R) and wardslot then
		local pos=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))+302,poz)
		local pos2=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))-705,poz)
		if Vector(myHero.pos):DistanceTo(pos)<=598 and not MapPosition:inWall(pos) then
			if self:ultimapos(target):DistanceTo(pos2)>302 or Vector(myHero.pos):DistanceTo(pos)>=100 and Ready(_W) then
			self:Cast(hkitems[wardslot], pos)
			self:Cast(hkitems[_W], pos)		
			end
			if self:ultimapos(target):DistanceTo(pos2)<=302 then
				Control.CastSpell(HK_R,target)
			end
		elseif Ready(_W) and Ready(_Q) then
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

function LeeSin:ultimapos(targetx,from)
	local from=from or Vector(myHero.pos)
	local targetx=targetx or target
	return self:Normalized2(Vector(targetx.pos),from:DistanceTo(Vector(targetx.pos))+700,from)
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

function LeeSin:Draw()
Draw.Circle(Position,150,Draw.Color(170,255, 255, 255))
Draw.Circle(Vector(9072,52,4558),160,Draw.Color(170,255, 255, 255))
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 600, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(AIO.Drawings.HPColor:Value()))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			local collisionc = Q.ignorecol and 0 or Q.minionCollisionWidth
			
			if (TPred) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			end
		end
		if Ready(_E) then
			local target = CurrentTarget(E.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos,  E.ignorecol, E.Type )
			end
		end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			end
		end
end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

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
		if ValidTarget(hero,range) and hero.isEnemy then
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
	if target and Ready(_R) then
			local posicao1=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))+180,poz)
			local posicao2=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))-700,poz)
			if Vector(myHero.pos):DistanceTo(posicao1)<=360 and Vector(myHero.pos):DistanceTo(Vector(target.pos))<= 375 then
				if LeeSin:ultimapos(target):DistanceTo(posicao2)<=300 then
					Control.CastSpell(HK_R,target)
				elseif Ready(flashslot) and not MapPosition:inWall(posicao1) then
					Control.CastSpell(HK_R,target)
					DelayAction(function()CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,posicao1)end,0.2)
				end
			elseif Ready(flashslot) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and not MapPosition:inWall(posicao1) then
			    Control.CastSpell(HK_Q,castpos)			
			end
		end
	end
end

function LeeSin:AutoW()
if Ready(_W) then
		for i = 1,Game.HeroCount()  do
			local hero = Game.Hero(i)	
			if ValidTarget(hero,700) and hero.isAlly and not hero.isMe then
				if hero.health/hero.maxHealth <= AIO.AutoW.savehp:Value()/100 and self:CountEnemy(hero.pos,700) > 0 then
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
		if ValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

-- function LeeSin:Autoult()
	-- for i = 1, Game.HeroCount() do
	-- local hero = Game.Hero(i)
		-- if hero and hero.isEnemy then
		-- if Ready(_R) then 
		-- if myHero.pos:DistanceTo(hero.pos) < 375 and hero:GetCollision(90, 1200, 0.10) - 1 > AIO.Ultimate.Min:Value() then
		-- Control.CastSpell(HK_R, hero)
	-- end
-- end
-- end
-- end
-- end

function LeeSin:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
	    if EnemyInRange(Q.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) and myHero.pos:DistanceTo(target.pos) > 250 then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end
    end
	
	function LeeSin:ComboQDelay()
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
		if EnemyInRange(200) and HasBuff(target, "BlindMonkQOne") then
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
	if Ready(_W) and myHero.health<=myHero.maxHealth * AIO.Combo.UseW:Value()/100 and EnemyInRange(500) and not target.dead and target.pos2D.onScreen then 
	Control.CastSpell(HK_W, myHero)
	end
end

function LeeSin:ComboQ2()
    local target = CurrentTarget(1300)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
	    if EnemyInRange(1300) and HasBuff(target, "BlindMonkQOne") then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
end
	
function LeeSin:ComboE()
	local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) and not target.dead and target.pos2D.onScreen then
	    if EnemyInRange(E.Range) then
			    Control.CastSpell(HK_E)
		    end
	    end
    end

function LeeSin:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQW:Value() and target and Ready(_Q) and Ready(_W) and not target.dead and target.pos2D.onScreen then
	    if EnemyInRange(Q.Range) then
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
    if AIO.Harass.UseQW:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
	    if EnemyInRange(1300) and HasBuff(target, "BlindMonkQOne") then
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

function LeeSin:Clear()
local qdelay = Game.Timer() - myHero:GetSpellData(_Q).castTime >= 1.7
for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if AIO.Clear.UseQ:Value() and Ready(_Q) then
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
    if AIO.Clear.UseW:Value() and Ready(_W) then
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
    if AIO.Clear.UseE:Value() and Ready(_E) then
		if not minion.isAlly and minion.pos:DistanceTo(myHero.pos) < E.Range and not minion.dead and minion.pos2D.onScreen and edelay then
		Control.CastSpell(HK_E)
end
end
end
end

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

function LeeSin:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = LeeSin:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

function LeeSin:KillstealE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and Ready(_E) and not target.dead and target.pos2D.onScreen then
		if EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = LeeSin:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_E) then
			    Control.CastSpell(HK_E,castpos)
				end
			end
		end
	end
end

function LeeSin:SpellonCCQ()
    local target = CurrentTarget(1000)
	if target == nil then return end
	if AIO.isCC.QCC["UseQ"..target.charName]:Value() and target and Ready(_Q) and not target.dead and target.pos2D.onScreen then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) and ImmobileEnemy then
			    CastSpell(HK_Q,castpos)
				end
			end
		end
	end

function LeeSin:RKS()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) and not target.dead and target.pos2D.onScreen then
		if EnemyInRange(R.Range) then 
		 	local Rdamage = LeeSin:RDMG()
			if Rdamage >= HpPred(target,0) + target.hpRegen * 1 then
			    CastSpell(HK_R,target)
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
	if AIO.Modes.Wardjump:Value() and Ready(_W) then
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
    -- if AIO.Modes.InAndOut:Value() and Ready(_Q) then
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
	
function LeeSin:Lasthit(range)
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
	local Qdamage = LeeSin:QDMG()
		if Ready(_Q) and not minion.dead and minion.pos2D.onScreen and myHero.pos:DistanceTo(minion.pos) > 250 then 
		if Qdamage >= HpPred(minion,1) + minion.hpRegen * 1 then
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
		if Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 425 and not minion.dead and minion.pos2D.onScreen and not Ready(_Q) then 
		if Edamage >= HpPred(minion,1) + minion.hpRegen * 1 then
			Control.CastSpell(HK_E)
    end
  end
end
end
end

class "Lux"


function Lux:LoadSpells()

	Q = {Range = 1150, Width = 80, Delay = 0.50, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 1075, Width = 150, Delay = 0.25, Speed = 1200, Collision = false, aoe = false, Type = "line"}
	E = {Range = 1100, Width = 0, Delay = 0.50, Speed = 1300, Collision = false, aoe = true, Type = "circular", radius = 350}
	R = {Range = 3340, Width = 190, Delay = 1.00, Speed = 3000, Collision = false, aoe = false, Type = "line"}

end

function Lux:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Lux", name = "Kypo's AIO: Lux", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id	="ShieldMinHealth",name="Min Health -> %",value=20,min=0,max=100})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "EHit", name = "E hits x minions", value = 4,min = 2, max = 6, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "UseR", name = "Semi R", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Killsteal:MenuElement({id = "RCC", name = "R on CC", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RCC:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end	
	AIO.Killsteal:MenuElement({id = "RR", name = "R KS Normal (Prediction)", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})
	
	AIO:MenuElement({id = "Junglesteal", name = "Junglesteal", type = MENU})
	AIO.Junglesteal:MenuElement({id = "jungleActive", name = "Use in jungle", key = string.byte("U")})
	AIO.Junglesteal:MenuElement({id = "Dragon", name = "Use AutoR on: Dragon", value = true})
	AIO.Junglesteal:MenuElement({id = "Baron", name = "Use AutoR on: Baron", value = true})
	AIO.Junglesteal:MenuElement({id = "Herald", name = "Use AutoR on: Herald", value = true})

	AIO:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	AIO.isCC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Will use Spell on:"})
	AIO.isCC:MenuElement({id = "blank", type = SPACE , name = "Stun, Snare, Knockup, Supression, Fear, Charm"})

	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--E
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})
    AIO.Drawings.R:MenuElement({id = "Minimap", name = "On minimap?", value = true})       	
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Lux:__init()
	
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

local JungleTable = {
	SRU_Baron = "",
	SRU_RiftHerald = "",
	SRU_Dragon_Water = "",
	SRU_Dragon_Fire = "",
	SRU_Dragon_Earth = "",
	SRU_Dragon_Air = "",
	SRU_Dragon_Elder = "",
}

function Lux:GetRDMGJng()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({900, 1100, 1400})[level] + 0.75 * myHero.ap)
	return rdamage
end
function Lux:GetRDMGBaron()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({900, 1100, 1900})[level] + 0.75 * myHero.ap)
	return rdamage
end

function Lux:Junglesteal()
	local rrange = 1200 + myHero.boundingRadius + 60
	for i, target in pairs(GetEnemyHeroes()) do
		if GetDistance(myHero.pos, target.pos) <= rrange then
			local RDamage = self:GetRDMGJng()
			local RDamageBaron = self:GetRDMGBaron()
			if AIO.Junglesteal.jungleActive["RU"..target.charName] and AIO.Junglesteal.jungleActive["RU"..target.charName]:Value() and RDamage > target.health then
				CastSpell(HK_Q, target.pos)
			end
		end
	end
	if AIO.Junglesteal.jungleActive:Value() then
		local RDamage = self:GetRDMGJng()
		local RDamageBaron = self:GetRDMGBaron()
		local minionlist = {}
		if _G.SDK then
			minionlist = _G.SDK.ObjectManager:GetMonsters(1200)
		elseif _G.GOS then
			for i = 1, Game.MinionCount() do
				local minion = Game.Minion(i)
				if minion.valid and minion.isEnemy and minion.pos:DistanceTo(myHero.pos) < 1200 then
					table.insert(minionlist, minion)
				end
			end
		end
		for i, minion in pairs(minionlist) do
			if AIO.Junglesteal.Dragon:Value() then
				if JungleTable[minion.charName] and RDamage > minion.health and Ready(_R) and Ready(_Q) then
						Control.SetCursorPos(minion.pos)
						Control.KeyDown(HK_Q)
						Control.KeyUp(HK_Q)					
						Control.CastSpell(HK_R, minion.pos)
					end
			end
			if AIO.Junglesteal.Herald:Value() then
				if minion.charName == "SRU_RiftHerald" and RDamage > minion.health and Ready(_R) and Ready(_Q) then
						Control.SetCursorPos(minion.pos)
						Control.KeyDown(HK_Q)
						Control.KeyUp(HK_Q)					
						Control.CastSpell(HK_R, minion.pos)				
						end
			end
			if AIO.Junglesteal.Baron:Value() then
				if minion.charName == "SRU_Baron" and RDamageBaron > minion.health and Ready(_R) and Ready(_Q) then
						Control.SetCursorPos(minion.pos)
						Control.KeyDown(HK_Q)
						Control.KeyUp(HK_Q)					
						Control.CastSpell(HK_R, minion.pos)
						end
			end
		end
	end
end

function Lux:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	if AIO.Junglesteal.jungleActive:Value() then
	self:Junglesteal()
	end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end
		self:KillstealQ()
		self:KillstealE()
		self:KillstealR()
		self:SpellonCCQ()
		self:RksCC()
		self:Autoshield()
end

function Lux:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 1175 , AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 1100, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 3340, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Minimap:Value() then Draw.CircleMinimap(myHero.pos, 3340, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local damage = QDamage + EDamage + RDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(3300)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 87, 51))
			end
		end
end

function Lux:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Lux:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 1150,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			CastSpell(HK_Q, castpos)
		    end
	    end
    end
 
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) and not HasBuff(myHero, "LuxLightstrikeToggle") then
			CastSpell(HK_E, castpos)
		    end
	    end
    end
end

function Lux:Harass()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 1150,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			CastSpell(HK_Q, castpos)
		    end
	    end
    end
 
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Harass.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range, E.Speed, myHero.pos, E.ignorecol, E.Type )
		    if (HitChance > 0 ) and not HasBuff(myHero, "LuxLightstrikeToggle") then
			CastSpell(HK_E, castpos)
		    end
	    end
    end
end

function Lux:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({50, 100, 150, 200, 250})[level] + 0.7 * myHero.ap)
	return qdamage
end

function Lux:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({50, 95, 140, 180, 225})[level] + 0.6 * myHero.ap)
	return edamage
end

function Lux:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({300, 400, 500})[level] + 0.75 * myHero.ap)
	return rdamage
end

function Lux:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) and target.pos2D.onScreen then
		if EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Lux:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_Q) then
			CastSpell(HK_Q, castpos)
			end
			end
		end
	end
end

function Lux:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) and target.pos2D.onScreen then
		if EnemyInRange(E.Range) then 
			local level = myHero:GetSpellData(_E).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, E.ignorecol, E.Type )
		   	local Edamage = Lux:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and Ready(_E) then
			CastSpell(HK_E, castpos)
			end
			end
		end
	end
end

function Lux:KillstealR()
    local target = CurrentTarget(3300)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) and target.pos2D.onScreen then
		if EnemyInRange(3300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	local Rdamage = Lux:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			CastSpell(HK_R, castpos)
				end
			end
		end
	end
end

function Lux:SpellonCCQ()
    local target = CurrentTarget(1150)
	if target == nil then return end
	if AIO.isCC.UseQ:Value() and target and Ready(_Q) and target.pos2D.onScreen then
		if EnemyInRange(1150) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			CastSpell(HK_Q, castpos)
			end
			end
		end
	end
end

function Lux:Autoshield()
    local target = CurrentTarget(1500)
	if target == nil then return end
	if AIO.Combo.UseW:Value() and Ready(_W) and myHero.health<=myHero.maxHealth * AIO.Combo.ShieldMinHealth:Value()/100 then
	if EnemyInRange(1500) then 
	Control.CastSpell(HK_W)
	end
	end
end

function Lux:RksCC()
    local target = CurrentTarget(3300)
	if target == nil then return end
	if AIO.Killsteal.RCC["UseR"..target.charName]:Value() and Ready(_R) and target.pos2D.onScreen then
		if EnemyInRange(3300) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = Lux:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and Ready(_R) then
			CastSpell(HK_R, castpos)
				end
			end
		end
	end
end
end

function Lux:Flee()
    local target = CurrentTarget(3300)
	if target == nil then return end
	if AIO.Flee.UseR:Value() and target and Ready(_R) and target.pos2D.onScreen then
		if EnemyInRange(3300) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) then
			CastSpell(HK_R, castpos)
				end
			end
		end
	end

function Lux:Clear()
	if Ready(_E) then
	local eMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,1000)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				eMinions[#eMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(1000, 350 + 40, eMinions)
		if BestHit >= AIO.Clear.EHit:Value() then
			CastSpell(HK_E,BestPos)
		end
	end
end
end

class "Nidalee"


function Nidalee:LoadSpells()

	Q = {Range = 1500, Width = 40, Delay = 0.45, Speed = 1600, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 0, Delay = 0.95, Speed = 1200, Collision = true, aoe = false, Type = "circular"}
	E = {Range = 600, Delay = 0.30, Speed = 900, Collision = false, aoe = false, Type = "line"}
	R = {Speed = 943, Collision = false, aoe = false, Type = "line"}
	Trap = {Range = 700, Delay = 0, Speed = 1200, Collision = false, aoe = false}

end

function Nidalee:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Nidalee", name = "Kypo's Nidalee", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseWH", name = "Cast W as Human?", value = false})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id	= "Eheal",name="Min Health to heal -> %",value=50,min=0,max=70})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "UseWH", name = "Cast W as Human?", value = false})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id	= "Eheal",name="Min Health to heal -> %",value=40,min=0,max=70})
	AIO.Clear:MenuElement({id = "WECount", name = "Use W/E on X minions (Lane Only)", value = 3, min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "{Q} Javelin Toss", key = string.byte("T")})

	AIO:MenuElement({id = "CC", name = "CC", type = MENU})
	AIO.CC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.CC:MenuElement({id = "UseW", name = "W Trap", value = true})
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Human", name = "Human", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Animal", name = "Animal", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Human", name = "Human", value = true})       
    AIO.Drawings.W:MenuElement({id = "Animal", name = "Animal", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 87, 51)})		
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
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

function Nidalee:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	
	if AIO.Combo.comboActive:Value() then
		self:DistQ()
		self:ComboQAnimal()
		self:ComboQHuman()
		self:ComboWAnimal()
		self:ComboEAnimal()
		self:AutoHealCombo()
		self:ChangeToR()
		self:ChangeToRHuman()
		
	end
	if AIO.Clear.clearActive:Value() then
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
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end		
	if AIO.Killsteal.UseQ:Value() then
		self:KillstealQ()
	end	
		self:CC()
		-- self:CCW()
end

function Nidalee:Draw()
if AIO.Drawings.Q.Human:Value() and myHero:GetSpellData(_Q).name == "JavelinToss" then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if AIO.Drawings.W.Human:Value() and myHero:GetSpellData(_Q).name == "JavelinToss" then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if AIO.Drawings.W.Animal:Value() and myHero:GetSpellData(_Q).name == "Takedown" then Draw.Circle(myHero.pos, 400, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end

if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local QDamage2 = (Ready(_Q) and getdmg("QM",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
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
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local damage2 = self:QDMG()
				if damage2 > hero.health then
					Draw.Text("Q KILLABLE", 35, hero.pos2D.x - 75, hero.pos2D.y - 190,Draw.Color(200, 255, 87, 51))	
				end
			end
		end	
	end
    if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local Qdamage = Nidalee:QDMG()
			
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end 
		end 
		if Ready(_W) then
			local target = CurrentTarget(W.Range)
			if target == nil then return end
			
			if (TPred) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 41, 41))
			end
		end
end

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

--Q
function Nidalee:ComboQHuman()
    local target = CurrentTarget(1500)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and self:isHuman() and target.pos2D.onScreen then
	    if EnemyInRange(Q.Range) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
			end
		end
	end
end

function Nidalee:ComboQAnimal()
	local target = CurrentTarget(450)
    if target == nil then return end  
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and self:isAnimal() and target.pos2D.onScreen then	
		if myHero.pos:DistanceTo(target.pos) < 450 then
		Control.CastSpell(HK_Q)
	end
end
end

function Nidalee:DistQ()
local target = CurrentTarget()
    if target == nil then return end
		if target.pos:DistanceTo(myHero.pos) > 400 and self:isAnimal() and Ready(_R) and not HasBuff(target, "NidaleePassiveHunted") and target.pos2D.onScreen then
			    Control.CastSpell(HK_R)
		else if target.pos:DistanceTo(myHero.pos) < 400 and self:isHuman() and Ready(_R) then
			    Control.CastSpell(HK_R)
	end
end
end

-- W
function Nidalee:ComboWAnimal()
local target = CurrentTarget(900)
    if target == nil then return end
	if target.pos2D.onScreen then
		if AIO.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 400 and not HasBuff(target, "NidaleePassiveHunted") and self:isAnimal() and Ready(_W) then
			    Control.CastSpell(HK_W, target)
		else if AIO.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 670 and HasBuff(target, "NidaleePassiveHunted") and self:isAnimal() and Ready(_W) then
			    Control.CastSpell(HK_W, target)
		else if AIO.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 670 and HasBuff(target, "NidaleePassiveHunted") and self:isHuman() and Ready(_R) then
			    Control.CastSpell(HK_R)
		else if AIO.Combo.UseW:Value() and target.pos:DistanceTo(myHero.pos) < 900 and self:isHuman() and Ready(_W) and not Ready(_Q) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and AIO.Combo.UseWH:Value() then
			    Control.CastSpell(HK_W, castpos)
		else if AIO.Combo.UseWH:Value() == false and HasBuff(target, "NidaleePassiveHunted") and self:isHuman() and Ready(_R) then
			Control.CastSpell(HK_R)
	end
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
		if myHero.health<=myHero.maxHealth * AIO.Combo.Eheal:Value()/100 and target.pos:DistanceTo(myHero.pos) < 900 and self:isHuman() and Ready(_E) then
			    Control.CastSpell(HK_E, myHero)		
		else if myHero.health<=myHero.maxHealth * AIO.Combo.Eheal:Value()/100 and target.pos:DistanceTo(myHero.pos) < 900 and self:isAnimal() and Ready(_R) then
			    Control.CastSpell(HK_R)
	end
end
end

function Nidalee:ChangeToR()
if self:isAnimal() and not Ready(_W) and not Ready(_Q) and not Ready(_E) and Ready(_R) then
		Control.CastSpell(HK_R)
	end
end

function Nidalee:ChangeToRHuman()
if self:isHuman() and not Ready(_W) and not Ready(_Q) and Ready(_R) then
		Control.CastSpell(HK_R)
	end
end

-- E
function Nidalee:ComboEAnimal()
local target = CurrentTarget(350)
    if target == nil then return end
		if AIO.Combo.UseE:Value() and target.pos:DistanceTo(myHero.pos) < 350 and self:isAnimal() and Ready(_E) then
			    Control.CastSpell(HK_E, target)
	end
end

function Nidalee:Clear()
	if Ready(_W) and self:isAnimal() then
	local wMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if ValidTarget(minion,350) then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				wMinions[#wMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(350, 300, wMinions)
		if BestHit >= AIO.Clear.WECount:Value() and AIO.Clear.UseW:Value() then
		Control.CastSpell(HK_W,BestPos)			
		else if Ready(_E) and self:isAnimal() then
		local BestPosE, BestHitE = GetBestCircularFarmPosition(200, 350, wMinions)
		if BestHitE >= AIO.Clear.WECount:Value() and AIO.Clear.UseE:Value() then
		Control.CastSpell(HK_E,BestPosE)
		end
	end
end
end
end

function Nidalee:ClearE()
	if AIO.Clear.UseE:Value() and self:isAnimal() and Ready(_E) then
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
	if AIO.Clear.UseQ:Value() and self:isHuman() and Ready(_Q) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 1500 then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		    if (HitChance > 1 ) and minion.pos2D.onScreen then
			Control.CastSpell(HK_Q,castpos)
			else if self:isAnimal() and Ready(_Q) and minion.pos:DistanceTo(myHero.pos) < 300 then
			Control.CastSpell(HK_Q, minion)
	end
end
end
end
end
end
end

function Nidalee:ClearQQminion()
	if AIO.Clear.UseQ:Value() and self:isAnimal() and Ready(_Q) then
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
if AIO.Clear.UseW:Value() then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 900 and self:isHuman() then
		   local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, 0.38, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and Ready(_W) and AIO.Clear.UseWH:Value() then
			Control.CastSpell(HK_W,castpos)
		else if AIO.Clear.UseWH:Value() == false and HasBuff(minion, "NidaleePassiveHunted") and self:isHuman() and Ready(_R) then
			Control.CastSpell(HK_R)
		else if HasBuff(minion, "NidaleePassiveHunted") and self:isHuman() and Ready(_R) then
			Control.CastSpell(HK_R)
		else if self:isAnimal() and HasBuff(minion, "NidaleePassiveHunted") and Ready(_W) and minion.pos:DistanceTo(myHero.pos) < 700 then
			Control.CastSpell(HK_W, minion)
		else if self:isAnimal() and not HasBuff(minion, "NidaleePassiveHunted") and Ready(_W) and minion.pos:DistanceTo(myHero.pos) < 400 then
			Control.CastSpell(HK_W, minion)
							end
						end
					end
				end
			end
		end
	end
end
end
end

function Nidalee:ClearWMinionJump()
if AIO.Clear.UseW:Value() then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.team == 300 then
			if minion.pos:DistanceTo(myHero.pos) < 700 then
		if HasBuff(minion, "NidaleePassiveHunted") and self:isAnimal() and Ready(_W) and minion.pos:DistanceTo(myHero.pos) < 700 then
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
		if myHero.health<=myHero.maxHealth * AIO.Clear.Eheal:Value()/100 and minion.pos:DistanceTo(myHero.pos) < 600 and self:isHuman() and Ready(_E) then
			    Control.CastSpell(HK_E, myHero)		
		else if myHero.health<=myHero.maxHealth * AIO.Clear.Eheal:Value()/100 and minion.pos:DistanceTo(myHero.pos) < 60 and self:isAnimal() and Ready(_R) then
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
		if minion.pos:DistanceTo(myHero.pos) > 400 and self:isAnimal() and Ready(_R) and not HasBuff(minion, "NidaleePassiveHunted") then
			    Control.CastSpell(HK_R)
		else if minion.pos:DistanceTo(myHero.pos) < 400 and self:isHuman() and Ready(_R) then
			    Control.CastSpell(HK_R)
	end
end
end
end
end



function Nidalee:Lasthit()
	if Ready(_Q) and AIO.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Nidalee:QDMG()
			local QdamageA = Nidalee:QdamageAnimal()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q.Delay, Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Lasthit.UseQ:Value() and minion.isEnemy and not minion.dead then
				if Qdamage >= HpPred(minion,1) and self:isHuman() and (HitChance > 0 ) then
			    CastSpell(HK_Q, castpos)
			else if minion.pos:DistanceTo(myHero.pos) < 300 and self:isAnimal() then
				if QdamageA >= HpPred(minion,1) then
			    CastSpell(HK_Q, minion)
				end
			end
		end
	end
end
end
end

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

function Nidalee:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Nidalee:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:isHuman() and target.pos:DistanceTo(myHero.pos) > 900 then
			    CastSpell(HK_Q,castpos)
			else if self:isAnimal()	and Ready(_R) then
			Control.CastSpell(HK_R)
				end
			end
		end
	end
end
end
	
function Nidalee:CC()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.CC.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy and self:isHuman() and (HitChance > 0 ) then
				Control.CastSpell(HK_Q, castpos)
			else if self:isAnimal() and ImmobileEnemy and Ready(_R) and target.pos:DistanceTo(myHero.pos) > 900 then
				Control.CastSpell(HK_R)
				end
			end
		end
	end
	end
	
function Nidalee:CCW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.CC.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay, W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if ImmobileEnemy and self:isHuman() and (HitChance > 0 ) then
				Control.CastSpell(HK_W, castpos)
			else if self:isAnimal() and ImmobileEnemy and Ready(_R) and EnemyInRange(W.Range) then
				Control.CastSpell(HK_R)
				end
			end
		end
	end
	end
	
class "Annie"


function Annie:LoadSpells()

	Q = {Range = 625, Delay = 0, Speed = 1400, Collision = false, aoe = false, Type = "line"}
	W = {Range = 600, Delay = 0.25, Speed = 0, Collision = false, aoe = false, Type = "line"}
	R = {Range = 600, Width = 150, Delay = 00, Speed = 1300, Collision = false, aoe = true, Type = "circular"}

end

function Annie:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Annie", name = "Kypo's AIO: Annie", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "SaveStun", name = "Save Stun Key", toggle = true, value = false, toggle, true, key = string.byte("Capslock")})
	AIO.Combo:MenuElement({id = "StunPreference", name = "Stun Preference", type = MENU})
	AIO.Combo.StunPreference:MenuElement({id = "blank", type = SPACE , name = "I think its better to only check one option."})
	AIO.Combo.StunPreference:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Combo.StunPreference:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo.StunPreference:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Combo.StunPreference:MenuElement({id = "UseStun", name = "Only R if has stun?", value = true})
	AIO.Combo.StunPreference:MenuElement({id = "Min", name = "Min enemies to Stun", value = 2, min = 1, max = 5})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})	
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "SaveQStun", name = "Save Stun?", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "SemiR", name = "R Key", type = MENU})
	AIO.SemiR:MenuElement({id = "UseR", name = "R", key = string.byte("T")})	
	
	AIO:MenuElement({id = "Misc", name = "Misc", type = MENU})
	AIO.Misc:MenuElement({id = "AutoStackStun", name = "Auto stack Stun", value = true})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})

	AIO.Killsteal:MenuElement({id = "RR", name = "R KS", value = true, type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	AIO.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})	

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function Annie:__init()
	
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

function Annie:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassW()
	end
	if AIO.Combo.comboActive:Value() then
		self:ComboQ()
		self:ComboW()
		self:UseRMin()
		self:UseWMin()
		
	end		
	if AIO.Lasthit.lasthitActive:Value() then
		self:LHQ()
	end	
		self:KillstealQ()
		self:KillstealW()
		self:KillstealR()
		self:SemiR()
		self:AutoStackStun()	
end

function Annie:Draw()
if AIO.Combo.SaveStun:Value() == true then
			local textPos = myHero.pos:To2D()
			Draw.Text("Save Stun ON", 20, textPos.x - 25, textPos.y + 40, Draw.Color(200, 229, 28, 21))
			end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() and Ready(_Q) then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() and Ready(_W) then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
end

function Annie:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Annie:ComboQ()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
		if self:HasStun() and AIO.Combo.SaveStun:Value() then return end
		if EnemyInRange(Q.Range) then
			CastSpell(HK_Q, target)
		    end
	    end
end

function Annie:ComboW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	if self:HasStun() and AIO.Combo.SaveStun:Value() then return end
	if EnemyInRange(W.Range) then
			CastSpell(HK_W, target)
	    end
end
end

function Annie:HarassQ()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			CastSpell(HK_Q, target)
		    end
	    end
end

function Annie:HarassW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(Q.Range) then
			CastSpell(HK_W, target)
		    end
	    end
end
	
function Annie:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({55, 92, 130, 170, 220})[level] + 0.8 * myHero.ap
	return qdamage
end

function Annie:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({70,115,160,205,250})[level] + 0.85 * myHero.ap)
	return wdamage
end

function Annie:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({150,275,400})[level] + 0.65 * myHero.ap)
	return rdamage
end

function Annie:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Annie:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_Q, target)
				end
			end
		end
	end
	
function Annie:AutoStackStun()
if Ready(_E) and AIO.Misc.AutoStackStun:Value() and not self:HasStun() then
	Control.CastSpell(HK_E)
				end
			end

function Annie:LHQ()
for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion.isEnemy and not minion.dead then
	if AIO.Lasthit.UseQ:Value() and Ready(_Q) then
		   	local Qdamage = Annie:QDMG()
			if Qdamage >= HpPred(minion,1) + minion.hpRegen * 1 and minion.pos:DistanceTo(myHero.pos) < 625 then
			    CastSpell(HK_Q, minion)
			elseif AIO.Lasthit.SaveQStun:Value() == false and self:HasStun() and Qdamage >= HpPred(minion,1) + minion.hpRegen * 1 and minion.pos:DistanceTo(myHero.pos) < 625 then
			    CastSpell(HK_Q, minion)
			elseif AIO.Lasthit.SaveQStun:Value() == true and self:HasStun() then return end
				end
				end
			end
		end
	
function Annie:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
		   	local Wdamage = Annie:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    CastSpell(HK_W, target)
				end
			end
		end
	end

function Annie:KillstealR()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.RR["UseR"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(Q.Range) then 
		   	local Rdamage = Annie:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if target then
			    CastSpell(HK_R, target)
				end
			end
		end
	end
end

function Annie:SemiR()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.SemiR.UseR:Value() and Ready(_R) and not HasBuff(myHero, "infernalguardianburning") then
		if EnemyInRange(R.Range) then 
			if target then
			    CastSpell(HK_R, target)
				end
			end
		end
	end

function Annie:EnemiesAround(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero and hero.isEnemy and not hero.dead and hero.pos:DistanceTo(pos, hero.pos) <= 290 then
            Count = Count + 1
        end
    end
    return Count
end

function Annie:EnemiesforW(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero and hero.isEnemy and not hero.dead and hero.pos:DistanceTo(pos, hero.pos) <= 600 then
            Count = Count + 1
        end
    end
    return Count
end

function Annie:UseRMin()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Combo.StunPreference.UseR:Value() and Ready(_R) and not HasBuff(myHero, "infernalguardianburning") then
		if EnemyInRange(R.Range) then 
			if target and self:EnemiesAround(target.pos, 290) >= AIO.Combo.StunPreference.Min:Value() and AIO.Combo.StunPreference.UseStun:Value() == true and self:HasStun() then
			    CastSpell(HK_R, target)
			elseif target and self:EnemiesAround(target.pos, 290) >= AIO.Combo.StunPreference.Min:Value() and AIO.Combo.StunPreference.UseStun:Value() == false and not self:HasStun() or self:HasStun() then
			    CastSpell(HK_R, target)
				end
			end
		end
	end
function Annie:UseWMin()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Combo.StunPreference.UseW:Value() and Ready(_W) and not HasBuff(myHero, "infernalguardianburning") then
		if EnemyInRange(W.Range) then 
			if target and self:EnemiesforW(myHero.pos, 625) >= AIO.Combo.StunPreference.Min:Value() and self:HasStun() then
			    CastSpell(HK_W, target)
				end
			end
		end
	end
	
function Annie:HasStun()
	if myHero.hudAmmo == myHero.hudMaxAmmo then
		return true
	end
	return false
end

class "Akali"


function Akali:LoadSpells()

	Q = {Range = 600, Width = 0, Delay = 0, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	W = {Range = 270, Width = 0, Delay = 0, Speed = 0, Collision = false, aoe = false, Type = "line"}
	E = {Range = 300, Width = 0, Delay = 0, Speed = 0, Collision = false, aoe = true, Type = "line"}
	R = {Range = 700, Width = 0, Delay = 0, Speed = 2200, Collision = false, aoe = false, Type = "line"}

end

function Akali:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Akali", name = "Kypo's AIO: Akali", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "UseRO", name = "R only if has Q?", value = true})
	AIO.Combo:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Combo:MenuElement({id = "KeepAmmo", name = "Ammo to keep:", value = 1, min = 0, max = 3, step = 1})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Clear:MenuElement({id = "ECount", name = "Use E on X minions", value = 3, min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Killsteal:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Killsteal:MenuElement({id = "UseQR", name = "Smart QR KS", value = true})
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q Range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W Range for walls", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})		
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E Range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R 
	AIO.Drawings:MenuElement({id = "R", name = "Draw R Range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Normal", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Akali:__init()
	
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

function Akali:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
		self:ComboR()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
		self:ClearQ()
		self:ClearEJng()
	end
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
		self:LasthitE()
	end					
		self:KillstealQ()
		self:KillstealE()
		self:KillstealR()
		self:KillstealRSmart()
	end


function Akali:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local Passive = (self:PassiveDMG())
				local damage = QDamage + RDamage + EDamage + Passive
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 50, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))				
					else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
end
end

function Akali:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
	return false	
end

function Akali:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) then
			Control.CastSpell(HK_Q, target)
		end
	end
end

function Akali:ComboE()
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(E.Range) then
			Control.CastSpell(HK_E)
		end
	end
end

function Akali:ComboR()
    local target = CurrentTarget(R.Range)
    if target == nil then return end
    if AIO.Combo.UseR:Value() and target and Ready(_R) then
	    if EnemyInRange(R.Range) and AIO.Combo.UseRO:Value() == true and HasBuff(target, "AkaliMota") and myHero:GetSpellData(3).ammo > AIO.Combo.KeepAmmo:Value() then
			Control.CastSpell(HK_R, target)	    
		elseif EnemyInRange(R.Range) and AIO.Combo.UseRO:Value() == false and not HasBuff(target, "AkaliMota") and myHero:GetSpellData(3).ammo > AIO.Combo.KeepAmmo:Value() then
			Control.CastSpell(HK_R, target)
		end
	end
end

function Akali:Clear()
	if Ready(_R) then
	local eMinions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  ValidTarget(minion,300)  then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy  then
				eMinions[#eMinions+1] = minion
			end	
	end	
		local BestPos, BestHit = GetBestCircularFarmPosition(300, 300, eMinions)
		if BestHit >= AIO.Clear.ECount:Value() and AIO.Clear.UseE:Value() then
		Control.CastSpell(HK_E)
		end
	end
end
end

function Akali:ClearQ()
	if Ready(_Q) and AIO.Clear.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and minion.isEnemy and not minion.dead then
			    Control.CastSpell(HK_Q,minion)
				end
			end
		end
	end
function Akali:ClearEJng()
	if Ready(_E) and AIO.Clear.UseE:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if myHero.pos:DistanceTo(minion.pos) < E.Range and minion.isEnemy and not minion.dead then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end

function Akali:Lasthit()
	if Ready(_Q) and AIO.Lasthit.UseQ:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Akali:QDMGLasthit()
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Lasthit.UseQ:Value() and minion.isEnemy or minion.team == 300 and not minion.dead then
				if Qdamage >= HpPred(minion,1) then
			    Control.CastSpell(HK_Q,minion)
				end
			end
		end
	end
end

function Akali:LasthitE()
	if Ready(_E) and AIO.Lasthit.UseE:Value() then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Edamage = Akali:EDMG()
			if myHero.pos:DistanceTo(minion.pos) < E.Range and AIO.Lasthit.UseE:Value() and minion.isEnemy or minion.team == 300 and not minion.dead then
				if Edamage >= HpPred(minion,1) then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end
end

function Akali:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({35, 55, 75, 95, 115})[level] + 0.4 * myHero.ap
    local qdamage2 = ({45, 70, 95, 120, 145})[level] + 0.5 * myHero.ap
	return qdamage + qdamage2
end

function Akali:QRDMG()
    local level = myHero:GetSpellData(_Q).level
	local levelr = myHero:GetSpellData(_R).level
    local qdamage = ({35, 55, 75, 95, 115})[level] + 0.4 * myHero.ap
    local qdamage2 = ({45, 70, 95, 120, 145})[level] + 0.5 * myHero.ap
	local rdamage = ({50, 100, 150})[levelr] + 0.35 * myHero.ap
	return qdamage + qdamage2 + rdamage
end

function Akali:QDMGLasthit()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({35, 55, 75, 95, 115})[level] + 0.4 * myHero.ap
	return qdamage
end

function Akali:EDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({70, 100, 130, 160, 190})[level] + 0.6 * myHero.ap + 0.8 * myHero.bonusDamage
	return qdamage
end

function Akali:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = ({50, 100, 150})[level] + 0.35 * myHero.ap
	return rdamage
end

function Akali:PassiveDMG()
    local level = myHero.levelData.lvl
    local pdamage = ({10,12,14,16,18,20,22,24,26,28,30,40,50,60,70,80,90,100})[level] + 0.50 * myHero.bonusDamage + 0.75 * myHero.ap
	return pdamage
end

function Akali:GunbladeDMG()
    local level = myHero.levelData.lvl
    local gbdamage = ({175,180,184,189,193,198,203,207,212,216,221,225,230,235,239,244,248,253})[level] + 0.30 * myHero.ap
	return gbdamage
end

function Akali:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Akali:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < Q.Range then
			    Control.CastSpell(HK_Q,target)
				end
			end
		end
	end
end

function Akali:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
		   	local Edamage = Akali:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < E.Range then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end
end

function Akali:KillstealR()
	local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseR:Value() and target and Ready(_R) then
		if EnemyInRange(R.Range) then 
		   	local Rdamage = Akali:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < 700 and Ready(_R) and myHero:GetSpellData(3).ammo > 0 then
			    Control.CastSpell(HK_R,target)
				end
			end
		end
	end
end

function Akali:KSGunblade()
	local target = CurrentTarget(700)
	if target == nil then return end
	if AIO.Killsteal.UseGB:Value() and target then
		local Gunblade = GetInventorySlotItem(3146)
		local dmg = Akali:GunbladeDMG()
		if Gunblade and EnemyInRange(700 ) and dmg >= HpPred(target,1) + target.hpRegen * 1 then
			Control.CastSpell(HKITEM[Gunblade], target)
			end
		end
	end

function Akali:KillstealRSmart()
	local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQR:Value() and target and Ready(_R) then
		if EnemyInRange(R.Range) then 
		   	local damage = Akali:QRDMG()
			if damage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < 700 and Ready(_R) and HasBuff(target, "AkaliMota") and myHero:GetSpellData(3).ammo > 0 then
			    Control.CastSpell(HK_R,target)
				end
			end
		end
	end
end
	
class "Caitlyn"


function Caitlyn:LoadSpells()

	Q = {Range = 1250, Width = 60, Delay = 0.90, Speed = 2200, Collision = false, aoe = false, Type = "line"}
	W = {Range = 800, Width = 0, Delay = 0.75, Speed = 1450, Collision = false, aoe = false, Type = "line"}
	E = {Range = 750, Width = 70, Delay = 0, Speed = 1600, Collision = false, aoe = true, Type = "line"}
	R = {Range = 2000, Width = 0, Delay = 0, Speed = 1500, Collision = false, aoe = false, Type = "line"}

end

function Caitlyn:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Caitlyn", name = "Kypo's AIO: Caitlyn", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W Key", key = string.byte("T")})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})	
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "QClear", name = "Use Q If Hit X Minion ", value = 4, min = 2, max = 6, step = 1})	
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseE", name = "E", value = true})
	
	AIO:MenuElement({id = "CC", name = "CC", type = MENU})
	AIO.CC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.CC:MenuElement({id = "UseW", name = "W", value = true})
	
	AIO:MenuElement({id = "Misc", name = "Misc", type = MENU})
	AIO.Misc:MenuElement({id = "gg", name = "Auto AA champion if killable with Headshot", value = true})
	AIO.Misc:MenuElement({id = "Wput", name = "Auto W if slowed with Net [E]", value = true})
	AIO.Misc:MenuElement({id = "AAonW", name = "Auto AA on trap [info]", value = true, tooltip = "Only if enemy is above your E range"})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q Range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E Range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R 
	AIO.Drawings:MenuElement({id = "R", name = "Draw R Range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Normal", value = true})       
    AIO.Drawings.R:MenuElement({id = "EnabledM", name = "Minimap", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Caitlyn:__init()
	
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

function Caitlyn:Tick()
       if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboE()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end		
	if AIO.Combo.UseW:Value() then
		self:WKey()
	end				
		self:KillstealQ()
		self:KillstealE()
		self:GG()
		self:WonE()
		self:AAonW()
		self:CCw()
		self:CCq()
	end

function Caitlyn:CCw()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.CC.UseW:Value() and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if target and ImmobileEnemy then
			CastSpell(HK_W, target)
				end
			end
		end
	end
	
function Caitlyn:CCq()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.CC.UseQ:Value() and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if target and ImmobileEnemy then
			CastSpell(HK_Q, target)
				end
			end
		end
	end
	
function Caitlyn:RDrawnormal()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif not Ready(_R) then goto continue
	::continue:: elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return Draw.Circle(myHero.pos, 2000, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return Draw.Circle(myHero.pos, 2500, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return Draw.Circle(myHero.pos, 3000, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value()) 
	end
end

function Caitlyn:RDrawmm()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif not Ready(_R) then goto continue
	::continue:: elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return Draw.CircleMinimap(myHero.pos, 2000, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return Draw.CircleMinimap(myHero.pos, 2500, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value())
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return Draw.CircleMinimap(myHero.pos, 3000, AIO.Drawings.R.Width:Value(),  AIO.Drawings.R.Color:Value()) 
	end
end


function Caitlyn:RRange()
	if myHero:GetSpellData(_R).level == 0 then
		return
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 1 then
		return 2000
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 2 then
		return 2500
	elseif Ready(_R) and myHero:GetSpellData(_R).level == 3 then
		return 3000
	end
end
function Caitlyn:GG()
	local target = CurrentTarget(650)
	if target == nil then return end
	if target then
	if AIO.Misc.gg:Value() then
	local passiveie = myHero.totalDamage + 1.70 * myHero.bonusDamage - target.armor
	local passive = myHero.totalDamage + 1.50 * myHero.bonusDamage - target.armor
		if EnemyInRange(650) then 
			if passiveie >= HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "caitlynheadshot") then
				Control.Attack(target)
			elseif passive >= HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "caitlynheadshot") then
				Control.Attack(target)
			if not HasBuff(myHero, "caitlynheadshot") then return end
				end
			end
		end
	end
	end
	
function Caitlyn:AAonW()
    local target = CurrentTarget(1250)
    if target == nil then return end
    if AIO.Misc.AAonW:Value() and target then
	    if EnemyInRange(1250) and HasBuff(target, "caitlynyordletrapinternal") and GetDistance(myHero.pos,target.pos) > E.Range then
			Control.Attack(target)
		end
	end
end

function Caitlyn:Draw()
 if myHero.dead then return end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then self:RDrawnormal() end
if Ready(_R) and AIO.Drawings.R.EnabledM:Value() then self:RDrawmm() end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0)
				local damage = QDamage + RDamage + EDamage + AA
				local passive = myHero.totalDamage + 1.50 * myHero.bonusDamage - hero.armor
				local passiveie = myHero.totalDamage + 1.70 * myHero.bonusDamage - hero.armor
				local RR = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				if RR > hero.health then
				Draw.Text("R KILLABLE", 25, hero.pos2D.x - 64, hero.pos2D.y - 210,Draw.Color(200, 255, 87, 51))
				if passive > hero.health and HasBuff(myHero, "caitlynheadshot") then
				Draw.Text("HS KILLABLE", 25, hero.pos2D.x - 67, hero.pos2D.y - 180,Draw.Color(200, 255, 87, 51))
				if passiveie > hero.health and HasBuff(myHero, "caitlynheadshot") then
				Draw.Text("HS KILLABLE", 25, hero.pos2D.x - 67, hero.pos2D.y - 180,Draw.Color(200, 255, 87, 51))
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
end
end
end
end


function Caitlyn:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and not buff.name == "caitlynyordletrapinternal" and buff.count > 0 then
				return true
			end
		end
	return false	
end

function Caitlyn:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
	    if EnemyInRange(Q.Range) and (HitChance > 1 ) then
			CastSpell(HK_Q, castpos)
		end
	end
end

function Caitlyn:WKey()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) and (HitChance > 0 ) then
			CastSpell(HK_W, castpos)
		end
	end
end

function Caitlyn:WonE()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
    if AIO.Misc.Wput:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) and (HitChance > 0 ) and HasBuff(target, "CaitlynEntrapmentMissile") then
			CastSpell(HK_W, castpos)
		end
	end
end

function Caitlyn:ComboE()
    local target = CurrentTarget(500)
    if target == nil then return end
	local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
    if AIO.Combo.UseE:Value() and target and Ready(_E) then
	    if EnemyInRange(500) and (HitChance > 0 ) and GetDistance(myHero.pos,target.pos) < 500 then
			Control.CastSpell(HK_E, castpos)
		end
	end
end

function Caitlyn:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion and minion:GetCollision(60, 1250, 0.25) - 1 >= AIO.Clear.QClear:Value() then
					Control.CastSpell(HK_Q, minion)
    end
  end
end
end
end

function Caitlyn:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({30, 70, 110, 150, 190})[level] + ({1.3, 1.4, 1.5, 1.6, 1.7})[level] * myHero.totalDamage 
	return qdamage
end

function Caitlyn:EDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({70, 110, 150, 190, 230})[level] + 0.8 * myHero.ap
	return qdamage
end

function Caitlyn:KillstealE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseE:Value() and target and Ready(_E) then
		local castpos,HitChance, pos = TPred:GetBestCastPosition(target, E.Delay , E.Width, E.Range,E.Speed, myHero.pos, not E.ignorecol, E.Type )
		if EnemyInRange(E.Range) then 
		   	local Edamage = Caitlyn:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < E.Range and (HitChance > 0 ) then
			    Control.CastSpell(HK_E, castpos)
				end
			end
		end
	end
end

function Caitlyn:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and target and Ready(_Q) then
		local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Caitlyn:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < Q.Range and (HitChance > 0 ) then
			    Control.CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

class "Azir"



function Azir:LoadSpells()

	Q = {Range = 740, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = false, Type = "line"}
	W = {Range = 570, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 1100, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = true, Type = "line"}
	R = {Range = 250, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = false, Type = "line"}

end

function Azir:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Azir", name = "Kypo's AIO: Azir", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	-- AIO.Combo:MenuElement({id = "ESet", name = "E Settings", type = MENU})
	-- AIO.Combo.ESet:MenuElement({id = "EE", name = "Blah1", value = true})
	-- AIO.Combo.ESet:MenuElement({id = "EEE", name = "Blah2", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	-- AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	-- AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	-- AIO.Clear:MenuElement({id = "QCount", name = "Use Q on X minions", value = 3, min = 1, max = 5, step = 1})
	-- AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "WE", name = "E to Soldier [READ]", key = string.byte("T"), tooltip = "If has no soldier on your mouse pos, it will cast one"})	
	AIO.Flee:MenuElement({id = "FlashInsec", name = "Flash Insec", key = string.byte("S")})
	AIO.Flee:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Flee:MenuElement({id = "KickPos", name = "Kick Position", key = string.byte("6")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseR", name = "R", value = true})	
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q Range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W Range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Soldier", name = "Draw Soldier?", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})		
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E Range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R 
	AIO.Drawings:MenuElement({id = "R", name = "Draw R Range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Normal", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Azir:__init()
	local flashslot
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

function Azir:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:ComboW()
	end
	-- if AIO.Clear.clearActive:Value() then
		-- self:Clear()
		-- self:ClearQ()
		-- self:ClearEJng()
	-- end
	-- if AIO.Lasthit.lasthitActive:Value() then
		-- self:Lasthit()
		-- self:LasthitE()
	-- end
	if AIO.Flee.KickPos:Value() then
		Position=mousePos
	end	
	if AIO.Flee.FlashInsec:Value() then
		self:FK(Position)
	end	
		self:KillstealQ()
		-- self:KillstealE()
		self:KillstealR()
		self:WQ()
		self:WQE()
		SoldierPos()
		flashslot = self:getFlash()

	end

function Azir:getFlash()
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

Soldier = {}	

function SoldierPos()
		for i = 0, Game.ParticleCount() do
			local particle = Game.Particle(i)
			local particlePos = particle.pos
			if particle and not particle.dead and particle.name:find("Azir_base_W_Sandbib.troy") then
			Soldier[particle.networkID] = particle
			end
		end	
end

function Azir:Draw()
Draw.Circle(Position,150,Draw.Color(170,255, 255, 255))
-- for i, soldier in pairs(Soldier) do
 -- Draw.Circle(soldier,280,Draw.Color(170,255, 255, 255)) end
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero)) * 3
				local damage = QDamage + RDamage + EDamage + AA
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 50, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
end
end

function Azir:ultimapos(targetx,from)
	local from=from or Vector(myHero.pos)
	local targetx=targetx or target
	return self:Normalized2(Vector(targetx.pos),from:DistanceTo(Vector(targetx.pos))+700,from)
end

function Azir:Normalized2(q,x,i)
	local x=x or 1
	local qx=(q-i)
	qx=Vector(0,0,0)+qx
	qx=qx:Normalized()
	qx=qx*x
	qx=i+qx
	return qx
end

function Azir:FK(poz)
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if target and Ready(_R) then
			local posicao1=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))+180,poz)
			local posicao2=self:Normalized2(Vector(target.pos),poz:DistanceTo(Vector(target.pos))-700,poz)
			if Vector(myHero.pos):DistanceTo(posicao1)<=500 and Vector(myHero.pos):DistanceTo(Vector(target.pos))<= 375 then
				if Azir:ultimapos(target):DistanceTo(posicao2)<=350 and Ready(flashslot) then
					Control.CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,posicao1)
					DelayAction(function()Control.CastSpell(HK_R, target)end,0.1)
				elseif Ready(flashslot) and not MapPosition:inWall(posicao1) then
					Control.CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,posicao1)
					DelayAction(function()Control.CastSpell(HK_R, target)end,0.1)
					end
			elseif Ready(flashslot) and GetDistance(myHero.pos, target.pos) < E.Range and GetDistance(myHero.pos, target.pos) > W.Range and Ready(_W) then
			local pos = target:GetPrediction(W.Speed,0.943)
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(W.Range)
			Control.CastSpell(HK_W, pos)
			elseif Ready(_Q) and GetDistance(myHero.pos, target.pos) < E.Range - 100 then
			Control.CastSpell(HK_Q,target)
			elseif Ready(_E) and GetDistance(target.pos, target.pos) < 1000 then
			Control.CastSpell(HK_E,target)
			elseif not Ready(flashslot) and GetDistance(myHero.pos, posicao1.pos) < 100 then
			Control.CastSpell(HK_R,target)
			end
		end
	end

function Azir:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
	return false	
end

function Azir:Combo()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end
	for i, soldier in pairs(Soldier) do
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and soldier and GetDistance(target.pos, soldier.pos) < Q.Range then
			Control.CastSpell(HK_Q, target)
		end
	end
	end

function Azir:WQ()
    if AIO.Flee.WE:Value() and Ready(_W) and Ready(_E) then
			Control.CastSpell(HK_W, mousePos)
			end
end

function Azir:WQE()
    if AIO.Flee.WE:Value() and Ready(_E) then
	for i, soldier in pairs(Soldier) do
	if soldier and GetDistance(soldier.pos, mousePos) < 350 then
			Control.CastSpell(HK_E, mousePos)
			end
end
end
end

function Azir:ComboW()
    local target = CurrentTarget(E.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) and myHero:GetSpellData(1).ammo > 0 then
	local pos = target:GetPrediction(W.Speed,0.943)
	pos = myHero.pos + (pos - myHero.pos):Normalized()*(E.Range - 500)
			Control.CastSpell(HK_W, pos)
		end
	end

	-- if isReady(0) and isReady(2) and SyndraMenu.Combo.UseQE:Value() then
		-- local target = GetTarget(QE.Range)
		-- if target then
			-- local pos = target:GetPrediction(QE.Speed,0.943)
			-- pos = myHero.pos + (pos - myHero.pos):Normalized()*(Q.Range - 65)
			-- Control.SetCursorPos(pos) 
			-- Control.KeyDown(HK_Q)
			-- DelayAction(function() Control.KeyDown(HK_E) Control.KeyUp(HK_Q) Control.KeyUp(HK_E) end, 0.25)



function Azir:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({70,95,120,145,170})[level] + 0.3 * myHero.ap
	return qdamage
end

function Azir:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = ({150, 250, 450})[level] + 0.60 * myHero.ap
	return rdamage
end

function Azir:KillstealQ()
for i, soldier in pairs(Soldier) do
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and soldier and Ready(_Q) then
	if not soldier then return end
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Azir:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(soldier.pos) < E.Range then
			    Control.CastSpell(HK_Q,target)
				end
			end
		end
	end
end
end

function Azir:KillstealR()
	local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseR:Value() and target and Ready(_R) then
		if EnemyInRange(R.Range) then 
		   	local Rdamage = Azir:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_R,target)
				end
			end
		end
	end


function Azir:KillstealRSmart()
	local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQR:Value() and target and Ready(_R) then
		if EnemyInRange(R.Range) then 
		   	local damage = Azir:QRDMG()
			if damage >= HpPred(target,1) + target.hpRegen * 1 then
			if target.pos:DistanceTo(myHero.pos) < 700 and Ready(_R) and HasBuff(target, "AzirMota") and myHero:GetSpellData(3).ammo > 0 then
			    Control.CastSpell(HK_R,target)
				end
			end
		end
	end
end

class "Riven"

local Q3Icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Steel_Tempest_3.png"

function Riven:LoadSpells()

	Q = {Range = 780, Width = 0, Delay = 0,30, Speed = 0, Collision = false, aoe = false, Type = "line"}
	W = {Range = 270, Width = 0, Delay = 0.25, Speed = 1500, Collision = false, aoe = false, Type = "circular"}
	E = {Range = 325, Width = 0, Delay = 0.25, Speed = 1450, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1150, Width = 0, Delay = 0.20, Speed = 1200, Collision = false, aoe = false, Type = "line"}

end

function Riven:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Riven", name = "Kypos AIO: Riven", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = false})
	AIO.Combo:MenuElement({id = "UseR", name = "R", value = false})
	AIO.Combo:MenuElement({id = "UseRHealth", name = "Use R if enemy health is below %",value=60,min=0,max=100})
	AIO.Combo:MenuElement({id = "ApproachTypes", name = "Approach Logic", value = 1,drop = {"W>Q>AA..", "E>W>Q>AA..","E>1Q>W>Q>.."}})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	AIO:MenuElement({id = "Burst", name = "Burst Combos", type = MENU})
	AIO.Burst:MenuElement({id = "BurstTypeKey1", name = "Burst Logic", value = 1,drop = {"R>E>Q3>W>AA", "X","X","X"}})
	AIO.Burst:MenuElement({id = "burstkey1", name = "Burst key 1", key = string.byte("T")})
	AIO.Burst:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Burst:MenuElement({id = "BurstTypeKey2", name = "Burst Logic", value = 1,drop = {"R>E>Q3>W>AA", "X","X","X"}})
	AIO.Burst:MenuElement({id = "burstkey2", name = "Burst key 2", key = string.byte("S")})
	AIO.Burst:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Burst:MenuElement({id = "BurstTypeKey3", name = "Burst Logic", value = 1,drop = {"R>E>Q3>W>AA", "X","X","X"}})
	AIO.Burst:MenuElement({id = "burstkey3", name = "Burst key 3", key = string.byte("Y")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "RR", name = "Enemies to KS:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "UseR", name = "R2", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	
    AIO:MenuElement({type = MENU, name = "Auto Features",  id = "AutoEvent"})
    AIO.AutoEvent:MenuElement({type = MENU, name = "Auto E",  id = "AutoE"})
        		AIO.AutoEvent.AutoE:MenuElement({id = "Enable", name = "Enabled", value = true})
        		AIO.AutoEvent.AutoE:MenuElement({type = MENU, id = "DetectedSpells", name = "Spells"})
        			AIO.AutoEvent.AutoE.DetectedSpells:MenuElement({id = "info", name = "Detecting Spells, Please Wait...", drop = {" "}})
        				do
        					local Delay = Game.Timer() > 10 and 0 or 10 - Game.Timer()
						local Added = false
						DelayAction(function()
        						for i, enemy in pairs(Riven:WGetEnemyHeroes()) do
        							if Riven.SpellData[enemy.charName] then
        								for i, v in pairs(Riven.SpellData[enemy.charName]) do
        									if enemy and v then
        										local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]
        										AIO.AutoEvent.AutoE.DetectedSpells:MenuElement({type = MENU, id = v.name, name = enemy.charName.." | "..SlotToStr.." | "..v.name, value = true})
        										AIO.AutoEvent.AutoE.DetectedSpells[v.name]:MenuElement({id = "Use", name = "Enabled", value = true})
        										Added = true
        									end
        								end
        							end
        						end
        					AIO.AutoEvent.AutoE.DetectedSpells.info:Remove()
        					if not Added then
        						AIO.AutoEvent.AutoE.DetectedSpells:MenuElement({id = "info", name = "No Spells Detected", drop = {" "}})
        					end
        					end, Delay)
        				end
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Riven:__init()
	
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

function Riven:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:ApproachTypes()
	end
	-- if AIO.Flee.fleeActive:Value() then
		-- self:Flee()
	-- end
	-- if AIO.Windwall.Enable:Value() then
		-- self:Windwall()
	-- end
		self:RksKnockedback()
		self:KillstealW()
		self:RKSNormal()
		self:test()
end

-- All credits to Shulepin from the Windwall.

function Riven:Windwall()
		for i = 1, Game.MissileCount() do
			local spell = nil
			local obj = Game.Missile(i)
			local data = obj.missileData
			local source = GetHeroByHandle(data.owner)
			if source then 
				if Riven.SpellData[source.charName] then
					spell = Riven.SpellData[source.charName][data.name:lower()]
				end
				if spell and not spell.isSkillshot and data.target == myHero.handle then
					if AIO.Windwall.DetectedSpells[spell.name].Use:Value() then
					Control.CastSpell(HK_E, obj.pos)
					return
					end
				end
				if spell and spell.isSkillshot and obj.isEnemy and data.speed and data.width and data.endPos and obj.pos then
					if AIO.Windwall.DetectedSpells[spell.name].Use:Value() then
						local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(obj.pos, data.endPos, myHero.pos)
						if isOnSegment and myHero.pos:DistanceTo(Vector(pointSegment.x, myHero.pos.y, pointSegment.y)) < data.width + myHero.boundingRadius then
						Control.CastSpell(HK_E, obj.pos)
						end
					end
				end
			end
		end
	end
	
	Riven.SpellData = {
		["Aatrox"] = {
			["aatroxeconemissile"] = {slot = 2, name = "Blade of Torment", isSkillshot = true}
		},
		["Ahri"] = {
			["ahriorbmissile"] = { slot = 0, name = "Orb of Deception", isSkillshot = true },
			["ahrifoxfiremissiletwo"] = {slot = 1, name = "Fox-Fire", isSkillshot = false},
			["ahriseducemissile"] = {slot = 2, name = "Charm", isSkillshot = true},
			["ahritumblemissile"] = {slot = 3, name = "SpiritRush", isSkillshot = false}
		},
		["Akali"] = {
			["akalimota"] = {slot = 0, name = "Mark of the Assasin", isSkillshot = false}
		},
		["Amumu"] = {
			["sadmummybandagetoss"] = {slot = 0, name = "Bandage Toss", isSkillshot = true}
		},
		["Anivia"] = {
			["flashfrostspell"] = {slot = 0, name = "Flash Frost", isSkillshot = true},
			["frostbite"] = {slot = 2, name = "Frostbite", isSkillshot = false}
		},
		["Annie"] = {
			["disintegrate"] = {slot = 0, name = "Disintegrate", isSkillshot = false}
		},
		["Ashe"] = {
			["volleyattack"] = {slot = 1, name = "Volley", isSkillshot = true},
			["enchantedcrystalarrow"] = {slot = 3, name = "Enchanted Crystal Arrow", isSkillshot = true}
		},
		["AurelionSol"] = {
			["aurelionsolqmissile"] = {slot = 0, name = "Starsurge", isSkillshot = true}
		},
		["Bard"] = {
			["bardqmissile"] = {slot = 0, name = "Cosmic Binding", isSkillshot = true}
		},
		["Blitzcrank"] = {
			["rocketgrabmissile"] = {slot = 0, name = "Rocket Grab", isSkillshot = true}
		},
		["Brand"] = {
			["brandqmissile"] = {slot = 0, name = "Sear", isSkillshot = true},
			["brandr"] = {slot = 3, name = "Pyroclasm", isSkillshot = false}
		},
		["Braum"] = {
			["braumqmissile"] = {slot = 0, name = "Winter's Bite", isSkillshot = true},
			["braumrmissile"] = {slot = 3, name = "Glacial Fissure", isSkillshot = true}
		},
		["Caitlyn"] = {
			["caitlynpiltoverpeacemaker"] = {slot = 0, name = "Piltover Peacemaker", isSkillshot = true},
			["caitlynaceintheholemissile"] = {slot = 3, name = "Ace in the Hole", isSkillshot = false}
		},
		["Cassiopeia"] = {
			["cassiopeiatwinfang"] = {slot = 2, name = "Twin Fang", isSkillshot = false}
		},
		["Nautilus"] = {
			["nautilusanchordragmissile"] = {slot = 0, name = "", isSkillshot = true}
		},
		["Nidalee"] = {
			["JavelinToss"] = {slot = 0, name = "Javelin Toss", isSkillshot = true}
		},
		["Nocturne"] = {
			["nocturneduskbringer"] = {slot = 0, name = "Duskbringer", isSkillshot = true}
		},
		["Pantheon"] = {
			["pantheonq"] = {slot = 0, name = "Spear Shot", isSkillshot = false}
		},
		["RekSai"] = {
			["reksaiqburrowedmis"] = {slot = 0, name = "Prey Seeker", isSkillshot = true}
		},
		["Rengar"] = {
			["rengarefinal"] = {slot = 2, name = "Bola Strike", isSkillshot = true}
		},
		["Riven"] = {
			["rivenlightsabermissile"] = {slot = 3, name = "Wind Slash", isSkillshot = true}
		},
		["Rumble"] = {
			["rumblegrenade"] = {slot = 2, name = "Electro Harpoon", isSkillshot = true}
		},
		["Ryze"] = {
			["ryzeq"] = {slot = 0, name = "Overload", isSkillshot = true},
			["ryzee"] = {slot = 2, name = "Spell Flux", isSkillshot = false}
		},
		["Sejuani"] = {
			["sejuaniglacialprison"] = {slot = 3, name = "Glacial Prison", isSkillshot = true}
		},
		["Sivir"] = {
			["sivirqmissile"] = {slot = 0, name = "Boomerang Blade", isSkillshot = true}
		},
		["Skarner"] = {
			["skarnerfracturemissile"] = {slot = 0, name = "Fracture ", isSkillshot = true}
		},
		["Shaco"] = {
			["twoshivpoison"] = {slot = 2, name = "Two-Shiv Poison", isSkillshot = false}
		},
		["Sona"] = {
			["sonaqmissile"] = {slot = 0, name = "Hymn of Valor", isSkillshot = false},
			["sonar"] = {slot = 3, name = "Crescendo ", isSkillshot = true}
		},
		["Swain"] = {
			["swaintorment"] = {slot = 2, name = "Torment", isSkillshot = false}
		},
		["Syndra"] = {
			["syndrarspell"] = {slot = 3, name = "Unleashed Power", isSkillshot = false}
		},
		["Teemo"] = {
			["blindingdart"] = {slot = 0, name = "Blinding Dart", isSkillshot = false}
		},
		["Tristana"] = {
			["detonatingshot"] = {slot = 2, name = "Explosive Charge", isSkillshot = false}
		},
		["Corki"] = {
			["phosphorusbombmissile"] = {slot = 0, name = "Phosphorus Bomb", isSkillshot = true},
			["missilebarragemissile"] = {slot = 3, name = "Missile Barrage", isSkillshot = true},
			["missilebarragemissile2"] = {slot = 3, name = "Big Missile Barrage", isSkillshot = true}
		},
		["Diana"] = {
			["dianaarcthrow"] = {slot = 0, name = "Crescent Strike", isSkillshot = true}
		},
		["DrMundo"] = {
			["infectedcleavermissile"] = {slot = 0, name = "Infected Cleaver", isSkillshot = true}
		},
		["Draven"] = {
			["dravenr"] = {slot = 3, name = "Whirling Death", isSkillshot = true}
		},
		["Ekko"] = {
			["ekkoqmis"] = {slot = 0, name = "Timewinder", isSkillshot = true}
		},
		["Elise"] = {
			["elisehumanq"] = {slot = 0, name = "Neurotoxin", isSkillshot = false},
			["elisehumane"] = {slot = 2, name = "Cocoon", isSkillshot = true}
		},
		["Ezreal"] = {
			["ezrealmysticshotmissile"] = {slot = 0, name = "Mystic Shot", isSkillshot = true},
			["ezrealessencefluxmissile"] = {slot = 1, name = "Essence Flux", isSkillshot = true},
			["ezrealarcaneshiftmissile"] = {slot = 2, name = "Arcane Shift", isSkillshot = false},
			["ezrealtrueshotbarrage"] = {slot = 3, name = "Trueshot Barrage", isSkillshot = true}
		},
		["FiddleSticks"] = {
			["fiddlesticksdarkwindmissile"] = {slot = 2, name = "Dark Wind", isSkillshot = false}
		},
		["Gangplank"] = {
			["parley"] = {slot = 0, name = "Parley", isSkillshot = false}
		},
		["Gnar"] = {
			["gnarqmissile"] = {slot = 0, name = "Boomerang Throw", isSkillshot = true},
			["gnarbigqmissile"] = {slot = 0, name = "Boulder Toss", isSkillshot = true}
		},
		["Gragas"] = {
			["gragasqmissile"] = {slot = 0, name = "Barrel Roll", isSkillshot = true},
			["gragasrboom"] = {slot = 3, name = "Explosive Cask", isSkillshot = true}
		},
		["Graves"] = {
			["gravesqlinemis"] = {slot = 0, name = "End of the Line", isSkillshot = true},
			["graveschargeshotshot"] = {slot = 3, name = "Collateral Damage", isSkillshot = true}
		},
		["Illaoi"] = {
			["illaoiemis"] = {slot = 2, name = "Test of Spirit", isSkillshot = true}
		},
		["Irelia"] = {
			["IreliaTranscendentBlades"] = {slot = 3, name = "Transcendent Blades", isSkillshot = true}
		},
		["Janna"] = {
			["howlinggalespell"] = {slot = 0, name = "Howling Gale", isSkillshot = true},
			["sowthewind"] = {slot = 1, name = "Zephyr", isSkillshot = false}
		},
		["Jayce"] = {
			["jayceshockblastmis"] = {slot = 0, name = "Shock Blast", isSkillshot = true},
			["jayceshockblastwallmis"] = {slot = 0, name = "Empowered Shock Blast", isSkillshot = true}
		},
		["Jinx"] = {
			["jinxwmissile"] = {slot = 1, name = "Zap!", isSkillshot = true},
			["jinxr"] = {slot = 3, name = "Super Mega Death Rocket!", isSkillshot = true}
		},
		["Jhin"] = {
			["jhinwmissile"] = {slot = 1, name = "Deadly Flourish", isSkillshot = true},
			["jhinrshotmis"] = {slot = 3, name = "Curtain Call's", isSkillshot = true}
		},
		["Kalista"] = {
			["kalistamysticshotmis"] = {slot = 0, name = "Pierce", isSkillshot = true}
		},
		["Karma"] = {
			["karmaqmissile"] = {slot = 0, name = "Inner Flame ", isSkillshot = true},
			["karmaqmissilemantra"] = {slot = 0, name = "Mantra: Inner Flame", isSkillshot = true}
		},
		["Kassadin"] = {
			["nulllance"] = {slot = 0, name = "Null Sphere", isSkillshot = false}
		},
		["Katarina"] = {
			["katarinaqmis"] = {slot = 0, name = "Bouncing Blade", isSkillshot = false}
		},
		["Kayle"] = {
			["judicatorreckoning"] = {slot = 0, name = "Reckoning", isSkillshot = false}
		},
		["Kennen"] = {
			["kennenshurikenhurlmissile1"] = {slot = 0, name = "Thundering Shuriken", isSkillshot = true}
		},
		["Khazix"] = {
			["khazixwmissile"] = {slot = 1, name = "Void Spike", isSkillshot = true}
		},
		["KogMaw"] = {
			["kogmawq"] = {slot = 0, name = "Caustic Spittle", isSkillshot = true},
			["kogmawvoidoozemissile"] = {slot = 3, name = "Void Ooze", isSkillshot = true},
		},
		["Leblanc"] = {
			["leblancchaosorbm"] = {slot = 0, name = "Shatter Orb", isSkillshot = false},
			["leblancsoulshackle"] = {slot = 2, name = "Ethereal Chains", isSkillshot = true},
			["leblancsoulshacklem"] = {slot = 2, name = "Ethereal Chains Clone", isSkillshot = true}
		},
		["LeeSin"] = {
			["blindmonkqone"] = {slot = 0, name = "Sonic Wave", isSkillshot = true}
		},
		["Leona"] = {
			["LeonaZenithBladeMissile"] = {slot = 2, name = "Zenith Blade", isSkillshot = true}
		},
		["Lissandra"] = {
			["lissandraqmissile"] = {slot = 0, name = "Ice Shard", isSkillshot = true},
			["lissandraemissile"] = {slot = 2, name = "Glacial Path ", isSkillshot = true}
		},
		["Lucian"] = {
			["lucianwmissile"] = {slot = 1, name = "Ardent Blaze", isSkillshot = true},
			["lucianrmissileoffhand"] = {slot = 3, name = "The Culling", isSkillshot = true}
		},
		["Lulu"] = {
			["luluqmissile"] = {slot = 0, name = "Glitterlance", isSkillshot = true}
		},
		["Lux"] = {
			["luxlightbindingmis"] = {slot = 0, name = "", isSkillshot = true}
		},
		["Malphite"] = {
			["seismicshard"] = {slot = 0, name = "Seismic Shard", isSkillshot = false}
		},
		["MissFortune"] = {
			["missfortunericochetshot"] = {slot = 0, name = "Double Up", isSkillshot = false}
		},
		["Morgana"] = {
			["darkbindingmissile"] = {slot = 0, name = "Dark Binding ", isSkillshot = true}
		},
		["Nami"] = {
			["namiwmissileenemy"] = {slot = 1, name = "Ebb and Flow", isSkillshot = false}
		},
		["Nunu"] = {
			["iceblast"] = {slot = 2, name = "Ice Blast", isSkillshot = false}
		},
		["TahmKench"] = {
			["tahmkenchqmissile"] = {slot = 0, name = "Tongue Lash", isSkillshot = true}
		},
		["Taliyah"] = {
			["taliyahqmis"] = {slot = 0, name = "Threaded Volley", isSkillshot = true}
		},
		["Talon"] = {
			["talonrakemissileone"] = {slot = 1, name = "Rake", isSkillshot = true}
		},
		["TwistedFate"] = {
			["bluecardpreattack"] = {slot = 1, name = "Blue Card", isSkillshot = false},
			["goldcardpreattack"] = {slot = 1, name = "Gold Card", isSkillshot = false},
			["redcardpreattack"] = {slot = 1, name = "Red Card", isSkillshot = false}
		},
		["Urgot"] = {
			--
		},
		["Varus"] = {
			["varusqmissile"] = {slot = 0, name = "Piercing Arrow", isSkillshot = true},
			["varusrmissile"] = {slot = 3, name = "Chain of Corruption", isSkillshot = true}
		},
		["Vayne"] = {
			["vaynecondemnmissile"] = {slot = 2, name = "Condemn", isSkillshot = false}
		},
		["Veigar"] = {
			["veigarbalefulstrikemis"] = {slot = 0, name = "Baleful Strike", isSkillshot = true},
			["veigarr"] = {slot = 3, name = "Primordial Burst", isSkillshot = false}
		},
		["Velkoz"] = {
			["velkozqmissile"] = {slot = 0, name = "Plasma Fission", isSkillshot = true},
			["velkozqmissilesplit"] = {slot = 0, name = "Plasma Fission Split", isSkillshot = true}
 		},
		["Viktor"] = {
			["viktorpowertransfer"] = {slot = 0, name = "Siphon Power", isSkillshot = false},
			["viktordeathraymissile"] = {slot = 2, name = "Death Ray", isSkillshot = true}
		},
		["Vladimir"] = {
			["vladimirtidesofbloodnuke"] = {slot = 2, name = "Tides of Blood", isSkillshot = false}
		},
		["Riven"] = {
			["yasuoq3w"] = {slot = 0, name = "Gathering Storm", isSkillshot = true}
		},
		["Zed"] = {
			["zedqmissile"] = {slot = 0, name = "Razor Shuriken ", isSkillshot = true}
		},
		["Zyra"] = {
			["zyrae"] = {slot = 2, name = "Grasping Roots", isSkillshot = true}
		}
	}


function Riven:WGetEnemyHeroes()
	local result = {}
  	for i = 1, Game.HeroCount() do
    		local unit = Game.Hero(i)
    		if unit.isEnemy then
    			result[#result + 1] = unit
  		end
  	end
  	return result
end

function Riven:dashpos(unit)
	return myHero.pos + (unit.pos - myHero.pos):Normalized() * 600
	end

function Riven:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end
			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0) - hero.armor
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0) - hero.armor
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0) - hero.armor
				local AA = Riven:AADMG() - hero.armor
				local damage = QDamage + WDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("KILLABLE", 28, hero.pos2D.x - 40, hero.pos2D.y - 215,Draw.Color(200, 41, 219, 32))	
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Riven:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
				return true
			end
		end
		return false	
	end

function Riven:IsKnockedUp(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 29 or buff.type == 30 or buff.type == 39) and buff.count > 0 then
				return true
			end
		end
		return false	
	end
	
function Riven:CountKnockedUpEnemies(range)
		local count = 0
		local rangeSqr = range * range
		for i = 1, Game.HeroCount()do
		local hero = Game.Hero(i)
			if hero.isEnemy and hero.alive and GetDistanceSqrYas(myHero.pos, hero.pos) <= rangeSqr then
			if Riven:IsKnockedUp(hero)then
			count = count + 1
    end
  end
end
return count
end


function Riven:Flee()
	if Ready(_E) then
			local minion = self:getminion()
			if minion then
				Control.CastSpell(HK_E,minion)
			end
		end
	end


-- function CastQ(target)
    -- local target = CurrentTarget(335)
    -- if target == nil then return end
	    -- if myHero.attackData.state == STATE_WINDDOWN and myHero.attackData.windDownTime >= 0.0000000000001 then
			    -- DisableOrb()
				-- Control.CastSpell(HK_Q,target)
				-- DelayAction(function() EnableOrb() end, 0.1)
		-- elseif myHero.attackData.windUpTime >= 0.0000000000010 then
				-- Control.Attack(target)
		-- end
	-- end


-- function CastQMinion(minion)
	-- for i = 1, Game.MinionCount() do
	-- local minion = Game.Minion(i)
	-- if minion and minion.team == 300 or minion.team ~= myHero.team then
	    		-- local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN
		-- local WINDUP = myHero.attackData.state == STATE_WINDUP
		-- local WINUPTIME = myHero.attackData.windUpTime
		-- local WINDOWNTIME = myHero.attackData.windDownTime
		-- local ANIMATIONTIME = myHero.attackData.animationTime
		
		-- local x = myHero.attackData.animationTime
		
	    -- if WINDDOWN and WINDOWNTIME >= 0.0000000000001 then
				-- DisableOrb()
				-- Control.CastSpell(HK_Q,minion)
		-- elseif ANIMATIONTIME >= WINUPTIME + 0.0000000000001 then
				-- Control.Move(minion.pos)
				-- print("moved")
		-- elseif ANIMATIONTIME >= WINDOWNTIME + 0.0000000000001 then
				-- Control.Attack(minion)
				-- DelayAction(function() EnableOrb() end, 0.45)
		-- end
	-- end
	-- end
	-- end
	
	-- function CastQMinion(minion)
	-- for i = 1, Game.MinionCount() do
	-- local minion = Game.Minion(i)
	-- if minion and minion.team == 300 or minion.team ~= myHero.team then
	    -- if myHero.attackData.state == STATE_WINDDOWN and myHero.attackData.windDownTime >= 0.0000000000001 then
			    -- DisableOrb()
				-- Control.CastSpell(HK_Q,minion)
				-- DelayAction(function() EnableOrb() end, 0.1)
		-- elseif myHero.attackData.windUpTime >= 0.0000000000010 then
		-- local Vec = Vector(myHero.pos):Normalized() * - (myHero.boundingRadius*1.1)
			    -- Control.Move(Vec)
				-- print("moved")
				-- Control.Attack(minion)
		-- end
	-- end
	-- end
	-- end

function Riven:test()
-- print("")

-- local q = false
-- local timer = 0
		-- if q == false and myHero:GetSpellData(Q).toggleState == 2 then
  -- timer = Game.Timer()
  -- q = true
-- end
		-- if q == true and myHero:GetSpellData(Q).toggleState == 1 then
  -- print(Game.Timer() - timer)
  -- q = false
-- end

-- print(myHero:GetSpellData(_Q).range)
-- print(myHero.attackData.endTime)
-- if myHero.attackData.state == STATE_WINDUP then
-- if myHero.attackData.windUpTime > 0.21577 then
-- Control.Move(mousePos)
-- print("finish aa")
end
-- end
-- end
-- end
-- end


function CastQ(target)
    local target = CurrentTarget(500)
    if target == nil then return end
																	-- AA > Q > Move > ..
		local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
		local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
		local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK
		local WINUPTIME = myHero.attackData.windUpTime				-- 
		local WINDOWNTIME = myHero.attackData.windDownTime			-- 
		local ANIMATIONTIME = myHero.attackData.animationTime		-- Animation time
		
	    if WINDDOWN and WINDOWNTIME > 0.0000000005000 then
				DisableOrb()
				Control.CastSpell(HK_Q,target)
		elseif WINDDOWN and WINDOWNTIME > 0.0000000009000 then
				DelayAction(function() 
				Control.Move(target.pos)
				-- Control.Attack(target)
				print("moved")
				end, 1.5)
	    -- if WINDDOWN and WINDOWNTIME >= 0.000030 then
				-- Control.Move(target.pos)
				-- print("moved")
		-- elseif ANIMATIONTIME >= WINDOWNTIME + 0.0000000000001 then
				DelayAction(function() EnableOrb() end, 0.3)

		end
		end

function Riven:ApproachTypes(target)
local mode = AIO.Combo.ApproachTypes:Value() 
	if mode == 1 then
		self:ApproachW()
		self:ApproachQ()
	elseif mode == 2 then
		self:Approach2E()
		self:Approach2W()
		self:ApproachQ()	
		elseif mode == 3 then
		self:Approach3E()
		self:Approach31Q()
		self:ApproachW()
		self:ApproachQ()
end
end

function Riven:ApproachQ()
    local target = CurrentTarget(335)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then		
	    if EnemyInRange(335) then
			CastQ()
		end    
	end
end
		
function Riven:ApproachW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			    Control.CastSpell(HK_W)
				end
			end
		end
function Riven:Approach2W()
    local target = CurrentTarget(270)
    if target == nil then return end
if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(270) then
			    Control.CastSpell(HK_W)
				end
			end
		end
		
function Riven:Approach2E()
    local target = CurrentTarget(E.Range+W.Range-50)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) and Ready(_W) then		
	    if EnemyInRange(E.Range+W.Range) then
			local pos = target:GetPrediction(E.Speed,0.25)
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(E.Range)
			Control.CastSpell(HK_E, pos)
		end    
	end
end

function Riven:Approach3E()
    local target = CurrentTarget(E.Range+W.Range+275)
    if target == nil then return end
    if AIO.Combo.UseE:Value() and target and Ready(_E) and Ready(_W) then		
	    if EnemyInRange(E.Range+W.Range) then
			local pos = target:GetPrediction(E.Speed,0.25)
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(E.Range)
			Control.CastSpell(HK_E, pos)
		end    
	end
end
function Riven:Approach31Q()
    local target = CurrentTarget(W.Range+275)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then		
	    if EnemyInRange(E.Range+W.Range) and GetDistance(myHero.pos, target.pos) > E.Range+W.Range+275 and myHero:GetSpellData(Q).ammo == 0 and not myHero:GetSpellData(Q).ammo == 1 and not myHero:GetSpellData(Q).ammo == 2 then
			local pos = target:GetPrediction(Q.Speed,0.25)
			pos = myHero.pos + (pos - myHero.pos):Normalized()*(Q.Range)
			Control.CastSpell(HK_Q, pos)
		end    
	end
end

	-- for i = 1, Game.MinionCount() do
	-- local minion = Game.Minion(i)
	-- if minion and minion.team == 300 or minion.name == "SRU_Razorbeak" or minion.name == "SRU_Red" or minion.name == "SRU_Blue" or minion.name == "SRU_Krug" or minion.name == "SRU_Gromp" or minion.name == "SRU_MurkWolf" or minion.name == "SRU_KrugMini" or minion.name == "SRU_Dragon_Fire" or minion.name == "SRU_Dragon_Air" or minion.name == "SRU_Dragon_Earth" or minion.name == "SRU_Dragon_Water" or minion.name == "SRU_Dragon_Elder" or minion.name == "SRU_Baron" or minion.name == "SRU_Herald" then
		-- if Ready(_Q) then 
			-- local castpos,HitChance, pos = TPred:GetBestCastPosition(minion, Q3.Delay , Q3.Width, Q3.Range ,Q3.Speed, myHero.pos, Q3.ignorecol, Q3.Type )
			-- if AIO.Clear.UseQ:Value() and minion then
				-- if ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 then
					-- if (HitChance > 0 ) and HasBuff(myHero, "RivenQ3W") then
					-- Control.CastSpell(HK_Q, castpos)
					-- end
				-- end
			-- end
		-- end
	-- end
	-- end
	-- end

-- SRU_Razorbeak
-- SRU_Red
-- SRU_Krug
-- SRU_Gromp
-- SRU_Blue
-- SRU_MurkWolf
-- SRU_KrugMini
-- SRU_MiniKrugB
-- Sru_Crab
-- SRU_Dragon_Fire
-- SRU_Dragon_Air
-- SRU_Dragon_Earth
-- SRU_Dragon_Water
-- SRU_Dragon_Elder

function Riven:AADMG()
    local aadamage = myHero.totalDamage * 4
	return aadamage
end

function Riven:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({15, 35, 55, 75, 95})[level] + myHero.totalDamage / 100 * ({45, 50, 55, 60, 65})[level]
	return qdamage
end

function Riven:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = ({55, 85, 115, 145, 175})[level] + 1.0 * myHero.bonusDamage
	return wdamage
end

function Riven:RDMG()
for i = 1, Game.HeroCount() do
	local target = Game.Hero(i);
	if target and target.isEnemy then
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 150, 200})[level] + 0.6 * myHero.bonusDamage) * math.max(0.04 * math.min(100 - GetPercentHP(target), 75), 1) - target.armor
	return rdamage
end
end
end

function Riven:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
		   	local Wdamage = Riven:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_W)
				end
			end
		end
	end

function Riven:RksKnockedback()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseR:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(R.Range) then 
			local ImmobileEnemy = self:IsKnockedUp(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Riven:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if ImmobileEnemy then
			if (HitChance > 0 ) and HasBuff(myHero, "rivenknockback") and HasBuff(myHero, "rivenwindslashready") then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

function Riven:RKSNormal()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Killsteal.UseR:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(R.Range) then 
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Riven:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and HasBuff(myHero, "rivenwindslashready") then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

class "Alistar"



function Alistar:LoadSpells()

	Q = {Range = 365, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = false, Type = "circular"}
	W = {Range = 650, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 320, Width = 0, Delay = 0, Speed = 500, Collision = false, aoe = true, Type = "circular"}

end

function Alistar:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Alistar", name = "Kypo's AIO: Alistar", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = false})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Flee", name = "Flee", type = MENU})
	AIO.Flee:MenuElement({id = "FQ", name = "Flash Q", key = string.byte("T")})	
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "RR", name = "Enemies to KS:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})	
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q Range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W Range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})		
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E Range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})
		
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Alistar:__init()
	local flashslot
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

function Alistar:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:ComboW()
		self:ComboQ()
		self:ComboE()
	end
	if AIO.Harass.harassActive:Value() then
		self:HarassW()
		self:HarassQ()
	end
	if AIO.Flee.FQ:Value() then
		self:FQ()
		self:FQQ()
	end	
		self:KillstealQ()
		self:KillstealW()
		flashslot = self:getFlash()
	end

function Alistar:getFlash()
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


function Alistar:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end

		if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 50, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
				end
				end
end
end


function Alistar:FQ()
    local target = CurrentTarget(Q.Range+400)
	if target == nil then return end
	if target and Ready(_Q) and Ready(flashslot) then
			Control.CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,target)
			end
		end
		
function Alistar:FQQ()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end	
	if EnemyInRange(Q.Range) and Ready(_Q) then
			Control.CastSpell(HK_Q)
end			
end	

function Alistar:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 29) and buff.count > 0 then
				return true
			end
		end
	return false	
end

function Alistar:ComboW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_Q) and Ready(_W) and GetDistance(myHero.pos, target.pos) > W.Range - Q.Range + 100 then
			Control.CastSpell(HK_W, target)
	end
	end
	
function Alistar:ComboQ()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end	
	if AIO.Combo.UseQ:Value() and EnemyInRange(Q.Range) and Ready(_Q) then
			Control.CastSpell(HK_Q)
end			
end	

function Alistar:ComboE()
    local target = CurrentTarget(E.Range)
    if target == nil then return end		
	if AIO.Combo.UseE:Value() and EnemyInRange(E.Range) and Ready(_E) then
			Control.CastSpell(HK_E)
end
end
	
function Alistar:HarassW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
			Control.CastSpell(HK_W, target)
		end
	end	
	
function Alistar:HarassQ()
    local target = CurrentTarget(Q.Range)
    if target == nil then return end			
	if AIO.Harass.UseQ:Value() and EnemyInRange(Q.Range) and Ready(_Q) then
			Control.CastSpell(HK_Q)
		end
	end

function Alistar:QDMG()
    local target = CurrentTarget()
    if target == nil then return end
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({60 , 105 , 150 , 195 , 240})[level] + 0.5 * myHero.ap - target.magicResist
	return qdamage
end

function Alistar:WDMG()
    local target = CurrentTarget()
    if target == nil then return end
    local level = myHero:GetSpellData(_W).level
    local wdamage = ({55 , 110 , 165 , 220 , 275})[level] + 0.70 * myHero.ap - target.magicResist
	return wdamage
end

function Alistar:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Alistar:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_Q,target)
				end
			end
		end
	end

function Alistar:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and target and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_W) then
		if EnemyInRange(W.Range) then 
		   	local Wdamage = Alistar:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			    Control.CastSpell(HK_W,target)
				end
			end
		end
	end

class "Ashe"


function Ashe:LoadSpells()

	Q = {Range = 600}
	W = {Range = 1200, Width = 0, Delay = 0.25, Speed = 902, Collision = true, aoe = false, Type = "line"}
	R = {Range = 5000, Width = 130, Delay = 0.60, Speed = 1600, Collision = true, aoe = false, Type = "line"}

end


function Ashe:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Ashe", name = "Kypo's AIO: Ashe", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Flee", name = "R key", type = MENU})
	AIO.Flee:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Flee:MenuElement({id = "fleeActive", name = "R key (MM Range)", key = string.byte("T")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "RR", name = "Enemies to KS:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Killsteal:MenuElement({id = "UseRCC", name = "R on CC", value = true})
	AIO.Killsteal:MenuElement({id = "RNormal", name = "R KS Normal (Prediction)", value = true})

	AIO:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	AIO.CC:MenuElement({id = "RR", name = "Enemies to Use:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.CC.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	
	AIO.CC:MenuElement({id = "UseW", name = "W", value = true})
	AIO.CC:MenuElement({id = "UseR", name = "R", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Ashe:__init()
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


function Ashe:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassW()
	end
	if AIO.Combo.comboActive:Value() then
		self:ComboQ()
		self:ComboW()
	end
	if AIO.Flee.fleeActive:Value() then
		self:Flee()
	end
		self:KillstealW()
		self:KillstealR()
		
		self:SpellonCCW()
		self:SpellonCCR()
		
		self:RksCC()
end

function Ashe:Draw()
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, 1450, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then 
Draw.Circle(myHero.pos, 5000, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value())
Draw.CircleMinimap(myHero.pos, 5000, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0) * 6
				local damage = RDamage + WDamage + AA
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(5000)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 5000, R.Speed, myHero.pos, not R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Ashe:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = ({20, 35, 50, 65, 80})[level] + 1.0 * myHero.totalDamage
	return wdamage
end

function Ashe:RDMG()
    local level = myHero:GetSpellData(_R).level
	local rdamage = ({200, 400, 600})[level] + 1.0 * myHero.ap
	return rdamage
end

function Ashe:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Ashe:ComboW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Ashe:ComboQ()	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) and HasBuff(myHero, "asheqcastready") then
			Control.CastSpell(HK_Q)
		    end
	    end

function Ashe:HarassW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Ashe:HarassQ()	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) and HasBuff(myHero, "asheqcastready") then
			Control.CastSpell(HK_Q)
		    end
	    end

function Ashe:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, not W.ignorecol, W.Type )
		   	local Wdamage = Ashe:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Ashe:KillstealR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.RNormal:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	local Rdamage = Ashe:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Ashe:Flee()
    local target = CurrentTarget(5000)
	if target == nil then return end
	if AIO.Flee.UseR:Value() and Ready(_R) then
		if EnemyInRange(5000) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 5000, R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Ashe:SpellonCCW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.CC.UseW:Value() and AIO.CC.RR["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, not W.ignorecol, W.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Ashe:SpellonCCR()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.CC.UseR:Value() and AIO.CC.RR["KS"..target.charName]:Value() and target and Ready(_R) then
		if EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end

function Ashe:RksCC()
    local target = CurrentTarget(2000)
	if target == nil then return end
	if AIO.Killsteal.UseRCC:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and Ready(_R) then
		if EnemyInRange(2000) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, not R.ignorecol, R.Type )
		   	if ImmobileEnemy then
			local Rdamage = Ashe:RDMG()
			if Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
			    CastSpell(HK_R,castpos)
				end
			end
		end
	end
end
end

class "Jhin"


function Jhin:LoadSpells()

	Q = {Range = 600}
	W = {Range = 2500, Width = 40, Delay = 0.45, Speed = 3200, Collision = false, aoe = false, Type = "line"}
	E = {Range = 750, Width = 120, Delay = 0.25, Speed = 1000, Collision = false, aoe = false, Type = "line"}
	R = {Range = 3500, Width = 80, Delay = 0, Speed = 3200, Collision = false, aoe = false, Type = "line"}

end


function Jhin:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Jhin", name = "Kypo's AIO: Jhin", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "RKey", name = "R Key [?]", key = string.byte("S"), tooltip = "Use on a key that doesn't move"})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})
	
	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = false})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "WClear", name = "Use W If Hit X Minion ", value = 5, min = 2, max = 7, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	AIO.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "RR", name = "Enemies to KS:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})

	AIO:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	AIO.CC:MenuElement({id = "RR", name = "Enemies to Use:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.CC.RR:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	
	AIO.CC:MenuElement({id = "UseE", name = "E", value = true})
	AIO.CC:MenuElement({id = "UseW", name = "W", value = true})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 168, 51)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Jhin:__init()
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


function Jhin:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassW()
	end
	if AIO.Combo.comboActive:Value() then
		self:ComboQ()
		self:ComboW()
	end	
	if AIO.Clear.clearActive:Value() then
		self:ClearQ()
		self:ClearW()
	end	
	if AIO.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealW()
		self:KillstealQ()
		
		self:SpellonCCW()
		self:SpellonCCE()
		self:Rkey()
end

function Jhin:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then 
Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value())
Draw.CircleMinimap(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("W",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0) * 4
				local damage = RDamage + WDamage + AA
				
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(R.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range, R.Speed, myHero.pos, R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Jhin:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = ({45, 70, 95, 120, 145})[level] + ({0.4, 0.45, 0.50, 0.55, 0.60})[level] * myHero.totalDamage + 0.6 * myHero.ap
	return qdamage
end

function Jhin:WDMG()
    local level = myHero:GetSpellData(_W).level
    local wdamage = ({50, 85, 120, 155, 190})[level] + 0.5 * myHero.totalDamage
	return wdamage
end

function Jhin:LastshotDMG()
   return ({15,20,25})[1 + math.floor(0.19 * myHero.levelData.lvl)]
end


function Jhin:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Jhin:ComboW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Combo.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) and GetDistance(myHero.pos, target.pos) > Q.Range - 100 and HasBuff(target,"jhinespotteddebuff") then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Jhin:ComboQ()	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
			Control.CastSpell(HK_Q, target)
		    end
	    end

function Jhin:HarassW()
    local target = CurrentTarget(W.Range)
    if target == nil then return end
    if AIO.Harass.UseW:Value() and target and Ready(_W) then
	    if EnemyInRange(W.Range) then
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
		    if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
		    end
	    end
    end
end

function Jhin:HarassQ()	
	local target = CurrentTarget(Q.Range)
    if target == nil then return end
    if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
			Control.CastSpell(HK_Q, target)
		    end
	    end

function Jhin:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
		   	local Wdamage = Jhin:WDMG()
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and not HasBuff(myHero, "JhinRShot") then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Jhin:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and AIO.Killsteal.RR["KS"..target.charName]:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Jhin:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 and not HasBuff(myHero, "JhinRShot") then
			    CastSpell(HK_Q,target)
				end
			end
		end
	end

function Jhin:Rkey()
    local target = CurrentTarget(R.Range)
	if target == nil then return end
	if AIO.Combo.RKey:Value() and Ready(_R) then
		if EnemyInRange(R.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, 0.15 , 80, R.Range, R.Speed, myHero.pos, R.ignorecol, R.Type )
			if (HitChance > 0 ) and target and not target.dead and target.pos2D.onScreen then
				Control.CastSpell(HK_R,castpos)
				end
			end
		end
	end

function Jhin:SpellonCCW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.CC.UseW:Value() and AIO.CC.RR["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos,not W.ignorecol, W.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and not HasBuff(myHero, "JhinRShot") then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end

function Jhin:SpellonCCE()
    local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.CC.UseE:Value() and AIO.CC.RR["KS"..target.charName]:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if ImmobileEnemy and not HasBuff(myHero, "JhinRShot") then
			    CastSpell(HK_E,target)
				end
			end
		end
	end
	
function Jhin:ClearQ()
if Ready(_Q) then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Jhin:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Clear.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
	end
	
function Jhin:Lasthit()
if Ready(_Q) then
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = Jhin:QDMG()
			if myHero.pos:DistanceTo(minion.pos) < Q.Range and AIO.Lasthit.UseQ:Value() and minion.isEnemy then
				if Qdamage >= minion.health and HasBuff(myHero, "JhinPassiveReload") then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
	end
	
	function Jhin:ClearW()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_W) then 
			if AIO.Clear.UseW:Value() and minion then
				if ValidTarget(minion, 2000) and myHero.pos:DistanceTo(minion.pos) < 2000  and minion:GetCollision(40, 1600, 0.10) - 1 >= AIO.Clear.WClear:Value() then
					Control.CastSpell(HK_W, minion)
					end
				end
			end
		end
	end
	end
	
class "Twitch"


function Twitch:LoadSpells()

	W = {Range = 950, Width = 0, Delay = 0.25, Speed = 1750, Collision = false, aoe = false, Type = "circular"}
	E = {Range = 1250, Width = 0, Delay = 0.25, Speed = 20, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1200, Width = 0, Delay = 0.60, Speed = 500, Collision = false, aoe = false, Type = "line"}

end


function Twitch:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Twitch", name = "Kypo's AIO: Twitch", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "EE", name = "Enemies to use E:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Combo.EE:MenuElement({id = "EE"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})

	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Twitch:__init()
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


function Twitch:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:ComboE()
		self:ComboW()
	end
end

function Twitch:Draw()
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local EDamage = (Ready(_E) and getdmg("E",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0) * 6
				local damage = EDamage + AA
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 55, hero.pos2D.y - 190,Draw.Color(200, 255, 87, 51))	
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_R) then
			local target = CurrentTarget(5000)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, 5000, R.Speed, myHero.pos, not R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Twitch:EDMG()
local level = myHero:GetSpellData(_E).level
	local edamage = ({20, 25, 30, 35, 40})[level] + 0.2 * myHero.ap + 0.25 * myHero.totalDamage + ({35, 45, 55, 65, 70})[level] * 3
	return edamage
end

function Twitch:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Twitch:ComboW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range,W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 ) and not HasBuff(myHero, "TwitchFullAutomatic") then
			    CastSpell(HK_W,castpos)
			end
		end
	end
end

function Twitch:ComboE()
	local target = CurrentTarget(E.Range)
	if target == nil then return end
	if AIO.Combo.UseE:Value() and AIO.Combo.EE["EE"..target.charName]:Value() and target and Ready(_E) then
		if EnemyInRange(E.Range) then 
		   	local Edamage = Twitch:EDMG()
			if Edamage >= HpPred(target,1) + target.hpRegen * 1 and HasBuff(target, "twitchdeadlyvenom") then
			    Control.CastSpell(HK_E)
				end
			end
		end
	end
	
class "Morgana"


function Morgana:LoadSpells()

	Q = {Range = 1175, Width = 70, Delay = 0.35, Speed = 1200, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 0, Delay = 0.25, Speed = 20, Collision = false, aoe = true, Type = "circular"}
	E = {Range = 800, Width = 0, Delay = 0.25, Speed = 20, Collision = false, aoe = false, Type = "line"}
	R = {Range = 625, Width = 0, Delay = 0.25, Speed = 20, Collision = false, aoe = false, Type = "circular"}

end


function Morgana:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Morgana", name = "Kypo's AIO: Morgana", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseR", name = "R", value = true})
	AIO.Combo:MenuElement({id = "RCount", name = "Use R on X targets", value = 2, min = 1, max = 5, step = 1})
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})	
	
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Clear:MenuElement({id = "WHit", name = "W hits x minions", value = 3,min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "KS", name = "Enemies to use:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.KS:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	
	AIO:MenuElement({id = "CC", name = "CC Settings", type = MENU})
	AIO.CC:MenuElement({id = "CC", name = "Enemies to use:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.CC.CC:MenuElement({id = "CC"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.CC:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.CC:MenuElement({id = "UseW", name = "W", value = true})
	
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Morgana:__init()
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


function Morgana:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:Combo()
		self:RonX()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Harass.harassActive:Value() then
		self:Harass()
	end
	
	self:SpellonCCQ()
	self:KillstealQ()
	self:SpellonCCW()

end

function Morgana:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local RDamage = (Ready(_R) and getdmg("R",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0) * 2
				local damage = QDamage + WDamage + RDamage + AA
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 55, hero.pos2D.y - 190,Draw.Color(200, 255, 87, 51))	
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
		if Ready(_Q) then
			local target = CurrentTarget(Q.Range)
			if target == nil then return end
			local temppred
			if (TPred) then
				local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, Q.Range, R.Speed, myHero.pos, not R.ignorecol, R.Type )
				Draw.Circle(castpos, 60, 3, Draw.Color(200, 255, 255, 255))
			end
		end
end

function Morgana:QDMG()
local target = CurrentTarget(Q.Range)
if target == nil then return end
local level = myHero:GetSpellData(_Q).level
	local damage = getdmg("Q",target,myHero)
	return damage
end

function Morgana:WDMG()
local target = CurrentTarget(W.Range)
if target == nil then return end
local level = myHero:GetSpellData(_W).level
	local damage = getdmg("W",target,myHero)
	return damage
end

function Morgana:RDMG()
local target = CurrentTarget(R.Range)
if target == nil then return end
local level = myHero:GetSpellData(_R).level
	local damage = getdmg("R",target,myHero)
	return damage
end

function Morgana:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

function Morgana:Combo()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if (HitChance > 0 ) then
			    CastSpell(HK_Q,castpos)
			end
		end
	end
end

function Morgana:Harass()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Harass.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
			end
		end
	end
end

function Morgana:Clear()
	local Minions = {}
	local mobs = {}
	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if ValidTarget(minion,W.Range) then
			if minion.team == 300 then
				mobs[#mobs+1] = minion
			elseif minion.isEnemy then
				Minions[#Minions+1] = minion
			end	
		end
	end		
	if Ready(_W) and AIO.Clear.UseW:Value() then
		local BestPos, BestHit = GetBestCircularFarmPosition(W.Range, 275 + 48, Minions)
		if BestHit >= AIO.Clear.WHit:Value() then
			Control.CastSpell(HK_W,BestPos)
		end
	end
	
	if Ready(_W) and AIO.Clear.UseW:Value() then
	local BestPos, BestHit = GetBestCircularFarmPosition(W.Range, 275 + 48, mobs)
		if BestHit >= AIO.Clear.WHit:Value() then
		Control.CastSpell(HK_W,mob)	end
end		
end

function Morgana:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and AIO.Killsteal.KS["KS"..target.charName]:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
		   	local Qdamage = Morgana:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

function Morgana:SpellonCCQ()
    local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.CC.UseQ:Value() and AIO.CC.CC["CC"..target.charName]:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, not Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) then
				CastSpell(HK_Q, castpos)
				end
			end
		end
	end
end

function Morgana:SpellonCCW()
    local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.CC.UseW:Value() and AIO.CC.CC["CC"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			if ImmobileEnemy then
				CastSpell(HK_W, target)
				end
			end
		end
	end
	
function Morgana:RonX()
if AIO.Combo.UseR:Value() and Ready(_R) then
	if EnemiesNear(myHero.pos,570) >= AIO.Combo.RCount:Value() then
		Control.CastSpell(HK_R)
end
end
end

class "Lucian"


function Lucian:LoadSpells()

	Q = {Range = 600, Width = 65, Delay = 0.10, Speed = 500, Collision = true, aoe = false, Type = "line"}
	W = {Range = 900, Width = 10, Delay = 0.20, Speed = 2000, Collision = false, aoe = false, Type = "line"}
	E = {Range = 445, Width = 50, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1400, Width = 60, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}

end


function Lucian:LoadMenu()
	AIO = MenuElement({type = MENU, id = "Lucian", name = "Kypo's AIO: Lucian", leftIcon = AIOIcon})
	AIO:MenuElement({id = "Combo", name = "Combo", type = MENU})
	AIO.Combo:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Combo:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Combo:MenuElement({id = "UseE", name = "E", value = true})
	AIO.Combo:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO.Combo:MenuElement({id = "ESet", name = "E Settings", type = MENU})
	AIO.Combo.ESet:MenuElement({id = "Type", name = "E Logic", value = 1, drop = {"To Mouse", "To Target"}})
	
	-- AIO.Combo:MenuElement({id = "RSet", name = "R Settings", type = MENU})
	-- AIO.Combo.RSet:MenuElement({id = "UseR", name = "R", value = true})
	
	AIO.Combo:MenuElement({id = "ComboType", name = "Combo Type", type = MENU})
	AIO.Combo.ComboType:MenuElement({id = "Type", name = "Combo Logic", value = 1,drop = {"QWE (Best)", "WQE", "EWQ", "EQW"}})
	
	AIO.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})	
	
	AIO:MenuElement({id = "Harass", name = "Harass", type = MENU})
	AIO.Harass:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Harass:MenuElement({id = "UseW", name = "W", value = true})
	AIO.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	AIO:MenuElement({id = "Clear", name = "Clear", type = MENU})
	AIO.Clear:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Clear:MenuElement({id = "QHit", name = "Q hits x minions", value = 3,min = 1, max = 5, step = 1})
	AIO.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	AIO:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	AIO.Killsteal:MenuElement({id = "KS", name = "Enemies to use:", type = MENU})
	for i, hero in pairs(GetEnemyHeroes()) do
	AIO.Killsteal.KS:MenuElement({id = "KS"..hero.charName, name = ""..hero.charName, value = true})
	end
	AIO.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true})
	AIO.Killsteal:MenuElement({id = "UseW", name = "W", value = true})
	
	AIO:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	--Q
	AIO.Drawings:MenuElement({id = "Q", name = "Draw Q range", type = MENU})
    AIO.Drawings.Q:MenuElement({id = "Enabled", name = "Enabled", value = false})       
    AIO.Drawings.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--W
	AIO.Drawings:MenuElement({id = "W", name = "Draw W range", type = MENU})
    AIO.Drawings.W:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--E
	AIO.Drawings:MenuElement({id = "E", name = "Draw E range", type = MENU})
    AIO.Drawings.E:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})	
	--R
	AIO.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU})
    AIO.Drawings.R:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    AIO.Drawings.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    AIO.Drawings.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(200, 255, 255, 255)})
	
	AIO.Drawings:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
    AIO.Drawings:MenuElement({id = "HPColor", name = "HP Color", color = Draw.Color(200, 255, 255, 255)})

	AIO:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	AIO:MenuElement({id = "delay", name = "Custom spellcast delay", value = 100, min = 0, max = 200, step = 5,tooltip = "increase this one if spells is going completely wrong direction", identifier = ""})
	
	AIO:MenuElement({id = "blank", type = SPACE , name = ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	AIO:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


function Lucian:__init()
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


function Lucian:Tick()
        if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true or ExtLibEvade and ExtLibEvade.Evading == true then return end
	if AIO.Combo.comboActive:Value() then
		self:ComboTypes()
	end
	if AIO.Clear.clearActive:Value() then
		self:Clear()
	end
	if AIO.Harass.harassActive:Value() then
		self:HarassQ()
		self:HarassW()
	end
	
	self:KillstealQ()
	self:KillstealW()

end

-- function Lucian:test()	
	-- local target = CurrentTarget(1000)
    -- if target == nil then return end
	-- print(GetDistance(myHero.pos,target.pos))
	-- end

function Lucian:Draw()
if Ready(_Q) and AIO.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, Q.Range, AIO.Drawings.Q.Width:Value(), AIO.Drawings.Q.Color:Value()) end
if Ready(_W) and AIO.Drawings.W.Enabled:Value() then Draw.Circle(myHero.pos, W.Range, AIO.Drawings.W.Width:Value(), AIO.Drawings.W.Color:Value()) end
if Ready(_E) and AIO.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, E.Range, AIO.Drawings.E.Width:Value(), AIO.Drawings.E.Color:Value()) end
if Ready(_R) and AIO.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, R.Range, AIO.Drawings.R.Width:Value(), AIO.Drawings.R.Color:Value()) end

			if AIO.Drawings.DrawDamage:Value() then
		for i, hero in pairs(GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (Ready(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (Ready(_W) and getdmg("W",hero,myHero) or 0)
				local AA = (getdmg("AA",hero,myHero) or 0) * 6
				local RR = Lucian:RDMG()
				local damage = QDamage + WDamage + RR + AA
				if damage > hero.health then
					Draw.Text("KILLABLE", 30, hero.pos2D.x - 55, hero.pos2D.y - 195,Draw.Color(200, 255, 87, 51))				
				if RR > hero.health and Ready(_R) then
					Draw.Text("R KILLABLE", 30, hero.pos2D.x - 55, hero.pos2D.y - 230,Draw.Color(200, 255, 87, 51))	
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, AIO.Drawings.HPColor:Value())
				end
			end
		end	
	end
end
end

function Lucian:QDMG()
local target = CurrentTarget(Q.Range)
if target == nil then return end
local level = myHero:GetSpellData(_Q).level
	local damage = getdmg("Q",target,myHero)
	return damage
end

function Lucian:WDMG()
local target = CurrentTarget(W.Range)
if target == nil then return end
local level = myHero:GetSpellData(_W).level
	local damage = getdmg("W",target,myHero)
	return damage
end

function Lucian:RDMG()
local level = myHero:GetSpellData(_R).level
local level2 = myHero:GetSpellData(_R).level
	local damage = ({20, 35, 50})[level] + 0.1 * myHero.ap + 0.20 * myHero.totalDamage * ({20, 25, 29})[level2]
	return damage
end

function Lucian:IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.type == 28 or buff.type == 21 or buff.type == 22) and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

-- Combo

function Lucian:ComboTypes(target)
local mode = AIO.Combo.ComboType.Type:Value() 
	if mode == 1 then
		self:Q()
		self:W()
		self:E()
	elseif mode == 2 then
		self:W2()
		self:Q2()
		self:E2()
	elseif mode == 3 then
		self:E3()
		self:W3()
		self:Q3()
	elseif mode == 4 then
		self:E4()
		self:Q4()
		self:W4()
		end
end

--------------------- 1
function Lucian:Q()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
			    CastSpell(HK_Q,target)
			end
		end
	end
end

function Lucian:W()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseW:Value() and target and Ready(_W) and not Ready(_Q) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 )	and WINDDOWN and not ATTACK and not WINDUP then
			DelayAction(function() 
				CastSpell(HK_W,castpos)
			end, 0.55)
			end
		end
	end
end

function Lucian:E()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	local mode = AIO.Combo.ESet.Type:Value() 

	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseE:Value() and target and Ready(_E) and not Ready(_W) then
		if EnemyInRange(W.Range) then 
			if WINDDOWN and not ATTACK and not WINDUP then
		if mode == 1 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.15)
		elseif mode == 1 then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.40)
		
		elseif mode == 2 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.15)
		elseif mode == 2 then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.40)
			end
		end
	end
end
end
--------------------- 1

--------------------- 2

function Lucian:W2()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseW:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 )	and WINDDOWN and not ATTACK and not WINDUP then
				DelayAction(function() 
				CastSpell(HK_W,castpos)
			end, 0.30)
			end
		end
	end
end

function Lucian:Q2()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not Ready(_W) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
				DelayAction(function() 
			    CastSpell(HK_Q,target)
			end, 0.20)
			end
		end
	end
end

function Lucian:E2()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	local mode = AIO.Combo.ESet.Type:Value() 

	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseE:Value() and target and Ready(_E) and not Ready(_Q) then
		if EnemyInRange(W.Range) then 
			if WINDDOWN and not ATTACK and not WINDUP then
		if mode == 1 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.40)
		elseif mode == 1 and Ready(_Q) then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.50)
		
		elseif mode == 2 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.40)
		elseif mode == 2 and Ready(_Q) then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.50)
			end
		end
	end
end
end
--------------------- 2


--------------------- 3

function Lucian:E3()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	local mode = AIO.Combo.ESet.Type:Value() 

	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(W.Range) then 
			if WINDDOWN and not ATTACK and not WINDUP then
		if mode == 1 and not Ready(_E) then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.30)
		elseif mode == 1 then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.40)
		
		elseif mode == 2 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.30)
		elseif mode == 2 then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.40)
			end
		end
	end
end
end

function Lucian:W3()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseW:Value() and target and Ready(_W) and not Ready(_E) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 )	and WINDDOWN and not ATTACK and not WINDUP then
			DelayAction(function() 
				CastSpell(HK_W,castpos)
			end, 0.30)
			end
		end
	end
end

function Lucian:Q3()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not Ready(_W) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
				DelayAction(function() 
			    CastSpell(HK_Q,target)
			end, 0.55)
			end
		end
	end
end
--------------------- 3

--------------------- 4

function Lucian:E4()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	local mode = AIO.Combo.ESet.Type:Value() 

	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseE:Value() and target and Ready(_E) then
		if EnemyInRange(W.Range) then 
			if WINDDOWN and not ATTACK and not WINDUP then
		if mode == 1 and not Ready(_E) then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.40)
		elseif mode == 1 then
		DelayAction(function()
			CastSpell(HK_E,mousePos)
		end, 0.50)
		
		elseif mode == 2 and not Ready(_W) then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.40)
		elseif mode == 2 then
		DelayAction(function()
			CastSpell(HK_E,target)
		end, 0.50)
			end
		end
	end
end
end

function Lucian:Q4()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not Ready(_E) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
				DelayAction(function() 
			    CastSpell(HK_Q,target)
			end, 0.65)
			end
		end
	end
end

function Lucian:W4()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseW:Value() and target and Ready(_W) and not Ready(_Q) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 )	and WINDDOWN and not ATTACK and not WINDUP then
			DelayAction(function() 
				CastSpell(HK_W,castpos)
			end, 0.30)
			end
		end
	end
end
--------------------- 4


function Lucian:Q4()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not Ready(_E) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
				DelayAction(function() 
			    CastSpell(HK_Q,target)
			end, 0.65)
			end
		end
	end
end

function Lucian:W4()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseW:Value() and target and Ready(_W) and not Ready(_Q) then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 )	and WINDDOWN and not ATTACK and not WINDUP then
			DelayAction(function() 
				CastSpell(HK_W,castpos)
			end, 0.30)
			end
		end
	end
end
--------------------- 6

function Lucian:Q5()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	local WINDDOWN = myHero.attackData.state == STATE_WINDDOWN	-- Finish AA
	local WINDUP = myHero.attackData.state == STATE_WINDUP 		-- About to AA
	local ATTACK = myHero.attackData.state == STATE_ATTACK		-- ATTACK

	if AIO.Combo.UseQ:Value() and target and Ready(_Q) and not Ready(_W) then
		if EnemyInRange(Q.Range) then 
			if WINDDOWN and not ATTACK then
				DelayAction(function() 
			    CastSpell(HK_Q,target)
			end, 0.3)
			end
		end
	end
end

--------------------- 5



function Lucian:HarassQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Harass.UseQ:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
			    CastSpell(HK_Q,target)
		end
	end
end

function Lucian:HarassW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Harass.UseW:Value() and target and Ready(_W) and not Ready(_Q)then
		if EnemyInRange(W.Range) then 
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, W.ignorecol, W.Type )
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
			end
		end
	end
end

function Lucian:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if Ready(_Q) then 
			if AIO.Clear.UseQ:Value() and minion then
				if ValidTarget(minion, 600) and myHero.pos:DistanceTo(minion.pos) < 600 and minion:GetCollision(65, 1600, 0.10) >= AIO.Clear.QHit:Value() then
					Control.CastSpell(HK_Q, minion)
					end
				end
			end
		end
	end
end

function Lucian:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if AIO.Killsteal.UseQ:Value() and AIO.Killsteal.KS["KS"..target.charName]:Value() and target and Ready(_Q) then
		if EnemyInRange(Q.Range) then 
		   	local Qdamage = Lucian:QDMG()
			if Qdamage >= HpPred(target,1) + target.hpRegen * 1 then
				CastSpell(HK_Q, target)
				end
			end
		end
	end
	
function Lucian:KillstealW()
	local target = CurrentTarget(W.Range)
	if target == nil then return end
	if AIO.Killsteal.UseW:Value() and AIO.Killsteal.KS["KS"..target.charName]:Value() and target and Ready(_W) then
		if EnemyInRange(W.Range) then 
		   	local Wdamage = Lucian:WDMG()
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, W.Delay , W.Width, W.Range, W.Speed, myHero.pos, not W.ignorecol, W.Type )
			if Wdamage >= HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) then
			    CastSpell(HK_W,castpos)
				end
			end
		end
	end
end


	
-- Utilities menu

class "Essentials"
local mapID = Game.mapID;
local wards = {}
local quality = 1

function Essentials:__init()
	self:BaseUltData()
	Essentials:Menu()
	Callback.Add("ProcessRecall", function(unit, recall) self:ProcessRecall(unit, recall) end)
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local orbwalkername = ""
	if _G.SDK then
		orbwalkername = "IC'S orbwalker"
end
end

function Essentials:Tick()
GetMode()
-- Summoner KS
	ChillingSmiteKS()
	IgniteKS()
-- Item KS
	TiamatKS()
	HydraKS()
	BladeKingKS()
	THydraKS()
	GLPKS()
	GunbladeKS()
	ProtobeltKS()
-- Items cast
if GetMode() == "Combo" then
	EdgeNightCast()
	TiamatCast()	
	HydraCast()
	BladeKingCast()
	THydraCast()
	GLPCast()	
	GunbladeCast()
	ProtobeltCast()
	YoumuuCast()
	end
	-- Awareness
	
	
	-- Baseult
	self:BaseultB()
	self:BaseultR()
	-- Other
	
	
end



function Essentials:Draw()
end


function GetMode()
	if _G.SDK and _G.SDK.Orbwalker then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "Lasthit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
	end
end
	

function Essentials:Menu()
	Essentials = MenuElement({type = MENU, id = "Essentials", name = "Kypo's Essentials", leftIcon = EssentialsIcon})
	Essentials:MenuElement({id = "Activator", name = "Activator", type = MENU})
	
	-- Offensive
	
	Essentials.Activator:MenuElement({id = "Offensive", name = "Offensive", type = MENU})
	Essentials.Activator.Offensive:MenuElement({id = "Tiamat", name = "Tiamat", value = true})
	Essentials.Activator.Offensive:MenuElement({id = "Hydra", name = "Ravenous Hydra", value = true})
	Essentials.Activator.Offensive:MenuElement({id = "THydra", name = "Titanic Hydra", value = true})
	
	Essentials.Activator.Offensive:MenuElement({id = "GLP", name = "Hextech GLP", type = MENU})
	Essentials.Activator.Offensive.GLP:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Offensive.GLP:MenuElement({id = "HP", name = "Max enemy HP", value = 50, min = 1, max = 100})
	
	Essentials.Activator.Offensive:MenuElement({id = "Gunblade", name = "Hextech Gunblade", type = MENU})
	Essentials.Activator.Offensive.Gunblade:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Offensive.Gunblade:MenuElement({id = "HP", name = "Max enemy HP", value = 50, min = 1, max = 100})
	
	Essentials.Activator.Offensive:MenuElement({id = "Protobelt", name = "Hextech Protobelt", type = MENU})
	Essentials.Activator.Offensive.Protobelt:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Offensive.Protobelt:MenuElement({id = "HP", name = "Max enemy HP", value = 50, min = 1, max = 100})
	
	Essentials.Activator.Offensive:MenuElement({id = "BladeKing", name = "Blade of the Ruined King", type = MENU})
	Essentials.Activator.Offensive.BladeKing:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Offensive.BladeKing:MenuElement({id = "HP", name = "Max Enemy HP", value = 80, min = 1, max = 100})
	
	Essentials.Activator.Offensive:MenuElement({id = "YG", name = "Youmuu's Ghostblade", type = MENU})
	Essentials.Activator.Offensive.YG:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Offensive.YG:MenuElement({id = "Dist", name = "Enemy Distance", value = 1000, min = 300, max = 1500, step = 50})
	
	-- Defensive
	Essentials.Activator:MenuElement({id = "Defensive", name = "Defensive", type = MENU})
	Essentials.Activator.Defensive:MenuElement({id = "EdgeNight", name = "Edge of Night", type = MENU})
	Essentials.Activator.Defensive.EdgeNight:MenuElement({id = "Enable", name = "Enable", value = true})
	Essentials.Activator.Defensive.EdgeNight:MenuElement({id = "MinEnemies", name = "Min Enemies", value = 2, min = 1, max = 5})

	-- Killsteal
	Essentials.Activator:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal"})
	Essentials.Activator.Killsteal:MenuElement({id = "KSEnemies", name = "Select enemy heroes you want to KS", type = MENU})
	for i, target in pairs(GetEnemyHeroes()) do
	Essentials.Activator.Killsteal.KSEnemies:MenuElement({id = "EnemiesToKS"..target.charName, name = ""..target.charName, value = true})
	end
	
	Essentials.Activator.Killsteal:MenuElement({type = MENU, id = "Summoners", name = "Summoners"})
	Essentials.Activator.Killsteal.Summoners:MenuElement({id = "Ignite", name = "Ignite", value = true})
	Essentials.Activator.Killsteal.Summoners:MenuElement({id = "ChillingSmite", name = "Chilling Smite", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	
	Essentials.Activator.Killsteal:MenuElement({id = "Tiamat", name = "Tiamat", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "Hydra", name = "Ravenous Hydra", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "THydra", name = "Titanic Hydra", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "GLP", name = "Hextech GLP", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "Gunblade", name = "Hextech Gunblade", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "Protobelt", name = "Hextech Protobelt", value = true})
	Essentials.Activator.Killsteal:MenuElement({id = "BladeKing", name = "Blade of the Ruined King", value = true})
	
	-- Awareness
	-- Essentials:MenuElement({id = "Awareness", name = "Awareness", type = MENU})

	-- Tracker
	-- Essentials:MenuElement({id = "Tracker", name = "Tracker", type = MENU})
	-- Essentials.Tracker:MenuElement({id = "SpellsMyhero", name = "My Spells", value = true})
	-- Essentials.Tracker:MenuElement({id = "SpellsEnemies", name = "Enemy Spells", value = true})
	-- Essentials.Tracker:MenuElement({id = "blank", type = SPACE , name = ""})
	-- Essentials.Tracker:MenuElement({id = "Recall", name = "Recall Track", value = true})

	-- Baseult
	Essentials:MenuElement({id = "Baseult", name = "Baseult", type = MENU})
  	Essentials.Baseult:MenuElement({type = MENU, id = "ultchamp", name = "Use ULT on:"})
  	for i, enemy in pairs(GetEnemyHeroes()) do
  	Essentials.Baseult.ultchamp:MenuElement({id = enemy.charName, name = enemy.charName, value = false})
  	end
	Essentials.Baseult:MenuElement({id = "Redside", name = "Enemy UP (minimap)",value = false})
	Essentials.Baseult:MenuElement({id = "Blueside", name = "Enemy DOWN (minimap)",value = false})
	Essentials.Baseult:MenuElement({id = "DontUlt", name = "Don't ult if pressed:", key = 32})
	Essentials.Baseult:MenuElement({id = "blank", type = SPACE , name = "Supported;"})
	Essentials.Baseult:MenuElement({id = "blank", type = SPACE , name = "Ashe, Draven, Ezreal, Jinx"})
	Essentials.Baseult:MenuElement({id = "blank", type = SPACE , name = "Lux, Gangplank, Ziggs"})

	-- Smite
	-- Essentials:MenuElement({id = "Smite", name = "Smite", type = MENU})	
	

	Essentials:MenuElement({id = "blank", type = SPACE , name = ""})
	Essentials:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	Essentials:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end


-- [ITEM DAMAGE]


function IgniteDMG()
	return 50+20*myHero.levelData.lvl
end

function ChillingSmiteDMG() --3706,1401,1400,1402,1416
	return 20+8*myHero.levelData.lvl
end 

function TiamatDMG() --3077
	return 100
end 

function THydraDMG() --3748
	return 200
end 

function GLPDMG() --3030
    local level = myHero.levelData.lvl
    local damage = ({100,106,112,118,124,130,136,141,147,153,159,165,171,176,182,188,194,200})[level] + 0.35 * myHero.ap
	return damage
end 

function GunbladeDMG() --3146
    local level = myHero.levelData.lvl
    local damage = ({175,180,184,189,193,198,203,207,212,216,221,225,230,235,239,244,248,253})[level] + 0.30 * myHero.ap
	return damage
end 

function ProtobeltDMG() --3152
    local level = myHero.levelData.lvl
    local damage = ({75,79,83,88,92,97,101,106,110,115,119,124,128,132,137,141,146,150})[level] + 0.25 * myHero.ap
	return damage
end

function BladeKingDMG() --3144,3153
	local target = CurrentTarget(550)
	if target == nil then return end
	return target.maxHealth * 0.1
end 



-- [ITEM KILLSTEAL]

function TiamatKS()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Tiamat:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local Tiamat = GetInventorySlotItem(3077)
		local dmg = TiamatDMG()
		if Tiamat and EnemyInRange(380) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[Tiamat])
			end
		end
	end
	
function HydraKS()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Hydra:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local Hydra = GetInventorySlotItem(3074)
		local dmg = TiamatDMG()
		if Hydra and EnemyInRange(380) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[Hydra])
			end
		end
	end
	
function THydraKS()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Killsteal.THydra:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local THydra = GetInventorySlotItem(3748)
		local dmg = THydraDMG()
		if THydra and EnemyInRange(380) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[THydra])
			end
		end
	end
	
function GLPKS()
	local target = CurrentTarget(880)
	if target == nil then return end
	if Essentials.Activator.Killsteal.GLP:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local GLP = GetInventorySlotItem(3030)
		local dmg = GLPDMG()
		if GLP and EnemyInRange(880) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[GLP], target)
			end
		end
	end
	
function GunbladeKS()
	local target = CurrentTarget(700)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Gunblade:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local Gunblade = GetInventorySlotItem(3146)
		local dmg = GunbladeDMG()
		if Gunblade and EnemyInRange(700) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[Gunblade], target)
			end
		end
	end
	
function ProtobeltKS()
	local target = CurrentTarget(850)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Protobelt:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local Protobelt = GetInventorySlotItem(3152)
		local dmg = ProtobeltDMG()
		if Protobelt and EnemyInRange(850) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[Protobelt], target)
			end
		end
	end
	
function BladeKingKS()
	local target = CurrentTarget(550)
	if target == nil then return end
	if Essentials.Activator.Killsteal.BladeKing:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local BladeKing = GetInventorySlotItem(3144) or GetInventorySlotItem(3153)
		local dmg = BladeKingDMG()
		if BladeKing and EnemyInRange(550) and dmg >= HpPred(target,1) then
			Control.CastSpell(HKITEM[BladeKing], target)
			end
		end
	end

-- [Summoner KILLSTEAL]

function IgniteKS()
	local target = CurrentTarget(600)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Summoners.Ignite:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		if EnemyInRange(600) then 
			local IgniteDMG = IgniteDMG()
			if IgniteDMG >= HpPred(target,1) then
        if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
            Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
            Control.CastSpell(HK_SUMMONER_2, target)				
			end
			end
		end
	end
	end
	
function ChillingSmiteKS()
	local target = CurrentTarget(500)
	if target == nil then return end
	if Essentials.Activator.Killsteal.Summoners.ChillingSmite:Value() and Essentials.Activator.Killsteal.KSEnemies["EnemiesToKS"..target.charName]:Value() then
		local dmg = ChillingSmiteDMG()
		if EnemyInRange(500) and dmg >= HpPred(target,1) then
        if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) then
            Control.CastSpell(HK_SUMMONER_1, target)
        elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) then
            Control.CastSpell(HK_SUMMONER_2, target)
			end
		end
	end
end
		
-- [Item Cast]
-- Offensive
function TiamatCast()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Offensive.Tiamat:Value() then
		local Tiamat = GetInventorySlotItem(3077)
		if Tiamat and EnemyInRange(380) then
			Control.CastSpell(HKITEM[Tiamat])
			end
		end
	end
	
function HydraCast()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Offensive.Hydra:Value() then
		local Hydra = GetInventorySlotItem(3074)
		local dmg = TiamatDMG()
		if Hydra and EnemyInRange(380) then
			Control.CastSpell(HKITEM[Hydra])
			end
		end
end
	
function THydraCast()
	local target = CurrentTarget(380)
	if target == nil then return end
	if Essentials.Activator.Offensive.THydra:Value()  then
		local THydra = GetInventorySlotItem(3074)
		local dmg = THydraDMG()
		if THydra and EnemyInRange(380) then
			Control.CastSpell(HKITEM[THydra])
			end
		end
	end
	
function GLPCast()
	local target = CurrentTarget(880)
	if target == nil then return end
	if Essentials.Activator.Offensive.GLP.Enable:Value() then
		local GLP = GetInventorySlotItem(3030)
		if GLP and EnemyInRange(880) and target.health/target.maxHealth <= Essentials.Activator.Offensive.GLP.HP:Value() / 100 then
			Control.CastSpell(HKITEM[GLP], target)
			end
		end
	end
	
function GunbladeCast()
	local target = CurrentTarget(700)
	if target == nil then return end
	if Essentials.Activator.Offensive.Gunblade.Enable:Value() then
		local Gunblade = GetInventorySlotItem(3146)
		if Gunblade and EnemyInRange(700) and target.health/target.maxHealth <= Essentials.Activator.Offensive.Gunblade.HP:Value() / 100 then
			Control.CastSpell(HKITEM[Gunblade], target)
			end
		end
	end
	
function ProtobeltCast()
	local target = CurrentTarget(850)
	if target == nil then return end
	if Essentials.Activator.Offensive.Protobelt.Enable:Value() and target.health/target.maxHealth <= Essentials.Activator.Offensive.Protobelt.HP:Value() / 100 then
		local Protobelt = GetInventorySlotItem(3152)
		if Protobelt and EnemyInRange(850) then
			Control.CastSpell(HKITEM[Protobelt], target)
			end
		end
	end
	
function BladeKingCast()
	local target = CurrentTarget(550)
	if target == nil then return end
	if Essentials.Activator.Offensive.BladeKing.Enable:Value() and target.health/target.maxHealth <= Essentials.Activator.Offensive.BladeKing.HP:Value() / 100 then
		local BladeKing = GetInventorySlotItem(3144) or GetInventorySlotItem(3153)
		if BladeKing and EnemyInRange(550) then
			Control.CastSpell(HKITEM[BladeKing], target)
			end
		end
	end
	
function YoumuuCast()
	local target = CurrentTarget(1500)
	if target == nil then return end
	if Essentials.Activator.Offensive.YG.Enable:Value() and target.distance < Essentials.Activator.Offensive.YG.Dist:Value() then
		local YG = GetInventorySlotItem(3142)
		if YG then
			Control.CastSpell(HKITEM[YG])
			end
		end
	end
	
-- Defensive
function EdgeNightCast()
	local target = CurrentTarget(1200)
	if target == nil then return end
	if Essentials.Activator.Defensive.EdgeNight.Enable:Value() and EnemyInRange(1200) >= Essentials.Activator.Defensive.EdgeNight.MinEnemies:Value() then
		local EdgeNight = GetInventorySlotItem(3814)
		if EdgeNight and EnemyInRange(1200) then
			Control.CastSpell(HKITEM[EdgeNight])
			end
		end
	end
	
----- BASEULT DATA

function Essentials:BaseUltData()
   	self.UltimateData = {
    		["Ashe"] = {Delay = 0.20, Speed = 1600, Width = 130, Collision = true, Damage = function(source, target) return getdmg("R", target, source) end},
    		["Draven"] = {Delay = 0.4, Speed = 2000, Width = 160, Collision = true, Damage = function(source, target) return getdmg("R", target, source) end},
    		["Ezreal"] = {Delay = 1, Speed = 2000, Width = 160, Damage = function(source, target) return getdmg("R", target, source) end},
    		["Jinx"] = {Delay = 0.7, Speed = 1700, Width = 140, Collision = true, Damage = function(source, target) return getdmg("R", target, source, 2) end},
    		["Lux"] = {Delay = 1, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
    		["Gangplank"] = {Delay = 1, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
    		["Ziggs"] = {Delay = 0, Speed = math.huge, Damage = function(source, target) return getdmg("R", target, source) end},
    	}
	self.tempodechegar = 0
	self.Caras, self.dadorecall, self.datadoenemigo, self.danoqpodev = {}, {}, {}, {}
	for i = 1, Game.HeroCount() do
	  	local unit = Game.Hero(i)
  	  	if unit.isMe then 
  	    		goto continue
  	  	end
  	  	if unit.isEnemy then 
  	    		self.datadoenemigo[unit.networkID] = 0
  	    		table.insert(self.Caras, unit)
  	  	end
  	  	::continue::
    	end
    	for i = 1, Game.ObjectCount() do
  	  	local object = Game.Object(i)
  	  	if object.isAlly or object.type ~= Obj_AI_SpawnPoint then 
  	    		goto continue
  	  	end
  	  	self.EnemySpawnPos = object
  	  	break
  	  	::continue::
    	end
end

function Essentials:vidapredicada(unit, time)
	if unit.health then return math.min(unit.maxHealth, unit.health+unit.hpRegen*(Game.Timer()-self.datadoenemigo[unit.networkID]+time)) end
end

function Essentials:pegoudanototal()
	local n = 0
	for i, damage in pairs(self.danoqpodev) do
    		n = n + damage
    	end
    	return n
end

function Essentials:GetRecallData(unit)
    	for i, recall in pairs(self.dadorecall) do
    		if recall.object.networkID == unit.networkID then
    			return {isRecalling = true, recall = recall.start+recall.duration-Game.Timer()}
	    	end
	end
	return {isRecalling = false, recall = 0}
end

function Essentials:GetUltimateData(unit)
	return self.UltimateData[unit.charName]
end

function Essentials:ProcessRecall(unit, recall)
	if not unit.isEnemy then return end
	if recall.isStart then
    		table.insert(self.dadorecall, {object = unit, start = Game.Timer(), duration = (recall.totalTime*0.001)})
    	else
      	for i, rc in pairs(self.dadorecall) do
        	if rc.object.networkID == unit.networkID then
          		table.remove(self.dadorecall, i)
        	end
      	end
    end
end

function Essentials:pegoudanototal()
	local n = 0
	for i, damage in pairs(self.danoqpodev) do
    		n = n + damage
    	end
    	return n
end

function Essentials:tempodechegarbase(unit, data)
	if data.Speed == math.huge and data.Delay ~= 0 then return data.Delay end
	local distance = unit.pos:DistanceTo(self.EnemySpawnPos.pos)
	local delay = data.Delay
	local missilespeed = data.Speed 
	if unit.charName == "Ziggs" then
		delay = 1.5 + 1.5 * distance / unit:GetSpellData(3).range
	end
	if unit.charName == "Jinx" then
		missilespeed = distance > 1350 and (2295000 + (distance - 1350) * 2200) / distance or data.Speed
    	end
	return distance / missilespeed + delay
end
	
	
function Essentials:BaseultR()
if not Essentials.Baseult.Redside:Value() or myHero.dead or not Ready(_R) then return end
	for i, enemy in pairs(self.Caras) do
		if enemy.visible then
			self.datadoenemigo[enemy.networkID] = Game.Timer()
		end
	end
	for i, enemy in pairs(self.Caras) do
		if enemy.valid and not enemy.dead and Essentials.Baseult.ultchamp[enemy.charName]:Value() and self:GetRecallData(enemy).isRecalling then
			local tempodechegar = self:tempodechegarbase(myHero, self:GetUltimateData(myHero))
			local recall = self:GetRecallData(enemy).recall
            		if recall >= tempodechegar then
            			self.danoqpodev[myHero.networkID] = self:GetUltimateData(myHero).Damage(myHero, enemy)
            		else
            			self.danoqpodev[myHero.networkID] = 0
            		end
            		if self:pegoudanototal() < self:vidapredicada(enemy, recall) then return end
            		self.tempodechegar = tempodechegar
            		if recall - tempodechegar > 0.1 or Essentials.Baseult.DontUlt:Value() then return end
					self:BaseultRed()
            		self.tempodechegar = 0
        	end
    	end
end

function Essentials:BaseultB()
if not Essentials.Baseult.Blueside:Value() or myHero.dead or not Ready(_R) then return end
	for i, enemy in pairs(self.Caras) do
		if enemy.visible then
			self.datadoenemigo[enemy.networkID] = Game.Timer()
		end
	end
	for i, enemy in pairs(self.Caras) do
		if enemy.valid and not enemy.dead and Essentials.Baseult.ultchamp[enemy.charName]:Value() and self:GetRecallData(enemy).isRecalling then
			local tempodechegar = self:tempodechegarbase(myHero, self:GetUltimateData(myHero))
			local recall = self:GetRecallData(enemy).recall
            		if recall >= tempodechegar then
            			self.danoqpodev[myHero.networkID] = self:GetUltimateData(myHero).Damage(myHero, enemy)
            		else
            			self.danoqpodev[myHero.networkID] = 0
            		end
            		if self:pegoudanototal() < self:vidapredicada(enemy, recall) then return end
            		self.tempodechegar = tempodechegar
            		if recall - tempodechegar > 0.1 or Essentials.Baseult.DontUlt:Value() then return end
					self:BaseultBlue()
            		self.tempodechegar = 0
        	end
    	end
end


function Essentials:BaseultBlue()
		for i,pos in pairs(BluePos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end

function Essentials:BaseultRed()
		for i,pos in pairs(RedPos) do
			if pos:DistanceTo(myHero.pos) < 99999 then
				local mpos = Vector(pos.x,0,pos.z):ToMM()
				Control.SetCursorPos(mpos.x,mpos.y)
				Control.CastSpell(HK_R)
			end
		end
	end
	
----- BASEULT DATA

Callback.Add("Load",function()
	Essentials()
	_G[myHero.charName]()
end)