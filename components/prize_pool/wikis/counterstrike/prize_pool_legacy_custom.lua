---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customSlot(newData, CACHED_DATA, slot)
	if newData.freetext1 == '0' then
		newData.freetext1 = nil
	end

	return newData
end

function CustomLegacyPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	if slot['usdprize' .. opponentIndex] then
		opponentData.usdprize = slot['usdprize' .. opponentIndex]
	end

	if slot['points' .. opponentIndex] then
		local param = CACHED_DATA.inputToId['points']
		opponentData[param] = slot['points' .. opponentIndex]
	end

	if slot['localprize' .. opponentIndex] then
		local param = CACHED_DATA.inputToId['localprize']
		opponentData[param] = slot['localprize' .. opponentIndex]
	end

	return opponentData
end

return CustomLegacyPrizePool
