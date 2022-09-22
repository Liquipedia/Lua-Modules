---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = require('Module:CleanRace')
local CleanRaceFullName = require('Module:CleanRace2')
local Lua = require('Module:Lua')
local Hotkeys = require('Module:Hotkey')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Building = Lua.import('Module:Infobox/Building', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center

local CustomBuilding = Class.new()

local CustomInjector = Class.new(Injector)

local _MINERALS = '[[File:Minerals.gif|baseline|link=Minerals]]'
local _GAS = mw.loadData('Module:Gas')
local _TIME = mw.loadData('Module:Buildtime')
local _HP = '[[File:Icon_Hitpoints.png|link=]]'
local _SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local _ARMOR = '[[File:Icon_Armor.png|link=Armor]]'

local _args
local _race
local _building_attributes = {}

function CustomBuilding.run(frame)
	local building = Building(frame)
	_args = building.args
	building.nameDisplay = CustomBuilding.nameDisplay
	building.setLpdbData = CustomBuilding.setLpdbData
	building.createWidgetInjector = CustomBuilding.createWidgetInjector
	return building:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Size', content = {_args.size}})
	table.insert(widgets, Cell{name = 'Sight', content = {_args.sight}})
	table.insert(widgets, Cell{name = 'Energy', content = {_args.energy}})
	table.insert(widgets, Cell{name = 'Detection/Attack Range', content = {_args.detection_range}})

	if _args.game ~= 'lotv' then
		table.insert(widgets, Center{content = {
			'<small>\'\'\'Note:\'\'\' ' ..
			'All time-related values are expressed assuming Normal speed, as they were before LotV.' ..
			' \'\'See [[Game Speed]].\'\'</small>'
		}})
	end

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CustomBuilding:_getCostDisplay()}},
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

function CustomBuilding:createWidgetInjector()
	return CustomInjector()
end

function CustomBuilding:_defenseDisplay()
	local display = _HP .. ' ' .. (_args.hp or 0)
	if _args.shield then
		display = display .. ' ' .. _SHIELDS .. ' ' .. _args.shield
	end
	display = display .. ' ' .. _ARMOR .. ' ' .. (_args.armor or 1)

	if _args.light then
		table.insert(_building_attributes, 'Light')
	else
		table.insert(_building_attributes, 'Armored')
	end
	table.insert(_building_attributes, 'Structure')
	if _race == 't' then
		table.insert(_building_attributes, 'Mechanical')
	elseif _race == 'z' then
		table.insert(_building_attributes, 'Biological')
	end
	return display .. ' ' .. '[[' .. table.concat(_building_attributes, ']], [[') .. ']]'
end

function CustomBuilding:nameDisplay(args)
	local raceIcon = CustomBuilding._getRace(args.race or 'unknown')
	local name = args.name or self.pagename

	return raceIcon .. '&nbsp;' .. name
end

function CustomBuilding._getRace(race)
	race = string.lower(race)
	_race = CleanRace[race] or race or ''
	local category = CleanRaceFullName[_race]
	local display = RaceIcon.getBigIcon({'alt_' .. _race})
	if not category and _race ~= 'unknown' then
		category = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	elseif category then
		category = '[[Category:' .. category .. ' Buildings]]'
	end

	return display .. (category or '')
end

function CustomBuilding:_getCostDisplay()
	local minerals = _args.min or 0
	minerals = _MINERALS .. '&nbsp;' .. minerals

	local gas = _args.gas or 0
	gas = (_GAS[_race] or _GAS['default']) .. '&nbsp;' .. gas

	local buildtime = _args.buildtime or 0
	if buildtime ~= 0 then
		buildtime = '&nbsp;' .. (_TIME[_race] or _TIME['default']) .. '&nbsp;' .. buildtime
	else
		buildtime = ''
	end

	return minerals .. '&nbsp;' .. gas .. buildtime
end

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

function CustomBuilding:setLpdbData(args)
	local lpdbData = {
		name = args.name,
		type = 'Building information ' .. _race,
		information = args.game,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			builtby = args.builtby,
			minerals = args.min,
			gas = args.gas,
			buildtime = args.buildtime,
			hp = args.hp,
			shield = args.shield,
			armor = args.armor or 1,
			attributes = table.concat(_building_attributes, ', '),
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
	}
	mw.ext.LiquipediaDB.lpdb_datapoint(args.name or '', lpdbData)
end

return CustomBuilding
