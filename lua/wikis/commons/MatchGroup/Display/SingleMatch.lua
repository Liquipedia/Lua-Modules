---
-- @Liquipedia
-- page=Module:MatchGroup/Display/SingleMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DisplayUtil = Lua.import('Module:DisplayUtil')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

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
---@return Widget|Html
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
---@return Widget|Html
function SingleMatchDisplay.SingleMatch(props)
	local propsConfig = props.config or {}
	local config = {
		MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer,
		width = propsConfig.width or 400,
	}

	return SingleMatchDisplay.Match{
		MatchSummaryContainer = config.MatchSummaryContainer,
		match = props.match,
		width = config.width,
	}
end

---Display component for a match in a singleMatch. Consists of the match summary.
---@param props {MatchSummaryContainer: function, match: MatchGroupUtilMatch, width: string|integer?}
---@return Widget|Html
function SingleMatchDisplay.Match(props)
	local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
	return DisplayUtil.TryPureComponent(props.MatchSummaryContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		config = {showScore = true},
		classes = {'brkts-popup', 'brkts-match-info-flat'},
		width = props.width,
	}, Lua.import('Module:Error/Display').ErrorList)
end

return SingleMatchDisplay
