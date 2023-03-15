---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Tier/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})

local NON_BREAKING_SPACE = '&nbsp;'

local TierCustom = Table.copy(Tier)

function TierCustom.parseFromQueryData(queryData)
	return queryData.liquipediatier, queryData.liquipediatiertype, {game = queryData.game}
end

function TierCustom.display(tier, tierType, options)
	local tierData, tierTypeData = Tier._raw(tier, tierType)

	if not tierData then return end

	options = options or {}

	local tierDisplayOptions = Tier._displayOptions(options, 'tier')
	tierDisplayOptions.game = options.game

	if not tierTypeData then
		return Tier.displaySingle(tierData, tierDisplayOptions)
	end

	local tierTypeDisplayOptions = Tier._displayOptions(options, 'tierType')
	tierTypeDisplayOptions.game = options.game

	if options.onlyTierTypeIfBoth then
		return Tier.displaySingle(tierTypeData, tierTypeDisplayOptions)
	end

	if options.shortIfBoth then
		options.short = true
	end

	return Tier.displaySingle(tierTypeData, tierDisplayOptions)
		.. NON_BREAKING_SPACE .. '(' .. Tier.displaySingle(tierData, tierTypeDisplayOptions) .. ')'
end

function Tier.displaySingle(data, options)
	local display = options.short and data.short or data.name

	if Logic.readBool(options.link) and data.link then
		return Page.makeInternalLink({}, display, TierCustom.adjustLink(data.link, options.game))
	elseif String.isNotEmpty(options.link) then
		return Page.makeInternalLink({}, display, options.link)
	end

	return display
end

function TierCustom.adjustLink(link, game)
	return game .. '/' .. link
end

return TierCustom
