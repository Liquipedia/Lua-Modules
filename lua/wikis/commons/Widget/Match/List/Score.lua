---
-- @Liquipedia
-- page=Module:Widget/Match/List/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local SCORE_DRAW = 0

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component.
]]
---@param props {opponent: standardOpponent, side: 'left'|'right'}
---@return VNode
local function MatchlistScore(props)
	local opponent = props.opponent

	return Html.Div{
		classes = Array.extendWith(
			{
				'brkts-matchlist-cell',
				'brkts-matchlist-score',
			},
			opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil,
			not Opponent.isTbd(opponent) and 'brkts-opponent-hover' or nil
		),
		children = Html.Div{
			classes = {'brkts-matchlist-cell-content'},
			children = OpponentDisplay.InlineScore(opponent),
		}
	}
end

return Component.component(MatchlistScore)
