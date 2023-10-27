---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Building/Custom
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
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Building = Lua.import('Module:Infobox/Building', {requireDevIfEnabled = true})
local Shared = Lua.import('Module:Infobox/Extension/BuildingUnitShared', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomBuilding = Class.new()

local CustomInjector = Class.new(Injector)

local EXPERIENCE = mw.loadData('Module:Experience')

local DEFAULT_BUILDING_TYPE_RACE = 'Neutral'
local ICON_HP = '[[File:Icon_Hitpoints.png|link=Hit Points]]'
local ICON_FOOD = '[[File:Food_WC3_Icon.gif|15px|link=Food]]'
local ADDITIONAL_BUILDING_RACES = {
	creeps = 'Creeps',
	neutral = 'Creeps',
	c = 'Creeps',
}

local _args

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = Building(frame)
	_args = building.args

	building.nameDisplay = CustomBuilding.nameDisplay
	building.setLpdbData = CustomBuilding.setLpdbData
	building.getWikiCategories = CustomBuilding.getWikiCategories
	building.createWidgetInjector = CustomBuilding.createWidgetInjector

	return building:createInfobox()
end

---@return WidgetInjector
function CustomBuilding:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local mana = Shared.manaValues(_args)
	local acquisitionRange = tonumber(_args.acq_range) or 0
	local level = tonumber(_args.level) or 0
	local race = Faction.toName(Faction.read(_args.race)) or ADDITIONAL_BUILDING_RACES[string.lower(_args.race or '')]

	Array.appendWith(widgets,
		Cell{name = '[[Food supplied|Food]]', content = {
			_args.foodproduced and (ICON_FOOD .. ' ' .. _args.foodproduced) or nil,
		}},
		Cell{name = '[[Race]]', content = {race and ('[[' .. race .. ']]') or _args.race}},
		Cell{name = '[[Targeting#Target_Classifications|Classification]]', content = {
			_args.class and String.convertWikiListToHtmlList(_args.class) or nil}},
		Cell{name = 'Sleeps', content = {_args.sleeps}},
		Cell{name = 'Cargo Capacity', content = {_args.cargo_capacity}},
		Cell{name = 'Morphs into', content = {_args.morphs}},
		Cell{name = 'Duration', content = {_args.duration}},
		Cell{name = 'Formation Rank', content = {_args.formationrank}},
		Cell{name = '[[Sight_Range|Sight]]', content = {race and (_args.daysight .. ' / ' .. _args.nightsight) or nil}},
		Cell{name = 'Acquisition Range', content = {acquisitionRange > 0 and acquisitionRange or nil}},
		Cell{name = '[[Experience#Determining_Experience_Gained|Level]]', content = {
			level > 0 and ('[[Experience|'.._args.level..']]') or nil}},
		Cell{name = '[[Mana]]', content = {mana.manaDisplay}},
		Cell{name = '[[Mana|Initial Mana]]', content = {mana.initialManaDisplay}},
		Cell{name = '[[Mana#Mana_Gain|Mana Regeneration]]', content = {mana.manaRegenDisplay}},
		Cell{name = 'Selection Priorty', content = {_args.priority}}
	)

	local movement = Shared.movement(_args, 'Uprooted Movement')
	if movement then
		Array.appendWith(widgets, unpack(movement))
	end

	local mercenaryStats = Shared.mercenaryStats(_args)
	if mercenaryStats then
		Array.appendWith(widgets, unpack(mercenaryStats))
	end

	local pathingMap = CustomBuilding._pathingMap(_args)
	if pathingMap then
		Array.appendWith(widgets,
			Title{name = 'Pathing Map'},
			Center{content = {pathingMap}}
		)
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
				gold = CustomBuilding._calculateCostValue('gold'),
				lumber = CustomBuilding._calculateCostValue('lumber'),
				buildTime = _args.build_time,
				food = _args.food,
			}}},
		}
	elseif id == 'requirements' then
		return {Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(_args.requires)}}}
	elseif id == 'builds' then
		return {
			Cell{name = 'Built From:', content = {_args.builtfrom}},
			Cell{name = '[[Hotkeys_per_Race|Hotkey]]', content = {CustomBuilding:_getHotkeys()}},
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(_args.builds)}},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocked Tech', content = {String.convertWikiListToHtmlList(_args.unlocks)}},
			Cell{name = 'Upgrades available', content = {String.convertWikiListToHtmlList(_args.upgrades)}},
			Cell{name = 'Upgrades to', content = {String.convertWikiListToHtmlList(_args.upgradesTo)}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = '[[Hit Points|Hit Points]]', content = {CustomBuilding:_defenseDisplay()}},
			Cell{name = '[[Hit Points#Hit Points Gain|HP Regeneration]]', content = {
				Shared.hitPointsRegeneration(_args, {display = true})}},
			Cell{name = '[[Armor|Armor]]', content = {CustomBuilding:_armorDisplay()}}
		}
	elseif id == 'attack' then return {}
	end

	return widgets
