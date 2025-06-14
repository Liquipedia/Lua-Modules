---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')
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

---@param newData table
---@param data table
---@param slot table
---@return table
function CustomLegacyPrizePool.customSlot(newData, data, slot)
	-- Remove points with only image
	-- Table.filter doesn't work on Tables (only Arrays)... Let's use Table.map instead
	newData = Table.map(newData, function(key, value)
		if key == 'points1' or key == 'points2' or key == 'points3' then
			if string.sub(value, 0, 2) == '[[' then
				return key, nil
			end
		end
		return key, value
	end)

	return newData
end

return CustomLegacyPrizePool
