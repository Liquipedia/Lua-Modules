---
-- @Liquipedia
-- page=Module:Infobox/Extension/CostDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')

local CostDisplay = {}

local ICONS = {
	gold = '[[File:Gold WC3 Icon.gif|15px|link=Gold]]',
	lumber = '[[File:Lumber WC3 Icon.gif|15}px|link=Lumber]]',
	buildTime = '[[File:Cooldown Clock.png|15px]]',
	food = '[[File:Food WC3 Icon.gif|15px|link=Food]]',
}
local ORDER = {
	'gold',
	'lumber',
	'buildTime',
	'food',
}
local CONCAT_VALUE = '&nbsp;'

---@class wcCostDisplayArgsValues
---@field gold string?
---@field lumber string|number?
---@field buildTime string|number?
---@field food string|number?
---@field goldForced boolean?
---@field lumberForced boolean?
---@field buildTimeForced boolean?
---@field foodForced boolean?
---@field goldTotal string|number?
---@field lumberTotal string|number?
---@field buildTimeTotal string|number?
---@field foodTotal string|number?

---@param args scCostDisplayArgsValues
---@return string?
function CostDisplay.run(args)
	if not args then
		return nil
	end

	local displays = {}
	for _, key in pairs(ORDER) do
		local value = tonumber(args[key]) or 0
		if value ~= 0 or args[key .. 'Forced'] or args[key .. 'Total'] then
			local display = ICONS[key] .. CONCAT_VALUE .. value ..
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
