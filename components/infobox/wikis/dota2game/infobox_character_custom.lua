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
local Title = Widgets.Title

---@class Dota2HeroInfobox: CharacterInfobox
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
	local shortPrimary = CustomHero.shortenPrimary(character.args.primary)

	character.args.informationType = 'Hero'
	character.args.image = character.args.image or character.args.name .. ' Large.png'
	character.args.imageText = '#' .. (character.args.hid or '')
	character.args.title = table.concat({
		ATTRIBUTE_ICONS[string.lower(character.args.primary)],
		string.upper(character.args.primary)
	}, ' ')

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

	if shortPrimary == 'uni' then
		character.args.primarybase =
			(character.args.strbase + character.args.agibase + character.args.intbase) * GameValues{'bonus universal damage'}
		character.args.primarygain =
			(character.args.strgain + character.args.agigain + character.args.intgain) * GameValues{'bonus universal damage'}
	else
		character.args.primarybase = character.args[shortPrimary .. 'base']
		character.args.primarygain = character.args[shortPrimary .. 'gain']
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

		local calculator = CustomHero.statsCalculator(args)

		local function floatToTheRight(mainInfo, rightInfo)
			return tostring(mw.html.create('div'):css('position', 'relative'):wikitext(mainInfo)
				:node(
					mw.html.create('div'):css('position', 'absolute'):css({right = '4px', top = '0px'}):wikitext(rightInfo)
				))
		end

		Array.appendWith(
			widgets,
			-- Health Bar
			Breakdown{
				content = {floatToTheRight(calculator.health(1), '+' .. calculator.healthRegen(1))},
				classes = {'infobox-center'}, rowClasses = {'healthbar'}
			},

			-- Mana Bar
			Breakdown{
				content = {floatToTheRight(calculator.mana(1), '+' .. calculator.manaRegen(1))},
				classes = {'infobox-center'}, rowClasses = {'manabar'}
			},

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
			Cell{name = CustomHero.addIconToTitle('Damage'), content = {
				calculator.damageMin(1) .. '-' .. calculator.damageMax(1)
			}},
			Cell{name = CustomHero.addIconToTitle('Attack Type', args.rangetype), content = {args.rangetype}},
			Cell{name = CustomHero.addIconToTitle('Attack Time'), content = {args.bat .. ' BAT'}},
			Cell{name = CustomHero.addIconToTitle('Attack Range'), content = {args.atkrange}},
			Cell{name = CustomHero.addIconToTitle('Projectile Speed'), content = {args['projectile speed']}}
		)

		Array.appendWith(
			widgets,
			Title{name = 'DEFENCE'},
			Cell{name = CustomHero.addIconToTitle('Armor'), content = {calculator.armor(1)}},
			Cell{name = CustomHero.addIconToTitle('Magic Resistance'), content = {calculator.magicRestistance(1)}}
		)

		Array.appendWith(
			widgets,
			Title{name = 'MOBILITY'},
			Cell{name = CustomHero.addIconToTitle('Turn Rate'), content = {args.turnrate}},
			Cell{name = CustomHero.addIconToTitle('Movement Speed'), content = CustomHero.dayNightContent(
				args.movespeed,
				args.movespeed + GameValues{'nighttime speed bonus'} * GameValues{'nighttime bonus multiplier'}
			)},
			Cell{name = CustomHero.addIconToTitle('Vision'), content = CustomHero.dayNightContent(
				args.visionday, args.visionnight
			)}
		)

		Array.appendWith(
			widgets,
			Title{name = 'GENERAL'},
			Cell{name = 'Released', content = {args.released}},
			Cell{name = 'Competitive Span', content = {args.compspan}},
			Cell{name = 'Internal Name', content = {args.intern and ('npc_dota_hero_' .. args.intern) or nil}}
		)

		return widgets
	elseif id == 'title' then
		return {}
	end

	return widgets
end

---@param args any
---@return {[string]: fun(level: integer): number}
function CustomHero.statsCalculator(args)
	local calculator = {}

	local function levelToBonus(level)
		local bonusLookup = {
			[17] = 2,
			[18] = 2,
			[19] = 4,
			[20] = 4,
			[21] = 6,
			[22] = 8,
			[23] = 10,
			[24] = 12,
			[25] = 12,
			[26] = 14,
			[27] = 14,
			[28] = 14,
			[29] = 14,
			[30] = 14,
		}
		return bonusLookup[level] or 0
	end

	function calculator.health(level)
		local bonus = levelToBonus(level)
		return CustomHero.calculateStats(
			level, args.hpbase, args.strbase, args.strgain, bonus, 'bonus health'
		)
	end

	function calculator.healthRegen(level)
		local bonus = levelToBonus(level)
		return CustomHero.calculateStats(
			level, args.hpregen, args.strbase, args.strgain, bonus, 'bonus health regeneration flat'
		)
	end

	function calculator.mana(level)
		local bonus = levelToBonus(level)
		return CustomHero.calculateStats(
			level, args.mpbase, args.intbase, args.intgain, bonus, 'bonus mana'
		)
	end

	function calculator.manaRegen(level)
		local bonus = levelToBonus(level)
		return CustomHero.calculateStats(
			level, args.mpregen, args.intbase, args.intgain, bonus, 'bonus mana regeneration flat'
		)
	end

	function calculator.armor(level)
		local bonus = levelToBonus(level)
		return Math.round(
			CustomHero.calculateStats(level, args.armor, args.agibase, args.agigain, bonus, 'bonus armor'),
			2
		)
	end

	function calculator.magicRestistance(level)
		local bonus = levelToBonus(level)
		return Math.round(
			CustomHero.calculateStats(level, args.mr, args.intbase, args.intgain, bonus, 'bonus magic resistance'),
			2
		)
	end

	function calculator.damageMin(level)
		return CustomHero.calculateStats(level, args.atkmin, args.primarybase, args.primarygain)
	end

	function calculator.damageMax(level)
		return CustomHero.calculateStats(level, args.atkmax, args.primarybase, args.primarygain)
	end

	return calculator
end

---@param level integer
---@param heroBase integer
---@param attributeBase integer
---@param attributeGain integer
---@param abbributeBonus integer?
---@param modifierName string?
function CustomHero.calculateStats(level, heroBase, attributeBase, attributeGain, abbributeBonus, modifierName)
	local modifier = modifierName and GameValues{modifierName} or 1
	local bonus = abbributeBonus or 0
	return heroBase + (attributeBase + (level - 1) * attributeGain + bonus) * modifier
end

---@param title string
---@param symbol string?
---@return string
function CustomHero.addIconToTitle(title, symbol)
	if not symbol then
		symbol = title:lower()
	end
	return title .. ' ' .. Symbols{symbol, size = '20px'}
end

---@param dayContent string|number
---@param nightContent string|number
---@return table
function CustomHero.dayNightContent(dayContent, nightContent)
	return {
		TIME_ICONS.day .. ' ' .. dayContent,
		TIME_ICONS.night .. ' ' .. nightContent,
	}
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
