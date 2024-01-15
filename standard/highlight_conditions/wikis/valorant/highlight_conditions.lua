---
-- @Liquipedia
-- wiki=valorant
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@return boolean
function HighlightConditions.tournament(data)
	return (data.publishertier == 'highlighted')
end

return HighlightConditions
