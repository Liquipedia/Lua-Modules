---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyPrizePool = {}

-- Template entry point
---@return Html
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

---@param newArgs table
---@param CACHED_DATA table
---@param header table
---@return table
function CustomLegacyPrizePool.customHeader(newArgs, CACHED_DATA, header)
	newArgs.qualifier = header.qualifier
	newArgs['tournamentName'] = header['tournament name']
	newArgs['points1link'] = header['points-link']
	newArgs['resultName'] = header['custom-name']

	return newArgs
end

---@param newData table
---@param CACHED_DATA table
---@param slot table
---@return table
function CustomLegacyPrizePool.customSlot(newData, CACHED_DATA, slot)
	-- Requested by CS so they can do cleanup of tables with incorrect data
	if newData.localprize then
		if newData.localprize:match('[^,%.%d]') then
			error('Unexpected value in localprize for place=' .. slot.place)
		end
	end

	if Logic.readBoolOrNil(slot.noqual) ~= nil then
		slot.qual = not Logic.readBool(slot.noqual)
	end
	newData.forceQualified = Logic.readBoolOrNil(slot.qual)

	return newData
end

---@param opponentData table
---@param CACHED_DATA table
---@param slot table
---@param opponentIndex integer
---@return table
function CustomLegacyPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	-- CS didn't support multiple points (etc), however they supported points (etc) per opponent

	local baseCurrencyPrize = PrizePoolLegacy.BASE_CURRENCY:lower() .. 'prize'
	if slot[baseCurrencyPrize .. opponentIndex] then
		opponentData[baseCurrencyPrize] = slot[baseCurrencyPrize .. opponentIndex]
	end

	if slot['points' .. opponentIndex] then
		local param = CACHED_DATA.inputToId['points']
		CustomLegacyPrizePool._setOpponentReward(opponentData, param, slot['points' .. opponentIndex])
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
