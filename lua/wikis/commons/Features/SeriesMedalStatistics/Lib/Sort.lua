---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Lib/Sort
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Types = Lua.import('Module:Features/SeriesMedalStatistics/Types')

local Sort = {}

---@param tbl table<string, SeriesMedalStatsDataSet>
---@param key1 any
---@param key2 any
---@return boolean
function Sort.rowSort(tbl, key1, key2)
	---@param key string|integer
	---@return boolean?
	local compare = function(key)
		local val1 = tbl[key1][key] or 0
		local val2 = tbl[key2][key] or 0
		if val1 == val2 then return end
		return val1 > val2
	end

	return Logic.nilOr(
		compare(1),
		compare(2),
		compare(Types.optionalPlacementColumns.THIRD),
		compare(Types.optionalPlacementColumns.SEMIFINALIST),
		compare(Types.optionalPlacementColumns.FOURTH),
		key1:lower() < key2:lower()
	)
end

return Sort
