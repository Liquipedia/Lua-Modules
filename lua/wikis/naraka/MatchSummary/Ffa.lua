---
-- @Liquipedia
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param defaultColumns table[]
---@return table[]
local function adjustMatchColumns(defaultColumns)
	return Array.flatMap(defaultColumns, function(column)
		if column.id ~= 'matchPoints' then
			return column
		end
		return {
			column,
			{
				id = 'startingPoints',
				class = 'cell--total-points',
				show = function(match)
					return Array.any(match.opponents, function(opponent)
						return (tonumber((opponent.extradata or {}).startingpoints) or 0) ~= 0
					end)
				end,
				header = {value = 'Pre-Match Points', mobileValue = 'Pre.'},
				row = {
					value = function(opponent)
						return tonumber((opponent.extradata or {}).startingpoints) or 0
					end,
				},
			},
		}
	end)
end

---@param props {bracketId: string, matchId: string}
---@return Renderable
function CustomMatchSummary.getByMatchId(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	---@cast match FFAMatchGroupUtilMatch
	SummaryHelper.updateMatchOpponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return Html.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = WidgetUtil.collect(
				MatchSummaryWidgets.GamesSchedule{match = match},
				MatchSummaryWidgets.PointsDistribution{scores = scoringData},
				MatchSummaryWidgets.MatchInformation(match),
				SummaryHelper.standardMatch(match, {adjustMatchColumns = adjustMatchColumns})
			)
		}
	}}
end

return CustomMatchSummary
