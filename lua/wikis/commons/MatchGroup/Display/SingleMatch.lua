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
		width = args.width,
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
	local MatchSummaryContainer = propsConfig.MatchSummaryContainer or DisplayHelper.DefaultMatchSummaryContainer

	local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)
	return DisplayUtil.TryPureComponent(MatchSummaryContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		config = {
			showScore = true,
			width = 400,
		},
		classes = {'brkts-popup', 'brkts-match-info-flat'},
		width = propsConfig.width,
	}, Lua.import('Module:Error/Display').ErrorList)
end

return SingleMatchDisplay
