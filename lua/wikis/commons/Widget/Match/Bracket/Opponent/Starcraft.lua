---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Opponent/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft')

local Component = Lua.import('Module:Widget/Component')

---@class StarcraftBracketOpponentProps: BracketOpponentProps
---@field opponent StarcraftStandardOpponent

---@param props StarcraftBracketOpponentProps
---@return Renderable
local function StarcraftBracketOpponent(props)
	local opponent = props.opponent

	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		overflow = 'ellipsis',
		playerClass = 'starcraft-bracket-block-player',
		showLink = false,
		showTbd = props.showTbd,
		teamStyle = props.forceShortName and 'short' or 'dynamic',
	}
end

return Component.component(StarcraftBracketOpponent)
