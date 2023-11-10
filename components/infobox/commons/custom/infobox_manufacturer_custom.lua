---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Manufacturer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomManufacturer = Class.new()

---@param frame Frame
---@return Html
function Manufacturer.run(frame)
	return Manufacturer(frame):createInfobox()
end

return CustomGame
