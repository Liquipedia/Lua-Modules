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

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local SingleMatchDisplay = {}

---@class SingleMatchConfigOptions
---@field MatchSummaryContainer function?
---@field width number?

---@param args table
---@return table
function SingleMatchDisplay.configFromArgs(args)
	return {
		width = tonumber((string.gsub(args.width or '', 'px', ''))),
	}
end

---Display component for a singleMatch. The singleMatch is specified by matchID.
---The component fetches the match data from LPDB or page variables.
---@param props {matchId: string, config: SingleMatchConfigOptions}
---@return Html
function SingleMatchDisplay.SingleMatchContainer(props)
	local bracketId, _ = MatchGroupUtil.splitMatchId(props.matchId)

	assert(bracketId, 'Missing or invalid matchId')

	local match = MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, props.matchId)
	return match
		and SingleMatchDisplay.SingleMatch({
			config = props.config,
			match = match,
		})
		or mw.html.create()
end

---Display component for a singleMatch. Match data is specified in the input.
---@param props {config: SingleMatchConfigOptions, match: MatchGroupUtilMatch}
---@return Html
function SingleMatchDisplay.SingleMatch(props)
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		width = propsConfig.width or 400,
	}

	local matchNode = SingleMatchDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		match = props.match,
	}

	return matchNode
		:addClass('brkts-popup brkts-match-info-flat')
		:css('width', config.width .. 'px')
end

---Display component for a match in a singleMatch. Consists of the match summary.
---@param props {MatchSummaryContainer: function, match: MatchGroupUtilMatch}
---@return Html
function SingleMatchDisplay.Match(props)
	local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
	return DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		config = {showScore = true},
	}, require('Module:Error/Display').ErrorList)
end

return Class.export(SingleMatchDisplay)
