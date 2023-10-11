---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ArmorIcon = require('Module:ArmorIcon')
local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})
local Shared = Lua.import('Module:Infobox/Extension/BuildingUnitShared', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

local EXPERIENCE = mw.loadData('Module:Experience')

local CRITTERS = 'critters'
local ICON_HP = '[[File:Icon_Hitpoints.png|link=Hit Points]]'
local GOLD = '[[File:Gold WC3 Icon.gif|15px|link=Gold]]'
local ADDITIONAL_UNIT_RACES = {
	creeps = 'Creeps',
	neutral = 'Creeps',
	c = 'Creeps',
}

local _args

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args

	unit.nameDisplay = CustomUnit.nameDisplay
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector

	return unit:createInfobox()
end

---@return WidgetInjector
function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local mana = Shared.manaValues(_args)
	local acquisitionRange = tonumber(_args.acq_range) or 0
	local level = tonumber(_args.level) or 0
	local race = Faction.toName(Faction.read(_args.race)) or ADDITIONAL_UNIT_RACES[string.lower(_args.race or '')]

	Array.appendWith(widgets,
		Cell{name = '[[Race]]', content = {race and ('[[' .. race .. ']]') or _args.race}},
		Cell{name = '[[Targeting#Target_Classifications|Classification]]', content = {
			_args.class and String.convertWikiListToHtmlList(_args.class) or nil}},
		Cell{name = 'Bounty Awarded', content = {CustomUnit._bounty(_args)}},
		Cell{name = 'Sleeps', content = {_args.sleeps}},
		Cell{name = 'Cargo Capacity', content = {_args.cargo_capacity}},
		Cell{name = 'Morphs into', content = {_args.morphs}},
		Cell{name = 'Duration', content = {_args.duration}},
		Cell{name = 'Formation Rank', content = {_args.formationrank}},
		Cell{name = '[[Sight_Range|Sight]]', content = {_args.daysight .. ' / ' .. _args.nightsight}},
		Cell{name = 'Acquisition Range', content = {acquisitionRange > 0 and acquisitionRange or nil}},
		Cell{name = '[[Experience#Determining_Experience_Gained|Level]]', content = {
			level > 0 and ('[[Experience|'.._args.level..']]') or nil}},
		Cell{name = '[[Mana]]', content = {mana.manaDisplay}},
		Cell{name = '[[Mana|Initial Mana]]', content = {mana.initialManaDisplay}},
		Cell{name = '[[Mana#Mana_Gain|Mana Regeneration]]', content = {mana.manaRegenDisplay}},
		Cell{name = 'Selection Priorty', content = {_args.priority}}
	)

	local movement = Shared.movement(_args, 'Movement')
	if movement then
		Array.appendWith(widgets, unpack(movement))
	end

	local mercenaryStats = Shared.mercenaryStats(_args)
	if mercenaryStats then
		Array.appendWith(widgets, unpack(mercenaryStats))
	end

	if _args.icon then
		Array.appendWith(widgets,
			Title{name = 'Icon'},
			Center{content = {'[[File:Wc3BTN' .. _args.icon .. '.png]]'}}
		)
	end

	return Array.append(widgets, unpack(Shared.attackDisplay(_args)))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = _args.race,
				gold = _args.gold,
				lumber = _args.lumber,
				buildTime = _args.build_time,
				food = _args.food,
			}}},
		}
	elseif id == 'requirements' then
		return {Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(_args.requires)}}}
	elseif id == 'defense' then
		return {
			Cell{name = '[[Hit Points|Hit Points]]', content = {CustomUnit:_defenseDisplay()}},
			Cell{name = '[[Hit Points#Hit Points Gain|HP Regeneration]]', content = {
				Shared.hitPointsRegeneration(_args, {display = true})}},
			Cell{name = '[[Armor|Armor]]', content = {CustomUnit:_armorDisplay()}}
		}
	elseif id == 'attack' then return {}
	end

	return widgets
end

