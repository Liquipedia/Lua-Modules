---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/OpponentEntry/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Winner = Lua.import('Module:MatchGroup/Util/Winner')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local ScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer/Custom')

---@class TrackmaniaBracketOpponentEntryProps: BracketOpponentEntryProps
---@field opponent StandardOpponent

---@param props TrackmaniaBracketOpponentEntryProps
---@return VNode
local function TrackmaniaBracketOpponentEntry(props)
	local opponent = props.opponent
	local win = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances
	local highlighted = Winner.isWinner(opponent)
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
						win and 'brkts-opponent-win' or nil
					),
					css = highlighted and {['font-weight'] = 'bold'} or nil,
					children = BracketOpponent(props),
				},
				props.displayType == 'bracket' and ScoreContainer(props) or nil
			}
		},
		props.opponent
	))
end

return Component.component(
	TrackmaniaBracketOpponentEntry,
	{
		showTbd = false
	}
)
