---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')

---@class BracketOpponentProps
---@field opponent standardOpponent
---@field forceShortName boolean?
---@field showTbd boolean?

---@param props BracketOpponentProps
---@return Renderable
local function BracketOpponent(props)
	local opponent = props.opponent
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		overflow = 'ellipsis',
		showLink = false,
		showTbd = opponent.type == Opponent.literal or props.showTbd,
		teamStyle = props.forceShortName and 'short' or 'dynamic',
	}
end

return Component.component(BracketOpponent)
