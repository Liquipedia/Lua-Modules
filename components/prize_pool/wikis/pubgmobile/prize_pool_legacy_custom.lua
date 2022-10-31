---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Currency = require('Module:Currency')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})

local CustomLegacyPrizePool = {}
-- Template entry point
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	if Logic.readBool(header.seed) then
		PrizePoolLegacy.assignType(newArgs, 'seed', 'seed')
	end

	-- no manual localcurrency input, so fall back to wiki variable set by infobox league
	if String.isEmpty(header.localcurrency) and String.isNotEmpty(Variables.varDefault('tournament_currency')) then
		local localCurrency = Variables.varDefault('tournament_currency')
		-- only allow valid currencies
		if Currency.raw(localCurrency) then
			newArgs.localcurrency = localCurrency
			data.inputToId.localprize = 'localprize'
		end
	end

	return newArgs
end

return CustomLegacyPrizePool
