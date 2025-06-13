---
-- @Liquipedia
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils')

local NON_BREAKING_SPACE = '&nbsp;'

---@class CounterstrikeTierUtils: TierUtils
local TierCustom = Table.copy(Tier)

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

	if options.onlyTierTypeIfBoth or (options.onlyDisplayPrioritized and tierTypeData.prioTierType) then
		return Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType'))
	elseif options.onlyDisplayPrioritized then
		return Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier'))
	end

	if options.shortIfBoth then
		options.short = true
	end

	return Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType'))
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier')) .. ')'
end

return TierCustom
