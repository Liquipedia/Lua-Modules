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

---@class MatchListScoreProps
---@field opponent standardOpponent
---@field side 'left'|'right'

--[[
Display component for the score of an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Score to the Matchlist
component.
]]
---@param props MatchListScoreProps
---@return VNode
local function MatchListScore(props)
	local opponent = props.opponent
	local opponentNotTbd = not Opponent.isTbd(opponent)

	return Html.Div{
		classes = Array.extendWith(
			{
				'brkts-matchlist-cell',
				'brkts-matchlist-score',
			},
			opponent.placement == 1 and 'brkts-matchlist-slot-bold' or nil,
			opponentNotTbd and 'brkts-opponent-hover' or nil
		),
		attributes = opponentNotTbd and {
			['aria-label'] = Opponent.toName(opponent),
		} or nil,
		children = Html.Div{
			classes = {'brkts-matchlist-cell-content'},
			children = OpponentDisplay.InlineScore(opponent),
		}
	}
end

return Component.component(MatchListScore, {opponent = Opponent.blank(Opponent.literal)})
