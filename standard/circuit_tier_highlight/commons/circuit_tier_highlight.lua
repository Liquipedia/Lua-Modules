---
-- @Liquipedia
-- wiki=commons
-- page=Module:CircuitTierHighlight
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')

local CircuitTierHighlight = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param args table
---@return boolean
function CircuitTierHighlight.tournament(args)
	return Logic.readBool(args.publishertier)
		or String.isNotEmpty(item.extradata.publisherpremier)
		or (String.isNotEmpty(item.extradata.valvepremier) and item.publishertier ~= 'Minor')
end

-- if a wiki needs a different function for matches they can set it up
-- while commons uses the same function as for tournaments
CircuitTierHighlight.match = CircuitTierHighlight.tournament

return Class.export(CircuitTierHighlight)
