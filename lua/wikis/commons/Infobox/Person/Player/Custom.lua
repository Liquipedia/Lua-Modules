---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Class = require('Module:Class')

local Player = Lua.import('Module:Infobox/Person')

---@class CustomInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	return CustomPlayer(frame):createInfobox()
end

return CustomPlayer
