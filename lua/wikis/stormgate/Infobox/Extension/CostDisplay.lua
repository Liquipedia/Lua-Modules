---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Extension/CostDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Faction = require('Module:Faction')
local Icon = require('Module:Icon')
local Table = require('Module:Table')

local CostDisplay = {}

--currently the ingame icons are still temporary
--use placeholders until ingame icons are final and we get them
local ICONS = {
	luminite = {
		default = Abbreviation.make{text = 'Lum', title = 'Luminite'},
	},
	therium = {
		default = Abbreviation.make{text = 'The', title = 'Therium'},
	},
	buildTime = {
		default = Icon.makeIcon{iconName = 'time', size = '100%'},
	},
	supply = {
		--expect to get different ones per faction
		default = '[[File:Supply-terran.gif|baseline|link=Supply]]',
	},
	animus = {
		default = Abbreviation.make{text = 'Ani', title = 'Animus'},
	},
	power = {
		default = Abbreviation.make{text = 'Pow', title = 'Power'},
	},
}
local ORDER = {
	'luminite',
	'therium',
	'supply',
	'animus',
	'power',
	'buildTime',
}
local CONCAT_VALUE = '&nbsp;'

---@class StormgateCostDisplayArgsValues
---@field faction string?
---@field luminite string|number?
---@field therium string|number?
---@field buildTime string|number?
---@field supply string|number?
---@field animus string|number?
---@field power string|number?
---@field luminiteForced boolean?
---@field theriumForced boolean?
---@field buildTimeForced boolean?
---@field supplyForced boolean?
---@field animusForced boolean?
---@field powerForced boolean?
---@field luminiteTotal string|number?
---@field theriumTotal string|number?
---@field buildTimeTotal string|number?
---@field supplyTotal string|number?
---@field animusTotal string|number?
---@field powerTotal string|number?

---@param args StormgateCostDisplayArgsValues
---@return string?
function CostDisplay.run(args)
	if not args then
		return nil
	end

	local faction = Faction.read(args.faction)

	local displays = {}
	for _, key in pairs(ORDER) do
		local iconData = ICONS[key]
		local icon = iconData[faction] or iconData.default
		local value = tonumber(args[key]) or 0
		if value ~= 0 or args[key .. 'Forced'] or args[key .. 'Total'] then
			local display = icon .. CONCAT_VALUE .. value ..
				(args[key .. 'Total'] and (CONCAT_VALUE .. '(' .. args[key .. 'Total'] .. ')') or '')
			table.insert(displays, display)
		end
	end

	if Table.isEmpty(displays) then
		return nil
	end

	return table.concat(displays, CONCAT_VALUE)
end

return CostDisplay
