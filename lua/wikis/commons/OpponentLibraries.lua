---
-- @Liquipedia
-- page=Module:OpponentLibraries
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info')

local Opponent = Lua.import('Module:' .. (Info.opponentLibrary or 'Opponent'))
local OpponentDisplay = Lua.import('Module:' .. (Info.opponentDisplayLibrary or 'OpponentDisplay'))

return {
	Opponent = Opponent, ---@module 'Opponent'
	OpponentDisplay = OpponentDisplay, ---@module 'OpponentDisplay'
}
