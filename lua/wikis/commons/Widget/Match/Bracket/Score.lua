---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {isWinner: boolean?, scoreText: Renderable?}
---@return VNode
local function BracketScoreDisplay(props)
	return Html.Div{
		classes = {'brkts-opponent-score-outer'},
		children = Html.Div{
			classes = {'brkts-opponent-score-inner'},
			children = props.isWinner and Html.B{children = props.scoreText} or props.scoreText
		}
	}
end

return Component.component(BracketScoreDisplay)
