---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')

local CustomOpponent = Table.deepCopy(Opponent)

--[[
Converts a opponent to a name. The name is the same as the one used in the
match2opponent.name field.

Returns nil if the team template does not exist.
]]
---@param opponent standardOpponent
---@return string
function CustomOpponent.toName(opponent)
	if opponent.type == Opponent.team then
		return mw.ext.TeamTemplate.raw(opponent.template).page
	end
	return Opponent.toName(opponent)
end

return CustomOpponent
