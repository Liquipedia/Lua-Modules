---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	data.extradata = data.extradata or {}

	return String.isNotEmpty(data.extradata['is ea major']) or String.isNotEmpty(data.publishertier)
end

return HighlightConditions
