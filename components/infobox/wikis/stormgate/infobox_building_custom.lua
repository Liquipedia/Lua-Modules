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
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local MessageBox = require('Module:Message box')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class StormgateBuildingInfobox: BuildingInfobox
---@field faction string?
local CustomBuilding = Class.new(Building)

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=Health]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local ICON_ENERGY = '[[File:EnergyIcon.gif|link=]]'
local ICON_DEPRECATED = '[[File:Cancelled Tournament.png|link=]]'
local HOTKEY_SEPERATOR = '&nbsp;&nbsp;/&nbsp;&nbsp;'
local CREEP = 'Camp'

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	building.faction = Faction.read(building.args.faction)

	building:_processPatchFromId('introduced')
	building:_processPatchFromId('deprecated')

	local builtInfobox = building:createInfobox()

	return mw.html.create()
		:node(builtInfobox)
		:node(CustomBuilding._deprecatedWarning(building.args.deprecatedDisplay))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if args.informationType == CREEP then
		return caller:_parseForCreeps(id, widgets)
	end

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Sight', content = {args.sight}},
			Cell{name = 'Energy', content = {caller:_energyDisplay()}},
			Cell{name = 'Upgrades To', content = caller:_csvToPageList(args.upgrades_to)},
			Cell{name = 'Introduced', content = {args.introducedDisplay}}
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
				supply = args.supply,
				supplyTotal = args.totalsupply,
				buildTime = args.buildtime,
				buildTimeTotal = args.totalbuildtime,
				animus = args.animus,
				animusTotal = args.totalanimus,
				power = args.power,
				powerTotal = args.totalpower,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Tech. Requirements', content = caller:_csvToPageList(args.tech_requirement)},
			Cell{name = 'Building Requirements', content = caller:_csvToPageList(args.building_requirement)},
		}
	elseif id == 'hotkey' then
		if not args.hotkey and not args.macro_key then return {} end
		local hotkeyName = table.concat(Array.append({},
			args.hotkey and 'Hotkeys', args.macro_key and 'Macrokeys'
		), HOTKEY_SEPERATOR)
		local hotkeys = table.concat(Array.append({},
			args.hotkey and CustomBuilding._hotkeys(args.hotkey, args.hotkey2),
			args.macro_key and CustomBuilding._hotkeys(args.macro_key, args.macro_key2)
		), HOTKEY_SEPERATOR)
		return {Cell{name = hotkeyName, content = {hotkeys}}}
	elseif id == 'builds' then
		return {
			Cell{name = 'Builds', content = caller:_csvToPageList(args.builds)},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocks', content = caller:_csvToPageList(args.unlocks)},
			Cell{name = 'Supply Gained', content = Array.parseCommaSeparatedString(args.supply_gained)},
			Cell{name = 'Power Gained', content = Array.parseCommaSeparatedString(args.power_gained)},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {caller:_getDefenseDisplay()}},
			Cell{name = 'Attributes', content = {caller:_displayCsvAsPageCsv(args.armor_type)}}
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
	local factionName = Faction.toName(self.faction)
	return Array.append({},
		factionName and (factionName .. ' Buildings') or nil,
		args.informationType == CREEP and 'Camps' or nil
	)
end

---@param args table
function CustomBuilding:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('building_' .. self.pagename, {
		name = args.name or self.pagename,
		type = (args.informationType or 'building'):lower(),
		information = self.faction,
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			deprecated = args.deprecated or '',
			introduced = args.introduced or '',
			size = tonumber(args.size),
			sight = tonumber(args.sight),
			luminite = tonumber(args.luminite),
			totalluminite = tonumber(args.totalluminite),
			therium = tonumber(args.therium),
			totaltherium = tonumber(args.totaltherium),
			supply = tonumber(args.supply),
			totalsupply = tonumber(args.totalsupply),
			animus = tonumber(args.animus),
			totalanimus = tonumber(args.totalanimus),
			power = tonumber(args.power),
			totalpower = tonumber(args.totalpower),
			buildtime = tonumber(args.buildtime),
			totalbuildtime = tonumber(args.totalbuildtime),
			techrequirement = Array.parseCommaSeparatedString(args.tech_requirement),
			buildingrequirement = Array.parseCommaSeparatedString(args.building_requirement),
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
			--extradata for creep camps
			startlevel = tonumber(args.start_level),
			respawn = tonumber(args.respawn),
			creeps = Array.parseCommaSeparatedString(args.creeps),
			capturepoint = args.capture_point,
			globalbuff = args.global_buff,
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
		ICON_HP,
		health or 0,
		extraHealth and ('(+' .. extraHealth .. ')') or nil,
		ICON_ARMOR,
		armor or 0
	), '&nbsp;')
end

---@param inputString string?
---@return string[]
function CustomBuilding:_csvToPageList(inputString)
	return Array.map(Array.parseCommaSeparatedString(inputString), function(value)
		return Page.makeInternalLink(value)
	end)
end

---@param input string?
---@return string
function CustomBuilding:_displayCsvAsPageCsv(input)
	return table.concat(self:_csvToPageList(input), ', ')
end

---@param key string
function CustomBuilding:_processPatchFromId(key)
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
---@return Html? -would need to check what warningbox actually returns ... am on phone ...
function CustomBuilding._deprecatedWarning(patch)
	if not patch then return end

	return MessageBox.main('ambox', {
		image= ICON_DEPRECATED,
		class='ambox-red',
		text= 'This has been removed from 1v1 with Patch ' .. patch,
	})
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomBuilding:_parseForCreeps(id, widgets)
	local args = self.args
	local startLevel = args.start_level == '1' and args.start_level or
		args.start_level and "'''" .. args.start_level .. "'''"
	local creeps = {}
	Array.forEach(Array.parseCommaSeparatedString(args.creeps), function(creep)
		local unit = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[information::n]] AND [[type::Unit]] AND [[name::' .. creep .. ']]',
			limit = 1,
		})[1] or {}
		Array.appendWith(creeps, unit)
	end)

	if id ~= 'custom' then return {} end

	return {
		Cell{name = 'Start Level', content = {startLevel}},
		Cell{name = 'Defenders', content = {self._displayCreepDefenders(creeps)}},
		Cell{name = 'Respawn', content = {args.respawn and args.respawn .. 's'}},
		Title{name = 'Tower Rewards'},
		Cell{name = 'Capture Point', content = {args.capture_point}},
		Cell{name = 'Global Buff', content = {args.global_buff}},
	}
end

---@param creeps table
---@return string
function CustomBuilding._displayCreepDefenders(creeps)
	local display = {}
	local groupedCreeps = Array.groupBy(creeps, function(creep) return creep.name end)

	Array.forEach(groupedCreeps, function(group)
		local bounty = CostDisplay.run{
			luminite = group[1].extradata.bountyluminite or 0,
			therium = group[1].extradata.bountytherium or 0,
		}
		Array.appendWith(display,
			Page.makeInternalLink(group[1].name) ..
			(bounty and (' (' .. bounty .. ')') or '') ..
			(#group > 1 and (' x' .. #group) or ''))
	end)

	return table.concat(display, '<br>')
end

return CustomBuilding
