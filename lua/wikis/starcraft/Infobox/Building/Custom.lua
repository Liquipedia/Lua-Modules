---
-- @Liquipedia
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

local Injector = Lua.import('Module:Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class StarcraftBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new(Building)
local CustomInjector = Class.new(Injector)

local ICON_HP = '[[File:Icon_Hitpoints.png|link=]]'
local ICON_SHIELDS = '[[File:Icon_Shields.png|link=Plasma Shield]]'
local ICON_ARMOR = '[[File:Icon_Armor.png|link=Armor]]'
local UNKNOWN_RACE = 'u'

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	return building:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Attributes', content = {args.att}},
			Cell{name = '[[Distance#Sight Range|Sight]]', content = {args.sight}},
			Cell{name = '[[Distance#Sight Range|Detection Range]]', content = {args.detection_range}},
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Size', content = {args.size}},
			Cell{name = '[[Game Speed#DPS|Energy Maximum]]', content = caller:_contentWithBonus('energy', 8)},
			Cell{name = '[[Game Speed#Regeneration Rates|Starting Energy]]',
				content = caller:_contentWithBonus('energystart', 9)},
			Cell{name = 'Animated', content = {args.banimation}},
		}
	elseif id == 'cost' then
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
			}}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Requirements', content = {String.convertWikiListToHtmlList(args.requires)}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = '[[Shortcuts|Hotkey]]', content = {caller:_getHotkeys()}}
		}
	elseif id == 'builds' then
		return {
			Cell{name = 'Built By', content = {args.builtfrom}},
			Cell{name = 'Builds', content = {String.convertWikiListToHtmlList(args.builds)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(args.morphs)}},
			Cell{name = 'Morphs into', content = {String.convertWikiListToHtmlList(args.morphsf)}},
			Cell{name = 'Add-Ons', content = {String.convertWikiListToHtmlList(args.addons)}},
		}
	elseif id == 'unlocks' then
		return {
			Cell{name = 'Unlocked Tech', content = {String.convertWikiListToHtmlList(args.unlocks)}},
			Cell{name = 'Upgrades available', content = {String.convertWikiListToHtmlList(args.upgrades)}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = 'Defense', content = {caller:_defenseDisplay()}}
		}
	elseif id == 'attack' then
		return {
			Cell{name = 'Damage', content = {args.damage}},
			Cell{name = '[[Distance#Range|Range]]', content = {args.range}},
			Cell{name = '[[Game Speed#Cooldown|Cooldown]]', content = {args.cooldown}},
			Cell{name = '[[Game Speed#Cooldown|Cooldown Bonus]]', content = caller:_contentWithBonus('cd2', 2)},
			Cell{name = '[[Game Speed#DPS|DPS]]', content = {args.dps}},
			Cell{name = '[[Game Speed#DPS|DPS Bonus]]', content = caller:_contentWithBonus('dps2', 3)},
			Cell{name = 'Ground Attack', content = {args.ground_attack}},
			Cell{name = '[[Distance#Range|Ground Range]]', content = {args.grange}},
			Cell{name = '[[Game Speed#Cooldown|G. Cooldown]]', content = {args.gcd}},
			Cell{name = '[[Game Speed#Cooldown|G. Cooldown Bonus]]', content = caller:_contentWithBonus('gcd2', 4)},
			Cell{name = '[[Game Speed#DPS|G. DPS]]', content = {args.gdps}},
			Cell{name = '[[Game Speed#DPS|G. DPS Bonus]]', content = caller:_contentWithBonus('gdps2', 6)},
			Cell{name = 'Air Attack', content = {args.air_attack}},
			Cell{name = '[[Distance#Range|Air Range]]', content = {args.arange}},
			Cell{name = '[[Game Speed#Cooldown|A. Cooldown]]', content = {args.acd}},
			Cell{name = '[[Game Speed#Cooldown|A. Cooldown Bonus]]', content = caller:_contentWithBonus('acd2', 5)},
			Cell{name = '[[Game Speed#DPS|A. DPS]]', content = {args.adps}},
			Cell{name = '[[Game Speed#DPS|A. DPS Bonus]]', content = caller:_contentWithBonus('adps2', 7)},
		}
	end
	return widgets
end

---@param key string
---@param bonusNumber integer
---@return string[]
function CustomBuilding:_contentWithBonus(key, bonusNumber)
	return {self.args[key] and self.args['bonus' .. bonusNumber] and
		(self.args[key] .. ' ' .. self.args['bonus' .. bonusNumber]) or self.args[key]
	}
end

---@return string
function CustomBuilding:_defenseDisplay()
	local display = ICON_HP .. ' ' .. (self.args.hp or 0)
	if self.args.shield then
		display = display .. ' ' .. ICON_SHIELDS .. ' ' .. self.args.shield
	end
	return display .. ' ' .. ICON_ARMOR .. ' ' .. (self.args.armor or 1)
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
	if not String.isEmpty(self.args.shortcut) then
		if not String.isEmpty(self.args.shortcut2) then
			display = Hotkeys.hotkey2{hotkey1 = self.args.shortcut, hotkey2 = self.args.shortcut2, seperator = 'arrow'}
		else
			display = Hotkeys.hotkey{hotkey = self.args.shortcut}
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
