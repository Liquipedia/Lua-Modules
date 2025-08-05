---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyPrizePool = {}

-- Template entry point
---@return Html
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

---@param opponentData table
---@param CACHED_DATA table
---@param slot table
---@param opponentIndex integer
---@return table
function CustomLegacyPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	-- ML has use case of same placement but has different earnings

	local baseCurrencyPrize = PrizePoolLegacy.BASE_CURRENCY:lower() .. 'prize'
	if slot[baseCurrencyPrize .. opponentIndex] then
		opponentData[baseCurrencyPrize] = slot[baseCurrencyPrize .. opponentIndex]
	end

	if slot['localprize' .. opponentIndex] then
		local param = CACHED_DATA.inputToId['localprize']
		CustomLegacyPrizePool._setOpponentReward(opponentData, param, slot['localprize' .. opponentIndex])
	end

	return opponentData
end

---@param opponentData table
---@param param string
---@param value string
function CustomLegacyPrizePool._setOpponentReward(opponentData, param, value)
	if param == 'seed' then
		PrizePoolLegacy.handleSeed(opponentData, value, 1)
	else
		opponentData[param] = value
	end
end

return CustomLegacyPrizePool
