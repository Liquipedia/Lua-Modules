---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/SetHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Span = Html.Span
local Div = Html.Div

local WinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return number
local function defaultCalculateGameScore(game, opponentIndex)
	if game.winner == opponentIndex then
		return 1
	elseif game.winner == 0 then
		return 0.5
	end
	return 0
end

---@alias SetHeaderGameScoreCalculator fun(game: MatchGroupUtilGame, opponentIndex: integer): number

---@class MatchSetHeaderProps
---@field set MatchGroupUtilSubgroup
---@field calculateGameScore? SetHeaderGameScoreCalculator

---@param props MatchSetHeaderProps
---@return VNode?
local function MatchSetHeader(props)
	-- TODO: Move logic elsewhere in the future
	local set = props.set
	if not set then
		return nil
	end

	local isStarted = Array.any(set.games, function (game)
		return MatchGroupUtil.computeMatchPhase(game) ~= 'upcoming'
	end)
	local isFinished = Array.all(set.games, function (game)
		return MatchGroupUtil.computeMatchPhase(game) == 'finished'
	end)

	local calculateGameScore = props.calculateGameScore or defaultCalculateGameScore
	local scoreLeft, scoreRight = 0, 0
	if isStarted then
		Array.forEach(set.games, function(game)
			scoreLeft = scoreLeft + calculateGameScore(game, 1)
			scoreRight = scoreRight + calculateGameScore(game, 2)
		end)
	end

	local winner
	if isFinished then
		if scoreLeft == scoreRight then
			winner = 0
		elseif scoreLeft > scoreRight then
			winner = 1
		elseif scoreRight > scoreLeft then
			winner = 2
		end
	end

	return Div{
		classes = {'brkts-popup-body-grid-header-center'},
		children = {
			Div{
				children = {
					WinLossIndicator{winner = winner, opponentIndex = 1}
				}
			},
			Div{
				classes = {'match-info-header-scoreholder'},
				children = isStarted and {
					Span{
						classes = {
							'match-info-header-scoreholder-score',
							(winner == 0 or winner == 1) and 'match-info-header-winner' or nil
						},
						children = scoreLeft,
					},
					Span{
						classes = {'match-info-header-scoreholder-divider'},
						children = ':'
					},
					Span{
						classes = {
							'match-info-header-scoreholder-score',
							(winner == 0 or winner == 2) and 'match-info-header-winner' or nil
						},
						children = scoreRight,
					}
				} or nil,
			},
			Div{
				children = {
					WinLossIndicator{winner = winner, opponentIndex = 2}
				}
			},
		}
	}
end

return Component.component(MatchSetHeader)
