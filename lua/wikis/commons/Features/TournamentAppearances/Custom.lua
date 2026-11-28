---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Controller = Lua.import('Module:Features/TournamentAppearances/Controller')

return {
	run = function(frame)
		return Controller.execute(frame)
	end
}
