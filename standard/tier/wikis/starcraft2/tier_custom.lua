---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})

local TierCustom = Table.copy(Tier)

--- Parses queryData to be processable for other Tier functions
---@param queryData table
---@return string?, string?, table
function TierCustom.parseFromQueryData(queryData)
	return queryData.liquipediatier, queryData.liquipediatiertype, {shortIfBoth = true}
end

--- Builds the display for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@param options table?
---@return string?
function TierCustom.display(tier, tierType, options)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	if not tierData then return end

	options = options or {}

	if not tierTypeData then
		return Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier'))
	end

	local link = options.link

	-- disable link since on sc2 we link only to the tier link not to the tierType
	options.link = false

	if options.shortIfBoth then
		options.short = true
	end

	local display = Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType'))
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier')) .. ')'

	if Logic.readBool(options.link) and tierData.link then
		return Page.makeInternalLink({}, display, tierData.link)
	elseif String.isNotEmpty(options.link) then
		return Page.makeInternalLink({}, display, options.link)
	end

	return display
end

return TierCustom
