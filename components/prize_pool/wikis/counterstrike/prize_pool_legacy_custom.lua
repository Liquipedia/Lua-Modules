---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customHeader(newArgs, CACHED_DATA, header)
	newArgs.qualifier = header.qualifier
	newArgs.points1link = header['points-link']

	return newArgs
end

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

function CustomLegacyPrizePool.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
	-- CS didn't support multiple points (etc), however they supported points (etc) per opponent

	if slot['usdprize' .. opponentIndex] then
		opponentData.usdprize = slot['usdprize' .. opponentIndex]
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

function CustomLegacyPrizePool._setOpponentReward(opponentData, param, value)
	if param == 'seed' then
		PrizePoolLegacy.handleSeed(opponentData, value)
	else
		opponentData[param] = value
	end
end

return CustomLegacyPrizePool
