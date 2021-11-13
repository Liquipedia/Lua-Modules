---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local matchHasDetailsWikiSpecific = require('Module:Brkts/WikiSpecific').matchHasDetails

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local SingleMatchDisplay = {propTypes = {}, types = {}}

SingleMatchDisplay.configFromArgs = function(args)
	return {
		width = tonumber(string.gsub(args.width or '', 'px', ''), nil),
	}
end

SingleMatchDisplay.types.SingleMatchConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	matchHasDetails = 'function',
	width = 'number',
})
SingleMatchDisplay.types.SingleMatchConfigOptions = TypeUtil.struct(
	Table.mapValues(SingleMatchDisplay.types.SingleMatchConfig.struct, TypeUtil.optional)
)

SingleMatchDisplay.propTypes.SingleMatchContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(SingleMatchDisplay.types.SingleMatchConfigOptions),
}

--[[
Display component for a singleMatch. The singleMatch is specified by ID.
The component fetches the match data from LPDB or page variables.
]]
function SingleMatchDisplay.SingleMatchContainer(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.SingleMatchContainer)
	return SingleMatchDisplay.SingleMatch({
		config = props.config,
		matches = MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

SingleMatchDisplay.propTypes.SingleMatch = {
	config = TypeUtil.optional(SingleMatchDisplay.types.SingleMatchConfigOptions),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
}

--[[
Display component for a singleMatch. Match data is specified in the input.
]]
function SingleMatchDisplay.SingleMatch(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.SingleMatch)

	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		matchHasDetails = propsConfig.matchHasDetails or matchHasDetailsWikiSpecific or DisplayHelper.defaultMatchHasDetails,
		width = propsConfig.width or 400,
	}

	local singleMatchNode = mw.html.create('div'):addClass('brkts-popup brkts-match-info-popup')
		:css('overflow', 'hidden')
		:css('position', 'unset')
		:css('max-height', 'unset')
		:css('width', config.width .. 'px')

	if #props.matches == 0 then
		-- No match, simply return
		return ''
	end

	local matchNode = SingleMatchDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		match = props.matches[1],
		matchHasDetails = config.matchHasDetails,
	}

	singleMatchNode:node(matchNode:css('width', config.width .. 'px'))

	return singleMatchNode
end

SingleMatchDisplay.propTypes.Match = {
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
	matchHasDetails = 'function',
}

--[[
Display component for a match in a singleMatch. Consists of the match summary.
]]
function SingleMatchDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.Match)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.match.matchId,
	})

	return matchSummaryNode
end

return Class.export(SingleMatchDisplay)
