---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameWins : StandingsTiebreaker
local TiebreakerGameWins = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWins:valueOf(state, opponent)
	return Array.reduce(
		Array.map(opponent.matches, function (match)
			local gamesWon = Array.filter(match.games, function (game)
				if not game.winner or game.winner == 0 then
					return false
				end
				return Opponent.same(opponent.opponent, match.opponents[game.winner])
			end)
			return #gamesWon
		end),
		Operator.add,
		0
	)
end

---@return string
function TiebreakerGameWins:headerTitle()
	return 'Games Won'
end

return TiebreakerGameWins
