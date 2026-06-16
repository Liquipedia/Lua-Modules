---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/OpponentEntry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Starcraft')

local Component = Lua.import('Module:Widget/Component')
local BracketOpponentEntry = Lua.import('Module:Widget/Match/Bracket/OpponentEntry')
local StarcraftBracketOpponent = Lua.import('Module:Widget/Match/Bracket/Opponent/Starcraft')

---@class StarcraftBracketOpponentEntryProps: BracketOpponentEntryProps
---@field opponent StarcraftStandardOpponent

---@param props StarcraftBracketOpponentEntryProps
---@return VNode
local function StarcraftBracketOpponentEntry(props)
	local opponent = props.opponent
	props.BracketOpponent = StarcraftBracketOpponent
	props.showFactionBackground = opponent.type == Opponent.solo
			or opponent.type == Opponent.duo and opponent.isArchon
	return BracketOpponentEntry(props)
end

return Component.component(StarcraftBracketOpponentEntry, {showTbd = false})
