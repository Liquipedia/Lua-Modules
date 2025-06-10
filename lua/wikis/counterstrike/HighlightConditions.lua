---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Table = require('Module:Table')

local HighlightConditions = {}

local DEFAULT_HIGHLIGHTABLE_VALUES = {
	'Major Championship',
	'Minor Championship',
	'Major Qualifier',
	'RMR Event'
}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@param options table
---@return boolean
function HighlightConditions.tournament(data, options)
	options = options or {}

	if options.onlyHighlightOnValue then
		return data.publishertier == options.onlyHighlightOnValue
	elseif options.highlightOnAnyValue then
		return String.isNotEmpty(data.publishertier)
	end

	return String.isNotEmpty(data.publishertier) and Table.includes(DEFAULT_HIGHLIGHTABLE_VALUES, data.publishertier)
end

return HighlightConditions
