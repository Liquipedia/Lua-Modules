---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local StarcraftMatchSummaryFfa = {}

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local BaseMatchSummary = Lua.import('Module:MatchSummary/Base/Ffa')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

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
			children = {
				StarcraftMatchSummaryFfa._schedule(match),
				BaseMatchSummary.standardMatch(match, Parser),
			}
		}
	}}
end

---@param match StarcraftMatchGroupUtilMatch
---@return Widget
function StarcraftMatchSummaryFfa._schedule(match)
	if StarcraftMatchSummaryFfa._gamesHaveDates(match) then
		return MatchSummaryWidgets.GamesSchedule{games = match.games}
	end
	return MatchSummaryWidgets.MatchSchedule{match = match}
end

---@param match StarcraftMatchGroupUtilMatch
---@return boolean
function StarcraftMatchSummaryFfa._gamesHaveDates(match)
	local dates = Array.map(match.games, Operator.property('date'))
	return Array.any(dates, function(date) return date ~= match.date end)
end

---@param columns table[]
---@return table[]
function Parser.adjustMatchColumns(columns)
	return Array.map(columns, function(column)
		if column.id == 'status' then
			column.show = function(match)
				return match.finished and #Array.filter(match.opponents, function(opponent)
					return Logic.readBool(opponent.advances)
				end) > 1
			end
			column.row = {
				value = function (opponent, idx)
					local statusIcon = Logic.readBool(opponent.advances)
						and BaseMatchSummary.STATUS_ICONS.advances
						or BaseMatchSummary.STATUS_ICONS.eliminated
					return mw.html.create('i')
						:addClass(statusIcon)
				end,
			}
		elseif column.id == 'opponent' then
			column.header = {value = 'Participant'}
		elseif column.id == 'totalPoints' then
			column.show = function(match) return not Logic.readBool(match.noScore) end
		elseif column.id == 'matchPoints' then
			return
		end
		return column
	end)
end

---@param columns table[]
---@return table[]
function Parser.adjustGameOverviewColumns(columns)
	Array.forEach(columns, function(column)
		if column.id == 'placement' then
			column.show = function(match) return true end
		elseif column.id == 'kills' then
			return
		elseif column.id == 'points' then
			column.show = function(match) return not Logic.readBool(match.noScore) end
			column.row = {value = function(opponent)
				return OpponentDisplay.InlineScore(Table.merge({extradata = {}, score = ''}, opponent))
			end}
		end
	end)

	return columns
end

---@param match table
---@param game table
---@param gameIndex integer
---@return table[]
function Parser.gameHeader(match, game, gameIndex)
	return {
		HtmlWidgets.Div{
			classes = {'panel-table__cell__game-title'},
			children = {
				MatchSummaryWidgets.CountdownIcon{game = game, additionalClasses = {'panel-table__cell-icon'}},
				HtmlWidgets.Span{
					classes = {'panel-table__cell-text'},
					children = 'Game ' .. gameIndex
				}
			}
		},
		StarcraftMatchSummaryFfa._gamesHaveDates(match) and MatchSummaryWidgets.GameCountdown{game = game} or nil,
	}
end

return StarcraftMatchSummaryFfa
