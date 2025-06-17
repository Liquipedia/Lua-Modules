---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Map = Lua.import('Module:Infobox/Map')

---@class CustomMapInfobox: MapInfobox
local CustomMap = Class.new(Map)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	return CustomMap(frame):createInfobox()
end

return CustomMap
