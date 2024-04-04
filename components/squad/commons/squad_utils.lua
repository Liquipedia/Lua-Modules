---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')

local SquadUtils = {}

---@param args table
---@return table[]
function SquadUtils.parsePlayers(args)
	return Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)
end

---@param players {inactivedate: string|nil}[]
---@return boolean
function SquadUtils.anyInactive(players)
	return Array.any(players, function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end)
end

return SquadUtils
