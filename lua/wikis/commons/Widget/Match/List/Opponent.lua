---
-- @Liquipedia
-- page=Module:Widget/Match/List/Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local SCORE_DRAW = 0

---@class MatchListOpponentProps: MatchListScoreProps
---@field winner integer?

--[[
Display component for an opponent in a matchlist.

This is the default implementation used by the Matchlist component. Specific
wikis may override this by passing a different props.Opponent to the Matchlist
component.
]]
---@param props MatchListOpponentProps
---@return VNode
local function MatchListOpponent(props)
	local opponent = props.opponent
	return Html.Div(DisplayHelper.addOpponentHighlightToProps({
		classes = Array.extendWith(
			{
				'brkts-matchlist-cell',
				'brkts-matchlist-opponent',
			},
			props.winner == SCORE_DRAW and 'brkts-matchlist-slot-bold bg-draw' or
			opponent.placement == 1 and 'brkts-matchlist-slot-winner' or nil
		),
		children = OpponentDisplay.BlockOpponent{
			flip = props.side == 'left',
			opponent = opponent,
			overflow = 'ellipsis',
			showLink = false,
			teamStyle = 'dynamic',
			additionalClasses = {'brkts-matchlist-cell-content'},
		}
	}, opponent))
end

return Component.component(MatchListOpponent, {opponent = Opponent.blank(Opponent.literal)})
