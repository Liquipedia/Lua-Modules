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

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local BreakDown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
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

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))

	return character:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return Array.append(widgets,
			Title{children = 'Attributes'},
			BreakDown{children = {
				self.caller:_basicAttribute('str'),
				self.caller:_basicAttribute('agi'),
				self.caller:_basicAttribute('int'),
			}, classes = {'infobox-center'}},
			BreakDown{children = {
				self.caller:_getDamageAttribute(),
				self.caller:_getArmorAttribute(),
				self.caller:_getPrimaryAttribute(),
			}, classes = {'infobox-center'}},
			Title{children = 'Base Stats'},
			Cell{name = '[[Movement Speed]]', content = {args.basespeed}},
			Cell{name = '[[Sight Range]]', content = {args.sightrange or (
				Abbreviation.make{text = args.daysight or 1800, title = 'Day'} .. ' / ' ..
				Abbreviation.make{text = args.nightsight or 800, title = 'Night'}
			)}},
			Cell{name = '[[Attack Range]]', content = {args.attackrange}},
			Cell{name = 'Missile Speed', content = {args.missilespeed}},
			Cell{name = 'Attack Duration', content = {args.attackduration}},
			Cell{name = 'Base Attack Time', content = {args.attacktime}},
			Cell{name = 'Turn Rate', content = {args.turnrate}},
			Cell{name = 'Hotkey', content = {Hotkeys.hotkey{hotkey = args.hotkey}}},
			args.icon and Title{children = 'Icon'} or nil,
			Center{children = {self.caller:_displayIcon()}},
			Title{children = 'Level Changes'},
			BreakDown{children = {'[[Experience|Level]]:', 1, 5, 10}, contentClasses = LEVEL_CHANGE_CLASSES},
			BreakDown(CustomCharacter._toLevelChangesRow(
				function(gainFactor) return self.caller:_calculateHitPoints(gainFactor) end, '[[Hit Points]]:')),
			BreakDown(CustomCharacter._toLevelChangesRow(function(gainFactor)
				return self.caller:_calculateHitPointsRegen(gainFactor) end, self.caller:_hitPointsRegenTitle())),
			BreakDown(CustomCharacter._toLevelChangesRow(
				function(gainFactor) return self.caller:_calculateMana(gainFactor) end, '[[Mana]]:')),
			BreakDown(CustomCharacter._toLevelChangesRow(
				function(gainFactor) return self.caller:_calculateManaRegen(gainFactor) end,
				'[[Mana#Mana_Gain|Mana <abbr title=Regeneration>Regen.</abbr>]]:'
			)),
			BreakDown(CustomCharacter._toLevelChangesRow(
				function(gainFactor) return self.caller:_calculateArmor(gainFactor, true) end, '[[Armor]]:')),
			BreakDown(CustomCharacter._toLevelChangesRow(
				function(gainFactor) return self.caller:_calculateDamage(gainFactor) end, '[[Attack Damage|Damage]]:')),
			BreakDown(CustomCharacter._toLevelChangesRow(function(gainFactor)
				return Math.round(self.caller:_calculateCooldown(gainFactor), 2) end, '[[Attack Speed|Cooldown]]:'))
		)
	end

	return widgets
end

---@param attribute string
---@return string
function CustomCharacter:_basicAttribute(attribute)
	return ATTRIBUTE_ICONS[ATTRIBUTES[attribute]:lower()]
		.. '<br><b>' .. (self.args['base' .. attribute] or '') .. '</b>'
		.. ' +' .. (self.args[attribute .. 'gain'] or '')
end

---@return string
function CustomCharacter:_getDamageAttribute()
	local mainAttribute = self.args.mainattribute

	local minimumDamage = (tonumber(self.args['base' .. mainAttribute]) or 0)
		+ (tonumber(self.args.numdice) or 2)
		+ (tonumber(self.args.basedamage) or 0)

	local maximumDamage = (tonumber(self.args['base' .. mainAttribute]) or 0)
		+ (tonumber(self.args.numdice) or 2) * (tonumber(self.args.sidesdie) or 0)
		+ (tonumber(self.args.basedamage) or 0)

	return ATTRIBUTE_ICONS.damage
		.. '<br>' .. minimumDamage .. ' - ' .. maximumDamage
end

---@return string
function CustomCharacter:_getArmorAttribute()
	local armorValue = (tonumber(self.args.baseagi) or 0) * 0.3
		- 2 + (tonumber(self.args.basearmor) or 0)

	return ATTRIBUTE_ICONS.armor
		.. '<br>' .. Abbreviation.make{text = Math.round(armorValue, 0), title = armorValue}
end

---@return string
function CustomCharacter:_getPrimaryAttribute()
	return ATTRIBUTE_ICONS[ATTRIBUTES[self.args.mainattribute]:lower()] .. '<br>Primary Attribute'
end

---@return string
function CustomCharacter:_displayIcon()
	local keyToDisplay = function(key)
		return self.args[key] and ('[[File:Wc3BTN' .. self.args[key] .. '.png]]') or ''
	end

	return keyToDisplay('icon') .. keyToDisplay('icon2')
end

---@param gainFactor number
---@return number
function CustomCharacter:_calculateHitPoints(gainFactor)
	local gain = math.floor((tonumber(self.args.strgain) or 0) * gainFactor)
	return (gain + (tonumber(self.args.basestr) or 0)) * 25 + (tonumber(self.args.basehp) or 100)
end

---@param gainFactor number
---@return number
function CustomCharacter:_calculateMana(gainFactor)
	local gain = math.floor((tonumber(self.args.intgain) or 0) * gainFactor)
	return (gain + (tonumber(self.args.baseint) or 0)) * 15
end

