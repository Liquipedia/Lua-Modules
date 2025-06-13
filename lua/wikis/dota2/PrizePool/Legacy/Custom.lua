---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local PrizePoolLegacy = Lua.import('Module:PrizePool/Legacy')

local CustomLegacyPrizePool = {}

-- Template entry point
---@return Html
function CustomLegacyPrizePool.run()
	return PrizePoolLegacy.run(CustomLegacyPrizePool)
end

---@param newArgs table
---@param data table
---@param header table
---@return table
function CustomLegacyPrizePool.customHeader(newArgs, data, header)
	newArgs.prizesummary = header.prizenote and true or newArgs.prizesummary

	local localCurrency = Variables.varDefault('currency')
	if not newArgs.localcurrency and localCurrency then
		newArgs.localcurrency = localCurrency
		data.inputToId.localprize = 'localprize'
	end

	return newArgs
end

return CustomLegacyPrizePool
