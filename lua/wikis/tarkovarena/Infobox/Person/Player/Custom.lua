---
-- @Liquipedia
-- wiki=tarkovarena
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Player = Lua.import('Module:Infobox/Person')

---@class TarkovArenaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player.args.history = TeamHistoryAuto.results{convertrole = true}
	return player:createInfobox()
end

return CustomPlayer
