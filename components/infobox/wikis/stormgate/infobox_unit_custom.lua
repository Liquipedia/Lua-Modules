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

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class Stormgate2UnitInfobox: UnitInfobox
---@field faction string?
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=]]'
local ICON_ENERGY = '[[File:EnergyIcon.gif|link=]]'

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	unit.faction = Faction.read(unit.args.faction)
	unit.args.informationType = unit.args.informationType or 'Unit'

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'type' then
		return {
			Cell{name = 'Type', content = caller:_readCommaSeparatedList(args.type, true)},
		}
	elseif id == 'builtfrom' then
		return {
			Cell{name = 'Built From', content = {Page.makeInternalLink(args.built, args.built_link)}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Tech. Requirement', content = caller:_readCommaSeparatedList(args.tech_requirement, true)},
			Cell{name = 'Building Requirement', content = caller:_readCommaSeparatedList(args.building_requirement, true)},
		}
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
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
			}}},
			Cell{name = 'Build Time', content = {args.buildtime and (args.buildtime .. 's') or nil}},
			Cell{name = 'Recharge Time', content = {args.charge_time and (args.charge_time .. 's') or nil}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = 'Hotkeys', content = {CustomUnit._hotkeys(args.hotkey, args.hotkey2)}},
			Cell{name = 'Macrokeys', content = {CustomUnit._hotkeys(args.macro_key, args.macro_key2)}},
		}
	elseif id == 'attack' then return {}
	elseif id == 'defense' then
		return {
			Cell{name = 'Health', content = {caller:_getHealthDisplay()}},
			Cell{name = 'Armor', content = caller:_getArmorDisplay()},
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Energy', content = {caller:_energyDisplay()}},
			Cell{name = 'Sight', content = {args.sight}},
			Cell{name = 'Speed', content = {args.speed}},
			Cell{name = 'Passive', content = caller:_readCommaSeparatedList(args.passive, true)}
		)
		-- moved to the bottom due to having headers that would look ugly if in place where attack is set in commons
		for _, attackArgs, attackIndex in Table.iter.pairsByPrefix(args, 'attack') do
			Array.extendWith(widgets, Attack.run(attackArgs, attackIndex, caller.faction))
		end
	end

	return widgets
end

---@return string?
function CustomUnit:_getHealthDisplay()
	if not Logic.isNumeric(self.args.health) then return end

	return table.concat({
		ICON_HP .. ' ' .. self.args.health,
		Logic.isNumeric(self.args.extra_health) and ('(+' .. self.args.extra_health .. ')') or nil,
	}, '&nbsp;')
end

---@return string[]
function CustomUnit:_getArmorDisplay()
	local armorTypes = self:_readCommaSeparatedList(self.args.armor_type, true)

	return Array.append({},
		self.args.armor and (ICON_ARMOR .. ' ' .. self.args.armor) or nil,
		String.nilIfEmpty(table.concat(armorTypes, ', '))
	)
end

---@param args table
---@return string
function CustomUnit:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
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
			type = self:_readCommaSeparatedList(args.type),
			builtfrom = args.built_link or args.built,
			techrequirement = self:_readCommaSeparatedList(args.tech_requirement),
			buildingrequirement = self:_readCommaSeparatedList(args.building_requirement),
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
			passive = self:_readCommaSeparatedList(args.passive),
			armortypes = self:_readCommaSeparatedList(args.armor_type),
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
		faction .. unitType
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
---@param makeLink boolean?
---@return string[]
function CustomUnit:_readCommaSeparatedList(inputString, makeLink)
	if String.isEmpty(inputString) then return {} end
	---@cast inputString -nil
	local values = Array.map(Array.map(mw.text.split(inputString, ','), String.trim), function(value)
		return mw.getContentLanguage():ucfirst(value)
	end)
	if not makeLink then return values end
	return Array.map(values, function(value) return Page.makeInternalLink(value) end)
end

return CustomUnit
