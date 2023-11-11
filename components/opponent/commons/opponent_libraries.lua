---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentLibraries
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {requireDevIfEnabled = true})

local Opponent = Lua.import('Module:' .. (Info.opponentLibrary or 'Opponent'), {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:' .. (Info.opponentDisplayLibrary or 'OpponentDisplay'),
	{requireDevIfEnabled = true})

return {
	Opponent = Opponent, ---@module 'opponent.commons.opponent'
	OpponentDisplay = OpponentDisplay, ---@module 'opponent.commons.opponent_display'
}
