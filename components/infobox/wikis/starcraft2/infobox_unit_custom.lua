---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Hotkeys = require('Module:Hotkey')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local GAME_LOTV = Game.name{game = 'lotv'}

local _args

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args

	_args.game = Game.name{game = _args.game}

	unit.nameDisplay = CustomUnit.nameDisplay
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	unit.getWikiCategories = CustomUnit.getWikiCategories

	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Title{name = 'Unit stats'},
		Cell{name = 'Defense', content = {CustomUnit:_defenseDisplay()}},
		Cell{name = 'Attributes', content = {_args.attributes}},
		Cell{name = 'Energy', content = {_args.energy}},
		Cell{name = 'Sight', content = {_args.sight}},
		Cell{name = 'Detection range', content = {_args.detection_range}},
		Cell{name = 'Speed', content = {_args.speed}},
		Cell{name = 'Speed Multiplier on Creep', content = {_args.creepspeedmult}},
		Cell{name = 'Speed on Creep', content = {_args.speedoncreep}},
		Cell{name = 'Flags', content = {_args.flags}},
		Cell{name = 'Morphs into', content = {_args.morphs}},
		Cell{name = 'Cargo size', content = {_args.cargo_size}},
		Cell{name = 'Cargo capacity', content = {_args.cargo_capacity}},
		Cell{name = 'Strong against', content = {String.convertWikiListToHtmlList(_args.strong)}},
		Cell{name = 'Weak against', content = {String.convertWikiListToHtmlList(_args.weak)}}
	)

	if _args.game ~= GAME_LOTV and _args.buildtime then
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
	if id == 'cost' and not String.isEmpty(_args.min) then
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
				supply = _args.supply or _args.control or _args.psy,
				supplyTotal = _args.totalsupply or _args.totalcontrol or _args.totalpsy,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(_args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {CustomUnit:_getHotkeys()}}
		}
	elseif id == 'type' and (not String.isEmpty(_args.size) or not String.isEmpty(_args.type)) then
		local display = _args.size
		if not display then
			display = _args.type
		elseif _args.type then
			display = display .. ' ' .. _args.type
		end
		return {
			Cell{name = 'Type', content = {display}}
		}
	elseif id == 'defense' then return {}
	elseif id == 'attack' then
		local attacks = {}
		local index = 1
		while not String.isEmpty(_args['attack' .. index .. '_target']) do
			for _, item in ipairs(CustomUnit:_getAttack(index)) do
				table.insert(attacks, item)
			end
			index = index + 1
		end
		return attacks
	end
	return widgets
end

---@return WidgetInjector
function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

---@return string
function CustomUnit:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if _args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. _args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (_args.armor or 1)

	return display
end

---@param args table
---@return string
function CustomUnit:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or Faction.defaultFaction}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@return string?
function CustomUnit:_getHotkeys()
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
function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('unit_' .. (args.name or ''), {
		name = args.name,
		type = 'Unit',
		information = args.game,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			wasonlybeta = tostring(Logic.readBool(args.wasOnlyBeta)),
			deprecated = tostring(Logic.readBool(args.deprecated)),
			iscampaignunit = tostring(Logic.readBool(args.isCampaignUnit)),
			race = Faction.read(args.race),
			size = args.size,
			type = args.type,
			builtfrom = args.builtfrom,
			requires = args.requires,
			minerals = args.min,
			mineralstotal = args.totalmin,
			gas = args.gas,
			gastotal = args.totalgas,
			buildtime = args.buildtime,
			buildtimetotal = args.totalbuildtime,
			attributes = args.attributes,
			hp = args.hp,
			shield = args.shield,
			armor = args.armor,
			hotkey = string.lower(args.hotkey or ''),
			energy = args.energy,
			sight = args.sight,
			detection = args.detection_range,
			speed = args.speed,
			creepspeedmult = args.creepspeedmult,
			speedoncreep = args.speedoncreep,
			cargo_size = args.cargo_size,
			cargo_capacity = args.cargo_capacity,
			morphs = args.morphs,
			strong_against = args.strong,
			weak_against = args.weak,
			supply = args.supply or args.control or args.psy,
			supplytotal = args.totalsupply or args.totalcontrol or args.totalpsy,
		}),
	})
end

---@param index number
---@return Widget[]
function CustomUnit:_getAttack(index)
	local attackHeader = 'Attack ' .. index
	if not String.isEmpty(_args['attack' .. index .. '_name']) then
		attackHeader = attackHeader .. ': ' .. _args['attack' .. index .. '_name']
	end

	CustomUnit:_storeAttack(index)

	return {
		Title{name = attackHeader},
		Cell{name = 'Targets', content = {_args['attack' .. index .. '_target']}},
		Cell{name = 'Damage', content = {_args['attack' .. index .. '_damage']}},
		Cell{name = '[[Damage Per Second|DPS]]', content = {_args['attack' .. index .. '_dps']}},
		Cell{name = '[[Cooldown]]', content = {_args['attack' .. index .. '_cooldown']}},
		Cell{name = 'Bonus', content = {_args['attack' .. index .. '_bonus']}},
		Cell{name = 'Bonus DPS', content = {_args['attack' .. index .. '_bonus_dps']}},
		Cell{name = '[[Range]]', content = {
				(_args['attack' .. index .. '_range'] or '')..
				(_args['attack' .. index .. '_range_note'] or '')
			}
		}
	}
end

---@param index number
function CustomUnit:_storeAttack(index)
	mw.ext.LiquipediaDB.lpdb_datapoint((_args.name or '') .. 'attack' .. index, {
		name = _args['attack' .. index .. '_name'] or ('Attack ' .. index),
		type = 'Unit attack ' .. index,
		information = _args.game,
		image = _args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			race = Faction.read(_args.race),
			damage = _args['attack' .. index .. '_damage'],
			dps = _args['attack' .. index .. '_dps'],
			cooldown = _args['attack' .. index .. '_cooldown'],
			bonus = _args['attack' .. index .. '_bonus'],
			bonus_dps = _args['attack' .. index .. '_bonus_dps'],
			range = _args['attack' .. index .. '_range'],
			target = _args['attack' .. index .. '_target'],
		}),
	})
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local race = Faction.read(args.race)

	if not race then
		return {}
	end

	return {Faction.toName(race) .. ' Units'}
end

return CustomUnit
