---
-- @Liquipedia
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Hotkeys = require('Module:Hotkey')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center

---@class Starcraft2BuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new(Building)

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local GAME_LOTV = Game.name{game = 'lotv'}

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	building.args.game = Game.name{game = building.args.game}

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
			Cell{name = 'Sight', content = {args.sight}},
			Cell{name = 'Energy', content = {args.energy}},
			Cell{name = 'Detection/Attack Range', content = {args.detection_range}}
		)

		if args.game ~= GAME_LOTV then
			table.insert(widgets, Center{children = {
				'<small><b>Note:</b> ' ..
				'All time-related values are expressed assuming Normal speed, as they were before LotV.' ..
				' <i>See [[Game Speed]].</i></small>'
			}})
		end
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = args.race,
				minerals = args.min,
				mineralsTotal = args.totalmin,
				mineralsForced = true,
				gas = args.gas,
				gasTotal = args.totalgas,
				gasForced = true,
				buildTime = args.buildtime,
				buildTimeTotal = args.totalbuildtime,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {self.caller:_getHotkeys()}}
		}
	elseif id == 'builds' then
		return {
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(args.builds)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(args.morphs)}},
			Cell{name = '[[Add-on]]s', content = {String.convertWikiListToHtmlList(args.addons)}},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocked Tech', content = {String.convertWikiListToHtmlList(args.unlocks)}},
			Cell{name = 'Upgrades available', content = {String.convertWikiListToHtmlList(args.upgrades)}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {self.caller:_defenseDisplay()}}
		}
	elseif id == 'attack' then
		return {
			Cell{name = 'Ground Attack', content = {args.ground_attack}},
			Cell{name = 'Ground [[Damage Per Second|DPS]]', content = {args.ground_dps}},
			Cell{name = 'Air Attack', content = {args.air_attack}},
			Cell{name = 'Air [[Damage Per Second|DPS]]', content = {args.air_dps}},
			Cell{name = 'Bonus', content = {args.bonus}},
			Cell{name = 'Bonus [[Damage Per Second|DPS]]', content = {args.bonus_dps}},
			Cell{name = 'Range', content = {args.range}},
			Cell{name = 'Cooldown', content = {args.cooldown}},
		}
	end
	return widgets
end

---@return string
function CustomBuilding:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (self.args.hp or 0)
	if self.args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. self.args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (self.args.armor or 1)

	return display .. ' ' .. table.concat(CustomBuilding._getAttributes(self.args, true), ', ')
end

---@param args table
---@param makeLink boolean?
---@return string[]
function CustomBuilding._getAttributes(args, makeLink)
	local race = Faction.read(args.race) or Faction.defaultFaction
	local attributes = {}

	if args.light then
		table.insert(attributes, 'Light')
	else
		table.insert(attributes, 'Armored')
	end
	table.insert(attributes, 'Structure')
	if race == 't' then
		table.insert(attributes, 'Mechanical')
	elseif race == 'z' then
		table.insert(attributes, 'Biological')
	end

	if makeLink then
		return Array.map(attributes, function(attribute) return '[[' .. attribute .. ']]' end)
	end

	return attributes
end

---@param args table
---@return string
function CustomBuilding:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or Faction.defaultFaction}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@return string?
function CustomBuilding:_getHotkeys()
	local display
	if not String.isEmpty(self.args.hotkey) then
		if not String.isEmpty(self.args.hotkey2) then
			display = Hotkeys.hotkey2{hotkey1 = self.args.hotkey, hotkey2 = self.args.hotkey2, seperator = 'arrow'}
		else
			display = Hotkeys.hotkey{hotkey = self.args.hotkey}
		end
	end

	return display
end

---@param args table
function CustomBuilding:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('building_' .. (args.name or ''), {
		name = args.name,
		type = 'Building information ' .. (Faction.read(args.race) or ''),
		information = args.game,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			builtby = args.builtby,
			minerals = args.min,
			mineralstotal = args.totalmin,
			gas = args.gas,
			gastotal = args.totalgas,
			buildtime = args.buildtime,
			buildtimetotal = args.totalbuildtime,
			hp = args.hp,
			shield = args.shield,
			armor = args.armor or 1,
			attributes = table.concat(CustomBuilding._getAttributes(args), ', '),
			hotkey = (args.hotkey or '') .. (args.hotkey2 ~= nil and (', ' .. args.hotkey2) or ''),
			energy = args.energy,
			size = args.size,
			sight = args.sight,
			detection = args.detection_range,
			requires = args.requires,
			builds = args.builds,
			morphs = args.morphs,
			addons = args.addons,
			unlocks = args.unlocks,
			upgrades = args.upgrades,
			groundAttack = args.ground_attack,
			groundDps = args.ground_dps,
			airAttack = args.air_attack,
			airDps = args.air_dps,
			bonus = args.bonus,
			bonusDps = args.bonus_dps,
			range = args.range,
			cooldown = args.cooldown,
		}),
	})
end

---@param args table
---@return string[]
function CustomBuilding:getWikiCategories(args)
	local race = Faction.read(args.race)

	if not race then
		return {}
	end

	return {Faction.toName(race) .. ' Buildings'}
end

return CustomBuilding
