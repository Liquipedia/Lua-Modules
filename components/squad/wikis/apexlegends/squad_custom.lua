---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, SquadUtils.defaultRow(SquadRow, {useTemplatesForSpecialTeams = true}))
end

return CustomSquad

