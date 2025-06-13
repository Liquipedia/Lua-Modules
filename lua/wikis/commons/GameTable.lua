---
-- @Liquipedia
-- page=Module:GameTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local VodLink = require('Module:VodLink')

local MatchTable = Lua.import('Module:MatchTable')

local NOT_PLAYED = 'notplayed'
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'

---@class GameTableMatch: MatchTableMatch
---@field games match2game[]

---@class GameTable: MatchTable
---@field countGames number
local GameTable = Class.new(MatchTable, function (self)
	self.countGames = 0
end)

---@param game match2game
---@return match2game?
function GameTable:gameFromRecord(game)
	if self.countGames == self.config.limit then return nil end
	if game.status == NOT_PLAYED or Logic.isEmpty(game.winner) then
		return nil
	end

	return game
end

---@param record table
---@return GameTableMatch?
function GameTable:matchFromRecord(record)
	if self.countGames == self.config.limit then return nil end
	local matchRecord = MatchTable.matchFromRecord(self, record)
	---@cast matchRecord GameTableMatch
	if Logic.isEmpty(record.match2games) then
		return nil
	end

	matchRecord.games = {}
	--order games from last played to first
	Array.forEach(Array.reverse(record.match2games), function (game)
		local gameRecord = self:gameFromRecord(game)
		if gameRecord then self.countGames = self.countGames + 1 end
		table.insert(matchRecord.games, gameRecord)
	end)

	return matchRecord
end

---@param vod string?
---@return Html?
function GameTable:_displayGameVod(vod)
	if not self.config.showVod then return end

	local vodNode = mw.html.create('td')
	if Logic.isEmpty(vod) then
		return vodNode:wikitext('')
	end
	---@cast vod -nil
	return vodNode:node(VodLink.display{vod = vod})
end

---@param result MatchTableMatchResult
---@param game match2game
---@return Html?
function GameTable:_displayGameScore(result, game)
	local scores = Array.map(game.opponents, Operator.property('score'))
	local toScore = function(opponentRecord)
		local isWinner = opponentRecord.id == tonumber(game.winner)
		local score = scores[opponentRecord.id] or (isWinner and 1) or 0
		return mw.html.create(isWinner and 'b' or nil)
			:wikitext(score)
	end

	return mw.html.create('td')
		:addClass('match-table-score')
		:node(toScore(result.opponent))
		:node(SCORE_CONCAT)
		:node(toScore(result.vs))
end

---@param game match2game
---@return Html?
function GameTable:_displayGameIconForGame(game)
	if not self.config.displayGameIcons then return end

	return mw.html.create('td')
		:node(Game.icon{game = game.game})
end

---@param match GameTableMatch
---@param game match2game
---@return Html?
function GameTable:displayGame(match, game)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	return mw.html.create()
		:node(self.config.showOpponent and self:_displayOpponent(match.result.opponent, true) or nil)
		:node(self:_displayGameScore(match.result, game))
		:node(self:_displayOpponent(match.result.vs):css('text-align', 'left'))
end

---@param match GameTableMatch
---@param game match2game
---@return Html?
function GameTable:gameRow(match, game)
	local winner = match.result.opponent.id == tonumber(game.winner) and 1 or 2

	return mw.html.create('tr')
		:addClass(self:_getBackgroundClass(winner))
		:node(self:_displayDate(match))
		:node(self:_displayTier(match))
		:node(self:_displayType(match))
		:node(self:_displayGameIconForGame(game))
		:node(self:_displayIcon(match))
		:node(self:_displayTournament(match))
		:node(self:displayGame(match, game))
		:node(self:_displayGameVod(game.vod))
end

---@param match GameTableMatch
---@return Html?
function GameTable:matchRow(match)
	local display = mw.html.create()

	Array.forEach(match.games, function(game)
		display:node(self:gameRow(match, game))
	end)

	return display
end

return GameTable
