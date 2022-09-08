---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}

local _remove_Place

-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	if Logic.readBool(header.seed) then
		PrizePoolLegacy.assignType(newArgs, 'seed', 'seed')
	end
	_remove_place = Loigc.readBool(header.removePlace)

	return newArgs
end

function CustomLegacyPrizePool.customSlot(newData, CACHED_DATA, slot)
	if _remove_Place then
		newData["place"] = nil
	end

	return newData
end

return CustomLegacyPrizePool
