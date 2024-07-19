---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Building/Custom
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
local Building = Lua.import('Module:Infobox/Building')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class StormgateBuildingInfobox: BuildingInfobox
---@field faction string?
local CustomBuilding = Class.new(Building)

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=Health]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local ICON_ENERGY = '[[File:EnergyIcon.gif|link=]]'
local HOTKEY_SEPERATOR = '&nbsp;&nbsp;/&nbsp;&nbsp;'

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	building.faction = Faction.read(building.args.faction)

	return building:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Sight', content = {args.sight}},
			Cell{name = 'Energy', content = {caller:_energyDisplay()}},
			Cell{name = 'Upgrades To', content = caller:_displayCommaSeparatedStringWithBreaks(args.upgrades_to)}
		)
		for _, attackArgs, attackIndex in Table.iter.pairsByPrefix(args, 'attack') do
			Array.extendWith(widgets, Attack.run(attackArgs, attackIndex, caller.faction))
		end
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
				buildTime = args.buildtime,
				buildTimeTotal = args.totalbuildtime,
				animus = args.animus,
				animusTotal = args.totalanimus,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Tech. Requirements', content = caller:_displayCommaSeparatedStringWithBreaks(args.tech_requirement)},
			Cell{name = 'Building Requirements', content =
					caller:_displayCommaSeparatedStringWithBreaks(args.building_requirement)},
		}
	elseif id == 'hotkey' then
		if not args.hotkey and not args.macro_key then return {} end
		local hotkeyName = table.concat(Array.append({},
			args.hotkey and 'Hotkeys',  args.macro_key and 'Macrokeys'
		), HOTKEY_SEPERATOR)
		local hotkeys = table.concat(Array.append({},
			args.hotkey and CustomBuilding._hotkeys(args.hotkey, args.hotkey2),
			args.macro_key and CustomBuilding._hotkeys(args.macro_key, args.macro_key2)
		), HOTKEY_SEPERATOR)
		return {Cell{name = hotkeyName, content = {hotkeys}}}
	elseif id == 'builds' then
		return {
			Cell{name = 'Builds', content = caller:_displayCommaSeparatedStringWithBreaks(args.builds)},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocks', content = caller:_displayCommaSeparatedStringWithBreaks(args.unlocks)},
			Cell{name = 'Supply Gained', content = Array.parseCommaSeparatedString(args.supply)},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {caller:_getDefenseDisplay()}},
			Cell{name = 'Attributes', content = {caller:_displayCommaSeparatedString(args.armor_type)}}
		}
	elseif id == 'attack' then return {}
	end
	return widgets
end

---@param args table
---@return string
function CustomBuilding:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
end

---@param hotkey1 string?
---@param hotkey2 string?
---@return string?
function CustomBuilding._hotkeys(hotkey1, hotkey2)
	if String.isEmpty(hotkey1) then return end
	if String.isEmpty(hotkey2) then
		return Hotkeys.hotkey(hotkey1)
	end
	return Hotkeys.hotkey2(hotkey1, hotkey2, 'plus')
end

---@return string?
function CustomBuilding:_energyDisplay()
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
---@return string[]
function CustomBuilding:getWikiCategories(args)
	if not self.faction then
		return {}
	end

	return {Faction.toName(self.faction) .. ' Buildings'}
end

---@param args table
function CustomBuilding:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('building_' .. self.pagename, {
		name = args.name or self.pagename,
		type = 'building',
		information = self.faction,
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			size = tonumber(args.size),
			sight = tonumber(args.sight),
			luminite = tonumber(args.luminite),
			totalluminite = tonumber(args.totalluminite),
			therium = tonumber(args.therium),
			totaltherium = tonumber(args.totaltherium),
			buildtime = tonumber(args.buildtime),
			totalbuildtime = tonumber(args.totalbuildtime),
			animus = tonumber(args.animus),
			totalanimus = tonumber(args.totalanimus),
			techrequirement = Array.parseCommaSeparatedString(args.tech_requirement),
			builds = Array.parseCommaSeparatedString(args.builds),
			unlocks = Array.parseCommaSeparatedString(args.unlocks),
			passive = Array.parseCommaSeparatedString(args.passive),
			armortypes = Array.parseCommaSeparatedString(args.armor_types),
			upgradesto = Array.parseCommaSeparatedString(args.upgrades_to),
			hotkey = args.hotkey,
			hotkey2 = args.hotkey2,
			macrokey = args.macro_key,
			macrokey2 = args.macro_key2,
			health = tonumber(args.health),
			armor = tonumber(args.armor),
			energy = tonumber(args.energy),
			energyrate = tonumber(args.energy_rate),
			energydesc = args.energy_desc,
			supply = args.supply,
		},
	})
end

---@return string?
function CustomBuilding:_getDefenseDisplay()
	local args = self.args
	local health = tonumber(args.health)
	local extraHealth = health and tonumber(args.extra_health)
	local armor = tonumber(args.armor)

	return table.concat(Array.append({},
		health and ICON_HP or nil,
		health,
		extraHealth and ('(+' .. extraHealth .. ')') or nil,
		armor and ICON_ARMOR or nil,
		armor
	), '&nbsp;')
end

---@param inputString string?
---@return string
function CustomBuilding:_displayCommaSeparatedString(inputString)
	return table.concat(Array.map(Array.parseCommaSeparatedString(inputString),
		function(value)
			return Page.makeInternalLink(value)
		end
	), ', ')
end

---@param inputString string?
---@return string[]
function CustomBuilding:_displayCommaSeparatedStringWithBreaks(inputString)
	return Array.map(Array.parseCommaSeparatedString(inputString), function(value)
		return Page.makeInternalLink({}, value)
	end)
end

return CustomBuilding
