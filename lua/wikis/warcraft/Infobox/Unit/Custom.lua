---
-- @Liquipedia
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

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')
local Shared = Lua.import('Module:Infobox/Extension/BuildingUnitShared')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)

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

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomUnit:addCustomCells(widgets)
	local args = self.args

	local mana = Shared.manaValues(args)
	local acquisitionRange = tonumber(args.acq_range) or 0
	local level = tonumber(args.level) or 0
	local race = Faction.toName(Faction.read(args.race)) or ADDITIONAL_UNIT_RACES[string.lower(args.race or '')]

	Array.appendWith(widgets,
		Cell{name = '[[Race]]', content = {race and ('[[' .. race .. ']]') or args.race}},
		Cell{name = '[[Targeting#Target_Classifications|Classification]]', content = {
			args.class and String.convertWikiListToHtmlList(args.class) or nil}},
		Cell{name = 'Bounty Awarded', content = {CustomUnit._bounty(args)}},
		Cell{name = 'Sleeps', content = {args.sleeps}},
		Cell{name = 'Cargo Capacity', content = {args.cargo_capacity}},
		Cell{name = 'Morphs into', content = {args.morphs}},
		Cell{name = 'Duration', content = {args.duration}},
		Cell{name = 'Formation Rank', content = {args.formationrank}},
		Cell{name = '[[Sight_Range|Sight]]', content = {args.daysight .. ' / ' .. args.nightsight}},
		Cell{name = 'Acquisition Range', content = {acquisitionRange > 0 and acquisitionRange or nil}},
		Cell{name = '[[Experience#Determining_Experience_Gained|Level]]', content = {
			level > 0 and ('[[Experience|'..args.level..']]') or nil}},
		Cell{name = '[[Mana]]', content = {mana.manaDisplay}},
		Cell{name = '[[Mana|Initial Mana]]', content = {mana.initialManaDisplay}},
		Cell{name = '[[Mana#Mana_Gain|Mana Regeneration]]', content = {mana.manaRegenDisplay}},
		Cell{name = 'Selection Priorty', content = {args.priority}}
	)

	local movement = Shared.movement(args, 'Movement')
	if movement then
		Array.appendWith(widgets, unpack(movement))
	end

	local mercenaryStats = Shared.mercenaryStats(args)
	if mercenaryStats then
		Array.appendWith(widgets, unpack(mercenaryStats))
	end

	if args.icon then
		Array.appendWith(widgets,
			Title{children = 'Icon'},
			Center{children = {'[[File:Wc3BTN' .. args.icon .. '.png]]'}}
		)
	end

	return Array.append(widgets, unpack(Shared.attackDisplay(args)))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = args.race,
				gold = args.gold,
				lumber = args.lumber,
				buildTime = args.build_time,
				food = args.food,
			}}},
		}
	elseif id == 'requirements' then
		return {Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(args.requires)}}}
	elseif id == 'defense' then
		return {
			Cell{name = '[[Hit Points|Hit Points]]', content = {self.caller:_defenseDisplay()}},
			Cell{name = '[[Hit Points#Hit Points Gain|HP Regeneration]]', content = {
				Shared.hitPointsRegeneration(args, {display = true})}},
			Cell{name = '[[Armor|Armor]]', content = {self.caller:_armorDisplay()}}
		}
	elseif id == 'attack' then return {}
	elseif id == 'custom' then
		return self.caller:addCustomCells(widgets)
	end

	return widgets
end

function CustomUnit._bounty(args)
	if not args.bountybase then return end
	local baseBounty = tonumber(args.bountybase) or 0
	local bountyDice = tonumber(args.bountydice) or 1
	local bountySides = tonumber(args.bountysides) or 1

	return GOLD .. ' ' .. (baseBounty + bountyDice) .. ' - ' .. (baseBounty + bountyDice * bountySides)
end

---@return string
function CustomUnit:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (self.args.hp or 0)
	if (tonumber(self.args.hitpoint_bonus) or 0) > 0 then
		return display .. ' (' .. (tonumber(self.args.hp) + tonumber(self.args.hitpoint_bonus)) .. ')'
	end
	return display
end

---@return string
function CustomUnit:_armorDisplay()
	local display = ArmorIcon.run(self.args.armortype)
	if self.args.armortype2 then
		display = display .. ' / ' .. ArmorIcon.run(self.args.armortype2)
	end
	display = display .. ' ' .. (self.args.armor or 0)
	if self.args.armor_upgrades then
		display = display.. ' (' .. (tonumber(self.args.armor or 0) + tonumber(self.args.armor_upgrades)) .. ')'
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
	if not String.isEmpty(self.args.shortcut) then
		if not String.isEmpty(self.args.shortcut2) then
			return Hotkeys.hotkey2{hotkey1 = self.args.shortcut, hotkey2 = self.args.shortcut2, seperator = 'arrow'}
		else
			return Hotkeys.hotkey{hotkey = self.args.shortcut}
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
