---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Qualified
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local BracketLineNode = Lua.import('Module:Widget/Match/Bracket/LineNode')

---@class BracketQualifiedProps
---@field OpponentEntry Component<BracketOpponentEntryProps>
---@field height number
---@field opponent standardOpponent
---@field topMargin number
---@field bottomMargin number

---@param props BracketQualifiedProps
---@return VNode
local function BracketQualified(props)
	local opponentEntryNode = props.OpponentEntry{
		displayType = 'bracket-qualified',
		height = props.height,
		opponent = props.opponent,
		classes = {'brkts-opponent-entry-last'},
	}

	return Html.Div{
		classes = {'brkts-qualified'},
		css = {
			['margin-top'] = props.topMargin .. 'px',
			['margin-bottom'] = props.bottomMargin .. 'px',
		},
		children = opponentEntryNode
	}
end

return Component.component(BracketQualified)
