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
---@param data match2|MatchGroupUtilMatch
---@param options table
---@return boolean
function HighlightConditions.tournament(data, options)
	options = options or {}

	local publishertier = data.publishertier or data.publisherTier

	if options.onlyHighlightOnValue then
		return publishertier == options.onlyHighlightOnValue
	elseif options.highlightOnAnyValue then
		return String.isNotEmpty(publishertier)
	end

	return String.isNotEmpty(publishertier) and Table.includes(DEFAULT_HIGHLIGHTABLE_VALUES, publishertier)
end

return HighlightConditions
