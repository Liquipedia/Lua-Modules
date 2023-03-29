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

return Class.export(CircuitTierHighlight)
