---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Singlematch
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

local SinglematchDisplay = {propTypes = {}, types = {}}

SinglematchDisplay.configFromArgs = function(args)
	return {
		width = tonumber(string.gsub(args.width or '', 'px', ''), nil),
	}
end

SinglematchDisplay.types.SinglematchConfig = TypeUtil.struct({
	MatchSummaryContainer = 'function',
	matchHasDetails = 'function',
	width = 'number',
})
SinglematchDisplay.types.SinglematchConfigOptions = TypeUtil.struct(
	Table.mapValues(SinglematchDisplay.types.SinglematchConfig.struct, TypeUtil.optional)
)

SinglematchDisplay.propTypes.SinglematchContainer = {
	bracketId = 'string',
	config = TypeUtil.optional(SinglematchDisplay.types.SinglematchConfigOptions),
}

--[[
Display component for a singlematch. The singlematch is specified by ID.
The component fetches the match data from LPDB or page variables.
]]
function SinglematchDisplay.SinglematchContainer(props)
	DisplayUtil.assertPropTypes(props, SinglematchDisplay.propTypes.SinglematchContainer)
	return SinglematchDisplay.Singlematch({
		config = props.config,
		matches = MatchGroupUtil.fetchMatches(props.bracketId),
	})
end

SinglematchDisplay.propTypes.Singlematch = {
	config = TypeUtil.optional(SinglematchDisplay.types.SinglematchConfigOptions),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
}

--[[
Display component for a singlematch. Match data is specified in the input.
]]
function SinglematchDisplay.Singlematch(props)
	DisplayUtil.assertPropTypes(props, SinglematchDisplay.propTypes.Singlematch)

	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		matchHasDetails = propsConfig.matchHasDetails or matchHasDetailsWikiSpecific or DisplayHelper.defaultMatchHasDetails,
		width = propsConfig.width or 400,
	}

	local singlematchNode = mw.html.create('div'):addClass('brkts-popup brkts-match-info-popup')
		:css('overflow', 'hidden')
		:css('position', 'unset')
		:css('max-height', 'unset')
		:css('width', config.width .. 'px')

	if #props.matches == 0 then
		-- No match, simply return
		return ''
	end

	local matchNode = SinglematchDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		match = props.matches[1],
		matchHasDetails = config.matchHasDetails,
	}

	singlematchNode:node(matchNode:css('width', config.width .. 'px'))

	return singlematchNode
end

SinglematchDisplay.propTypes.Match = {
	MatchSummaryContainer = 'function',
	match = MatchGroupUtil.types.Match,
	matchHasDetails = 'function',
}

--[[
Display component for a match in a singlematch. Consists of the match summary.
]]
function SinglematchDisplay.Match(props)
	DisplayUtil.assertPropTypes(props, SinglematchDisplay.propTypes.Match)

	local matchSummaryNode = DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = props.match.matchId:match('^(.*)_'), -- everything up to the final '_'
		matchId = props.match.matchId,
	})

	return matchSummaryNode
end

return Class.export(SinglematchDisplay)
