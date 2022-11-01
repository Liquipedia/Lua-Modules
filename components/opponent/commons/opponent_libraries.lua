---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentLibraries
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = require('Module:Info')
local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:'.. (Info.opponentLibrary or 'Opponent'), {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:'.. (Info.opponentDisplayLibrary or 'OpponentDisplay'),
	{requireDevIfEnabled = true})

return Opponent, OpponentDisplay
