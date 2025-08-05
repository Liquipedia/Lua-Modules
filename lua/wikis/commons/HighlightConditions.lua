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

	local publishertier = data.publishertier or data.publisherTier

	if options.onlyHighlightOnValue then
		return publishertier == options.onlyHighlightOnValue
	end

	return Logic.nilOr(
		Logic.readBoolOrNil(publishertier),
		String.isNotEmpty(publishertier) or nil,
		String.isNotEmpty(data.extradata.publisherpremier)
	)
end

return HighlightConditions
