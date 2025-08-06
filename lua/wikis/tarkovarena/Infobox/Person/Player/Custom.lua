---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')

local Player = Lua.import('Module:Infobox/Person')

---@class TarkovArenaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player.args.history = TeamHistoryAuto.results{convertrole = true}
	player.args.autoTeam = true
	return player:createInfobox()
end

return CustomPlayer
