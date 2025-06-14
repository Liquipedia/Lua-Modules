---
-- @Liquipedia
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils')

---@class ApexTierUtils: TierUtils
local TierCustom = Table.copy(Tier)

local NON_BREAKING_SPACE = '&nbsp;'

--- Parses queryData to be processable for other Tier functions
---@param queryData table
---@return string?, string?, table
function TierCustom.parseFromQueryData(queryData)
	return queryData.liquipediatier, queryData.liquipediatiertype, {tierTypeShort = true}
end

--- Builds the display for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@param options table?
---@return string?
function TierCustom.display(tier, tierType, options)
	local tierData, tierTypeData = Tier.raw(tier, tierType)

	if not tierData then return end

	options = options or {}

	if not tierTypeData then
		return Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier'))
	end

	if options.shortIfBoth then
		options.short = true
	end

	return Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier'))
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType')) .. ')'
end

return TierCustom
