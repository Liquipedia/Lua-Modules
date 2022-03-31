---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- local Squad = require('Module:Squad')
-- local SquadRow = require('Module:Squad/Row')

local CustomSquad = {}

function CustomSquad.run(frame)
	error("CustomSquad.run() needs to be implemented on the local wiki if using manual Squad Tables")
end

function CustomSquad.runAuto(playerList, squadType)
	error("CustomSquad.runAuto() needs to be implemented on the local wiki if using SquadAuto")
end

return CustomSquad
