---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:PrizePool/Legacy/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local LegacyPrizePool = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyAwardPrizePool = {}

-- Template entry point
function CustomLegacyAwardPrizePool.run()
	return LegacyPrizePool.run(CustomLegacyAwardPrizePool)
end

function CustomLegacyAwardPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	opponentData.race = slot['race' .. opponentIndex]

	return opponentData
end

return CustomLegacyAwardPrizePool
