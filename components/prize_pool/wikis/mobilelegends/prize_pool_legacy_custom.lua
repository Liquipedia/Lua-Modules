---
-- @Liquipedia
-- wiki=mobilelegends
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

function CustomLegacyPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	-- ML has use case of same placement but has different earnings

	if slot['usdprize' .. opponentIndex] then
		opponentData.usdprize = slot['usdprize' .. opponentIndex]
	end

	if slot['localprize' .. opponentIndex] then
		local param = CACHED_DATA.inputToId['localprize']
		CustomLegacyPrizePool._setOpponentReward(opponentData, param, slot['localprize' .. opponentIndex])
	end

	return opponentData
end

function CustomLegacyPrizePool._setOpponentReward(opponentData, param, value)
	if param == 'seed' then
		PrizePoolLegacy.handleSeed(opponentData, value, 1)
	else
		opponentData[param] = value
	end
end

return CustomLegacyPrizePool
