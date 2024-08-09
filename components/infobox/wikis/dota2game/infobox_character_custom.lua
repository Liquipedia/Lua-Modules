---
-- @Liquipedia
-- wiki=dota2game
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')

local GameValues = require('Module:Attribute bonuses')._main
local Symbols = require('Module:Symbol')._main

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Header = Widgets.Header
local Title = Widgets.Title

---@class Dota2CharacterInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

local ATTRIBUTE_ICONS = {
	strength = Symbols{'strength', size = '35px'},
	agility = Symbols{'agility', size = '35px'},
	intelligence = Symbols{'intelligence', size = '35px'},
	universal = Symbols{'universal', size = '35px'},
}

local TIME_ICONS = {
	day = '<span title="Daytime" class="fas fa-sun" style="font-size:12px"></span>',
	night = '<span title="Nighttime" class="fas fa-moon" style="font-size:12px;"></span>',
}

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local character = CustomHero(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Hero'
	character.args.image = character.args.image or character.args.name .. ' Large.png'
	character.args.title = ATTRIBUTE_ICONS[string.lower(character.args.primary)] .. ' ' .. string.upper(character.args.primary)

	character.args.hpbase = character.args.hpbase or GameValues{'health'}
	character.args.hpregen = character.args.hpregen or GameValues{'health regen'}
	character.args.mpbase = character.args.mpbase or GameValues{'mana'}
	character.args.mpregen = character.args.mpregen or GameValues{'mana regen'}
	character.args.atkmin = character.args.atkmin or GameValues{'attack damage min'}
	character.args.atkmax = character.args.atkmax or GameValues{'attack damage max'}
	character.args.armor = character.args.armor or GameValues{'armor'}
	character.args.mr = character.args.mr or GameValues{'magic resistance'}
	character.args.bat = character.args.bat or GameValues{'base attack time'}
	character.args.visionday = character.args.visionday or GameValues{'vision day'}
	character.args.visionnight = character.args.visionnight or GameValues{'vision night'}
	character.args['turn rate'] = character.args['turn rate'] or GameValues{'turn rate'}

	character.args.strbase = character.args.strbase or 0
	character.args.agibase = character.args.agibase or 0
	character.args.intbase = character.args.intbase or 0

	local param = CustomHero.shortenPrimary(character.args.primary)
	character.args.primarybase = character.args[param .. 'base']
	character.args.primarygain = character.args[param .. 'gain']

	if param == 'uni' then
		character.args.primarybase = (character.args.strbase + character.args.agibase + character.args.intbase) * GameValues{'bonus universal damage'}
		character.args.primarygain = (character.args.strgain + character.args.agigain + character.args.intgain) * GameValues{'bonus universal damage'}
	end

	return character:createInfobox()
end

---@param primary string
---@return string
function CustomHero.shortenPrimary(primary)
	local normPrimary = primary:lower()
	if normPrimary == 'strength' then
		return 'str'
	elseif normPrimary == 'agility' then
		return 'agi'
	elseif normPrimary == 'intelligence' then
		return 'int'
	elseif normPrimary == 'universal' then
		return 'uni'
	else
		error('Unknown Primary')
	end
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		local primaryAttr = CustomHero.shortenPrimary(args.primary)
		local primaryIdx = primaryAttr == 'str' and 1 or primaryAttr == 'agi' and 2 or primaryAttr == 'int' and 3 or 0

		local function calculateHealth(level, bonus)
			return CustomHero.calculateStats(level, args.hpbase, args.strbase, args.strgain, bonus, 'bonus health')
		end

		local function calculateHealthRegen(level, bonus)
			return CustomHero.calculateStats(level, args.hpregen, args.strbase, args.strgain, bonus, 'bonus health regeneration flat')
		end

		local function calculateMana(level, bonus)
			return CustomHero.calculateStats(level, args.mpbase, args.intbase, args.intgain, bonus, 'bonus mana')
		end

		local function calculateManaRegen(level, bonus)
			return CustomHero.calculateStats(level, args.mpregen, args.intbase, args.intgain, bonus, 'bonus mana regeneration flat')
		end

		local function calculateArmor(level, bonus)
			return Math.round(CustomHero.calculateStats(level, args.armor, args.agibase, args.agigain, bonus, 'bonus armor'), 2)
		end

		local function calculateMagicRestistance(level, bonus)
			return Math.round(CustomHero.calculateStats(level, args.mr, args.intbase, args.intgain, bonus, 'bonus magic resistance'), 2)
		end

		local function calculateDamageMin(level)
			return CustomHero.calculateStats(level, args.atkmin, args.primarybase, args.primarygain, 0)
		end

		local function calculateDamageMax(level)
			return CustomHero.calculateStats(level, args.atkmax, args.primarybase, args.primarygain, 0)
		end

		Array.appendWith(
			widgets,
			-- Level Header
			Breakdown{content = {
				'<b>Hero Level</b>',
				'1', -- TODO Icon
				-- width: 48px;height: 48px;border-radius: 999px;background: #000;display: table-cell;vertical-align: middle;font-size: 200%;color: #e6d292;font-weight: bold;box-shadow: inset 0px 0px 2px 1px #aaa;
  				'15', -- TODO Icon
  				'25', -- TODO Icon
  				'30', -- TODO Icon
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}},

			-- Health Bar
			Breakdown{content = {
				'<b>Health</b>',
				calculateHealth(1, 0) .. '<br>+' .. calculateHealthRegen(1, 0),
				calculateHealth(15, 0) .. '<br>+' .. calculateHealthRegen(15, 0),
				calculateHealth(25, 12) .. '<br>+' .. calculateHealthRegen(25, 12),
				calculateHealth(30, 14) .. '<br>+' .. calculateHealthRegen(30, 14),
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}, rowClasses = {'healthbar'}},

			-- Mana Bar
			Breakdown{content = {
				'<b>Mana</b>',
				calculateMana(1, 0) .. '<br>+' .. calculateManaRegen(1, 0),
				calculateMana(15, 0) .. '<br>+' .. calculateManaRegen(15, 0),
				calculateMana(25, 12) .. '<br>+' .. calculateManaRegen(25, 12),
				calculateMana(30, 14) .. '<br>+' .. calculateManaRegen(30, 14),
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}, rowClasses = {'manabar'}},

			-- Armor
			Breakdown{content = {
				'<b>Armor</b><br>&nbsp;',
				calculateArmor(1, 0),
				calculateArmor(15, 0),
				calculateArmor(25, 12),
				calculateArmor(30, 14),
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}},

			-- Magic Restistance
			Breakdown{content = {
				'<b>Magic resistance</b>',
				calculateMagicRestistance(1, 0),
				calculateMagicRestistance(15, 0),
				calculateMagicRestistance(25, 12),
				calculateMagicRestistance(30, 14),
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}},

			-- Damage
			Breakdown{content = {
				'<b>Damage</b>',
				calculateDamageMin(1) .. '<br>' ..  calculateDamageMax(1),
				calculateDamageMin(15) .. '<br>' ..  calculateDamageMax(15),
				calculateDamageMin(25) .. '<br>' ..  calculateDamageMax(25),
				calculateDamageMin(30) .. '<br>' ..  calculateDamageMax(30),
			}, contentClasses = {content2 = {'infobox-center'}, content3 = {'infobox-center'}, content4 = {'infobox-center'}, content5 = {'infobox-center'}}},

			-- Attribute Gain
			Breakdown{content = {
				ATTRIBUTE_ICONS.strength .. '<br><b>' .. args.strbase .. '</b> +' .. args.strgain,
  				ATTRIBUTE_ICONS.agility .. '<br><b>' .. args.agibase .. '</b> +' .. args.agigain,
  				ATTRIBUTE_ICONS.intelligence .. '<br><b>' .. args.intbase .. '</b> +' .. args.intgain,
			}, classes = {'infobox-center'}, contentClasses = {['content' .. primaryIdx] = {'primaryAttribute'}}}
		)

		Array.appendWith(
			widgets,
			Title{name = 'ATTACK'},
			Cell{name = CustomHero.addIconToTitle('Attack type', 'ranged'), content = {args.rangetype}},
			Cell{name = CustomHero.addIconToTitle('Attack time', 'attack time'), content = {args.bat .. ' BAT'}},
			Cell{name = CustomHero.addIconToTitle('Attack range', 'attack range'), content = {args.atkrange}},
			Cell{name = CustomHero.addIconToTitle('Projectile speed', 'projectile speed'), content = {args['projectile speed']}}
		)

		Array.appendWith(
			widgets,
			Title{name = 'MOBILITY'},
			Cell{name = CustomHero.addIconToTitle('Movement speed', 'movement speed'), content = {TIME_ICONS.day .. ' ' .. args.movespeed, TIME_ICONS.night .. ' ' .. args.movespeed + GameValues{'nighttime speed bonus'} * GameValues{'nighttime bonus multiplier'}}}, -- TODO: Day/Night icon
			Cell{name = CustomHero.addIconToTitle('Turn rate', 'turn rate'), content = {args.turnrate}},
			Cell{name = CustomHero.addIconToTitle('Vision', 'vision'), content = {TIME_ICONS.day .. ' ' .. args.visionday, TIME_ICONS.night .. ' ' .. args.visionnight}}
		)

		Array.appendWith(
			widgets,
			Title{name = 'GENERAL'},
			Cell{name = 'Released', content = {args.released}},
			Cell{name = 'Internal Name', content = {'npc_dota_hero_' .. args.intern}}
		)

		return widgets
	elseif id == 'title' then
		return {}
	end

	return widgets
end

---@param level integer
---@param heroBase integer
---@param attributeBase integer
---@param attributeGain integer
---@param abbributeBonus integer
---@param modifierName string?
function CustomHero.calculateStats(level, heroBase, attributeBase, attributeGain, abbributeBonus, modifierName)
	local modifier = modifierName and GameValues{modifierName} or 1
	return heroBase + (attributeBase + (level - 1) * attributeGain + abbributeBonus) * modifier
end

---@param title string
---@param symbol string
---@return string
function CustomHero.addIconToTitle(title, symbol)
	return title .. ' ' .. Symbols{symbol, size = '20px'}
end

---@param args table
---@return string[]
function CustomHero:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.appendWith({'Heroes'},
		String.isNotEmpty(args.rangetype) and (args.rangetype .. ' Heroes') or nil,
		String.isNotEmpty(args.primary) and (args.primary .. ' Heroes') or nil
	)
end

---@param lpdbData table
---@param args table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.information = args.hid
	lpdbData.image = args.image
	lpdbData.date = args.released
	lpdbData.extradata = {
		name = args.name or '',
		game = args.game or '',
		hid = args.hid or '',
		intern = 'npc_dota_hero_' .. args.intern,
		icon = args.name .. 'icon.png',
		allstars = args.allstars, -- DotA Allstars release date.
		dotaver = args.dotaver or '',
		primary = args.primary or '',

		strbase = args.strbase or '',
		strgain = args.strgain or '',

		agibase = args.agibase or '',
		agigain = args.agigain or '',

		intbase = args.intbase or '',
		intgain = args.intgain or '',

		hpbase = args.hpbase,
		hpregen = args.hpregen,
		mpbase = args.mpbase,
		mpregen = args.mpregen,

		armor = args.armor,
		mr = args.mr,
		sr = args.sr or GameValues{'status resistance'},

		movespeed = args.movespeed or '',

		atkspeed = args.atkspeed or '',
		projectilespeed = args['projectile speed'] or args.rangetype == 'Melee' and GameValues{'melee projectile speed'},
		bat = args.bat,
		rangetype = args.rangetype or '',
		atkmin = args.atkmin or '',
		atkmax = args.atkmax or '',
		atkrange = args.atkrange or '',
		atkpoint = args.atkpoint or '',
		atkbacks = args.atkbacks or '',
		acquirange = args.acquirange or '',

		turnrate = args.turnrate,

		visionday = args.visionday,
		visionnight = args.visionnight,

		collisionsize = args.collisionsize,
		boundradius = args.boundradius or '',

		gibtype = args.gibtype or GameValues{'gib type'},
	}

	return lpdbData
end

return CustomHero
