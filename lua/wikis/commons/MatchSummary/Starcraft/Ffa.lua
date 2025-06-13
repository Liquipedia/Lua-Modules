---
-- @Liquipedia
-- page=Module:MatchSummary/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local StarcraftMatchSummaryFfa = {}

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local BaseMatchSummary = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@type FfaMatchSummaryParser
local Parser = {}

---@param props {bracketId: string, matchId: string}
---@return Widget
function StarcraftMatchSummaryFfa.getByMatchId(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	---@cast match StarcraftMatchGroupUtilMatch

	BaseMatchSummary.updateMatchOpponents(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = WidgetUtil.collect(
				MatchSummaryWidgets.GamesSchedule{match = match},
				MatchSummaryWidgets.MatchInformation(match),
				BaseMatchSummary.standardMatch(match, Parser)
			)
		}
	}}
end

---@param columns table[]
---@return table[]
function Parser.adjustMatchColumns(columns)
	return Array.map(columns, function(column)
		if column.id == 'totalPoints' then
			column.show = function(match) return not match.extradata.settings.noscore end
		end
		return column
	end)
end

---@param columns table[]
---@return table[]
function Parser.adjustGameOverviewColumns(columns)
	return Array.map(columns, function(column)
		if column.id == 'placement' then
			column.show = function(match) return true end

		-- css for points shifts it to the next line and expects kills to be present
		elseif column.id == 'points' then
			return

		-- css for kills works just fine for our purposes
		elseif column.id == 'kills' then
			column.show = function(match) return not match.extradata.settings.noscore end
			column.row = {value = function(opponent)
				return OpponentDisplay.InlineScore(Table.merge({extradata = {}, score = ''}, opponent))
			end}
			column.icon = 'points'
			column.header = {value = 'Pts.'}
		end

		return column
	end)
end

return StarcraftMatchSummaryFfa
