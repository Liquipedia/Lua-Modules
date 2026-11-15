---
-- @Liquipedia
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local function startingPoints(opponent)
	return tonumber((opponent.extradata or {}).startingpoints) or 0
end

local function adjustMatchColumns(defaultColumns)
	local columns = {}
	for _, column in ipairs(defaultColumns) do
		table.insert(columns, column)
		if column.id == 'matchPoints' then
			table.insert(columns, {
				id = 'startingPoints',
				class = 'cell--total-points',
				show = function(match)
					for _, opponent in ipairs(match.opponents) do
						if startingPoints(opponent) ~= 0 then
							return true
						end
					end
					return false
				end,
				header = {value = 'Pre-Match Points', mobileValue = 'Pre.'},
				row = {value = startingPoints},
			})
		end
	end
	return columns
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