---@param gainFactor number
---@return number
function CustomCharacter:_calculateManaRegen(gainFactor)
	local gain = math.floor((tonumber(self.args.intgain) or 0) * gainFactor)
	return (gain + (tonumber(self.args.baseint) or 0)) * 0.05 + 0.01
end

---@param gainFactor number
---@param abbreviate boolean?
---@return string|number|nil
function CustomCharacter:_calculateArmor(gainFactor, abbreviate)
	local gain = math.floor((tonumber(self.args.agigain) or 0) * gainFactor)
	local armor = (gain + (tonumber(self.args.baseagi) or 0)) * 0.3
		- 2 + (tonumber(self.args.basearmor) or 0)

	if abbreviate then
		return Abbreviation.make{text = Math.round(armor, 0), title = armor}
	end

	return armor
end

---@param gainFactor number
---@return string
function CustomCharacter:_calculateDamage(gainFactor)
	local gain = math.floor((tonumber(self.args[self.args.mainattribute .. 'gain']) or 0) * gainFactor)

	return (self:_baseMinimumDamage() + gain) .. ' - ' .. (self:_baseMaximumDamage() + gain)
end

---@return number
function CustomCharacter:_baseMinimumDamage()
	return (tonumber(self.args['base' .. self.args.mainattribute]) or 0)
		+ (tonumber(self.args.basedamage) or 0)
		+ (tonumber(self.args.numdice) or 2)
end

---@return number
function CustomCharacter:_baseMaximumDamage()
	return (tonumber(self.args['base' .. self.args.mainattribute]) or 0)
		+ (tonumber(self.args.basedamage) or 0)
		+ (tonumber(self.args.numdice) or 2) * (tonumber(self.args.sidesdie) or 1)
end

---@param gainFactor number
---@return number
function CustomCharacter:_calculateCooldown(gainFactor)
	local gain = math.floor((tonumber(self.args.agigain) or 0) * gainFactor)
	return (tonumber(self.args.basecd) or 0) / (1 + (gain + (tonumber(self.args.baseagi) or 0)) * 0.02)
end

---@return string
function CustomCharacter:_hitPointsRegenTitle()
	local hpRegenType = self:_hitPointsRegenType()

	if hpRegenType == HP_REGEN_BLIGHT then
		return DEFAULT_HP_REGEN_TITLE .. ' (+2.00 on Blight)'
	elseif hpRegenType == HP_REGEN_NIGHT then
		return DEFAULT_HP_REGEN_TITLE .. ' (+0.50 at Night)'
	end

	return DEFAULT_HP_REGEN_TITLE
end

---@param gainFactor number
---@return number
function CustomCharacter:_calculateHitPointsRegen(gainFactor)
	local hpRegenType = self:_hitPointsRegenType()
	local gain = math.floor((tonumber(self.args.strgain) or 0) * gainFactor)
	local baseHpRegen = (gain + (tonumber(self.args.basestr) or 0)) * 0.05

	if hpRegenType == HP_REGEN_BLIGHT or hpRegenType == HP_REGEN_BLIGHT then
		return baseHpRegen
	end

	return baseHpRegen + 0.25
end

---@return string
function CustomCharacter:_hitPointsRegenType()
	return self.args.hpregentype or FACTION_TO_HP_REGEN_TYPE[Faction.read(self.args.race)]
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
	lpdbData.type = 'hero'
	lpdbData.name = self.pagename
	lpdbData.image = args.icon and ('Wc3BTN' .. args.icon .. '.png') or nil
	lpdbData.information = Faction.toName(Faction.read(args.race)) or 'Neutral'

	lpdbData.extradata['primary attribute'] = ATTRIBUTES[args.mainattribute]
	lpdbData.extradata.baseint = args.baseint
	lpdbData.extradata.intgain = args.intgain
	lpdbData.extradata.baseagi = args.baseagi
	lpdbData.extradata.agigain = args.agigain
	lpdbData.extradata.basestr = args.basestr
	lpdbData.extradata.strgain = args.strgain
	lpdbData.extradata.basehp = args.basehp or 100
	lpdbData.extradata.basearmor = args.basearmor or 0
	lpdbData.extradata.numdice = args.numdice
	lpdbData.extradata.sidesdie = args.sidesdie
	lpdbData.extradata.basecd = args.basecd
	lpdbData.extradata.race = Faction.read(args.race)
	lpdbData.extradata.dps = self:_calculateDps(args)
	lpdbData.extradata.ehp = self:_calculateEhp(args)

	return lpdbData
end

---@param args table
---@return number[]
function CustomCharacter:_calculateDps(args)
	local baseAverageDamage = (self:_baseMinimumDamage() + self:_baseMaximumDamage()) / 2
	local baseGain = tonumber(args[args.mainattribute .. 'gain']) or 0

	local toDps = function(gainFactor)
		return (baseAverageDamage + math.floor(gainFactor * baseGain)) / self:_calculateCooldown(gainFactor)
	end

	return {toDps(0), toDps(2), toDps(4), toDps(9)}
end

---@param args table
---@return number[]
function CustomCharacter:_calculateEhp(args)
	local toEhp = function(gainFactor)
		return Math.round(
			self:_calculateHitPoints(gainFactor) * (1 + 0.06 * self:_calculateArmor(gainFactor)),
			0
		)
	end

	return {toEhp(0), toEhp(4), toEhp(9)}
end

---@param funct fun(num:number): number|string|nil
---@param title string
---@return {content: table, contentClasses: table}}
function CustomCharacter._toLevelChangesRow(funct, title)
	return {children = {title, funct(0), funct(4), funct(9)}, contentClasses = LEVEL_CHANGE_CLASSES}
end

return CustomCharacter
