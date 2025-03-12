---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@return boolean
function HighlightConditions.tournament(data)
	return String.isNotEmpty(data.publishertier) and tonumber(data.liquipediatier) == 1
end

return HighlightConditions
