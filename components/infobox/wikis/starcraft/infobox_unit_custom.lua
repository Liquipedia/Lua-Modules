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
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local UNKNOWN_RACE = 'u'

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

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local contentWithBonus = function(key, bonusNumber)
		return {_args[key] and _args['bonus' .. bonusNumber] and (_args[key] .. ' ' .. _args['bonus' .. bonusNumber])
			or _args[key]}
	end

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
		Cell{name = '[[Game Speed#Cooldown|Cooldown Bonus]]', content = contentWithBonus('cd2', 2)},
		Cell{name = '[[Game Speed#Cooldown|G. Cooldown Bonus]]', content = contentWithBonus('gcd2', 4)},
		Cell{name = '[[Game Speed#Cooldown|A. Cooldown Bonus]]', content = contentWithBonus('acd2', 5)},
		Cell{name = 'Air Attacks', content = {_args.aa}},
		Cell{name = 'Attacks', content = {_args.ga}},
		Cell{name = '[[Game Speed#DPS|DPS]]', content = {_args.dps}},
		Cell{name = '[[Game Speed#DPS|G. DPS]]', content = {_args.gdps}},
		Cell{name = '[[Game Speed#DPS|A. DPS]]', content = {_args.adps}},
		Cell{name = '[[Game Speed#DPS|DPS Bonus]]', content = contentWithBonus('dps2', 3)},
		Cell{name = '[[Game Speed#DPS|G. DPS Bonus]]', content = contentWithBonus('gdps2', 6)},
		Cell{name = '[[Game Speed#DPS|A. DPS Bonus]]', content = contentWithBonus('adps2', 7)},
		Cell{name = '[[Game Speed#Regeneration Rates|Energy Maximum]]', content = contentWithBonus('energy', 8)},
		Cell{name = '[[Game Speed#Regeneration Rates|Starting Energy]]', content = contentWithBonus('energystart', 9)},
		Cell{name = '[[Distance#Range|Sight]]', content = {_args.sight}},
		Cell{name = '[[Distance#Range|Detection Range]]', content = {_args.detection_range}},
		Cell{name = '[[Game Speed#Movement Speed|Speed]]', content = {_args.speed}},
		Cell{name = '[[Game Speed#Movement Speed|Speed Bonus]]', content = contentWithBonus('speed2', 1)},
		Cell{name = 'Morphs into', content = {_args.morphs, _args.morphs2}},
		Cell{name = 'Morphs From', content = {_args.morphsf}},
	}
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
			Cell{name = '[[Shortcuts|Hotkey]]', content = {CustomUnit:_getHotkeys()}}
		}
	elseif id == 'type' then
		local display
		if not _args.size then
			display = _args.type
		elseif _args.type then
			display = _args.size .. ' ' .. _args.type
		end
		return {Cell{name = 'Type', content = {display}}}
	elseif id == 'defense' or id == 'attack' then return {}
	elseif id == 'customcontent' then
		local aoeArgs = Json.parseIfTable(_args.aoe)
		if not aoeArgs or String.isEmpty(aoeArgs.name) then return {} end

		return {
			Title{name = aoeArgs.name},
			Cell{name = 'Inner', content = {aoeArgs.size1}},
			Cell{name = 'Medium', content = {aoeArgs.size2}},
			Cell{name = 'Outer', content = {aoeArgs.size3}},
			Center{content = {aoeArgs.footnotes and ('<small>' .. aoeArgs.footnotes .. '</small>') or nil}}
		}
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
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or UNKNOWN_RACE}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@return string?
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
