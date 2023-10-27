---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Hotkeys = require('Module:Hotkey')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Building = Lua.import('Module:Infobox/Building', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomBuilding = Class.new()

local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local UNKNOWN_RACE = 'u'

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

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Attributes', content = {_args.att}},
		Cell{name = '[[Distance#Sight Range|Sight]]', content = {_args.sight}},
		Cell{name = '[[Distance#Sight Range|Detection Range]]', content = {_args.detection_range}},
		Cell{name = 'Type', content = {_args.type}},
		Cell{name = 'Size', content = {_args.size}},
		Cell{name = '[[Game Speed#DPS|Energy Maximum]]', content = CustomBuilding._contentWithBonus('energy', 8)},
		Cell{name = '[[Game Speed#Regeneration Rates|Starting Energy]]',
			content = CustomBuilding._contentWithBonus('energystart', 9)},
		Cell{name = 'Animated', content = {_args.banimation}},
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
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
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(_args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Shortcuts|Hotkey]]', content = {CustomBuilding:_getHotkeys()}}
		}
	elseif id == 'builds' then
		return {
			Cell{name = 'Built By', content = {_args.builtfrom}},
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(_args.builds)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(_args.morphs)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(_args.morphsf)}},
			Cell{name = 'Add-Ons', content = {String.convertWikiListToHtmlList(_args.addons)}},
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
			Cell{name = 'Damage', content = {_args.damage}},
			Cell{name = '[[Distance#Range|Range]]', content = {_args.range}},
			Cell{name = '[[Game Speed#Cooldown|Cooldown]]', content = {_args.cooldown}},
			Cell{name = '[[Game Speed#Cooldown|Cooldown Bonus]]', content = CustomBuilding._contentWithBonus('cd2', 2)},
			Cell{name = '[[Game Speed#DPS|DPS]]', content = {_args.dps}},
			Cell{name = '[[Game Speed#DPS|DPS Bonus]]', content = CustomBuilding._contentWithBonus('dps2', 3)},
			Cell{name = 'Ground Attack', content = {_args.ground_attack}},
			Cell{name = '[[Distance#Range|Ground Range]]', content = {_args.grange}},
			Cell{name = '[[Game Speed#Cooldown|G. Cooldown]]', content = {_args.gcd}},
			Cell{name = '[[Game Speed#Cooldown|G. Cooldown Bonus]]', content = CustomBuilding._contentWithBonus('gcd2', 4)},
			Cell{name = '[[Game Speed#DPS|G. DPS]]', content = {_args.gdps}},
			Cell{name = '[[Game Speed#DPS|G. DPS Bonus]]', content = CustomBuilding._contentWithBonus('gdps2', 6)},
			Cell{name = 'Air Attack', content = {_args.air_attack}},
			Cell{name = '[[Distance#Range|Air Range]]', content = {_args.arange}},
			Cell{name = '[[Game Speed#Cooldown|A. Cooldown]]', content = {_args.acd}},
			Cell{name = '[[Game Speed#Cooldown|A. Cooldown Bonus]]', content = CustomBuilding._contentWithBonus('acd2', 5)},
			Cell{name = '[[Game Speed#DPS|A. DPS]]', content = {_args.adps}},
			Cell{name = '[[Game Speed#DPS|A. DPS Bonus]]', content = CustomBuilding._contentWithBonus('adps2', 7)},
		}
	end
	return widgets
end

---@param key string
---@param bonusNumber integer
---@return string[]
function CustomBuilding._contentWithBonus(key, bonusNumber)
	return {_args[key] and _args['bonus' .. bonusNumber] and (_args[key] .. ' ' .. _args['bonus' .. bonusNumber])
		or _args[key]}
end

---@return CustomWidgetInjector
function CustomBuilding:createWidgetInjector()
	return CustomInjector()
end

---@return string
function CustomBuilding:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (_args.hp or 0)
	if _args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. _args.shield
	end
	return display .. ' ' .. ICON_ARMOR .. ' ' .. (_args.armor or 1)
end

---@param args table
---@return string
function CustomBuilding:nameDisplay(args)
	local raceIcon = Faction.Icon{size = 'large', faction = args.race or UNKNOWN_RACE}
	raceIcon = raceIcon and (raceIcon .. '&nbsp;') or ''

	return raceIcon .. (args.name or self.pagename)
end

---@return string?
function CustomBuilding:_getHotkeys()
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
function CustomBuilding:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint(args.name or '', {
		name = args.name,
		type = 'building',
		information = Faction.read(args.race),
		image = args.image,
	})
end

---@param args table
---@return string[]
function CustomBuilding:getWikiCategories(args)
	if String.isEmpty(args.race) then
		return {}
	end

	local race = Faction.read(args.race)

	if race == UNKNOWN_RACE then
		return {}
	elseif not race then
		return {'InfoboxRaceError'}
	end

	return {Faction.toName(race) .. ' Buildings'}
end

return CustomBuilding