function CustomUnit._bounty(args)
	if not args.bountybasethen then return end
	local baseBounty = tonumber(args.bountybase) or 0
	local bountyDice = tonumber(args.bountydice) or 1
	local bountySides = tonumber(args.bountysides) or 1

	return GOLD .. ' ' .. (baseBounty + bountyDice) .. ' - ' .. (baseBounty + bountyDice * bountySides)
end

---@return string
function CustomUnit:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if tonumber(_args.hitpoint_bonus) > 0 then
		return display .. ' (' .. _args.hp + _args.hitpoint_bonus .. ')'
	end
	return display
end

---@return string
function CustomUnit:_armorDisplay()
	local display = ArmorIcon.run(_args.armortype) .. ' ' .. (_args.armor or 0)
	if _args.armor_upgrades then
		display = display.. ' (' .. (_args.armor + _args.armor_upgrades) .. ')'
	end
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
	if not String.isEmpty(_args.shortcut) then
		if not String.isEmpty(_args.shortcut2) then
			return Hotkeys.hotkey2(_args.shortcut, _args.shortcut2, 'arrow')
		else
			return Hotkeys.hotkey(_args.shortcut)
		end
	end
end

---@param args table
---@return boolean
function CustomUnit._isSpecialUnit(args)
	return (args.race or ''):lower() ~= CRITTERS and (tonumber(args.special) or 0) > 0
end

---@param args table
---@return boolean
function CustomUnit._isAirUnit(args)
	return args.movetype == 'fly'
end

---@param args table
function CustomUnit:setLpdbData(args)
	local extradata = Shared.buildBaseExtraData(args)

	local experience = EXPERIENCE[tonumber(args.level)] or 0

	extradata = Table.merge(extradata, {
		food = args.food,
		gold = args.gold,
		lumber = args.lumber,
		hasrangedattack = tostring(args.weapontype ~= 'normal'),
		cargosize = args.cargo_size,
		buildtime = CustomUnit._isSpecialUnit(args) and 0 or args.build_time,
		experience = CustomUnit._isSpecialUnit(args) and experience / 2 or experience,
		airorground = CustomUnit._isAirUnit(args) and 'air' or 'ground',

		--legacy reasons
		['increased mana regeneration'] = extradata.increasedmanaregeneration,
		['armor type'] = extradata.armortype,
		mercenarytileset = args.merctileset,
	})

	mw.ext.LiquipediaDB.lpdb_datapoint('unit_' .. (args.name or ''), {
		type = 'unit',
		name = args.name or self.pagename,
		image = args.icon and ('Wc3BTN' .. args.icon .. '.png') or nil,
		information = CustomUnit.getUnitRaceType(args),
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
	})
end

---@param args table
---@return string
function CustomUnit.getUnitRaceType(args)--this gets more complex for units
	local race = Shared.raceValue(args.race)
	if race == CRITTERS then return 'Critters' end
	local cleanedRace = Faction.toName(Faction.read(race))
	if cleanedRace == Faction.toName('n') then
		cleanedRace = 'Night Elf'
	end
	if (race == 'creeps' or race == 'demon') then
		cleanedRace = (tonumber(args.passive) or 0) > 0 and 'Neutral' or 'Creep'
	elseif race == 'other' or race == 'commoner' then
		cleanedRace = 'Neutral'
	end
	if not cleanedRace then return 'Neutral Units' end

	local isSpecialUnit = (tonumber(args.special) or 0) ~= 0
	local isMercenary = not isSpecialUnit and (tonumber(args.cannot_be_built) or 0) == 0
		and Logic.isNotEmpty(args.merctileset)

	return cleanedRace .. (isSpecialUnit and ' Special' or ' Standard')
		.. ' Units' .. (isMercenary and ' Mercenaries' or '')
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local unitType = CustomUnit._isAirUnit(args) and 'Air' or 'Ground'

	return {
		CustomUnit.getUnitRaceType(args),
		unitType .. ' Units',
		args.level and ('Level ' .. args.level .. ' Units') or nil,
	}
end

return CustomUnit
