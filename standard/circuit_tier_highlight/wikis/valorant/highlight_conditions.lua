---
-- @Liquipedia
-- wiki=valorant
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param args table
---@return boolean
function HighlightConditions.tournament(data)
	return String.isNotEmpty(data.publishertier)
end

return HighlightConditions
