---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StarcraftUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local UNKNOWN_RACE = 'u'

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'cost' and not String.isEmpty(args.min) then
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
				supply = args.supply or args.control or args.psy,
				supplyTotal = args.totalsupply or args.totalcontrol or args.totalpsy,
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Shortcuts|Hotkey]]', content = {CustomUnit:_getHotkeys(args)}}
		}
	elseif id == 'type' then
		local display
		if not args.size then
			display = args.type
		elseif args.type then
			display = args.size .. ' ' .. args.type
		end
		return {Cell{name = 'Type', content = {display}}}
	elseif id == 'defense' or id == 'attack' then return {}
	elseif id == 'customcontent' then
		local aoeArgs = Json.parseIfTable(args.aoe)
		if not aoeArgs or String.isEmpty(aoeArgs.name) then return {} end

		return {
			Title{children = aoeArgs.name},
			Cell{name = 'Inner', content = {aoeArgs.size1}},
			Cell{name = 'Medium', content = {aoeArgs.size2}},
			Cell{name = 'Outer', content = {aoeArgs.size3}},
			Center{children = {aoeArgs.footnotes and ('<small>' .. aoeArgs.footnotes .. '</small>') or nil}}
		}
	elseif id == 'custom' then
		return self.caller:getCustomCells(widgets)
	end
	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomUnit:getCustomCells(widgets)
	local args = self.args
	local contentWithBonus = function(key, bonusNumber)
		return {args[key] and args['bonus' .. bonusNumber] and (args[key] .. ' ' .. args['bonus' .. bonusNumber])
			or args[key]}
	end

	return {
		Title{children = 'Unit stats'},
		Cell{name = 'Attributes', content = {args.att}},
		Cell{name = 'Defense', content = {CustomUnit:_defenseDisplay(args)}},
		Cell{name = 'Damage', content = {args.damage}},
		Cell{name = 'Ground Damage', content = {args.ground_attack}},
		Cell{name = 'Air Damage', content = {args.air_attack}},
		Cell{name = '[[Distance#Range|Range]]', content = {args.range}},
		Cell{name = '[[Distance#Range|Ground Range]]', content = {args.grange}},
		Cell{name = '[[Distance#Range|Air Range]]', content = {args.arange}},
		Cell{name = '[[Distance#Range|Minimum Range]]', content = {args.mrange}},
		Cell{name = '[[Distance#Range|Minimum A. Range]]', content = {args.marange}},
		Cell{name = '[[Distance#Range|Minimum G. Range]]', content = {args.mgrange}},
		Cell{name = '[[Distance#Leash Range|Leash Range]]', content = {args.lrange}},
		Cell{name = '[[Game Speed#Cooldown|Cooldown]]', content = {args.cooldown}},
		Cell{name = '[[Game Speed#Cooldown|G. Cooldown]]', content = {args.gcd}},
		Cell{name = '[[Game Speed#Cooldown|A. Cooldown]]', content = {args.acd}},
		Cell{name = '[[Game Speed#Cooldown|Cooldown Bonus]]', content = contentWithBonus('cd2', 2)},
		Cell{name = '[[Game Speed#Cooldown|G. Cooldown Bonus]]', content = contentWithBonus('gcd2', 4)},
		Cell{name = '[[Game Speed#Cooldown|A. Cooldown Bonus]]', content = contentWithBonus('acd2', 5)},
		Cell{name = 'Air Attacks', content = {args.aa}},
		Cell{name = 'Attacks', content = {args.ga}},
		Cell{name = '[[Game Speed#DPS|DPS]]', content = {args.dps}},
		Cell{name = '[[Game Speed#DPS|G. DPS]]', content = {args.gdps}},
		Cell{name = '[[Game Speed#DPS|A. DPS]]', content = {args.adps}},
		Cell{name = '[[Game Speed#DPS|DPS Bonus]]', content = contentWithBonus('dps2', 3)},
		Cell{name = '[[Game Speed#DPS|G. DPS Bonus]]', content = contentWithBonus('gdps2', 6)},
		Cell{name = '[[Game Speed#DPS|A. DPS Bonus]]', content = contentWithBonus('adps2', 7)},
		Cell{name = '[[Game Speed#Regeneration Rates|Energy Maximum]]', content = contentWithBonus('energy', 8)},
		Cell{name = '[[Game Speed#Regeneration Rates|Starting Energy]]', content = contentWithBonus('energystart', 9)},
		Cell{name = '[[Distance#Range|Sight]]', content = {args.sight}},
		Cell{name = '[[Distance#Range|Detection Range]]', content = {args.detection_range}},
		Cell{name = '[[Game Speed#Movement Speed|Speed]]', content = {args.speed}},
		Cell{name = '[[Game Speed#Movement Speed|Speed Bonus]]', content = contentWithBonus('speed2', 1)},
		Cell{name = 'Morphs into', content = {args.morphs, args.morphs2}},
		Cell{name = 'Morphs From', content = {args.morphsf}},
	}
end

---@param args table
---@return string
function CustomUnit:_defenseDisplay(args)
	local display = ICON_HP .. ' ' .. (args.hp or 0)
	if args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. args.shield
	end
	display = display .. ' ' .. ICON_ARMOR .. ' ' .. (args.armor or 1)

	return display
end

---@param args table
---@return string
function CustomUnit:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or UNKNOWN_RACE}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@param args table
---@return string?
function CustomUnit:_getHotkeys(args)
	local display
	if not String.isEmpty(args.shortcut) then
		if not String.isEmpty(args.shortcut2) then
			display = Hotkeys.hotkey2{hotkey1 = args.shortcut, hotkey2 = args.shortcut2, seperator = 'arrow'}
		else
			display = Hotkeys.hotkey{hotkey = args.shortcut}
		end
	end

	return display
end

---@param args table
function CustomUnit:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint(args.name or '', {
		name = args.name,
		type = 'unit',
		information = Faction.read(args.race),
		image = args.image,
	})
end

---@param args table
---@return string[]
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
