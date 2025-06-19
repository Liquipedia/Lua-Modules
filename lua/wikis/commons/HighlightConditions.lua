---
-- @Liquipedia
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local HighlightConditions = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param data table
---@param options table?
---@return boolean
function HighlightConditions.tournament(data, options)
	data.extradata = data.extradata or {}
	options = options or {}

	if options.onlyHighlightOnValue then
		return data.publishertier == options.onlyHighlightOnValue
	end

	return Logic.nilOr(
		Logic.readBoolOrNil(data.publishertier),
		String.isNotEmpty(data.publishertier) or nil,
		String.isNotEmpty(data.extradata.publisherpremier)
	)
end

return HighlightConditions
