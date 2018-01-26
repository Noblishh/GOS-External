local Heroes = {"Yasuo"}
if not table.contains(Heroes, myHero.charName) then return end

require "DamageLib"

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 24
local barYOffset = -8
local Version,Author,LVersion = "v1.0.4","Kypo's","8.1"

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
	

class "Yasuo"

local HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/97/Blood_Moon_Yasuo_profileicon.png"
local QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e5/Steel_Tempest.png"
local Q3Icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Steel_Tempest_3.png"
local WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/61/Wind_Wall.png"
local EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f8/Sweeping_Blade.png"
local RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/c6/Last_Breath.png"

function Yasuo:LoadSpells()

	Q = {Range = 475, Width = 50, Delay = 0,30, Speed = 1500, Collision = false, aoe = false, Type = "line"}
	Q3 = {Name = "YasuoQ3W", Range = 900, Width = 90, Delay = 0.25, Speed = 1500, Collision = false, aoe = false, Type = "line"}
	W = {Range = 400, Width = 0, Delay = 0.25, Speed = 500, Collision = false, aoe = false, Type = "line"}
	E = {Range = 475, Width = 80, Delay = 0.25, Speed = 0, Collision = false, aoe = false, Type = "line"}
	R = {Range = 1200, Width = 0, Delay = 0.20, Speed = 20, Collision = false, aoe = false, Type = "line"}

end

function Yasuo:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Yasuo", name = "Kypo's Yasuo", leftIcon = HeroIcon})
	self.Menu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Combo:MenuElement({id = "UseE", name = "E", value = false, leftIcon = EIcon})
	-- self.Menu.Combo:MenuElement({id = "EUnderTurret", name = "Use E Under Turret", value = false, leftIcon = EIcon})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
		
	self.Menu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("V")})

	self.Menu:MenuElement({id = "Clear", name = "Clear", type = MENU})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Clear:MenuElement({id = "Q3Clear", name = "Use Q3 If Hit X Minion ", value = 3, min = 1, max = 5, step = 1, leftIcon = Q3Icon})
	self.Menu.Clear:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("C")})
	
	self.Menu:MenuElement({id = "AutoR", name = "Auto R Champs", type = MENU})
	self.Menu.AutoR:MenuElement({id = "AutoRXEnable", name = "R", value = true, leftIcon = RIcon})
	self.Menu.AutoR:MenuElement({id = "AutoRX", name = "Use R if champs are UP", value = 3, min = 2, max = 5, step = 1, leftIcon = RIcon})
	
	self.Menu:MenuElement({id = "Lasthit", name = "Lasthit", type = MENU})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Lasthit:MenuElement({id = "UseE", name = "E", value = true, leftIcon = EIcon})
	self.Menu.Lasthit:MenuElement({id = "lasthitActive", name = "Lasthit key", key = string.byte("X")})
	
	self.Menu:MenuElement({id = "Flee", name = "Flee", type = MENU})
	self.Menu.Flee:MenuElement({id = "UseE", name = "E on minions/gapclose", value = true, leftIcon = EIcon})
	self.Menu.Flee:MenuElement({id = "fleeActive", name = "Flee key", key = string.byte("T")})
	
	self.Menu:MenuElement({id = "Killsteal", name = "Killsteal", type = MENU})
	self.Menu.Killsteal:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.Killsteal:MenuElement({id = "UseQ3", name = "Q3", value = true, leftIcon = Q3Icon})
	self.Menu.Killsteal:MenuElement({id = "UseE", name = "E (OP!)", value = true, leftIcon = EIcon})
	
	self.Menu.Killsteal:MenuElement({id = "RR", name = "Use R on", value = true, type = MENU, leftIcon = RIcon})
	for i, hero in pairs(self:GetEnemyHeroes()) do
	self.Menu.Killsteal.RR:MenuElement({id = "UseR"..hero.charName, name = "Use R on: "..hero.charName, value = true, leftIcon = RIcon})
	end
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "When the game starts, wait 30 secs and reload"})
	self.Menu.Killsteal:MenuElement({id = "blank", type = SPACE , name = "EXT so it can actually load the enemies here."})

	self.Menu:MenuElement({id = "isCC", name = "CC Settings", type = MENU})
	self.Menu.isCC:MenuElement({id = "UseQ", name = "Q", value = true, leftIcon = QIcon})
	self.Menu.isCC:MenuElement({id = "UseQ3", name = "Q3", value = true, leftIcon = Q3Icon})
	
    self.Menu:MenuElement({type = MENU, name = "Windwall",  id = "Windwall"})
        		self.Menu.Windwall:MenuElement({id = "Enable", name = "Enabled", value = true})
        		self.Menu.Windwall:MenuElement({type = MENU, id = "DetectedSpells", name = "Spells"})
        			self.Menu.Windwall.DetectedSpells:MenuElement({id = "info", name = "Detecting Spells, Please Wait...", drop = {" "}})
        				do
        					local Delay = Game.Timer() > 10 and 0 or 10 - Game.Timer()
						local Added = false
						DelayAction(function()
        						for i, enemy in pairs(Yasuo:WGetEnemyHeroes()) do
        							if Yasuo.SpellData[enemy.charName] then
        								for i, v in pairs(Yasuo.SpellData[enemy.charName]) do
        									if enemy and v then
        										local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]
        										self.Menu.Windwall.DetectedSpells:MenuElement({type = MENU, id = v.name, name = enemy.charName.." | "..SlotToStr.." | "..v.name, value = true})
        										self.Menu.Windwall.DetectedSpells[v.name]:MenuElement({id = "Use", name = "Enabled", value = true})
        										Added = true
        									end
        								end
        							end
        						end
        					self.Menu.Windwall.DetectedSpells.info:Remove()
        					if not Added then
        						self.Menu.Windwall.DetectedSpells:MenuElement({id = "info", name = "No Spells Detected", drop = {" "}})
        					end
        					end, Delay)
        				end
	
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
	self.Menu.Drawings:MenuElement({id = "R", name = "Draw R range", type = MENU, leftIcon = WIcon})
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

