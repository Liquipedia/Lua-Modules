---
-- @Liquipedia
-- page=Module:MatchSummary/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local SummaryHelper = Lua.import('Module:MatchSummary/Base/Ffa')

local Html = Lua.import('Module:Widget/Html')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

local MARTIAL_ARTS_MAP = 'martial arts showdown'

---@param game table?
---@return boolean
local function isMartialArts(game)
	if not game then
		return false
	end

	return Array.any({game.map or '', game.mapDisplayName or ''}, function(name)
		return String.trim(name):lower():gsub('_', ' ') == MARTIAL_ARTS_MAP
	end)
end

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
				header = {
					value = 'Pre-Match Points',
					mobileValue = 'Pre.',
				},
				row = {
					value = function(opponent)
						return tonumber((opponent.extradata or {}).startingpoints) or 0
					end,
				},
			},
		}
	end)
end

---@param defaultColumns table[]
---@return table[]
local function adjustGameOverviewColumns(defaultColumns)
	return Array.map(defaultColumns, function(column)
		if column.id ~= 'kills' then
			return column
		end

		local result = Table.copy(column)
		local originalShow = column.show

		---@param match table
		---@param game table?
		---@return boolean
		result.show = function(match, game)
			if isMartialArts(game) then
				return false
			end

			return not originalShow or originalShow(match)
		end

		return result
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
		MatchSummaryWidgets.Header{
			matchId = match.matchId,
			games = match.games,
		},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = WidgetUtil.collect(
				MatchSummaryWidgets.GamesSchedule{match = match},
				MatchSummaryWidgets.PointsDistribution{scores = scoringData},
				MatchSummaryWidgets.MatchInformation(match),
				SummaryHelper.standardMatch(match, {
					adjustMatchColumns = adjustMatchColumns,
					adjustGameOverviewColumns = adjustGameOverviewColumns,
				})
			),
		},
	}}
end

return CustomMatchSummary
