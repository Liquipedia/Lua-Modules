---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Attack = require('Module:Infobox/Extension/Attack')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local MessageBox = require('Module:Message box')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class Stormgate2UnitInfobox: UnitInfobox
---@field faction string?
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=Health]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local ICON_ENERGY = '[[File:EnergyIcon.gif|link=]]'
local ICON_DEPRECATED = '[[File:Cancelled Tournament.png|link=]]'

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	unit.faction = Faction.read(unit.args.faction)
	unit.args.informationType = unit.args.informationType or 'Unit'

	unit:_processPatchFromId('introduced')
	unit:_processPatchFromId('deprecated')

	local builtInfobox = unit:createInfobox()

	return mw.html.create()
		:node(builtInfobox)
		:node(CustomUnit._deprecatedWarning(unit.args.deprecatedDisplay))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	local SEP = '&nbsp;&nbsp;/&nbsp;&nbsp;'

	if id == 'type' then
		return {
			Cell{name = 'Type', content = {caller:_displayCommaSeparatedString(args.type)}},
		}
	elseif id == 'builtfrom' then
		return {
			Cell{name = 'Built From', content = {caller:_displayCommaSeparatedString(args.built)}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Tech. Requirement', content = {caller:_displayCommaSeparatedString(args.tech_requirement)}},
			Cell{name = 'Building Requirement', content = {caller:_displayCommaSeparatedString(args.building_requirement)}},
		}
	elseif id == 'cost' then
		return {
			Cell{
				name = 'Cost',
				content = {
					args.informationType ~= 'Hero' and CostDisplay.run{
						faction = caller.faction,
						luminite = args.luminite,
						luminiteTotal = args.totalluminite,
						luminiteForced = true,
						therium = args.therium,
						theriumTotal = args.totaltherium,
						theriumForced = true,
						supply = args.supply,
						supplyTotal = args.totalsupply,
						supplyForced = true,
						animus = args.animus,
						animusTotal = args.totalanimus,
					} or nil
				}
			},
			Cell{
				name = 
					args.buildtime and args.charge_time and 'Built' .. SEP .. 'Recharge Time' or
					args.charge_time and 'Recharge Time' or
					'Built Time',					
				content = {
					args.buildtime and args.charge_time and args.buildtime .. 's' .. SEP .. args.charge_time .. 's' or 
					args.charge_time and args.charge_time .. 's' or
					args.buildtime and args.buildtime .. 's' or nil
				}
			},
		}
	elseif id == 'hotkey' then
		return {
			Cell{
				name = args.hotkey and args.macro_key and 'Hotkeys' .. SEP .. 'Macrokeys' or 'Hotkeys',
				content = {
					args.hotkey and args.macro_key and
						CustomUnit._hotkeys(args.hotkey, args.hotkey2) .. SEP .. CustomUnit._hotkeys(args.macro_key, args.macro_key2) or
					args.hotkey and CustomUnit._hotkeys(args.hotkey, args.hotkey2) or nil
				}
			},
		}
	elseif id == 'attack' then return {}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {caller:_getHealthDisplay()}},
			Cell{name = 'Attributes', content = {caller:_displayCommaSeparatedString(args.armor_type)}}
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Energy', content = {caller:_energyDisplay()}},
			Cell{name = 'Sight', content = {args.sight}},
			Cell{name = 'Speed', content = {args.speed}},
			Cell{name = 'Upgrades To', content = {caller:_displayCommaSeparatedString(args.upgrades_to)}},
			Cell{name = 'Introduced', content = {args.introducedDisplay}}
		)
		for _, attackArgs, attackIndex in Table.iter.pairsByPrefix(args, 'attack') do
			Array.extendWith(widgets, Attack.run(attackArgs, attackIndex, caller.faction))
		end
	end

	return widgets
end

---@return string?
function CustomUnit:_getHealthDisplay()
	if not Logic.isNumeric(self.args.health) then return end
	local armor = self.args.armor or '0'

	local health = table.concat({
		ICON_HP .. ' ' .. self.args.health,
		Logic.isNumeric(self.args.extra_health) and ('(+' .. self.args.extra_health .. ')') or nil,
	}, '&nbsp;')

	return table.concat({
		health,
		self.args.armor and (ICON_ARMOR .. ' ' .. self.args.armor) or nil,
	}, '&nbsp;')
end

---@param args table
---@return string
function CustomUnit:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
end

---@param args table
---@return string?
function CustomUnit:subHeaderDisplay(args)
	if string.find(args.subfaction, '1v1') or string.find(args.subfaction, self.pagename) then return end
	return tostring(mw.html.create('span')
		:css('font-size', '90%')
		:wikitext('Hero: ' .. self:_displayCommaSeparatedString(args.subfaction))
	)
end

