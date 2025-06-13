---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	return (data.publishertier == 'highlighted')
end

return HighlightConditions
