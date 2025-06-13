---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local LegacyPrizePool = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyAwardPrizePool = {}

-- Template entry point
---@return Html
function CustomLegacyAwardPrizePool.run()
	return LegacyPrizePool.run(CustomLegacyAwardPrizePool)
end

---@param opponentData table
---@param CACHED_DATA table
---@param slot table
---@param opponentIndex integer
---@return table
function CustomLegacyAwardPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	opponentData.race = slot['race' .. opponentIndex]

	return opponentData
end

return CustomLegacyAwardPrizePool
