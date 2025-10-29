---
-- @Liquipedia
-- page=Module:Infobox/Extension/CostDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local Table = Lua.import('Module:Table')

local CostDisplay = {}

local ICONS = {
	minerals = {
		default = '[[File:scr-minerals.png|baseline|20px|20px|link=Resources#Minerals|Minerals]]',
	},
	gas = {
		t = '[[File:scr-gas-t.png|baseline|20px|20px|link=Resources#Vespene_Gas|Vespene Gas]]',
		p = '[[File:scr-gas-p.png|baseline|20px|20px|link=Resources#Vespene_Gas|Vespene Gas]]',
		z = '[[File:scr-gas-z.png|baseline|20px|20px|link=Resources#Vespene_Gas|Vespene Gas]]',
		default = '[[File:scr-gas-t.png|baseline|20px|20px|link=Resources#Vespene_Gas|Vespene Gas]]',
	},
	buildTime = {
		default = '[[File:DurationIcon.gif|baseline|20px|20px|link=Game Speed#Build Time|Build Time]]',
	},
	supply = {
		t = '[[File:scr-food-t.png|baseline|20px|20px|link=Resources#Supply|Supply]]',
		p = '[[File:scr-food-p.png|baseline|20px|20px|link=Resources#Supply|Supply]]',
		z = '[[File:scr-food-t.png|baseline|20px|20px|link=Resources#Supply|Supply]]',
		default = '[[File:scr-food-t.png|baseline|20px|20px|link=Resources#Supply|Supply]]',
	},
}
local ORDER = {
	'minerals',
	'gas',
	'buildTime',
	'supply',
}
local CONCAT_VALUE = '&nbsp;'

---@class scCostDisplayArgsValues
---@field faction string?
---@field minerals string|number?
---@field gas string|number?
---@field buildTime string|number?
---@field supply string|number?
---@field mineralsForced boolean?
---@field gasForced boolean?
---@field buildTimeForced boolean?
---@field supplyForced boolean?
---@field mineralsTotal string|number?
---@field gasTotal string|number?
---@field buildTimeTotal string|number?
---@field supplyTotal string|number?

---@param args scCostDisplayArgsValues
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
