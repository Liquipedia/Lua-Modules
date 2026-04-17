---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local SquadContexts = Lua.import('Module:Features/Squad/Contexts/Squad')
local SquadController = Lua.import('Module:Features/Squad/Controller')

local CustomSquad = {}

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	return SquadContexts.GameTitle{value = args.game, children = {SquadController.run(frame)}}
end

return CustomSquad
