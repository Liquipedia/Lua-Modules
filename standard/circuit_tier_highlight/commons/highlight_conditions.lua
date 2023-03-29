---
-- @Liquipedia
-- wiki=commons
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local CircuitTierHighlight = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param args table
---@return boolean
function CircuitTierHighlight.tournament(data, options)
	data.extradata = data.extradata or {}
	options = options or {}

	if options.onlyHighlightOnValue then
		return data.publishertier == options.onlyHighlightOnValue
	end

	return Logic.nilOr(
		Logic.readBoolOrNil(data.publishertier),
		String.isNotEmpty(data.extradata.publisherpremier)
			or (String.isNotEmpty(data.extradata.valvepremier) and data.publishertier ~= 'Minor')
	)
end

return Class.export(CircuitTierHighlight)
