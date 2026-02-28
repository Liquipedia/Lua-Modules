---
-- @Liquipedia
-- page=Module:GameTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local VodLink = Lua.import('Module:VodLink')

local MatchTable = Lua.import('Module:MatchTable')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NOT_PLAYED = 'notplayed'
local SCORE_CONCAT = '&nbsp;&colon;&nbsp;'

---@class GameTable: MatchTable
---@operator call(table): GameTable
---@field countGames integer
local GameTable = Class.new(MatchTable, function (self)
	self.countGames = 0
end)

---@param record match2
---@return MatchTableMatch?
function GameTable:matchFromRecord(record)
	if self.countGames >= self.config.limit then return nil end
	local matchRecord = MatchTable.matchFromRecord(self, record)
	if not matchRecord then
		return
	elseif Logic.isEmpty(record.match2games) then
		return nil
	end

	matchRecord.games = Array.filter(matchRecord.games, function (game)
		return self:filterGame(game)
	end)

	self.countGames = self.countGames + #matchRecord.games

	return matchRecord
end

---@param game MatchGroupUtilGame
---@return boolean
function GameTable:filterGame(game)
	return game.status ~= NOT_PLAYED and Logic.isNotEmpty(game.winner)
end

---@param vod string?
---@return Widget?
function GameTable:_displayGameVod(vod)
	if not self.config.showVod then
		return
	elseif Logic.isEmpty(vod) then
		return TableWidgets.Cell{}
	end
	---@cast vod -nil
	return TableWidgets.Cell{children = VodLink.display{vod = vod}}
end

---@param result MatchTableMatchResult
---@param game MatchGroupUtilGame
---@return Html?
function GameTable:_displayGameScore(result, game)
	local scores = Array.map(game.opponents, Operator.property('score'))
	local indexes = result.flipped and {2, 1} or {1, 2}

	---@param opponentIndex integer
	---@return Widget
	local toScore = function(opponentIndex)
		local isWinner = opponentIndex == tonumber(game.winner)
		local score = scores[opponentIndex] or (isWinner and 1) or 0
		return HtmlWidgets.Span{
			css = {['font-weight'] = isWinner and 'bold' or nil},
			children = score
		}
	end

	return TableWidgets.Cell{children = {
		toScore(indexes[1]),
		SCORE_CONCAT,
		toScore(indexes[2]),
	}}
end

---@param game MatchGroupUtilGame
---@return Html?
function GameTable:_displayGameIconForGame(game)
	if not self.config.displayGameIcons then return end

	return TableWidgets.Cell{
		children = Game.icon{game = game.game}
	}
end

---@param match MatchTableMatch
---@param game MatchGroupUtilGame
---@return Widget|Widget[]?
function GameTable:displayGame(match, game)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	return WidgetUtil.collect(
		self.config.showOpponent and self:_displayOpponent(match.result.opponent, true) or nil,
		self:_displayGameScore(match.result, game),
		self:_displayOpponent(match.result.vs)
	)
end

---@param match MatchTableMatch
---@param game MatchGroupUtilGame
---@return Widget
function GameTable:gameRow(match, game)
	local indexes = match.result.flipped and {2, 1} or {1, 2}
	local winner = game.winner == indexes[1]

	return TableWidgets.Row{
		classes = {self:_getBackgroundClass(winner)},
		children = WidgetUtil.collect(
			self:_displayDate(match),
			self:displayTier(match),
			self:_displayType(match),
			self:_displayGameIconForGame(game),
			self:_displayIcon(match),
			self:_displayTournament(match),
			self:displayGame(match, game),
			self:_displayGameVod(game.vod),
			self:_displayMatchPage(match)
		)
	}
end

---@return Widget[]
function GameTable:buildRows()
	---@type Widget[]
	local rows = {}

	local currentYear = math.huge
	Array.forEach(self.matches, function(match)
		local year = DateExt.getYearOf(match.date)
		if self.config.showYearHeaders and year ~= currentYear then
			currentYear = year
			table.insert(rows, self:_yearRow(year))
		end
		Array.extendWith(rows, Array.reverse(
			Array.map(match.games, function (game)
				return self:gameRow(match, game)
			end)
		))
	end)

	return rows
end

return GameTable
