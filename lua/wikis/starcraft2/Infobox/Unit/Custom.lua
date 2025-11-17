---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local CostDisplay = Lua.import('Module:Infobox/Extension/CostDisplay')
local Faction = Lua.import('Module:Faction')
local Game = Lua.import('Module:Game')
local Hotkeys = Lua.import('Module:Hotkey')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class Starcraft2UnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local GAME_LOTV = Game.name{game = 'lotv'}

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	unit.args.game = Game.name{game = unit.args.game}

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'cost' and not String.isEmpty(args.min) then
		return {
			Cell{name = 'Cost', children = {CostDisplay.run{
				faction = args.race,
				minerals = args.min,
				mineralsTotal = args.totalmin,
				mineralsForced = true,
				gas = args.gas,
				gasTotal = args.totalgas,
				gasForced = true,
				buildTime = args.buildtime,
				buildTimeTotal = args.totalbuildtime,
				supply = args.supply or args.control or args.psy,
				supplyTotal = args.totalsupply or args.totalcontrol or args.totalpsy,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', children = {String.convertWikiListToHtmlList(args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Hotkeys per Race|Hotkey]]', children = {self.caller:_getHotkeys()}}
		}
	elseif id == 'type' and (not String.isEmpty(args.size) or not String.isEmpty(args.type)) then
		local display = args.size
		if not display then
			display = args.type
		elseif args.type then
			display = display .. ' ' .. args.type
		end
		return {
			Cell{name = 'Type', children = {display}}
		}
	elseif id == 'defense' then return {}
	elseif id == 'attack' then
		local attacks = {}
		local index = 1
		while not String.isEmpty(args['attack' .. index .. '_target']) do
			for _, item in ipairs(self.caller:_getAttack(index)) do
				table.insert(attacks, item)
			end
			index = index + 1
		end
		return attacks
	elseif id == 'custom' then
		Array.appendWith(
			widgets,
			Title{children = 'Unit stats'},
			Cell{name = 'Defense', children = {self.caller:_defenseDisplay()}},
			Cell{name = 'Attributes', children = {args.attributes}},
			Cell{name = 'Energy', children = {args.energy}},
			Cell{name = 'Sight', children = {args.sight}},
			Cell{name = 'Detection range', children = {args.detection_range}},
			Cell{name = 'Speed', children = {args.speed}},
			Cell{name = 'Speed Multiplier on Creep', children = {args.creepspeedmult}},
			Cell{name = 'Speed on Creep', children = {args.speedoncreep}},
			Cell{name = 'Flags', children = {args.flags}},
			Cell{name = 'Morphs into', children = {args.morphs}},
			Cell{name = 'Cargo size', children = {args.cargo_size}},
			Cell{name = 'Cargo capacity', children = {args.cargo_capacity}},
			Cell{name = 'Strong against', children = {String.convertWikiListToHtmlList(args.strong)}},
			Cell{name = 'Weak against', children = {String.convertWikiListToHtmlList(args.weak)}}
		)

		if args.game ~= GAME_LOTV and args.buildtime then
			table.insert(widgets, Center{children = {
				'<small><b>Note:</b> ' ..
				'All time-related values are expressed assuming Normal speed, as they were before LotV.' ..
				' <i>See [[Game Speed]].</i></small>'
			}})
		end
	end
	return widgets
end

---@return string
function CustomUnit:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (self.args.hp or 0)
	if self.args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. self.args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (self.args.armor or 1)

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
	local args = self.args
	local attackHeader = 'Attack ' .. index
	if not String.isEmpty(args['attack' .. index .. '_name']) then
		attackHeader = attackHeader .. ': ' .. args['attack' .. index .. '_name']
	end

	self:_storeAttack(index)

	return {
		Title{children = attackHeader},
		Cell{name = 'Targets', children = {args['attack' .. index .. '_target']}},
		Cell{name = 'Damage', children = {args['attack' .. index .. '_damage']}},
		Cell{name = '[[Damage Per Second|DPS]]', children = {args['attack' .. index .. '_dps']}},
		Cell{name = '[[Cooldown]]', children = {args['attack' .. index .. '_cooldown']}},
		Cell{name = 'Bonus', children = {args['attack' .. index .. '_bonus']}},
		Cell{name = 'Bonus DPS', children = {args['attack' .. index .. '_bonus_dps']}},
		Cell{name = '[[Range]]', children = {
				(args['attack' .. index .. '_range'] or '')..
				(args['attack' .. index .. '_range_note'] or '')
			}
		}
	}
end

---@param index number
function CustomUnit:_storeAttack(index)
	local args = self.args
	mw.ext.LiquipediaDB.lpdb_datapoint((args.name or '') .. 'attack' .. index, {
		name = args['attack' .. index .. '_name'] or ('Attack ' .. index),
		type = 'Unit attack ' .. index,
		information = args.game,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			race = Faction.read(args.race),
			damage = args['attack' .. index .. '_damage'],
			dps = args['attack' .. index .. '_dps'],
			cooldown = args['attack' .. index .. '_cooldown'],
			bonus = args['attack' .. index .. '_bonus'],
			bonus_dps = args['attack' .. index .. '_bonus_dps'],
			range = args['attack' .. index .. '_range'],
			target = args['attack' .. index .. '_target'],
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
