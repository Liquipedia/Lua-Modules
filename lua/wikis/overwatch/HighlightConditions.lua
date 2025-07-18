---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data match2|MatchGroupUtilMatch
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	return String.isNotEmpty(data.publishertier or data.publisherTier) and tonumber(data.liquipediatier) == 1
end

return HighlightConditions