---@return string?
function CustomUnit:_getHotkeys()
	local display
	if not String.isEmpty(self.args.hotkey) then
		if not String.isEmpty(self.args.hotkey2) then
			display = Hotkeys.hotkey2(self.args.hotkey, self.args.hotkey2, 'arrow')
		else
			display = Hotkeys.hotkey(self.args.hotkey)
		end
	end

	return display
end

---@return string?
function CustomUnit:_energyDisplay()
	local energy = tonumber(self.args.energy) or 0
	local maxEnergy = tonumber(self.args.max_energy) or 0
	if energy == 0 and maxEnergy == 0 then return end

	local gainRate = tonumber(self.args.energy_rate)

	return table.concat({
		ICON_ENERGY .. ' ' .. energy,
		'/' .. (maxEnergy == 0 and '?' or maxEnergy),
		gainRate and (' (+' .. gainRate .. '/s)') or Abbreviation.make('+ varies', self.args.energy_desc),
	})
end

---@param args table
function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('unit_' .. self.pagename, {
		name = args.name,
		type = args.informationType,
		information = self.faction,
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			deprecated = args.deprecated or '',
			introduced = args.introduced or '',
			subfaction = Array.parseCommaSeparatedString(args.subfaction),
			veterancybonushealth = Array.parseCommaSeparatedString(args.veterancybonushealth),
			veterancybonusdamage = Array.parseCommaSeparatedString(args.veterancybonusdamage),
			veterancybonusattackspeed = Array.parseCommaSeparatedString(args.veterancybonusattackspeed),
			veterancyxp = Array.parseCommaSeparatedString(args.veterancyxp),
			type = Array.parseCommaSeparatedString(args.type),
			builtfrom = Array.parseCommaSeparatedString(args.built),
			techrequirement = Array.parseCommaSeparatedString(args.tech_requirement),
			buildingrequirement = Array.parseCommaSeparatedString(args.building_requirement),
			luminite = tonumber(args.luminite),
			totalluminite = tonumber(args.totalluminite),
			therium = tonumber(args.therium),
			totaltherium = tonumber(args.totaltherium),
			supply = tonumber(args.supply),
			totalsupply = tonumber(args.totalsupply),
			animus = tonumber(args.animus),
			totalanimus = tonumber(args.totalanimus),
			buildtime = tonumber(args.buildtime),
			rechargetime = tonumber(args.charge_time),
			sight = tonumber(args.sight),
			speed = tonumber(args.speed),
			health = tonumber(args.health),
			extrahealth = tonumber(args.extra_health),
			armor = tonumber(args.armor),
			energy = tonumber(args.energy),
			maxenergy = tonumber(args.max_energy),
			energyrate = tonumber(args.energy_rate),
			hotkey = args.hotkey,
			hotkey2 = args.hotkey2,
			macrokey = args.macro_key,
			macrokey2 = args.macro_key2,
			energydesc = args.energy_desc,
			passive = Array.parseCommaSeparatedString(args.passive),
			armortypes = Array.parseCommaSeparatedString(args.armor_type),
			upgradesto = Array.parseCommaSeparatedString(args.upgrades_to),
		},
	})
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local unitType = args.informationType .. 's'
	local faction = Faction.toName(self.faction)
	local categories = {unitType}

	if not faction then
		return categories
	end

	return Array.append(categories,
		faction .. ' ' .. unitType
	)
end

---@param hotkey1 string?
---@param hotkey2 string?
---@return string?
function CustomUnit._hotkeys(hotkey1, hotkey2)
	if String.isEmpty(hotkey1) then return end
	if String.isEmpty(hotkey2) then
		return Hotkeys.hotkey(hotkey1)
	end
	return Hotkeys.hotkey2(hotkey1, hotkey2, 'plus')
end

---@param inputString string?
---@return string
function CustomUnit:_displayCommaSeparatedString(inputString)
	return table.concat(Array.map(Array.parseCommaSeparatedString(inputString),
		function(value)
			return Page.makeInternalLink(value)
		end
	), ', ')
end

---@param key string
function CustomUnit:_processPatchFromId(key)
	local args = self.args
	local input = Table.extract(args, key)
	if String.isEmpty(input) then return end

	local patches = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::patch]]',
		limit = 5000,
	})

	args[key] = (Array.filter(patches, function(patch)
		return String.endsWith(patch.pagename, '/' .. input)
	end)[1] or {}).pagename
	assert(args[key], 'Invalid patch "' .. input .. '"')

	args[key .. 'Display'] = Page.makeInternalLink(input, args[key])
end

---@param patch string?
---@return Html?
function CustomUnit._deprecatedWarning(patch)
	if not patch then return end

	return MessageBox.main('ambox', {
		image= ICON_DEPRECATED,
		class='ambox-red',
		text= 'This has been removed from 1v1 with Patch ' .. patch,
	})
end

return CustomUnit
