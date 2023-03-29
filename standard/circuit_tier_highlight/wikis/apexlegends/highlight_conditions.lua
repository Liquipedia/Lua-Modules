---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:HighlightConditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')

local CircuitTierHighlight = {}

--- Check arguments or queryData if the tournament should be highlighted
---@param args table
---@return boolean
function CircuitTierHighlight.tournament(args)
	args.extradata = args.extradata or {}

	return String.isNotEmpty(args.extradata['is ea major']) or String.isNotEmpty(args.publishertier)
end

-- if a wiki needs a different function for matches they can set it up
-- while commons uses the same function as for tournaments
CircuitTierHighlight.match = CircuitTierHighlight.tournament

return Class.export(CircuitTierHighlight)
