---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data match2|MatchGroupUtilMatch
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	return (data.publishertier or data.publisherTier) == 'highlighted'
end

return HighlightConditions
