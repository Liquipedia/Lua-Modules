---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Attack = require('Module:Infobox/Extension/Attack')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Hotkeys = require('Module:Hotkey')
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

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=]]'

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
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Sight', content = {args.sight}}
			--todo: energy/energy_rate
		)
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = self.caller.faction,
				luminite = args.min,
				luminiteTotal = args.totalmin,
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
			Cell{name = 'Tech. Requirements', content = CustomBuilding._readCommaSeparatedList(args.tech_requirement)},
			Cell{name = 'Building Requirements', content = CustomBuilding._readCommaSeparatedList(args.building_requirement)},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = 'Hotkeys', content = {CustomBuilding._hotkeys(args.hotkey, args.hotkey2)}},
			Cell{name = 'Macrokeys', content = {CustomBuilding._hotkeys(args.macro_key, args.macro_key2)}},
		}
	elseif id == 'builds' then
		return {
			Cell{name = 'Builds', content = CustomBuilding._readCommaSeparatedList(args.builds)},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocks', content = CustomBuilding._readCommaSeparatedList(args.unlocks)},
			Cell{name = 'Passive', content = CustomBuilding._readCommaSeparatedList(args.passive)},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Health', content = {args.health and (ICON_HP .. args.health) or nil}},
			Cell{name = 'Armor', content = self.caller:_getArmorDisplay()},
		}
	elseif id == 'attack' then
		for _, attackArgs, attackIndex in Table.iter.pairsByPrefix(args, 'attack') do
			Array.extendWith(widgets, Attack.run(attackArgs, attackIndex, self.caller.faction))
		end
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
			size = args.size,
			sight = args.sight,
			luminite = args.luminite,
			totalluminite = args.totalluminite,
			therium = args.therium,
			totaltherium = args.totaltherium,
			buildtime = args.buildtime,
			totalbuildtime = args.totalbuildtime,
			animus = args.animus,
			totalanimus = args.totalanimus,
			techrequirement = CustomBuilding._readCommaSeparatedList(args.tech_requirement),
			builds = CustomBuilding._readCommaSeparatedList(args.builds),
			unlocks = CustomBuilding._readCommaSeparatedList(args.unlocks),
			passive = CustomBuilding._readCommaSeparatedList(args.passive),
			armortypes = CustomBuilding._readCommaSeparatedList(args.armor_types),
			hotkey = args.hotkey,
			hotkey2 = args.hotkey2,
			macrokey = args.macro_key,
			macrokey2 = args.macro_key2,
			health = args.health,
			armor = args.sight,
			energy = args.energy,
			energyrate = args.energy_rate,
		},
	})
end

---@param inputString string?
---@return string[]
function CustomBuilding._readCommaSeparatedList(inputString)
	if String.isEmpty(inputString) then return {} end
	---@cast inputString -nil
	return Array.map(mw.text.split(inputString, ','), String.trim)
end

---@return string[]
function CustomBuilding:_getArmorDisplay()
	local armorTypes = Array.map(CustomBuilding._readCommaSeparatedList(self.args.armor_type), function(armorType)
		return Page.makeInternalLink(armorType)
	end)

	return Array.append({},
		self.args.armor and (ICON_ARMOR .. self.args.armor) or nil,
		String.nilIfEmpty(table.concat(armorTypes, ', '))
	)
end

return CustomBuilding
