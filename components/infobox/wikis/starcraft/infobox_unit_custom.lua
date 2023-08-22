---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local UNKNOWN_RACE = 'u'

local _args

function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args

	unit.nameDisplay = CustomUnit.nameDisplay
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector

	return unit:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	return {
		Title{name = 'Unit stats'},
		Cell{name = 'Attributes', content = {_args.att}},
		Cell{name = 'Defense', content = {CustomUnit:_defenseDisplay()}},
		Cell{name = 'Damage', content = {_args.damage}},
		Cell{name = 'Ground Damage', content = {_args.ground_attack}},
		Cell{name = 'Air Damage', content = {_args.air_attack}},
		Cell{name = '[[Distance#Range|Range]]', content = {_args.range}},
		Cell{name = '[[Distance#Range|Ground Range]]', content = {_args.grange}},
		Cell{name = '[[Distance#Range|Air Range]]', content = {_args.arange}},
		Cell{name = '[[Distance#Range|Minimum Range]]', content = {_args.mrange}},
		Cell{name = '[[Distance#Range|Minimum A. Range]]', content = {_args.marange}},
		Cell{name = '[[Distance#Range|Minimum G. Range]]', content = {_args.mgrange}},
		Cell{name = '[[Distance#Leash Range|Leash Range]]', content = {_args.lrange}},
		Cell{name = '[[Game Speed#Cooldown|Cooldown]]', content = {_args.cooldown}},
		Cell{name = '[[Game Speed#Cooldown|G. Cooldown]]', content = {_args.gcd}},
		Cell{name = '[[Game Speed#Cooldown|A. Cooldown]]', content = {_args.acd}},
		Cell{name = '[[Game Speed#Cooldown|Cooldown Bonus]]', content = {
			_args.cd2 and _args.bonus2 and (_args.cd2 .. ' ' .. _args.bonus2)
			or _args.cd2
		}},
		Cell{name = '[[Game Speed#Cooldown|G. Cooldown Bonus]]', content = {
			_args.gcd2 and _args.bonus4 and (_args.gcd2 .. ' ' .. _args.bonus4)
			or _args.gcd2
		}},
		Cell{name = '[[Game Speed#Cooldown|A. Cooldown Bonus]]', content = {
			_args.acd2 and _args.bonus5 and (_args.acd2 .. ' ' .. _args.bonus5)
			or _args.acd2
		}},
		Cell{name = 'Air Attacks', content = {_args.aa}},
		Cell{name = 'Attacks', content = {_args.ga}},
		Cell{name = '[[Game Speed#DPS|DPS]]', content = {_args.dps}},
		Cell{name = '[[Game Speed#DPS|G. DPS]]', content = {_args.gdps}},
		Cell{name = '[[Game Speed#DPS|A. DPS]]', content = {_args.adps}},
		Cell{name = '[[Game Speed#DPS|DPS Bonus]]', content = {
			_args.dps2 and _args.bonus3 and (_args.dps2 .. ' ' .. _args.bonus3)
			or _args.dps2
		}},
		Cell{name = '[[Game Speed#DPS|G. DPS Bonus]]', content = {
			_args.gdps2 and _args.bonus6 and (_args.gdps2 .. ' ' .. _args.bonus6)
			or _args.gdps2
		}},
		Cell{name = '[[Game Speed#DPS|A. DPS Bonus]]', content = {
			_args.adps2 and _args.bonus7 and (_args.adps2 .. ' ' .. _args.bonus7)
			or _args.adps2
		}},
		Cell{name = '[[Game Speed#Regeneration Rates|Energy Maximum]]', content = {
			_args.energy and _args.bonus8 and (_args.energy .. ' ' .. _args.bonus8)
			or _args.energy
		}},
		Cell{name = '[[Game Speed#Regeneration Rates|Starting Energy]]', content = {
			_args.energystart and _args.bonus9 and (_args.energystart .. ' ' .. _args.bonus9)
			or _args.energystart
		}},
		Cell{name = '[[Distance#Range|Sight]]', content = {_args.sight}},
		Cell{name = '[[Distance#Range|Detection Range]]', content = {_args.detection_range}},
		Cell{name = '[[Game Speed#Movement Speed|Speed]]', content = {_args.speed}},
		Cell{name = '[[Game Speed#Movement Speed|Speed Bonus]]', content = {
			_args.speed2 and _args.bonus1 and (_args.speed2 .. ' ' .. _args.bonus1)
			or _args.speed2
		}},
		Cell{name = 'Morphs into', content = {_args.morphs, _args.morphs2}},
		Cell{name = 'Morphs From', content = {_args.morphsf}},
	}
end

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
			Cell{name = '[[Shortcuts|Hotkey]]', content = {CustomUnit:_getHotkeys()}}
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
	elseif id == 'defense' or id == 'attack' then return {}
	end
	return widgets
end

function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

function CustomUnit:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if _args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. _args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (_args.armor or 1)

	return display
end

function CustomUnit:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or UNKNOWN_RACE}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

function CustomUnit:_getHotkeys()
	local display
	if not String.isEmpty(_args.shortcut) then
		if not String.isEmpty(_args.shortcut2) then
			display = Hotkeys.hotkey2(_args.shortcut, _args.shortcut2, 'arrow')
		else
			display = Hotkeys.hotkey(_args.shortcut)
		end
	end

	return display
end

function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint(args.name or '', {
		name = args.name,
		type = 'unit',
		information = Faction.read(args.race),
		image = args.image,
	})
end

function CustomUnit:getWikiCategories(args)
	if String.isEmpty(args.race) then
		return {}
	end

	local race = Faction.read(args.race)

	if race == UNKNOWN_RACE then
		return {}
	elseif not race then
		return {'InfoboxRaceError'}
	end

	return {Faction.toName(race) .. ' Units'}
end

return CustomUnit
