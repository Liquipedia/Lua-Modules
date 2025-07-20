---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	return String.isNotEmpty(data.publishertier) and tonumber(data.liquipediatier) == 1
end

return HighlightConditions
