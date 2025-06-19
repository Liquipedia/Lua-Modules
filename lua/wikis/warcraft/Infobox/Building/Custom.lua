---
-- @Liquipedia
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ArmorIcon = Lua.import('Module:ArmorIcon')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local CostDisplay = Lua.import('Module:Infobox/Extension/CostDisplay')
local Faction = Lua.import('Module:Faction')
local Hotkeys = Lua.import('Module:Hotkey')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')
local Shared = Lua.import('Module:Infobox/Extension/BuildingUnitShared')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new(Building)

local CustomInjector = Class.new(Injector)

local EXPERIENCE = Lua.import('Module:Experience', {loadData = true})

local DEFAULT_BUILDING_TYPE_RACE = 'Neutral'
local ICON_HP = '[[File:Icon_Hitpoints.png|link=Hit Points]]'
local ICON_FOOD = '[[File:Food_WC3_Icon.gif|15px|link=Food]]'
local ADDITIONAL_BUILDING_RACES = {
	creeps = 'Creeps',
	neutral = 'Creeps',
	c = 'Creeps',
}

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	return building:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomBuilding:addCustomCells(widgets)
	local args = self.args

	local mana = Shared.manaValues(args)
	local acquisitionRange = tonumber(args.acq_range) or 0
	local level = tonumber(args.level) or 0
	local race = Faction.toName(Faction.read(args.race)) or ADDITIONAL_BUILDING_RACES[string.lower(args.race or '')]

	Array.appendWith(widgets,
		Cell{name = '[[Food supplied|Food]]', content = {
			args.foodproduced and (ICON_FOOD .. ' ' .. args.foodproduced) or nil,
		}},
		Cell{name = '[[Race]]', content = {race and ('[[' .. race .. ']]') or args.race}},
		Cell{name = '[[Targeting#Target_Classifications|Classification]]', content = {
			args.class and String.convertWikiListToHtmlList(args.class) or nil}},
		Cell{name = 'Sleeps', content = {args.sleeps}},
		Cell{name = 'Cargo Capacity', content = {args.cargo_capacity}},
		Cell{name = 'Morphs into', content = {args.morphs}},
		Cell{name = 'Duration', content = {args.duration}},
		Cell{name = 'Formation Rank', content = {args.formationrank}},
		Cell{name = '[[Sight_Range|Sight]]', content = {race and (args.daysight .. ' / ' .. args.nightsight) or nil}},
		Cell{name = 'Acquisition Range', content = {acquisitionRange > 0 and acquisitionRange or nil}},
		Cell{name = '[[Experience#Determining_Experience_Gained|Level]]', content = {
			level > 0 and ('[[Experience|'..args.level..']]') or nil}},
		Cell{name = '[[Mana]]', content = {mana.manaDisplay}},
		Cell{name = '[[Mana|Initial Mana]]', content = {mana.initialManaDisplay}},
		Cell{name = '[[Mana#Mana_Gain|Mana Regeneration]]', content = {mana.manaRegenDisplay}},
		Cell{name = 'Selection Priorty', content = {args.priority}}
	)

	local movement = Shared.movement(args, 'Uprooted Movement')
	if movement then
		Array.appendWith(widgets, unpack(movement))
	end

	local mercenaryStats = Shared.mercenaryStats(args)
	if mercenaryStats then
		Array.appendWith(widgets, unpack(mercenaryStats))
	end

	local pathingMap = CustomBuilding._pathingMap(args)
	if pathingMap then
		Array.appendWith(widgets,
			Title{children = 'Pathing Map'},
			Center{children = {pathingMap}}
		)
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
	if id == 'custom' then
		return self.caller:addCustomCells(widgets)
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = args.race,
				gold = self.caller:_calculateCostValue('gold'),
				lumber = self.caller:_calculateCostValue('lumber'),
				buildTime = args.build_time,
				food = args.food,
			}}},
		}
	elseif id == 'requirements' then
		return {Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(args.requires)}}}
	elseif id == 'builds' then
		return {
			Cell{name = 'Built From:', content = {args.builtfrom}},
			Cell{name = '[[Hotkeys_per_Race|Hotkey]]', content = {self.caller:_getHotkeys()}},
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(args.builds)}},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocked Tech', content = {String.convertWikiListToHtmlList(args.unlocks)}},
			Cell{name = 'Upgrades available', content = {String.convertWikiListToHtmlList(args.upgrades)}},
			Cell{name = 'Upgrades to', content = {String.convertWikiListToHtmlList(args.upgradesTo)}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = '[[Hit Points|Hit Points]]', content = {self.caller:_defenseDisplay()}},
			Cell{name = '[[Hit Points#Hit Points Gain|HP Regeneration]]', content = {
				Shared.hitPointsRegeneration(args, {display = true})}},
			Cell{name = '[[Armor|Armor]]', content = {self.caller:_armorDisplay()}}
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
function CustomBuilding:_calculateCostValue(key)
	local value = tonumber(self.args[key]) or 0
	if value == 0 then return end

	local previousValue = tonumber(self.args['previous_' .. key]) or 0

	return value - previousValue
end

---@return string?
function CustomBuilding:_defenseDisplay()
	if Logic.readBool(self.args.invulnerable) then
		return
	end

	local display = ICON_HP .. ' ' .. (self.args.hp or 0)
	if (tonumber(self.args.hitpoint_bonus) or 0) > 0 then
		return display .. ' (' .. (tonumber(self.args.hp) + tonumber(self.args.hitpoint_bonus)) .. ')'
	end
	return display
end

---@return string
function CustomBuilding:_armorDisplay()
	if Logic.readBool(self.args.invulnerable) then
		return ArmorIcon.run(self.args.armortype) .. ' invulnerable'
	end

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
function CustomBuilding:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or Faction.defaultFaction}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@return string?
function CustomBuilding:_getHotkeys()
	if not String.isEmpty(self.args.shortcut) then
		if not String.isEmpty(self.args.shortcut2) then
			return Hotkeys.hotkey2{hotkey1 = self.args.shortcut, hotkey2 = self.args.shortcut2, seperator = 'arrow'}
		else
			return Hotkeys.hotkey{hotkey = self.args.shortcut}
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
		gold = self:_calculateCostValue('gold'),
		lumber = self:_calculateCostValue('lumber'),
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
