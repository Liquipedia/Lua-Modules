---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/SingleMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local SingleMatchDisplay = {propTypes = {}, types = {}}

SingleMatchDisplay.configFromArgs = function(args)
	return {
		width = tonumber(string.gsub(args.width or '', 'px', ''), nil),
	}
end

SingleMatchDisplay.types.SingleMatchConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	width = 'number',
})
SingleMatchDisplay.types.SingleMatchConfigOptions = TypeUtil.struct(
	Table.mapValues(SingleMatchDisplay.types.SingleMatchConfig.struct, TypeUtil.optional)
)

SingleMatchDisplay.propTypes.SingleMatchContainer = {
	matchId = 'string',
	config = TypeUtil.optional(SingleMatchDisplay.types.SingleMatchConfigOptions),
}

--[[
Display component for a singleMatch. The singleMatch is specified by matchID.
The component fetches the match data from LPDB or page variables.
]]
function SingleMatchDisplay.SingleMatchContainer(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.SingleMatchContainer)

	local bracketId, _ = MatchGroupUtil.splitMatchId(props.matchId)

	local match = MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, props.matchId)
	return match
		and SingleMatchDisplay.SingleMatch({
			config = props.config,
			match = match,
		})
		or ''
end

SingleMatchDisplay.propTypes.SingleMatch = {
	config = TypeUtil.optional(SingleMatchDisplay.types.SingleMatchConfigOptions),
	match = MatchGroupUtil.types.Match,
}

--[[
Display component for a singleMatch. Match data is specified in the input.
]]
function SingleMatchDisplay.SingleMatch(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.SingleMatch)

	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		width = propsConfig.width or 400,
	}

	local matchNode = SingleMatchDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		match = props.match,
	}

	matchNode:addClass('brkts-popup brkts-match-info-flat')
		:css('width', config.width .. 'px')

	return matchNode
end

SingleMatchDisplay.propTypes.Match = {
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
}

--[[
Display component for a match in a singleMatch. Consists of the match summary.
]]
function SingleMatchDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, SingleMatchDisplay.propTypes.Match)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.match.matchId,
		config = {showScore = true},
	})

	return matchSummaryNode
end

return Class.export(SingleMatchDisplay)
