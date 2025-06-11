---
-- @Liquipedia
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Game = Lua.import('Module:Infobox/Game')

---@class CustomGameInfobox: GameInfobox
local CustomGame = Class.new(Game)

---@param frame Frame
---@return Html
function CustomGame.run(frame)
	local customGame = CustomGame(frame)
	return customGame:createInfobox()
end

return CustomGame
