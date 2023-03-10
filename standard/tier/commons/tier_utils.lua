---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tier/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- module intended to be moved to `Module:Tier` after the old ones usage has been eliminated

local Logic = require('Module:Logic')
local FnUtil = require('Module:FnUtil')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local TierData = mw.loadData('Module:Tier/Data')

local NON_BREAKING_SPACE = '&nbsp;'

local Tier = {}

--- Converts input to standardized identifier format
---@param input string|integer|nil
---@return string|integer|nil
function Tier.toIdentifier(input)
	if String.isEmpty(input) then
		return
	end

	return tonumber(input)
		or string.lower(input):gsub(' ', '')
end

--- Retrieves the raw data for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return table?, table?
function Tier._raw(tier, tierType)
	return (TierData.tiers or {})[Tier.toIdentifier(tier)],
		(TierData.tierTypes or {})[Tier.toIdentifier(tierType)]
end

--- Checks if a valid (tier, tierType) tuple is provided
---@param tier integer
---@param tierType string?
---@return boolean
function Tier.isValid(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	if not tierData then return false end

	if not tierTypeData and String.isNotEmpty(tierType) then
		return false
	end

	return true
end

--- Converts input to (storage) values for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return integer?, string|integer|nil
function Tier.toValue(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	return (tierData or {}).value, (tierTypeData or {}).value
end

--- Converts input to displayNames for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return string?, string?
function Tier.toName(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	return (tierData or {}).name, (tierTypeData or {}).name
end

--- Converts input to short names for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return string?, string?
function Tier.toShortName(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	return (tierData or {}).short, (tierTypeData or {}).short
end

--- Converts input to categories for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return string?, string?
function Tier.toCategory(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	return (tierData or {}).category, (tierTypeData or {}).category
end

--- Converts input to a sort value for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@return string
function Tier.toSortValue(tier, tierType)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	return (tierData or {}).sort .. ((tierTypeData or {}).sort or '')
end

--- Parses queryData to be processable for other Tier functions
--- overwritable on a per wiki basis if additional data needs to be passed
---@param queryData table
---@return string?, string?, table
function Tier.parseFromQueryData(queryData)
	return queryData.liquipediatier, queryData.liquipediatiertype, {}
end

--- Builds the display for a given (tier, tierType) tuple
---@param tier integer
---@param tierType string?
---@param options table?
---@return string?
function Tier.display(tier, tierType, options)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	if not tierData then return end

	options = options or {}

	if not tierTypeData then
		return Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier'))
	end

	if options.onlyTierTypeIfBoth then
		return Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType'))
	end

	if options.shortIfBoth then
		options.short = true
	end

	return Tier.displaySingle(tierTypeData, Tier._displayOptions(options, 'tierType'))
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierData, Tier._displayOptions(options, 'tier')) .. ')'
end

--- reads the (global) options and retrieves the values needed for a give prefix
--- overwritable on a per wiki basis if additional data needs to be passed
---@param options table
---@param prefix 'tier'|'tierType'
---@return table
function Tier._displayOptions(options, prefix)
	return {
		link = options[prefix .. 'Link'] or options.link,
		short = Logic.readBool(options[prefix .. 'Short'] or options.short),
	}
end

--- Builds the display for a given tierData/tierTypeData table
--- overwritable on a per wiki basis if adjustments are needed
---@param data table
---@param options {short: boolean, link: boolean|string}
---@return string
function Tier.displaySingle(data, options)
	local display = options.short and data.short or data.name

	if Logic.readBool(options.link) and data.link then
		return Page.makeInternalLink({}, display, data.link)
	elseif String.isNotEmpty(options.link) then
		return Page.makeInternalLink({}, display, options.link)
	end

	return display
end

--- Iterate over tiers/tierTypes in a sorted order
---@param subTable 'tiers'|'tierTypes'
---@return function
function Tier.iterate(subTable)
	return Table.iter.spairs(TierData[subTable], function(tierData, key1, key2)
		return tierData[key1].sort < tierData[key2].sort
	end)
end

Tier.legacyNumbers = FnUtil.memoize(function()
	return Table.map(TierData.tiers, function(key, data) return data.name:lower():gsub(' ', ''), tonumber(key) or '' end)
end)

Tier.legacyShortNumbers = FnUtil.memoize(function()
	return Table.map(TierData.tiers, function(key, data) return data.short:lower():gsub(' ', ''), tonumber(key) or '' end)
end)

--- Legacy: Converts legacy tier input to its numeric value. DEPRECATED!!!
---@param tier string|integer|nil
---@return integer
---@deprecated
function Tier.toNumber(tier)
	return tonumber(tier)
		or Tier.legacyNumbers[string.lower(tier or ''):gsub(' ', '')]
		or Tier.legacyShortNumbers[string.lower(tier or ''):gsub(' ', '')]
end

return Tier