function Yasuo:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.Harass.harassActive:Value() then
		self:Harass()
	end
	if self.Menu.Flee.fleeActive:Value() then
		self:Flee()
	end
	if self.Menu.Windwall.Enable:Value() then
		self:Windwall()
	end
	if self.Menu.Combo.comboActive:Value() then
		self:Combo()
	end
	if self.Menu.Clear.clearActive:Value() and self:CanCast(_Q) then
		self:Clear()
		self:ClearQ3()
	end
	if self.Menu.Lasthit.lasthitActive:Value() then
		self:Lasthit()
	end
		self:KillstealQ()
		self:KillstealQ3()
		self:KillstealE()
		self:SpellonCCQ3()
		self:AutoRX()
		self:RksKnockedUp()
end

function Yasuo:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Yasuo:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

-- All credits to Shulepin from the Windwall.

function Yasuo:Windwall()
		for i = 1, Game.MissileCount() do
			local spell = nil
			local obj = Game.Missile(i)
			local data = obj.missileData
			local source = Yasuo:GetHeroByHandle(data.owner)
			if source then 
				if Yasuo.SpellData[source.charName] then
					spell = Yasuo.SpellData[source.charName][data.name:lower()]
				end
				if spell and not spell.isSkillshot and data.target == myHero.handle then
					if self.Menu.Windwall.DetectedSpells[spell.name].Use:Value() then
					Control.CastSpell(HK_W, obj.pos)
					return
					end
				end
				if spell and spell.isSkillshot and obj.isEnemy and data.speed and data.width and data.endPos and obj.pos then
					if self.Menu.Windwall.DetectedSpells[spell.name].Use:Value() then
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
		["Kogmaw"] = {
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

function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function Yasuo:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Yasuo:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Yasuo:CanCast(spellSlot)
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

function Yasuo:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 475 then
        return true
        end
    	end
    	return false
end

function Yasuo:GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
	end
end

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

function Yasuo:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Yasuo:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Yasuo:dashpos(unit)
	return myHero.pos + (unit.pos - myHero.pos):Normalized() * 600
	end
-----------------------------
-- DRAWINGS
-----------------------------

function Yasuo:Draw()
if self.Menu.Drawings.Q.Enabled:Value() then Draw.Circle(myHero.pos, 900, self.Menu.Drawings.Q.Width:Value(), self.Menu.Drawings.Q.Color:Value()) end
if self.Menu.Drawings.E.Enabled:Value() then Draw.Circle(myHero.pos, 475, self.Menu.Drawings.E.Width:Value(), self.Menu.Drawings.E.Color:Value()) end
if self.Menu.Drawings.R.Enabled:Value() then Draw.Circle(myHero.pos, 1200, self.Menu.Drawings.R.Width:Value(), self.Menu.Drawings.R.Color:Value()) end
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

function Yasuo:CastSpell(spell,pos)
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

function Yasuo:HpPred(unit, delay)
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
			if hero.isEnemy and hero.alive and GetDistanceSqr(myHero.pos, hero.pos) <= rangeSqr then
			if Yasuo:IsKnockedUp(hero)then
			count = count + 1
    end
  end
end
return count
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


function Yasuo:AutoRX()
		if self:CanCast(_R) and self.Menu.AutoR.AutoRXEnable:Value() then
		if Yasuo:CountKnockedUpEnemies(1400) >= self.Menu.AutoR.AutoRX:Value() then
		Control.CastSpell(HK_R)
end
end
end

-----------------------------
-- Flee
-----------------------------
function Yasuo:Flee()
	if self:CanCast(_E) then
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
			if Yasuo:ValidTarget(minion, 475) then
				local rato = Yasuo:GetDistance(myHero.pos, mousePos)
				local jogador = Yasuo:GetDistance(Yasuo:dashpos(minion), mousePos)
				local enemigo = Yasuo:GetDistance(Yasuo:dashpos(minion), myHero.pos)
				if jogador < rato and enemigo < perto and not HasBuff(minion, "YasuoDashWrapper") then
					gebest = minion
					perto = enemigo
				end
			end
		end
		return gebest
	end
	
	function Yasuo:GetDistance(p1, p2)
	local p2 = p2 or myHero.pos
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

function Yasuo:GetDistance2D(p1, p2)
	local p2 = p2 or myHero.pos
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end


function Yasuo:GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHero.pos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx * dx + dz * dz

end

-----------------------------
-- COMBO
-----------------------------

function Yasuo:Combo()
    local target = CurrentTarget(900)
    if target == nil then return end
    if self.Menu.Combo.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,castpos)
		    else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
	
	if self.Menu.Combo.UseE:Value() and self:CanCast(_E) and myHero.pos:DistanceTo(target.pos) < 2000 and self.Menu.Combo.comboActive:Value() and not HasBuff(myHero, "YasuoQ3W") then		
	self:Flee()
	end
	
	local target = CurrentTarget(475)
    if target == nil then return end
	    if self.Menu.Combo.UseE:Value() and target and self:CanCast(_E) and not HasBuff(target, "YasuoDashWrapper") then
	    if self:EnemyInRange(475) then
			Control.CastSpell(HK_E,target)
		end
	end
