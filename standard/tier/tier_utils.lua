---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tier/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- module intended to be moved to `Module:Tier` after the old ones usage has been eliminated

local HiddenSort = require('Module:HiddenSort')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local TierData = mw.loadData('Module:Tier/Data')

local NON_BREAKING_SPACE = '&nbsp;'

local Tier = {}

--- Converts input to standardized identifier format
---@param input string|integer|nil
---@return string|integer|nil
function Tier.toIdentifier(input)
	if String.isEmpty(input) then
		return ''
	end

	if Logic.isNumeric(input) then
		return tonumber(input)
	end

	return string.lower(input):gsub(' ', '')
end

--- Retrieves the raw tier/tierType data for a given input
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return table?
function Tier.raw(input, mode)
	return (TierData[mode] or {})[input]
end

--- Converts input to storage value for tier/tierType
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return boolean
function Tier.isValid(input, mode)
	return String.isEmpty(input) or Tier.raw(input, mode) ~= nil
end

--- Converts input to (storage) value for tier/tierType
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return string|integer|nil
function Tier.toValue(input, mode)
	return (Tier.raw(input, mode) or {}).value
end

--- Converts input to display name for tier/tierType
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return string?
function Tier.toName(input, mode)
	return (Tier.raw(input, mode) or {}).name
end

--- Converts input to short name for tier/tierType
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return string?
function Tier.toShortName(input, mode)
	return (Tier.raw(input, mode) or {}).short
end

--- Converts input to (portal) page for tier/tierType
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return string?
function Tier.toLink(input, mode)
	return (Tier.raw(input, mode) or {}).link
end

--- Converts input to a tier/tierType category
---@param input string|integer|nil
---@param mode 'tiers'|'tiertypes'
---@return string?
function Tier.toCategory(input, mode)
	return (Tier.raw(input, mode) or {}).category
end

--- Builds the display for a single tier/tierType
---@param args {
---		input: string|integer|nil,
---		mode: 'tiers'|'tiertypes',
---		short: boolean?,
---		link: string|boolean|nil,
---		sort: boolean?
---	}
---@return string?
function Tier.displaySingle(args)
	args = args or {}

	local tierData = Tier.raw(args.input, args.mode)

	if not tierData then return '' end

	local display = args.short and tierData.short or tierData.name

	if not display then return '' end

	local hiddenSort = args.sort and HiddenSort.run(tierData.sort) or ''

	if Logic.readBool(args.link) and tierData.link then
		return Page.makeInternalLink({}, display, tierData.link)
	elseif String.isNotEmpty(args.link) then
		return Page.makeInternalLink({}, display, args.link)
	end

	return display
end

--- Builds the display for a a tier/tierType combination
---@param args table
---@return string?
function Tier.display(args)
	args = args or {}

	args.tier = args.tier or args.liquipediatier
	args.tiertype = args.tiertype or args.liquipediatiertype

	if String.isEmpty(args.tier) and String.isEmpty(args.tier) then
		return ''
	elseif String.isEmpty(args.tier) or String.isEmpty(args.tier) then
		args.shortIfBoth = false
	end

	local tierDisplay = Tier.displaySingle(Tier.parseDisplayArgs(args, 'tier'))

	local tierTypeDisplay = Tier.displaySingle(Tier.parseDisplayArgs(args, 'tiertype'))
	if String.isEmpty(tierTypeDisplay) then
		return tierDisplay
	end

	return tierTypeDisplay .. NON_BREAKING_SPACE .. '(' .. tierDisplay .. ')'
end

--- Builds the display for a single tier/tierType
---@param args table
---@param prefix string
---@return table
function Tier.parseDisplayArgs(args, prefix)
	return {
		mode = prefix .. 's',
		input = args[prefix],
		link = args[prefix .. 'link'],
		short = Logic.readBool(args[prefix .. 'short']) or Logic.readBool(args.shortIfBoth),
		sort = Logic.readBool(args[prefix .. 'sort']),
	}
end

--- Legacy: Converts legacy tier input to its numeric value. DEPRECATED!!!
---@param input string|integer|nil
---@return integer
---@deprecated
function Tier.toNumber(input)
	-- do not error for empty input, only for invalid
	if String.isEmpty(input) then
		return
	end

	return Tier.raw(input, 'tierToNumber')
		or error('Invalid tier "' .. input .. '" in legacy conversion')
end

return Tier
