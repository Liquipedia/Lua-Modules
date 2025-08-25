---
-- @Liquipedia
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = require('Module:Array')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@type FfaMatchSummaryParser
local Parser = {}

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class FFAMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	SummaryHelper.updateMatchOpponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = WidgetUtil.collect(
				MatchSummaryWidgets.GamesSchedule{match = match},
				MatchSummaryWidgets.PointsDistribution{scores = scoringData},
				MatchSummaryWidgets.MatchInformation(match),
				SummaryHelper.standardMatch(match, Parser)
			)
		}
	}}
end

---@param columns table[]
---@return table[]
function Parser.adjustGameOverviewColumns(columns)
	return Array.map(columns, function(column)
		if column.id == 'kills' then
			column.icon = 'points'
			column.header = {value = 'Pts.'}
		end
		return column
	end)
end

return CustomMatchSummary