end

-----------------------------
-- HARASS
-----------------------------

function Yasuo:Harass()
    local target = CurrentTarget(900)
    if target == nil then return end
    if self.Menu.Harass.UseQ:Value() and target and self:CanCast(_Q) then
	    if self:EnemyInRange(475) then
		    local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range ,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		    if (HitChance > 0 ) then
			    Control.CastSpell(HK_Q,target)
				else if myHero.pos:DistanceTo(target.pos) < 900 and HasBuff(myHero, "YasuoQ3W") then
			    Control.CastSpell(HK_Q,castpos)
		    end
	    end
    end
    end

end

-----------------------------
-- Clear
-----------------------------

function Yasuo:Clear()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if minion and minion.team == 300 or minion.team ~= myHero.team then
		if self:CanCast(_Q) then 
			if self.Menu.Clear.UseQ:Value() and minion then
				if Yasuo:ValidTarget(minion, 475) and myHero.pos:DistanceTo(minion.pos) < 475 and not HasBuff(myHero, "YasuoQ3W") then
					Control.CastSpell(HK_Q, minion)
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
		if self:CanCast(_Q) then 
			if self.Menu.Clear.UseQ:Value() and minion then
				if Yasuo:ValidTarget(minion, 900) and myHero.pos:DistanceTo(minion.pos) < 900 and HasBuff(myHero, "YasuoQ3W") and minion:GetCollision(90, 1600, 0.10) - 1 >= self.Menu.Clear.Q3Clear:Value() then
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

