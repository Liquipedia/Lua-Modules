---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/OpponentEntry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local ScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer/Custom')

---@class BracketOpponentEntryProps: BracketOpponentProps
---@field classes string[]?
---@field height number
---@field displayType string
---@field showFactionBackground boolean?
---@field BracketOpponent Component<BracketOpponentProps>?

---@param props BracketOpponentEntryProps
---@return VNode
local function BracketOpponentEntry(props)
	local opponent = props.opponent
	local win = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances
	local BracketOpponent = props.BracketOpponent or Lua.import('Module:Widget/Match/Bracket/Opponent')
	return Html.Div(DisplayHelper.addOpponentHighlightToProps(
		{
			classes = Array.extend(
				'brkts-opponent-entry',
				props.classes
			),
			css = props.height and {height = props.height .. 'px'} or nil,
			children = {
				Html.Div{
					classes = Array.extend(
						'brkts-opponent-entry-left',
						win and 'brkts-opponent-win' or nil,
						Logic.nilOr(
							props.showFactionBackground, opponent.type == Opponent.solo
						) and Faction.bgClass(opponent.players[1].faction) or nil
					),
					children = BracketOpponent(props),
				},
				props.displayType == 'bracket' and ScoreContainer(props) or nil
			}
		},
		props.opponent
	))
end

return Component.component(
	BracketOpponentEntry,
	{
		showTbd = false
	}
)
