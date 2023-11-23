---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Character = Lua.import('Module:Infobox/Character', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local BreakDown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomCharacter = Class.new()
local CustomInjector = Class.new(Injector)

local NON_BREAKING_SPACE = '&nbsp;'
local NEUTRAL = 'Neutral'
local ATTRIBUTES = {
	str = 'Strength',
	agi = 'Agility',
	int = 'Intelligence',
}
local ATTRIBUTE_ICONS = {
	strength = '[[File:Infocard-heroattributes-str.png|link=Strength]]',
	agility = '[[File:Infocard-heroattributes-agi.png|link=Agility]]',
	intelligence = '[[File:Infocard-heroattributes-int.png|link=Intelligence]]',
	damage = '[[File:Infocard-neutral-attack-hero.png|alt=Damage|link=Physical Damage]]',
	armor = '[[File:Infocard-armor-hero.png|alt=Armor|link=Armor]]',
	speed = '[[File:Movespeed_Icon.png|alt=Movespeed|link=Movement Speed]]',
}
ATTRIBUTE_ICONS.movespeed = ATTRIBUTE_ICONS.speed
ATTRIBUTE_ICONS['movement speed'] = ATTRIBUTE_ICONS.speed
local LEVEL_CHANGE_CLASSES = {
	content1 = {'infobox-description'},
	content2 = {'infobox-center'},
	content3 = {'infobox-center'},
	content4 = {'infobox-center'},
}
local HP_REGEN_BLIGHT = 'blight'
local HP_REGEN_NIGHT = 'night'
local FACTION_TO_HP_REGEN_TYPE = {u = HP_REGEN_BLIGHT, n = HP_REGEN_NIGHT}
local DEFAULT_HP_REGEN_TITLE = '[[Hit_Points#Hit_Points_Gain|HP <abbr title=Regeneration>Regen.</abbr>]]:'

local _args

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = Character(frame)
	_args = character.args

	character.createWidgetInjector = CustomCharacter.createWidgetInjector
	character.defineCustomPageVariables = CustomCharacter.defineCustomPageVariables
	character.getWikiCategories = CustomCharacter.getWikiCategories
	character.nameDisplay = CustomCharacter.nameDisplay
	character.addToLpdb = CustomCharacter.addToLpdb

	return character:createInfobox(frame)
end

---@return WidgetInjector
function CustomCharacter:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.append(widgets,
		Title{name = 'Attributes'},
		BreakDown{content = {
			CustomCharacter._basicAttribute('str'),
			CustomCharacter._basicAttribute('agi'),
			CustomCharacter._basicAttribute('int'),
		}, classes = {'infobox-center'}},
		BreakDown{content = {
			CustomCharacter._getDamageAttribute(),
			CustomCharacter._getArmorAttribute(),
			CustomCharacter._getPrimaryAttribute(),
		}, classes = {'infobox-center'}},
		Title{name = 'Base Stats'},
		Cell{name = '[[Movement Speed]]', content = {_args.basespeed}},
		Cell{name = '[[Sight Range]]', content = {_args.sightrange or (
			Abbreviation.make(_args.daysight or 1800, 'Day') .. ' / ' .. Abbreviation.make(_args.nightsight or 800, 'Night')
		)}},
		Cell{name = '[[Attack Range]]', content = {_args.attackrange}},
		Cell{name = 'Missile Speed', content = {_args.missilespeed}},
		Cell{name = 'Attack Duration', content = {_args.attackduration}},
		Cell{name = 'Base Attack Time', content = {_args.attacktime}},
		Cell{name = 'Turn Rate', content = {_args.turnrate}},
		Cell{name = 'Hotkey', content = {Hotkeys.hotkey(_args.hotkey)}},
		_args.icon and Title{name = 'Icon'} or nil,
		Center{content = {CustomCharacter._displayIcon()}},
		Title{name = 'Level Changes'},
		BreakDown{content = {'[[Experience|Level]]:', 1, 5, 10}, contentClasses = LEVEL_CHANGE_CLASSES},
		BreakDown(CustomCharacter._toLevelChangesRow(
			CustomCharacter._calculateHitPoints, CustomCharacter._hitPointsRegenTitle())),
		BreakDown(CustomCharacter._toLevelChangesRow(CustomCharacter._calculateHitPointsRegen, '[[Hit Points]]:')),
		BreakDown(CustomCharacter._toLevelChangesRow(CustomCharacter._calculateMana, '[[Mana]]:')),
		BreakDown(CustomCharacter._toLevelChangesRow(
			CustomCharacter._calculateManaRegen, '[[Mana#Mana_Gain|Mana <abbr title=Regeneration>Regen.</abbr>]]:')),
		BreakDown(CustomCharacter._toLevelChangesRow(
			function(gainFactor) return CustomCharacter._calculateArmor(gainFactor, true) end, '[[Armor]]:')),
		BreakDown(CustomCharacter._toLevelChangesRow(CustomCharacter._calculateDamage, '[[Attack Damage|Damage]]:')),
		BreakDown(CustomCharacter._toLevelChangesRow(function(gainFactor)
			return Math.round(CustomCharacter._calculateCooldown(gainFactor), 2) end, '[[Attack Speed|Cooldown]]:'))
	)
end

---@param attribute string
---@return string
function CustomCharacter._basicAttribute(attribute)
	return ATTRIBUTE_ICONS[ATTRIBUTES[attribute]:lower()]
		.. '<br><b>' .. (_args['base' .. attribute] or '') .. '</b>'
		.. ' +' .. (_args[attribute .. 'gain'] or '')
end

---@return string
function CustomCharacter._getDamageAttribute()
	local mainAttribute = _args.mainattribute

	local minimumDamage = (tonumber(_args['base' .. mainAttribute]) or 0)
		+ (tonumber(_args.numdice) or 2)
		+ (tonumber(_args.basedamage) or 0)

	local maximumDamage = (tonumber(_args['base' .. mainAttribute]) or 0)
		+ (tonumber(_args.numdice) or 2) * (tonumber(_args.sidesdie) or 0)
		+ (tonumber(_args.basedamage) or 0)

	return ATTRIBUTE_ICONS.damage
		.. '<br>' .. minimumDamage .. ' - ' .. maximumDamage
end

---@return string
function CustomCharacter._getArmorAttribute()
	local armorValue = (tonumber(_args.baseagi) or 0) * 0.3
		- 2 + (tonumber(_args.basearmor) or 0)

	return ATTRIBUTE_ICONS.armor
		.. '<br>' .. Abbreviation.make(Math.round(armorValue, 0), armorValue)
end

---@return string
function CustomCharacter._getPrimaryAttribute()
	return ATTRIBUTE_ICONS[ATTRIBUTES[_args.mainattribute]:lower()] .. '<br>Primary Attribute'
end

---@return string
function CustomCharacter._displayIcon()
	local keyToDisplay = function(key)
		return _args[key] and ('[[File:Wc3BTN' .. _args[key] .. '.png]]') or ''
	end

	return keyToDisplay('icon') .. keyToDisplay('icon2')
end

---@param gainFactor number
---@return number
function CustomCharacter._calculateHitPoints(gainFactor)
	local gain = math.floor((tonumber(_args.strgain) or 0) * gainFactor)
	return (gain + (tonumber(_args.basestr) or 0)) * 25 + (tonumber(_args.basehp) or 100)
end

---@param gainFactor number
---@return number
function CustomCharacter._calculateMana(gainFactor)
	local gain = math.floor((tonumber(_args.intgain) or 0) * gainFactor)
	return (gain + (tonumber(_args.baseint) or 0)) * 15
end

---@param gainFactor number
---@return number
function CustomCharacter._calculateManaRegen(gainFactor)
	local gain = math.floor((tonumber(_args.intgain) or 0) * gainFactor)
	return (gain + (tonumber(_args.baseint) or 0)) * 0.05 + 0.01
end

---@param gainFactor number
---@param abbreviate boolean?
---@return string|number|nil
function CustomCharacter._calculateArmor(gainFactor, abbreviate)
	local gain = math.floor((tonumber(_args.agigain) or 0) * gainFactor)
	local armor = (gain + (tonumber(_args.baseagi) or 0)) * 0.3
		- 2 + (tonumber(_args.basearmor) or 0)

	if abbreviate then
		return Abbreviation.make(Math.round(armor, 0), armor)
	end

	return armor
end

---@param gainFactor number
---@return string
function CustomCharacter._calculateDamage(gainFactor)
	local gain = math.floor((tonumber(_args[_args.mainattribute .. 'gain']) or 0) * gainFactor)

	return (CustomCharacter._baseMinimumDamage() + gain) .. ' - ' .. (CustomCharacter._baseMaximumDamage() + gain)
end

---@return number
function CustomCharacter._baseMinimumDamage()
	return (tonumber(_args['base' .. _args.mainattribute]) or 0)
		+ (tonumber(_args.basedamage) or 0)
		+ (tonumber(_args.numdice) or 2)
end

---@return number
function CustomCharacter._baseMaximumDamage()
	return (tonumber(_args['base' .. _args.mainattribute]) or 0)
		+ (tonumber(_args.basedamage) or 0)
		+ (tonumber(_args.numdice) or 2) * (tonumber(_args.sidesdie) or 1)
end

---@param gainFactor number
---@return number
function CustomCharacter._calculateCooldown(gainFactor)
	local gain = math.floor((tonumber(_args.agigain) or 0) * gainFactor)
	return (tonumber(_args.basecd) or 0) / (1 + (gain + (tonumber(_args.baseagi) or 0)) * 0.02)
end

---@return string
function CustomCharacter._hitPointsRegenTitle()
	local hpRegenType = CustomCharacter._hitPointsRegenType()

	if hpRegenType == HP_REGEN_BLIGHT then
		return DEFAULT_HP_REGEN_TITLE .. ' (+2.00 on Blight)'
	elseif hpRegenType == HP_REGEN_NIGHT then
		return DEFAULT_HP_REGEN_TITLE .. ' (+0.50 at Night)'
	end

	return DEFAULT_HP_REGEN_TITLE
end

---@param gainFactor number
---@return number
function CustomCharacter._calculateHitPointsRegen(gainFactor)
	local hpRegenType = CustomCharacter._hitPointsRegenType()
	local gain = math.floor((tonumber(_args.strgain) or 0) * gainFactor)
	local baseHpRegen = (gain + (tonumber(_args.basestr) or 0)) * 0.05

	if hpRegenType == HP_REGEN_BLIGHT or hpRegenType == HP_REGEN_BLIGHT then
		return baseHpRegen
	end

	return baseHpRegen + 0.25
end

---@return string
function CustomCharacter._hitPointsRegenType()
	return _args.hpregentype or FACTION_TO_HP_REGEN_TYPE[Faction.read(_args.race)]
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	local character = args.informationType
	local faction = Faction.toName(Faction.read(args.race)) or NEUTRAL

	local attribute = ATTRIBUTES[args.mainattribute]
	if not attribute then
		return {faction .. ' ' .. character}
	end

	return {faction .. ' ' .. character, attribute .. ' ' .. character}
end

---@param args table
---@return string
function CustomCharacter:nameDisplay(args)
	local factionIcon = Faction.Icon{faction = Faction.read(args.race)}

	return (factionIcon and (factionIcon .. NON_BREAKING_SPACE) or '') .. self.name
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	return {
		type = 'hero',
		name = self.pagename,
		image = args.icon and ('Wc3BTN' .. args.icon .. '.png') or nil,
		information = Faction.toName(Faction.read(args.race)) or 'Neutral',
		extradata = {
			['primary attribute'] = ATTRIBUTES[args.mainattribute],
			baseint = args.baseint,
			intgain = args.intgain,
			baseagi = args.baseagi,
			agigain = args.agigain,
			basestr = args.basestr,
			strgain = args.strgain,
			basehp = args.basehp or 100,
			basearmor = args.basearmor or 0,
			numdice = args.numdice,
			sidesdie = args.sidesdie,
			basecd = args.basecd,
			race = Faction.read(args.race),
			dps = CustomCharacter._calculateDps(args),
			ehp = CustomCharacter._calculateEhp(args),
		}
	}
end

---@param args table
---@return number[]
function CustomCharacter._calculateDps(args)
	local baseAverageDamage = (CustomCharacter._baseMinimumDamage() + CustomCharacter._baseMaximumDamage()) / 2
	local baseGain = tonumber(args[args.mainattribute .. 'gain']) or 0

	local toDps = function(gainFactor)
		return (baseAverageDamage + math.floor(gainFactor * baseGain)) / CustomCharacter._calculateCooldown(gainFactor)
	end

	return {toDps(0), toDps(2), toDps(4), toDps(9)}
end

---@param args table
---@return number[]
function CustomCharacter._calculateEhp(args)
	local toEhp = function(gainFactor)
		return Math.round(
			CustomCharacter._calculateHitPoints(gainFactor) * (1 + 0.06 * CustomCharacter._calculateArmor(gainFactor)),
			0
		)
	end

	return {toEhp(0), toEhp(4), toEhp(9)}
end

---@param funct fun(num:number): number|string|nil
---@param title string
---@return {content: table, contentClasses: table}}
function CustomCharacter._toLevelChangesRow(funct, title)
	return {content = {title, funct(0), funct(4), funct(9)}, contentClasses = LEVEL_CHANGE_CLASSES}
end

return CustomCharacter