end

---@param args table
---@return string?
function CustomBuilding._pathingMap(args)
	if not args.pathingw and not args.pathingh then return end

	return Template.safeExpand(mw.getCurrentFrame(), 'Pathing Map', {
		centered = 1,
		width = tonumber(args.pathingw) or 1,
		height = tonumber(args.pathingh) or 1,
		startx = tonumber(args.pathingx1) or 1,
		starty = tonumber(args.pathingy1) or 1,
		endx = tonumber(args.pathingx2) or tonumber(args.pathingw) or 1,
		endy = tonumber(args.pathingy2) or tonumber(args.pathingh) or 1,
	})
end

---@param key string
---@return number?
function CustomBuilding._calculateCostValue(key)
	local value = tonumber(_args[key]) or 0
	if value == 0 then return end

	local previousValue = tonumber(_args['previous_' .. key]) or 0

	return value - previousValue
end

---@return string?
function CustomBuilding:_defenseDisplay()
	if Logic.readBool(_args.invulnerable) then
		return
	end

	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if (tonumber(_args.hitpoint_bonus) or 0) > 0 then
		return display .. ' (' .. _args.hp + _args.hitpoint_bonus .. ')'
	end
	return display
end

---@return string
function CustomBuilding:_armorDisplay()
	if Logic.readBool(_args.invulnerable) then
		return ArmorIcon.run(_args.armortype) .. ' invulnerable'
	end

	local display = ArmorIcon.run(_args.armortype)
	if _args.armortype2 then
		display = display .. ' / ' .. ArmorIcon.run(_args.armortype2)
	end
	display = display .. ' ' .. (_args.armor or 0)
	if _args.armor_upgrades then
		display = display.. ' (' .. (_args.armor + _args.armor_upgrades) .. ')'
	end
	return display
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
	if not String.isEmpty(_args.shortcut) then
		if not String.isEmpty(_args.shortcut2) then
			return Hotkeys.hotkey2(_args.shortcut, _args.shortcut2, 'arrow')
		else
			return Hotkeys.hotkey(_args.shortcut)
		end
	end
end

---@param args table
function CustomBuilding:setLpdbData(args)
	local extradata = Table.merge(Shared.buildBaseExtraData(args), {
		foodproduced = args.foodproduced,
		buildtime = args.build_time,
		israngedattack = tostring(args.weapontype ~= 'normal'),
		experience = EXPERIENCE[tonumber(args.level)],
		gold = CustomBuilding._calculateCostValue('gold'),
		lumber = CustomBuilding._calculateCostValue('lumber'),
	})

	mw.ext.LiquipediaDB.lpdb_datapoint('building_' .. (args.name or ''), {
		type = 'building',
		name = args.name or self.pagename,
		image = args.icon and ('Wc3BTN' .. args.icon .. '.png') or nil,
		information = CustomBuilding.getBuildingType(args),
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
	})
end

---@param args table
---@return string
function CustomBuilding.getBuildingType(args)
	local race = Faction.toName(Faction.read(args.race)) or DEFAULT_BUILDING_TYPE_RACE

	if race == Faction.toName('n') then
		race = 'Night Elf'
	end

	return race .. ' Buildings'
end

---@param args table
---@return string[]
function CustomBuilding:getWikiCategories(args)
	return {CustomBuilding.getBuildingType(args)}
end

return CustomBuilding
