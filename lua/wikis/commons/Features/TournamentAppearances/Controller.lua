---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Legacy = Lua.import('Module:PlayerTournamentAppearances')

local Controller = {}

function Controller.execute(frame, CustomConfig)
	return Legacy.run(frame)
end

return Controller
