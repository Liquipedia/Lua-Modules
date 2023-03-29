---
-- @Liquipedia
-- wiki=overwatch
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
	return String.isNotEmpty(args.publishertier)
end

CircuitTierHighlight.match = CircuitTierHighlight.tournament

return Class.export(CircuitTierHighlight)
