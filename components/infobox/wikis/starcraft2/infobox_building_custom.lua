---
-- @Liquipedia
-- wiki=starcraft2
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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Building = Lua.import('Module:Infobox/Building', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center

---@class CustomBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new()

---@class CustomWidgetInjector: WidgetInjector
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local GAME_LOTV = Game.name{game = 'lotv'}

local _args

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = Building(frame)
	_args = building.args

	_args.game = Game.name{game = _args.game}

	building.nameDisplay = CustomBuilding.nameDisplay
	building.setLpdbData = CustomBuilding.setLpdbData
	building.getWikiCategories = CustomBuilding.getWikiCategories
	building.createWidgetInjector = CustomBuilding.createWidgetInjector

	return building:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Cell{name = 'Size', content = {_args.size}},
		Cell{name = 'Sight', content = {_args.sight}},
		Cell{name = 'Sight', content = {_args.sight}},
		Cell{name = 'Energy', content = {_args.energy}},
		Cell{name = 'Detection/Attack Range', content = {_args.detection_range}}
	)

	if _args.game ~= GAME_LOTV then
		table.insert(widgets, Center{content = {
			'<small><b>Note:</b> ' ..
			'All time-related values are expressed assuming Normal speed, as they were before LotV.' ..
			' <i>See [[Game Speed]].</i></small>'
		}})
	end

	return widgets
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = _args.race,
				minerals = _args.min,
				mineralsTotal = _args.totalmin,
				mineralsForced = true,
				gas = _args.gas,
				gasTotal = _args.totalgas,
				gasForced = true,
				buildTime = _args.buildtime,
				buildTimeTotal = _args.totalbuildtime,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(_args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {CustomBuilding:_getHotkeys()}}
		}
	elseif id == 'builds' then
		return {
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(_args.builds)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(_args.morphs)}},
			Cell{name = '[[Add-on]]s', content = {String.convertWikiListToHtmlList(_args.addons)}},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocked Tech', content = {String.convertWikiListToHtmlList(_args.unlocks)}},
			Cell{name = 'Upgrades available', content = {String.convertWikiListToHtmlList(_args.upgrades)}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {CustomBuilding:_defenseDisplay()}}
		}
	elseif id == 'attack' then
		return {
			Cell{name = 'Ground Attack', content = {_args.ground_attack}},
			Cell{name = 'Ground [[Damage Per Second|DPS]]', content = {_args.ground_dps}},
			Cell{name = 'Air Attack', content = {_args.air_attack}},
			Cell{name = 'Air [[Damage Per Second|DPS]]', content = {_args.air_dps}},
			Cell{name = 'Bonus', content = {_args.bonus}},
			Cell{name = 'Bonus [[Damage Per Second|DPS]]', content = {_args.bonus_dps}},
			Cell{name = 'Range', content = {_args.range}},
			Cell{name = 'Cooldown', content = {_args.cooldown}},
		}
	end
	return widgets
end

---@return CustomWidgetInjector
function CustomBuilding:createWidgetInjector()
	return CustomInjector()
end

---@return string
function CustomBuilding:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if _args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. _args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (_args.armor or 1)

	return display .. ' ' .. table.concat(CustomBuilding._getAttributes(_args, true), ', ')
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
	if not String.isEmpty(_args.hotkey) then
		if not String.isEmpty(_args.hotkey2) then
			display = Hotkeys.hotkey2(_args.hotkey, _args.hotkey2, 'arrow')
		else
			display = Hotkeys.hotkey(_args.hotkey)
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
