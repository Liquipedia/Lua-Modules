---
-- @Liquipedia
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils')

---@class RocketleagueTierUtils: TierUtils
local TierCustom = Table.copy(Tier)

local NON_BREAKING_SPACE = '&nbsp;'

--- Builds the display for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@param options table?
---@return string?
function TierCustom.display(tier, tierType, options)
	local tierData, tierTypeData = Tier.raw(tier, tierType)

	if not tierData then return end

	options = options or {}

	local tierDisplayOptions = Tier._displayOptions(options, 'tier')

	if not tierTypeData then
		return Tier.displaySingle(tierData, tierDisplayOptions)
	end

	local tierTypeDisplayOptions = Tier._displayOptions(options, 'tierType')
	tierTypeDisplayOptions.mode = options.mode

	if options.onlyTierTypeIfBoth then
		return Tier.displaySingle(tierTypeData, tierTypeDisplayOptions)
			.. TierCustom.appendTierType2(options.tierType2)
	end

	if options.shortIfBoth then
		options.short = true
	end

	return Tier.displaySingle(tierTypeData, tierDisplayOptions) .. TierCustom.appendTierType2(options.tierType2)
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierData, tierTypeDisplayOptions) .. ')'
end

---@param tierType2 string?
---@return string
function TierCustom.appendTierType2(tierType2)
	if String.isEmpty(tierType2) then
		return ''
	end

	return NON_BREAKING_SPACE .. tierType2
end

return TierCustom