function Yasuo:Lasthit()
	if self:CanCast(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
			if myHero.pos:DistanceTo(minion.pos) < 475 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy then
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
			local Edamage = (({60,70,80,90,100})[level] + 0.2 * myHero.totalDamage)
			if minion.pos:DistanceTo(myHero.AttackRange) < 475 and self.Menu.Lasthit.UseE:Value() and minion.isEnemy and not HasBuff(minion, "YasuoDashWrapper") then
				if Edamage >= minion.health and self:CanCast(_E) then
				Control.CastSpell(HK_E,minion.pos)
				end
			end
		end
	end
end

-----------------------------
-- KILLSTEAL
-----------------------------

function Yasuo:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({20,45,70,95,120})[level] + 1.0 * myHero.totalDamage)
	return qdamage
end

function Yasuo:EDMG()
    local level = myHero:GetSpellData(_E).level
    local edamage = (({55,65,75,85,90})[level] + 0.2 * myHero.totalDamage)
	return edamage
end

function Yasuo:RDMG()
    local level = myHero:GetSpellData(_R).level
    local rdamage = (({100, 200, 350})[level] + 1.5 * myHero.totalDamage)
	return rdamage
end

function Yasuo:ValidTarget(unit,range)
	local range = type(range) == "number" and range or math.huge
	return unit and unit.team ~= myHero.team and unit.valid and unit.distance <= range and not unit.dead and unit.isTargetable and unit.visible
end
-----------------------------
-- Q KS
-----------------------------
function Yasuo:KillstealQ()
	local target = CurrentTarget(Q.Range)
	if target == nil then return end
	if self.Menu.Killsteal.UseQ:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Yasuo:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 then
			if (HitChance > 0 ) and self:CanCast(_Q) then
			    Control.CastSpell(HK_Q,castpos)
				else if self:EnemyInRange(900) then 
				if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "YasuoQ3W") then
				Control.CastSpell(HK_Q,castpos)
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
	if self.Menu.Killsteal.UseQ3:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(Q3.Range) then 
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, 900, Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
		   	local Qdamage = Yasuo:QDMG()
			if Qdamage >= self:HpPred(target,1) + target.hpRegen * 1 and HasBuff(myHero, "YasuoQ3W") then
			if (HitChance > 0 ) and self:CanCast(_Q) then
			    Control.CastSpell(HK_Q,castpos)

				end
			end
		end
	end
	end

	function Yasuo:KillstealE()
	local target = CurrentTarget(475)
	if target == nil then return end
	if self.Menu.Killsteal.UseE:Value() and target and self:CanCast(_E) then
		if self:EnemyInRange(475) then 
			local level = myHero:GetSpellData(_E).level	
		   	local Edamage = Yasuo:EDMG()
			if Edamage >= self:HpPred(target,1) + target.hpRegen * 1 and not HasBuff(target, "YasuoDashWrapper") then
			    Control.CastSpell(HK_E,target)
				end
			end
		end
	end

-----------------------------
-- Q3 Spell on CC
-----------------------------

function Yasuo:SpellonCCQ3()
    local target = CurrentTarget(900)
	if target == nil then return end
	if self.Menu.isCC.UseQ3:Value() and target and self:CanCast(_Q) then
		if self:EnemyInRange(900) then 
			local ImmobileEnemy = self:IsImmobileTarget(target)
			local level = myHero:GetSpellData(_Q).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, Q.Delay , Q.Width, Q.Range,Q.Speed, myHero.pos, Q.ignorecol, Q.Type )
			if ImmobileEnemy then
			if (HitChance > 0 ) and HasBuff(myHero, "YasuoQ3W") then
			    Control.CastSpell(HK_Q,castpos)
				end
			end
		end
	end
end

-----------------------------
-- R KS on CC
-----------------------------

function Yasuo:RksKnockedUp()
    local target = CurrentTarget(1200)
	if target == nil then return end
	if self.Menu.Killsteal.RR["UseR"..target.charName]:Value() and self:CanCast(_R) then
		if self:EnemyInRange(1200) then 
			local ImmobileEnemy = self:IsKnockedUp(target)
			local level = myHero:GetSpellData(_R).level	
			local castpos,HitChance, pos = TPred:GetBestCastPosition(target, R.Delay , R.Width, R.Range,R.Speed, myHero.pos, R.ignorecol, R.Type )
		 	local Rdamage = Yasuo:RDMG()
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

function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

Callback.Add("Load",function() _G[myHero.charName]() end)