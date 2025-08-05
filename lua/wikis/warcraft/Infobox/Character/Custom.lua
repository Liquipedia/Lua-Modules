---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Math = Lua.import('Module:MathUtil')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local BreakDown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Slider = Lua.import('Module:Widget/Basic/Slider')
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

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
local HP_REGEN_BLIGHT = 'blight'
local HP_REGEN_NIGHT = 'night'
local FACTION_TO_HP_REGEN_TYPE = {u = HP_REGEN_BLIGHT, n = HP_REGEN_NIGHT}

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
	---@type WarcraftCharacterInfobox
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local primary = args.mainattribute

		local levelBreakdown = function(level)
			level = level - 1
			return {
				Cell{name = 'HP', content = {caller:_calculateHitPoints(level)}},
				Cell{name = 'HP Regen.', content = {caller:_calculateHitPointsRegen(level) .. '/sec'}},
				Cell{name = 'Mana', content = {caller:_calculateMana(level)}},
				Cell{name = 'Mana Regen.', content = {caller:_calculateManaRegen(level) .. '/sec'}},
				Cell{name = 'Armor', content = {Math.round(caller:_calculateArmor(level), 2)}},
				Cell{name = 'Damage', content = {caller:_calculateDamage(level)}},
				Cell{name = 'Attack Cooldown', content = {Math.round(caller:_calculateCooldown(level), 2)}}
			}
		end

		local factionData = Faction.getProps(Faction.read(args.race)) or {name = NEUTRAL, pageName = NEUTRAL}
		local factionIcon = Faction.Icon{faction = Faction.read(args.race), size = '54px', showLink = true}

		local function fetchBuildingInfo(buildingName)
			if not buildingName then
				return {}
			end
			local data = mw.ext.LiquipediaDB.lpdb(
				'datapoint',
				{conditions = '[[type::building]] and [[name::'.. buildingName ..']]'}
			)[1] or {}
			return {name = data.name, image = data.image, page = data.pagename}
		end
		local buildingInfo = fetchBuildingInfo(args.trainedat)

		local breakDownCard = function(content)
			return HtmlWidgets.Div{
				attributes = {style = 'display: flex; flex-direction: column; align-items: center;'},
				children = content,
			}
		end

		return Array.append(widgets,
			BreakDown{children = {
				breakDownCard{
					HtmlWidgets.Div{children = {factionIcon}},
					HtmlWidgets.Div{children = {'Race:'}},
					HtmlWidgets.Div{children = Link{children = factionData.name, link = factionData.pageName}},
				},
				breakDownCard{
					HtmlWidgets.Div{children = {buildingInfo.image and
						('[[File:' .. buildingInfo.image .. '|link='.. buildingInfo.page ..'|54px]]') or ''
					}},
					HtmlWidgets.Div{children = {'Trained at:'}},
					HtmlWidgets.Div{children = {Link{children = buildingInfo.name or 'Unknown', link = buildingInfo.page or ''}}},
				},
				breakDownCard{
					HtmlWidgets.Div{classes = {'hotkey-button'}, children = {args.hotkey}},
					HtmlWidgets.Div{children = {'Hotkey:'}},
					HtmlWidgets.Div{children = {args.hotkey}},
				},
			}, classes = {'infobox-center'}},

			Title{children = 'Attributes'},
			BreakDown{children = {
				caller:_basicAttribute('str', primary == 'str'),
				caller:_basicAttribute('agi', primary == 'agi'),
				caller:_basicAttribute('int', primary == 'int'),
			}, classes = {'infobox-center'}},

			Title{children = 'Base Stats'},
			Cell{name = '[[Movement Speed]]', content = {args.basespeed}},
			Cell{name = '[[Sight Range]]', content = {args.sightrange or (
				tostring(Icon{iconName = 'day'}) .. (args.daysight or 1800) .. ' / ' ..
				tostring(Icon{iconName = 'night'}) .. (args.nightsight or 800)
			)}},
			Cell{name = '[[Attack Range]]', content = {args.attackrange}},
			Cell{name = 'Missile Speed', content = {args.missilespeed}},
			Cell{name = 'Attack Duration', content = {args.attackduration}},
			Cell{name = 'Base Attack Time', content = {args.attacktime}},
			Cell{name = 'Turn Rate', content = {args.turnrate}},

			Title{children = 'Stats per Level'},
			Slider{min = 1, max = 10, step = 1, defaultValue = 1, id = 'level', class = 'infobox-slider',
				title = function(level)
					return 'Level ' .. level
				end,
				childrenAtValue = levelBreakdown,
			}
		)
	end

	return widgets
end

---@param attribute string
---@param highlight boolean
---@return Widget
function CustomCharacter:_basicAttribute(attribute, highlight)
	return HtmlWidgets.Div{
		children = {
			ATTRIBUTE_ICONS[ATTRIBUTES[attribute]:lower()],
			'<br><b>' .. (self.args['base' .. attribute] or '') .. '</b>',
			' +' .. (self.args[attribute .. 'gain'] or '')
		},
		classes = { highlight and 'primaryAttribute' or nil },
	}
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
---@return number
function CustomCharacter:_calculateArmor(gainFactor)
	local gain = math.floor((tonumber(self.args.agigain) or 0) * gainFactor)
	return (gain + (tonumber(self.args.baseagi) or 0)) * 0.3
		- 2 + (tonumber(self.args.basearmor) or 0)
end

---@param gainFactor number
---@return string
function CustomCharacter:_calculateDamage(gainFactor)
	local gain = math.floor((tonumber(self.args[self.args.mainattribute .. 'gain']) or 0) * gainFactor)
	local baseMin, baseMax = self:_baseMinimumDamage(), self:_baseMaximumDamage()
	local baseAvg = (baseMin + baseMax) / 2

	return (baseMin + gain) .. ' - ' .. (baseMax + gain) .. ' (' .. baseAvg + gain .. ' avg)'
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
	local characterIcon = self:_displayIcon()

	return (characterIcon and (characterIcon .. NON_BREAKING_SPACE) or '') .. self.name
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

return CustomCharacter
