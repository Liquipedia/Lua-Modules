---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Extension/CostDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Table = require('Module:Table')

local CostDisplay = {}

local ICONS = {
	minerals = {
		default = '[[File:Minerals.gif|baseline|link=Minerals]]',
	},
	gas = {
		t = '[[File:Vespene-terran.gif|baseline|link=Gas]]',
		p = '[[File:Vespene-protoss.gif|baseline|link=Gas]]',
		z = '[[File:Vespene-zerg.gif|baseline|link=Gas]]',
		default = '[[File:Vespene-terran.gif|baseline|link=Gas]]',
	},
	buildTime = {
		t = '[[File:Buildtime_terran.gif|baseline|link=Game Speed]]',
		p = '[[File:Buildtime_protoss.gif|baseline|link=Game Speed]]',
		z = '[[File:Buildtime_zerg.gif|baseline|link=Game Speed]]',
		default = '[[File:Buildtime_terran.gif|baseline|link=Game Speed]]',
	},
	supply = {
		t = '[[File:Supply-terran.gif|baseline|link=Supply]]',
		p = '[[File:Supply-protoss.gif|baseline|link=Supply]]',
		z = '[[File:Supply-zerg.gif|baseline|link=Supply]]',
		default = '[[File:Supply-terran.gif|baseline|link=Supply]]',
	},
}
local ORDER = {
	'minerals',
	'gas',
	'buildTime',
	'supply',
}
local CONCAT_VALUE = '&nbsp;'

---@class sc2CostDisplayArgsValues
---@field faction string?
---@field minerals string|number?
---@field gas string|number?
---@field buildTime string|number?
---@field supply string|number?
---@field mineralsForced boolean?
---@field gasForced boolean?
---@field buildTimeForced boolean?
---@field supplyForced boolean?

---@param args sc2CostDisplayArgsValues
function CostDisplay.run(args)
	if not args then
		return {}
	end

	local faction = Faction.read(args.faction)

	local displays = {}
	for _, key in pairs(ORDER) do
		local iconData = ICONS[key]
		local icon = iconData[faction] or iconData.default
		local value = tonumber(args[key]) or 0
		if value ~= 0 or args[key .. 'Forced'] then
			local display = icon .. CONCAT_VALUE .. value
			table.insert(displays, display)
		end
	end

	if Table.isEmpty(displays) then
		return nil
	end

	return table.concat(displays, CONCAT_VALUE)
end

return CostDisplay
