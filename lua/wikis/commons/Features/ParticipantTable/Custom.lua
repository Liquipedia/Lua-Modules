---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Controller = Lua.import('Module:Features/ParticipantTable/Controller')

local CustomConfig = {}

return {
	run = function(frame)
		return Controller.execute(frame, CustomConfig)
	end
}
