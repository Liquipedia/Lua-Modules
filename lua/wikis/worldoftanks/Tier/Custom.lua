---
-- @Liquipedia
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils')

local NON_BREAKING_SPACE = '&nbsp;'

---@class WoTTierUtils: TierUtils
local TierCustom = Table.copy(Tier)

--- Parses queryData to be processable for other Tier functions
---@param queryData table
---@return string?, string?, {game: string?}
function TierCustom.parseFromQueryData(queryData)
	return queryData.liquipediatier, queryData.liquipediatiertype, {game = queryData.game}
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

	local tierDisplayOptions = Tier._displayOptions(options, 'tier')
	tierDisplayOptions.game = options.game

	if not tierTypeData then
		return TierCustom.displaySingle(tierData, tierDisplayOptions)
	end

	local tierTypeDisplayOptions = Tier._displayOptions(options, 'tierType')
	tierTypeDisplayOptions.game = options.game

	if options.onlyTierTypeIfBoth then
		return TierCustom.displaySingle(tierTypeData, tierTypeDisplayOptions)
	end

	if options.shortIfBoth then
		options.short = true
	end

	return TierCustom.displaySingle(tierTypeData, tierTypeDisplayOptions)
		.. NON_BREAKING_SPACE .. '(' .. TierCustom.displaySingle(tierData, tierDisplayOptions) .. ')'
end

--- Builds the display for a given tierData/tierTypeData table
---@param data table
---@param options {short: boolean?, link: boolean|string|nil, game: string?}
---@return string?
function TierCustom.displaySingle(data, options)
	local display = options.short and data.short or data.name

	if Logic.readBool(options.link) and data.link then
		return Page.makeInternalLink({}, display, TierCustom.adjustLink(data.link, options.game))
	elseif Logic.readBoolOrNil(options.link) == nil then
		local link = options.link --[[@as string?]]
		if String.isNotEmpty(link) then
			return Page.makeInternalLink({}, display, link)
		end
	end

	return display
end

---@param link string
---@param game string?
---@return string
function TierCustom.adjustLink(link, game)
	return String.isNotEmpty(game) and (Game.link{game = game} .. '/' .. link) or link
end

return TierCustom
