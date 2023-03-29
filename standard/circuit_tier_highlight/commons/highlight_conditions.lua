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
function CircuitTierHighlight.tournament(args)
	args.extradata = args.extradata or {}

	return Logic.nilOr(
		Logic.readBoolOrNil(args.publishertier),
		String.isNotEmpty(args.extradata.publisherpremier)
			or (String.isNotEmpty(args.extradata.valvepremier) and args.publishertier ~= 'Minor')
	)
end

return Class.export(CircuitTierHighlight)
