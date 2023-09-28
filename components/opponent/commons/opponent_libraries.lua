---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentLibraries
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {requireDevIfEnabled = true})

return {
	Opponent = Lua.import('Module:'.. (Info.opponentLibrary or 'Opponent'), {requireDevIfEnabled = true}),
	OpponentDisplay = Lua.import('Module:'.. (Info.opponentDisplayLibrary or 'OpponentDisplay'),
		{requireDevIfEnabled = true})
}
